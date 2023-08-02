import 'dart:async';
import 'package:audio_record/Classes/adBreakAlgorithm.dart';
import 'package:audio_record/Classes/camera_data.dart';
import 'package:audio_record/Classes/final_stat.dart';
import 'package:audio_record/Classes/location_data.dart';
import 'package:audio_record/Classes/route_data.dart';
import 'package:audio_record/Models/driver.dart';
import 'package:audio_record/Models/path.dart';
import 'package:audio_record/Models/superPath.dart';
import 'package:audio_record/Models/systemAccount.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:audio_record/Widgets/drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_ui/firebase_auth_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_location/flutter_background_location.dart';
import 'package:intl/intl.dart';

class StartPage extends StatefulWidget {
  final Function toggleView, logOutStatus;
  final ValueNotifier<bool> speakCon;
  // final ValueNotifier<int> numberOfAdBreak;
  final ValueNotifier<CompilationForServe> compilationForServeVN;
  final String driverDocID;

  StartPage(
      {this.toggleView,
      this.speakCon,
      // this.numberOfAdBreak,
      this.compilationForServeVN,
      this.driverDocID,
      this.logOutStatus});
  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  bool inStartRange = false;

  StreamSubscription _tvStatus, _driverStream, _tvStream;
  SystemRequirementAccount _systemRequirementAccount;

  bool drawerLoaded = false;

  Driver _driver;
  int allowedToServe = 0;

  List<DropdownMenuItem<String>> buildDropDownItem(List places) {
    List<DropdownMenuItem<String>> items = [];
    for (var place in places) {
      items.add(DropdownMenuItem(
        value: place,
        child: Text(
          place,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
        ),
      ));
    }
    return items;
  }

  String _selectedSuperPath, _selectedPath;

  onRegionChange(String selectedRegion) {
    // NEW
    compilationForServe = null;
    adExist = false;
    //
    String superPathID = "";
    mainRouteChange = true;
    inStartRange = false;
    setState(() {
      _selectedSuperPath = selectedRegion;
    });
    for (var item in mainRoutes) {
      String dest = item.destination;
      // String start = item.startingLocation;
      // String route = start + " - " + dest;
      String route = dest;
      if (route == selectedRegion) {
        superPathID = item.docID;
        spPrice = item.spPrice;
        break;
      }
    }
    mainSuperPathID = superPathID;
    FinalStat.clearStaticFields();
    DatabaseService().getPaths(superPathID).then((value) {
      // Main
      FinalStat.routeStartingLocation = value[0].startingLocation;
      // Main
      FinalStat.routeEndingLocation = value[0].endingLocation;
      // Main
      FinalStat.startingRange = value[0].startingRange;
      // Main
      FinalStat.endingRange = value[0].endingRange;
      // Main
      FinalStat.adStopRange = value[0].adStopRange;
      // Main
      for (LocationData dropOff in value[0].dropOffs) {
        FinalStat.saveDropOff(
            latitude: dropOff.latitude, longitude: dropOff.longitude);
      }

      paths = value;
      _selectedPath = paths[0].name;
      mainPathID = paths[0].pathDocID;
      mainRouteChange = false;
      setState(() {});
    });
  }

  onRegionChange2(String selectedRegion2) {
    inStartRange = false;
    _selectedPath = selectedRegion2;
    FinalStat.clearStaticFields();
    for (var item in paths) {
      if (item.name == selectedRegion2) {
        // Main
        FinalStat.routeStartingLocation = item.startingLocation;
        print("MAIN STARTING LOCATION : ${FinalStat.routeStartingLocation}");
        // Main
        FinalStat.routeEndingLocation = item.endingLocation;
        print("MAIN ENDING LOCATION : ${FinalStat.routeEndingLocation}");
        // Main
        FinalStat.startingRange = item.startingRange;
        print("FS AD - START RANGE ${FinalStat.startingRange}");
        // Main
        FinalStat.endingRange = item.endingRange;
        print("FS AD - END RANGE ${FinalStat.endingRange}");
        // Main
        FinalStat.adStopRange = item.adStopRange;
        print("FS AD - STOP RANGE ${FinalStat.adStopRange}");
        // Main
        for (LocationData dropOff in item.dropOffs) {
          FinalStat.saveDropOff(
              latitude: dropOff.latitude, longitude: dropOff.longitude);
        }
        mainPathID = item.pathDocID;
        break;
      }
    }
    DateTime cd = DateTime.now();
    bool allowedTime = false;
    if (_systemRequirementAccount.allowedStartingTime.hour < cd.hour &&
        _systemRequirementAccount.allowedEndingTime.hour > cd.hour) {
      allowedTime = true;
    } else if (_systemRequirementAccount.allowedStartingTime.hour == cd.hour) {
      if (_systemRequirementAccount.allowedStartingTime.minute <= cd.minute) {
        allowedTime = true;
      }
    } else if (_systemRequirementAccount.allowedEndingTime.hour == cd.hour) {
      if (_systemRequirementAccount.allowedEndingTime.minute > cd.minute) {
        allowedTime = true;
      }
    } else {
      allowedTime = false;
    }
    if (allowedTime) {
      adCardsRetrieved = false;
      // retrieve compilaiton here (path change acts
      // as a trigger)
      pathChange = true;
    }
    setState(() {});
    // DatabaseService().getCompData(
    //     mainSuperPathID, mainTimeSlotID, mainCarModelID, mainPathID);
  }

  // bool tvRunOnce = false, tvStat = true;

  // NEW
  List<SuperPath> mainRoutes = [];
  List<PathModel> paths = [];
  bool mainRouteChange = false;
  String mainSuperPathID, mainCarModelID, mainTimeSlotID, mainPathID;
  Timer _timeSlotTimer;
  DateTime endTime = DateTime.now();
  bool first = true, timeSlotFirstEnter = false;
  double lemz, hemz, tsPercentage, cmPercentage, spPrice;
  int passengerSize;

  bool adCardsRetrieved = true, pathChange = false, startRoute = false;
  CompilationForServe compilationForServe;

  bool adExist = false, driverRunOnce = false;
  DateFormat timeFormat = DateFormat("jm");

  bool badSetup = false;
  //

  @override
  void initState() {
    // // Main
    // FinalStat.routeStartingLocation =
    //     LocationData(latitude: 8.344999, longitude: 38.743965);
    // // Main
    // FinalStat.routeEndingLocation =
    //     LocationData(latitude: 8.344900, longitude: 38.743801);
    // // Main
    // FinalStat.startingRange = 100;
    // // Main
    // FinalStat.endingRange = 200;
    // // Main
    // FinalStat.adStopRange = 20;
    // // Main
    // FinalStat.saveDropOff(latitude: 8.344999, longitude: 38.743965);
    // // Main
    // RouteData.lms = 11;
    // // Main
    // RouteData.hms = 13;
    // // Main
    // RouteData.vhms = 16;
    // // Main
    // RouteData.cutoff = 7;

    FlutterBackgroundLocation.startLocationService();

    FlutterBackgroundLocation.getLocationUpdates((location) {
      print("Location Update");
      setState(() {
        inStartRange = LocationData.isInStationRange(
            lat1: location.latitude,
            long1: location.longitude,
            lat2: FinalStat.routeStartingLocation.latitude,
            long2: FinalStat.routeStartingLocation.longitude);
      });
    });

    _tvStatus =
        DatabaseService().getTVstatus(widget.driverDocID).listen((event) async {
      if (event != null) {
        // print("t stat: " + event.toString());
        // if (event == false && tvRunOnce) {
        //   print("tv stat: " + event.toString());
        //   // logOut();
        // }
        if (event == false) {
          // print("tv stat: " + event.toString());

          // because sometimes app will logout even
          // if its true because app first gets data from
          // cache and logs out before the status in the
          // local cache updated this will make the app
          // wait so it can update the cache so the driver
          // wont be logged out on the second try.
          await Future.delayed(Duration(seconds: 2));
          logOut();
        }
        // tvRunOnce = true;
      }
    });

    _tvStream =
        DatabaseService().getTvStream(widget.driverDocID).listen((event) {
      if (!event.engineSoundPollution ||
          event.speakerPosition == 2 ||
          !event.speakerQuality) {
        badSetup = true;
      } else {
        badSetup = false;
      }
    });

    _driverStream = DatabaseService()
        .getDriverStream(widget.driverDocID)
        .listen((event) async {
      drawerLoaded = true;
      _driver = event;
      if (event.banned) {
        // print("driv stat: " + event.banned.toString());
        logOut();
      }

      if (!driverRunOnce) {
        driverRunOnce = true;
        // NEW
        await DatabaseService()
            .doesUnreportedRouteExist(_driver.docID)
            .then((value) {
          if (value != null) {
            // print("VAL : " + value.toString());
            if (value) {
              logOut();
            }
          } else {
            logOut();
          }
        });

        // NEW
        DatabaseService()
            .getMainRoutesForStartPage(_driver.systemAccountID)
            .then((value) {
          mainRoutes = value;
          String dest = value[0].destination;
          // String start = value[0].startingLocation;
          // String route = start + " - " + dest;
          String route = dest;
          _selectedSuperPath = route;
          mainSuperPathID = value[0].docID;
          spPrice = value[0].spPrice;
          mainRouteChange = true;
          setState(() {});
          DatabaseService().getPaths(value[0].docID).then((value) {
            _selectedPath = value[0].name;
            mainPathID = value[0].pathDocID;
            paths = value;
            FinalStat.clearStaticFields();
            for (var item in paths) {
              if (item.name == _selectedPath) {
                // Main
                FinalStat.routeStartingLocation = item.startingLocation;
                // Main
                FinalStat.routeEndingLocation = item.endingLocation;
                // Main
                FinalStat.startingRange = item.startingRange;
                // Main
                FinalStat.endingRange = item.endingRange;
                // Main
                FinalStat.adStopRange = item.adStopRange;
                // Main
                for (LocationData dropOff in item.dropOffs) {
                  FinalStat.saveDropOff(
                      latitude: dropOff.latitude, longitude: dropOff.longitude);
                }
                mainPathID = item.pathDocID;
                break;
              }
            }
            setState(() {
              mainRouteChange = false;
            });
          });
        });
        DatabaseService().getCarForStartPage(_driver.docID).then((value) {
          if (value != null) {
            // Main
            RouteData.lms = value.lms;
            // Main
            RouteData.hms = value.hms;
            // Main
            RouteData.vhms = value.vhms;
            // Main
            RouteData.cutoff = value.cs;
            mainCarModelID = value.carModelDocID;
            //
            lemz = value.lemz;
            hemz = value.hemz;
            passengerSize = value.passengerSize;
            cmPercentage = value.pricePercentage;
          }
        });
        //

        DatabaseService()
            .getSystemAccount(_driver.systemAccountID)
            .then((value) async {
          _systemRequirementAccount = value;
          if (_systemRequirementAccount != null) {
            // if you plan to use this make sure tvStatus
            // is not commented out
            // if (!_systemRequirementAccount.tvStatus) {
            //   logOut();
            // }
            // allowedToServe must be 1 in order for driver to be allowed
            // to serve DONE
            // We need to compare the current time according to local time to know
            // whether the current time is a valid time to serve Ads this check
            // must be done constantly but since start page will be initialized
            // everytime a driver takes a trip the check will be done before the
            // driver takes a trip which is where we need it. DONE

            // if recent daily value is the same date to current date (locally)
            // allowedToServe becomes 0 and driver cant serve routes
            // because once image uploaded you cant serve for the rest of the
            // day DONE

            DateTime now = DateTime.now().toLocal();
            bool timeZoneSimilar = _systemRequirementAccount.timeZoneOffset ==
                    now.timeZoneOffset.inMinutes
                ? true
                : false;
            bool allowedTime = false;
            if (_systemRequirementAccount.allowedStartingTime.hour < now.hour &&
                _systemRequirementAccount.allowedEndingTime.hour > now.hour) {
              allowedTime = true;
            } else if (_systemRequirementAccount.allowedStartingTime.hour ==
                now.hour) {
              if (_systemRequirementAccount.allowedStartingTime.minute <
                  now.minute) {
                allowedTime = true;
              }
            } else if (_systemRequirementAccount.allowedEndingTime.hour ==
                now.hour) {
              if (_systemRequirementAccount.allowedEndingTime.minute >
                  now.minute) {
                allowedTime = true;
              }
            } else {
              allowedTime = false;
            }
            bool imageUploadedToday = now.day == _driver.recentDailyDate.day &&
                now.month == _driver.recentDailyDate.month &&
                now.year == _driver.recentDailyDate.year;
            if (allowedTime && timeZoneSimilar && !imageUploadedToday) {
              // if daily status is server failure(4) and failedFix is false
              // then we need to delete all images DONE

              if (_driver.recentDailyStatus == 4 && !_driver.failedFix) {
                List<String> imagePaths = await CameraData.getImages();
                // The reason we use != null in addition to not empty is
                // because the first time this app is opened imagePaths will
                // be null so we must protect against that
                if (imagePaths != null) {
                  if (imagePaths.isNotEmpty) {
                    await CameraData.deleteAllImages().then((value) {
                      if (value) {
                        DatabaseService()
                            .updateFailedFixed(_driver.docID)
                            .then((value) {
                          if (value) {
                            allowedToServe = 1;
                          } else {
                            allowedToServe = 2;
                          }
                        });
                      }
                    }).catchError((e) => allowedToServe = 2);
                  } else {
                    DatabaseService()
                        .updateFailedFixed(_driver.docID)
                        .then((value) {
                      if (value) {
                        allowedToServe = 1;
                      }
                    });
                  }
                } else {
                  DatabaseService()
                      .updateFailedFixed(_driver.docID)
                      .then((value) {
                    if (value) {
                      allowedToServe = 1;
                    }
                  });
                }
              } else {
                allowedToServe = 1;
              }
            } else {
              allowedToServe = 0;
            }
          }
          setState(() {});
        });
      }
    });
    // NEW
    _timeSlotTimer = Timer.periodic(Duration(milliseconds: 600), (time) async {
      DateTime cd = DateTime.now();
      if (first && _driver != null) {
        if (!timeSlotFirstEnter && _driver.status) {
          timeSlotFirstEnter = true;
          DatabaseService()
              .getTimeslot(cd, _driver.systemAccountID)
              .then((value) {
            if (value != null) {
              mainTimeSlotID = value.timeSlotID;
              endTime = value.endTime;
              tsPercentage = value.pricePercentage;
            }
            first = false;
          });
        }
      } else if (_driver != null && paths != null) {
        // adCardsRetrieved make sure ad cards are not being retrieved so
        // that two ad card retrival request arent active at the same time
        // _driver.status is useful to know
        if (cd.millisecondsSinceEpoch >= endTime.millisecondsSinceEpoch &&
            adCardsRetrieved &&
            _driver.status) {
          bool allowedTime = false;
          if (_systemRequirementAccount.allowedStartingTime.hour < cd.hour &&
              _systemRequirementAccount.allowedEndingTime.hour > cd.hour) {
            allowedTime = true;
          } else if (_systemRequirementAccount.allowedStartingTime.hour ==
              cd.hour) {
            if (_systemRequirementAccount.allowedStartingTime.minute <=
                cd.minute) {
              allowedTime = true;
            }
          } else if (_systemRequirementAccount.allowedEndingTime.hour ==
              cd.hour) {
            if (_systemRequirementAccount.allowedEndingTime.minute >
                cd.minute) {
              allowedTime = true;
            }
          } else {
            allowedTime = false;
          }
          if (allowedTime) {
            adCardsRetrieved = false;
            adExist = false;
            setState(() {});
            await DatabaseService()
                .getTimeslot(cd, _driver.systemAccountID)
                .then((value) {
              if (value != null) {
                mainTimeSlotID = value.timeSlotID;
                endTime = value.endTime;
                tsPercentage = value.pricePercentage;
              }
            });
            if (mainTimeSlotID != null) {
              // Retrieve compilation/Ad cards again
              DatabaseService()
                  .getAdcards(
                      mainSuperPathID,
                      mainTimeSlotID,
                      mainCarModelID,
                      mainPathID,
                      _driver.systemAccountID,
                      _driver.docID,
                      badSetup,
                      double.tryParse(_driver.calibration.toString()),
                      tsPercentage,
                      cmPercentage,
                      spPrice,
                      lemz,
                      hemz,
                      passengerSize)
                  .then((value) {
                compilationForServe = value;
                if (compilationForServe.totalAdLength > 0) {
                  adExist = true;
                }
                adCardsRetrieved = true;
                widget.compilationForServeVN.value = compilationForServe;
                setState(() {});
              });
            }
          }
        }
      }
      if (pathChange) {
        pathChange = false;
        adExist = false;
        if (mainTimeSlotID != null) {
          DatabaseService()
              .getAdcards(
                  mainSuperPathID,
                  mainTimeSlotID,
                  mainCarModelID,
                  mainPathID,
                  _driver.systemAccountID,
                  _driver.docID,
                  badSetup,
                  double.tryParse(_driver.calibration.toString()),
                  tsPercentage,
                  cmPercentage,
                  spPrice,
                  lemz,
                  hemz,
                  passengerSize)
              .then((value) {
            compilationForServe = value;
            if (compilationForServe.totalAdLength > 0) {
              adExist = true;
            }
            adCardsRetrieved = true;
            widget.compilationForServeVN.value = compilationForServe;
            setState(() {});
          });
        }
      }
      if (startRoute) {
        adCardsRetrieved = false;
        setState(() {});
        startRoute = false;
        DatabaseService().startRoute(compilationForServe).then((value) {
          // print("DATABASESERVICE: $value");
          if (value != null) {
            if (value != "n") {
              compilationForServe.routeID = value;
              widget.compilationForServeVN.value = compilationForServe;
              widget.toggleView();
            } else {
              adCardsRetrieved = true;
              setState(() {});
            }
          } else {
            adCardsRetrieved = true;
            setState(() {});
          }
        });
      }
    });
    //
    super.initState();
  }

  void logOut() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuthUi.instance().logout().then((value) {
        widget.logOutStatus();
        Navigator.pop(context);
      });
    }
  }

  @override
  void dispose() {
    if (_driverStream != null) {
      _driverStream.cancel();
    }
    if (_tvStatus != null) {
      _tvStatus.cancel();
    }
    if (_tvStream != null) {
      _tvStream.cancel();
    }
    if (_timeSlotTimer != null) {
      _timeSlotTimer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;

    FlutterBackgroundLocation.startLocationService();

    // print("allowed to serve: " + allowedToServe.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text("NEGARIT-AD"),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(Icons.delete),
              onPressed: allowedToServe == 2
                  ? () async {
                      await CameraData.deleteAllImages().then((value) {
                        if (value) {
                          DatabaseService()
                              .updateFailedFixed(_driver.docID)
                              .then((value) {
                            if (value) {
                              allowedToServe = 1;
                            } else {
                              allowedToServe = 2;
                            }
                          });
                        }
                      }).catchError((e) => allowedToServe = 2);
                      setState(() {});
                    }
                  : null),
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      content: Text(
                        "Are you sure you want to Logout?",
                        style: TextStyle(fontSize: deviceWidth * 0.06),
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            logOut();
                            Navigator.pop(context);
                            widget.logOutStatus();
                          },
                          child: Text(
                            'Yes',
                            style: TextStyle(fontSize: deviceWidth * 0.06),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'No',
                            style: TextStyle(fontSize: deviceWidth * 0.06),
                          ),
                        ),
                      ],
                    );
                  },
                );
              }),
        ],
      ),
      drawer: drawerLoaded
          ? MyDrawer(
              driverName: _driver.name,
              driverDocID: widget.driverDocID,
              balance: double.parse(_driver.balance.toString()),
              potentialBalance:
                  double.parse(_driver.potentialBalance.toString()),
              systemAccountId: _driver.systemAccountID,
              plateNumber: _driver.plateNumber,
              phoneNumber: _driver.phoneNumber,
              mainRoutes: _driver.mainRoutes,
              totalProfit: _driver.totalProfit,
              calibrationValue: _driver.calibration,
              allowedToServe: allowedToServe,
            )
          : Loading(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: adCardsRetrieved
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Allowed Time",
                    style: TextStyle(fontSize: deviceWidth * 0.06),
                  ),
                  _systemRequirementAccount != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              timeFormat.format(_systemRequirementAccount
                                  .allowedStartingTime),
                              style: TextStyle(fontSize: deviceWidth * 0.07),
                            ),
                            Text(
                              "-",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.08,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              timeFormat.format(
                                  _systemRequirementAccount.allowedEndingTime),
                              style: TextStyle(fontSize: deviceWidth * 0.07),
                            )
                          ],
                        )
                      : Container(
                          width: 0,
                          height: 0,
                        ),
                  SizedBox(
                    height: deviceHeight * 0.01,
                  ),
                  Text(
                    "TRIP",
                    style: TextStyle(
                        fontSize: deviceWidth * 0.1,
                        fontWeight: FontWeight.w400),
                  ),
                  SizedBox(
                    height: deviceHeight * 0.015,
                  ),
                  ValueListenableBuilder<bool>(
                      valueListenable: widget.speakCon,
                      builder:
                          (BuildContext context, bool value, Widget child) {
                        return Row(
                          children: [
                            Text(
                              "Speaker Connected :",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.08,
                                  fontWeight: FontWeight.w300),
                            ),
                            SizedBox(
                              width: deviceWidth * 0.03,
                            ),
                            Icon(
                              Icons.speaker,
                              size: deviceWidth * 0.1,
                              color: value ? Colors.green : Colors.red,
                            )
                          ],
                        );
                      }),
                  SizedBox(
                    height: deviceHeight * 0.015,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Choose Your Destination ",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.07,
                                  fontWeight: FontWeight.w300)),
                        ],
                      ),
                      Container(
                        width: deviceWidth * 0.68,
                        child: DropdownButton(
                          isExpanded: true,
                          items: mainRoutes.map((e) {
                            String dest = e.destination;
                            // String start = e.startingLocation;
                            // String route = start + " - " + dest;
                            String route = dest;
                            return DropdownMenuItem<String>(
                              child: Text(
                                route,
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.06,
                                    fontWeight: FontWeight.w300),
                              ),
                              value: route,
                            );
                          }).toList(),
                          style: TextStyle(
                            fontSize: deviceWidth * 0.1,
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                          ),
                          onChanged: onRegionChange,
                          value: _selectedSuperPath,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: deviceHeight * 0.01,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Choose Your Path ",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.07,
                                  fontWeight: FontWeight.w300)),
                          SizedBox(
                            width: deviceWidth * 0.04,
                          ),
                          IconButton(
                              icon: Icon(
                                Icons.refresh,
                                size: deviceWidth * 0.1,
                              ),
                              onPressed: mainRouteChange
                                  ? null
                                  : _driver != null
                                      ? _driver.status && paths != null
                                          ? () {
                                              DateTime cd = DateTime.now();
                                              bool allowedTime = false;
                                              if (_systemRequirementAccount
                                                          .allowedStartingTime
                                                          .hour <
                                                      cd.hour &&
                                                  _systemRequirementAccount
                                                          .allowedEndingTime
                                                          .hour >
                                                      cd.hour) {
                                                allowedTime = true;
                                              } else if (_systemRequirementAccount
                                                      .allowedStartingTime
                                                      .hour ==
                                                  cd.hour) {
                                                if (_systemRequirementAccount
                                                        .allowedStartingTime
                                                        .minute <=
                                                    cd.minute) {
                                                  allowedTime = true;
                                                }
                                              } else if (_systemRequirementAccount
                                                      .allowedEndingTime.hour ==
                                                  cd.hour) {
                                                if (_systemRequirementAccount
                                                        .allowedEndingTime
                                                        .minute >
                                                    cd.minute) {
                                                  allowedTime = true;
                                                }
                                              } else {
                                                allowedTime = false;
                                              }
                                              if (allowedTime) {
                                                adCardsRetrieved = false;
                                                // retrieve compilaiton here (path change acts
                                                // as a trigger)
                                                pathChange = true;
                                              }
                                              setState(() {});
                                            }
                                          : null
                                      : null)
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: deviceWidth * 0.9,
                            child: DropdownButton(
                              isExpanded: true,
                              // items: _regionItems2,
                              items: paths.map((e) {
                                return DropdownMenuItem<String>(
                                  child: Text(
                                    e.name,
                                    style: TextStyle(
                                        fontSize: deviceWidth * 0.05,
                                        fontWeight: FontWeight.w300),
                                  ),
                                  value: e.name,
                                );
                              }).toList(),
                              style: TextStyle(
                                fontSize: deviceWidth * 0.1,
                                color: Colors.black,
                                fontWeight: FontWeight.w300,
                              ),
                              onChanged: mainRouteChange
                                  ? null
                                  : _driver != null
                                      ? _driver.status && paths != null
                                          ? onRegionChange2
                                          : null
                                      : null,
                              value: _selectedPath,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: deviceHeight * 0.01,
                  ),
                  Row(
                    children: [
                      Text(
                        "Ad Exist For Route:",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.07,
                            fontWeight: FontWeight.w300),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.03,
                      ),
                      Icon(
                        compilationForServe != null
                            ? compilationForServe.totalAdLength > 0
                                ? Icons.done
                                : Icons.cancel
                            : Icons.timelapse,
                        size: deviceWidth * 0.1,
                        color: compilationForServe != null
                            ? compilationForServe.totalAdLength > 0
                                ? Colors.green
                                : Colors.red
                            : Colors.grey,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: deviceHeight * 0.01,
                  ),
                  Row(
                    children: [
                      Text(
                        "Ads Missing :",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.07,
                            fontWeight: FontWeight.w300),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.03,
                      ),
                      Text(
                        compilationForServe != null
                            ? compilationForServe.missingAds.toString()
                            : "0",
                        style: TextStyle(
                            color: compilationForServe != null
                                ? compilationForServe.missingAds > 0
                                    ? Colors.red
                                    : Colors.green
                                : Colors.grey,
                            fontSize: deviceWidth * 0.09,
                            fontWeight: FontWeight.normal),
                      )
                    ],
                  ),
                  SizedBox(
                    height: deviceHeight * 0.015,
                  ),
                  Row(
                    children: [
                      Text(
                        "Profit(~) :",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w300),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.03,
                      ),
                      Text(
                        compilationForServe != null
                            ? compilationForServe.availableprofit < 1000
                                ? compilationForServe.availableprofit
                                        .toStringAsFixed(2) +
                                    " \$"
                                : compilationForServe.availableprofit
                                        .toStringAsPrecision(3) +
                                    " \$"
                            : "00.00" + " \$",
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: deviceWidth * 0.11,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: deviceHeight * 0.01,
                  ),
                  drawerLoaded
                      ? ValueListenableBuilder<bool>(
                          valueListenable: widget.speakCon,
                          builder:
                              (BuildContext context, bool value, Widget child) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: value &&
                                          // status is used because a driver
                                          // can be without a TV (transport
                                          // vehicle at any moment)
                                          _driver.status &&
                                          allowedToServe == 1 &&
                                          // make sure that ad/ads exist
                                          // to be served in this route
                                          adExist &&
                                          // just to be extra safe
                                          DateTime.now()
                                                  .millisecondsSinceEpoch <
                                              endTime.millisecondsSinceEpoch &&
                                          inStartRange
                                      ? () {
                                          // explanation for why allowed time is
                                          // checked again when start route button
                                          // is clicked is in code remark
                                          DateTime now =
                                              DateTime.now().toLocal();
                                          bool allowedTime = false;
                                          if (_systemRequirementAccount
                                                      .allowedStartingTime
                                                      .hour <
                                                  now.hour &&
                                              _systemRequirementAccount
                                                      .allowedEndingTime.hour >
                                                  now.hour) {
                                            allowedTime = true;
                                          } else if (_systemRequirementAccount
                                                  .allowedStartingTime.hour ==
                                              now.hour) {
                                            if (_systemRequirementAccount
                                                    .allowedStartingTime
                                                    .minute <=
                                                now.minute) {
                                              allowedTime = true;
                                            }
                                          } else if (_systemRequirementAccount
                                                  .allowedEndingTime.hour ==
                                              now.hour) {
                                            if (_systemRequirementAccount
                                                    .allowedEndingTime.minute >
                                                now.minute) {
                                              allowedTime = true;
                                            }
                                          } else {
                                            allowedTime = false;
                                          }
                                          showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: Text(
                                                    allowedTime
                                                        ? "Are you sure you want" +
                                                            " to start the Route ?"
                                                        : "You are not allowed " +
                                                            "to start a route " +
                                                            "at this time.",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w400),
                                                  ),
                                                  actions: [
                                                    allowedTime
                                                        ? TextButton(
                                                            onPressed: () {
                                                              startRoute = true;
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              "Yes",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      deviceWidth *
                                                                          0.07),
                                                            ))
                                                        : null,
                                                    allowedTime
                                                        ? TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              "No",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      deviceWidth *
                                                                          0.07),
                                                            ))
                                                        : TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              "OK",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      deviceWidth *
                                                                          0.06),
                                                            ))
                                                  ],
                                                );
                                              });
                                        }
                                      : null,
                                  child: Text(
                                    "START ROUTE",
                                    style: TextStyle(
                                      fontSize: deviceWidth * 0.07,
                                    ),
                                  ),
                                )
                              ],
                            );
                          })
                      : Container(
                          width: 0,
                          height: 0,
                        ),
                  SizedBox(
                    height: deviceHeight * 0.01,
                  ),
                  !inStartRange
                      ? Text(
                          "Not In Range!",
                          style: TextStyle(fontSize: 15, color: Colors.red),
                        )
                      : SizedBox(
                          height: 0,
                        )
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Loading()],
              ),
      ),
    );
  }
}
