import 'package:audio_record/Classes/adBreakAlgorithm.dart';
import 'package:audio_record/Classes/location_data.dart';
// import 'package:audio_record/Models/CompData.dart';
import 'package:audio_record/Models/adAudio.dart';
import 'package:audio_record/Models/carModel.dart';
import 'package:audio_record/Models/driver.dart';
import 'package:audio_record/Models/fixClaimModel.dart';
import 'package:audio_record/Models/path.dart';
import 'package:audio_record/Models/penality.dart';
import 'package:audio_record/Models/superPath.dart';
import 'package:audio_record/Models/systemAccount.dart';
import 'package:audio_record/Models/timeslot.dart';
import 'package:audio_record/Models/transaction.dart';
import 'package:audio_record/Models/transportVehicle.dart';
import 'package:audio_record/Models/trip.dart';
import 'package:audio_record/Models/tvAdModel.dart';
import 'package:audio_record/Service/cloudStorageServ.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DatabaseService {
  final CollectionReference driverCollection =
      FirebaseFirestore.instance.collection("driver");
  final CollectionReference systemAccountCollection =
      FirebaseFirestore.instance.collection("systemRequirementAccount");
  final CollectionReference superPathCollection =
      FirebaseFirestore.instance.collection("superPath");
  final CollectionReference cspCollection =
      FirebaseFirestore.instance.collection("csp");
  final CollectionReference tvCollection =
      FirebaseFirestore.instance.collection("transportVehicle");
  final CollectionReference carModelCollection =
      FirebaseFirestore.instance.collection("carModel");
  final CollectionReference fixClaimCollection =
      FirebaseFirestore.instance.collection("fixClaim");
  // final CollectionReference adCardCollection =
  //     FirebaseFirestore.instance.collection("adCard");
  final CollectionReference tempAdCardColl =
      FirebaseFirestore.instance.collection("AdCardTemp");
  final CollectionReference adCardSetupCollection =
      FirebaseFirestore.instance.collection("adCardSetup");
  final CollectionReference tempAdAudioCollection =
      FirebaseFirestore.instance.collection("AdAudioTest");
  // final CollectionReference adAudioCollection =
  //     FirebaseFirestore.instance.collection("adAudio");
  final CollectionReference transactionCollection =
      FirebaseFirestore.instance.collection("transaction");
  final CollectionReference penaltyCollection =
      FirebaseFirestore.instance.collection("penalities");
  final CollectionReference tripCollection =
      FirebaseFirestore.instance.collection("route");
  final CollectionReference tvAdCollection =
      FirebaseFirestore.instance.collection("tvAD");
  final CollectionReference pathCollection =
      FirebaseFirestore.instance.collection("path");
  final CollectionReference adCompilCollection =
      FirebaseFirestore.instance.collection("AdCompilation");
  // check if both collection name are correct
  final CollectionReference timeSlotCollection =
      FirebaseFirestore.instance.collection("timeSlot");
  final CollectionReference timeSpanCollection =
      FirebaseFirestore.instance.collection("timeSpan");
  final CollectionReference mainPayAccCollection =
      FirebaseFirestore.instance.collection("mainPaymentAccount");
  final CollectionReference tempTransaction =
      FirebaseFirestore.instance.collection("tempTransaction");
  final CollectionReference tempRouteCollection =
      FirebaseFirestore.instance.collection("routeTest1");
  // Support page collections
  final CollectionReference newPathReportCollection =
      FirebaseFirestore.instance.collection("new_path_Report");
  final CollectionReference registrationScheduleCollection =
      FirebaseFirestore.instance.collection("scheduled_for_registration");

  DateFormat dateFormat = DateFormat("yMd");
  DateFormat timeFormat = DateFormat("jm");

  Future<List<AdAudio>> returnAdAudios(
      QuerySnapshot adCardQuery, String tvDocID) async {
    try {
      List<AdAudio> adAudios = [];
      for (var element in adCardQuery.docs) {
        DocumentSnapshot docSnap =
            await tempAdAudioCollection.doc(element.get("adAudioID")).get();
        print(docSnap.data());
        AdAudio adAudio = _mapDocSnapTOAdAudio(
            docSnap, element.get("name"), element.id, tvDocID);
        adAudios.add(adAudio);
      }
      return adAudios;
    } catch (e) {
      print("Error: " + e.toString());
      return null;
    }
  }

  List<SuperPath> _mapQuerySnapToSuperPath(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      return SuperPath(
          docID: e.id,
          startingLocation: e.get("startingLocation"),
          destination: e.get("destination"));
    }).toList();
  }

  List<SuperPath> _mapToSuperPathForStartPage(QuerySnapshot querySnapshot) {
    int counter = 0;
    return querySnapshot.docs.map((e) {
      int substringMinus = 1;
      if (counter > 9) {
        substringMinus = 2;
      } else if (counter > 99) {
        substringMinus = 3;
      } else if (counter > 999) {
        substringMinus = 4;
      }
      // String startLoc = e.get("startingLocation");
      // startLoc = startLoc.length < 14
      //     ? startLoc
      //     : startLoc.substring(0, 10 - substringMinus) + "...";
      String dest = e.get("destination");
      dest = dest.length < 20 - substringMinus
          ? dest + " /" + counter.toString()
          : dest.substring(0, 16 - substringMinus) +
              " /" +
              counter.toString() +
              "...";
      counter++;
      return SuperPath(
          docID: e.id,
          // startingLocation: startLoc,
          startingLocation: "",
          destination: dest,
          spPrice: double.parse(e.get("price").toString()));
    }).toList();
  }

  List<SystemRequirementAccount> _mapQuerySnapToSystemAccount(
      QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      return SystemRequirementAccount(
        docID: e.id,
        name: e.get("regionName"),
      );
    }).toList();
  }

  List<Driver> _mapQuerySnapToDriver(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      return Driver(
        phoneID: e.get("phoneID"),
        banned: e.get("banned"),
        docID: e.id,
        systemAccountID: e.get("systemAccountId"),
      );
    }).toList();
  }

  List<CarModel> _mapQuerySnapToCarModel(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      return CarModel(carModelDocID: e.id, name: e.get("name"));
    }).toList();
  }

  List<TransactionModel> _mapQuerySnapToTransactionModel(
      QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      Timestamp timestamp = e.get("timestamp");
      DateTime dateTime = timestamp.toDate();
      String transDate = dateFormat.format(dateTime);
      return TransactionModel(amount: e.get("amount"), date: transDate);
    }).toList();
  }

  List<PenalityModel> _mapQuerySnapToPenalityModel(
      QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      Timestamp suspensionTimestamp = e.get("createdDate");
      Timestamp returnTimeStamp = e.get("returnDate");
      DateTime suspensionDateTime = suspensionTimestamp.toDate();
      DateTime returnDateTime = returnTimeStamp.toDate();
      String suspensionDate = dateFormat.format(suspensionDateTime);
      String returnDate = dateFormat.format(returnDateTime);
      PenalityModel penalityModel = PenalityModel(
          type: e.get("type"),
          returnDate: returnDate,
          suspensionDate: suspensionDate,
          suspensionLength: e.get("duration"));
      penalityModel.defineType(penalityModel.type);
      return penalityModel;
    }).toList();
  }

  List<TripModel> _mapQuerySnapToTripModel(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      Timestamp tripStartTime = e.get("startTime");
      Timestamp tripEndTime = e.get("endTime");
      DateTime tripStartDate = tripStartTime.toDate();
      DateTime tripEnddateTime = tripEndTime.toDate();
      String date = dateFormat.format(tripStartDate);
      String startTime = timeFormat.format(tripStartDate);
      String endTime = timeFormat.format(tripEnddateTime);
      return TripModel(
          adServed: e.get("numberOfAdServed"),
          numberOfAvailableAds: e.get("numberOfAvailableAds"),
          date: date,
          startTime: startTime,
          endTime: endTime,
          pathName: e.get("pathName"),
          profit: double.parse(e.get("profit").toString()),
          availableProfit: double.parse(e.get("availableProfit").toString()),
          imageStatus: e.get("imageStatus"),
          status: e.get("status"),
          totalRoutes: e.get("totalRoutes"),
          weeklyRoutes: e.get("weeklyRoutes"));
    }).toList();
  }

  List<TVAdModel> _mapTvAdForOsc(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.map((e) {
      return TVAdModel(
          adName: e.get("adName"),
          docID: e.id,
          uniqueName: e.get("uniqueName"));
    }).toList();
  }

  List<PathModel> _mapQuerySnapToPathModel(QuerySnapshot querySnapshot) {
    int counter = 0;
    return querySnapshot.docs.map((e) {
      Map<String, dynamic> dropOffObject = e.get("dropOffLocations");
      List<LocationData> dropOffLocations = [];
      dropOffObject.forEach((key, value) {
        dropOffLocations.add(
            LocationData(latitude: value.latitude, longitude: value.longitude));
      });
      GeoPoint startLocation = e.get("startingLocation"),
          endLocation = e.get("destination");
      String name = e.get("pathName");
      int substringMinus = 1;
      if (counter > 9) {
        substringMinus = 2;
      } else if (counter > 99) {
        substringMinus = 3;
      } else if (counter > 999) {
        substringMinus = 4;
      }
      name = name.length < 39 - substringMinus
          ? name + " /" + counter.toString()
          : name.substring(0, 35 - substringMinus) +
              " /" +
              counter.toString() +
              "...";
      counter++;
      return PathModel(
          pathDocID: e.id,
          name: name,
          pathAdBrakeNum: e.get("maximumAmountOfAdBrake"),
          startingLocation: LocationData(
              latitude: startLocation.latitude,
              longitude: startLocation.longitude),
          endingLocation: LocationData(
              latitude: endLocation.latitude, longitude: endLocation.longitude),
          adStopRange: double.parse(e.get("destinationBuffer").toString()),
          endingRange: double.parse(e.get("destinationRange").toString()),
          startingRange: double.parse(e.get("boardingRange").toString()),
          dropOffs: dropOffLocations);
    }).toList();
  }

  Driver _mapDriverForStream(DocumentSnapshot documentSnapshot) {
    var routesObject = documentSnapshot.get("mainRoutes");
    List<String> mainroutes = [];
    for (var item in routesObject) {
      mainroutes.add(item);
    }

    List<dynamic> dailyValueArray = documentSnapshot.get("dailyValue");
    Map<String, dynamic> dailyValueMaps =
        dailyValueArray[dailyValueArray.length - 1];
    Timestamp dailyValueDate = dailyValueMaps["date"];
    DateTime date = dailyValueDate.toDate().toLocal();
    var dailyStatus = dailyValueMaps["dailyStatus"];

    return Driver(
        docID: documentSnapshot.id,
        banned: documentSnapshot.get("banned"),
        status: documentSnapshot.get("status"),
        balance: documentSnapshot.get("balance"),
        potentialBalance: documentSnapshot.get("potentialBalance"),
        phoneNumber: documentSnapshot.get("phoneNumber"),
        plateNumber: documentSnapshot.get("plateNumber"),
        // the parse is useful to set the dynamic value as
        // as double. Balance and potential balance are set
        // to double when they are assigned to drawer widget
        // but they could have been done here as well
        totalProfit:
            double.parse(documentSnapshot.get("totalProfit").toString()),
        calibration:
            double.parse(documentSnapshot.get("calibrationValue").toString()),
        mainRoutes: mainroutes,
        recentDailyDate: date,
        recentDailyStatus: dailyStatus,
        failedFix: documentSnapshot.get("failedFix"),
        systemAccountID: documentSnapshot.get("systemAccountId"),
        name: documentSnapshot.get("name"));
  }

  Driver _mapDriverForEdit(DocumentSnapshot documentSnapshot) {
    var routesObject = documentSnapshot.get("mainRoutes");
    List<String> mainroutes = [];
    for (var item in routesObject) {
      mainroutes.add(item);
    }
    String plateNumber = "";
    Map<String, dynamic> map = documentSnapshot.data();
    if (map.containsKey("plateNumber")) {
      plateNumber = map["plateNumber"];
    }

    return Driver(
        calibration: documentSnapshot.get("calibrationValue"),
        bankAccount: documentSnapshot.get("bankAccountNumber"),
        systemAccountID: documentSnapshot.get("systemAccountId"),
        mainRoutes: mainroutes,
        plateNumber: plateNumber,
        name: documentSnapshot.get("name"));
  }

  TransportVehicle _mapTvForEdit(QuerySnapshot querySnapshot) {
    if (querySnapshot.docs.isEmpty) {
      return TransportVehicle(
          plateNumber: "",
          tvDocID: "",
          engineSoundPollution: true,
          systemAccountId: "",
          speakerPosition: 0,
          carModelID: "",
          imageUrl: "",
          speakerQuality: true);
    } else {
      return TransportVehicle(
          plateNumber: querySnapshot.docs[0].get("plateNumber"),
          tvDocID: querySnapshot.docs[0].id,
          carModelID: querySnapshot.docs[0].get("carModelID"),
          engineSoundPollution:
              querySnapshot.docs[0].get("engineSoundPollution"),
          imageUrl: querySnapshot.docs[0].get("imageUrl"),
          systemAccountId: querySnapshot.docs[0].get("systemAccountId"),
          speakerPosition: querySnapshot.docs[0].get("speakerPosition"),
          speakerQuality: querySnapshot.docs[0].get("speakerQuality"));
    }
  }

  AdAudio _mapDocSnapTOAdAudio(DocumentSnapshot documentSnapshot, String name,
      String adCardID, String tvDocID) {
    return AdAudio(
        uniqueName: documentSnapshot.get("uniqueName"),
        name: name,
        adCardID: adCardID,
        tvDocID: tvDocID,
        hash: documentSnapshot.get("hash"),
        audioUrl: documentSnapshot.get("audioUrl"));
  }

  FixClaimModel _mapDocSnapToFixClaim(QuerySnapshot querySnapshot) {
    return querySnapshot.docs.isNotEmpty
        ? FixClaimModel(
            scheduled: querySnapshot.docs[0].get("scheduled"),
            urgent: querySnapshot.docs[0].get("urgent"),
            docID: querySnapshot.docs[0].id)
        : null;
  }

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
        // tvStatus: documentSnapshot.get("vehicleStatus"),
        allowedEndingTime: endDateTime,
        allowedStartingTime: startDateTime,
        timeZoneOffset:
            int.parse(documentSnapshot.get("timeZoneOffset").toString()));
  }

  TransportVehicle _mapTvForSat(QuerySnapshot querySnapshot) {
    return TransportVehicle(
      carModelID: querySnapshot.docs[0].get("carModelID"),
      // tvDocID: querySnapshot.docs[0].id,
    );
  }

  CarModel _mapCarForSat(DocumentSnapshot documentSnapshot) {
    return CarModel(
        lemz: double.parse(documentSnapshot.get("lemz").toString()),
        hemz: double.parse(documentSnapshot.get("hemz").toString()));
  }

  CarModel _mapCarForStartPage(DocumentSnapshot documentSnapshot) {
    return CarModel(
        carModelDocID: documentSnapshot.id,
        lemz: double.parse(documentSnapshot.get("lemz").toString()),
        hemz: double.parse(documentSnapshot.get("hemz").toString()),
        passengerSize: documentSnapshot.get("maxPassenger"),
        pricePercentage:
            double.parse(documentSnapshot.get("percentage").toString()),
        lms: documentSnapshot.get("lms"),
        hms: documentSnapshot.get("hms"),
        vhms: documentSnapshot.get("vhms"),
        cs: documentSnapshot.get("cs"));
  }

  Future<Driver> getDriverData(String driverDocID) {
    return driverCollection.doc(driverDocID).get().then(_mapDriverForEdit);
  }

  Future<TransportVehicle> getTVdata(String driverDocID) {
    return tvCollection
        .where("driverID", isEqualTo: driverDocID)
        .limit(1)
        .get()
        .then(_mapTvForEdit);
  }

  Future<FixClaimModel> getFixClaim(String driverDocID) {
    return fixClaimCollection
        .where("driverID", isEqualTo: driverDocID)
        .where("status", isEqualTo: 0)
        .limit(1)
        .get()
        .then(_mapDocSnapToFixClaim);
  }

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

  Future<TransportVehicle> getTVforSat(String driverID) {
    try {
      return tvCollection
          .where("driverID", isEqualTo: driverID)
          .get()
          .then(_mapTvForSat);
    } catch (e) {
      return null;
    }
  }

  Future<CarModel> getCarModelForSat(String carModelID) {
    try {
      return carModelCollection.doc(carModelID).get().then(_mapCarForSat);
    } catch (e) {
      return null;
    }
  }

  Future<String> getStandardAudiourl(String systemAccountID) {
    return systemAccountCollection
        .doc(systemAccountID)
        .get()
        .then((value) => value.get("saUrl").toString())
        .catchError((e) => "f");
  }

  Future<bool> tvAdExist(String adCardID, String tvID) {
    return tvAdCollection
        .where("adCardID", isEqualTo: adCardID)
        .where("tvID", isEqualTo: tvID)
        .get()
        .then((value) => value.docs.isNotEmpty)
        // so that if error happens we dont write a
        // new tvAD because it might already exist and
        // will just write the next time the user enters
        // ads page
        .catchError((e) => true);
  }

  Future<CarModel> getCarForOsc(String driverID) async {
    try {
      String carModelID =
          await driverCollection.doc(driverID).get().then((value) async {
        List<dynamic> dailyValueArray = value.get("dailyValue");
        Map<String, dynamic> dailyValueMaps =
            dailyValueArray[dailyValueArray.length - 1];
        String tvID = dailyValueMaps["tvID"];

        return tvCollection.doc(tvID).get().then((cm) {
          return cm.get("carModelID");
        });
      });
      return carModelCollection.doc(carModelID).get().then(_mapCarForSat);
    } catch (e) {
      return null;
    }
  }

  Future<CarModel> getCarForStartPage(String driverID) async {
    try {
      String carModelID =
          await driverCollection.doc(driverID).get().then((value) async {
        List<dynamic> dailyValueArray = value.get("dailyValue");
        Map<String, dynamic> dailyValueMaps =
            dailyValueArray[dailyValueArray.length - 1];
        String tvID = dailyValueMaps["tvID"];

        return tvCollection.doc(tvID).get().then((cm) {
          return cm.get("carModelID");
        });
      });
      return carModelCollection.doc(carModelID).get().then(_mapCarForStartPage);
    } catch (e) {
      return null;
    }
  }

  // Future<CompData> getCompData(String superPathID, String timeSlotID,
  //     String carModelID, String pathID) async {
  //   int adBrakeNum = await pathCollection
  //       .doc(pathID)
  //       .get()
  //       .then((value) => value.get("maximumAmountOfAdBrake"));
  //   // when combining target variables to produce setup we have to be sure the
  //   // order is cm => ts => sp
  //   String setup = carModelID + "-" + timeSlotID + "-" + superPathID;
  //   return adCompilCollection
  //       .where("availableSetups", arrayContains: setup)
  //       .orderBy("timeScore")
  //       // .orderBy("tl2")
  //       .limit(1)
  //       .get()
  //       .then((value) async {
  //     double profit = 0;
  //     Map<String, List<double>> listOfFrequency =
  //         value.docs[0].get("list_of_frequency");
  //     List<double> results = listOfFrequency[setup];
  //     if (results[0] >= adBrakeNum) {
  //       profit = results[adBrakeNum];
  //     } else {
  //       profit = results[int.parse(results[0].toString())];
  //     }
  //     List<String> adCardIds = [];
  //     var adCardIdsObj = value.docs[0].get("listOfAdCards");
  //     for (var item in adCardIdsObj) {
  //       adCardIds.add(item);
  //     }
  //     List<CompAdCardData> compAdCards = [];
  //     for (var item in adCardIds) {
  //       tempAdCardColl.doc(item).get().then((adCard) {
  //         adAudioCollection.doc(adCard.get("adAudioID")).get().then((adAudio) {
  //           compAdCards.add(CompAdCardData(
  //               audioUniqueName: adAudio.get("uniqueName"),
  //               hash: adAudio.get("hash"),
  //               adCardDocID: adCard.id));
  //         });
  //       });
  //     }
  //     return CompData(
  //         listOfAdCards: compAdCards,
  //         profit: profit,
  //         adBreakNum: int.parse(results[0].toString()));
  //   });
  // }

  Future<CompilationForServe> getAdcards(
      String superPathID,
      String timeSlotID,
      String carModelID,
      String pathID,
      String systemAccountID,
      String driverID,
      bool badSetup,
      double calibrationValue,
      double tsPercentage,
      double cmPercentage,
      double spPrice,
      double lemz,
      double hemz,
      int passengerSize) async {
    try {
      bool remove = false;
      int bufferLength = 1,
          adBrakeNum = 1,
          pathEffRang = 1,
          pathMaximumWaitTime = 60;
      double pathEfficiency = 1;
      String pathName = "";
      await pathCollection.doc(pathID).get().then((pathDoc) async {
        adBrakeNum = pathDoc.get("maximumAmountOfAdBrake");
        pathEfficiency =
            double.parse(pathDoc.get("distanceEfficiency").toString());
        pathEffRang = pathDoc.get("efficiencyAccuracyRange");
        pathName = pathDoc.get("pathName");
        pathMaximumWaitTime = pathDoc.get("maximumWaitTime");
        await timeSpanCollection.doc(pathDoc.get("timeSpanID")).get().then(
            (timeSpanDoc) => bufferLength = timeSpanDoc.get("bufferLength"));
      });
      int maximumLengthPerAdbrake = await systemAccountCollection
          .doc(systemAccountID)
          .get()
          .then((value) => value.get("adBrakeMaximumLength"));
      String tvID = await tvCollection
          .where("driverID", isEqualTo: driverID)
          .limit(1)
          .get()
          .then((value) => value.docs[0].id);
      double systemPriceCut, badSetupCut;
      await systemAccountCollection.doc(systemAccountID).get().then((value) {
        systemPriceCut = double.parse(value.get("priceCut").toString());
        badSetupCut = double.parse(value.get("badSetupCut").toString());
      });
      if (badSetup) {
        systemPriceCut += badSetupCut;
        // As additional check
        if (systemPriceCut > 100) {
          systemPriceCut = 100;
        }
      }
      // when combining target variables to produce setup we have to be sure the
      // order is cm => ts => sp
      String setup = carModelID + "-" + timeSlotID + "-" + superPathID;
      AdCompilation adCompilation = new AdCompilation(listOfCard: []);
      double tsDeductable = (tsPercentage / 100) * spPrice;
      double cmDeductable = (cmPercentage / 100) * spPrice;
      double pricePerSlot = spPrice - tsDeductable - cmDeductable;
      // print("Price Per Slot: " + pricePerSlot.toString());
      // List<List<AdCard>> adBreakCards = [];
      CompilationForServe compilationForServe;
      DocumentSnapshot lastVisible;
      int missingAds = 0;
      for (var i = 1; i > 0; i++) {
        bool breakFromLoop = false;
        int returnedDocsNum = 0;
        List<AdCard> tempAdCards = [];
        if (i != 1) {
          await adCardSetupCollection
              .where("activeForDate", isEqualTo: true)
              .where("availableSetups", arrayContains: setup)
              .orderBy("timeScore", descending: true)
              .orderBy("length", descending: true)
              .orderBy("frequency_per_route", descending: true)
              .startAfterDocument(lastVisible)
              .limit(8)
              .get()
              .then((value) async {
            returnedDocsNum = value.docs.length;
            lastVisible = value.docs[value.docs.length - 1];
            for (var element in value.docs) {
              int freqPerRoute = element.get("frequency_per_route");
              // Map<String, List<double>> listOfFrequency =
              //     element.get("list_of_frequency");
              // List<double> results = listOfFrequency[setup];
              // if (results[0] < freqPerRoute) {
              //   freqPerRoute = int.parse(results[0].toString());
              // }
              // double profit = double.parse(results[1].toString());
              double balance =
                  double.parse(element.get("adCardBalance").toString());
              int length = element.get("length");
              int freqLeft = balance ~/ (pricePerSlot * length);
              if (freqLeft < freqPerRoute) {
                freqPerRoute = freqLeft;
              }
              String adCardID = element.get("adCardID");
              double profit = length * pricePerSlot;
              double systemCut = (systemPriceCut / 100) * profit;
              profit -= systemCut;
              String uniqueName, hash, tvAdID;
              bool silent, loud, preProcessed, warning;
              double seir;
              int volumeDecrease;
              bool tvAdExist = false;
              await tvAdCollection
                  .where("adCardID", isEqualTo: adCardID)
                  .where("tvID", isEqualTo: tvID)
                  .limit(1)
                  .get()
                  .then((tvAd) {
                // print("TvID: " + tvID + "adID : " + adCardID);
                // print("tvAd: " + tvAd.size.toString());
                if (tvAd.docs.isNotEmpty) {
                  tvAdExist = true;
                  uniqueName = tvAd.docs[0].get("uniqueName");
                  hash = tvAd.docs[0].get("hash");
                  tvAdID = tvAd.docs[0].id;
                  silent = tvAd.docs[0].get("silent");
                  loud = tvAd.docs[0].get("loud");
                  preProcessed = tvAd.docs[0].get("preProcessed");
                  warning = tvAd.docs[0].get("warning");
                  seir = double.parse(tvAd.docs[0].get("seir").toString());
                  volumeDecrease = tvAd.docs[0].get("vd");
                }
                if (tvAdExist) {
                  tempAdCards.add(new AdCard(
                      name: adCardID,
                      uniqueName: uniqueName,
                      hash: hash,
                      silent: silent,
                      loud: loud,
                      preProcessed: preProcessed,
                      seir: seir,
                      tvAdId: tvAdID,
                      volumeDecrease: volumeDecrease,
                      warning: warning,
                      profit: profit,
                      length: length,
                      frequencyPerRoute: freqPerRoute));
                } else {
                  missingAds++;
                }
              });
            }
          });
        } else {
          await adCardSetupCollection
              .where("activeForDate", isEqualTo: true)
              .where("availableSetups", arrayContains: setup)
              .orderBy("timeScore", descending: true)
              .orderBy("length", descending: true)
              .orderBy("frequency_per_route", descending: true)
              .limit(8)
              .get()
              .then((value) async {
            if (value.docs.isNotEmpty) {
              lastVisible = value.docs[value.docs.length - 1];
            }
            returnedDocsNum = value.docs.length;
            for (var element in value.docs) {
              int freqPerRoute = element.get("frequency_per_route");
              // Map<String, List<double>> listOfFrequency =
              //     element.get("list_of_frequency");
              // List<double> results = listOfFrequency[setup];
              // if (results[0] < freqPerRoute) {
              //   freqPerRoute = int.parse(results[0].toString());
              // }
              // double profit = double.parse(results[1].toString());
              double balance =
                  double.parse(element.get("adCardBalance").toString());
              int length = element.get("length");
              int freqLeft = balance ~/ (pricePerSlot * length);
              if (freqLeft < freqPerRoute) {
                freqPerRoute = freqLeft;
              }
              String adCardID = element.get("adCardID");
              double profit = length * pricePerSlot;
              double systemCut = (systemPriceCut / 100) * profit;
              profit -= systemCut;
              String uniqueName, hash, tvAdID;
              bool silent, loud, preProcessed, warning;
              double seir;
              int volumeDecrease;
              bool tvAdExist = false;
              await tvAdCollection
                  .where("adCardID", isEqualTo: adCardID)
                  .where("tvID", isEqualTo: tvID)
                  .limit(1)
                  .get()
                  .then((tvAd) {
                // print("TvID: " + tvID + "adID : " + adCardID);
                // print("tvAd: " + tvAd.size.toString());
                if (tvAd.docs.isNotEmpty) {
                  tvAdExist = true;
                  uniqueName = tvAd.docs[0].get("uniqueName");
                  hash = tvAd.docs[0].get("hash");
                  tvAdID = tvAd.docs[0].id;
                  silent = tvAd.docs[0].get("silent");
                  loud = tvAd.docs[0].get("loud");
                  preProcessed = tvAd.docs[0].get("preProcessed");
                  warning = tvAd.docs[0].get("warning");
                  seir = double.parse(tvAd.docs[0].get("seir").toString());
                  volumeDecrease = tvAd.docs[0].get("vd");
                }
                if (tvAdExist) {
                  tempAdCards.add(new AdCard(
                      name: adCardID,
                      uniqueName: uniqueName,
                      hash: hash,
                      silent: silent,
                      loud: loud,
                      preProcessed: preProcessed,
                      seir: seir,
                      tvAdId: tvAdID,
                      volumeDecrease: volumeDecrease,
                      warning: warning,
                      profit: profit,
                      length: length,
                      frequencyPerRoute: freqPerRoute));
                } else {
                  missingAds++;
                }
              });
            }
          });
        }
        AudioCheckData audioCheckData = await audioCheck(tempAdCards);
        if (audioCheckData.hashFailed) {
          // print("Hash failed");
          FirebaseFirestore.instance.runTransaction((transaction) {
            DateTime cd = DateTime.now();
            int oneDay = 24 * 60 * 60 * 1000;
            DateTime returnDate = DateTime.fromMillisecondsSinceEpoch(
                cd.millisecondsSinceEpoch + oneDay);
            transaction.set(penaltyCollection.doc(), {
              "createdDate": Timestamp.now(),
              "returnDate": Timestamp.fromDate(returnDate),
              "driverID": driverID,
              "duration": 1,
              "type": "FF",
              "status": 0
            });
            transaction
                .update(driverCollection.doc(driverID), {"status": false});
            return null;
          });
        }
        AdCompilation tempAdCompilation = AdCompilation(listOfCard: []);
        tempAdCompilation.listOfCard.addAll(adCompilation.listOfCard);
        tempAdCompilation.listOfCard.addAll(audioCheckData.adCards);
        Map<int, List<String>> adBreakAdcards = adBreakAssignForDriver(
            tempAdCompilation, maximumLengthPerAdbrake, remove);
        // adBreakAdcards.forEach((key, value) {
        //   value.forEach((element) {
        //     print("Key : " + key.toString() + " " + element);
        //   });
        // });
        CompilationData compilationData = spotsLeftLength(
            maximumLengthPerAdbrake,
            adBrakeNum,
            adBreakAdcards,
            tempAdCompilation);
        adCompilation.listOfCard.clear();
        adCompilation.listOfCard
            .addAll(compilationData.adCompilation.listOfCard);
        remove = compilationData.remove;
        if (compilationData.spotsLeft == 0 || returnedDocsNum < 8) {
          // print("Return Doc: " +
          //     returnedDocsNum.toString() +
          //     " SpotLeft: " +
          //     compilationData.spotsLeft.toString());
          compilationForServe = returnCompForServe(
              adBreakAdcards,
              adCompilation,
              adBrakeNum,
              bufferLength,
              missingAds,
              carModelID,
              timeSlotID,
              superPathID,
              lemz,
              hemz,
              tvID,
              driverID,
              systemAccountID,
              pricePerSlot,
              pathName,
              pathID,
              badSetup,
              calibrationValue,
              pathEfficiency,
              pathEffRang,
              pathMaximumWaitTime,
              passengerSize);
          // compilationForServe.adbreakAdCards.forEach((element) {
          //   element.forEach((adCard) {
          //     print("Name: " +
          //         adCard.uniqueName +
          //         " " +
          //         adCard.songIndex.toString());
          //   });
          // });
          breakFromLoop = true;
        }
        if (breakFromLoop) {
          break;
        }
      }
      return compilationForServe;
    } catch (e) {
      print("Db error: " + e.toString());
      return null;
    }
  }

  Future<TimeSlotModel> getTimeslot(
      DateTime currentTime, String systemAccountID) {
    TimeSlotModel timeSlotModel;
    return timeSlotCollection
        .where("systemAccountId", isEqualTo: systemAccountID)
        .where("startTime",
            isLessThanOrEqualTo: Timestamp.fromDate(currentTime))
        .orderBy("startTime", descending: true)
        .limit(1)
        .get()
        .then((value) {
      if (value.docs.isNotEmpty) {
        // print("Ts ID: " + value.docs[0].id);
        DateTime cd = DateTime.now();
        DateTime endTime, tempEnd;
        // Timestamp startTimeStamp = value.docs[0].get("startTime");
        Timestamp endTimeStamp = value.docs[0].get("endTime");
        tempEnd = endTimeStamp.toDate();
        endTime = new DateTime(cd.year, cd.month, cd.day, tempEnd.hour,
            tempEnd.minute, tempEnd.second, tempEnd.millisecond);
        timeSlotModel = new TimeSlotModel(
            endTime: endTime,
            timeSlotID: value.docs[0].id,
            pricePercentage:
                double.parse(value.docs[0].get("percentage").toString()));
        return timeSlotModel;
      } else {
        return null;
      }
    });
  }

  Future<String> getPhoneNumber(String systemAccountID) {
    return systemAccountCollection
        .doc(systemAccountID)
        .get()
        .then((value) => value.get("phoneNumber"));
  }

  Future<List<Driver>> driverAccountExist(String phoneNumber) async {
    return await driverCollection
        .where("phoneNumber", isEqualTo: phoneNumber)
        .limit(1)
        .get()
        .then(_mapQuerySnapToDriver);
  }

  Future<List<SuperPath>> getMainRoutes(String systemAccountId) {
    return superPathCollection
        .where("systemAccountId", isEqualTo: systemAccountId)
        .get()
        .then((value) => _mapQuerySnapToSuperPath(value));
  }

  Future<List<SuperPath>> getMainRoutesForStartPage(String systemAccountId) {
    try {
      return superPathCollection
          .where("systemAccountId", isEqualTo: systemAccountId)
          .get()
          .then((value) => _mapToSuperPathForStartPage(value));
    } catch (e) {
      return null;
    }
  }

  Future<List<SystemRequirementAccount>> getRegions() {
    return systemAccountCollection.get().then(_mapQuerySnapToSystemAccount);
  }

  Future<List<CarModel>> getCarModels(String systemAccountID) {
    return carModelCollection
        .where("systemAccountId", isEqualTo: systemAccountID)
        .get()
        .then((value) {
      return _mapQuerySnapToCarModel(value);
    });
  }

  Future<List<AdAudio>> getAdDocs(String systemAccountId,
      List<String> mainRoutes, bool all, String driverID) async {
    try {
      String tvDocID = await tvCollection
          .where("driverID", isEqualTo: driverID)
          .limit(1)
          .get()
          .then((value) => value.docs[0].id);
      // print("tvid: " + tvDocID + " driverid: " + driverID);
      if (all) {
        QuerySnapshot adCardQuery = await tempAdCardColl
            .where("systemAccountID", isEqualTo: systemAccountId)
            .where("completed", isEqualTo: false)
            .orderBy("startDate", descending: true)
            .get();
        return await returnAdAudios(adCardQuery, tvDocID);
      } else {
        // QuerySnapshot adCardQuery = await tempAdCardColl
        //     .where("systemAccountId", isEqualTo: systemAccountId)
        //     .where("status", isEqualTo: true)
        //     .where("sp", arrayContainsAny: mainRoutes)
        //     .orderBy("startDate", descending: true)
        //     .get();
        QuerySnapshot adCardQuery = await tempAdCardColl
            .where("systemAccountID", isEqualTo: systemAccountId)
            .where("completed", isEqualTo: false)
            .where("sp", arrayContainsAny: mainRoutes)
            .orderBy("start_date", descending: true)
            .get();
        // print("Ad Card query: " +
        //     adCardQuery.docs.length.toString() +
        //     " " +
        //     systemAccountId);
        return await returnAdAudios(adCardQuery, tvDocID);
      }
    } catch (e) {
      print("Error: " + e.toString());
      return [];
    }
  }

  Future<List<TransactionModel>> getTransactions(String driverDocID) {
    return transactionCollection
        .where("reciever", isEqualTo: driverDocID)
        // meaning driver withdraw
        .where("specifictype", isEqualTo: 6)
        .orderBy("timestamp", descending: true)
        .limit(50)
        .get()
        .then(_mapQuerySnapToTransactionModel);
  }

  Future<List<PenalityModel>> getPenalities(String driverDocID) {
    return penaltyCollection
        .where("driverID", isEqualTo: driverDocID)
        .orderBy("createdDate", descending: true)
        .get()
        .then(_mapQuerySnapToPenalityModel);
  }

  Future<List<TripModel>> getTrips(String driverDocID) {
    // return tripCollection
    return tempRouteCollection
        .where("driverID", isEqualTo: driverDocID)
        .where("status", isEqualTo: 1)
        .orderBy("startTime", descending: true)
        // .orderBy("endTime", descending: true)
        .limit(20)
        // .limit(100)
        .get()
        .then(_mapQuerySnapToTripModel);
  }

  Future<List<TVAdModel>> getTvAds(String driverID) async {
    String tvID = await tvCollection
        .where("driverID", isEqualTo: driverID)
        .limit(1)
        .get()
        .then((value) => value.docs[0].id);
    // print("tV Id: " + tvID);
    return tvAdCollection
        .where("tvID", isEqualTo: tvID)
        .where("preProcessed", isEqualTo: false)
        .get()
        .then(_mapTvAdForOsc);
  }

  Future<List<PathModel>> getPaths(String superPathId) {
    return pathCollection
        .where("superPathID", isEqualTo: superPathId)
        .get()
        .then(_mapQuerySnapToPathModel);
  }

  Stream<bool> getTVstatus(String driverDocID) {
    return tvCollection
        .where("driverID", isEqualTo: driverDocID)
        .limit(1)
        .snapshots()
        .map((event) =>
            event.docs.length != 0 ? event.docs[0].get("status") : null);
  }

  Stream<Driver> getDriverStream(String driverDocID) {
    return driverCollection
        .doc(driverDocID)
        .snapshots()
        .map(_mapDriverForStream);
  }

  Stream<TransportVehicle> getTvStream(String driverDocID) {
    return tvCollection
        .where("driverID", isEqualTo: driverDocID)
        .limit(1)
        .snapshots()
        .map(_mapTvForEdit);
  }

  Future<String> createDriver(
      String name,
      String phoneNumber,
      String phoneID,
      String systemAccountId,
      String licenseNumber,
      String bankAccount,
      int cspIdentifier,
      List<String> mainRoutes) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        QuerySnapshot cspExistQuery = await cspCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("cspIdentifier", isEqualTo: cspIdentifier)
            .where("status", isEqualTo: true)
            .where("disabled", isEqualTo: false)
            .limit(1)
            .get();
        QuerySnapshot licenseNumberExist = await driverCollection
            .where("licenseNumber", isEqualTo: licenseNumber)
            .limit(1)
            .get();
        if (cspExistQuery.docs.length > 0 &&
            licenseNumberExist.docs.length == 0) {
          String cspID = cspExistQuery.docs[0].id;
          DocumentReference driverDocRef = driverCollection.doc();
          transaction.set(driverDocRef, {
            "cspID": cspID,
            "phoneNumber": phoneNumber,
            "phoneID": phoneID,
            "licenseNumber": licenseNumber,
            "mainRoutes": mainRoutes,
            "systemAccountId": systemAccountId,
            // creating dailyValues field at account creation is
            // useful because at all times there needs to be
            // atleast one daily value for the app to work
            // properly as its one of the first data the app read
            "dailyValue": [
              {
                "dailyStatus": 1,
                "date": Timestamp.fromDate(DateTime(2021, 2, 7)),
                "imageUrl": "no image",
                "tvID": "no tv"
              }
            ],
            // NEW
            "noDailyValueToCheck": true,
            //
            "failedFix": true,
            "calibrationValue": 0,
            "potentialBalance": 0,
            "balance": 0,
            "bankAccountNumber": bankAccount,
            "numberOfRoutePerDay": 0,
            "profitOfTheDay": 0,
            "totalProfit": 0,
            "name": name,
            "banned": false,
            "status": false
          });
          return {"val": driverDocRef.id};
          // return driverCollection.doc().set({
          //   "cspID": cspID,
          //   "phoneNumber": phoneNumber,
          //   "phoneID": phoneID,
          //   "licenseNumber": licenseNumber,
          //   "mainRoutes": mainRoutes,
          //   "systemAccountId": systemAccountId,
          //   // creating dailyValues field at account creation is
          //   // useful because at all times there needs to be
          //   // atleast one daily value for the app to work
          //   // properly as its one of the first data the app read
          //   "dailyValue": [
          //     {
          //       "dailyStatus": 1,
          //       "date": Timestamp.fromDate(DateTime(2021, 2, 7)),
          //       "imageUrl": "no image",
          //       "tvID": "no tv"
          //     }
          //   ],
          //   "failedFix": true,
          //   "calibrationValue": 0,
          //   "potentialBalance": 0,
          //   "balance": 0,
          //   "bankAccountNumber": bankAccount,
          //   "numberOfRoutePerDay": 0,
          //   "profitOfTheDay": 0,
          //   "totalProfit": 0,
          //   "name": name,
          //   "banned": false,
          //   "status": false
          // }).then((value) {
          //   return driverCollection
          //       .where("phoneNumber", isEqualTo: phoneNumber)
          //       .limit(1)
          //       .get()
          //       .then((value) => {"val": value.docs[0].id});
          // });
        } else {
          return {"val": "false"};
        }
      });
      return a["val"];
    } catch (e) {
      return "false";
    }
  }

  Future<bool> updateDriverAccount(
      String name,
      String systemAccountId,
      String plateNumber,
      double calibrationValue,
      String bankAccount,
      String driverDocID,
      String imageUrl,
      int cspIdentifier,
      List<String> mainRoutes) async {
    try {
      bool updated;
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        QuerySnapshot tvExist = await tvCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("plateNumber", isEqualTo: plateNumber)
            .limit(1)
            .get();
        QuerySnapshot cspExistQuery = await cspCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("cspIdentifier", isEqualTo: cspIdentifier)
            .where("status", isEqualTo: true)
            .where("disabled", isEqualTo: false)
            .limit(1)
            .get();
        QuerySnapshot fixClaimExist = await fixClaimCollection
            .where("driverID", isEqualTo: driverDocID)
            .where("status", isEqualTo: 0)
            .limit(1)
            .get();

        if (tvExist.docs.length > 0 && cspExistQuery.docs.length > 0) {
          QuerySnapshot driverWithThisPlateNumberExist = await driverCollection
              .where("systemAccountId", isEqualTo: systemAccountId)
              .where("plateNumber", isEqualTo: plateNumber)
              .limit(1)
              .get();
          if (driverWithThisPlateNumberExist.docs.isNotEmpty) {
            transaction.update(
                driverCollection.doc(driverWithThisPlateNumberExist.docs[0].id),
                {"plateNumber": "", "status": false});
          }
          if (fixClaimExist.docs.isNotEmpty) {
            transaction
                .update(fixClaimCollection.doc(fixClaimExist.docs[0].id), {
              "status": 1,
              "imageUrl": imageUrl,
              "cspID": cspExistQuery.docs[0].id,
              "resolvedDate": Timestamp.now()
            });
            // NEW
            transaction.update(cspCollection.doc(cspExistQuery.docs[0].id),
                {"attended": FieldValue.increment(1)});
            //
          } else {
            await CloudStorageService().deleteFile(imageUrl);
          }
          String cspID = cspExistQuery.docs[0].id;
          transaction.update(driverCollection.doc(driverDocID), {
            "cspID": cspID,
            "mainRoutes": mainRoutes,
            "calibrationValue": calibrationValue,
            "bankAccountNumber": bankAccount,
            "name": name,
            "plateNumber": plateNumber,
            "status": true
          });
          if (tvExist.docs[0].get("driverID") != driverDocID) {
            transaction.update(tvCollection.doc(tvExist.docs[0].id),
                {"driverID": driverDocID, "imageUrl": ""});
          }
          return {"val": true};
        } else {
          await CloudStorageService().deleteFile(imageUrl);
          return {"val": false};
        }
      });
      updated = a["val"];
      return updated;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateTV(
      String tvDocID,
      String plateNumber,
      int speakerPosition,
      bool engineSoundPollution,
      bool speakerQuality,
      int cspIdentifier,
      String imageUrl,
      String tvImageUrl,
      String driverDocID,
      String systemAccountId) async {
    try {
      bool updated;
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        QuerySnapshot cspExistQuery = await cspCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("cspIdentifier", isEqualTo: cspIdentifier)
            .where("status", isEqualTo: true)
            .where("disabled", isEqualTo: false)
            .limit(1)
            .get();
        QuerySnapshot fixClaimExist = await fixClaimCollection
            .where("driverID", isEqualTo: driverDocID)
            .where("status", isEqualTo: 0)
            .limit(1)
            .get();

        if (cspExistQuery.docs.isNotEmpty) {
          if (fixClaimExist.docs.isNotEmpty) {
            transaction
                .update(fixClaimCollection.doc(fixClaimExist.docs[0].id), {
              "status": 1,
              "imageUrl": imageUrl,
              "cspID": cspExistQuery.docs[0].id,
              "resolvedDate": Timestamp.now()
            });
            // NEW
            transaction.update(cspCollection.doc(cspExistQuery.docs[0].id),
                {"attended": FieldValue.increment(1)});
            //
          } else {
            await CloudStorageService().deleteFile(imageUrl);
          }
          if (tvImageUrl != "") {
            transaction.update(tvCollection.doc(tvDocID), {
              "engineSoundPollution": engineSoundPollution,
              "speakerQuality": speakerQuality,
              "speakerPosition": speakerPosition,
              "imageUrl": tvImageUrl
              // "plateNumber": plateNumber
            });
          } else {
            transaction.update(tvCollection.doc(tvDocID), {
              "engineSoundPollution": engineSoundPollution,
              "speakerQuality": speakerQuality,
              "speakerPosition": speakerPosition,
              // "plateNumber": plateNumber
            });
          }
          return {"val": true};
        } else {
          await CloudStorageService().deleteFile(imageUrl);
          return {"val": false};
        }
      });
      updated = a["val"];
      return updated;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createTV(
      String plateNumber,
      int speakerPosition,
      bool engineSoundPollution,
      bool speakerQuality,
      int cspIdentifier,
      String carModelID,
      String imageUrl,
      String systemAccountId) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        QuerySnapshot cspExistQuery = await cspCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("cspIdentifier", isEqualTo: cspIdentifier)
            .where("status", isEqualTo: true)
            .where("disabled", isEqualTo: false)
            .limit(1)
            .get();
        QuerySnapshot plateNumberExist = await tvCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("plateNumber", isEqualTo: plateNumber)
            .limit(1)
            .get();
        DocumentSnapshot systemDoc =
            await systemAccountCollection.doc(systemAccountId).get();
        if (cspExistQuery.docs.isNotEmpty &&
            plateNumberExist.docs.isEmpty &&
            (systemDoc.get("taxiNeeded") > systemDoc.get("registeredTaxi"))) {
          transaction.set(tvCollection.doc(), {
            "systemAccountId": systemAccountId,
            "status": true,
            "engineSoundPollution": engineSoundPollution,
            "speakerQuality": speakerQuality,
            "speakerPosition": speakerPosition,
            "plateNumber": plateNumber,
            "cspID": cspExistQuery.docs[0].id,
            "svd": 3,
            "silentAdNumber": 0,
            "carModelID": carModelID,
            "imageUrl": imageUrl
          });
          transaction.update(systemAccountCollection.doc(systemAccountId), {
            "registeredTaxi": FieldValue.increment(1),
            // "newTaxi": FieldValue.increment(1)
          });
          return {"val": true};
        } else {
          return {"val": false};
        }
      });
      return a["val"];
    } catch (e) {
      return false;
    }
  }

  Future<bool> createFixClaim(String driverID, String type, bool urgent,
      String plateNumber, String phoneNumber, systemAccountId) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        QuerySnapshot claimForFixExist = await fixClaimCollection
            .where("driverID", isEqualTo: driverID)
            .where("status", isEqualTo: 0)
            .limit(1)
            .get();
        if (claimForFixExist.docs.isNotEmpty) {
          transaction.delete(claimForFixExist.docs[0].reference);
        }
        transaction.set(fixClaimCollection.doc(), {
          "phoneNumber": phoneNumber,
          "plateNumber": plateNumber,
          "scheduled": false,
          "systemAccountId": systemAccountId,
          "type": type,
          "urgent": urgent,
          "driverID": driverID,
          "createdDate": Timestamp.now(),
          "status": 0,
          // NEW
          "imageStatus": 0
          //
        });
        return {"val": true};
      });
      return a["val"];
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateDailyStatus(String driverID, String imageUrl) async {
    QuerySnapshot tvDocQuery = await tvCollection
        .where("driverID", isEqualTo: driverID)
        .limit(1)
        .get();
    // DateTime now = DateTime.now().toUtc();
    // DateTime timeAdjustedDateTime = DateTime.utc(now.year, now.month, now.day);
    return driverCollection
        .doc(driverID)
        .update({
          "dailyValue": FieldValue.arrayUnion([
            {
              // "date": Timestamp.fromDate(timeAdjustedDateTime),
              "date": Timestamp.now(),
              "imageUrl": imageUrl,
              "dailyStatus": 0,
              "tvID": tvDocQuery.docs[0].id
            }
          ]),
          "noDailyValueToCheck": false
        })
        .then((value) => true)
        .catchError((e) => false);
    // bool result = true;
    // Map<String, dynamic> a =
    //     await FirebaseFirestore.instance.runTransaction((transaction) async {
    //   QuerySnapshot tvDocQuery = await tvCollection
    //       .where("driverID", isEqualTo: driverID)
    //       .limit(1)
    //       .get();
    //   DocumentSnapshot getDailyValueForDelete =
    //       await driverCollection.doc(driverID).get();
    //   List<Map> mapToBeDeleted = getDailyValueForDelete.get("dailyValue");
    //   transaction.update(driverCollection.doc(driverID), {
    //     "dailyValue": FieldValue.arrayRemove([mapToBeDeleted[0]]),
    //   });
    //   transaction.update(driverCollection.doc(driverID), {
    //     "dailyValue": FieldValue.arrayUnion([
    //       {
    //         "date": Timestamp.now(),
    //         "imageUrl": imageUrl,
    //         "dailyStatus": 0,
    //         "tvID": tvDocQuery.docs[0].id
    //       }
    //     ])
    //   });
    //   return {"val": true};
    // }).catchError((e) {
    //   result = false;
    // });
    // return result ? a["val"] : false;
  }

  Future<bool> updateFailedFixed(String driverID) async {
    return driverCollection
        .doc(driverID)
        .update({"failedFix": true})
        .then((value) => true)
        .catchError((e) => false);
  }

  Future<int> solutionForInactiveCSP(String fixClaimID) async {
    try {
      DocumentSnapshot documentSnapshot =
          await fixClaimCollection.doc(fixClaimID).get();
      String cspID = documentSnapshot.get("cspID");
      DocumentSnapshot cspDocSnap = await cspCollection.doc(cspID).get();

      bool status = cspDocSnap.get("status");
      bool disabled = cspDocSnap.get("disabled");

      if (!status || disabled) {
        fixClaimCollection.doc(fixClaimID).update({"scheduled": false});
        return 1;
      } else {
        return 0;
      }
    } catch (e) {
      return 2;
    }
  }

  Future<bool> createTvAd(String adCardID, String uniqueName, String adName,
      String tvID, String hash) {
    return tvAdCollection.doc().set({
      "adCardID": adCardID,
      "tvID": tvID,
      // if preProcessed is false then we need to ignore
      // seir,silent and loud values of the tvAD doc
      "seir": 0,
      "vd": 3,
      "preProcessed": false,
      "silent": false,
      "loud": false,
      // used to mark TVAD unprocessed when it fails
      // after giving warning
      "warning": false,
      // unique name and hash are included here so
      // as to not make another read to ad doc if
      // the ad is preprocessed whenever driver is
      // about to start route
      "hash": hash,
      // unique name and adName are also useful
      // for OSC
      "adName": adName,
      "uniqueName": uniqueName
    }).then((value) => true);
  }

  Future<bool> updateTvAd(String tvAdDocID, double seir, int vd, bool silent,
      bool loud, String systemAccountID) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        if (silent) {
          String tvID = await tvAdCollection
              .doc(tvAdDocID)
              .get()
              .then((value) => value.get("tvID"));
          int silentAdLimit = await systemAccountCollection
              .doc(systemAccountID)
              .get()
              .then((value) => value.get("silentAdLimit"));
          int silentAdNumber = await tvCollection
              .doc(tvID)
              .get()
              .then((value) => value.get("silentAdNumber"));
          if (silentAdNumber < silentAdLimit) {
            transaction.update(tvCollection.doc(tvID),
                {"silentAdNumber": FieldValue.increment(1)});
            transaction.update(tvAdCollection.doc(tvAdDocID), {
              "seir": seir,
              "vd": vd,
              "silent": silent,
              "loud": loud,
              "preProcessed": true
            });
            return {"val": true};
          } else {
            return {"val": false};
          }
        } else {
          transaction.update(tvAdCollection.doc(tvAdDocID), {
            "seir": seir,
            "vd": vd,
            "silent": silent,
            "loud": loud,
            "preProcessed": true
          });
          return {"val": true};
        }
      });
      return a["val"];
    } catch (e) {
      return false;
    }
  }

  // returns routeID
  Future<String> startRoute(CompilationForServe compilationForServe) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        double systemPriceCut, badSetupCut;
        await systemAccountCollection
            .doc(compilationForServe.systemAccountID)
            .get()
            .then((value) {
          systemPriceCut = double.parse(value.get("priceCut").toString());
          badSetupCut = double.parse(value.get("badSetupCut").toString());
        });
        if (compilationForServe.badSetup) {
          systemPriceCut += badSetupCut;
          // As additional check
          if (systemPriceCut > 100) {
            systemPriceCut = 100;
          }
        }
        String mainAccPaymentID = await mainPayAccCollection
            .where("systemAccountId",
                isEqualTo: compilationForServe.systemAccountID)
            .limit(1)
            .get()
            .then((value) => value.docs[0].id);
        Map<String, double> checkAdCardDeduct = {};
        for (var adBreakCards in compilationForServe.adbreakAdCards) {
          for (var adCard in adBreakCards) {
            double serveCut = compilationForServe.pricePerSlot * adCard.length;
            if (checkAdCardDeduct.containsKey(adCard.name)) {
              double value = checkAdCardDeduct[adCard.name];
              value += serveCut;
              checkAdCardDeduct[adCard.name] = value;
            } else {
              checkAdCardDeduct[adCard.name] = serveCut;
            }
          }
        }
        bool routeCanBeServed = true;
        for (var item in checkAdCardDeduct.entries) {
          // print("Item: " + item.key + " deduct: " + item.value.toString());
          await tempAdCardColl.doc(item.key).get().then((value) {
            if (double.parse(value.get("adCardBalance").toString()) <
                item.value) {
              routeCanBeServed = false;
            }
          });
        }
        // print("routeCanBeServed: " + routeCanBeServed.toString());
        if (routeCanBeServed) {
          double totalAddToDriverBalance = 0,
              totalAddToOwnedBalance = 0,
              totalSubToBusinessBalance = 0;
          Map<String, double> adCardDeduct = {};
          DocumentReference routeRef = tempRouteCollection.doc();
          for (var adBreakCards in compilationForServe.adbreakAdCards) {
            for (var adCard in adBreakCards) {
              double driverCut =
                  compilationForServe.pricePerSlot * adCard.length;
              double systemCut = (systemPriceCut / 100) * driverCut;
              driverCut -= systemCut;
              totalAddToDriverBalance += driverCut;
              totalAddToOwnedBalance += systemCut;
              totalSubToBusinessBalance -= driverCut;
              totalSubToBusinessBalance -= systemCut;
              if (adCardDeduct.containsKey(adCard.name)) {
                double value = adCardDeduct[adCard.name];
                value += driverCut + systemCut;
                adCardDeduct[adCard.name] = value;
              } else {
                adCardDeduct[adCard.name] = driverCut + systemCut;
              }
              DocumentReference dpTransRef = tempTransaction.doc();
              DocumentReference scTransRef = tempTransaction.doc();
              // if (adCard.transIDs.length != 0) {
              //   adCard.transIDs.add(dpTransRef.id);
              //   adCard.transIDs.add(scTransRef.id);
              // }

              // specific type 2 driver payment (dp) and 3 system cut (sc)
              // dp transaction
              if (adCard.dpTransIDs.length == 0) {
                // useful to assign the unique served people amount of the
                // specific setup only to one of the transaction of the adCard
                transaction.set(dpTransRef, {
                  "sender": adCard.name,
                  "reciever": compilationForServe.driverID,
                  "amount": driverCut,
                  compilationForServe.setup: compilationForServe.passengerSize,
                  "type": true,
                  "specificType": 2,
                  "status": 0,
                  "cp": false,
                  "routeID": routeRef.id,
                  "systemAccountId": compilationForServe.systemAccountID,
                  "timestamp": Timestamp.now()
                });
              } else {
                transaction.set(dpTransRef, {
                  "sender": adCard.name,
                  "reciever": compilationForServe.driverID,
                  "amount": driverCut,
                  "type": true,
                  "specificType": 2,
                  "status": 0,
                  "cp": false,
                  "routeID": routeRef.id,
                  "systemAccountId": compilationForServe.systemAccountID,
                  "timestamp": Timestamp.now()
                });
              }

              // sc transaction
              transaction.set(scTransRef, {
                "sender": adCard.name,
                "reciever": mainAccPaymentID,
                "amount": systemCut,
                "type": true,
                "specificType": 3,
                "status": 0,
                "cp": true,
                "routeID": routeRef.id,
                "systemAccountId": compilationForServe.systemAccountID,
                "timestamp": Timestamp.now()
              });
              // print("Ad: " + adCard.name + " dp: " + dpTransRef.id);
              adCard.dpTransIDs.add(dpTransRef.id);
              adCard.scTransIDs.add(scTransRef.id);
            }
          }
          // print(
          //     "Total subTo business: " + totalSubToBusinessBalance.toString());
          // print("Total addToOwnedBalance " + totalAddToOwnedBalance.toString());
          // print(
          //     "Total addToDriverBalance " + totalAddToDriverBalance.toString());
          // updates main payment account
          transaction.update(mainPayAccCollection.doc(mainAccPaymentID), {
            "businessBalance": FieldValue.increment(totalSubToBusinessBalance),
            "driverBalance": FieldValue.increment(totalAddToDriverBalance),
            "ownedBalance": FieldValue.increment(totalAddToOwnedBalance)
          });
          int oneDay = 24 * 60 * 60 * 1000;
          // DateTime cd = DateTime.now().toUtc();
          // DateTime timeNeutralCd =
          //     DateTime.utc(cd.year, cd.month, cd.day, 0, 0, 0, 0, 0);
          // int daysSinceEpoch = timeNeutralCd.millisecondsSinceEpoch ~/ oneDay;
          DateTime cd = DateTime.now().toLocal();
          DateTime timeNeutralCd =
              DateTime(cd.year, cd.month, cd.day, 0, 0, 0, 0, 0);
          // print("Mill: " + timeNeutralCd.millisecondsSinceEpoch.toString());
          double daysSinceEpoch = timeNeutralCd.millisecondsSinceEpoch / oneDay;
          daysSinceEpoch *= 100;
          int dse = daysSinceEpoch.floor();
          transaction
              .update(driverCollection.doc(compilationForServe.driverID), {
            // updates profit of the day
            dse.toString(): FieldValue.increment(totalAddToDriverBalance),
            "potentialBalance": FieldValue.increment(totalAddToDriverBalance)
          });
          // print("De: " + dse.toString());
          // deduct balance from ad cards
          adCardDeduct.forEach((key, value) {
            double deductAmount = 0 - value;
            // print("Key: " + key + "Deduct amount: " + deductAmount.toString());

            transaction.update(tempAdCardColl.doc(key),
                {"adCardBalance": FieldValue.increment(deductAmount)});
          });
          // this will also trigger ths (transaction handler start)
          // which is set to be triggered on document(route) creation
          transaction.set(routeRef, {
            "driverID": compilationForServe.driverID,
            "cm": compilationForServe.cmID,
            "ts": compilationForServe.tsID,
            "sp": compilationForServe.spID,
            "startTime": Timestamp.fromDate(cd),
            // end time will be updated when route finishes
            // by the driver or cloud function
            "endTime": Timestamp.fromDate(cd),
            "numberOfAvailableAds": compilationForServe.totalAdLength,
            "pathName": compilationForServe.pathName,
            "pathID": compilationForServe.pathID,
            "maximumWaitTime": compilationForServe.pathMaximumWaitTime,
            "availableProfit": compilationForServe.availableprofit,
            "imageStatus": 0,
            "status": 0,
            "systemAccountId": compilationForServe.systemAccountID
          });
          return {"val": routeRef.id};
        } else {
          return {"val": "n"};
        }
      });
      return a["val"];
    } catch (e) {
      return null;
    }
  }

  // The return is used to know whether the route was already reported
  // because driver took too long to report the route
  Future<bool> reportRoute(
      List<List<String>> failedTransIds,
      String routeID,
      double profit,
      int servedAds,
      bool disqualified,
      String driverID,
      // For unprocessedTvAds we need to only add
      // tvAds that have a pure SMIR and/or that
      // failed (meaning lower than lemz)
      Map<String, List<dynamic>> unprocessedTvAds,
      // For processedTvAds we should add tvAds that
      // failed but it doesnt matter if you add all
      // of the processed tvAds except it will be
      // a little more efficient
      Map<String, List<dynamic>> processedTvAds,
      double lemz,
      double hemz,
      int maxVol,
      DateTime endTime,
      String systemAccountID,
      tvID) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        int routeReported = await tempRouteCollection
            .doc(routeID)
            .get()
            .then((value) => value.get("status"));
        int silentAdLimit = await systemAccountCollection
            .doc(systemAccountID)
            .get()
            .then((value) => value.get("silentAdLimit"));
        int silentAdNumber = await tvCollection
            .doc(tvID)
            .get()
            .then((value) => value.get("silentAdNumber"));
        print("Route status: " +
            routeReported.toString() +
            " " +
            silentAdNumber.toString() +
            " " +
            silentAdLimit.toString());
        // print("Failed : " +
        //     failedTransIds.length.toString() +
        //     " => " +
        //     unprocessedTvAds.length.toString() +
        //     " => " +
        //     processedTvAds.length.toString());

        // TVAD related
        // key is tvAdID, value[0] is SMIR and value[1] is VD (volume decrease)
        if (routeReported == 0) {
          unprocessedTvAds.forEach((key, value) {
            if (value[0] < lemz && value[1] == 0) {
              if (silentAdNumber < silentAdLimit) {
                transaction.update(tvCollection.doc(tvID),
                    {"silentAdNumber": FieldValue.increment(1)});
                transaction.update(tvAdCollection.doc(key), {
                  "preProcessed": true,
                  "warning": false,
                  "loud": false,
                  "silent": true,
                  "seir": value[0],
                });
              }
            } else if (value[0] < lemz && value[1] > 0) {
              // increases volume
              value[1]--;
              transaction.update(tvAdCollection.doc(key), {
                // marking it loud/silent and assigning seir
                // for now have no use
                "loud": false,
                "silent": true,
                "seir": value[0],
                "vd": value[1],
              });
            } else if (value[0] >= lemz && value[0] <= hemz) {
              transaction.update(tvAdCollection.doc(key), {
                "preProcessed": true,
                "warning": false,
                "loud": false,
                "silent": false,
                "seir": value[0],
              });
            } else if (value[0] > hemz) {
              // decreases volume
              if (value[1] < maxVol) {
                value[1]++;
              }
              transaction.update(tvAdCollection.doc(key), {
                // marking it loud/silent and assigning seir
                // for now have no use
                "loud": true,
                "silent": false,
                "seir": value[0],
                "vd": value[1],
              });
            }
          });
          // key is tvAdID, value[0] is SMIR and value[1] is warning
          processedTvAds.forEach((key, value) {
            if (value[0] < lemz && value[1]) {
              transaction.update(tvAdCollection.doc(key),
                  {"preProcessed": false, "warning": false});
            } else if (value[0] < lemz && !value[1]) {
              transaction.update(tvAdCollection.doc(key), {"warning": true});
            }
          });
        }

        // ROUTE related
        if (routeReported == 0) {
          List<int> totalRoutes, weeklyRoutes;
          // first elemnt of both totalRoutes and weeklyRoutes are succesfull
          // routes and second element is failed routes so its updated
          // accordingly depending on whether the route was disqualified or not
          // then we add the history on top of it.
          if (disqualified) {
            totalRoutes = [0, 1];
            weeklyRoutes = [0, 1];
          } else {
            totalRoutes = [1, 0];
            weeklyRoutes = [1, 0];
          }
          await tempRouteCollection
              .where("driverID", isEqualTo: driverID)
              .where("status", isEqualTo: 1)
              .orderBy("startTime", descending: true)
              .limit(1)
              .get()
              .then((value) {
            if (value.docs.isNotEmpty) {
              List<dynamic> tr = value.docs[0].get("totalRoutes");
              List<dynamic> wr = value.docs[0].get("weeklyRoutes");
              totalRoutes[0] += tr[0];
              totalRoutes[1] += tr[1];
              weeklyRoutes[0] += wr[0];
              weeklyRoutes[1] += wr[1];
            }
          });
          for (var item in failedTransIds) {
            // dp transaction
            transaction.update(
                tempTransaction.doc(item[0]), {"cp": false, "status": 3});
            // sc transaction
            transaction.update(
                tempTransaction.doc(item[1]), {"cp": false, "status": 3});
          }
          // trigger the (transaction handler end)
          if (failedTransIds.length > 0) {
            if (disqualified) {
              transaction.update(tempRouteCollection.doc(routeID), {
                "weeklyRoutes": weeklyRoutes,
                "totalRoutes": totalRoutes,
                "imageStatus": 2,
                "status": 1,
                "profit": 0,
                "numberOfAdServed": servedAds,
                "endTime": Timestamp.fromDate(endTime),
                "the": FieldValue.increment(1)
              });
            } else {
              transaction.update(tempRouteCollection.doc(routeID), {
                "weeklyRoutes": weeklyRoutes,
                "totalRoutes": totalRoutes,
                "status": 1,
                "profit": profit,
                "numberOfAdServed": servedAds,
                "endTime": Timestamp.fromDate(endTime),
                "the": FieldValue.increment(1)
              });
            }
          } else {
            transaction.update(tempRouteCollection.doc(routeID), {
              "weeklyRoutes": weeklyRoutes,
              "totalRoutes": totalRoutes,
              "status": 1,
              "profit": profit,
              "numberOfAdServed": servedAds,
              "endTime": Timestamp.fromDate(endTime),
            });
          }
          return {"val": true};
        } else {
          return {"val": false};
        }
      });
      // print("Return val: " + a["val"].toString());
      return a["val"];
    } catch (e) {
      print("Error: " + e.toString());
      return null;
    }
  }

  Future<bool> createPenality(String type, String driverID) async {
    try {
      // For now both types of penality here (in addition to file fraud in
      // getAdCards) all have a suspension duration of one day (lasts one day)
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        DateTime cd = DateTime.now();
        int oneDay = 24 * 60 * 60 * 1000;
        DateTime returnDate = DateTime.fromMillisecondsSinceEpoch(
            cd.millisecondsSinceEpoch + oneDay);
        transaction.set(penaltyCollection.doc(), {
          "createdDate": Timestamp.now(),
          "returnDate": Timestamp.fromDate(returnDate),
          "driverID": driverID,
          "duration": 1,
          "type": type,
          "status": 0
        });
        transaction.update(driverCollection.doc(driverID), {"status": false});
        return {"val": true};
      });
      return a["val"];
    } catch (e) {
      return null;
    }
  }

  Future<bool> doesUnreportedRouteExist(String driverID) {
    try {
      return tempRouteCollection
          .where("driverID", isEqualTo: driverID)
          .where("status", isEqualTo: 0)
          .get()
          .then((value) => value.docs.isNotEmpty ? true : false);
    } catch (e) {
      return null;
    }
  }

  // For Supporting Pages
  Future<bool> createNewPathReport(
    String additionalInfo,
    String endLocationName,
    String startLocationName,
    String nickName,
    String systemAccountID,
  ) {
    return newPathReportCollection
        .doc()
        .set({
          "additionalInfo": additionalInfo,
          "attended": false,
          "date": Timestamp.now(),
          "endingLocation": endLocationName,
          "startingLocation": startLocationName,
          "nickname": nickName,
          "systemAccountId": systemAccountID
        })
        .then((value) => true)
        .catchError((err) => false);
  }

  Future<bool> scheduleForRegistration(
      List<String> mainRoutes,
      String name,
      String phoneModel,
      String phoneNumber,
      String plateNumber,
      String systemAccountId) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        QuerySnapshot plateNumberExist = await tvCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("plateNumber", isEqualTo: plateNumber)
            .limit(1)
            .get();
        if (plateNumberExist.docs.isEmpty) {
          transaction.set(registrationScheduleCollection.doc(), {
            "mainRoutes": mainRoutes,
            "name": name,
            "phoneModel": phoneModel,
            "phoneNumber": phoneNumber,
            "plateNumber": plateNumber,
            "registered": false,
            "scheduled": false,
            "systemAccountId": systemAccountId,
            "timestamp": Timestamp.now(),
          });
          return {"val": true};
        } else {
          return {"val": false};
        }
      });
      return a["val"];
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePhone(String phoneID, String driverID,
      String systemAccountId, String imageUrl, int cspIdentifier) async {
    try {
      Map<String, dynamic> a =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        QuerySnapshot cspExistQuery = await cspCollection
            .where("systemAccountId", isEqualTo: systemAccountId)
            .where("cspIdentifier", isEqualTo: cspIdentifier)
            .where("status", isEqualTo: true)
            .where("disabled", isEqualTo: false)
            .limit(1)
            .get();
        QuerySnapshot fixClaimExist = await fixClaimCollection
            .where("driverID", isEqualTo: driverID)
            .where("status", isEqualTo: 0)
            .limit(1)
            .get();
        if (cspExistQuery.docs.isNotEmpty) {
          if (fixClaimExist.docs.isNotEmpty) {
            transaction
                .update(fixClaimCollection.doc(fixClaimExist.docs[0].id), {
              "status": 1,
              "imageUrl": imageUrl,
              "cspID": cspExistQuery.docs[0].id,
              "resolvedDate": Timestamp.now()
            });
            transaction.update(cspCollection.doc(cspExistQuery.docs[0].id),
                {"attended": FieldValue.increment(1)});
          } else {
            await CloudStorageService().deleteFile(imageUrl);
          }
          String cspID = cspExistQuery.docs[0].id;
          transaction.update(driverCollection.doc(driverID),
              {"cspID": cspID, "phoneID": phoneID});
          return {"val": true};
        } else {
          await CloudStorageService().deleteFile(imageUrl);
          return {"val": false};
        }
      });
      return a["val"];
    } catch (e) {
      return false;
    }
  }

  Future<int> routesTakenForTheDay(
      DateTime currentDate, String driverID, String systemAccountID) async {
    try {
      currentDate = currentDate.toLocal();
      DateTime timeAdjustedCd =
          DateTime(currentDate.year, currentDate.month, currentDate.day);
      int timeZoneOffset = await systemAccountCollection
          .doc(systemAccountID)
          .get()
          .then((value) => value.get("timeZoneOffset"));
      // print("TzOff: " +
      //     timeZoneOffset.toString() +
      //     " " +
      //     timeFormat.format(timeAdjustedCd));
      if (timeZoneOffset == timeAdjustedCd.timeZoneOffset.inMinutes) {
        // return tripCollection
        return tempRouteCollection
            .where("driverID", isEqualTo: driverID)
            .where("imageStatus", isEqualTo: 0)
            .where("startTime",
                isGreaterThanOrEqualTo: Timestamp.fromDate(timeAdjustedCd))
            .get()
            .then((value) => value.docs.length);
      } else {
        return 0;
      }
    } catch (e) {
      print("routeTakenForTheDay Error: " + e.toString());
      return 0;
    }
  }
}
