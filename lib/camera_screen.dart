import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scan_result_screen.dart';
import 'scan_history_screen.dart';
import 'settings.dart';
import 'help_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _userFlashPreference = false; // Tracks user's flash preference
  File? _frontImage;
  File? _backImage;
  bool _isCapturingBack = false;
  bool _showTips = true;
  int _currentTipIndex = 0;

  final List<Map<String, String>> _photoTips = [
    {
      'title': 'Clean Your Camera',
      'description':
          'Wipe your camera lens with a soft cloth to remove smudges and dust for clearer photos.',
      'image': 'assets/img/clean_cam.png',
    },
    {
      'title': 'Good Lighting',
      'description':
          'Take photos in well-lit conditions. Avoid direct sunlight or dark shadows.',
      'image': 'assets/img/good_lighting.png',
    },
    {
      'title': 'Steady & Clear',
      'description':
          'Hold your phone steady to avoid blurry images. Tap to focus on the vegetables.',
      'image': 'assets/img/steady_clear.png',
    },
    {
      'title': 'Full View',
      'description':
          'Capture the entire vegetable in the frame. Avoid cutting off parts of it.',
      'image': 'assets/img/full_view.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    _checkShowTips();
  }

  Future<void> _checkShowTips() async {
    final prefs = await SharedPreferences.getInstance();
    final showTips = prefs.getBool('showCameraTips') ?? true;
    if (mounted) {
      setState(() {
        _showTips = showTips;
      });
      if (_showTips) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showInstructionPrompt();
        });
      }
    }
  }

  Future<void> _showInstructionPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    bool dontShowAgain = !(prefs.getBool('showCameraTips') ?? true);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                          itemCount: _photoTips.length,
                          onPageChanged: (index) {
                            setModalState(() {
                              _currentTipIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final tip = _photoTips[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    tip['image']!,
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tip['title']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    tip['description']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _photoTips.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentTipIndex == index ? 12 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentTipIndex == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: dontShowAgain,
                      onChanged: (value) {
                        setModalState(() {
                          dontShowAgain = value ?? false;
                        });
                      },
                    ),
                    Text(
                      "Don't show again",
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('showCameraTips', !dontShowAgain);
                    if (mounted) {
                      setState(() {
                        _showTips = !dontShowAgain;
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: Text(
                    'Got It',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("No cameras found.");
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController?.initialize();

      // Set initial flash state based on user preference
      if (_userFlashPreference && _cameraController != null) {
        await _cameraController!.setFlashMode(FlashMode.torch);
        setState(() {
          _isFlashOn = true;
        });
      }

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('📷 Error initializing camera: $e');
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _captureMultiAngleImage() async {
    if (!_isCameraInitialized || _cameraController == null) {
      print('📷 Camera not initialized for capture');
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final resizedFile = File(image.path);

      if (!_isCapturingBack) {
        setState(() {
          _frontImage = resizedFile;
          _isCapturingBack = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Front side captured. Now take the back side of the vegetable."),
          ),
        );
      } else {
        setState(() {
          _backImage = resizedFile;
          _isCapturingBack = false;
        });

        if (_frontImage != null && _backImage != null) {
          final frontPath = _frontImage!.path;
          final backPath = _backImage!.path;

          _frontImage = null;
          _backImage = null;

          // Turn off flash before navigating to ScanResultScreen
          if (_isFlashOn) {
            await _cameraController!.setFlashMode(FlashMode.off);
            setState(() {
              _isFlashOn = false;
            });
          }

          print(
              "📸 Navigating to ScanResultScreen with front: $frontPath, back: $backPath");
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanResultScreen(
                frontImagePath: frontPath,
                backImagePath: backPath,
                isMultiAngle: true,
                isUploadedImage: false,
                userFlashPreference: _userFlashPreference,
              ),
            ),
          );

          // Restore flash state based on returned preference
          if (result is bool && _cameraController != null) {
            setState(() {
              _userFlashPreference = result;
              _isFlashOn = result;
            });
            await _cameraController!.setFlashMode(
              result ? FlashMode.torch : FlashMode.off,
            );
          }
        } else {
          print("❌ One of the images was null. Capture failed.");
        }
      }
    } catch (e) {
      print("❌ Error during multi-angle capture: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();

    final frontConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Front Image'),
        content: const Text('Please select the FRONT view of the vegetable.'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Pick Image', style: GoogleFonts.poppins(
                      color: Colors.white,
                    ),),
          ),
        ],
      ),
    );

    if (frontConfirmed != true) return;

    final frontImage = await picker.pickImage(source: ImageSource.gallery);
    if (frontImage == null) {
      print("❌ No front image selected from gallery");
      return;
    }

    final backConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Back Image'),
        content: const Text('Now select the BACK view of the vegetable.'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Pick Image', style: GoogleFonts.poppins(
                      color: Colors.white,),)
          ),
        ],
      ),
    );

    if (backConfirmed != true) return;

    final backImage = await picker.pickImage(source: ImageSource.gallery);
    if (backImage == null) {
      print("❌ No back image selected from gallery");
      return;
    }

    final resizedFront = frontImage.path;
    final resizedBack = backImage.path;

    print(
        "📸 Navigating to ScanResultScreen with front: $resizedFront, back: $resizedBack");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScanResultScreen(
          frontImagePath: resizedFront,
          backImagePath: resizedBack,
          isUploadedImage: true,
          isMultiAngle: true,
          userFlashPreference: _userFlashPreference,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize!.height,
                    height: _cameraController!.value.previewSize!.width,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Hamburger Menu Icon
          Positioned(
            top: 50,
            left: 16,
            child: Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                    size: 35,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                );
              },
            ),
          ),
          // Flash and Question Mark Icons
          Positioned(
            top: 50,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    if (_cameraController != null) {
                      setState(() {
                        _isFlashOn = !_isFlashOn;
                        _userFlashPreference = _isFlashOn;
                      });
                      await _cameraController!.setFlashMode(
                        _isFlashOn ? FlashMode.torch : FlashMode.off,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.question_mark,
                    color: Colors.white,
                    size: 28,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  onPressed: _showInstructionPrompt,
                  tooltip: 'Show photo tips',
                ),
              ],
            ),
          ),
          // Gallery Button
          Positioned(
            bottom: 40,
            left: 50,
            child: GestureDetector(
              onTap: _pickImageFromGallery,
              child: Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.image,
                  color: Colors.green,
                  size: 35,
                ),
              ),
            ),
          ),
          // Capture Button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _captureMultiAngleImage,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
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
    // Define colors
    const Color selectedColor = Color(0xFF059212); // Green for selected item
    const Color unselectedColor =
        Color(0xFF787878); // Gray for unselected items

    // Helper function to determine if a route is active
    bool isRouteActive(String routeName) {
      return ModalRoute.of(context)?.settings.name == routeName;
    }

    return Drawer(
      child: Column(
        children: [
          // Custom Drawer Header
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
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                ],
              ),
            ),
          ),
          // Drawer Items
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
                    "Camera",
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
                    Navigator.pop(context); // Close drawer
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
                    "Scan History",
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
                    "Settings",
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
                    "Help",
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
                    "Developers",
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
