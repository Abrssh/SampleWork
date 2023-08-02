import 'dart:async';

import 'package:csp_app/Classes/AD_data.dart';
import 'package:csp_app/Classes/recorded_data.dart';
import 'package:csp_app/Pages/Drawer%20Pages/Testing/ad_stats.dart';
// import 'package:csp_app/Pages/Drawer%20Pages/Testing/distance_locs.dart';
import 'package:csp_app/Shared/constant.dart';
import 'package:csp_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_location/flutter_background_location.dart';
import 'package:csp_app/Classes/location_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

class NoiseMeterTest extends StatefulWidget {
  @override
  _NoiseMeterTestState createState() => _NoiseMeterTestState();
}

class _NoiseMeterTestState extends State<NoiseMeterTest> {
  bool routeReady = false;
  bool startSaved = false;
  bool routeSelected = true;
  bool routeStarted = false;
  bool resultTime = false;
  bool canSaveStart = false;
  LocationData nft;
  int accuracyThreshold = 200;
  int adv = 0;
  int prevAdv = 0;
  int pausednum = 0;
  bool paused = false;
  bool adtime = false;
  bool silencetime = false;
  double totalAdTimeVoice = 0.0;
  int totalAdTimeVoiceNo = 0;
  double totalPrevAdTimeVoice = 0.0;
  int totalPrevAdTimeVoiceNo = 0;
  double totalStTimeVoice = 0.0;
  int totalStTimeVoiceNo = 0;
  LocationData selectedDestination;
  LocationData startingPosition;
  List<LocationData> savedLocations = [];
  double totalDistance;
  double totalCalculatedDistance;
  int numLocations;
  int totalTime;
  bool statGenerated;
  Timer _timer;
  int _adStopping = 0;
  double displacement = 0;
  String reportDestination = "";
  StreamSubscription<NoiseReading> _noiseSubscription;
  NoiseMeter _noiseMeter;
  int time = 0;
  double perSec = 0;
  bool isRecording = false;
  double totalNoise = 0.0;
  double average = 0.0;
  double caliber = 0.0;
  double oldSoundLevel = 0.0;
  double soundLevel = 0.0;
  int lms = 11;
  int hms = 13;
  int vhms = 16;
  int cutoff = 7;
  //double upDistance;

  void showSnack({String message, var context, int type = 1}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: type == 1 ? Colors.black : Colors.red,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  void initState() {
    super.initState();

    //Request Permission
    _requestPermission();

    // Remove Saved Starting Location & Saved Progresses
    cleanHistory();

    // Remove Saved AD Ending Times & Saved Paused Locations
    cleanAdHistory();

    // Initialize Noise Meter
    _noiseMeter = new NoiseMeter((e) {
      setState(() {
        isRecording = false;
      });
      print("ERROR NOISE INIT: " + e.toString());
    });

    // Starts Location Service
    FlutterBackgroundLocation.startLocationService();

    // Activates the Listener for Location Updates
    FlutterBackgroundLocation.getLocationUpdates((location) {
      // Update the State of the current location object
      setState(() {
        this.nft = LocationData.withAccuracy(
            latitude: location.latitude,
            longitude: location.longitude,
            speed: location.speed,
            accuracy: location.accuracy);
      });

      // Result Time is always false if the app is no route or being ready to a route
      if (!resultTime) {
        // Route Started is true if the app has already started a route which means if the moved distance is greater than the starting range
        if (routeReady) {
          setState(() {
            routeStarted = true;
          });
          startRecording();
        }

        if (routeStarted) {
          if (adv == 0) {
            setState(() {
              adv = 1;
              prevAdv = 1;
              adtime = true;
              _adStopping = 0;
            });
            // Starts the Timer to calculate current ADs, Silence Times, and Previous ADs

          }
          // Checks if whether the current received location accuracy is lower than the needed max-threshold
          if (nft.accuracy < this.accuracyThreshold) {
            // Checks whether the received distance is less than the ending range

            // If the distance between the current received location and the stopping location is above the ending range, then the route is not over
            // AD TIme is only false when the route is paused
            if (adtime) {
              // Saves the location as an active progress
              LocationData adDataToBeSaved = LocationData.forAD(
                  latitude: nft.latitude,
                  longitude: nft.longitude,
                  name: "AD-" + adv.toString() + "-" + prevAdv.toString(),
                  accuracy: nft.accuracy,
                  speed: nft.speed,
                  timestamp: nft.timestamp);
              LocationData.saveProgress(adDataToBeSaved).then((value) {});
            } else {
              // Saves the location anyway
              LocationData.saveProgress(nft).then((value) {});
            }
          }
        }
      }
    });
  }

  // Request Permission
  void _requestPermission() async {
    var microphoneStatus = await Permission.microphone.status;
    var backgroundLocationStatus = await Permission.locationAlways.status;
    if (!microphoneStatus.isGranted && !backgroundLocationStatus.isGranted) {
      await Permission.microphone.request();
      await Permission.locationAlways.request();
    } else if (!microphoneStatus.isGranted) {
      await Permission.microphone.request();
    } else if (!backgroundLocationStatus.isGranted) {
      await Permission.locationAlways.request();
    }
  }

  // On Data
  void onData(NoiseReading noiseReading) {
    print("RECORD : " + isRecording.toString());
    //showSnack(message: "${this.isRecording}", context: context);

    if (isRecording &&
        !paused &&
        double.parse(noiseReading.maxDecibel.toString()).isFinite) {
      setState(() {
        soundLevel = double.parse(noiseReading.maxDecibel.toString());
      });

      setState(() {
        soundLevel += caliber;
        oldSoundLevel = soundLevel;
      });
      // If the status is on Silent Time
      if (silencetime) {
        try {
          setState(() {
            totalStTimeVoice += soundLevel;
            totalStTimeVoiceNo++;
          });
          print("Sound Silence Recorded " +
              (totalStTimeVoice.toString()) +
              " - " +
              totalStTimeVoiceNo.toString());
        } catch (e) {
          print("Silence Time Volume Error: " + e.toString());
        }
      }
      // Record it anyway
      try {
        setState(() {
          totalPrevAdTimeVoice += soundLevel;
          totalPrevAdTimeVoiceNo++;
        });
      } catch (e) {
        print("Prev Volume Error: " + e.toString());
      }

      try {
        // If Prev Adv == Adv
        if (prevAdv != adv) {
          setState(() {
            totalAdTimeVoice += soundLevel;
            totalAdTimeVoiceNo++;
          });
        }
        print("Sound AD Recorded " +
            (totalPrevAdTimeVoice.toString()) +
            " - " +
            totalPrevAdTimeVoiceNo.toString());
      } catch (e) {
        print("Final Volume Error: " + e.toString());
      }
    }
  }

  // Start Recording
  void startRecording() async {
    try {
      AdData.lms = lms;
      AdData.hms = hms;
      AdData.vhms = vhms;
      AdData.cutoff = cutoff;
      setState(() {
        isRecording = true;
      });
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
      print("NOISE SUB: " + _noiseSubscription.toString());
    } catch (err) {
      setState(() {
        isRecording = false;
      });
      print("ERROR NOISE SUB: " + err.toString());
    }
  }

  @override
  void dispose() {
    // Dispose the Listener and Timer
    FlutterBackgroundLocation.stopLocationService();
    if (_timer != null) {
      _timer.cancel();
    }
    this.setState(() {
      isRecording = false;
    });
    if (_noiseSubscription != null) {
      _noiseSubscription.cancel();
    }
    super.dispose();
  }

  // Timer Function
  void startTimer() {
    print("counting time");

    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        // Check if the AD is not the first AD at the 3rd Second of the counter
        if (_adStopping == 3 && adv > 1) {
          // Save the average here
          if (totalPrevAdTimeVoiceNo > 0) {
            RecordedData.saveAverage(RecordedData(
                    name: "AD",
                    counter: prevAdv,
                    average: totalPrevAdTimeVoice / totalPrevAdTimeVoiceNo))
                .then((value) => null);
          }
          // If the Previous AD counter has not been updated to the current AD counter then update it
          print("PREADV : $prevAdv --- ADV : $adv");
          if (adv > prevAdv) {
            setState(() {
              prevAdv = prevAdv += 1;
            });

            // Assign new average to old average
            setState(() {
              totalPrevAdTimeVoice = totalAdTimeVoice;
              totalPrevAdTimeVoiceNo = totalAdTimeVoiceNo;
              totalAdTimeVoice = 0;
              totalAdTimeVoiceNo = 0;
            });
          }
        }
        // End the range of Silence Time at the 8th Second
        if (_adStopping == 1) {
          // Save Silence here
          if (totalStTimeVoiceNo > 0) {
            RecordedData.saveAverage(RecordedData(
                    name: "ST",
                    counter: prevAdv - 1,
                    average: totalStTimeVoice / totalStTimeVoiceNo))
                .then((value) => null);
          }
          setState(() {
            silencetime = false;
          });

          // Initialize Silence recording data
          setState(() {
            totalStTimeVoice = 0;
            totalStTimeVoiceNo = 0;
          });
        }

        // Reset the adStopping Counter to 0 and increment the current AD counter at the 32 Second
        if (_adStopping == 32) {
          setState(() {
            _adStopping = 0;
            adv = adv + 1;
            adtime = true;
          });
          // Sets the new average  = 0
        } else {
          // Save the AD stopping time which will later be used in the AD duration at the 30 Second, meaning the current ad has ended
          // Start the Silence Time by setting it to True
          if (_adStopping == 30) {
            AdData.saveAdFinals();
            setState(() {
              silencetime = true;
            });
          }
          // Increment the adStopping counter unless the Route is paused
          _adStopping++;
        }
      },
    );
  }

  // Stops the ongoing Route
  void stopRoute() {
    if (silencetime) {
      if (totalStTimeVoiceNo > 0) {
        RecordedData.saveAverage(RecordedData(
                name: "ST",
                counter: prevAdv - 1,
                average: totalStTimeVoice / totalStTimeVoiceNo))
            .then((value) => null);
      }
    }
    if (totalPrevAdTimeVoiceNo > 0) {
      RecordedData.saveAverage(RecordedData(
              name: "AD",
              counter: prevAdv,
              average: totalPrevAdTimeVoice / totalPrevAdTimeVoiceNo))
          .then((value) => null);
    }
    if (selectedDestination != null) {
      reportDestination = selectedDestination.name;
    }
    _timer.cancel();
    print("1 IS RECORD NOISE SUBSCRIPTION NULL? $_noiseSubscription");
    if (_noiseSubscription != null) {
      _noiseSubscription.cancel();
    }
    this.setState(() {
      isRecording = false;
    });
    setState(() {
      _noiseSubscription = null;
    });

    print("2 IS RECORD NOISE SUBSCRIPTION NULL? $_noiseSubscription");
    // Save the last AD ending timestamp if the ad is really playing
    if (adtime && _adStopping <= 30) {
      AdData.saveAdFinals();
    }
    // Instantiate the state back to their original values
    setState(() {
      routeStarted = false;
      selectedDestination = null;
      routeSelected = false;
      routeReady = false;
      startSaved = false;
      resultTime = true;
      adtime = false;
      adv = 0;
      pausednum = 0;
      prevAdv = 0;
      _adStopping = 0;
      nft = null;
    });
  }

  // Cleans the cache of Saved Starting Location and Saved Progress Locations
  void cleanHistory() async {
    final prefs = await AppMain.mainPrefs;
    await prefs.remove('start_location');
    await prefs.remove('dist_progress');
  }

  // Cleans the cache of Saved AD ending times, recorded voices, and Saved Paused Locations
  void cleanAdHistory() async {
    final prefs = await AppMain.mainPrefs;
    await prefs.remove('ad_finals');
    await prefs.remove('recorded_data');
    await prefs.remove('paused_locations');
  }

  // Calculates Toatal Route Duration
  int calculateTime(LocationData starting, LocationData ending) {
    return (ending.timestamp.millisecondsSinceEpoch -
            starting.timestamp.millisecondsSinceEpoch) ~/
        60000;
  }

  // Generate the Stats for the Ended Route
  generateStats() async {
    // Stops the Location Listener
    FlutterBackgroundLocation.stopLocationService();

    // Cleans the Locations List to generate a whole new Locations List
    setState(() {
      savedLocations = [];
    });

    final prefs = await AppMain.mainPrefs;
    List<String> savedProgresses = prefs.getStringList('dist_progress');

    // Check whether there were any Saved Progresses by checking if its null or less than 3
    if (savedProgresses != null) {
      if (savedProgresses.length >= 3) {
        // Get Saved Starting and Stopping Locations
        LocationData startingLocation = LocationData.fromString(
          ldString: savedProgresses.first,
        );
        LocationData stoppingLocation = LocationData.fromString(
          ldString: savedProgresses.last,
        );
        print(
            "Starting Location: $startingLocation ; Ending Location: $stoppingLocation");
        // Calculate the pure displacement of the ideal and complete route
        double distance = Geolocator.distanceBetween(
            startingLocation.latitude,
            startingLocation.longitude,
            stoppingLocation.latitude,
            stoppingLocation.longitude);
        // Save the ideal and complete distance as a total distance
        setState(() {
          totalDistance = distance;
        });
        // Loop through all Saved Progress and Save them in the Saved Locations list EXCEPT FOR PAUSED LOCATIONS
        for (String svstr in savedProgresses) {
          LocationData retreivedData = LocationData.fromString(
            ldString: svstr,
          );
          if (retreivedData.name != null) {
            if (retreivedData.name.contains('PS')) {
              continue;
            }
          }
          savedLocations.add(retreivedData);
        }
        // Instantiate Calculated Distance
        setState(() {
          totalCalculatedDistance = 0;
        });
        if (savedLocations.length >= 3) {
          // Calculate the distance traveled by evaluating each leap taken and incrementing it to the Calculated Distance Variable
          for (int i = 1; i < savedLocations.length; i++) {
            setState(() {
              totalCalculatedDistance = totalCalculatedDistance +
                  Geolocator.distanceBetween(
                      savedLocations[i - 1].latitude,
                      savedLocations[i - 1].longitude,
                      savedLocations[i].latitude,
                      savedLocations[i].longitude);
            });
          }
        }
        //Calculate total Route Duration by Subtracting the timestamps between the Last and First Saved Locations
        int mins = calculateTime(
            savedLocations[0], savedLocations[savedLocations.length - 1]);

        // Assign the Stats to their resepective variables to show
        setState(() {
          numLocations = savedLocations.length;
          resultTime = true;
          totalTime = mins;
          statGenerated = true;
        });
        // Remove Saved Starting Location & Saved Progresses
        cleanHistory();
      } else {
        for (String svstr in savedProgresses) {
          LocationData retreivedData = LocationData.fromString(
            ldString: svstr,
          );
          if (retreivedData.name != null) {
            if (retreivedData.name.contains('PS')) {
              continue;
            }
          }
          savedLocations.add(retreivedData);
        }
        // Remove Saved AD Ending Times & Saved Paused Locations
        cleanHistory();
        // Report that there was no Stat Generated
        setState(() {
          statGenerated = false;
        });
      }
    } else {
      // Remove Saved AD Ending Times & Saved Paused Locations
      cleanHistory();
      // Report that there was no Stat Generated
      setState(() {
        statGenerated = false;
      });
    }
  }

  Widget locationData(String data) {
    return Text(
      data,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget resultWidget(dynamic context) {
    if (statGenerated) {
      return Container(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
              ),
              locationData(
                  "Displacement: ${(totalDistance / 1000).toStringAsFixed(2)}"),
              SizedBox(
                height: 5,
              ),
              locationData(
                  "Distance: ${(totalCalculatedDistance / 1000).toStringAsFixed(2)}"),
              SizedBox(
                height: 5,
              ),
              locationData("Data Length: $numLocations"),
              SizedBox(
                height: 5,
              ),
              locationData("Total Time: $totalTime mins"),
              SizedBox(height: 20),
              RaisedButton(
                  color: Colors.blue,
                  onPressed: () async {
                    // Generates AD Data by using the Saved Locations and report them to the AD status Screen
                    List<AdData> stats =
                        await AdData.generateAdData(savedLocations);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (BuildContext context) => Scaffold(
                                  body: AdStats(
                                    savedStats: stats,
                                  ),
                                )));
                  },
                  child: Text(
                    "AD Stats",
                    style: TextStyle(color: Colors.white),
                  )),
              SizedBox(height: 5),
              RaisedButton(
                  color: Colors.blue,
                  onPressed: () {
                    showSnack(
                        message: "Long Press to Finish", context: context);
                  },
                  onLongPress: () {
                    // Instantiates Variables to Start Again
                    cleanAdHistory();
                    setState(() {
                      FlutterBackgroundLocation.startLocationService();
                      stopRoute();
                      resultTime = false;
                      totalCalculatedDistance = null;
                      totalDistance = null;
                      numLocations = null;
                      reportDestination = null;
                    });
                  },
                  child: Text(
                    "Done",
                    style: TextStyle(color: Colors.white),
                  )),
              SizedBox(
                height: 5,
              ),
            ],
          ),
        ),
      );
    } else {
      // Show that There are no Stats Generated
      return Container(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                savedLocations != null
                    ? savedLocations.length.toString() + " Saved Locations"
                    : "No Saved Locations",
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 5),
              Text(
                "No Stat",
                style: TextStyle(fontSize: 20),
              ),
              SizedBox(height: 20),
              RaisedButton(
                  color: Colors.blue,
                  onPressed: () {
                    setState(() {
                      FlutterBackgroundLocation.startLocationService();
                      stopRoute();
                      resultTime = false;
                      totalCalculatedDistance = null;
                      totalDistance = null;
                      numLocations = null;
                    });
                  },
                  child: Text(
                    "Done",
                    style: TextStyle(color: Colors.white),
                  ))
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Location AD Sim"),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: Row(
              children: [
                InkWell(
                  child: Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  onLongPress: () {
                    FlutterBackgroundLocation.startLocationService();
                  },
                  onTap: () {},
                ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 0),
            child: !resultTime
                ? ListView(
                    children: [
                      SizedBox(
                        height: 50,
                      ),
                      locationData(
                          "Latitude:  ${this.nft != null ? nft.latitude.toString() : 'waiting...'}"),
                      locationData(
                          "Longitude: ${this.nft != null ? nft.longitude.toString() : 'waiting...'}"),
                      locationData(
                          "Accuracy: ${this.nft != null ? nft.accuracy.toStringAsFixed(3) : 'waiting...'}"),
                      locationData(
                          "Speed: ${this.nft != null ? nft.speed.toStringAsFixed(3) : 'waiting...'}"),

                      SizedBox(
                        height: 5,
                      ),
                      RaisedButton(
                        color: routeReady ? Colors.red : Colors.blue,
                        onPressed: () {
                          // If Route has been Selected then This is a Start Route Button, It sets Route Ready to True
                          if (!routeReady) {
                            setState(() {
                              routeReady = true;
                            });
                            startTimer();
                          } else {
                            showSnack(
                                message: "Long Press to End Route",
                                context: context);
                          }

                          // If Route has not been Selected then This is a Select Destination Button, It Selects Destination and Set Route Selected to True
                        },
                        onLongPress: () async {
                          // Stop Route and Generate the Stats
                          if (routeReady) {
                            stopRoute();
                            await generateStats();
                            showSnack(message: "Route Ended", context: context);
                          }
                        },
                        child: Text(
                          // This Becomes a Start Route Button if Route has been Selected. It is Selected Destination Button if Route has not been Selected
                          routeReady ? "End Route" : "Start Route",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      // routeStarted
                      //     ? Container(
                      //         margin: EdgeInsets.only(top: 40),
                      //         child: RaisedButton(
                      //           color: Colors.red,
                      //           onPressed: () {
                      //             showSnack(
                      //                 message: "Long Press to End Route",
                      //                 context: context);
                      //           },
                      //           onLongPress: () async {
                      //             // Stop Route and Generate the Stats
                      //             stopRoute();
                      //             await generateStats();
                      //             showSnack(
                      //                 message: "Route Ended", context: context);
                      //           },
                      //           child: Text(
                      //             "End Route",
                      //             style: TextStyle(color: Colors.white),
                      //           ),
                      //         ),
                      //       )
                      //     : SizedBox(
                      //         height: 0,
                      //       ),

                      // Show Destination Name if a Destination has been Selected

                      // Show Total Displacement if a Destination has been Selected

                      Container(
                        margin: EdgeInsets.only(top: 20),
                        child: Row(
                          children: [
                            RaisedButton(
                              color: Colors.blue,
                              onPressed: () {
                                setState(() {
                                  caliber -= 0.5;
                                });
                              },
                              child: Text(
                                "-",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                            Expanded(
                                child: locationData("Calibration : $caliber")),
                            RaisedButton(
                              color: Colors.blue,
                              onPressed: () {
                                setState(() {
                                  caliber += 0.5;
                                });
                              },
                              child: Text(
                                "+",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Enable the Save Starting Location Button if a Route has not been Selected, and a Route has not been Started

                      // If Route has been Started and Is Not in Paused State, THen Show Adv Counter and adStopping Time Counter
                      routeStarted
                          ? adtime
                              ? _adStopping == 31 || _adStopping == 32
                                  ? SizedBox(
                                      height: 0,
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: locationData(
                                          "Serving AD No $adv; $_adStopping Elapsed Time"),
                                    )
                              : SizedBox(
                                  height: 0,
                                )
                          : SizedBox(
                              height: 0,
                            ),
                      routeStarted
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: prevAdv == adv
                                  ? locationData("Average DB : " +
                                      (totalPrevAdTimeVoice /
                                              totalPrevAdTimeVoiceNo)
                                          .toStringAsFixed(3))
                                  : locationData("Average DB : " +
                                      (totalAdTimeVoice / totalAdTimeVoiceNo)
                                          .toStringAsFixed(3)))
                          : SizedBox(
                              height: 0,
                            ),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration:
                                  textInputDecoration.copyWith(hintText: "LMS"),
                              validator: (value) =>
                                  value.isEmpty ? "Enter LMS" : null,
                              onChanged: (value) {
                                int kk = 11;
                                try {
                                  kk = int.parse(value);
                                  setState(() {
                                    lms = kk;
                                  });
                                } catch (e) {
                                  //error
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: TextFormField(
                              decoration:
                                  textInputDecoration.copyWith(hintText: "HMS"),
                              validator: (value) =>
                                  value.isEmpty ? "Enter HMS" : null,
                              onChanged: (value) {
                                int kk = 13;
                                try {
                                  kk = int.parse(value);
                                  setState(() {
                                    hms = kk;
                                  });
                                } catch (e) {
                                  //error
                                }
                              },
                            ),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Expanded(
                            child: TextFormField(
                              decoration: textInputDecoration.copyWith(
                                  hintText: "VHMS"),
                              validator: (value) =>
                                  value.isEmpty ? "Enter VHMS" : null,
                              onChanged: (value) {
                                int kk = 16;
                                try {
                                  kk = int.parse(value);
                                  setState(() {
                                    vhms = kk;
                                  });
                                } catch (e) {
                                  //error
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        decoration:
                            textInputDecoration.copyWith(hintText: "Cut Off"),
                        validator: (value) =>
                            value.isEmpty ? "Enter Cut Off" : null,
                        onChanged: (value) {
                          int kk = 7;
                          try {
                            kk = int.parse(value);
                            setState(() {
                              cutoff = kk;
                            });
                          } catch (e) {
                            //error
                          }
                        },
                      ),

                      // Show the End Route Button if Route has been Started

                      // Provide an Option to Unselect Destination if Route has been Selected and Route has not Started
                    ],
                  )
                :
                // Show Result Widget if the app is on Result Time State
                resultWidget(context)),
      ),
    );
  }
}
