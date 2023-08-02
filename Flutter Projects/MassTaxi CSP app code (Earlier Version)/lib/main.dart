import 'package:csp_app/Pages/Drawer%20Pages/Path%20Creation/inPath.dart';
import 'package:csp_app/Pages/Home/paths.dart';
import 'package:csp_app/Pages/wrapper.dart';
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
      debugShowCheckedModeBanner: false,
      debugShowMaterialGrid: false,
      home: Wrapper(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        backgroundColor: Colors.white,
      ),
      // initialRoute: "paths",
      routes: {
        "paths": (context) => Paths(),
        "PathPrep": (context) => InPath(),
      },
    );
  }
}
