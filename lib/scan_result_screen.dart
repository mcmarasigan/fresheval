import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'model_service.dart';

class ScanResultScreen extends StatefulWidget {
  final String imagePath;
  final bool isUploadedImage;
  final Function(String imagePath, String name)? onSave;

  const ScanResultScreen({
    super.key,
    required this.imagePath,
    required this.isUploadedImage,
    this.onSave,
  });

  @override
  _ScanResultScreenState createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late ModelService _modelService;
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _isLoading = true;
  final double _imageSize = 640; // YOLOv8 input size

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
          'originalWidth': detected['originalWidth'],
          'originalHeight': detected['originalHeight'],
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

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String formattedTime = DateFormat.jm().format(now);

    final newScan = json.encode({
      'imagePath': widget.imagePath,
      'objects': _detectedObjects
          .map((obj) => {
                'label': obj['label'],
                'confidence': obj['confidence'].toStringAsFixed(2),
                'freshness': obj['freshness'],
                'freshnessConfidence':
                    obj['freshnessConfidence'].toStringAsFixed(2),
              })
          .toList(),
      'date': formattedDate,
      'time': formattedTime,
    });

    scanData.removeWhere((scan) {
      final decoded = json.decode(scan);
      return decoded['imagePath'] == widget.imagePath;
    });

    scanData.add(newScan);
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
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final double displaySize = constraints.maxWidth;
                          return Container(
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
                                    width: displaySize,
                                    height: displaySize,
                                  ),
                                ),
                                if (_detectedObjects.isNotEmpty)
                                  ..._detectedObjects.map((detected) {
                                    final bbox = detected['bbox'];
                                    final originalWidth =
                                        detected['originalWidth'] as double;
                                    final originalHeight =
                                        detected['originalHeight'] as double;

                                    // Scale from YOLOv8 640x640 to original dimensions
                                    double scaleX = _imageSize / originalWidth;
                                    double scaleY = _imageSize / originalHeight;
                                    double scale =
                                        scaleX < scaleY ? scaleX : scaleY;
                                    double offsetX =
                                        (_imageSize - originalWidth * scale) /
                                            2;
                                    double offsetY =
                                        (_imageSize - originalHeight * scale) /
                                            2;

                                    final double xMin = (bbox[0] - offsetX) *
                                        (displaySize / (originalWidth * scale));
                                    final double yMin = (bbox[1] - offsetY) *
                                        (displaySize /
                                            (originalHeight * scale));
                                    final double boxWidth = (bbox[2] -
                                            bbox[0]) *
                                        (displaySize / (originalWidth * scale));
                                    final double boxHeight =
                                        (bbox[3] - bbox[1]) *
                                            (displaySize /
                                                (originalHeight * scale));

                                    Color boxColor =
                                        _getBoxColor(detected['label']);
                                    log("🟢 Adjusted BBox for ${detected['label']}: xMin=$xMin, yMin=$yMin, width=$boxWidth, height=$boxHeight, displaySize=$displaySize");

                                    return Positioned(
                                      left: xMin,
                                      top: yMin,
                                      child: Container(
                                        width: boxWidth,
                                        height: boxHeight,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: boxColor, width: 2),
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
                                  }),
                              ],
                            ),
                          );
                        },
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
