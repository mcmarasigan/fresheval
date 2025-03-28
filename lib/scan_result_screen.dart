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

  Future<Size> _getImageSize(File imageFile) async {
    final decoded = await decodeImageFromList(imageFile.readAsBytesSync());
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }

  List<Widget> _buildBoundingBoxes(double displayWidth, double displayHeight) {
    return _detectedObjects.map((detected) {
      final bbox = detected['bbox']; // [xMin, yMin, xMax, yMax]

      final double scaleX = displayWidth / _imageSize;
      final double scaleY = displayHeight / _imageSize;

      final double xMin = bbox[0] * scaleX;
      final double yMin = bbox[1] * scaleY;
      final double boxWidth = (bbox[2] - bbox[0]) * scaleX;
      final double boxHeight = (bbox[3] - bbox[1]) * scaleY;

      final Color boxColor = _getBoxColor(detected['label']);

      return Positioned(
        left: xMin,
        top: yMin,
        child: Container(
          width: boxWidth,
          height: boxHeight,
          decoration: BoxDecoration(
            border: Border.all(color: boxColor, width: 2),
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
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _saveScanResult,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Retake',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final imageFile = File(widget.imagePath);
                        final double containerWidth = constraints.maxWidth;

                        return FutureBuilder<Size>(
                          future: _getImageSize(imageFile),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final imageSize = snapshot.data!;
                            final double aspectRatio =
                                imageSize.width / imageSize.height;
                        
                            return AspectRatio(
                              aspectRatio:
                                  aspectRatio, // Maintain original image aspect ratio
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: LayoutBuilder(
                                    builder: (context, boxConstraints) {
                                      final displayWidth =
                                          boxConstraints.maxWidth;
                                      final displayHeight =
                                          boxConstraints.maxHeight;

                                      return Stack(
                                        children: [
                                          Image.file(
                                            imageFile,
                                            width: displayWidth,
                                            height: displayHeight,
                                            fit: BoxFit
                                                .fill, // Because aspect ratio is already preserved
                                          ),
                                          if (_detectedObjects.isNotEmpty)
                                            ..._buildBoundingBoxes(
                                                displayWidth, displayHeight),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );

                          },
                        );
                      },
                    ),



                    const SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _detectedObjects.length,
                      itemBuilder: (context, index) {
                        final detected = _detectedObjects[index];
                        return Card(
                          child: ExpansionTile(
                            title: Text(
                              "${detected['label']} - ${detected['freshness']}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                    "Detection Confidence: ${detected['confidence'].toStringAsFixed(2)}%"),
                                subtitle: Text(
                                    "Freshness Confidence: ${detected['freshnessConfidence'].toStringAsFixed(2)}%"),
                              )
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                  ],
                ),
              ),
            ),
    );
  }
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

