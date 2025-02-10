import 'dart:io';
import 'package:flutter/material.dart';
import 'model_service.dart';
import 'dart:developer';

class ScanResultScreen extends StatefulWidget {
  final String imagePath;
  final bool isUploadedImage;

  const ScanResultScreen({
    Key? key,
    required this.imagePath,
    required this.isUploadedImage,
  }) : super(key: key);

  @override
  _ScanResultScreenState createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late ModelService _modelService;
  Map<String, dynamic>? _detectedObject;
  Map<String, dynamic>? _classification;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _modelService = ModelService();
    _runInference();
  }

  Future<void> _runInference() async {
    try {
      await _modelService.loadModels();
      final imageBytes = await File(widget.imagePath).readAsBytes();

      // Step 1: Detect object using YOLOv8.
      final yoloResult = _modelService.detectObject(imageBytes);
      if (yoloResult == null) {
        log("No object detected.");
        setState(() {
          _detectedObject = null;
          _classification = null;
          _isLoading = false;
        });
        return;
      }

      final detectedLabel = yoloResult['label'];
      final detectionConfidence = yoloResult['confidence']; // Already in percentage.
      final bbox = yoloResult['bbox'];

      log("YOLOv8 Detection - Label: $detectedLabel, Confidence: $detectionConfidence%");
      log("Bounding Box: $bbox");

      // Step 2: Crop the detected object from the original image.
      final croppedImage = _modelService.cropObject(imageBytes, bbox);
      // Step 3: Classify freshness using EfficientNetB7.
      final freshnessResult = _modelService.classifyFreshness(croppedImage);
      final freshnessLabel = freshnessResult['label'];
      final freshnessConfidence = freshnessResult['confidence'];

      log("EfficientNet Classification - Label: $freshnessLabel, Confidence: $freshnessConfidence%");

      setState(() {
        _detectedObject = {
          'label': detectedLabel,
          'confidence': detectionConfidence,
          'bbox': bbox,
        };
        _classification = freshnessResult;
        _isLoading = false;
      });
    } catch (e) {
      log("Error during inference: $e");
      setState(() {
        _isLoading = false;
        _detectedObject = null;
        _classification = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        leading: const BackButton(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Display the original image.
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          // Overlay the detection bounding box and label.
                          if (_detectedObject != null)
                            LayoutBuilder(builder: (context, constraints) {
                              // Scale bounding box from 224 to the displayed size.
                              final double scaleX = constraints.maxWidth / 224;
                              final double scaleY = constraints.maxHeight / 224;
                              final bbox = _detectedObject!['bbox'];
                              final double xMin = bbox[0] * scaleX;
                              final double yMin = bbox[1] * scaleY;
                              final double boxWidth = (bbox[2] - bbox[0]) * scaleX;
                              final double boxHeight = (bbox[3] - bbox[1]) * scaleY;

                              return Positioned(
                                left: xMin,
                                top: yMin,
                                width: boxWidth,
                                height: boxHeight,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 2),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Text(
                                      '${_detectedObject!['label']} (${_classification?['label'] ?? 'Unknown'})',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _detectedObject != null
                        ? "Object: ${_detectedObject!['label']}\n"
                          "Detection Confidence: ${(_detectedObject!['confidence']).toStringAsFixed(2)}%\n"
                          "Freshness: ${_classification?['label'] ?? 'Unknown'}\n"
                          "Freshness Confidence: ${(_classification?['confidence'] ?? 0.0).toStringAsFixed(2)}%"
                        : "No object detected",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Retake Scan',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
