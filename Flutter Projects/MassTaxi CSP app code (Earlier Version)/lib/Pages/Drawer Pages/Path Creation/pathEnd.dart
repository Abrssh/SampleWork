// import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csp_app/Classes/location_data.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/loading.dart';
// import 'package:csp_app/Shared/constant.dart';
import 'package:csp_app/main.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PathDone extends StatefulWidget {
  final String systemAccountId,
      superPathDocID,
      // startingLocation,
      destination,
      cspID;
  PathDone(
      {this.systemAccountId,
      this.superPathDocID,
      this.cspID,
      // this.startingLocation,
      this.destination});
  @override
  _PathDoneState createState() => _PathDoneState();
}

class _PathDoneState extends State<PathDone> {
  TextEditingController _efficiencyRange = TextEditingController();
  TextEditingController _adStopRange = TextEditingController();
  TextEditingController _boardingRange = TextEditingController();
  TextEditingController _destinationRange = TextEditingController();
  TextEditingController _initialTime = TextEditingController();
  List<LocationData> savedLocations = [];
  double totalDistance = 0;
  double totalCalculatedDistance = 0;
  //Main
  int efficencyPercentage = 0;
  //Main
  double totalTime = 0;

  int numLocations = 0;
  int numDropOffs = 0;
  //Main
  String pathname = '';
  //Main
  List<LocationData> savedDropOffs = [];
  // Main
  GeoPoint _startingLocation, _destination;

  bool loading = true;

  Map<String, GeoPoint> changeLocDataToMap(
      List<LocationData> locationDataColl) {
    // List<GeoPoint> geoPoints = [];
    Map<String, GeoPoint> dropOffs = {};
    locationDataColl.forEach((element) {
      // geoPoints.add(GeoPoint(element.latitude, element.longitude));
      dropOffs[element.name] = GeoPoint(element.latitude, element.longitude);
    });
    print("drop offs leng: " + dropOffs.length.toString());
    // return geoPoints;
    return dropOffs;
  }

  @override
  void initState() {
    _efficiencyRange.text = "0";
    _adStopRange.text = "0";
    _initialTime.text = "30";
    _boardingRange.text = "15";
    _destinationRange.text = "15";
    generateReport();
    super.initState();
  }

  void generateReport() async {
    // Cleans the Locations List to generate a whole new Locations List
    setState(() {
      savedLocations = [];
    });

    LocationData.getPathName().then((value) {
      setState(() {
        pathname = value;
      });
    });

    final prefs = await AppMain.mainPrefs;
    List<String> savedProgresses = prefs.getStringList('dist_progress');
    List<LocationData> savedDrops = await LocationData.getDropOffLocations();
    setState(() {
      savedDropOffs = savedDrops;
    });
    print("${savedDropOffs.length} SAVED DROP OFFS : $savedDropOffs");

    if (savedDropOffs != null) {
      setState(() {
        numDropOffs = savedDropOffs.length;
      });
    }

    // Check whether there were any Saved Progresses by checking if its null or less than 3
    if (savedProgresses != null) {
      if (savedProgresses.length >= 3) {
        // Get Saved Starting and Stopping Locations
        LocationData startingLocation =
            await LocationData.getStartingPosition();
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
        await LocationData.saveDistanceAndDisplacement(
            this.totalDistance, this.totalCalculatedDistance);
        //Calculate total Route Duration by Subtracting the timestamps between the Last and First Saved Locations
        double mins = LocationData.calculateTime(
            savedLocations[0], savedLocations[savedLocations.length - 1]);

        await LocationData.saveDuration(mins);

        // Assign the Stats to their resepective variables to show
        setState(() {
          numLocations = savedLocations.length;
          totalTime = mins;
        });
        try {
          setState(() {
            double ef = (totalDistance / totalCalculatedDistance) * 100;
            efficencyPercentage = ef.round();
            // print("EffiPer: " +
            //     efficencyPercentage.toString() +
            //     " " +
            //     totalDistance.toString() +
            //     " " +
            //     totalCalculatedDistance.toString());
          });
        } catch (e) {
          setState(() {
            efficencyPercentage = 0;
          });
          // print("PeError: " + e.toString());
        }
        _startingLocation =
            GeoPoint(startingLocation.latitude, startingLocation.longitude);
        _destination =
            GeoPoint(stoppingLocation.latitude, stoppingLocation.longitude);
        await LocationData.clearProgress();
      } else {
        // Remove Saved AD Ending Times & Saved Paused Locations
        await LocationData.clearProgress();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          leading: Icon(null),
          title: Text("Path Recorded"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${this.pathname} ($numDropOffs)",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Text(
                          //   widget.startingLocation.length < 11
                          //       ? widget.startingLocation
                          //       : widget.startingLocation.substring(0, 11) +
                          //           "...",
                          //   style: TextStyle(
                          //       fontSize: deviceWidth * 0.08,
                          //       fontWeight: FontWeight.w400),
                          // ),
                          // Text(
                          //   "->",
                          //   style: TextStyle(
                          //       fontSize: deviceWidth * 0.08,
                          //       fontWeight: FontWeight.w600),
                          // ),
                          Text(
                            "Destination :",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.06,
                                fontWeight: FontWeight.w300),
                          ),
                          SizedBox(
                            width: deviceWidth * 0.05,
                          ),
                          Text(
                            widget.destination.length < 12
                                ? widget.destination
                                : widget.destination.substring(0, 12) + "...",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      Row(
                        children: [
                          SizedBox(
                            width: deviceWidth * 0.082,
                          ),
                          Text(
                            "Time Taken :",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w300),
                          ),
                          SizedBox(
                            width: deviceWidth * 0.03,
                          ),
                          Text(
                            this.totalTime.toStringAsFixed(2),
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w300),
                          )
                        ],
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      Column(
                        children: [
                          Text(
                            "Distance",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w300),
                          ),
                          Text(
                            "${(totalCalculatedDistance / 1000).toStringAsFixed(2)} KM",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w400),
                          ),
                          SizedBox(
                            height: deviceHeight * 0.01,
                          ),
                          Text(
                            "Displacement",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w300),
                          ),
                          Text(
                            "${(totalDistance / 1000).toStringAsFixed(2)} KM",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w400),
                          )
                        ],
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      Column(
                        children: [
                          Text(
                            "Route Efficiency",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                                fontWeight: FontWeight.w400),
                          ),
                          Text(
                            "${this.efficencyPercentage} %",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.25,
                                fontWeight: FontWeight.w300),
                          )
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                              flex: 6,
                              fit: FlexFit.tight,
                              child: Text(
                                "Ad Stop Range (m) :",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.06,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                              ),
                              controller: _adStopRange,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    int temp = int.parse(_adStopRange.text);
                                    temp += 50;
                                    _adStopRange.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp = int.parse(_adStopRange.text);
                                    if (temp >= 50) {
                                      temp -= 50;
                                      _adStopRange.text = temp.toString();
                                    }
                                  },
                                  iconSize: deviceWidth * 0.08,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                              flex: 6,
                              fit: FlexFit.tight,
                              child: Text(
                                "Boarding Range (m) :",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.06,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                              ),
                              controller: _boardingRange,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    int temp = int.parse(_boardingRange.text);
                                    temp += 15;
                                    _boardingRange.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp = int.parse(_boardingRange.text);
                                    if (temp > 15) {
                                      temp -= 15;
                                      _boardingRange.text = temp.toString();
                                    }
                                  },
                                  iconSize: deviceWidth * 0.08,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                              flex: 6,
                              fit: FlexFit.tight,
                              child: Text(
                                "Destination Range (m) :",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.06,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                              ),
                              controller: _destinationRange,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    int temp =
                                        int.parse(_destinationRange.text);
                                    temp += 15;
                                    _destinationRange.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp =
                                        int.parse(_destinationRange.text);
                                    if (temp > 15) {
                                      temp -= 15;
                                      _destinationRange.text = temp.toString();
                                    }
                                  },
                                  iconSize: deviceWidth * 0.08,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                              flex: 6,
                              fit: FlexFit.tight,
                              child: Text(
                                "Efficiency Range (%) :",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.06,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                              ),
                              controller: _efficiencyRange,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    int temp = int.parse(_efficiencyRange.text);
                                    temp++;
                                    _efficiencyRange.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp = int.parse(_efficiencyRange.text);
                                    if (temp > 0) {
                                      temp--;
                                      _efficiencyRange.text = temp.toString();
                                    }
                                  },
                                  iconSize: deviceWidth * 0.08,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(
                              flex: 6,
                              fit: FlexFit.tight,
                              child: Text(
                                "Initial Time (Second) :",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.06,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                              ),
                              controller: _initialTime,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: Column(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: () {
                                    int temp = int.parse(_initialTime.text);
                                    temp += 30;
                                    _initialTime.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp = int.parse(_initialTime.text);
                                    if (temp > 30) {
                                      temp -= 30;
                                      _initialTime.text = temp.toString();
                                    }
                                  },
                                  iconSize: deviceWidth * 0.08,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed: () async {
                                await LocationData.clearProgress();
                                Navigator.popUntil(
                                    context, ModalRoute.withName("PathPrep"));
                              },
                              child: Text(
                                "CANCEL",
                                style: TextStyle(fontSize: deviceWidth * 0.06),
                              )),
                          ElevatedButton(
                              onPressed: _startingLocation != null
                                  ? () {
                                      setState(() {
                                        loading = false;
                                      });
                                      Map<String, GeoPoint> pathDropOffData =
                                          {};
                                      pathDropOffData =
                                          changeLocDataToMap(savedDropOffs);
                                      DatabaseService()
                                          .createPath(
                                              int.parse(_initialTime.text),
                                              pathDropOffData,
                                              widget.cspID,
                                              widget.systemAccountId,
                                              22,
                                              // totalTime.toInt(),
                                              int.parse(_boardingRange.text),
                                              int.parse(_destinationRange.text),
                                              int.parse(_adStopRange.text),
                                              efficencyPercentage,
                                              int.parse(_efficiencyRange.text),
                                              pathname,
                                              _startingLocation,
                                              _destination,
                                              // widget.startingLocation,
                                              widget.destination,
                                              widget.superPathDocID)
                                          .then((value) async {
                                        setState(() {
                                          loading = true;
                                        });
                                        if (value) {
                                          await LocationData.clearProgress();
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                "Path failed to be Created"),
                                            backgroundColor: Colors.red,
                                          ));
                                        }
                                      }).catchError((err) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content:
                                              Text("Path failed to be Created"),
                                          backgroundColor: Colors.red,
                                        ));
                                      });
                                    }
                                  : null,
                              child: Text("SUBMIT",
                                  style:
                                      TextStyle(fontSize: deviceWidth * 0.06))),
                        ],
                      )
                    ],
                  ),
                )
              : Column(
                  children: [
                    SizedBox(
                      height: deviceHeight * 0.35,
                    ),
                    Loading()
                  ],
                ),
        ),
      ),
    );
  }
}
