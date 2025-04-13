import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'l10n.dart';

class ScanHistoryScreen extends StatefulWidget {
  final AppLocalizations localizations;

  const ScanHistoryScreen({super.key, required this.localizations});

  @override
  _ScanHistoryScreenState createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<Map<String, dynamic>> scanHistory = [];
  List<Map<String, dynamic>> filteredScanHistory = [];
  List<bool> selectedItems = [];
  String searchQuery = '';
  bool showDeleteMode = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
    _searchController.addListener(() {
      _filterScanHistory(_searchController.text);
    });
  }

  Future<void> _loadScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final scanData = prefs.getStringList('recent_scans') ?? [];

    setState(() {
      scanHistory = scanData.map((scan) {
        final decoded = json.decode(scan) as Map<String, dynamic>;

        return {
          'imagePath': decoded['imagePath']?.toString(),
          'frontImagePath': decoded['frontImagePath']?.toString(),
          'backImagePath': decoded['backImagePath']?.toString(),
          'isMultiAngle': decoded['isMultiAngle'] ?? false,
          'objects': decoded.containsKey('objects') &&
                  decoded['objects'] != null
              ? List<Map<String, dynamic>>.from(decoded['objects'])
                  .where((obj) =>
                      obj.isNotEmpty &&
                      (obj['bbox'] != null && (obj['bbox'] as List).isNotEmpty))
                  .toList()
              : [], // ✅ Ensure objects is always a valid list
          'date': decoded.containsKey('date')
              ? decoded['date'].toString()
              : "Unknown",
          'time': decoded.containsKey('time')
              ? decoded['time'].toString()
              : "Unknown",
        };
      }).toList();

      _filterScanHistory('');
    });
  }

  void _filterScanHistory(String query) {
    query = query.toLowerCase();

    setState(() {
      searchQuery = query;
      filteredScanHistory = scanHistory.where((scan) {
        final date = scan['date'].toLowerCase();
        final time = scan['time'].toLowerCase();

        // Search inside detected objects
        final objectLabels = scan['objects']
            .map<String>((obj) => obj['label'].toString().toLowerCase())
            .join(" ");

        return date.contains(query) ||
            time.contains(query) ||
            objectLabels.contains(query);
      }).toList();

      selectedItems = List.generate(filteredScanHistory.length, (_) => false);
    });
  }


  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.localizations.getTranslation('delete scans')),
          content: Text(widget.localizations
              .getTranslation('confirm_delete_selected_scans')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(widget.localizations.getTranslation('cancel')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedScans();
              },
              child: Text(widget.localizations.getTranslation('confirm')),
            ),
          ],
        );
      },
    );
  }

  void _deleteSelectedScans() async {
    final prefs = await SharedPreferences.getInstance();
    final scansToKeep = <Map<String, dynamic>>[];

    for (int i = 0; i < filteredScanHistory.length; i++) {
      if (!selectedItems[i]) {
        scansToKeep.add(filteredScanHistory[i]);
      }
    }

    setState(() {
      scanHistory = scansToKeep;
      _filterScanHistory('');
      showDeleteMode = false;
    });

    await prefs.setStringList(
        'recent_scans', scanHistory.map((scan) => json.encode(scan)).toList());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${widget.localizations.getTranslation('scan history')} ${widget.localizations.getTranslation('deleted')}'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: Text(widget.localizations.getTranslation('scan history')),
        backgroundColor: Colors.green,
        actions: [
          if (scanHistory.isNotEmpty)
            IconButton(
              icon: Icon(showDeleteMode ? Icons.cancel : Icons.delete,
                  color: Colors.white),
              onPressed: () {
                setState(() {
                  showDeleteMode = !showDeleteMode;
                  selectedItems =
                      List.generate(filteredScanHistory.length, (_) => false);
                });
              },
            ),
          if (showDeleteMode)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: selectedItems.contains(true) ? _confirmDelete : null,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: widget.localizations.getTranslation('search'),
                hintText:
                    widget.localizations.getTranslation('Search by Date and Time'),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: filteredScanHistory.isEmpty
                ? Center(
                    child: Text(widget.localizations
                        .getTranslation('no scans available')),
                  )
                : ListView.builder(
                    itemCount: filteredScanHistory.length,
                    itemBuilder: (context, index) {
                      final scan = filteredScanHistory[index];
                      final objectCount =
                          (scan['objects'] as List?)?.length ?? 0;


                      return ListTile(
                        leading: showDeleteMode
                            ? Checkbox(
                                value: selectedItems[index],
                                onChanged: (bool? value) {
                                  setState(() {
                                    selectedItems[index] = value ?? false;
                                  });
                                },
                              )
                            : null,
                       title: Text(
                            objectCount == 0
                                ? "No Object Detected"
                                : "$objectCount Object${objectCount > 1 ? 's' : ''} Detected",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        subtitle: Text(
                            "Date: ${scan['date']}  Time: ${scan['time']}"),
                        trailing: scan['isMultiAngle'] == true
                            ? Image.file(
                                File(scan['frontImagePath'] ?? ''),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              )
                            : Image.file(
                                File(scan['imagePath'] ?? ''),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),

                        onTap: () {
                          if (showDeleteMode) {
                            setState(() {
                              selectedItems[index] = !selectedItems[index];
                            });
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ScanDetailScreen(scan: scan),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

 Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            accountName: Text("FreshEval"),
            accountEmail: Text("Scan and evaluate freshness"),
            decoration: BoxDecoration(color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/camera');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Scan History"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/help');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("Developers"),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/developers');
            },
          ),
        ],
      ),
    );
  }


}

/// **Full View Screen**

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> scan;

  const ScanDetailScreen({super.key, required this.scan});

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
    final List<dynamic> objects = scan['objects'] ?? [];
    const double fallbackSize = 640;
  final imagePath = scan['isMultiAngle'] == true
        ? (scan['frontImagePath'] ?? scan['imagePath'])
        : scan['imagePath'];

    final imageFile = imagePath != null ? File(imagePath) : null;

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🖼 Image with bounding boxes
            scan['isMultiAngle'] == true
                ? Row(
                    children: [
                      for (final path in [
                        scan['frontImagePath'],
                        scan['backImagePath']
                      ])
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                path == scan['frontImagePath']
                                    ? 'Front View'
                                    : 'Back View',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FutureBuilder<Size>(
                                future: _getImageSize(File(path)),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox(
                                      height: 200,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    );
                                  }

                                  final imageSize = snapshot.data!;
                                  final double aspectRatio =
                                      imageSize.width / imageSize.height;

                                  return AspectRatio(
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
                                        child: Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageFile == null
                        ? const SizedBox(
                            height: 200,
                            child: Center(
                                child: Icon(Icons.broken_image, size: 48)),
                          )
                        : FutureBuilder<Size>(
                            future: _getImageSize(imageFile),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }

                              final imageSize = snapshot.data!;
                              final double aspectRatio =
                                  imageSize.width / imageSize.height;

                              return AspectRatio(
                                aspectRatio: aspectRatio,
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
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        ),
                                        ...objects.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final obj = entry.value;
                                          final bbox = obj['bbox'];
                                          if (bbox == null ||
                                              bbox.length != 4) {
                                            return const SizedBox();
                                          }

                                          final originalWidth =
                                              (obj['originalWidth'] as num?)
                                                      ?.toDouble() ??
                                                  imageSize.width;
                                          final originalHeight =
                                              (obj['originalHeight'] as num?)
                                                      ?.toDouble() ??
                                                  imageSize.height;

                                          final scaleX =
                                              displayWidth / originalWidth;
                                          final scaleY =
                                              displayHeight / originalHeight;

                                          final xMin = bbox[0] * scaleX;
                                          final yMin = bbox[1] * scaleY;
                                          final boxWidth =
                                              (bbox[2] - bbox[0]) * scaleX;
                                          final boxHeight =
                                              (bbox[3] - bbox[1]) * scaleY;

                                          final color = _getBoxColor(
                                              obj['label'] ?? 'unknown');

                                          return Positioned(
                                            left: xMin,
                                            top: yMin,
                                            child: Container(
                                              width: boxWidth,
                                              height: boxHeight,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: color, width: 2),
                                              ),
                                              child: Align(
                                                alignment: Alignment.topLeft,
                                                child: Container(
                                                  color: color.withOpacity(0.7),
                                                  padding:
                                                      const EdgeInsets.all(2),
                                                  child: Text(
                                                    "${index + 1}. ${obj['label']} (${(obj['confidence'] as num?)?.toStringAsFixed(2) ?? '0.00'}%)",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),


            const SizedBox(height: 20),

            // 🧾 Object list with number + color
            Expanded(
              child: objects.isEmpty
                  ? const Center(
                      child: Text(
                        'No objects detected.',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: objects.length,
                      itemBuilder: (context, index) {
                        final obj = objects[index];
                        final boxColor =
                            _getBoxColor(obj['label'] ?? 'unknown');

                        return Card(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: boxColor, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: boxColor,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${obj['label']} - ${obj['freshness'] ?? 'Unknown'}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Detection confidence
                                      Text(
                                        "Detection Confidence: ${(obj['confidence'] as num?)?.toStringAsFixed(2) ?? '0.00'}%",
                                      ),

                                      // Freshness confidence (multi-angle or single)
                                      if (obj['backFreshnessConfidence'] !=
                                          null)
                                        Text(
                                          "Front Confidence: ${(obj['freshnessConfidence'] as num?)?.toStringAsFixed(2) ?? '0.00'}%\n"
                                          "Back Confidence: ${(obj['backFreshnessConfidence'] as num?)?.toStringAsFixed(2) ?? '0.00'}%\n"
                                          "Average Confidence: ${(obj['mergedConfidence'] as num?)?.toStringAsFixed(2) ?? '0.00'}%",
                                        )
                                      else
                                        Text(
                                          "Condition: ${(obj['freshnessConfidence'] as num?)?.toStringAsFixed(2) ?? '0.00'}%",
                                        ),

                                      // Status and explanation
                                      Text(
                                          "Condition: ${obj['freshness'] ?? 'N/A'}"),
                                      Text(
                                          "Interpretation: ${obj['freshnessStatus'] ?? 'N/A'}"),

                                      const SizedBox(height: 6),
                                      Text(
                                        obj['explanation'] ??
                                            'No explanation available.',
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),

                                      const SizedBox(height: 6),
                                      Text(
                                          "📆 Shelf Life: ${obj['shelfLife'] ?? 'N/A'}"),
                                      Text(
                                          "📌 Recommendation: ${obj['recommendation'] ?? 'N/A'}"),
                                    ],
                                  ),
                                )

                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )

          ],
        ),
      ),
    );
  }
  Future<Size> _getImageSize(File imageFile) async {
    final decoded = await decodeImageFromList(imageFile.readAsBytesSync());
    return Size(decoded.width.toDouble(), decoded.height.toDouble());
  }
}
