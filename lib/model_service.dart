import 'package:flutter_vision/flutter_vision.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:developer';
import 'dart:math' as math;
import 'dart:convert';

class ModelService {
  late FlutterVision _flutterVision;
  late Interpreter _efficientNetInterpreter;
  late List<String> _yoloLabels;
  late List<String> _efficientNetLabels;
  bool _modelsLoaded = false;

  final double _yoloInputSize = 640;
  final double _efficientNetInputSize = 224;

  Future<void> loadModels() async {
    try {
      _flutterVision = FlutterVision();

      _yoloLabels = await _loadLabels("assets/yolov8_label.txt");
      _efficientNetLabels =
          await _loadLabels("assets/efficientnetb7_label.txt");

      await _flutterVision.loadYoloModel(
        modelPath: "assets/yolov8_best.tflite",
        labels: "assets/yolov8_label.txt",
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
      );

      _efficientNetInterpreter = await Interpreter.fromAsset(
        "assets/efficientnetb7_fixed.tflite",
        options: InterpreterOptions()..threads = 2,
      );

      _modelsLoaded = true;
      log("✅ YOLOv8 & EfficientNetB7 models loaded successfully.");
    } catch (e) {
      log("⚠️ Error loading models: $e");
    }
  }

  Future<List<String>> _loadLabels(String assetPath) async {
    try {
      String labelsString = await rootBundle.loadString(assetPath);
      return LineSplitter.split(labelsString)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      log("⚠️ Error loading labels from $assetPath: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> classifyInvalid(Uint8List croppedImage) async {
    if (!_modelsLoaded) {
      log("⚠️ Models not loaded yet.");
      return {'label': 'Unknown', 'confidence': 0.0};
    }

    try {
      final input = _preprocessImageForEfficientNet(croppedImage);
      final outputShape = _efficientNetInterpreter.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape([1, outputShape[1]]);

      _efficientNetInterpreter.run(input, output);
      final predictions = List<double>.from(output[0]);
      final softmaxScores = _softmax(predictions);
      final predictedIndex = softmaxScores
          .indexWhere((val) => val == softmaxScores.reduce(math.max));

      return {
        'label': _efficientNetLabels[predictedIndex],
        'confidence': softmaxScores[predictedIndex] * 100,
      };
    } catch (e) {
      log("⚠️ Error during Invalid model classification: $e");
      return {'label': 'Unknown', 'confidence': 0.0};
    }
  }

  Future<List<Map<String, dynamic>>> detectAndClassify(
    Uint8List imageBytes,
    double imageWidth,
    double imageHeight,
  ) async {
    // Check image brightness
    final avgBrightness = _calculateAverageBrightness(imageBytes);
    const double darkThreshold = 50.0;
    const double brightThreshold = 200.0;

    if (avgBrightness < darkThreshold) {
      log("🌑 Image too dark (Brightness: $avgBrightness).");
      return [
        {
          'object': 'None',
          'confidence': 0.0,
          'freshness': 'N/A',
          'freshnessConfidence': 0.0,
          'freshnessStatus': 'Image Too Dark',
          'explanation':
              'The image is too dark for accurate detection. Try turning on the flash, increasing lighting, or cleaning the camera lens.',
          'bbox': [],
          'originalWidth': imageWidth,
          'originalHeight': imageHeight,
        }
      ];
    } else if (avgBrightness > brightThreshold) {
      log("☀️ Image too bright (Brightness: $avgBrightness).");
      return [
        {
          'object': 'None',
          'confidence': 0.0,
          'freshness': 'N/A',
          'freshnessConfidence': 0.0,
          'freshnessStatus': 'Image Too Bright',
          'explanation':
              'The image is too bright for accurate detection. Please reduce lighting or clean the camera lens.',
          'bbox': [],
          'originalWidth': imageWidth,
          'originalHeight': imageHeight,
        }
      ];
    }
    Future<List<Map<String, dynamic>>> analyzeMultiAngleImages({
      required Uint8List frontImage,
      required Uint8List backImage,
      required double imageWidth,
      required double imageHeight,
    }) async {
      final frontResults =
          await detectAndClassify(frontImage, imageWidth, imageHeight);
      final backResults =
          await detectAndClassify(backImage, imageWidth, imageHeight);

      // Optionally: Merge logic if needed (based on object label or bounding box proximity)
      List<Map<String, dynamic>> combinedResults = [];

      for (int i = 0; i < frontResults.length; i++) {
        final front = frontResults[i];

        Map<String, dynamic> matchedBack = backResults.firstWhere(
          (back) => back['object'] == front['object'],
          orElse: () => {},
        );

        String finalStatus = front['freshnessStatus'];
        double finalConfidence = front['freshnessConfidence'];

        if (matchedBack.isNotEmpty) {
          final double avgConfidence = (front['freshnessConfidence'] +
                  matchedBack['freshnessConfidence']) /
              2;
          final String mergedLabel =
              front['freshness'] == matchedBack['freshness']
                  ? front['freshness']
                  : (avgConfidence > 50
                      ? front['freshness']
                      : matchedBack['freshness']);

          finalStatus =
              interpretFreshness(avgConfidence, mergedLabel.toLowerCase());
          finalConfidence = avgConfidence;
        }

        combinedResults.add({
          'object': front['object'],
          'front': front,
          'back': matchedBack.isNotEmpty ? matchedBack : null,
          'mergedFreshness': front['freshness'],
          'mergedConfidence': finalConfidence,
          'mergedStatus': finalStatus,
        });
      }

      return combinedResults;
    }


    // Check image blurriness
    final blurScore = _calculateBlurVariance(imageBytes);
    const double blurThreshold = 5.0; // Lowered threshold for testing

    if (blurScore < blurThreshold) {
      log("🌫️ Image too blurry (Gradient Score: $blurScore < $blurThreshold).");
      return [
        {
          'object': 'None',
          'confidence': 0.0,
          'freshness': 'N/A',
          'freshnessConfidence': 0.0,
          'freshnessStatus': 'Image Too Blurry',
          'explanation':
              'The image is too blurry for accurate detection. Please hold the camera steady or clean the lens.',
          'bbox': [],
          'originalWidth': imageWidth,
          'originalHeight': imageHeight,
        }
      ];
    } else {
      log("✅ Image sharpness acceptable (Gradient Score: $blurScore >= $blurThreshold).");
    }

    // Proceed with detection if brightness and blur are acceptable
    final detections = await detectObjects(imageBytes, imageWidth, imageHeight);

    if (detections.isEmpty) {
      log("❌ No objects detected in the image.");
      return [
        {
          'object': 'None',
          'confidence': 0.0,
          'freshness': 'N/A',
          'freshnessConfidence': 0.0,
          'freshnessStatus': 'No Detection',
          'explanation': 'No objects were detected in the image.',
          'bbox': [],
          'originalWidth': imageWidth,
          'originalHeight': imageHeight,
        }
      ];
    }

    List<Map<String, dynamic>> results = [];

    for (final detection in detections) {
      final cropped = cropObject(
        imageBytes,
        detection['bbox'],
        detection['originalWidth'],
        detection['originalHeight'],
      );

      final freshness = await classifyFreshness(cropped);
      final interpretation = interpretFreshness(
        freshness['confidence'],
        freshness['label'].toLowerCase(),
      );
      final explanation = getPredictionExplanation(
        freshness['label'].toLowerCase(),
        freshness['confidence'],
      );

      results.add({
        'object': detection['label'],
        'bbox': detection['bbox'],
        'confidence': detection['confidence'],
        'freshness': freshness['label'],
        'freshnessConfidence': freshness['confidence'],
        'freshnessStatus': interpretation,
        'explanation': explanation,
        'originalWidth': detection['originalWidth'],
        'originalHeight': detection['originalHeight'],
      });
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> detectObjects(
      Uint8List imageBytes, double imageWidth, double imageHeight) async {
    if (!_modelsLoaded) {
      log("⚠️ Models not loaded yet.");
      return [];
    }

    try {
      final img.Image? originalImage = img.decodeImage(imageBytes);
      final originalWidth = originalImage?.width.toDouble() ?? imageWidth;
      final originalHeight = originalImage?.height.toDouble() ?? imageHeight;
      log("📏 Original Image Dimensions: ${originalWidth}x$originalHeight");

      final detections = await _flutterVision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: _yoloInputSize.toInt(),
        imageWidth: _yoloInputSize.toInt(),
        iouThreshold: 0.4,
        confThreshold: 0.5,
      );

      log("🔍 YOLOv8 Raw Detections: $detections");

      if (detections.isEmpty) {
        log("⚠️ No objects detected.");
        return [];
      }

      return detections
          .map((detection) {
            List bbox = detection['box'];
            if (bbox.length < 5) return null;

            double xMin = bbox[0];
            double yMin = bbox[1];
            double xMax = bbox[2];
            double yMax = bbox[3];
            double confidence = bbox[4] * 100;

            log("📍 Raw BBox for ${detection['tag']}: [$xMin, $yMin, $xMax, $yMax]");

            return {
              'label': detection['tag'],
              'confidence': confidence,
              'bbox': [xMin, yMin, xMax, yMax],
              'originalWidth': originalWidth,
              'originalHeight': originalHeight,
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (e) {
      log("⚠️ Error during YOLO inference: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> classifyFreshness(Uint8List croppedImage) async {
    if (!_modelsLoaded) {
      log("⚠️ Models not loaded yet.");
      return {'label': 'Unknown', 'confidence': 0.0};
    }

    try {
      final input = _preprocessImageForEfficientNet(croppedImage);
      final outputShape = _efficientNetInterpreter.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape([1, outputShape[1]]);

      _efficientNetInterpreter.run(input, output);
      final predictions = List<double>.from(output[0]);
      final softmaxScores = _softmax(predictions);
      final predictedIndex = softmaxScores
          .indexWhere((val) => val == softmaxScores.reduce(math.max));

      return {
        'label': _efficientNetLabels[predictedIndex],
        'confidence': softmaxScores[predictedIndex] * 100,
      };
    } catch (e) {
      log("⚠️ Error during EfficientNet classification: $e");
      return {'label': 'Unknown', 'confidence': 0.0};
    }
  }

  Uint8List cropObject(
      Uint8List imageBytes, List bbox, double imageWidth, double imageHeight) {
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception("Failed to decode image.");

    double xMin = bbox[0];
    double yMin = bbox[1];
    double xMax = bbox[2];
    double yMax = bbox[3];

    int cropX = xMin.round();
    int cropY = yMin.round();
    int cropW = (xMax - xMin).round();
    int cropH = (yMax - yMin).round();

    final img.Image cropped =
        img.copyCrop(originalImage, cropX, cropY, cropW, cropH);
    final img.Image resizedCropped = img.copyResize(cropped,
        width: _efficientNetInputSize.toInt(),
        height: _efficientNetInputSize.toInt());

    return Uint8List.fromList(img.encodeJpg(resizedCropped, quality: 85));
  }

  List<List<List<List<double>>>> _preprocessImageForEfficientNet(
      Uint8List imageBytes) {
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception("Failed to decode image.");

    final img.Image resizedImage = img.copyResize(originalImage,
        width: _efficientNetInputSize.toInt(),
        height: _efficientNetInputSize.toInt());

    return [
      List.generate(_efficientNetInputSize.toInt(), (y) {
        return List.generate(_efficientNetInputSize.toInt(), (x) {
          final int pixel = resizedImage.getPixel(x, y);
          return [
            ((pixel >> 16) & 0xFF) / 127.5 - 1.0,
            ((pixel >> 8) & 0xFF) / 127.5 - 1.0,
            (pixel & 0xFF) / 127.5 - 1.0,
          ];
        });
      })
    ];
  }

  List<double> _softmax(List<double> scores) {
    final expScores = scores.map(math.exp).toList();
    final sumExpScores = expScores.reduce((a, b) => a + b);
    return expScores.map((score) => score / sumExpScores).toList();
  }

String interpretFreshness(double confidence, String label) {
    final isFresh = label.toLowerCase() == "fresh";

    if (isFresh) {
      if (confidence > 80.0) return "Healthy and vibrant";
      if (confidence >= 35.0) return "Showing signs of dullness or ripping";
      return "May be entering early spoilage";
    } else {
      if (confidence > 80.0) return "Shriveled or moldy";
      if (confidence > 40.0) return "Bruised or soft, early mold possible";
      return "Degradation suspected";
    }
  }


  String getPredictionExplanation(String label, double confidence) {
    final isFresh = label.toLowerCase() == "fresh";

    if (isFresh) {
      if (confidence > 80.0) {
        return "The item is healthy, with firm skin and vibrant color.";
      } else if (confidence >= 35.0) {
        return "Dullness or minor ripping observed. Quality may be declining.";
      } else {
        return "Early spoilage signs are visible. Use with caution.";
      }
    } else {
      if (confidence > 80.0) {
        return "Clear signs of spoilage: shriveling, mold, or discoloration.";
      } else if (confidence > 40.0) {
        return "Bruising or softness observed. Early mold might be forming.";
      } else {
        return "Slight issues noted. Degradation might be starting.";
      }
    }
  }


  Map<String, String> getShelfLifeAndRecommendation(
      String label, String interpretation) {
    final lowerLabel = label.toLowerCase();
    String shelfLife = '';
    String recommendation = '';

    switch (lowerLabel) {
      case 'eggplant':
        if (interpretation.contains('Healthy')) {
          shelfLife = '3–5 days in the fridge';
          recommendation = 'Store in a crisper drawer. Don’t wash until use.';
        } else if (interpretation.contains('dullness') ||
            interpretation.contains('ripping')) {
          shelfLife = '1–2 days max';
          recommendation = 'Use quickly. May already be soft or less shiny.';
        } else {
          shelfLife = '0 days';
          recommendation = 'Spoiled or risky to eat. Discard if soft or brown.';
        }
        break;

      case 'tomato':
        if (interpretation.contains('Healthy')) {
          shelfLife = '4–7 days at room temp, up to 2 weeks in the fridge';
          recommendation =
              'Store at room temp to ripen. Refrigerate when ripe.';
        } else if (interpretation.contains('dullness') ||
            interpretation.contains('ripping')) {
          shelfLife = '1–3 days (likely overripe)';
          recommendation = 'Use soon. Check for softness or bruising.';
        } else {
          shelfLife = '0 days';
          recommendation =
              'Likely spoiled. Discard if soft, leaking, or smelly.';
        }
        break;

      case 'potato':
        if (interpretation.contains('Healthy')) {
          shelfLife = '1–2 months (cool, dark place)';
          recommendation = 'Store in a paper bag. Don’t refrigerate.';
        } else if (interpretation.contains('dullness') ||
            interpretation.contains('ripping')) {
          shelfLife = '1–2 weeks max';
          recommendation = 'Use soon. Check for sprouting or soft spots.';
        } else {
          shelfLife = '0 days';
          recommendation =
              'Toxic signs possible (green skin/sprouting). Discard.';
        }
        break;

      default:
        shelfLife = 'Unknown';
        recommendation = 'No data available.';
    }

    return {
      'shelfLife': shelfLife,
      'recommendation': recommendation,
    };
  }




  double _calculateAverageBrightness(Uint8List imageBytes) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      log("⚠️ Failed to decode image for brightness check.");
      return 128.0;
    }

    double totalLuminance = 0.0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel >> 16) & 0xFF;
        final g = (pixel >> 8) & 0xFF;
        final b = pixel & 0xFF;
        final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
        totalLuminance += luminance;
        pixelCount++;
      }
    }

    final averageBrightness = totalLuminance / pixelCount;
    log("💡 Average Brightness: $averageBrightness");
    return averageBrightness;
  }

  double _calculateBlurVariance(Uint8List imageBytes) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      log("⚠️ Failed to decode image for blur check.");
      return 1000.0; // Default high value (not blurry) if decoding fails
    }

    // Resize to a smaller size for consistency and speed
    final resized = img.copyResize(image, width: 320, height: 320);
    final grayscale = img.grayscale(resized);

    // Calculate gradient magnitude with more detailed logging
    double totalGradient = 0.0;
    double maxGradient = 0.0;
    int count = 0;

    for (int y = 1; y < grayscale.height - 1; y++) {
      for (int x = 1; x < grayscale.width - 1; x++) {
        final center = (grayscale.getPixel(x, y) & 0xFF).toDouble();
        final right = (grayscale.getPixel(x + 1, y) & 0xFF).toDouble();
        final bottom = (grayscale.getPixel(x, y + 1) & 0xFF).toDouble();
        final gradientX = (right - center).abs();
        final gradientY = (bottom - center).abs();
        final magnitude =
            math.sqrt(gradientX * gradientX + gradientY * gradientY);
        totalGradient += magnitude;
        maxGradient = math.max(maxGradient, magnitude);
        count++;
      }
    }

    final avgGradient = count > 0 ? totalGradient / count : 0.0;
    log("🌫️ Blur Check - Avg Gradient: $avgGradient, Max Gradient: $maxGradient, Pixels Processed: $count");
    return avgGradient;
  }

Future<List<Map<String, dynamic>>> analyzeMultiAngleImages({
    required Uint8List frontImage,
    required Uint8List backImage,
    required double imageWidth,
    required double imageHeight,
  }) async {
    final frontResults =
        await detectAndClassify(frontImage, imageWidth, imageHeight);
    final backResults =
        await detectAndClassify(backImage, imageWidth, imageHeight);

    List<Map<String, dynamic>> combinedResults = [];

   for (final front in frontResults) {
      // Skip invalid detection
      if (front['object'] == 'None' || front['freshness'] == 'N/A') {
        combinedResults.add({
          'object': front['object'],
          'front': front,
          'back': null,
          'mergedFreshness': front['freshness'],
          'mergedConfidence': front['freshnessConfidence'],
          'mergedStatus': front['freshnessStatus'],
        });
        continue;
      }

      final matchedBack = backResults.firstWhere(
        (back) => back['object'] == front['object'],
        orElse: () => {},
      );

      double finalConfidence = front['freshnessConfidence'];
      String finalLabel = front['freshness'];
      String finalStatus = front['freshnessStatus'];

      if (matchedBack.isNotEmpty &&
          matchedBack['object'] != 'None' &&
          matchedBack['freshness'] != 'N/A') {
        final double avgConfidence = (front['freshnessConfidence'] +
                matchedBack['freshnessConfidence']) /
            2;
        final mergedLabel = front['freshness'] == matchedBack['freshness']
            ? front['freshness']
            : (avgConfidence > 50
                ? front['freshness']
                : matchedBack['freshness']);

        finalConfidence = avgConfidence;
        finalLabel = mergedLabel;
        finalStatus =
            interpretFreshness(avgConfidence, mergedLabel.toLowerCase());
      }

      combinedResults.add({
        'object': front['object'],
        'front': front,
        'back': matchedBack.isNotEmpty ? matchedBack : null,
        'mergedFreshness': finalLabel,
        'mergedConfidence': finalConfidence,
        'mergedStatus': finalStatus,
      });
    }


    return combinedResults;
  }

  void close() {
    _flutterVision.closeYoloModel();
    _efficientNetInterpreter.close();
  }
}
