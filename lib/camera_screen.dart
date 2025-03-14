import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'scan_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

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
      if (cameras.isEmpty) {
        throw Exception("No cameras found.");
      }
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

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    try {
      final image = await _cameraController!.takePicture();
      final resizedImagePath = await _resizeTo640(image.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultScreen(
            imagePath: resizedImagePath,
            isUploadedImage: false,
          ),
        ),
      );
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  /// **🔥 Resize Image to 640x640**
  Future<String> _resizeTo640(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? originalImage =
        img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) return imagePath;

    // ✅ Resize the image to 640x640
    final img.Image resizedImage = img.copyResize(
      originalImage,
      width: 640,
      height: 640,
    );

    final String resizedPath =
        '${imageFile.parent.path}/resized_640_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(resizedPath).writeAsBytes(img.encodeJpg(resizedImage));

    return resizedPath;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Camera Screen'),
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
          if (_isCameraInitialized)
            Center(
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(16), // Match scan result rounding
                child: AspectRatio(
                  aspectRatio: 1, // Ensure a square preview
                  child: FittedBox(
                    fit: BoxFit
                        .cover, // ✅ Ensures the preview behaves like Image.file
                    child: SizedBox(
                      width: _cameraController!.value.previewSize!.height,
                      height: _cameraController!.value.previewSize!.width,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),

          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: const Icon(
                    Icons.camera,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
