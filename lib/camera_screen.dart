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
      final croppedImagePath = await _cropAndResize(image.path);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultScreen(
            imagePath: croppedImagePath,
            isUploadedImage: false,
          ),
        ),
      );
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  /// **🔥 Crop and Resize Image to 1:1 Aspect Ratio**
  Future<String> _cropAndResize(String imagePath) async {
    final File imageFile = File(imagePath);
    final img.Image? originalImage =
        img.decodeImage(await imageFile.readAsBytes());

    if (originalImage == null) return imagePath;

    // Step 1: Crop to 1:1 aspect ratio (Square)
    int size = min(originalImage.width, originalImage.height);
    int offsetX = (originalImage.width - size) ~/ 2;
    int offsetY = (originalImage.height - size) ~/ 2;

    final img.Image cropped = img.copyCrop(
      originalImage,
      offsetX,
      offsetY,
      size,
      size,
    );

    // Step 2: Resize to 640x640 for YOLOv8
    final img.Image resized640 = img.copyResize(
      cropped,
      width: 640,
      height: 640,
    );

    final String resizedPath =
        '${imageFile.parent.path}/resized_640_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(resizedPath).writeAsBytes(img.encodeJpg(resized640));

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
              child: AspectRatio(
                aspectRatio: 1, // ✅ Force square preview
                child: CameraPreview(_cameraController!),
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
