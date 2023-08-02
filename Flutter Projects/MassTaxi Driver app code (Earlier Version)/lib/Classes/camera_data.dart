import 'dart:io';

import 'package:audio_record/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CameraData {
  static SharedPreferences prefs;
  static Future<List<String>> getImages() async {
    try {
      if (prefs == null) {
        prefs = await AppMain.mainPrefs;
      }
      return prefs.getStringList('images');
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveImage(String newImage) async {
    try {
      if (prefs == null) {
        prefs = await AppMain.mainPrefs;
      }
      List<String> images = await getImages();
      if (images != null) {
        images.insert(0, newImage);
      } else {
        images = [];
        images.add(newImage);
      }
      await prefs.setStringList('images', images);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteImage(String image) async {
    try {
      await File(image).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAllImages() async {
    try {
      if (prefs == null) {
        prefs = await AppMain.mainPrefs;
      }
      List<String> images = await getImages();
      images.forEach((image) async {
        await File(image).delete();
      });

      prefs.setStringList('images', []);
      return true;
    } catch (e) {
      return false;
    }
  }
}
