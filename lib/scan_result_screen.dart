import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _isLoading = true;
  double _imageWidth = 640;
  double _imageHeight = 640;

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

      final image = File(widget.imagePath);
      final decodedImage = await decodeImageFromList(image.readAsBytesSync());

      _imageWidth = decodedImage.width.toDouble();
      _imageHeight = decodedImage.height.toDouble();

      final yoloResults = await _modelService.detectObjects(imageBytes);
      if (yoloResults.isEmpty) {
        log("⚠️ No objects detected.");
        setState(() {
          _detectedObjects = [];
          _isLoading = false;
        });
        return;
      }

      List<Map<String, dynamic>> classifiedResults = [];

      for (var detected in yoloResults) {
        final croppedImage =
            _modelService.cropObject(imageBytes, detected['bbox']);
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
                      aspectRatio: _imageWidth / _imageHeight,
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
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            if (_detectedObjects.isNotEmpty)
                              ..._detectedObjects.map((detected) {
                                final bbox = detected['bbox'];

                                final double xMinScaled =
                                    (bbox[0] / 640) * _imageWidth;
                                final double yMinScaled =
                                    (bbox[1] / 640) * _imageHeight;
                                final double boxWidthScaled =
                                    ((bbox[2] - bbox[0]) / 640) * _imageWidth;
                                final double boxHeightScaled =
                                    ((bbox[3] - bbox[1]) / 640) * _imageHeight;

                                log("🟢 Bounding Box for ${detected['label']}: xMin=$xMinScaled, yMin=$yMinScaled, width=$boxWidthScaled, height=$boxHeightScaled");

                                return Positioned(
                                  left: xMinScaled,
                                  top: yMinScaled,
                                  width: boxWidthScaled,
                                  height: boxHeightScaled,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.red, width: 2),
                                    ),
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Container(
                                        color: Colors.red.withOpacity(0.7),
                                        padding: const EdgeInsets.all(2),
                                        child: Text(
                                          '${detected['label']} (${detected['freshness']})',
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
}
