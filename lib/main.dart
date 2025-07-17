import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_barcode_sdk_example/desktop.dart';
import 'package:flutter_barcode_sdk_example/mobile.dart';
import 'package:flutter_barcode_sdk_example/web.dart';

Future<void> main() async {
  StatefulWidget app;
  if (kIsWeb) {
    app = Web();
  } else if (Platform.isAndroid || Platform.isIOS) {
    // Ensure that plugin services are initialized so that `availableCameras()`
    // can be called before `runApp()`
    WidgetsFlutterBinding.ensureInitialized();

    // Obtain a list of the available cameras on the device.
    final cameras = await availableCameras();

    // Get a specific camera from the list of available cameras.
    final firstCamera = cameras.first;

    app = Mobile(
      camera: firstCamera,
    );
  } else {
    app = Desktop();
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      
      title: 'Dynamsoft Barcode Reader',
      home: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: app,
      ),
    ),
  );
}
