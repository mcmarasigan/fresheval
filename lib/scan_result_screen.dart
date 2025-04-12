import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model_service.dart';

class ScanResultScreen extends StatefulWidget {
  final String? imagePath; // Keep for single image case
  final String? frontImagePath;
  final String? backImagePath;
  final bool isMultiAngle;
  final bool isUploadedImage;
  final Function(String imagePath, String name)? onSave;

  const ScanResultScreen({
    super.key,
    this.imagePath,
    this.frontImagePath,
    this.backImagePath,
    required this.isMultiAngle,
    required this.isUploadedImage, this.onSave,
  });


  @override
  _ScanResultScreenState createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late ModelService _modelService;
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _isLoading = true;
  double _originalWidth = 640;
  double _originalHeight = 640;

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

      if (widget.isMultiAngle) {
        final frontBytes = await File(widget.frontImagePath!).readAsBytes();
        final backBytes = await File(widget.backImagePath!).readAsBytes();

        final decoded = await decodeImageFromList(frontBytes);
        _originalWidth = decoded.width.toDouble();
        _originalHeight = decoded.height.toDouble();

        final combinedResults = await _modelService.analyzeMultiAngleImages(
          frontImage: frontBytes,
          backImage: backBytes,
          imageWidth: _originalWidth,
          imageHeight: _originalHeight,
        );

        for (var res in combinedResults) {
          log("📸 MULTI-ANGLE RESULT:");
          log("🫲 Front: ${res['front']['freshness']} (${res['front']['freshnessConfidence']?.toStringAsFixed(2)}%)");
          log("🫱 Back:  ${res['back']?['freshness'] ?? 'N/A'} (${res['back']?['freshnessConfidence']?.toStringAsFixed(2) ?? '--'}%)");
          log("✅ Merged: ${res['mergedFreshness']} (${res['mergedConfidence'].toStringAsFixed(2)}%) => ${res['mergedStatus']}");
        }

        setState(() {
          _detectedObjects = combinedResults.map((res) {
            final shelfInfo = _modelService.getShelfLifeAndRecommendation(
              res['object'],
              res['mergedStatus'],
            );
            return {
              'label': res['object'],
              'confidence': res['mergedConfidence'],
              'freshness': res['mergedFreshness'],
              'freshnessConfidence': res['mergedConfidence'],
              'freshnessStatus': res['mergedStatus'],
              'explanation': res['front']['explanation'] ?? 'No explanation',
              'bbox': res['front']['bbox'],
              'originalWidth': res['front']['originalWidth'],
              'originalHeight': res['front']['originalHeight'],
              'shelfLife': shelfInfo['shelfLife'],
              'recommendation': shelfInfo['recommendation'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        final imageBytes = await File(widget.imagePath!).readAsBytes();

        final decoded = await decodeImageFromList(imageBytes);
        _originalWidth = decoded.width.toDouble();
        _originalHeight = decoded.height.toDouble();

        final classifiedResults = await _modelService.detectAndClassify(
          imageBytes,
          _originalWidth,
          _originalHeight,
        );

        for (var res in classifiedResults) {
          log("📸 SINGLE IMAGE RESULT:");
          log("✅ ${res['object']} - ${res['freshness']} (${res['freshnessConfidence'].toStringAsFixed(2)}%) => ${res['freshnessStatus']}");
        }

        setState(() {
          _detectedObjects = classifiedResults.map((res) {
            final shelfInfo = _modelService.getShelfLifeAndRecommendation(
              res['object'],
              res['freshnessStatus'] ?? '',
            );

            return {
              'label': res['object'],
              'confidence': res['confidence'],
              'bbox': res['bbox'],
              'freshness': res['freshness'],
              'freshnessConfidence': res['freshnessConfidence'],
              'freshnessStatus': res['freshnessStatus'] ?? 'Unknown',
              'explanation': res['explanation'] ?? 'No explanation available.',
              'originalWidth': res['originalWidth'] ?? _originalWidth,
              'originalHeight': res['originalHeight'] ?? _originalHeight,
              'shelfLife': shelfInfo['shelfLife'],
              'recommendation': shelfInfo['recommendation'],
            };
          }).toList();
          _isLoading = false;
        });
      }
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
                'confidence': obj['confidence'],
                'freshness': obj['freshness'],
                'freshnessConfidence': obj['freshnessConfidence'],
                'bbox': (obj['bbox'] as List).map((e) => e.toDouble()).toList(),
                'originalWidth': obj['originalWidth'],
                'originalHeight': obj['originalHeight'],
                'freshnessStatus': obj['freshnessStatus'],
                'explanation': obj['explanation'],
                'shelfLife': obj['shelfLife'],
                'recommendation': obj['recommendation'],
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
    return _detectedObjects.asMap().entries.map((entry) {
      final int index = entry.key;
      final detected = entry.value;
      final bbox = detected['bbox'];

      if (bbox == null || bbox.isEmpty || bbox.length < 4) {
        return const SizedBox();
      }

      final double scaleX = displayWidth / _originalWidth;
      final double scaleY = displayHeight / _originalHeight;

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
                '${index + 1}. ${detected['label']} (${detected['confidence'].toStringAsFixed(2)}%)',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Display
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final imageFile = File(widget.isMultiAngle
                            ? widget.frontImagePath!
                            : widget.imagePath!);
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

                            return Center(
                              child: SizedBox(
                                width: containerWidth * 0.85,
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
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
                                                fit: BoxFit.cover,
                                              ),
                                              if (_detectedObjects.isNotEmpty &&
                                                  _detectedObjects[0]
                                                          ['label'] !=
                                                      'None')
                                                ..._buildBoundingBoxes(
                                                    displayWidth,
                                                    displayHeight),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Results or Quality Warnings
                    if (_detectedObjects.isNotEmpty &&
                        _detectedObjects[0]['freshnessStatus'] ==
                            'Image Too Dark')
                      Card(
                        color: Colors.red[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image Too Dark',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _detectedObjects[0]['explanation'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_detectedObjects.isNotEmpty &&
                        _detectedObjects[0]['freshnessStatus'] ==
                            'Image Too Bright')
                      Card(
                        color: Colors.yellow[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image Too Bright',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _detectedObjects[0]['explanation'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_detectedObjects.isNotEmpty &&
                        _detectedObjects[0]['freshnessStatus'] ==
                            'Image Too Blurry')
                      Card(
                        color: Colors.blue[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Image Too Blurry',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _detectedObjects[0]['explanation'],
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _detectedObjects.length,
                        itemBuilder: (context, index) {
                          final detected = _detectedObjects[index];
                          final boxColor = _getBoxColor(detected['label']);

                          return Card(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: boxColor, width: 2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              title: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: boxColor,
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "${detected['label'] ?? 'Unknown'} - ${detected['freshnessStatus'] ?? detected['freshness'] ?? 'N/A'}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                ListTile(
                                  title: Text(
                                    "Detection Confidence: ${detected['confidence']?.toStringAsFixed(2) ?? '0.00'}%\n"
                                    "Condition: ${detected['freshness']} (${detected['freshnessConfidence']?.toStringAsFixed(2) ?? '0.00'}%)\n"
                                    "Interpretation: ${detected['freshnessStatus'] ?? 'Unknown'}",
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        detected['explanation'] ??
                                            'No explanation available.',
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                          "📆 Shelf Life: ${detected['shelfLife']}"),
                                      Text(
                                          "📌 Recommendation: ${detected['recommendation']}"),
                                    ],
                                  ),
                                ),
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
