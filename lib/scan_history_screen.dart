import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'l10n.dart';

class ScanHistoryScreen extends StatefulWidget {
  final AppLocalizations localizations;

  const ScanHistoryScreen({super.key, required this.localizations});

  @override
  _ScanHistoryScreenState createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<Map<String, String>> scanHistory = [];
  List<Map<String, String>> filteredScanHistory = [];
  List<bool> selectedItems = [];
  String searchQuery = '';
  int _currentIndex = 1;
  bool showDeleteMode = false; // Flag to toggle delete mode

  @override
  void initState() {
    super.initState();
    _loadScanHistory();
  }

  Future<void> _loadScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final scanData = prefs.getStringList('recent_scans') ?? [];

    setState(() {
      scanHistory = scanData
          .map((scan) => Map<String, String>.from(json.decode(scan)))
          .toList();
      filteredScanHistory = List.from(scanHistory);
      selectedItems = List.generate(scanHistory.length, (_) => false);
    });
  }

  void _filterScanHistory(String query) {
    setState(() {
      searchQuery = query;
      filteredScanHistory = scanHistory
          .where((scan) =>
              scan['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
      selectedItems = List.generate(filteredScanHistory.length, (_) => false);
    });
  }

  void _clearSearch() {
    setState(() {
      searchQuery = '';
      filteredScanHistory = List.from(scanHistory);
      selectedItems = List.generate(scanHistory.length, (_) => false);
    });
  }

  Future<void> _deleteSelectedScans() async {
    final prefs = await SharedPreferences.getInstance();

    // Remove selected items from scanHistory
    final scansToKeep = <Map<String, String>>[];
    for (int i = 0; i < filteredScanHistory.length; i++) {
      if (!selectedItems[i]) {
        scansToKeep.add(filteredScanHistory[i]);
      }
    }

    setState(() {
      scanHistory = scansToKeep;
      filteredScanHistory = List.from(scanHistory);
      selectedItems = List.generate(filteredScanHistory.length, (_) => false);
      showDeleteMode = false; // Exit delete mode after deletion
    });

    // Save updated scan history
    final updatedScans = scanHistory
        .map((scan) => json.encode(scan))
        .toList(); // Convert maps back to JSON strings
    await prefs.setStringList('recent_scans', updatedScans);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.localizations.getTranslation('scan history')} ${widget.localizations.getTranslation('deleted')}'),
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
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

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushNamed(context, '/home');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/history');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/settings');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/help');
    }
  }

  void _navigateToDetails(Map<String, String> scan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanDetailsScreen(
          imagePath: scan['imagePath']!,
          name: scan['name']!,
          timestamp: scan['timestamp']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.localizations.getTranslation('scan history')),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: _filterScanHistory,
                    controller: TextEditingController(text: searchQuery),
                    decoration: InputDecoration(
                      labelText: widget.localizations.getTranslation('search'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      showDeleteMode = !showDeleteMode; // Toggle delete mode
                      selectedItems = List.generate(
                          filteredScanHistory.length, (_) => false);
                    });
                  },
                ),
              ],
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
                      return ListTile(
                        onTap: () {
                          if (showDeleteMode) {
                            setState(() {
                              selectedItems[index] = !selectedItems[index];
                            });
                          } else {
                            _navigateToDetails(scan);
                          }
                        },
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
                        title: Text(scan['name']!),
                        subtitle: Text(scan['timestamp']!),
                        trailing: Image.file(
                          File(scan['imagePath']!),
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
          ),
          if (showDeleteMode && filteredScanHistory.isNotEmpty)
            ElevatedButton.icon(
              onPressed: selectedItems.contains(true)
                  ? _showConfirmationDialog
                  : null,
              icon: const Icon(Icons.delete),
              label: Text(widget.localizations.getTranslation('delete scans')),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFDCDE9F),
        selectedItemColor: const Color(0xFF446129),
        unselectedItemColor: const Color(0xFF92A65F),
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: widget.localizations.getTranslation('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: widget.localizations.getTranslation('scan history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: widget.localizations.getTranslation('settings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.help),
            label: widget.localizations.getTranslation('help'),
          ),
        ],
      ),
    );
  }
}

// Add the ScanDetailsScreen class at the bottom of this file.
class ScanDetailsScreen extends StatelessWidget {
  final String imagePath;
  final String name;
  final String timestamp;

  const ScanDetailsScreen({
    super.key,
    required this.imagePath,
    required this.name,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: $name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Timestamp: $timestamp',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
