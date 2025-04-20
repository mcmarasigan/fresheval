import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'l10n.dart';
import 'dart:ui';

class ScanHistoryScreen extends StatefulWidget {
  final AppLocalizations localizations;

  const ScanHistoryScreen({super.key, required this.localizations});

  @override
  _ScanHistoryScreenState createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> scanHistory = [];
  List<Map<String, dynamic>> filteredScanHistory = [];
  List<bool> selectedItems = [];
  String searchQuery = '';
  bool showDeleteMode = false;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadScanHistory();
    _searchController.addListener(() {
      _filterScanHistory(_searchController.text);
    });
  }

  Future<void> _loadScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final scanData = prefs.getStringList('recent_scans') ?? [];

    scanHistory = scanData.map((scan) {
      final decoded = json.decode(scan) as Map<String, dynamic>;

      return {
        'imagePath': decoded['imagePath']?.toString(),
        'frontImagePath': decoded['frontImagePath']?.toString(),
        'backImagePath': decoded['backImagePath']?.toString(),
        'isMultiAngle': decoded['isMultiAngle'] ?? false,
        'bookmarked': decoded['bookmarked'] ?? false,
        'objects': decoded.containsKey('objects') && decoded['objects'] != null
            ? List<Map<String, dynamic>>.from(decoded['objects'])
                .where((obj) =>
                    obj.isNotEmpty &&
                    (obj['bbox'] != null && (obj['bbox'] as List).isNotEmpty))
                .toList()
            : [],
        'date': decoded.containsKey('date')
            ? decoded['date'].toString()
            : "Unknown",
        'time': decoded.containsKey('time')
            ? decoded['time'].toString()
            : "Unknown",
      };
    }).toList();

    _filterScanHistory('');
  }

  void _filterScanHistory(String query) {
    query = query.toLowerCase();

    setState(() {
      searchQuery = query;
      filteredScanHistory = scanHistory.where((scan) {
        final date = scan['date'].toLowerCase();
        final time = scan['time'].toLowerCase();
        final objectLabels = scan['objects']
            .map<String>((obj) => obj['label'].toString().toLowerCase())
            .join(" ");

        if (_tabController.index == 1) {
          return scan['bookmarked'] == true &&
              (date.contains(query) ||
                  time.contains(query) ||
                  objectLabels.contains(query));
        } else {
          return date.contains(query) ||
              time.contains(query) ||
              objectLabels.contains(query);
        }
      }).toList();

      selectedItems = List.generate(filteredScanHistory.length, (_) => false);
    });
  }

  Future<void> _toggleBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final scan = filteredScanHistory[index];
    final scanIndex = scanHistory.indexWhere((s) =>
        s['imagePath'] == scan['imagePath'] &&
        s['date'] == scan['date'] &&
        s['time'] == scan['time']);

    if (scanIndex != -1) {
      setState(() {
        scanHistory[scanIndex]['bookmarked'] =
            !(scanHistory[scanIndex]['bookmarked'] ?? false);
        _filterScanHistory(_searchController.text);
      });

      await prefs.setStringList('recent_scans',
          scanHistory.map((scan) => json.encode(scan)).toList());
    }
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
        content: Text(widget.localizations.getTranslation('scans_deleted')),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color greenColor = Color(0xFF059212);
    const Color grayColor = Color(0xFF787878);

    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(
                Icons.menu,
                color: greenColor,
                size: 30,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: Text(
          widget.localizations.getTranslation('scan history'),
          style: TextStyle(color: greenColor),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: widget.localizations.getTranslation('search'),
                labelStyle: TextStyle(color: greenColor),
                hintText: widget.localizations
                    .getTranslation('Search by Date and Time'),
                prefixIcon: Icon(Icons.search, color: greenColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: greenColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: greenColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide(color: greenColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: greenColor,
            unselectedLabelColor: grayColor,
            labelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            indicatorColor: greenColor,
            onTap: (index) {
              _filterScanHistory(_searchController.text);
            },
            tabs: [
              Tab(text: widget.localizations.getTranslation('all_scans')),
              Tab(text: widget.localizations.getTranslation('bookmarks')),
            ],
          ),
          Expanded(
            child: filteredScanHistory.isEmpty
                ? Center(
                    child: Text(
                      widget.localizations.getTranslation('no scans available'),
                      style: TextStyle(color: grayColor),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: filteredScanHistory.length,
                    itemBuilder: (context, index) {
                      final scan = filteredScanHistory[index];
                      final objectCount =
                          (scan['objects'] as List?)?.length ?? 0;
                      final firstObjectLabel = objectCount > 0
                          ? scan['objects'][0]['label']
                          : 'Unknown';
                      final freshness = objectCount > 0
                          ? scan['objects'][0]['freshness']
                          : 'N/A';
                      final vqr = objectCount > 0
                          ? (scan['objects'][0]['vqr'] ?? 8)
                          : 8;
                      final isBookmarked = scan['bookmarked'] ?? false;

                      return GestureDetector(
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
                                    ScanDetailScreen(scan: scan, localizations: widget.localizations,),
                              ),
                            );
                          }
                        },
                        onLongPress: () {
                          setState(() {
                            showDeleteMode = true;
                            selectedItems = List.generate(
                                filteredScanHistory.length, (_) => false);
                          });
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            side: BorderSide(color: greenColor, width: 1),
                          ),
                          child: Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(8.0)),
                                      child: scan['isMultiAngle'] == true
                                          ? Image.file(
                                              File(
                                                  scan['frontImagePath'] ?? ''),
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.broken_image),
                                            )
                                          : Image.file(
                                              File(scan['imagePath'] ?? ''),
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                      Icons.broken_image),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "$firstObjectLabel (VQR: $vqr)",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          scan['date'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: IconButton(
                                  icon: Icon(
                                    isBookmarked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    color: isBookmarked
                                        ? Colors.yellow[700]
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    _toggleBookmark(index);
                                  },
                                ),
                              ),
                              if (showDeleteMode)
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Checkbox(
                                    value: selectedItems[index],
                                    onChanged: (bool? value) {
                                      setState(() {
                                        selectedItems[index] = value ?? false;
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (showDeleteMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showDeleteMode = false;
                        selectedItems = List.generate(
                            filteredScanHistory.length, (_) => false);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      widget.localizations.getTranslation('cancel'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedItems.contains(true) ? _confirmDelete : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      widget.localizations.getTranslation('delete'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    const Color selectedColor = Color(0xFF059212);
    const Color unselectedColor = Color(0xFF787878);
    const Color greenColor = Color(0xFF059212);

    bool isRouteActive(String routeName) {
      return ModalRoute.of(context)?.settings.name == routeName;
    }

    return Drawer(
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FRESHEVAL',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                  leading: Icon(
                    Icons.camera,
                    color: isRouteActive('/camera')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    widget.localizations.getTranslation('camera'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/camera')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/camera')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor: isRouteActive('/camera') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/camera');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.history,
                    color: isRouteActive('/history')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    widget.localizations.getTranslation('scan history'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/history')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/history')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor:
                      isRouteActive('/history') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/history');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.settings,
                    color: isRouteActive('/settings')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    widget.localizations.getTranslation('settings'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/settings')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/settings')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor:
                      isRouteActive('/settings') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/settings');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.help,
                    color: isRouteActive('/help')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    widget.localizations.getTranslation('help'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/help')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/help')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor: isRouteActive('/help') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/help');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.info,
                    color: isRouteActive('/developers')
                        ? selectedColor
                        : unselectedColor,
                  ),
                  title: Text(
                    widget.localizations.getTranslation('developers'),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isRouteActive('/developers')
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isRouteActive('/developers')
                          ? selectedColor
                          : unselectedColor,
                    ),
                  ),
                  tileColor:
                      isRouteActive('/developers') ? Colors.grey[200] : null,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/developers');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScanDetailScreen extends StatelessWidget {
  final Map<String, dynamic> scan;
  final AppLocalizations localizations;

  const ScanDetailScreen({super.key, required this.scan, required this.localizations});

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
      appBar: AppBar(
        title: Text(localizations.getTranslation('scan details')),
        backgroundColor: Colors.green),
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
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    try {
      final decoded = await decodeImageFromList(imageFile.readAsBytesSync());
      return Size(decoded.width.toDouble(), decoded.height.toDouble());
    } catch (e) {
      return const Size(640, 640); // Fallback size
    }
  }
}
