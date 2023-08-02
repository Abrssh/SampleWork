// Copyright 2013 The Flutter Authors. All rights reserved.

import 'package:audio_record/Pages/Authentication/signIn.dart';
import 'package:audio_record/Pages/wrapper.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  runApp(new AppMain());
}

class AppMain extends StatelessWidget {
  static Future<SharedPreferences> mainPrefs = SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AudioServiceWidget(child: SignInPage()),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        backgroundColor: Colors.white,
      ),
      // initialRoute: "wrapper",
      routes: {
        "wrapper": (context) => Wrapper(),
      },
    );
  }
}
