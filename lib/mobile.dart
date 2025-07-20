import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:flutter_barcode_sdk_example/home_screen.dart';
import 'package:flutter_barcode_sdk_example/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'license.dart';
import 'overlay_painter.dart';

class Mobile extends StatefulWidget {
  final CameraDescription camera;

  const Mobile({
    super.key,
    required this.camera,
  });

  @override
  MobileState createState() => MobileState();
}

class MobileState extends State<Mobile> with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  FlutterBarcodeSdk? _barcodeReader;
  bool _isScanAvailable = true;
  bool _isScanRunning = false;
  Widget _buttonText = Icon(Icons.play_arrow, color: Colors.white);
  Size _previewSize = Size(0, 0);
  List<BarcodeResult> _results = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer for app lifecycle

    // _initializeCameraController();
    // Initialize Dynamsoft Barcode Reader
    initBarcodeSDK();
  }

  Future<void> _initializeCameraController() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );

    try {
      await _controller!.initialize();
      _previewSize = _controller!.value.previewSize!;
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> initBarcodeSDK() async {
    _barcodeReader = FlutterBarcodeSdk();
    // Get 30-day FREEE trial license from https://www.dynamsoft.com/customer/license/trialLicense/?product=dcv&package=cross-platform
    await _barcodeReader!.setLicense(LICENSE_KEY);
    await _barcodeReader!.init();
  }

  void pictureScan() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        List<BarcodeResult> results =
            await _barcodeReader!.decodeFile(image.path);

        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DisplayPictureScreen(
                  imagePath: image.path, barcodeResults: results),
            ));
        setState(() {});
      }
    } catch (err) {
      print('Error: $err');
    }

    // final image = await _controller!.takePicture();
  }

  List<BarcodeResult> rotate90barcode(List<BarcodeResult> input, int height) {
    List<BarcodeResult> output = [];
    for (BarcodeResult result in input) {
      int x1 = result.x1;
      int x2 = result.x2;
      int x3 = result.x3;
      int x4 = result.x4;
      int y1 = result.y1;
      int y2 = result.y2;
      int y3 = result.y3;
      int y4 = result.y4;
      int errorCode = result.errorCode;
      String errorMsg = result.errorMsg;

      BarcodeResult newResult = BarcodeResult(
          result.format,
          result.text,
          height - y1,
          x1,
          height - y2,
          x2,
          height - y3,
          x3,
          height - y4,
          x4,
          result.angle,
          result.barcodeBytes,
          errorCode,
          errorMsg);

      output.add(newResult);
    }

    return output;
  }

  void startVideo() async {
    await _initializeCameraController();
    setState(() {
      _buttonText = Icon(Icons.start_outlined,color: Colors.white,);
    });
    _isScanRunning = true;
    await _controller!.startImageStream((CameraImage availableImage) async {
      assert(defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
      int format = ImagePixelFormat.IPF_NV21.index;

      int rotation = 0;
      if (MediaQuery.of(context).size.width <
          MediaQuery.of(context).size.height) {
        if (Platform.isAndroid) {
          rotation = ImageRotation.rotation90.value;
        }
      }

      switch (availableImage.format.group) {
        case ImageFormatGroup.yuv420:
          format = ImagePixelFormat.IPF_NV21.index;
          break;
        case ImageFormatGroup.bgra8888:
          format = ImagePixelFormat.IPF_ARGB_8888.index;
          break;
        default:
          format = ImagePixelFormat.IPF_RGB_888.index;
      }

      if (!_isScanAvailable) {
        return;
      }

      _isScanAvailable = false;

      _barcodeReader!
          .decodeImageBuffer(
              availableImage.planes[0].bytes,
              availableImage.width,
              availableImage.height,
              availableImage.planes[0].bytesPerRow,
              format,
              rotation)
          .then((results) {
        if (_isScanRunning) {
          _results = results;
          // if (Platform.isAndroid && results.isNotEmpty) {
          //   _results = rotate90barcode(_results, _previewSize_previewSize.height.toInt());
          // }
          setState(() {});
        }

        _isScanAvailable = true;
      }).catchError((error) {
        _isScanAvailable = false;
      });
    });
  }

  void stopVideo() async {
    setState(() {
      _buttonText = Icon(Icons.stop_circle, color: Colors.white);
      _results = [];
    });
    _isScanRunning = false;
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.stopImageStream();
      _controller?.dispose();
      _controller = null;
    }
  }

  void videoScan() async {
    if (!_isScanRunning) {
      startVideo();
    } else {
      stopVideo();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      stopVideo();
    } else if (state == AppLifecycleState.resumed) {
      startVideo();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    stopVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
      SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Stack(
              children: [
                _controller == null
                    ? Image.asset(
                        'images/default.png',
                      )
                    : SizedBox(
                        width: MediaQuery.of(context).size.width <
                                MediaQuery.of(context).size.height
                            ? _previewSize.height
                            : _previewSize.width,
                        height: MediaQuery.of(context).size.width <
                                MediaQuery.of(context).size.height
                            ? _previewSize.width
                            : _previewSize.height,
                        child: CameraPreview(
                          _controller!,
                        )),
                Positioned(
                  top: 0.0,
                  right: 0.0,
                  bottom: 0.0,
                  left: 0.0,
                  child: _results.isEmpty
                      ? Container(
                          color: Color.fromARGB(26, 0, 0, 0),
                          child: const Center(
                            
                          ))
                      : createOverlay(_results),
                ),
                Positioned.fill(
                    child: BarcodeOverlayWithToken(results: _results)),
              ],
            ),
          )),
      Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: 100,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  CircleAvatar(
                    backgroundColor: const Color.fromARGB(255, 5, 5, 5),
                    radius: 30,
                    child: MaterialButton(
                        child: _buttonText,
                        
                        onPressed: () async {
                          try {
                            // Ensure that the camera is initialized.
                            await _initializeControllerFuture;
                    
                            videoScan();
                            // pictureScan();
                          } catch (e) {
                            // If an error occurs, log the error to the console.
                            print(e);
                          }
                        }),
                  ),
                      CircleAvatar(
                        backgroundColor: const Color.fromARGB(255, 5, 5, 5),
                        radius: 30,
                        child: MaterialButton(
                          
                        child: Icon(Icons.upload_file, color: Colors.white,),
                        
                          
                        onPressed: () async {
                          pictureScan();
                        }),
                      ),
                      MaterialButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                          
                        child: Text("Register now", style: TextStyle(color: Colors.white),),
                        color: const Color.fromARGB(255, 0, 0, 0),
                          
                        onPressed: () async {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                        }
                        
                        ),
                      
                ]),
          ),
        ],
      )
    ]);
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  final List<BarcodeResult> barcodeResults;

  const DisplayPictureScreen(
      {super.key, required this.imagePath, required this.barcodeResults});

  Future<ui.Image> _loadImage(File imageFile) async {
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(imageBytes, (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  Widget getDefaultImageWithOverlay() {
    final File imageFile = File(imagePath);

    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<ui.Image>(
          future: _loadImage(imageFile), // Load the image as a ui.Image
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }

            final ui.Image image = snapshot.data!;

            return Stack(
              children: [
                SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Stack(
                        children: [
                          SizedBox(
                            width: image.width.toDouble(),
                            height: image.height.toDouble(),
                            child: Image.file(imageFile),
                          ),
                          Positioned(
                            top: 0.0,
                            right: 0.0,
                            bottom: 0.0,
                            left: 0.0,
                            child: barcodeResults.isEmpty
                                ? Container(
                                    color: Color.fromARGB(26, 0, 0, 0),
                                    child: const Center(
                                      
                                    ))
                                : createOverlay(barcodeResults),
                          ),
                        ],
                      ),
                    )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildImageWithOverlay(BoxConstraints constraints) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight * 0.7,
            child: getDefaultImageWithOverlay(),
          ),
          SizedBox(height: 10),
          SelectableText(
            getBarcodeResults(barcodeResults),
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dynamsoft Barcode Reader')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Display camera stream or image
              Expanded(child: _buildImageWithOverlay(constraints)),
            ],
          );
        },
      ),
    );
  }
}
