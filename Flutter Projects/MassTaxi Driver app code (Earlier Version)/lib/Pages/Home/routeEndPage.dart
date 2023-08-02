import 'dart:async';
import 'package:audio_record/Classes/adBreakAlgorithm.dart';
import 'package:audio_record/Classes/camera_data.dart';
import 'package:audio_record/Classes/final_stat.dart';
import 'package:audio_record/Classes/location_data.dart';
import 'package:audio_record/Classes/recorded_data.dart';
import 'package:audio_record/Classes/route_data.dart';
import 'package:audio_record/Pages/Home/adStats.dart';
import 'package:audio_record/Pages/wrapper.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:audio_record/main.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:volume/volume.dart';
import 'package:intl/intl.dart';

class RouteEndPage extends StatefulWidget {
  final Function toggleView;
  final int adServed;
  final int totalAdTobeServed;
  final CompilationForServe compilationForServe;
  // final double pricePerSlot;
  final double totalCalculatedDistance;
  final double duration;
  final List<LocationData> savedLocations;
  final bool success;
  RouteEndPage(
      {this.toggleView,
      this.adServed,
      this.totalAdTobeServed,
      this.success,
      this.compilationForServe,
      this.duration,
      this.totalCalculatedDistance,
      this.savedLocations});
  @override
  _RouteEndPageState createState() => _RouteEndPageState();
}

class _RouteEndPageState extends State<RouteEndPage> {
  List<CameraDescription> cameras;
  CameraController controller;
  XFile imageFile;
  FinalStat fstat = null;

  // NEW
  bool routeDisqualified = false;
  List<String> disqualifiedReasons = [
    "None",
    "Cancelled",
    "Audio Fraud",
    "Vehicle Exit",
    "Volume Related",
    "Location Related",
    "Recorder Related",
    "Late Report"
  ];
  int disqualifiedReasonIndex = 0;
  Map<String, List<dynamic>> unprocessedTvAds = {}, processedTvAds = {};
  List<List<String>> failedTransIds = [], backUpFailedTransIds = [];
  int maxVol = 0;
  FinalStat finalStat;
  DateTime startTime, endTime;
  bool loaded = true;
  bool reported = false, reportAllowed = true;
  // NEW
  bool statGenerated = false;
  double profitDeduct = 0;
  //

  Timer _timer;

  DateFormat timeFormat = DateFormat("jm");

  Future<FinalStat> generateStats() async {
    final prefs = await AppMain.mainPrefs;
    List<LocationData> savedLocations = [];
    List<RouteData> stats = [];
    List<String> savedProgresses = prefs.getStringList('dist_progress');
    print("Saved Progress: " + savedProgresses.toString());
    // List<RecordedData> recordings = await RecordedData.getAverageRecordings();
    // print("Saved Recording: " + recordings.toString());
    // Check whether there were any Saved Progresses by checking if its null or
    // less than 3
    if (savedProgresses != null) {
      if (savedProgresses.length >= 3) {
        // Loop through all Saved Progress and Save them in the Saved Locations
        // list EXCEPT FOR PAUSED LOCATIONS
        for (String svstr in savedProgresses) {
          print("SVSTR: " + svstr);
          LocationData retreivedData = LocationData.fromString(
            ldString: svstr,
          );
          print("Retreived Data: " + retreivedData.toString());
          if (retreivedData.name != null) {
            if (retreivedData.name.contains('PS')) {
              continue;
            }
          }
          savedLocations.add(retreivedData);
        }
        print("Saved Location: " + savedLocations.toString());
        stats = await RouteData.generateRouteData(savedLocations);
        print("Final Saved Length: " + stats.length.toString());
        for (var routedt in stats) {
          print("Final Saved " + routedt.adnumber.toString());
        }
      }
    }
    bool isCompromised = false;
    List<int> uncompleteads = [];
    for (var i = 0; i < stats.length; i++) {
      RouteData element = stats[i];
      if (element.recordedAverage == 0) {
        uncompleteads.add(i);
      } else if (element.recordedAverage == -1) {
        isCompromised = true;
        break;
      }
    }
    if (!isCompromised) {
      for (var ix in uncompleteads) {
        stats.removeAt(ix);
      }
    }
    uncompleteads = [];
    if (savedLocations.length >= 3) {
      FinalStat fs = FinalStat(
          components: stats,
          startingLocation: savedLocations.first,
          endingLocation: savedLocations.last,
          timetaken: widget.duration);
      fs.isCompromised = isCompromised;
      double displacement = LocationData.calculateDistance(
          firstLoc: FinalStat.routeStartingLocation,
          secLoc: FinalStat.routeEndingLocation);
      fs.efficency =
          ((displacement / widget.totalCalculatedDistance) * 100).toInt();
      // print("Final Stat = (components) ")
      fs.components.forEach((element) {
        print(
            "FINALE STAT COMPONENT: ${element.silence ? 'ST' : 'AD'} ${element.adname} : ${element.status}  : ${element.recordedAverage}");
      });
      print("FINALE STAT : STARTING LOCATION ${fs.startingLocation}");
      print("FINALE STAT : ENDING LOCATION ${fs.endingLocation}");
      print("FINALE STAT : TIME TAKEN ${fs.timetaken}");
      print("FINALE STAT : IS IT COMPROMISED = ${fs.isCompromised}");
      print("FINALE STAT : EFFICENCIY ${fs.efficency}");
      print("FINALE STAT leng: " + fs.components.length.toString());
      setState(() {
        fstat = fs;
      });
      return fs;
    } else
      return null;
  }

  void setupCameras() async {
    cameras = await availableCameras();
    if (cameras != null) {
      controller = CameraController(
        cameras[1],
        ResolutionPreset.max,
      );
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    if (_timer != null) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    print("Lemz: " + widget.compilationForServe.lemz.toString());
    endTime = DateTime.now();
    int nowInMillisecond = endTime.millisecondsSinceEpoch;
    int durationInMs =
        1000 * 60 * int.parse(widget.duration.round().toString());
    startTime =
        DateTime.fromMillisecondsSinceEpoch(nowInMillisecond - durationInMs);
    Volume.getMaxVol.then((value) => maxVol = value);
    List<AdCard> adCards = [];
    widget.compilationForServe.adbreakAdCards.forEach((element) {
      element.forEach((adBreakAdCard) {
        bool exist = false;
        for (var adCard in adCards) {
          if (adBreakAdCard.name == adCard.name) {
            exist = true;
            break;
          }
        }
        if (!exist) {
          adCards.add(adBreakAdCard);
          print("Name: " +
              adBreakAdCard.uniqueName +
              " " +
              adBreakAdCard.preProcessed.toString() +
              " Sile: " +
              adBreakAdCard.silent.toString());
        }
      });
    });
    for (var card in adCards) {
      for (var i = 0; i < card.dpTransIDs.length; i++) {
        backUpFailedTransIds.add([card.dpTransIDs[i], card.scTransIDs[i]]);
      }
    }
    if (!widget.success) {
      routeDisqualified = true;
      disqualifiedReasonIndex = 1;
    }
    generateStats().then((value) {
      if (!routeDisqualified) {
        print("Comp leng: " + value.components.length.toString());
        finalStat = value;
        double efficiencyDiff =
            widget.compilationForServe.pathEfficiency - value.efficency;
        if (efficiencyDiff.abs() >
            widget.compilationForServe.pathEfficiencyRange) {
          routeDisqualified = true;
          disqualifiedReasonIndex = 5;
        }
        if (!routeDisqualified && value.isCompromised) {
          routeDisqualified = true;
          disqualifiedReasonIndex = 6;
          // print("P:Compromised");
        }
        if (efficiencyDiff.abs() >
            widget.compilationForServe.pathEfficiencyRange) {
          routeDisqualified = true;
          disqualifiedReasonIndex = 5;
        }
        if (!routeDisqualified && value.isCompromised) {
          routeDisqualified = true;
          disqualifiedReasonIndex = 6;
          // print("P:Compromised");
        }
        int failedSilentCheck = 0, successfullSilentCheck = 0;
        int failedCleanTest = 0, successfullCleanTest = 0;
        List<String> successfulldpTrans = [], successfullscTrans = [];
        List<int> successfullAdIndex = [];
        if (!routeDisqualified) {
          for (var element in value.components) {
            print("P: " +
                element.status.toString() +
                " " +
                element.silence.toString() +
                " " +
                element.recordedAverage.toString());
            if (element.silence) {
              if (element.status == "Pure" || element.status == "Clean") {
                if (element.recordedAverage < widget.compilationForServe.lemz) {
                  successfullSilentCheck++;
                } else {
                  failedSilentCheck++;
                }
              }
            } else {
              print("PNS: " +
                  element.status.toString() +
                  " " +
                  element.recordedAverage.toString());
              int index = 0;
              for (var adCard in adCards) {
                if (adCard.uniqueName == element.adname) {
                  break;
                }
                index++;
              }
              print("PAdCard: " + adCards[index].preProcessed.toString());
              if (adCards[index].preProcessed) {
                if (element.recordedAverage < widget.compilationForServe.lemz &&
                    !adCards[index].silent) {
                  processedTvAds[adCards[index].tvAdId] = [
                    element.recordedAverage,
                    adCards[index].warning
                  ];
                  print("P: volume low");
                  routeDisqualified = true;
                  disqualifiedReasonIndex = 4;
                  // break;
                } else {
                  successfulldpTrans.add(adCards[index].dpTransIDs.last);
                  successfullscTrans.add(adCards[index].scTransIDs.last);
                  successfullAdIndex.add(index);
                  if (element.status == "Pure" || element.status == "Clean") {
                    double seirSmirDiff =
                        element.recordedAverage - adCards[index].seir;
                    print("seirSmirDiff: " + seirSmirDiff.abs().toString());
                    if (seirSmirDiff.abs() > 1) {
                      failedCleanTest++;
                    } else {
                      successfullCleanTest++;
                    }
                  }
                }
              } else {
                if ((element.recordedAverage <
                            widget.compilationForServe.lemz &&
                        adCards[index].guaranteed) ||
                    (element.recordedAverage >=
                        widget.compilationForServe.lemz)) {
                  successfulldpTrans.add(adCards[index].dpTransIDs.last);
                  successfullscTrans.add(adCards[index].scTransIDs.last);
                  successfullAdIndex.add(index);
                } else {
                  profitDeduct += adCards[index].profit;
                }
                if (element.recordedAverage < widget.compilationForServe.lemz ||
                    element.status == "Pure") {
                  unprocessedTvAds[adCards[index].tvAdId] = [
                    element.recordedAverage,
                    adCards[index].volumeDecrease
                  ];
                }
              }
            }
          }
        }
        // if (!routeDisqualified &&
        //     (failedSilentCheck + successfullSilentCheck) > 0 &&
        //     (failedCleanTest + successfullCleanTest) > 0) {
        //   int ascPercent = (failedSilentCheck * 100) ~/
        //       (failedSilentCheck + successfullSilentCheck);
        //   int cleanPercent = (failedCleanTest * 100) ~/
        //       (failedCleanTest + successfullCleanTest);
        //   if (ascPercent > 20 && cleanPercent > 25) {
        //     print("P: AF");
        //     routeDisqualified = true;
        //     disqualifiedReasonIndex = 2;
        //   }
        // }
        if (!routeDisqualified &&
            (failedSilentCheck + successfullSilentCheck) > 0) {
          int ascPercent = (failedSilentCheck * 100) ~/
              (failedSilentCheck + successfullSilentCheck);
          int cleanPercent = 30;
          if ((failedCleanTest + successfullCleanTest) > 0) {
            cleanPercent = (failedCleanTest * 100) ~/
                (failedCleanTest + successfullCleanTest);
          }
          if (ascPercent > 20 && cleanPercent > 25) {
            print("P: AF");
            routeDisqualified = true;
            disqualifiedReasonIndex = 2;
          }
        }
        if (!routeDisqualified) {
          for (var i = 0; i < successfullAdIndex.length; i++) {
            for (var ad in adCards) {
              if (adCards[i].name == ad.name) {
                if (adCards[i].dpTransIDs.isNotEmpty) {
                  adCards[i].dpTransIDs.removeLast();
                  adCards[i].scTransIDs.removeLast();
                }
                break;
              }
            }
          }
        } else {
          // processedTvAds.clear();
          unprocessedTvAds.clear();
        }
        print("Sil and clean: " +
            successfullSilentCheck.toString() +
            " " +
            successfullCleanTest.toString() +
            " f: " +
            failedSilentCheck.toString() +
            " " +
            failedCleanTest.toString());
      }
      for (var card in adCards) {
        if (card.dpTransIDs.isNotEmpty) {
          for (var i = 0; i < card.dpTransIDs.length; i++) {
            failedTransIds.add([card.dpTransIDs[i], card.scTransIDs[i]]);
          }
        }
      }
      unprocessedTvAds.forEach((key, value) {
        print("Un: " + key + " " + value.toString());
      });
      processedTvAds.forEach((key, value) {
        print("Pr: " + key + " " + value.toString());
      });
      // failedTransIds.forEach((element) {
      //   print("El: " + element.toString());
      //   element.forEach((element2) {
      //     print("Failed trId: " + element2);
      //   });
      // });
      print("TotalFaTrans: " + failedTransIds.length.toString());
      print("TotalBackUp: " + backUpFailedTransIds.length.toString());
      setState(() {
        statGenerated = true;
      });
    });
    setupCameras();
    _timer = Timer.periodic(Duration(milliseconds: 800), (timer) async {
      if (!routeDisqualified) {
        if (!Wrapper.speakConnection) {
          print("Speaker Disconnected");
          routeDisqualified = true;
          disqualifiedReasonIndex = 3;
          failedTransIds = backUpFailedTransIds;
          processedTvAds.clear();
          unprocessedTvAds.clear();
        }
      }
      if (reported) {
        reported = false;
        bool reportStatus = await DatabaseService().reportRoute(
            failedTransIds,
            widget.compilationForServe.routeID,
            (widget.adServed *
                    (widget.compilationForServe.availableprofit /
                        widget.compilationForServe.totalAdLength) -
                profitDeduct),
            widget.adServed,
            routeDisqualified,
            widget.compilationForServe.driverID,
            unprocessedTvAds,
            processedTvAds,
            widget.compilationForServe.lemz,
            widget.compilationForServe.hemz,
            maxVol,
            endTime,
            widget.compilationForServe.systemAccountID,
            widget.compilationForServe.tvID);
        if (routeDisqualified && reportStatus != null) {
          if (disqualifiedReasonIndex == 2) {
            await DatabaseService()
                .createPenality("AF", widget.compilationForServe.driverID);
            // Navigator.pop(context);
          } else if (disqualifiedReasonIndex == 3) {
            await DatabaseService()
                .createPenality("VE", widget.compilationForServe.driverID);
            // Navigator.pop(context);
          }
        }
        if (reportStatus != null) {
          await onTakePictureButtonPressed();
          await Future.delayed(Duration(seconds: 1));
          print("Pic Taken");
        }
        if (reportStatus == null) {
          setState(() {
            loaded = true;
            reportAllowed = true;
          });
        } else if (reportStatus == false) {
          setState(() {
            loaded = true;
            disqualifiedReasonIndex = 7;
            routeDisqualified = true;
          });
          await Future.delayed(Duration(seconds: 2));
          Navigator.pop(context);
          widget.toggleView();
        } else {
          Navigator.pop(context);
          widget.toggleView();
        }
      }
    });
    super.initState();
  }

  Future<XFile> takePicture() async {
    final CameraController cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      print('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print(e);
      return null;
    }
  }

  Future onTakePictureButtonPressed() async {
    takePicture().then((XFile file) async {
      if (mounted) {
        setState(() {
          imageFile = file;
        });
        if (file != null) {
          await CameraData.saveImage(file.path);
          print('Picture saved to ${file.path}');
        }
      } else {
        print('Not Mounted');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;

    print("Saved Locations: " + widget.savedLocations.length.toString());

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Route Ended"),
          centerTitle: true,
          leading: Icon(null),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: loaded
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Route Status :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.09,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.04,
                        ),
                        Icon(
                          !routeDisqualified ? Icons.done : Icons.cancel,
                          color: !routeDisqualified ? Colors.green : Colors.red,
                          size: deviceWidth * 0.15,
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Failure Reason :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          disqualifiedReasons[disqualifiedReasonIndex],
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      children: [
                        Text(
                          "Ad Served Length :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          widget.adServed.toString() +
                              " / " +
                              widget.totalAdTobeServed.toString(),
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      children: [
                        Text(
                          "Potential Profit : ",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.02,
                        ),
                        Text(
                          (widget.adServed *
                                          (widget.compilationForServe
                                                  .availableprofit /
                                              widget.compilationForServe
                                                  .totalAdLength) -
                                      profitDeduct)
                                  .toStringAsFixed(2) +
                              " \$",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.08,
                              fontWeight: FontWeight.w700),
                        ),
                        widget.compilationForServe.availableprofit < 100
                            ? Text(
                                " / " +
                                    (widget.compilationForServe.availableprofit)
                                        .toStringAsFixed(2),
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.05,
                                    fontWeight: FontWeight.w300),
                              )
                            : Text(
                                " / " +
                                    (widget.compilationForServe.availableprofit)
                                        .toStringAsPrecision(1),
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.05,
                                    fontWeight: FontWeight.w300),
                              ),
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      children: [
                        Text(
                          "Start Time :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          timeFormat.format(startTime),
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      children: [
                        Text(
                          "End Time :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          timeFormat.format(endTime),
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      children: [
                        Text(
                          "Time Taken (Min) :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          // widget.duration.toStringAsFixed(2),
                          widget.duration.toStringAsFixed(0),
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    // SizedBox(
                    //   height: deviceHeight * 0.01,
                    // ),
                    // Row(
                    //   children: [
                    //     Text(
                    //       "Route :",
                    //       style: TextStyle(
                    //           fontSize: deviceWidth * 0.06,
                    //           fontWeight: FontWeight.w400),
                    //     ),
                    //     SizedBox(
                    //       width: deviceWidth * 0.035,
                    //     ),
                    //     Text(
                    //       "Lafto - Mexico",
                    //       style: TextStyle(
                    //           fontSize: deviceWidth * 0.07,
                    //           fontWeight: FontWeight.w300),
                    //     )
                    //   ],
                    // ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      children: [
                        Text(
                          "Path :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          widget.compilationForServe.pathName.length < 24
                              ? widget.compilationForServe.pathName
                              : widget.compilationForServe.pathName
                                      .substring(0, 22) +
                                  "...",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      children: [
                        Text(
                          "Total Distance :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          widget.totalCalculatedDistance.toStringAsFixed(3),
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Comps Length :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          this.fstat != null
                              ? this.fstat.components.length.toString()
                              : "-",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "Efficiency :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.06,
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(
                          width: deviceWidth * 0.035,
                        ),
                        Text(
                          this.fstat != null
                              ? this.fstat.efficency.toString()
                              : "-",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300),
                        )
                      ],
                    ),
                    ElevatedButton(
                        onPressed: this.fstat != null
                            ? () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (BuildContext context) =>
                                            Scaffold(
                                              body: AdStats(
                                                savedStats: this.fstat,
                                              ),
                                            )));
                              }
                            : null,
                        child: Text(
                          "Components",
                          style: TextStyle(
                            fontSize: deviceWidth * 0.07,
                          ),
                        )),
                    // SizedBox(
                    //   height: deviceHeight * 0.01,
                    // ),
                    // Row(
                    //   children: [
                    //     Text(
                    //       "Saved locations :",
                    //       style: TextStyle(
                    //           fontSize: deviceWidth * 0.06,
                    //           fontWeight: FontWeight.w400),
                    //     ),
                    //     SizedBox(
                    //       width: deviceWidth * 0.035,
                    //     ),
                    //     Text(
                    //       widget.savedLocations.length.toString(),
                    //       style: TextStyle(
                    //           fontSize: deviceWidth * 0.07,
                    //           fontWeight: FontWeight.w300),
                    //     )
                    //   ],
                    // ),

                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    ElevatedButton(
                        onPressed: !reported &&
                                loaded &&
                                reportAllowed &&
                                statGenerated
                            ? () {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: Text(
                                          "Are you sure you want to report the Route ?",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w400),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                reportAllowed = false;
                                                reported = true;
                                                setState(() {
                                                  loaded = false;
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                "Yes",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.07),
                                              )),
                                          TextButton(
                                              onPressed: () {
                                                // await generateStats();
                                                // await onTakePictureButtonPressed();
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                "No",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.07),
                                              ))
                                        ],
                                      );
                                    });
                              }
                            : null,
                        child: Text(
                          "Report Route",
                          style: TextStyle(
                            fontSize: deviceWidth * 0.07,
                          ),
                        )),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Loading(),
                  ],
                ),
        ),
      ),
    );
  }
}
