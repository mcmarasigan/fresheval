import 'dart:io';
import 'dart:developer';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fresheval/l10n.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
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
      print('Error initializing camera: $e');
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

 Future<void> _captureMultiAngleImage() async {
    if (!_isCameraInitialized || _cameraController == null) return;

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
          log("❌ One of the images was null. Capture failed.");
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

    if (originalImage == null) return imagePath;

    final img.Image resized = img.copyResize(originalImage, width: 640);

    final String resizedPath =
        '${imageFile.parent.path}/resized_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await File(resizedPath).writeAsBytes(img.encodeJpg(resized));

    return resizedPath;
  }



  Future<void> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        final resizedImagePath = await _resizeToFit(pickedImage.path);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScanResultScreen(
              imagePath: resizedImagePath,
              isUploadedImage: true, isMultiAngle: true,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
    }
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

          // 📸 Capture & Upload Buttons (Positioned Correctly)
         Positioned(
            bottom: 30, // Places the buttons near the bottom
            left: 0,
            right: 0, // Ensures full width usage for centering
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Centering the capture button
              children: [
                // 📤 Upload Button (Lower Left)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 30), // Adjust left padding
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

                const Spacer(), // Pushes the capture button to the center

                // 📸 Capture Button (Lower Center)
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

                const Spacer(), // Balances layout

                // **(Optional) Empty space for symmetry**
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
