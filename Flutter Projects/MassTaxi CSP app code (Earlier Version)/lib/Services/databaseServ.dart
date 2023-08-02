import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csp_app/Classes/bookedSpots.dart';
import 'package:csp_app/Classes/csp.dart';
import 'package:csp_app/Classes/fixClaim.dart';
import 'package:csp_app/Classes/newPath.dart';
import 'package:csp_app/Classes/pathClass.dart';
import 'package:csp_app/Classes/superPath.dart';
import 'package:csp_app/Classes/systemAccount.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final CollectionReference cspCollection =
      FirebaseFirestore.instance.collection("csp");
  final CollectionReference scheduleForRegistration =
      FirebaseFirestore.instance.collection("scheduled_for_registration");
  final CollectionReference newPathReportCollection =
      FirebaseFirestore.instance.collection("new_path_Report");
  final CollectionReference fixClaimCollection =
      FirebaseFirestore.instance.collection("fixClaim");
  final CollectionReference superPathCollection =
      FirebaseFirestore.instance.collection("superPath");
  final CollectionReference pathCollection =
      FirebaseFirestore.instance.collection("path");
  final CollectionReference timeSpanCollection =
      FirebaseFirestore.instance.collection("timeSpan");
  final CollectionReference systemAccountCollection =
      FirebaseFirestore.instance.collection("systemRequirementAccount");

  DateFormat dateFormat = DateFormat("yMd");

  Csp _mapDocSnapToCsp(QuerySnapshot querySnapshot) {
    return Csp(
        name: querySnapshot.docs[0].get("name"),
        identifier: querySnapshot.docs[0].get("cspIdentifier"),
        cspID: querySnapshot.docs[0].id,
        systemAccountId: querySnapshot.docs[0].get("systemAccountId"));
  }

  // NEW
  SystemRequirementAccount _mapDocSnapToSystemAccount(
      DocumentSnapshot documentSnapshot) {
    Timestamp startTime, endTime;
    startTime = documentSnapshot.get("startTime");
    endTime = documentSnapshot.get("endTime");
    DateTime startDateTime = startTime.toDate().toLocal();
    DateTime endDateTime = endTime.toDate().toLocal();

    return SystemRequirementAccount(
        // docID: documentSnapshot.id,
        // name: documentSnapshot.get("regionName"),
        allowedEndingTime: endDateTime,
        allowedStartingTime: startDateTime,
        timeZoneOffset:
            int.parse(documentSnapshot.get("timeZoneOffset").toString()));
  }
  //

  Csp _mapToCspForStream(DocumentSnapshot documentSnapshot) {
    return Csp(
        status: documentSnapshot.get("status"),
        disabled: documentSnapshot.get("disabled"));
  }

  List<BookedSpot> _mapQuerysnapToBookedSpot(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((doc) {
      return BookedSpot(
          name: doc.get("name"),
          phoneModel: doc.get("phoneModel"),
          phoneNumber: doc.get("phoneNumber"),
          plateNumber: doc.get("plateNumber"),
          docID: doc.id,
          registered: doc.get("registered"),
          scheduled: doc.get("scheduled"),
          mainRoutes: List.castFrom(doc.get("mainRoutes") as List ?? []));
    }).toList();
  }

  List<NewPathReport> _mapQuerSnapToNewPath(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      Timestamp timestamp = e.get("date");
      DateTime dateTime = timestamp.toDate();
      String newPathDate = dateFormat.format(dateTime);
      return NewPathReport(
          nickName: e.get("nickname"),
          additionalInfo: e.get("additionalInfo"),
          docID: e.id,
          startingLocation: e.get("startingLocation"),
          endingLocation: e.get("endingLocation"),
          date: newPathDate);
    }).toList();
  }

  List<FixClaim> _mapQuerSnapToFixClaim(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      Timestamp timestamp = e.get("createdDate");
      DateTime dateTime = timestamp.toDate();
      String reportedDate = dateFormat.format(dateTime);
      return FixClaim(
          createdDate: reportedDate,
          phoneNumber: e.get("phoneNumber"),
          plateNumber: e.get("plateNumber"),
          scheduled: e.get("scheduled"),
          docID: e.id,
          type: e.get("type"),
          urgent: e.get("urgent"));
    }).toList();
  }

  List<SuperPath> _mapQuerSnapToSuperPath(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      return SuperPath(
          docID: e.id,
          // startingLocation: e.get("startingLocation"),
          destination: e.get("destination"));
    }).toList();
  }

  List<PathClass> _mapQuerSnapToPaths(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      Map fireBaseMap = e.get("dropOffLocations");
      Map<String, GeoPoint> dropOffs = {};
      fireBaseMap.forEach((key, value) {
        dropOffs[key] = GeoPoint(value.latitude, value.longitude);
      });
      return PathClass(
          startingLocationName: e.get("startingLocationName"),
          destinationName: e.get("destinationName"),
          boardingRange: e.get("boardingRange"),
          destinationRange: e.get("destinationRange"),
          destinationBuffer: e.get("destinationBuffer"),
          efficiencyAccuracyRange: e.get("efficiencyAccuracyRange"),
          pathName: e.get("pathName"),
          dropOffLocations: dropOffs,
          docID: e.id,
          timetaken: e.get("timeTaken"));
    }).toList();
  }

  Future<QuerySnapshot> cspAccountExist(String phoneNumber) async {
    return await cspCollection
        .where("phoneNumber", isEqualTo: phoneNumber)
        .limit(1)
        .get();
  }

  Future<Csp> retrieveAccount(String phoneNumber) {
    return cspCollection
        .where("phoneNumber", isEqualTo: phoneNumber)
        .limit(1)
        .get()
        .then((value) => _mapDocSnapToCsp(value));
  }

  // NEW
  Future<SystemRequirementAccount> getSystemAccount(
      String systemAccountId) async {
    try {
      return systemAccountCollection
          .doc(systemAccountId)
          .get()
          .then(_mapDocSnapToSystemAccount);
    } catch (e) {
      return null;
    }
  }
  //

  Future<List<SuperPath>> getSuperPaths(String systemAccountId) {
    return superPathCollection
        .where("systemAccountId", isEqualTo: systemAccountId)
        .get()
        .then((value) => _mapQuerSnapToSuperPath(value));
  }

  Stream<Csp> getCspStatus(String cspDocID) {
    return cspCollection.doc(cspDocID).snapshots().map(_mapToCspForStream);
  }

  Stream<List<BookedSpot>> personalBookedSpot(
      String cspID, String systemAccountId) {
    return scheduleForRegistration
        .where("cspID", isEqualTo: cspID)
        .where("registered", isEqualTo: false)
        .where("scheduled", isEqualTo: true)
        .where("systemAccountId", isEqualTo: systemAccountId)
        .snapshots()
        .map(_mapQuerysnapToBookedSpot);
  }

  Stream<List<BookedSpot>> unattendedBookedSpots(String systemAccountId) {
    return scheduleForRegistration
        .where("registered", isEqualTo: false)
        .where("scheduled", isEqualTo: false)
        .where("systemAccountId", isEqualTo: systemAccountId)
        .orderBy("timestamp", descending: false)
        .snapshots()
        .map(_mapQuerysnapToBookedSpot);
  }

  Stream<List<NewPathReport>> newPathReports(String systemAccountId) {
    return newPathReportCollection
        .where("attended", isEqualTo: false)
        .where("systemAccountId", isEqualTo: systemAccountId)
        .orderBy("date", descending: false)
        .snapshots()
        .map(_mapQuerSnapToNewPath);
  }

  Stream<List<FixClaim>> personalScheduledfixClaims(
      String systemAccountId, String cspID) {
    return fixClaimCollection
        .where("systemAccountId", isEqualTo: systemAccountId)
        .where("status", isEqualTo: 0)
        // .where("type", whereIn: ["SSE", "VRD", "ASD", "COT", "COP", "SSU"])
        .where("type", whereIn: ["SSF", "TIC", "COT", "CSP", "SSU"])
        .where("scheduled", isEqualTo: true)
        .where("cspID", isEqualTo: cspID)
        // Sorting is UNNECESSARY here but certainly can
        // be used
        // .orderBy("urgent", descending: true)
        // .orderBy("createdDate", descending: false)
        .snapshots()
        .map(_mapQuerSnapToFixClaim);
  }

  Stream<List<FixClaim>> unScheduledfixClaims(String systemAccountId) {
    try {
      return fixClaimCollection
          .where("systemAccountId", isEqualTo: systemAccountId)
          .where("status", isEqualTo: 0)
          // .where("type", whereIn: ["SSE", "VRD", "ASD", "COT", "COP", "SSU"])
          .where("type", whereIn: ["SSF", "TIC", "COT", "CSP", "SSU"])
          .where("scheduled", isEqualTo: false)
          .orderBy("urgent", descending: true)
          .orderBy("createdDate", descending: false)
          .snapshots()
          .map(_mapQuerSnapToFixClaim);
    } catch (e) {
      print("Error: " + e.toString());
      return null;
    }
  }

  Stream<List<PathClass>> getPaths(String systemAccountId, String cspID) {
    return pathCollection
        .where("systemAccountId", isEqualTo: systemAccountId)
        .where("cspID", isEqualTo: cspID)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(_mapQuerSnapToPaths);
  }

  Future markBookedSpotAsRegistered(String spotID) {
    return scheduleForRegistration.doc(spotID).update({"registered": true});
  }

  Future scheduleSpot(String cspID, String spotID) {
    return scheduleForRegistration
        .doc(spotID)
        .update({"cspID": cspID, "scheduled": true});
  }

  Future unScheduleSpot(String cspID, String spotID) async {
    return scheduleForRegistration
        .doc(spotID)
        .update({"cspID": cspID, "scheduled": false});
  }

  Future markAsAttended(String newPathDocID) {
    return newPathReportCollection.doc(newPathDocID).update({"attended": true});
  }

  Future scheduleFixClaim(String fixClaimDocId, String cspID) {
    return fixClaimCollection
        .doc(fixClaimDocId)
        .update({"scheduled": true, "cspID": cspID});
  }

  Future unScheduleFixClaim(String fixClaimDocId) async {
    return fixClaimCollection.doc(fixClaimDocId).update({"scheduled": false});
  }

  Future<bool> createPath(
      int initialTime,
      Map<String, GeoPoint> dropOffLocations,
      String cspID,
      String systemAccountId,
      int timeTaken,
      int boardingRange,
      int destinationRange,
      int destinationBuffer,
      int distanceEfficiency,
      int efficiencyAccuracyRange,
      String pathName,
      GeoPoint startingLocation,
      GeoPoint destination,
      // String startingLocationName,
      String destinationName,
      String superPathDocId) async {
    int originalTimeTaken = timeTaken;
    QuerySnapshot timeSpanQuery = await timeSpanCollection
        .where("systemAccountId", isEqualTo: systemAccountId)
        .where("length", isEqualTo: timeTaken)
        .limit(1)
        .get();
    DocumentSnapshot systemAccountDoc =
        await systemAccountCollection.doc(systemAccountId).get();

    if (timeSpanQuery.docs.length == 0 || !systemAccountDoc.exists) {
      return false;
    } else {
      String timeSpanID = timeSpanQuery.docs[0].id;
      int maximumWaitTime = timeSpanQuery.docs[0].get("maximumWaitTime");
      int bufferLength = timeSpanQuery.docs[0].get("bufferLength");

      int maximumLengthPerAdBrake =
          systemAccountDoc.get("adBrakeMaximumLength");
      // because one length equals to 30 second in our system
      maximumLengthPerAdBrake = maximumLengthPerAdBrake * 30;
      bufferLength *= 60;
      timeTaken *= 60;
      int rast = bufferLength + maximumLengthPerAdBrake;

      if (timeTaken < (initialTime + maximumLengthPerAdBrake)) {
        // cant even serve one Ad brake fully but it can serve
        // some ads so its uploaded
        return pathCollection
            .doc()
            .set({
              "initialTime": (initialTime / 60),
              "maximumAmountOfAdBrake": 1,
              "dropOffLocations": dropOffLocations,
              "maximumWaitTime": maximumWaitTime,
              "timeSpanID": timeSpanID,
              "cspID": cspID,
              "boardingRange": boardingRange,
              "destinationRange": destinationRange,
              "destinationBuffer": destinationBuffer,
              "distanceEfficiency": distanceEfficiency,
              "efficiencyAccuracyRange": efficiencyAccuracyRange,
              "systemAccountId": systemAccountId,
              "pathName": pathName,
              "startingLocation": startingLocation,
              "destination": destination,
              "superPathID": superPathDocId,
              "startingLocationName": "",
              "destinationName": destinationName,
              "timeTaken": originalTimeTaken,
              "timestamp": Timestamp.now()
            })
            .then((value) => true)
            .catchError((err) => false);
      } else {
        // because the first ad is played immediately after
        // vehicle exist the starting range
        timeTaken -= initialTime + maximumLengthPerAdBrake;
        int maximumAmountOfAdBrake = timeTaken ~/ rast;
        // added because of the first ad that is played immediately
        maximumAmountOfAdBrake += 1;
        if (maximumAmountOfAdBrake > 3) {
          maximumAmountOfAdBrake = 3;
        }
        return pathCollection
            .doc()
            .set({
              "initialTime": (initialTime / 60),
              "maximumAmountOfAdBrake": maximumAmountOfAdBrake,
              "dropOffLocations": dropOffLocations,
              "maximumWaitTime": maximumWaitTime,
              "timeSpanID": timeSpanID,
              "cspID": cspID,
              "boardingRange": boardingRange,
              "destinationRange": destinationRange,
              "destinationBuffer": destinationBuffer,
              "distanceEfficiency": distanceEfficiency,
              "efficiencyAccuracyRange": efficiencyAccuracyRange,
              "systemAccountId": systemAccountId,
              "pathName": pathName,
              "startingLocation": startingLocation,
              "destination": destination,
              "superPathID": superPathDocId,
              "startingLocationName": "",
              "destinationName": destinationName,
              "timeTaken": originalTimeTaken,
              "timestamp": Timestamp.now()
            })
            .then((value) => true)
            .catchError((err) => false);
      }
    }
  }

  Future<bool> updateDropOff(
      Map<String, GeoPoint> dropOffLocations, String pathDocId) {
    return pathCollection
        .doc(pathDocId)
        .update({"dropOffLocations": dropOffLocations})
        .then((value) => true)
        .catchError((err) {
          return false;
        });
  }

  Future<bool> savePathChanges(
      Map<String, GeoPoint> dropOffLocations,
      int efficiencyRange,
      int startingRange,
      int destinationRange,
      int destinationBuffer,
      String pathDocId) {
    return pathCollection
        .doc(pathDocId)
        .update({
          "dropOffLocations": dropOffLocations,
          "boardingRange": startingRange,
          "destinationRange": destinationRange,
          "destinationBuffer": destinationBuffer,
          "efficiencyAccuracyRange": efficiencyRange,
        })
        .then((value) => true)
        .catchError((err) => false);
  }

  Future<bool> deletePath(String pathDocID) async {
    return pathCollection
        .doc(pathDocID)
        .delete()
        .then((value) => true)
        .catchError((e) => false);
  }
}
