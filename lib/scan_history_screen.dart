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
          'imagePath': decoded['imagePath'].toString(),
          'objects':
              decoded.containsKey('objects') && decoded['objects'] != null
                  ? List<Map<String, dynamic>>.from(decoded['objects'])
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
      drawer: _buildDrawer(),
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
                      final objectCount = scan['objects']
                          .length; // ✅ Ensure it counts objects properly

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
                          "$objectCount Objects Detected",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                            "Date: ${scan['date']}  Time: ${scan['time']}"),
                        trailing: Image.file(File(scan['imagePath']!),
                            width: 50, height: 50, fit: BoxFit.cover),
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

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("FreshEval"),
            accountEmail: const Text("Scan and evaluate freshness"),
            decoration: const BoxDecoration(color: Colors.green),
          ),
          ListTile(
            leading: const Icon(Icons.camera),
            title: const Text("Camera"),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Scan History"),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Settings"),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("Help"),
            onTap: () {
              Navigator.pushNamed(context, '/help');
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

  @override
  Widget build(BuildContext context) {
    final List<dynamic> objects = scan['objects'] ?? []; // Ensure it's a list
    final double imageSize = 640; // Image size reference
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text("Detected Objects")),
      body: Column(
        children: [
          // ✅ Image with Bounding Boxes
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 1, // Keep Square Aspect Ratio
              child: Stack(
                children: [
                  Image.file(
                    File(scan['imagePath']!),
                    fit: BoxFit.cover,
                    width: imageSize,
                    height: imageSize,
                  ),
                  // ✅ Overlay Bounding Boxes if they exist
                  ...objects
                      .where((obj) =>
                          obj.containsKey('bbox') && obj['bbox'] != null)
                      .map((obj) {
                    final bbox = obj['bbox']; // Ensure bbox exists

                    if (bbox.length != 4)
                      return const SizedBox(); // Skip invalid bbox

                    final double scaleFactor = screenWidth / imageSize;
                    final double xMin = bbox[0] * scaleFactor;
                    final double yMin = bbox[1] * scaleFactor;
                    final double boxWidth = (bbox[2] - bbox[0]) * scaleFactor;
                    final double boxHeight = (bbox[3] - bbox[1]) * scaleFactor;

                    return Positioned(
                      left: xMin,
                      top: yMin,
                      child: Container(
                        width: boxWidth,
                        height: boxHeight,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            color: Colors.red.withOpacity(0.7),
                            padding: const EdgeInsets.all(2),
                            child: Text(
                              "${obj['label']} (${double.parse(obj['confidence']).toStringAsFixed(2)}%)",
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

          // ✅ Detected Object List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: objects.length,
              itemBuilder: (context, index) {
                final obj = objects[index];
                return Card(
                  child: ListTile(
                    title: Text("${obj['label']}"),
                   subtitle: Text(
                      "Confidence: ${double.tryParse(obj['confidence'].toString())?.toStringAsFixed(2) ?? 'N/A'}%\n"
                      "Freshness: ${obj['freshness']} (${double.tryParse(obj['freshnessConfidence'].toString())?.toStringAsFixed(2) ?? 'N/A'}%)",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
