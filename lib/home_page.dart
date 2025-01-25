import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_screen.dart';
import 'scan_result_screen.dart';
import 'l10n.dart';

class HomePage extends StatefulWidget {
  final AppLocalizations localizations;

  const HomePage({super.key, required this.localizations});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> recentScans = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadRecentScans();
  }

  Future<void> _loadRecentScans() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScans = prefs.getStringList('recent_scans') ?? [];

    setState(() {
      recentScans = savedScans
          .map((scan) => Map<String, String>.from(json.decode(scan)))
          .toList();
    });
  }

  Future<void> _saveScan({required String imagePath, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    final savedScans = prefs.getStringList('recent_scans') ?? [];

    // Create a new scan entry
    final newScan = json.encode({
      'imagePath': imagePath,
      'timestamp': DateTime.now().toString(),
      'name': name,
    });

    // Avoid duplicates
    if (!savedScans.contains(newScan)) {
      savedScans.add(newScan);
      await prefs.setStringList('recent_scans', savedScans);
    }

    _loadRecentScans(); // Reload the updated list
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

  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        await _saveScan(
          imagePath: pickedImage.path,
          name: widget.localizations.getTranslation('uploaded_image'),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(
              imagePath: pickedImage.path,
              isUploadedImage: true,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.localizations.getTranslation('failed_to_pick_image')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = widget.localizations;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.getTranslation('app_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFDCDE9F),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.getTranslation('recent scans'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: recentScans.isEmpty
                    ? Center(
                        child: Text(localizations.getTranslation('no scans available')),
                      )
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: recentScans
                            .reversed
                            .take(4)
                            .map((scan) {
                              return ScanCard(
                                title: scan['name']!,
                                subtitle: scan['timestamp']!,
                                imagePath: scan['imagePath']!,
                              );
                            }).toList(),
                      ),
              ),
              const SizedBox(height: 20),
              if (recentScans.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/history');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFEEF),
                      ),
                      child: Text(
                        localizations.getTranslation('see more'),
                        style: const TextStyle(color: Color(0xFF333330)),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 164,
                    height: 66.81,
                    child: ElevatedButton.icon(
                      onPressed: _pickImageFromGallery,
                      icon: const Icon(Icons.image, color: Color(0xFF333330)),
                      label: Text(
                        localizations.getTranslation('upload image'),
                        style: const TextStyle(color: Color(0xFF333330)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFEEF),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 164,
                    height: 66.81,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraScreen(),
                          ),
                        ).then((_) => _loadRecentScans());
                      },
                      icon: const Icon(Icons.camera, color: Color(0xFF333330)),
                      label: Text(
                        localizations.getTranslation('scan now'),
                        style: const TextStyle(color: Color(0xFF333330)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFEEF),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
            label: localizations.getTranslation('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: localizations.getTranslation('history'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: localizations.getTranslation('settings'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.help),
            label: localizations.getTranslation('help'),
          ),
        ],
      ),
    );
  }
}

class ScanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;

  const ScanCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.all(8.0),
      width: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEEF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
