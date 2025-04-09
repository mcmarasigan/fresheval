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
    Uint8List imageBytes,
    double imageWidth,
    double imageHeight,
  ) async {
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
      if (confidence >= 80.0) return "Still Fresh";
      if (confidence >= 40.0) return "Fresh but Near Spoiling";
      return "May Be Spoiling Soon";
    } else {
      if (confidence >= 80.0) return "Definitely Rotten";
      if (confidence >= 40.0) return "Likely Rotten";
      return "Possibly Rotten";
    }
  }

 String getPredictionExplanation(String label, double confidence) {
    final isFresh = label.toLowerCase() == "fresh";

    if (isFresh) {
      if (confidence >= 80.0) {
        return "The produce appears vibrant and firm, indicating it's still in great condition.";
      } else if (confidence >= 40.0) {
        return "Some softness or dullness is visible. Consume soon before it starts to spoil.";
      } else {
        return "There are early signs of spoilage despite being categorized as fresh. Use caution.";
      }
    } else {
      if (confidence >= 80.0) {
        return "Strong visual cues like mold, wrinkles, or decay suggest it's spoiled.";
      } else if (confidence >= 40.0) {
        return "Possible spoilage signs like soft areas, bruises, or slight discoloration.";
      } else {
        return "Minor hints of spoilage detected. It may still be usable, but check manually.";
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
        if (interpretation.contains('Still Fresh')) {
          shelfLife = '4–7 days at room temp, up to 2 weeks in the fridge';
          recommendation =
              'Store at room temperature to ripen. Refrigerate once ripe. Great for salads or sauces.';
        } else if (interpretation.contains('Fresh but Near')) {
          shelfLife = '1–3 days (approaching spoilage)';
          recommendation = 'Use soon. Check for soft spots or dullness.';
        } else if (interpretation.contains('Likely Rotten')) {
          shelfLife = 'Possibly spoiled';
          recommendation = 'Inspect for softness or smell before use.';
        } else {
          shelfLife = '0 days';
          recommendation = 'Discard. Likely spoiled or unsafe to eat.';
        }
        break;

      case 'eggplant':
        if (interpretation.contains('Still Fresh')) {
          shelfLife = '3–5 days in the fridge';
          recommendation = 'Keep in crisper. Avoid washing until use.';
        } else if (interpretation.contains('Fresh but Near')) {
          shelfLife = '1–2 days';
          recommendation = 'Use quickly. Softness may be starting.';
        } else if (interpretation.contains('Likely Rotten')) {
          shelfLife = 'Possibly spoiled';
          recommendation = 'Check for wrinkles, softness, or spots.';
        } else {
          shelfLife = '0 days';
          recommendation = 'Not safe to eat. Discard.';
        }
        break;

      case 'potato':
        if (interpretation.contains('Still Fresh')) {
          shelfLife = '1–2 months (cool, dark place)';
          recommendation = 'Store in a paper bag. Avoid refrigeration.';
        } else if (interpretation.contains('Fresh but Near')) {
          shelfLife = '1–2 weeks';
          recommendation = 'Use soon. Watch for sprouting or softness.';
        } else if (interpretation.contains('Likely Rotten')) {
          shelfLife = 'Likely spoiled';
          recommendation = 'Discard if green, soft, or with foul smell.';
        } else {
          shelfLife = '0 days';
          recommendation = 'Toxic risk (green or sprouted). Discard.';
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
  }
}
