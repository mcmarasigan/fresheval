import 'dart:typed_data';
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

  Future<void> loadModels() async {
    try {
      _flutterVision = FlutterVision();

      _yoloLabels = await _loadLabels("assets/yolov8_label.txt");
      _efficientNetLabels =
          await _loadLabels("assets/efficientnetb7_label.txt");

      // Load YOLOv8 model using Flutter Vision
      await _flutterVision.loadYoloModel(
        modelPath: "assets/yolov8_best.tflite",
        labels: "assets/yolov8_label.txt",
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
      );

      // Load EfficientNetB7 model using TFLite
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

  /// **🔥 Runs YOLOv8 object detection**
 Future<Map<String, dynamic>?> detectObject(Uint8List imageBytes) async {
    if (!_modelsLoaded) {
      log("⚠️ Models not loaded yet.");
      return null;
    }

    try {
      final detections = await _flutterVision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: 640,
        imageWidth: 640,
        iouThreshold: 0.3,
        confThreshold: 0.5,
      );

      log("🔍 YOLOv8 Raw Detections: $detections");

      if (detections.isEmpty) {
        log("⚠️ No objects detected.");
        return null;
      }

      // 🔥 Find the best detection (highest confidence)
      var bestDetection = detections.reduce((a, b) {
        double confidenceA = (a["box"] as List).last ?? 0.0;
        double confidenceB = (b["box"] as List).last ?? 0.0;
        return confidenceA > confidenceB ? a : b;
      });

      List bbox = bestDetection['box'];

      // 🔥 Extract confidence from the correct position in the "box" list
      double confidence = (bbox.last as double) * 100;

      if (bbox.length < 4) {
        log("⚠️ Invalid bounding box data: $bbox");
        return null;
      }

      log("✅ Final Confidence Extracted: $confidence%");

      return {
        'label': bestDetection['tag'],
        'confidence': confidence, // 🔥 Now correctly extracted!
        'bbox': bbox.sublist(0, 4), // 🔥 Only first 4 values are bbox
      };
    } catch (e) {
      log("⚠️ Error during YOLO inference: $e");
      return null;
    }
  }


  /// **🔥 Runs EfficientNetB7 classification (Using TFLite)**
  Future<Map<String, dynamic>> classifyFreshness(Uint8List croppedImage) async {
    if (!_modelsLoaded) {
      log("⚠️ Models not loaded yet.");
      return {'label': 'Unknown', 'confidence': 0.0};
    }

    try {
      final input = preprocessImageForEfficientNet(croppedImage, 224, 224);
      final outputShape = _efficientNetInterpreter.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape([1, outputShape[1]]);

      _efficientNetInterpreter.run(input, output);
      final predictions = List<double>.from(output[0]);
      final softmaxScores = softmax(predictions);
      final predictedIndex = softmaxScores.indexWhere(
        (val) => val == softmaxScores.reduce(math.max),
      );

      return {
        'label': _efficientNetLabels[predictedIndex],
        'confidence': softmaxScores[predictedIndex] * 100,
      };
    } catch (e) {
      log("⚠️ Error during EfficientNet classification: $e");
      return {'label': 'Unknown', 'confidence': 0.0};
    }
  }

  /// **🔥 Crop detected object correctly**
  Uint8List cropObject(Uint8List imageBytes, List bbox) {
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception("Failed to decode image.");

    double scaleX = originalImage.width / 640.0;
    double scaleY = originalImage.height / 640.0;

    double xMin = bbox[0] * scaleX;
    double yMin = bbox[1] * scaleY;
    double xMax = bbox[2] * scaleX;
    double yMax = bbox[3] * scaleY;

    int cropX = xMin.round();
    int cropY = yMin.round();
    int cropW = (xMax - xMin).round();
    int cropH = (yMax - yMin).round();

    final img.Image cropped =
        img.copyCrop(originalImage, cropX, cropY, cropW, cropH);

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
  }

  /// **🔥 Preprocess Image for EfficientNet**
  List<List<List<List<double>>>> preprocessImageForEfficientNet(
      Uint8List imageBytes, int height, int width) {
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception("Failed to decode image.");

    final img.Image resizedImage =
        img.copyResize(originalImage, width: width, height: height);

    return [
      List.generate(height, (y) {
        return List.generate(width, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            ((pixel >> 16) & 0xFF) / 127.5 - 1.0,
            ((pixel >> 8) & 0xFF) / 127.5 - 1.0,
            (pixel & 0xFF) / 127.5 - 1.0,
          ];
        });
      })
    ];
  }

  List<double> softmax(List<double> scores) {
    final expScores = scores.map(math.exp).toList();
    final sumExpScores = expScores.reduce((a, b) => a + b);
    return expScores.map((score) => score / sumExpScores).toList();
  }

  void close() {
    _flutterVision.closeYoloModel();
    _efficientNetInterpreter.close();
  }
}
