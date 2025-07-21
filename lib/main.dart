import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_barcode_sdk_example/desktop.dart';
import 'package:flutter_barcode_sdk_example/firebase_options.dart';
import 'package:flutter_barcode_sdk_example/phone_number.dart';
import 'package:flutter_barcode_sdk_example/mobile.dart';
import 'package:flutter_barcode_sdk_example/web.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Row(
                children: [
                  Text(
                    'Barcode Reader',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor:const Color.fromARGB(255, 16, 77, 6),
              
            ),
            
            backgroundColor: const Color.fromARGB(255, 189, 189, 189),
            body: FirebaseAuth.instance.currentUser == null ? PhoneNumberPage() : app,
          );
        },
      ),
    ),
  );
}
