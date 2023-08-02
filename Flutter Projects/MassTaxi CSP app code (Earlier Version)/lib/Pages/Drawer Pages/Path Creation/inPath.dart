import 'package:csp_app/Classes/location_data.dart';
import 'package:csp_app/Pages/Drawer%20Pages/Path%20Creation/pathEnd.dart';
import 'package:csp_app/Shared/constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_location/flutter_background_location.dart';

class InPath extends StatefulWidget {
  final String systemAccountId,
      superPathDocID,
      // startingLocation,
      destination,
      cspID;
  InPath(
      {this.systemAccountId,
      this.superPathDocID,
      this.cspID,
      // this.startingLocation,
      this.destination});
  @override
  _InPathState createState() => _InPathState();
}

class _InPathState extends State<InPath> {
  LocationData nft;
  String dropoffname = '';
  String pathname = '';
  int numofDropOffs = 0;
  @override
  void initState() {
    // Starts Location Service
    FlutterBackgroundLocation.startLocationService();

    FlutterBackgroundLocation.getLocationUpdates((location) {
      setState(() {
        this.nft = LocationData.withAccuracy(
            latitude: location.latitude,
            longitude: location.longitude,
            speed: location.speed,
            accuracy: location.accuracy);
      });
      LocationData.saveProgress(nft).then((value) {});
    });

    LocationData.getPathName().then((value) {
      setState(() {
        pathname = value;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    // Dispose the Listener and Timer
    FlutterBackgroundLocation.stopLocationService();
    super.dispose();
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
          title: Row(
            children: [
              SizedBox(
                width: deviceWidth * 0.11,
              ),
              Text("Path Recording...")
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Column(
                  children: [
                    Text(
                      this.pathname,
                      style: TextStyle(
                          fontSize: deviceWidth * 0.1,
                          fontWeight: FontWeight.w300),
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          "Destination",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.08,
                              fontWeight: FontWeight.w600),
                        ),
                        // Text(
                        //   widget.startingLocation.length < 20
                        //       ? widget.startingLocation
                        //       : widget.startingLocation.substring(0, 20) +
                        //           "...",
                        //   style: TextStyle(
                        //       fontSize: deviceWidth * 0.08,
                        //       fontWeight: FontWeight.w400),
                        // ),
                        // SizedBox(
                        //   height: deviceHeight * 0.02,
                        // ),
                        // Text(
                        //   "TO",
                        //   style: TextStyle(
                        //       fontSize: deviceWidth * 0.1,
                        //       fontWeight: FontWeight.w300),
                        // ),
                        // SizedBox(
                        //   height: deviceHeight * 0.02,
                        // ),
                        Text(
                          widget.destination.length < 35
                              ? widget.destination
                              : widget.destination.substring(0, 35) + "...",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.1,
                              fontWeight: FontWeight.w300),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.01,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Accuracy :",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.06,
                                fontWeight: FontWeight.w300)),
                        SizedBox(
                          width: deviceWidth * 0.018,
                        ),
                        Text(
                            nft != null ? nft.accuracy.toStringAsFixed(2) : '-',
                            style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                                fontWeight: FontWeight.w300))
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Drop Offs :",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.06,
                                fontWeight: FontWeight.w300)),
                        SizedBox(
                          width: deviceWidth * 0.018,
                        ),
                        Text(this.numofDropOffs.toString(),
                            style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                                fontWeight: FontWeight.w300))
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: deviceHeight * 0.06,
                ),
                Column(
                  children: [
                    Container(
                      width: deviceWidth * 0.8,
                      child: TextFormField(
                        decoration: textInputDecoration.copyWith(
                            hintText: "Drop Off Name"),

                        // validator: (value) => value.isEmpty ? "Enter Drop Off name" : null,
                        onChanged: (value) {
                          setState(() {
                            dropoffname = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      height: deviceHeight * 0.015,
                    ),
                    ElevatedButton(
                        onPressed: this.dropoffname.length >= 4
                            ? () async {
                                nft.name = this.dropoffname;
                                await LocationData.saveDropOff(nft)
                                    .then((value) => {
                                          setState(() {
                                            numofDropOffs = numofDropOffs + 1;
                                            dropoffname = '';
                                          })
                                        });
                              }
                            : null,
                        child: Text(
                          "Save As A Drop Off",
                          style: TextStyle(fontSize: deviceWidth * 0.08),
                        )),
                  ],
                ),
                SizedBox(
                  height: deviceHeight * 0.15,
                ),
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        LocationData.clearProgress();
                        Navigator.pop(context);
                      },
                      child: Text(
                        "CANCEL",
                        style: TextStyle(fontSize: deviceWidth * 0.09),
                      ),
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        FlutterBackgroundLocation.stopLocationService();
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PathDone(
                                      systemAccountId: widget.systemAccountId,
                                      superPathDocID: widget.superPathDocID,
                                      cspID: widget.cspID,
                                      // startingLocation: widget.startingLocation,
                                      destination: widget.destination,
                                    )));
                      },
                      child: Text(
                        "END ROUTE",
                        style: TextStyle(fontSize: deviceWidth * 0.09),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
