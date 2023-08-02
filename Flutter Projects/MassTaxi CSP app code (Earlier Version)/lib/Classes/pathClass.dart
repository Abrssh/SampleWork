import 'package:cloud_firestore/cloud_firestore.dart';

class PathClass {
  final String startingLocationName, destinationName, pathName, docID;
  final int timetaken,
      boardingRange,
      destinationRange,
      destinationBuffer,
      efficiencyAccuracyRange;
  final Map<String, GeoPoint> dropOffLocations;

  PathClass(
      {this.startingLocationName,
      this.destinationName,
      this.pathName,
      this.docID,
      this.timetaken,
      this.boardingRange,
      this.destinationBuffer,
      this.destinationRange,
      this.dropOffLocations,
      this.efficiencyAccuracyRange});
}
