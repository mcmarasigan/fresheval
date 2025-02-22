import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:developer';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:convert';

class ModelService {
  late Interpreter _yoloInterpreter;
  late Interpreter _efficientNetInterpreter;
  late List<String> _yoloLabels;
  late List<String> _efficientNetLabels;
  bool _modelsLoaded = false;

  Future<void> loadModels() async {
    try {
      // Load YOLO labels from assets/yolov8_label.txt
      _yoloLabels = await _loadLabels("assets/yolov8_label.txt");

      // Load EfficientNet labels from assets/efficientnetb7_label.txt
      _efficientNetLabels =
          await _loadLabels("assets/efficientnetb7_label.txt");

      // Load YOLO model
      _yoloInterpreter = await Interpreter.fromAsset(
        'assets/yolov8_best.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      // Load EfficientNet model
      _efficientNetInterpreter = await Interpreter.fromAsset(
        'assets/efficientnetb7_fixed.tflite',
        options: InterpreterOptions()..threads = 2,
      );

      _modelsLoaded = true;
      log("✅ Models loaded successfully.");
    } catch (e) {
      log("⚠️ Error loading models: $e");
    }
  }

  /// Load labels from .txt file
  Future<List<String>> _loadLabels(String assetPath) async {
    try {
      String labelsString = await rootBundle.loadString(assetPath);
      return LineSplitter.split(labelsString).toList();
    } catch (e) {
      log("⚠️ Error loading labels from $assetPath: $e");
      return [];
    }
  }

  double sigmoid(double x) => 1 / (1 + math.exp(-x));

  Future<Map<String, dynamic>?> detectObject(Uint8List imageBytes) async {
    if (!_modelsLoaded) {
      log("⚠️ Models not loaded yet.");
      return null;
    }

    return await Isolate.run(() {
      try {
        final img.Image? originalImage = img.decodeImage(imageBytes);
        if (originalImage == null) throw Exception("Failed to decode image.");

        final input = preprocessImage(imageBytes, 416, 416);
        final outputShape = _yoloInterpreter.getOutputTensor(0).shape;
        final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
            .reshape([1, outputShape[1], outputShape[2]]);

        _yoloInterpreter.run(input, output);
        final detections = output[0];

        double maxConfidence = 0;
        Map<String, dynamic>? bestDetection;

        for (var detection in detections) {
          double objectness = sigmoid(detection[4]);

          if (objectness >= 0.4) {
            // Adjusted threshold for better detections
            double cx = detection[0] * originalImage.width;
            double cy = detection[1] * originalImage.height;
            double w = detection[2] * originalImage.width;
            double h = detection[3] * originalImage.height;

            double xMin =
                (cx - w / 2).clamp(0.0, originalImage.width.toDouble());
            double yMin =
                (cy - h / 2).clamp(0.0, originalImage.height.toDouble());
            double xMax =
                (cx + w / 2).clamp(0.0, originalImage.width.toDouble());
            double yMax =
                (cy + h / 2).clamp(0.0, originalImage.height.toDouble());

            final bbox = [xMin, yMin, xMax, yMax];

            final classLogits = detection.sublist(5, 5 + _yoloLabels.length);
            final classProbabilities = softmax(classLogits);
            final labelIndex = classProbabilities.indexWhere(
                (val) => val == classProbabilities.reduce(math.max));

            final confidence = objectness * classProbabilities[labelIndex];

            if (confidence > maxConfidence) {
              maxConfidence = confidence;
              bestDetection = {
                'label': _yoloLabels[labelIndex],
                'confidence': confidence * 100,
                'bbox': bbox,
              };
            }

            log("✅ Detection - Label: ${_yoloLabels[labelIndex]}, Confidence: ${confidence * 100}%");
            log("✅ Bounding Box: $bbox");
          }
        }
        return bestDetection;
      } catch (e) {
        log("⚠️ Error during YOLO inference: $e");
        return null;
      }
    });
  }

  /// **Classify Freshness Using EfficientNetB7**
  Future<Map<String, dynamic>> classifyFreshness(Uint8List croppedImage) async {
    return await Isolate.run(() {
      try {
        final inputShape = _efficientNetInterpreter.getInputTensor(0).shape;
        final outputShape = _efficientNetInterpreter.getOutputTensor(0).shape;

        final input = preprocessImage(croppedImage, 224, 224);
        final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
            .reshape([1, outputShape[1]]);

        _efficientNetInterpreter.run(input, output);
        final predictions = List<double>.from(output[0]);
        final softmaxScores = softmax(predictions);
        final predictedIndex = softmaxScores
            .indexWhere((val) => val == softmaxScores.reduce(math.max));

        return {
          'label': _efficientNetLabels[predictedIndex],
          'confidence': softmaxScores[predictedIndex] * 100,
        };
      } catch (e) {
        log("⚠️ Error during EfficientNet inference: $e");
        return {'label': 'Unknown', 'confidence': 0.0};
      }
    });
  }

  Uint8List cropObject(Uint8List imageBytes, List bbox) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception("Failed to decode image.");

    final xMin = bbox[0].toInt();
    final yMin = bbox[1].toInt();
    final width = (bbox[2] - bbox[0]).toInt();
    final height = (bbox[3] - bbox[1]).toInt();

    final img.Image cropped = img.copyCrop(
      image,
      xMin,
      yMin,
      width,
      height,
    );

    return Uint8List.fromList(img.encodeJpg(cropped, quality: 85));
  }

  List preprocessImage(
      Uint8List imageBytes, int targetHeight, int targetWidth) {
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception("Failed to decode image.");

    final img.Image resizedImage = img.copyResize(
      originalImage,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    final List<List<List<double>>> processed = List.generate(
      targetHeight,
      (y) => List.generate(
        targetWidth,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            ((pixel >> 16) & 0xFF) / 255.0,
            ((pixel >> 8) & 0xFF) / 255.0,
            (pixel & 0xFF) / 255.0
          ];
        },
      ),
    );

    return [processed];
  }

  List<double> softmax(List<double> scores) {
    final expScores = scores.map((score) => math.exp(score)).toList();
    final sumExpScores = expScores.reduce((a, b) => a + b);
    return expScores.map((score) => score / sumExpScores).toList();
  }

  void close() {
    _yoloInterpreter.close();
    _efficientNetInterpreter.close();
  }
}
