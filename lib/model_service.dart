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
        modelPath: "assets/yolov8_vegetable.tflite",
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
      log("✅ Models loaded successfully");
    } catch (e) {
      log("❌ Error loading models: $e");
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
      log("❌ Error loading labels: $e");
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
      log("❌ Error classifying invalid: $e");
      return {'label': 'Unknown', 'confidence': 0.0};
    }
  }

  Future<List<Map<String, dynamic>>> detectObjects(
      Uint8List imageBytes, double imageWidth, double imageHeight) async {
    if (!_modelsLoaded) {
      return [];
    }

    try {
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return [];

      final double originalWidth = originalImage.width.toDouble();
      final double originalHeight = originalImage.height.toDouble();

      final double scale = math.min(
          _yoloInputSize / originalWidth, _yoloInputSize / originalHeight);
      final int newWidth = (originalWidth * scale).round();
      final int newHeight = (originalHeight * scale).round();

      final img.Image resizedImage =
          img.copyResize(originalImage, width: newWidth, height: newHeight);

      final img.Image canvas =
          img.Image(_yoloInputSize.toInt(), _yoloInputSize.toInt());
      img.fill(canvas, img.getColor(0, 0, 0));

      final int offsetX = ((_yoloInputSize - newWidth) / 2).round();
      final int offsetY = ((_yoloInputSize - newHeight) / 2).round();
      img.copyInto(canvas, resizedImage, dstX: offsetX, dstY: offsetY);

      final Uint8List resizedBytes = Uint8List.fromList(img.encodeJpg(canvas));

      final rawDetections = await _flutterVision.yoloOnImage(
        bytesList: resizedBytes,
        imageHeight: _yoloInputSize.toInt(),
        imageWidth: _yoloInputSize.toInt(),
        iouThreshold: 0.4,
        confThreshold: 0.5,
      );

      if (rawDetections.isEmpty) {
        return [];
      }

      final mappedDetections = rawDetections
          .map((detection) {
            final bbox = detection['box'];
            if (bbox.length < 5) return null;

            final String tag =
                (detection['tag'] ?? '').toString().toLowerCase();

            if (tag == 'invalid') {
              log("⚠️ Skipped invalid detection");
              return null;
            }

            final double xMin = bbox[0].toDouble();
            final double yMin = bbox[1].toDouble();
            final double xMax = bbox[2].toDouble();
            final double yMax = bbox[3].toDouble();
            final double confidence = bbox[4].toDouble();

            log("✅ Detected: $tag (${(confidence * 100).toStringAsFixed(2)}%)");

            return {
              'tag': tag,
              'box': [xMin, yMin, xMax, yMax, confidence],
            };
          })
          .whereType<Map<String, dynamic>>()
          .toList();

     return mappedDetections.map((det) {
        final bbox = det['box'];
        final double resizedWidth = _yoloInputSize;
        final double resizedHeight = _yoloInputSize;

        // Compute original → resized scale
        final double scale = math.min(
            resizedWidth / originalWidth, resizedHeight / originalHeight);
        final int newWidth = (originalWidth * scale).round();
        final int newHeight = (originalHeight * scale).round();
        final int offsetX = ((resizedWidth - newWidth) / 2).round();
        final int offsetY = ((resizedHeight - newHeight) / 2).round();

        // Map bbox back to original image coordinates
        final double xMin =
            ((bbox[0] - offsetX) / scale).clamp(0.0, originalWidth);
        final double yMin =
            ((bbox[1] - offsetY) / scale).clamp(0.0, originalHeight);
        final double xMax =
            ((bbox[2] - offsetX) / scale).clamp(0.0, originalWidth);
        final double yMax =
            ((bbox[3] - offsetY) / scale).clamp(0.0, originalHeight);

        return {
          'label': det['tag'],
          'confidence': bbox[4] * 100,
          'bbox': [xMin, yMin, xMax, yMax],
          'originalWidth': originalWidth,
          'originalHeight': originalHeight,
        };
      }).toList();


    } catch (e) {
      log("❌ Error during detection: $e");
      return [];
    }
  }


  Future<Map<String, dynamic>> classifyDetection({
    required Uint8List imageBytes,
    required Map<String, dynamic> detection,
    required AppLocalizations localizations,
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
      localizations,
    );
    final explanation = getPredictionExplanation(
      freshness['label'],
      freshness['confidence'],
      detection['label'],
      localizations,
    );
    final freshnessLabel = getFreshnessLabel(freshness['label'], localizations);

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

  String getFreshnessLabel(String vqrLabel, AppLocalizations localizations) {
    final int vqr = int.tryParse(vqrLabel.replaceAll("VQR-", "")) ?? -1;
    if (vqr >= 4) return localizations.getTranslation('freshness_label_fresh');
    if (vqr >= 1) return localizations.getTranslation('freshness_label_rotten');
    return localizations.getTranslation('freshness_label_unknown');
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
      log("❌ Error classifying freshness: $e");
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

  String interpretFreshness(
      double confidence, String vqrLabel, AppLocalizations localizations) {
    final int vqr = int.tryParse(vqrLabel.replaceAll("VQR-", "")) ?? -1;

    if (vqr >= 8) {
      return localizations.getTranslation('freshness_excellent');
    } else if (vqr >= 6) {
      return localizations.getTranslation('freshness_good');
    } else if (vqr >= 4) {
      return localizations.getTranslation('freshness_fair');
    } else if (vqr == 3) {
      return localizations.getTranslation('rotten_spoiling');
    } else if (vqr >= 1) {
      return localizations.getTranslation('rotten');
    } else {
      return localizations.getTranslation('unknown_status');
    }
  }

  String getPredictionExplanation(String vqrLabel, double confidence,
      String label, AppLocalizations localizations) {
    final int vqr = int.tryParse(vqrLabel.replaceAll("VQR-", "")) ?? -1;
    final vegetable = label.toLowerCase();

    if (vegetable.contains('eggplant')) {
      if (vqr >= 8) {
        return localizations.getTranslation('explanation_eggplant_vqr_8');
      } else if (vqr >= 6) {
        return localizations.getTranslation('explanation_eggplant_vqr_6');
      } else if (vqr >= 4) {
        return localizations.getTranslation('explanation_eggplant_vqr_4');
      } else if (vqr == 3) {
        return localizations.getTranslation('explanation_eggplant_vqr_3');
      } else if (vqr >= 1) {
        return localizations.getTranslation('explanation_eggplant_vqr_1');
      }
    } else if (vegetable.contains('tomato')) {
      if (vqr >= 8) {
        return localizations.getTranslation('explanation_tomato_vqr_8');
      } else if (vqr >= 6) {
        return localizations.getTranslation('explanation_tomato_vqr_6');
      } else if (vqr >= 4) {
        return localizations.getTranslation('explanation_tomato_vqr_4');
      } else if (vqr == 3) {
        return localizations.getTranslation('explanation_tomato_vqr_3');
      } else if (vqr >= 1) {
        return localizations.getTranslation('explanation_tomato_vqr_1');
      }
    } else if (vegetable.contains('potato')) {
      if (vqr >= 8) {
        return localizations.getTranslation('explanation_potato_vqr_8');
      } else if (vqr >= 6) {
        return localizations.getTranslation('explanation_potato_vqr_6');
      } else if (vqr >= 4) {
        return localizations.getTranslation('explanation_potato_vqr_4');
      } else if (vqr == 3) {
        return localizations.getTranslation('explanation_potato_vqr_3');
      } else if (vqr >= 1) {
        return localizations.getTranslation('explanation_potato_vqr_1');
      }
    }

    return localizations.getTranslation('explanation_fallback');
  }

  Map<String, String> getShelfLifeAndRecommendation(
      String label, String vqrLabel, AppLocalizations localizations) {
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

    String shelfLife = localizations.getTranslation('shelf_life_unknown');
    String recommendation =
        localizations.getTranslation('recommendation_unknown');

    switch (matchedLabel) {
      case 'eggplant':
        if (effectiveVqr >= 8) {
          shelfLife = localizations.getTranslation('shelf_life_eggplant_vqr_8');
          recommendation =
              localizations.getTranslation('recommendation_eggplant_vqr_8');
        } else if (effectiveVqr >= 6) {
          shelfLife = localizations.getTranslation('shelf_life_eggplant_vqr_6');
          recommendation =
              localizations.getTranslation('recommendation_eggplant_vqr_6');
        } else if (effectiveVqr >= 4) {
          shelfLife = localizations.getTranslation('shelf_life_eggplant_vqr_4');
          recommendation =
              localizations.getTranslation('recommendation_eggplant_vqr_4');
        } else if (effectiveVqr == 3) {
          shelfLife = localizations.getTranslation('shelf_life_eggplant_vqr_3');
          recommendation =
              localizations.getTranslation('recommendation_eggplant_vqr_3');
        } else if (effectiveVqr == 2) {
          shelfLife = localizations.getTranslation('shelf_life_eggplant_vqr_2');
          recommendation =
              localizations.getTranslation('recommendation_eggplant_vqr_2');
        } else {
          shelfLife = localizations.getTranslation('shelf_life_eggplant_vqr_1');
          recommendation =
              localizations.getTranslation('recommendation_eggplant_vqr_1');
        }
        break;

      case 'tomato':
        if (effectiveVqr >= 8) {
          shelfLife = localizations.getTranslation('shelf_life_tomato_vqr_8');
          recommendation =
              localizations.getTranslation('recommendation_tomato_vqr_8');
        } else if (effectiveVqr >= 6) {
          shelfLife = localizations.getTranslation('shelf_life_tomato_vqr_6');
          recommendation =
              localizations.getTranslation('recommendation_tomato_vqr_6');
        } else if (effectiveVqr >= 4) {
          shelfLife = localizations.getTranslation('shelf_life_tomato_vqr_4');
          recommendation =
              localizations.getTranslation('recommendation_tomato_vqr_4');
        } else if (effectiveVqr == 3) {
          shelfLife = localizations.getTranslation('shelf_life_tomato_vqr_3');
          recommendation =
              localizations.getTranslation('recommendation_tomato_vqr_3');
        } else if (effectiveVqr == 2) {
          shelfLife = localizations.getTranslation('shelf_life_tomato_vqr_2');
          recommendation =
              localizations.getTranslation('recommendation_tomato_vqr_2');
        } else {
          shelfLife = localizations.getTranslation('shelf_life_tomato_vqr_1');
          recommendation =
              localizations.getTranslation('recommendation_tomato_vqr_1');
        }
        break;

      case 'potato':
        if (effectiveVqr >= 8) {
          shelfLife = localizations.getTranslation('shelf_life_potato_vqr_8');
          recommendation =
              localizations.getTranslation('recommendation_potato_vqr_8');
        } else if (effectiveVqr >= 6) {
          shelfLife = localizations.getTranslation('shelf_life_potato_vqr_6');
          recommendation =
              localizations.getTranslation('recommendation_potato_vqr_6');
        } else if (effectiveVqr >= 4) {
          shelfLife = localizations.getTranslation('shelf_life_potato_vqr_4');
          recommendation =
              localizations.getTranslation('recommendation_potato_vqr_4');
        } else if (effectiveVqr == 3) {
          shelfLife = localizations.getTranslation('shelf_life_potato_vqr_3');
          recommendation =
              localizations.getTranslation('recommendation_potato_vqr_3');
        } else if (effectiveVqr == 2) {
          shelfLife = localizations.getTranslation('shelf_life_potato_vqr_2');
          recommendation =
              localizations.getTranslation('recommendation_potato_vqr_2');
        } else {
          shelfLife = localizations.getTranslation('shelf_life_potato_vqr_1');
          recommendation =
              localizations.getTranslation('recommendation_potato_vqr_1');
        }
        break;

      default:
        shelfLife = localizations.getTranslation('shelf_life_unknown');
        recommendation = localizations.getTranslation('recommendation_unknown');
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

    // Calculate gradient magnitude
    double totalGradient = 0.0;
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
          .getTranslation('no_objects_detected')
          .replaceAll('{side}', localizedSide);
      return [
        {
          'object': 'None',
          'front': null,
          'back': null,
          'mergedFreshness':
              localizations.getTranslation('freshness_label_unknown'),
          'mergedStatus': localizations.getTranslation('scan error'),
          'mergedVQR': 'VQR-wastage',
          'mergedConfidence': 0.0,
          'error':
              '$errorMessage\n${localizations.getTranslation('no_valid_vegetable_detected')}',
        }
      ];
    }

    // Compare labels to ensure the same vegetable
    final frontLabelRaw = frontTop['label'].toString().toLowerCase().trim();
    final backLabelRaw = backTop['label'].toString().toLowerCase().trim();
    final frontLabel = localizations.getVegetableLabel(frontLabelRaw);
    final backLabel = localizations.getVegetableLabel(backLabelRaw);

    if (frontLabel != backLabel) {
      return [
        {
          'object': 'None',
          'front': null,
          'back': null,
          'mergedFreshness':
              localizations.getTranslation('freshness_label_unknown'),
          'mergedStatus':
              localizations.getTranslation('error_different_vegetables'),
          'mergedVQR': 'VQR-0',
          'mergedConfidence': 0.0,
          'error': localizations
              .getTranslation('different_vegetable_error')
              .replaceAll('{front}', frontLabel)
              .replaceAll('{back}', backLabel),
        }
      ];
    }

    final frontClassified = await classifyDetection(
      imageBytes: frontImage,
      detection: frontTop,
      localizations: localizations,
    );

    final backClassified = await classifyDetection(
      imageBytes: backImage,
      detection: backTop,
      localizations: localizations,
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
      avgConf = (frontConf + backConf) / 2;
    } else if (frontConf >= threshold) {
      mergedVQRNum = frontVQRNum;
      avgConf = frontConf;
    } else if (backConf >= threshold) {
      mergedVQRNum = backVQRNum;
      avgConf = backConf;
    } else {
      mergedVQRNum = ((frontVQRNum + backVQRNum) / 2).round();
      avgConf = (frontConf + backConf) / 2;
    }

    final mergedVQR = "VQR-$mergedVQRNum";
    final mergedFreshness = getFreshnessLabel(mergedVQR, localizations);
    final mergedStatus = interpretFreshness(avgConf, mergedVQR, localizations);
    final mergedExplanation = getPredictionExplanation(
      mergedVQR,
      avgConf,
      frontClassified['object'],
      localizations,
    );
    final shelfLifeAndRecommendation = getShelfLifeAndRecommendation(
      frontClassified['object'],
      mergedVQR,
      localizations,
    );

    // Check image quality
    final frontBrightness = _calculateAverageBrightness(frontImage);
    final backBrightness = _calculateAverageBrightness(backImage);
    final frontBlur = _calculateBlurVariance(frontImage);
    final backBlur = _calculateBlurVariance(backImage);

    final List<String> imageIssues = [];
    if (frontBrightness < 50 || backBrightness < 50) {
      imageIssues.add(localizations.getTranslation('image_too_dark'));
    } else if (frontBrightness > 200 || backBrightness > 200) {
      imageIssues.add(localizations.getTranslation('image_too_bright'));
    }
    if (frontBlur < 2.0 || backBlur < 2.0) {
      imageIssues.add(localizations.getTranslation('image_too_blurry'));
    }

    final Map<String, dynamic> result = {
      'object': frontClassified['object'],
      'front': frontClassified,
      'back': backClassified,
      'mergedFreshness': mergedFreshness,
      'mergedStatus': mergedStatus,
      'mergedVQR': mergedVQR,
      'mergedConfidence': avgConf,
      'explanation': mergedExplanation,
      'shelfLife': shelfLifeAndRecommendation['shelfLife'],
      'recommendation': shelfLifeAndRecommendation['recommendation'],
      'imageIssues': imageIssues,
    };

    return [result];
  }

  void close() {
    if (_modelsLoaded) {
      try {
        _flutterVision.closeYoloModel();
        _efficientNetInterpreter.close();
        _modelsLoaded = false;
        log("✅ Model resources released successfully");
      } catch (e) {
        log("❌ Error closing models: $e");
      }
    }
  }
}
