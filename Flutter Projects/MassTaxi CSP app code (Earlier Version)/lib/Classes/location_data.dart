import 'package:csp_app/main.dart';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  double speed;
  double accuracy;
  String name;
  DateTime timestamp;
  static double startingRange;
  static double endingRange;

  @override
  String toString() {
    // Converts Location Data into various forms of String
    if (name != null) {
      if (speed != null && accuracy != null) {
        return '$latitude;$longitude;$name;$accuracy;$speed;$timestamp';
      } else {
        return '$latitude;$longitude;$name;$timestamp';
      }
    } else if (accuracy != null) {
      return '$latitude;$longitude;$accuracy;$speed;$timestamp';
    }
    return '$latitude;$longitude;$timestamp;';
  }

  // Converts Various Types of Location Data to String
  static LocationData fromString({String ldString}) {
    List<String> ldList = ldString.split(';');

    switch (ldList.length) {
      case 3:
        return LocationData(
            latitude: double.parse(ldList[0]),
            longitude: double.parse(ldList[1]),
            timestamp: DateTime.parse(ldList[2]));
      case 4:
        return LocationData.withName(
            latitude: double.parse(ldList[0]),
            longitude: double.parse(ldList[1]),
            name: ldList[2],
            timestamp: DateTime.parse(ldList[3]));
      case 5:
        return LocationData.withAccuracy(
            latitude: double.parse(ldList[0]),
            longitude: double.parse(ldList[1]),
            accuracy: double.parse(ldList[2]),
            speed: double.parse(ldList[3]),
            timestamp: DateTime.parse(ldList[4]));
      case 6:
        return LocationData.forAD(
            latitude: double.parse(ldList[0]),
            longitude: double.parse(ldList[1]),
            name: ldList[2],
            accuracy: double.parse(ldList[3]),
            speed: double.parse(ldList[4]),
            timestamp: DateTime.parse(ldList[5]));
    }
  }

  LocationData({this.latitude, this.longitude, timestamp}) {
    if (timestamp == null) {
      this.timestamp = DateTime.now();
    } else {
      this.timestamp = timestamp;
    }
  }

  LocationData.withAccuracy(
      {this.latitude, this.longitude, this.accuracy, this.speed, timestamp}) {
    if (timestamp == null) {
      this.timestamp = DateTime.now();
    } else {
      this.timestamp = timestamp;
    }
  }

  LocationData.withName({this.latitude, this.longitude, this.name, timestamp}) {
    if (timestamp == null) {
      this.timestamp = DateTime.now();
    } else {
      this.timestamp = timestamp;
    }
  }

  LocationData.forAD(
      {this.latitude,
      this.longitude,
      this.name,
      this.accuracy,
      this.speed,
      timestamp}) {
    if (timestamp == null) {
      this.timestamp = DateTime.now();
    } else {
      this.timestamp = timestamp;
    }
  }

  static Future<bool> saveProgress(LocationData currentLocation) async {
    bool returnbool = false;
    final prefs = await AppMain.mainPrefs;
    List<String> progresstillnow = prefs.getStringList('dist_progress');
    if (progresstillnow == null) {
      progresstillnow = [];
    }
    if (progresstillnow.length > 0) {
      LocationData last =
          LocationData.fromString(ldString: progresstillnow.last);
      if (last.latitude == currentLocation.latitude &&
          last.longitude == currentLocation.longitude) {
        print("DUPLICATE PROGRESS: $currentLocation ");
        return false;
      }
    }
    progresstillnow.add(currentLocation.toString());
    returnbool = await prefs.setStringList("dist_progress", progresstillnow);
    print("SAVE PROGRESS: $currentLocation ");
    return returnbool;
  }

  static Future<bool> saveDropOff(LocationData currentLocation) async {
    bool returnbool = false;
    final prefs = await AppMain.mainPrefs;
    List<String> progresstillnow = prefs.getStringList('drop_off');
    if (progresstillnow == null) {
      progresstillnow = [];
    }
    if (progresstillnow.length > 0) {
      LocationData last =
          LocationData.fromString(ldString: progresstillnow.last);
      if (last.latitude == currentLocation.latitude &&
          last.longitude == currentLocation.longitude) {
        print("DUPLICATE DROP OFF: $currentLocation ");
        return false;
      }
    }
    progresstillnow.add(currentLocation.toString());
    returnbool = await prefs.setStringList("drop_off", progresstillnow);
    print("SAVE DROP OFF: $currentLocation ");
    return returnbool;
  }

  static Future<bool> saveStart(LocationData currentLocation) async {
    final prefs = await AppMain.mainPrefs;
    if (await prefs.setString("start_location", currentLocation.toString())) {
      print("SAVE START: $currentLocation ");
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> savePathName(String pathname) async {
    final prefs = await AppMain.mainPrefs;
    if (await prefs.setString("path_name", pathname)) {
      print("SAVE PATH NAME: $pathname ");
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> saveSuperPath(String pathname) async {
    final prefs = await AppMain.mainPrefs;
    if (await prefs.setString("super_path", pathname)) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> saveDistanceAndDisplacement(
      double distance, double displacement) async {
    final prefs = await AppMain.mainPrefs;
    if (await prefs.setString(
        "distance_displacement",
        distance.toStringAsFixed(2) +
            " : " +
            displacement.toStringAsFixed(2))) {
      print("DISTANCE : $distance, DISPLACEMENT : $displacement");
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> saveDuration(double time) async {
    final prefs = await AppMain.mainPrefs;
    if (await prefs.setDouble("duration", time)) {
      print("SAVE DURATION: $time ");
      return true;
    } else {
      return false;
    }
  }

  static Future<LocationData> getStartingPosition() async {
    final prefs = await AppMain.mainPrefs;
    String startingPosition = prefs.get('start_location');
    return LocationData.fromString(
      ldString: startingPosition,
    );
  }

  static Future<LocationData> getSuperPath() async {
    final prefs = await AppMain.mainPrefs;
    String startingPosition = prefs.get('super_path');
    return LocationData.fromString(
      ldString: startingPosition,
    );
  }

  static Future<String> getPathName() async {
    final prefs = await AppMain.mainPrefs;
    String pathname = prefs.get('path_name');
    return pathname;
  }

  static Future<bool> setRanges(
      {double startingRange, double endingRange}) async {
    final prefs = await AppMain.mainPrefs;
    bool sr = await prefs.setDouble("starting_range", startingRange);
    bool er = await prefs.setDouble("ending_range", endingRange);
    LocationData.startingRange = startingRange;
    LocationData.endingRange = endingRange;
    return sr && er;
  }

  static double calculateDistance(
      {LocationData firstLoc, LocationData secLoc}) {
    return Geolocator.distanceBetween(firstLoc.latitude, firstLoc.longitude,
        secLoc.latitude, secLoc.longitude);
  }

  // Calculates Toatal Route Duration
  static double calculateTime(LocationData starting, LocationData ending) {
    return (ending.timestamp.millisecondsSinceEpoch -
            starting.timestamp.millisecondsSinceEpoch) /
        60000;
  }

  static Future<List<LocationData>> getDropOffLocations() async {
    final prefs = await AppMain.mainPrefs;
    List<String> savedDropOffs = prefs.getStringList('drop_off');
    List<LocationData> dropoffs = [];
    if (savedDropOffs != null) {
      savedDropOffs.forEach((element) {
        dropoffs.add(LocationData.fromString(ldString: element));
      });
    }
    return dropoffs;
  }

  static Future<void> clearProgress() async {
    final prefs = await AppMain.mainPrefs;
    await prefs.remove('start_location');
    await prefs.remove('dist_progress');
    await prefs.remove('drop_off');
    await prefs.remove('path_name');
    await prefs.remove('save_super_path');
    await prefs.remove('distance_displacement');
    await prefs.remove('duration');
  }
}
