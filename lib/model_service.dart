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
  late Interpreter _nullInterpreter;
  late List<String> _nullLabels;
  bool _modelsLoaded = false;

  final double _yoloInputSize = 640; // YOLOv8 input size
  final double _efficientNetInputSize = 224; // EfficientNet input size

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
      _nullLabels = await _loadLabels("assets/null_label.txt");

      _nullInterpreter = await Interpreter.fromAsset(
        "assets/null.tflite",
        options: InterpreterOptions()..threads = 2,
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
      final outputShape = _nullInterpreter.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape([1, outputShape[1]]);

      _nullInterpreter.run(input, output);
      final predictions = List<double>.from(output[0]);
      final softmaxScores = _softmax(predictions);
      final predictedIndex = softmaxScores
          .indexWhere((val) => val == softmaxScores.reduce(math.max));

      return {
        'label': _nullLabels[predictedIndex],
        'confidence': softmaxScores[predictedIndex] * 100,
      };
    } catch (e) {
      log("⚠️ Error during Invalid model classification: $e");
      return {'label': 'Unknown', 'confidence': 0.0};
    }
  }

 Future<List<Map<String, dynamic>>> detectAndClassify(
      Uint8List imageBytes, double imageWidth, double imageHeight) async {
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

      final invalidCheck = await classifyInvalid(cropped);
      log("🧪 Invalid Check: ${invalidCheck['label']} @ ${invalidCheck['confidence'].toStringAsFixed(1)}%");

      if (invalidCheck['label'] == 'invalid' &&
          invalidCheck['confidence'] > 80.0) {
        log("🚫 Skipped invalid detection: ${detection['label']}");
        continue;
      }

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

    // Final fallback in case all detections were skipped
    if (results.isEmpty) {
      log("⚠️ All detections were filtered out (invalid objects).");
      return [
        {
          'object': 'None',
          'confidence': 0.0,
          'freshness': 'N/A',
          'freshnessConfidence': 0.0,
          'freshnessStatus': 'All Skipped',
          'explanation': 'All detected objects were filtered out as invalid.',
          'bbox': [],
          'originalWidth': imageWidth,
          'originalHeight': imageHeight,
        }
      ];
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
    if (label == "fresh") {
      if (confidence >= 80.0) return "Fresh (High Confidence)";
      if (confidence >= 40.0) return "Fresh (Low Confidence)";
      return "Fresh (Uncertain)";
    } else {
      if (confidence >= 80.0) return "Rotten (High Confidence)";
      if (confidence >= 40.0) return "Rotten (Low Confidence)";
      return "Rotten (Uncertain)";
    }
  }

  String getPredictionExplanation(String label, double confidence) {
    if (label == "fresh") {
      if (confidence >= 80.0) {
        return "The produce looks visually healthy with firm skin and vibrant color.";
      } else if (confidence >= 40.0) {
        return "Some ripeness or dulling is visible. It may be overripe or slightly soft.";
      } else {
        return "Low confidence: visual cues suggest early spoilage despite being labeled fresh.";
      }
    } else {
      if (confidence >= 80.0) {
        return "Signs of spoilage like mold, wrinkles, or discoloration are clearly visible.";
      } else if (confidence >= 40.0) {
        return "Potential spoilage indicators like bruises, soft areas, or early mold.";
      } else {
        return "Low confidence: spoilage signs not obvious, but model suspects degradation.";
      }
    }
  }
Map<String, String> getShelfLifeAndRecommendation(
      String label, String interpretation) {
    final lowerLabel = label.toLowerCase();

    String shelfLife = '';
    String recommendation = '';

    switch (lowerLabel) {
      case 'tomato':
        if (interpretation.contains('Fresh (High')) {
          shelfLife = '4–7 days at room temp, up to 2 weeks in the fridge';
          recommendation =
              'Store at room temperature to ripen. Refrigerate once ripe. Best for salads and sauces.';
        } else if (interpretation.contains('Fresh (Low')) {
          shelfLife = '1–3 days (likely overripe)';
          recommendation =
              'Use soon. Check for softness or bruising before eating.';
        } else if (interpretation.contains('Rotten (Low')) {
          shelfLife = 'Likely already spoiled';
          recommendation =
              'Check manually. If soft, leaking, or smells, discard.';
        } else {
          shelfLife = '0 days';
          recommendation = 'Discard immediately. Likely unsafe to eat.';
        }
        break;

      case 'eggplant':
        if (interpretation.contains('Fresh (High')) {
          shelfLife = '3–5 days in the fridge';
          recommendation = 'Store in crisper drawer. Don’t wash until use.';
        } else if (interpretation.contains('Fresh (Low')) {
          shelfLife = '1–2 days max';
          recommendation = 'Use quickly. May already be soft.';
        } else if (interpretation.contains('Rotten (Low')) {
          shelfLife = 'Likely spoiled';
          recommendation = 'Inspect manually for browning or softness.';
        } else {
          shelfLife = '0 days';
          recommendation = 'Spoiled. Not safe to eat.';
        }
        break;

      case 'potato':
        if (interpretation.contains('Fresh (High')) {
          shelfLife = '1–2 months (cool, dark place)';
          recommendation = 'Store in a paper bag. Don’t refrigerate.';
        } else if (interpretation.contains('Fresh (Low')) {
          shelfLife = '1–2 weeks max';
          recommendation = 'Use soon. Check for sprouting or soft spots.';
        } else if (interpretation.contains('Rotten (Low')) {
          shelfLife = 'Likely spoiled';
          recommendation = 'Inspect manually for greening or odor.';
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


  void close() {
    _flutterVision.closeYoloModel();
    _efficientNetInterpreter.close();
    _nullInterpreter.close();
  }
}
