import 'package:audio_record/Classes/location_data.dart';
import 'package:audio_record/Classes/route_data.dart';

class FinalStat {
  final List<RouteData> components;
  int efficency;
  bool isCompromised;
  final LocationData startingLocation;
  final LocationData endingLocation;
  final double timetaken;
  static LocationData routeStartingLocation;
  static LocationData routeEndingLocation;
  static double startingRange = 100;
  static double endingRange = 200;
  static double adStopRange = 300;
  static List<LocationData> dropOffs = [];

  FinalStat(
      {this.components,
      this.startingLocation,
      this.endingLocation,
      this.timetaken});

  static saveDropOff({double latitude, double longitude}) {
    dropOffs.add(LocationData(latitude: latitude, longitude: longitude));
  }

  static clearStaticFields() {
    routeStartingLocation = null;
    routeEndingLocation = null;
    startingRange = 100;
    endingRange = 200;
    adStopRange = 300;
    dropOffs = [];
  }
}
