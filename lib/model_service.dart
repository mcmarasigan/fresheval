import 'package:flutter_vision/flutter_vision.dart';
import 'package:fresheval/l10n.dart';
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
  late FlutterVision _invalidVision;
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

       // primary YOLO (valid vegetables)
      await _flutterVision.loadYoloModel(
        modelPath: "assets/yolov8_best.tflite",
        labels: "assets/yolov8_label.txt",
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
      );
       // invalid YOLO (Arm, BellPepper, Bread… Strawberry)
      await _invalidVision.loadYoloModel(
        modelPath: "assets/invalid_yolov8.tflite",
        labels: "assets/invalid_labels.txt",
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
      );
      // EfficientNet model for freshness classification
      _efficientNetInterpreter = await Interpreter.fromAsset(
        "assets/efficientnetb7_fixed.tflite",
        options: InterpreterOptions()..threads = 2,
      );

      _modelsLoaded = true;
      
    } catch (e) {
      
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
      
      return [];
    }
  }

  Future<Map<String, dynamic>> classifyInvalid(Uint8List croppedImage) async {
    if (!_modelsLoaded) {
      
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
      
      return {'label': 'Unknown', 'confidence': 0.0};
    }
  }

 Future<List<Map<String, dynamic>>> detectObjects(
      Uint8List imageBytes, double imageW, double imageH) async {
    if (!_modelsLoaded) return [];

    // 1) build 640×640 canvas exactly as you already do…
    final img.Image original = img.decodeImage(imageBytes)!;
    final double scale = math.min(
        _yoloInputSize / original.width, _yoloInputSize / original.height);
    final int newW = (original.width * scale).round();
    final int newH = (original.height * scale).round();
    final img.Image resized =
        img.copyResize(original, width: newW, height: newH);
    final img.Image canvas =
        img.Image(_yoloInputSize.toInt(), _yoloInputSize.toInt());
    img.fill(canvas, img.getColor(0, 0, 0));
    final int offX = ((_yoloInputSize - newW) / 2).round();
    final int offY = ((_yoloInputSize - newH) / 2).round();
    img.copyInto(canvas, resized, dstX: offX, dstY: offY);
    final Uint8List canvasBytes = Uint8List.fromList(img.encodeJpg(canvas));

    // 2) run your valid-classes YOLO on full canvas
    final validRaw = await _flutterVision.yoloOnImage(
      bytesList: canvasBytes,
      imageHeight: _yoloInputSize.toInt(),
      imageWidth: _yoloInputSize.toInt(),
      iouThreshold: 0.4,
      confThreshold: 0.5,
    );
    if (validRaw.isEmpty) return [];

    // prepare img.Image for cropping
    final img.Image canvasImg = img.decodeImage(canvasBytes)!;
    const double invalidThreshold = 0.6; // 60% conf for invalid

    List<Map<String, dynamic>> kept = [];

    // 3) for each valid detection, crop & check invalid
    for (final det in validRaw) {
      final List<double> box = List<double>.from(det['box']);
      final int x1 = box[0].round(), y1 = box[1].round();
      final int w = (box[2] - box[0]).round();
      final int h = (box[3] - box[1]).round();

      // crop region out of canvas
      img.Image win = img.copyCrop(
        canvasImg,
        x1.clamp(0, 639),
        y1.clamp(0, 639),
        w.clamp(1, 640 - x1),
        h.clamp(1, 640 - y1),
      );
      // resize crop back to 640×640 for invalid YOLO
      win = img.copyResize(
        win,
        width: _yoloInputSize.toInt(),
        height: _yoloInputSize.toInt(),
      );
      final Uint8List winBytes = Uint8List.fromList(img.encodeJpg(win));

      // 4) run invalid YOLO on _that_ crop
      final invRaw = await _invalidVision.yoloOnImage(
        bytesList: winBytes,
        imageHeight: _yoloInputSize.toInt(),
        imageWidth: _yoloInputSize.toInt(),
        iouThreshold: 0.4,
        confThreshold: invalidThreshold,
      );

      // keep only if invalid model found NOTHING
      if (invRaw.isEmpty) {
        // scale box back to original image coords
        double xMin =
            ((box[0] - offX) / scale).clamp(0.0, original.width.toDouble());
        double yMin =
            ((box[1] - offY) / scale).clamp(0.0, original.height.toDouble());
        double xMax =
            ((box[2] - offX) / scale).clamp(0.0, original.width.toDouble());
        double yMax =
            ((box[3] - offY) / scale).clamp(0.0, original.height.toDouble());
        final double conf = box[4] * 100;

        if (xMax > xMin && yMax > yMin) {
          kept.add({
            'label': det['tag'],
            'confidence': conf,
            'bbox': [xMin, yMin, xMax, yMax],
            'originalWidth': original.width.toDouble(),
            'originalHeight': original.height.toDouble(),
          });
        }
      }
      // else: drop this valid det because invalid YOLO said “that’s a Kiwi/Furniture/etc”
    }

    return kept;
  }


  Future<Map<String, dynamic>> classifyDetection({
    required Uint8List imageBytes,
    required Map<String, dynamic> detection,
  }) async {
    final cropped = cropObject(
      imageBytes,
      detection['bbox'],
      detection['originalWidth'],
      detection['originalHeight'],
    );

    final freshness = await classifyFreshness(cropped);
    final interpretation = interpretFreshness(
      freshness['confidence'],
      freshness['label'],
    );
    final explanation = getPredictionExplanation(
      freshness['label'],
      freshness['confidence'],
    );
    final freshnessLabel = getFreshnessLabel(freshness['label']);

    return {
      'object': detection['label'],
      'bbox': detection['bbox'],
      'confidence': detection['confidence'],
      'freshness': freshnessLabel,
      'freshnessConfidence': freshness['confidence'],
      'freshnessStatus': interpretation,
      'explanation': explanation,
      'originalWidth': detection['originalWidth'],
      'originalHeight': detection['originalHeight'],
      'vqr': freshness['label'],
    };
  }

  String getFreshnessLabel(String vqrLabel) {
    final int vqr = int.tryParse(vqrLabel.replaceAll("VQR-", "")) ?? -1;
    if (vqr >= 4) return "Fresh";
    if (vqr >= 1) return "Rotten";
    return "Unknown";
  }

  Future<Map<String, dynamic>> classifyFreshness(Uint8List croppedImage) async {
    if (!_modelsLoaded) {
      return {'label': 'Unknown', 'confidence': 0.0};
    }

    try {
      final input = _preprocessImageForEfficientNet(croppedImage);
      final outputShape = _efficientNetInterpreter.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape([1, outputShape[1]]);

      _efficientNetInterpreter.run(input, output);
      final predictions = List<double>.from(output[0]);

      // Fallback protection against NaN or bad outputs
      if (predictions.isEmpty || predictions.any((e) => e.isNaN)) {
        return {'label': 'Unknown', 'confidence': 0.0};
      }

      final softmaxScores = _softmax(predictions);
      final predictedIndex =
          softmaxScores.indexOf(softmaxScores.reduce(math.max));

      // Protection against empty label list
      if (predictedIndex < 0 || predictedIndex >= _efficientNetLabels.length) {
        return {'label': 'Unknown', 'confidence': 0.0};
      }

      return {
        'label': _efficientNetLabels[predictedIndex],
        'confidence': softmaxScores[predictedIndex] * 100,
      };
    } catch (e) {
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

    // Clamp coordinates to image boundaries
    xMin = xMin.clamp(0.0, imageWidth);
    yMin = yMin.clamp(0.0, imageHeight);
    xMax = xMax.clamp(0.0, imageWidth);
    yMax = yMax.clamp(0.0, imageHeight);

    int cropX = xMin.round();
    int cropY = yMin.round();
    int cropW = (xMax - xMin).round();
    int cropH = (yMax - yMin).round();

    // Ensure positive dimensions
    cropW = cropW > 0 ? cropW : 1;
    cropH = cropH > 0 ? cropH : 1;

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
          final pixel = resizedImage.getPixel(x, y);
          final r = ((pixel >> 16) & 0xFF) / 127.5 - 1.0;
          final g = ((pixel >> 8) & 0xFF) / 127.5 - 1.0;
          final b = (pixel & 0xFF) / 127.5 - 1.0;
          return [r, g, b];
        });
      })
    ];
  }



  List<double> _softmax(List<double> scores) {
    final expScores = scores.map(math.exp).toList();
    final sumExpScores = expScores.reduce((a, b) => a + b);
    return expScores.map((score) => score / sumExpScores).toList();
  }

 String interpretFreshness(double confidence, String vqrLabel) {
    final int vqr = int.tryParse(vqrLabel.replaceAll("VQR-", "")) ?? -1;

    if (vqr >= 8) {
      return "🟢 Fresh (Excellent)";
    } else if (vqr >= 6) {
      return "🟡 Fresh (Good)";
    } else if (vqr >= 4) {
      return "🟡 Fresh (Fair)";
    } else if (vqr == 3) {
      return "🔴 Rotten (Spoiling)";
    } else if (vqr >= 1) {
      return "🔴 Rotten";
    } else {
      return "⚠️ Unknown";
    }
  }
String getPredictionExplanation(String vqrLabel, double confidence) {
    final int vqr = int.tryParse(vqrLabel.replaceAll("VQR-", "")) ?? -1;

    if (vqr >= 8) {
      return "Firm texture, vibrant color, and no visible damage.";
    } else if (vqr >= 6) {
      return "Slight signs of aging, but still looks edible and safe.";
    } else if (vqr >= 4) {
      return "Some softness or dullness visible — use as soon as possible.";
    } else if (vqr == 3) {
      return "Visible spoilage like dark spots or softness — risky to eat.";
    } else if (vqr >= 1) {
      return "Severe signs of decay. Not recommended for consumption.";
    } else {
      return "Image unclear. Try retaking the photo in better lighting.";
    }
  }


  Map<String, String> getShelfLifeAndRecommendation(
      String label, String vqrLabel) {
    String originalLabel = label.toLowerCase().trim();
    final RegExp vqrMatch = RegExp(r"(\d+)");
    final int vqr =
        int.tryParse(vqrMatch.firstMatch(vqrLabel)?.group(1) ?? '') ?? -1;

    final int effectiveVqr = vqr == -1 ? 1 : vqr;

    String matchedLabel = '';
    if (originalLabel.contains('eggplant')) {
      matchedLabel = 'eggplant';
    } else if (originalLabel.contains('tomato')) {
      matchedLabel = 'tomato';
    } else if (originalLabel.contains('potato')) {
      matchedLabel = 'potato';
    } else {
      matchedLabel = 'unknown';
    }

    String shelfLife = '📆 Shelf life info not available';
    String recommendation = '📌 No advice available.';

    switch (matchedLabel) {
      case 'eggplant':
        if (effectiveVqr >= 8) {
          shelfLife = '🟢 5–6 days at room temperature';
          recommendation =
              '✅ Store in a cool spot. Do not wash until ready to use.';
        } else if (effectiveVqr >= 6) {
          shelfLife = '🟡 3–4 days';
          recommendation = '⚠️ Use soon. Skin may begin softening.';
        } else if (effectiveVqr >= 4) {
          shelfLife = '🟡 2 days';
          recommendation = '⚠️ May be losing firmness. Cook immediately.';
        } else if (effectiveVqr == 3) {
          shelfLife = '🔴 1 day';
          recommendation = '❌ Almost spoiled. Only use if still firm.';
        } else {
          shelfLife = '🔴 Not marketable';
          recommendation = '❌ Discard. Not safe for use.';
        }
        break;

      case 'tomato':
        if (effectiveVqr >= 8) {
          shelfLife = '🟢 14 days at room temperature';
          recommendation =
              '✅ Store at room temp to ripen. Refrigerate when fully ripe.';
        } else if (effectiveVqr >= 6) {
          shelfLife = '🟡 10–12 days';
          recommendation =
              '⚠️ Still fresh but may soften faster. Monitor daily.';
        } else if (effectiveVqr >= 4) {
          shelfLife = '🟡 4–9 days';
          recommendation = '⚠️ Overripe signs may appear. Eat soon.';
        } else if (effectiveVqr == 3) {
          shelfLife = '🔴 1–3 days';
          recommendation = '❌ Likely overripe. Consume immediately or discard.';
        } else {
          shelfLife = '🔴 Not marketable';
          recommendation = '❌ Discard. Not suitable for consumption.';
        }
        break;

      case 'potato':
        if (effectiveVqr >= 8) {
          shelfLife = '🟢 30–60 days (cool, dark place)';
          recommendation = '✅ Very fresh. Store in a ventilated paper bag.';
        } else if (effectiveVqr >= 6) {
          shelfLife = '🟡 14–21 days';
          recommendation =
              '⚠️ Still acceptable. Monitor for sprouting or softness.';
        } else if (effectiveVqr >= 4) {
          shelfLife = '🟡 7–13 days';
          recommendation = '⚠️ Aging. Use quickly and check for spoilage.';
        } else if (effectiveVqr == 3) {
          shelfLife = '🔴 1–6 days';
          recommendation = '❌ At risk. Use immediately or discard.';
        } else {
          shelfLife = '🔴 Not marketable';
          recommendation = '❌ Discard. May be unsafe to eat.';
        }
        break;

      default:
        shelfLife = '📆 Shelf life info not available';
        recommendation = '📌 No advice available.';
    }

    return {
      'shelfLife': shelfLife,
      'recommendation': recommendation,
    };
  }



  double _calculateAverageBrightness(Uint8List imageBytes) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      
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
    
    return averageBrightness;
  }

  double _calculateBlurVariance(Uint8List imageBytes) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      
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
    
    return avgGradient;
  }

  Future<List<Map<String, dynamic>>> analyzeMultiAngleImages({
    required Uint8List frontImage,
    required Uint8List backImage,
    required double imageWidth,
    required double imageHeight,
    required AppLocalizations localizations,
  }) async {
    final frontDetections =
        await detectObjects(frontImage, imageWidth, imageHeight);
    final backDetections =
        await detectObjects(backImage, imageWidth, imageHeight);

    final frontTop = frontDetections.isNotEmpty
        ? frontDetections
            .reduce((a, b) => a['confidence'] > b['confidence'] ? a : b)
        : null;

    final backTop = backDetections.isNotEmpty
        ? backDetections
            .reduce((a, b) => a['confidence'] > b['confidence'] ? a : b)
        : null;

    // Check if objects are detected in both images
    if (frontTop == null || backTop == null) {

      final missingSide = frontTop == null ? 'front' : 'back';
      final localizedSide = localizations.getTranslation(missingSide);
      final errorMessage = localizations
          .getTranslation('no objects detected')
          .replaceAll('{side}', localizedSide);
      return [
        {
          'object': 'None',
          'front': null,
          'back': null,
          'mergedFreshness': 'Unknown',
          'mergedStatus': '⚠️ No object detected – Try scanning again',
          'mergedVQR': 'VQR-0',
          'mergedConfidence': 0.0,
          'error':
              errorMessage,
        }
      ];
    }

    // Compare labels to ensure the same vegetable
    final frontLabelRaw = frontTop['label'].toString().toLowerCase().trim();
    final backLabelRaw = backTop['label'].toString().toLowerCase().trim();
    final frontLabel = localizations.getTranslation(frontLabelRaw);
    final backLabel = localizations.getTranslation(backLabelRaw);

    if (frontLabel != backLabel) {
      
      return [
        {
          'object': 'None',
          'front': null,
          'back': null,
          'mergedFreshness': 'Unknown',
          'mergedStatus': '❌ Error – Different vegetables detected',
          'mergedVQR': 'VQR-0',
          'mergedConfidence': 0.0,
          'error': localizations.getTranslation('different vegetable error')
              .replaceAll('{front}', frontLabel)
              .replaceAll('{back}', backLabel),
        }
      ];
    }

    final frontClassified = await classifyDetection(
      imageBytes: frontImage,
      detection: frontTop,
    );

    final backClassified = await classifyDetection(
      imageBytes: backImage,
      detection: backTop,
    );

    final String frontVQR = frontClassified['vqr'] ?? 'VQR-0';
    final String backVQR = backClassified['vqr'] ?? 'VQR-0';
    final int frontVQRNum = int.tryParse(frontVQR.replaceAll("VQR-", "")) ?? 0;
    final int backVQRNum = int.tryParse(backVQR.replaceAll("VQR-", "")) ?? 0;
    final double frontConf = frontClassified['freshnessConfidence'] ?? 0.0;
    final double backConf = backClassified['freshnessConfidence'] ?? 0.0;

    const double threshold = 60.0;
    double avgConf;
    int mergedVQRNum;

    if (frontConf >= threshold && backConf >= threshold) {
      mergedVQRNum = ((frontVQRNum + backVQRNum) / 2).round();
    } else if (frontConf >= threshold) {
      mergedVQRNum = frontVQRNum;
    } else if (backConf >= threshold) {
      mergedVQRNum = backVQRNum;
    } else {
      mergedVQRNum = ((frontVQRNum + backVQRNum) / 2).round();
    }
    avgConf = (frontConf + backConf) / 2;

    final mergedVQR = "VQR-$mergedVQRNum";
    final mergedFreshness = getFreshnessLabel(mergedVQR);
    final mergedStatus = interpretFreshness(avgConf, mergedVQR);

    return [
      {
        'object': frontClassified['object'],
        'front': frontClassified,
        'back': backClassified,
        'mergedFreshness': mergedFreshness,
        'mergedStatus': mergedStatus,
        'mergedVQR': mergedVQR,
        'mergedConfidence': avgConf,
      }
    ];
  }

  void close() {
    _flutterVision.closeYoloModel();
    _efficientNetInterpreter.close();
  }
}
