import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:path/path.dart' as p;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Capture Image',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<CameraDescription>? cameras;
  CameraController? _cameraController;

/// This function initializes the camera controller with the highest resolution preset available.
/// 
/// Returns:
///   Nothing is being returned explicitly in this code snippet. However, the `initCamera()` function is
/// returning a `Future<void>` type, which indicates that it will eventually complete without returning
/// a value.
  Future<void> initCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(cameras![0], ResolutionPreset.high);
    _cameraController!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  bool _capturing = false;
  bool get capturing => _capturing;
  set capturing(bool capturing) {
    _capturing = capturing;
    setState(() {});
  }

  File? _compressedImage;
  File? get compressedImage => _compressedImage;
  set compressedImage(File? compressedImage) {
    _compressedImage = compressedImage;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: !_cameraController!.value.isInitialized
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!)),
                  const SizedBox(height: 20),
                  if (compressedImage != null)
                    Expanded(child: Image.file(compressedImage!)),
                  const SizedBox(height: 20),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: capturing ? null : captureAndConvertImage,
        tooltip: 'Increment',
        child: capturing
            ? const Center(child: CircularProgressIndicator())
            : const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

/// This function captures an image using the camera, compresses it, and saves it as a JPEG file.
  Future<void> captureAndConvertImage() async {
    try {
      capturing = true;
      XFile file = await _cameraController!.takePicture();
      final filePath = file.path;
      final path = '${p.withoutExtension(filePath)}.compressed.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        path,
        format: CompressFormat.jpeg,
      );
      compressedImage = result;
      log('Converted image path: ${result?.path}');
    } on CameraException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.code}\n${e.description}'),
        ),
      );
      log('Error: ${e.code}\n${e.description}');
    }

    capturing = false;
  }
}
