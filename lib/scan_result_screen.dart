import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'model_service.dart';

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
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _isLoading = true;
  final double _imageSize = 640; // Force 1:1 aspect ratio for YOLOv8

  @override
  void initState() {
    super.initState();
    _modelService = ModelService();
    _runInference();
  }

  Future<void> _runInference() async {
    try {
      log("🟢 Starting model inference...");

      await _modelService.loadModels();
      final imageBytes = await File(widget.imagePath).readAsBytes();

      log("📸 Image successfully loaded: ${widget.imagePath}");

      final yoloResults =
          await _modelService.detectObjects(imageBytes, _imageSize, _imageSize);

      log("🟡 YOLO Detection Results: $yoloResults");

      List<Map<String, dynamic>> classifiedResults = [];

      for (var detected in yoloResults) {
        log("🟢 Detected: ${detected['label']} - Confidence: ${detected['confidence']}");

        final croppedImage = _modelService.cropObject(
            imageBytes, detected['bbox'], _imageSize, _imageSize);

        final freshnessResult =
            await _modelService.classifyFreshness(croppedImage);

        log("✅ ${detected['label']} - Classified as ${freshnessResult['label']} with ${freshnessResult['confidence']}% confidence");

        classifiedResults.add({
          'label': detected['label'],
          'confidence': detected['confidence'],
          'bbox': detected['bbox'],
          'freshness': freshnessResult['label'],
          'freshnessConfidence': freshnessResult['confidence'],
        });
      }

      setState(() {
        _detectedObjects = classifiedResults;
        _isLoading = false;
      });
    } catch (e) {
      log("⚠️ Error during inference: $e");
      setState(() {
        _isLoading = false;
        _detectedObjects = [];
      });
    }
  }

  Future<void> _saveScanResult() async {
    if (_detectedObjects.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final scanData = prefs.getStringList('recent_scans') ?? [];

    for (var detected in _detectedObjects) {
      final newScan = json.encode({
        'imagePath': widget.imagePath,
        'name': detected['label'],
        'confidence': detected['confidence'],
        'freshness': detected['freshness'],
        'freshnessConfidence': detected['freshnessConfidence'],
        'timestamp': DateTime.now().toString(),
      });

      scanData.add(newScan);
    }

    await prefs.setStringList('recent_scans', scanData);
    _showSaveDialog();
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Successful'),
        content: const Text('Scan results have been saved successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Results')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(widget.imagePath),
                                fit: BoxFit.cover,
                                width: 640,
                                height: 640,
                              ),
                            ),
                            if (_detectedObjects.isNotEmpty)
                              ..._detectedObjects.map((detected) {
                                final bbox = detected['bbox'];

                                final double scaleFactor =
                                    MediaQuery.of(context).size.width /
                                        _imageSize;

                                final double xMin = bbox[0] * scaleFactor;
                                final double yMin = bbox[1] * scaleFactor;
                                final double boxWidth =
                                    (bbox[2] - bbox[0]) * scaleFactor;
                                final double boxHeight =
                                    (bbox[3] - bbox[1]) * scaleFactor;

                                Color boxColor =
                                    _getBoxColor(detected['label']);

                                log("🟢 Bounding Box for ${detected['label']}: xMin=$xMin, yMin=$yMin, width=$boxWidth, height=$boxHeight");

                                return Positioned(
                                  left: xMin,
                                  top: yMin,
                                  child: Container(
                                    width: boxWidth,
                                    height: boxHeight,
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: boxColor, width: 2),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        color: boxColor.withOpacity(0.7),
                                        padding: const EdgeInsets.all(2),
                                        child: Text(
                                          '${detected['label']} (${detected['confidence'].toStringAsFixed(2)}%)',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: _detectedObjects
                          .map((detected) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  "Object: ${detected['label']}\n"
                                  "Detection Confidence: ${detected['confidence'].toStringAsFixed(2)}%\n"
                                  "Freshness: ${detected['freshness']}\n"
                                  "Freshness Confidence: ${detected['freshnessConfidence'].toStringAsFixed(2)}%",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _saveScanResult,
                      child: const Text('Save'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Retake'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Color _getBoxColor(String label) {
    switch (label.toLowerCase()) {
      case 'tomato':
        return Colors.red;
      case 'eggplant':
        return Colors.purple;
      case 'potato':
        return const Color(0xFFC4A484);
      default:
        return Colors.blue;
    }
  }
}
