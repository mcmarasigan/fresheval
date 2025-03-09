import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:path_provider/path_provider.dart';
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

  /// **🔥 Runs YOLOv8 object detection**
  Future<List<Map<String, dynamic>>> detectObjects(
      Uint8List imageBytes, double imageWidth, double imageHeight) async {
    if (!_modelsLoaded) {
      log("⚠️ Models not loaded yet.");
      return [];
    }

    try {
      final detections = await _flutterVision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: 640, // YOLOv8 expects 640x640
        imageWidth: 640,
        iouThreshold: 0.3,
        confThreshold: 0.5,
      );

      log("🔍 YOLOv8 Raw Detections: $detections");

      if (detections.isEmpty) {
        log("⚠️ No objects detected.");
        return [];
      }

      List<Map<String, dynamic>> detectedObjects = [];

      for (var detection in detections) {
        List bbox = detection['box'];
        if (bbox.length < 5) continue;

        // Convert YOLO format [x_center, y_center, width, height] to [x_min, y_min, x_max, y_max]
        double xCenter = bbox[0];
        double yCenter = bbox[1];
        double boxWidth = bbox[2];
        double boxHeight = bbox[3];

        double xMin = xCenter - (boxWidth / 2);
        double yMin = yCenter - (boxHeight / 2);
        double xMax = xCenter + (boxWidth / 2);
        double yMax = yCenter + (boxHeight / 2);

        // ✅ Corrected: Scale bounding box to match actual image size
        double scaleX = imageWidth / 640.0; // Scale factor for width
        double scaleY = imageHeight / 640.0; // Scale factor for height

        xMin *= scaleX;
        yMin *= scaleY;
        xMax *= scaleX;
        yMax *= scaleY;

        // ✅ Ensure bounding box stays within image boundaries
        xMin = xMin.clamp(0, imageWidth);
        yMin = yMin.clamp(0, imageHeight);
        xMax = xMax.clamp(0, imageWidth);
        yMax = yMax.clamp(0, imageHeight);

        double confidence = bbox[4] * 100;

        log("✅ Detected ${detection['tag']} - Bounding Box: [$xMin, $yMin, $xMax, $yMax]");

        detectedObjects.add({
          'label': detection['tag'],
          'confidence': confidence,
          'bbox': [xMin, yMin, xMax, yMax], // ✅ Correct scaling applied
        });
      }

      return detectedObjects;
    } catch (e) {
      log("⚠️ Error during YOLO inference: $e");
      return [];
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



  /// **🔥 Crop detected object correctly and resize for EfficientNetB7**
  Uint8List cropObject(
      Uint8List imageBytes, List bbox, double imageWidth, double imageHeight) {
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception("Failed to decode image.");

    // ✅ Use the bounding box directly (Already Scaled in `detectObjects`)
    double xMin = bbox[0];
    double yMin = bbox[1];
    double xMax = bbox[2];
    double yMax = bbox[3];

    // ✅ Convert to integer values for cropping
    int cropX = xMin.round();
    int cropY = yMin.round();
    int cropW = (xMax - xMin).round();
    int cropH = (yMax - yMin).round();

    // ✅ Ensure bounding box doesn't exceed image boundaries
    cropX = cropX.clamp(0, originalImage.width - 1);
    cropY = cropY.clamp(0, originalImage.height - 1);
    cropW = cropW.clamp(1, originalImage.width - cropX);
    cropH = cropH.clamp(1, originalImage.height - cropY);

    // 🟢 Debug Log: Check if values are correct before cropping
    log("🔍 Cropping Region - X: $cropX, Y: $cropY, Width: $cropW, Height: $cropH");

    // ✅ Perform cropping
    final img.Image cropped =
        img.copyCrop(originalImage, cropX, cropY, cropW, cropH);

    // ✅ Resize cropped image to 224x224 for EfficientNetB7
    final img.Image resizedCropped =
        img.copyResize(cropped, width: 224, height: 224);

    // ✅ Convert image back to Uint8List format
    Uint8List croppedBytes =
        Uint8List.fromList(img.encodeJpg(resizedCropped, quality: 85));

    // 🔥 Save cropped image for debugging
    _saveCroppedImage(croppedBytes, "cropped_debug");

    return croppedBytes;
  }



  /// **🔥 Save Cropped Image for Debugging in Writable Directory**
  Future<void> _saveCroppedImage(Uint8List imageBytes, String label) async {
    try {
      // ✅ Save images inside the "Downloads" folder for easy access
      String directoryPath = "/storage/emulated/0/Download/fresheval_cropped";

      Directory directory = Directory(directoryPath);

      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      String filePath =
          '$directoryPath/${label}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      log("📸 Cropped Image Saved (External Storage): $filePath");
    } catch (e) {
      log("⚠️ Error saving cropped image to external storage: $e");
    }
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
          final int pixel =
              resizedImage.getPixel(x, y); // Get the pixel integer

          final int r = (pixel >> 16) & 0xFF; // Extract Red
          final int g = (pixel >> 8) & 0xFF; // Extract Green
          final int b = pixel & 0xFF; // Extract Blue

          return [
            (r / 127.5) - 1.0, // Normalize R
            (g / 127.5) - 1.0, // Normalize G
            (b / 127.5) - 1.0, // Normalize B
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
