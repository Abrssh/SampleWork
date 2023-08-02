import 'package:audio_record/Classes/location_data.dart';

class PathModel {
  final String name, pathDocID;
  final int pathAdBrakeNum;
  final LocationData startingLocation, endingLocation;
  final List<LocationData> dropOffs;
  final double startingRange, endingRange, adStopRange;

  PathModel({
    this.name,
    this.pathDocID,
    this.pathAdBrakeNum,
    this.startingLocation,
    this.endingLocation,
    this.dropOffs,
    this.startingRange,
    this.endingRange,
    this.adStopRange,
  });
}
