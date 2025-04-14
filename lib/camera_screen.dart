import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
    bool dontShowAgain = !(prefs.getBool('showCameraTips') ??
        true); // Checked if showCameraTips is false
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
                // Handle
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
      final resizedPath = await _resizeToFit(image.path);
      final resizedFile = File(resizedPath);

      if (!_isCapturingBack) {
        setState(() {
          _frontImage = resizedFile;
          _isCapturingBack = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Front image captured. Now take the back image."),
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

          // Reset before navigating
          _frontImage = null;
          _backImage = null;

          print(
              "📸 Navigating to ScanResultScreen with front: $frontPath, back: $backPath");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScanResultScreen(
                frontImagePath: frontPath,
                backImagePath: backPath,
                isMultiAngle: true,
                isUploadedImage: false,
              ),
            ),
          );
        } else {
          print("❌ One of the images was null. Capture failed.");
        }
      }
    } catch (e) {
      print("❌ Error during multi-angle capture: $e");
    }
  }

  Future<String> _resizeToFit(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? originalImage =
        img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) {
      print("❌ Failed to decode image for resizing: $imagePath");
      return imagePath;
    }

    final img.Image resized = img.copyResize(originalImage, width: 640);

    final String resizedPath =
        '${imageFile.parent.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await File(resizedPath).writeAsBytes(img.encodeJpg(resized));

    return resizedPath;
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();

    // Ask for FRONT image first
    final frontConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Front Image'),
        content: const Text('Please select the FRONT view of the vegetable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pick Image'),
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

    // Ask for BACK image
    final backConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Back Image'),
        content: const Text('Now select the BACK view of the vegetable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pick Image'),
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

    final resizedFront = await _resizeToFit(frontImage.path);
    final resizedBack = await _resizeToFit(backImage.path);

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
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('FreshEval Camera'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
              await _cameraController!.setFlashMode(
                _isFlashOn ? FlashMode.torch : FlashMode.off,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.question_mark),
            onPressed: _showInstructionPrompt,
            tooltip: 'Show photo tips',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 30),
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
                ),
                const Spacer(),
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
                const Spacer(),
                const SizedBox(width: 60),
              ],
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
