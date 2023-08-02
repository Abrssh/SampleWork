import 'package:audio_record/Classes/final_stat.dart';
import 'package:audio_record/main.dart';
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  double speed;
  double accuracy;
  String name;
  DateTime timestamp;

  @override
  String toString() {
    // Converts Location Data into various forms of String
    if (name != null) {
      if (speed != null && accuracy != null) {
        return '$latitude;;;$longitude;;;$name;;;$accuracy;;;$speed;;;$timestamp';
      } else {
        return '$latitude;;;$longitude;;;$name;;;$timestamp';
      }
    } else if (accuracy != null) {
      return '$latitude;;;$longitude;;;$accuracy;;;$speed;;;$timestamp';
    }
    return '$latitude;;;$longitude;;;$timestamp';
  }

  // Converts Various Types of Location Data to String
  static LocationData fromString({String ldString}) {
    List<String> ldList = ldString.split(';;;');
    switch (ldList.length) {
      case 3:
        return LocationData(
            latitude: double.parse(ldList[0]),
            longitude: double.parse(ldList[1]),
            timestamp: DateTime.parse(ldList[2]));
      case 4:
        //print("SAVE Before Error: " + ldList.toString());
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

  LocationData.forPaused(
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

    if (currentLocation.name != null) {
      // Check if the location is a Paused location
      if (currentLocation.name.contains("PS")) {
        LocationData last =
            LocationData.fromString(ldString: progresstillnow.last);
        if (last.name != null) {
          if (last.name.contains("PS")) {
            // If the last saved location is a Paused Locaton that means the current Location is a Play Location so it will delete the last pause location
            if (last.name[2] == currentLocation.name[2] &&
                last.name[3] == currentLocation.name[3]) {
              progresstillnow.removeAt(progresstillnow.length - 1);
            }
          }
        }

        LocationData normalData = LocationData.withAccuracy(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude,
            accuracy: currentLocation.accuracy,
            speed: currentLocation.speed);
        progresstillnow.add(normalData.toString());
        progresstillnow.add(currentLocation.toString());
        returnbool =
            await prefs.setStringList("dist_progress", progresstillnow);
        print("SAVE PROGRESS: $currentLocation ");
        return returnbool;
      }
    }
    //print("PROGRESS TILL NOW ${progresstillnow.length}");
    if (progresstillnow.length > 0) {
      LocationData last =
          LocationData.fromString(ldString: progresstillnow.last);
      if (last.latitude == currentLocation.latitude &&
          last.longitude == currentLocation.longitude) {
        //print("DUPLICATE PROGRESS: $currentLocation ");
        return false;
      }
    }
    progresstillnow.add(currentLocation.toString());
    returnbool = await prefs.setStringList("dist_progress", progresstillnow);
    print("SAVE PROGRESS: $currentLocation ");
    return returnbool;
  }

  static Future<bool> saveStart(LocationData currentLocation) async {
    final prefs = await AppMain.mainPrefs;
    print("SAVE START: $currentLocation");
    if (await prefs.setString("start_location", currentLocation.toString())) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> saveDestination(LocationData selectedDestination) async {
    final prefs = await AppMain.mainPrefs;
    if (await prefs.setString(
        "stop_location", selectedDestination.toString())) {
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> checkRouteStart({LocationData currentLocation}) async {
    final prefs = await AppMain.mainPrefs;
    // print("CURRENTLOCATION $currentLocation");
    // print("START LOCATION: ${prefs.get('start_location')}");
    LocationData startingLoc = LocationData.fromString(
      ldString: prefs.get('start_location'),
    );
    //print("STARTINGLOC $startingLoc");
    double distance = Geolocator.distanceBetween(
        startingLoc.latitude,
        startingLoc.longitude,
        currentLocation.latitude,
        currentLocation.longitude);
    //print("STARTING DIST $distance");
    //print("STARTING ${FinalStat.startingRange}");
    if (distance > FinalStat.startingRange) {
      return true;
    } else {
      return false;
    }
    // return false here
  }

  static Future<bool> checkRouteStop({LocationData currentLocation}) async {
    double dist = Geolocator.distanceBetween(
        FinalStat.routeEndingLocation.latitude,
        FinalStat.routeEndingLocation.longitude,
        currentLocation.latitude,
        currentLocation.longitude);
    //print("DIST $dist");
    //print("ENDING ${FinalStat.endingRange}");
    return dist < FinalStat.endingRange;
  }

  static Future<double> checkRouteEnd({LocationData currentLocation}) async {
    //print("ENDING LOCATION : ${FinalStat.routeEndingLocation}");
    double dist = Geolocator.distanceBetween(
        FinalStat.routeEndingLocation.latitude,
        FinalStat.routeEndingLocation.longitude,
        currentLocation.latitude,
        currentLocation.longitude);
    return dist;
  }

  static Future<double> checkRoutetartingRange(
      {LocationData currentLocation}) async {
    final prefs = await AppMain.mainPrefs;
    LocationData startingLoc = LocationData.fromString(
      ldString: prefs.get('start_location'),
    );
    return Geolocator.distanceBetween(
        startingLoc.latitude,
        startingLoc.longitude,
        currentLocation.latitude,
        currentLocation.longitude);
  }

  static Future<bool> checkADStop({LocationData currentLocation}) async {
    double dist = Geolocator.distanceBetween(
        FinalStat.routeEndingLocation.latitude,
        FinalStat.routeEndingLocation.longitude,
        currentLocation.latitude,
        currentLocation.longitude);
    //print("AD STOP DIST $dist");
    //print("AD STOP ENDING ${FinalStat.adStopRange}");
    return dist < FinalStat.adStopRange;
  }

  static Future<LocationData> getStartingPosition() async {
    final prefs = await AppMain.mainPrefs;
    String startingPosition = prefs.get('start_location');
    return LocationData.fromString(
      ldString: startingPosition,
    );
  }

  static Future<LocationData> getEndingPosition() async {
    final prefs = await AppMain.mainPrefs;
    String startingPosition = prefs.get('stop_location');
    return LocationData.fromString(
      ldString: startingPosition,
    );
  }

  static double calculateDistance(
      {LocationData firstLoc, LocationData secLoc}) {
    return Geolocator.distanceBetween(firstLoc.latitude, firstLoc.longitude,
        secLoc.latitude, secLoc.longitude);
  }

  static bool isInStationRange(
      {double lat1, double long1, double lat2, double long2}) {
    print(
        "CURRENT RANGE: ${Geolocator.distanceBetween(lat1, long1, lat2, long2)}");
    if (FinalStat.startingRange >
        Geolocator.distanceBetween(lat1, long1, lat2, long2)) {
      return true;
    }
    return false;
  }

  // Calculates Toatal Route Duration
  static double calculateTime(LocationData starting, LocationData ending) {
    return (ending.timestamp.millisecondsSinceEpoch -
            starting.timestamp.millisecondsSinceEpoch) /
        60000;
  }
}
