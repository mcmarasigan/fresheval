import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'dart:developer';
import 'dart:math' as math;

class ModelService {
  late Interpreter _yoloInterpreter;
  late Interpreter _efficientNetInterpreter;
  late List<String> _yoloLabels;
  late List<String> _efficientNetLabels;

  Future<void> loadModels() async {
    try {
      // Load YOLOv8 model and labels
      _yoloInterpreter =
          await Interpreter.fromAsset('assets/yolov8_best.tflite');
      _yoloLabels = (await rootBundle.loadString('assets/yolov8_label.txt'))
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();

      // Load EfficientNetB7 model and labels
      _efficientNetInterpreter =
          await Interpreter.fromAsset('assets/efficientnetb7_fixed.tflite');
      _efficientNetLabels = ['Fresh', 'Rotten'];

      log("Models loaded successfully.");
    } catch (e) {
      log("Error loading models: $e");
    }
  }

  double sigmoid(double x) => 1 / (1 + math.exp(-x));

  /// YOLOv8 Object Detection
  Map<String, dynamic>? detectObject(Uint8List imageBytes) {
    try {
      final inputShape = _yoloInterpreter.getInputTensor(0).shape; // [1, 640, 640, 3]
      final outputShape = _yoloInterpreter.getOutputTensor(0).shape;

      // Preprocess the image to 640x640
      final input = preprocessImage(imageBytes, 640, 640);

      // Create output buffer
      final output = List.filled(
          outputShape.reduce((a, b) => a * b), 0.0).reshape([1, outputShape[1], outputShape[2]]);

      _yoloInterpreter.run(input, output);
      final detections = output[0];

      for (var detection in detections) {
        double objectness = sigmoid(detection[4]);
        if (objectness > 0.5) { // Confidence threshold
          final double cx = detection[0] * 640;
          final double cy = detection[1] * 640;
          final double w = detection[2] * 640;
          final double h = detection[3] * 640;

          final double xMin = cx - w / 2;
          final double yMin = cy - h / 2;
          final double xMax = cx + w / 2;
          final double yMax = cy + h / 2;

          final bbox = [xMin, yMin, xMax, yMax];
          final classLogits = detection.sublist(5, 5 + _yoloLabels.length);
          final classProbabilities = softmax(classLogits);
          final labelIndex = classProbabilities.indexWhere(
              (val) => val == classProbabilities.reduce(math.max));

          return {
            'label': _yoloLabels[labelIndex],
            'confidence': objectness * 100,
            'bbox': bbox,
          };
        }
      }
      return null;
    } catch (e) {
      log("Error during YOLO inference: $e");
      return null;
    }
  }

  /// EfficientNetB7 Freshness Classification
  Map<String, dynamic> classifyFreshness(Uint8List croppedImage) {
    try {
      final inputShape = _efficientNetInterpreter.getInputTensor(0).shape; // [1, 224, 224, 3]
      final outputShape = _efficientNetInterpreter.getOutputTensor(0).shape;

      final input = preprocessImage(croppedImage, 224, 224);
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
          .reshape([1, outputShape[1]]);

      _efficientNetInterpreter.run(input, output);
      final predictions = List<double>.from(output[0]);
      final softmaxScores = softmax(predictions);
      final predictedIndex = softmaxScores.indexWhere(
          (val) => val == softmaxScores.reduce(math.max));

      return {
        'label': _efficientNetLabels[predictedIndex],
        'confidence': softmaxScores[predictedIndex] * 100,
      };
    } catch (e) {
      log("Error during EfficientNet inference: $e");
      return {'label': 'Unknown', 'confidence': 0.0};
    }
  }

  /// Preprocess the image
  List preprocessImage(Uint8List imageBytes, int height, int width) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception("Failed to decode image.");
    final img.Image resizedImage = img.copyResize(image, width: width, height: height);
    return [
      List.generate(height, (y) {
        return List.generate(width, (x) {
          final pixel = resizedImage.getPixel(x, y);
          final red = ((pixel >> 16) & 0xFF) / 255.0;
          final green = ((pixel >> 8) & 0xFF) / 255.0;
          final blue = (pixel & 0xFF) / 255.0;
          return [red, green, blue];
        });
      })
    ];
  }

  /// Crop the detected object
  Uint8List cropObject(Uint8List imageBytes, List bbox) {
    final img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception("Failed to decode image.");

    final xMin = bbox[0].toInt();
    final yMin = bbox[1].toInt();
    final width = (bbox[2] - bbox[0]).toInt();
    final height = (bbox[3] - bbox[1]).toInt();

    final img.Image cropped = img.copyCrop(image, xMin, yMin, width, height);
    return Uint8List.fromList(img.encodeJpg(cropped));
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
