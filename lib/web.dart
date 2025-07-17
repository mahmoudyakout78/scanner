import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:flutter_barcode_sdk_example/utils.dart';
import 'package:image_picker/image_picker.dart';

import 'license.dart';
import 'overlay_painter.dart';
import 'scanner_screen.dart';

import 'dart:ui' as ui;

class Web extends StatefulWidget {
  @override
  _WebState createState() => _WebState();
}

class _WebState extends State<Web> {
  FlutterBarcodeSdk? _barcodeReader;
  String? _fileUrl; // Store the file URL for web
  String _barcodeResults = '';
  final picker = ImagePicker();
  bool _isSDKLoaded = false;
  List<BarcodeResult> _barcodeResultsList = [];

  @override
  void initState() {
    super.initState();
    initBarcodeSDK();
  }

  Future<void> initBarcodeSDK() async {
    _barcodeReader = FlutterBarcodeSdk();
    await _barcodeReader!.setLicense(LICENSE_KEY);
    await _barcodeReader!.init();

    // Get all current parameters.
    String params = await _barcodeReader!.getParameters();
    // Update the parameters.
    int ret = await _barcodeReader!.setParameters(params);
    print('Parameter update: $ret');

    // ret = await _barcodeReader!.setBarcodeFormats(BarcodeFormat.ONED);
    // print('setBarcodeFormats: $ret');

    setState(() {
      _isSDKLoaded = true;
    });
  }

  void updateResults(List<BarcodeResult> results) {
    setState(() {
      _barcodeResults = getBarcodeResults(results);
    });
  }

  _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // For web, pickedFile.path returns a URL
      setState(() {
        _fileUrl = pickedFile.path; // Use the file URL for web
        _barcodeResults = '';
      });

      if (_fileUrl != null) {
        // _barcodeResultsList =
        //     await _barcodeReader!.decodeFile(_fileUrl!); // Pass the URL
        Uint8List fileBytes = await pickedFile.readAsBytes();

        ui.Image image = await decodeImageFromList(fileBytes);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);

        if (byteData != null) {
          _barcodeResultsList = await _barcodeReader!.decodeImageBuffer(
              byteData.buffer.asUint8List(),
              image.width,
              image.height,
              byteData.lengthInBytes ~/ image.height,
              ImagePixelFormat.IPF_ARGB_8888.index,
              ImageRotation.rotation0.value);
        }

        updateResults(_barcodeResultsList);
      }
    } else {
      print('No image selected.');
    }
  }

  Widget getDefaultImageWithOverlay() {
    if (_fileUrl == null) {
      return Center(
        child: Text(
          'No image loaded',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<Image>(
            future: Future.value(Image.network(_fileUrl!)), // Use Image.network
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final Image image = snapshot.data!;

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
                          image, // Display the image
                          Positioned.fill(
                            child: _barcodeResultsList.isEmpty
                                ? Container(
                                    color: Color.fromARGB(26, 0, 0, 0),
                                    child: const Center(
                                      child: Text(
                                        'No barcode detected',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                : createOverlay(_barcodeResultsList),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }
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
            _barcodeResults,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: _fileUrl == null
                    ? Image.asset('images/default.png')
                    : _buildImageWithOverlay(constraints),
              ),
              Container(
                height: 100,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      MaterialButton(
                        child: Icon(Icons.upload_file,color: Colors.white,),
                        
                        color: const Color.fromARGB(255, 0, 0, 0),
                        onPressed: () async {
                          if (_isSDKLoaded == false) {
                            _showDialog('Error', 'Barcode SDK is not loaded.');
                            return;
                          }

                          await _pickImage();
                        },
                      ),
                      MaterialButton(
                        child: Icon(Icons.camera_alt,color: Colors.white,),
                        color: const Color.fromARGB(255, 0, 0, 0),
                        
                        onPressed: () async {
                          if (_isSDKLoaded == false) {
                            _showDialog('Error', 'Barcode SDK is not loaded.');
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScannerScreen(
                                barcodeReader: _barcodeReader!,
                              ),
                            ),
                          );
                        },
                      ),
                    ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
