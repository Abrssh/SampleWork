import 'dart:io';
import 'dart:math';

import 'package:audio_record/Classes/camera_data.dart';
import 'package:audio_record/Models/trip.dart';
import 'package:audio_record/Service/cloudStorageServ.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class Trips extends StatefulWidget {
  final String driverDocID, systemAccountID;
  final int allowedToServe;
  Trips({this.driverDocID, this.allowedToServe, this.systemAccountID});
  @override
  _TripsState createState() => _TripsState();
}

class _TripsState extends State<Trips> {
  bool loaded = false;
  List<TripModel> _trips = [];
  int totalApprovedRoute = 0,
      weeklyApprovedRoute = 0,
      weeklyTotalRoute = 0,
      weeklyfailedRoute = 0;

  @override
  void initState() {
    DatabaseService().getTrips(widget.driverDocID).then((value) {
      setState(() {
        if (value.isNotEmpty) {
          totalApprovedRoute = value[0].totalRoutes[0];
          weeklyTotalRoute =
              value[0].weeklyRoutes[0] + value[0].weeklyRoutes[1];
          weeklyApprovedRoute = value[0].weeklyRoutes[0];
          weeklyfailedRoute = value[0].weeklyRoutes[1];
        }
        _trips = value;
        loaded = true;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // print("allow: " + widget.allowedToServe.toString());
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: deviceWidth * 0.23,
            ),
            Text("Trips")
          ],
        ),
      ),
      body: loaded
          ? Column(
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  color: Colors.blue[100],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            height: deviceHeight * 0.015,
                          ),
                          Row(
                            children: [
                              Text(
                                "Total Approved Routes:",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.05,
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(
                                width: deviceWidth * 0.01,
                              ),
                              Text(
                                totalApprovedRoute < 1000000000000
                                    ? totalApprovedRoute.toString()
                                    : totalApprovedRoute
                                        .toStringAsExponential(8),
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.05,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: deviceHeight * 0.01,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Approved Routes(Weekly):",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.05,
                                    fontWeight: FontWeight.w400),
                              ),
                              SizedBox(
                                width: deviceWidth * 0.01,
                              ),
                              Text(
                                weeklyApprovedRoute < 10000
                                    ? weeklyApprovedRoute.toString()
                                    : weeklyApprovedRoute
                                        .toStringAsExponential(1),
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.07,
                                    fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: deviceHeight * 0.01,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    "Failed Route (Weekly)",
                                    style: TextStyle(
                                        fontSize: deviceWidth * 0.04,
                                        fontWeight: FontWeight.w300),
                                  ),
                                  SizedBox(
                                    height: deviceHeight * 0.01,
                                  ),
                                  Text(
                                    weeklyfailedRoute < 100000
                                        ? weeklyfailedRoute.toString()
                                        : weeklyfailedRoute
                                            .toStringAsExponential(2),
                                    style: TextStyle(
                                        fontSize: deviceWidth * 0.055,
                                        fontWeight: FontWeight.w300),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: deviceWidth * 0.05,
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Total Route (Weekly)",
                                    style: TextStyle(
                                        fontSize: deviceWidth * 0.04,
                                        fontWeight: FontWeight.w300),
                                  ),
                                  SizedBox(
                                    height: deviceHeight * 0.01,
                                  ),
                                  Text(
                                    weeklyTotalRoute < 100000
                                        ? weeklyTotalRoute.toString()
                                        : weeklyTotalRoute
                                            .toStringAsExponential(2),
                                    style: TextStyle(
                                        fontSize: deviceWidth * 0.055,
                                        fontWeight: FontWeight.w300),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: deviceHeight * 0.02,
                ),
                Text(
                  "ROUTES",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.08,
                      fontWeight: FontWeight.bold),
                ),
                SingleChildScrollView(
                  child: Container(
                    height: deviceHeight * 0.628,
                    // color: Colors.amber,
                    child: Column(
                      children: [
                        Expanded(
                            child: ListView.builder(
                          itemCount: _trips.length,
                          itemBuilder: (context, index) {
                            double profit = _trips[index].profit;
                            double availableProfit =
                                _trips[index].availableProfit;
                            IconData statusIcon;
                            Color statusColor;
                            if (_trips[index].imageStatus == 0) {
                              statusIcon = Icons.pause;
                              statusColor = Colors.orange;
                            } else if (_trips[index].imageStatus == 1) {
                              statusIcon = Icons.done;
                              statusColor = Colors.green;
                            } else {
                              statusIcon = Icons.clear;
                              statusColor = Colors.red;
                            }
                            return Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Card(
                                elevation: 5,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10.0, horizontal: 10),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _trips[index].pathName.length < 16
                                                ? _trips[index].pathName
                                                : _trips[index]
                                                        .pathName
                                                        .substring(0, 15) +
                                                    "...",
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.065,
                                                fontWeight: FontWeight.w400),
                                          ),
                                          Text(
                                            _trips[index].date,
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.065,
                                                fontWeight: FontWeight.w400),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: deviceHeight * 0.015,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                  _trips[index]
                                                          .adServed
                                                          .toString() +
                                                      " / " +
                                                      _trips[index]
                                                          .numberOfAvailableAds
                                                          .toString(),
                                                  style: TextStyle(
                                                      fontSize:
                                                          deviceWidth * 0.05,
                                                      fontWeight:
                                                          FontWeight.w300)),
                                              Text("Ads Served",
                                                  style: TextStyle(
                                                      fontSize:
                                                          deviceWidth * 0.05,
                                                      fontWeight:
                                                          FontWeight.w400)),
                                            ],
                                          ),
                                          Container(
                                            color: Colors.grey[100],
                                            child: IconButton(
                                                icon: Icon(
                                                  statusIcon,
                                                  color: statusColor,
                                                ),
                                                onPressed: null),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: deviceHeight * 0.02,
                                      ),
                                      Row(
                                        children: [
                                          Text("Profit: ",
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.05,
                                                  fontWeight: FontWeight.w400)),
                                          Text(
                                              profit < 10000
                                                  ? profit.toStringAsFixed(2)
                                                  : profit
                                                      .toStringAsExponential(1),
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.05,
                                                  fontWeight: FontWeight.w300)),
                                          Text(" / ",
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.05,
                                                  fontWeight: FontWeight.w300)),
                                          Text(
                                              availableProfit < 10000
                                                  ? availableProfit
                                                      .toStringAsFixed(2)
                                                  : availableProfit
                                                      .toStringAsExponential(1),
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.05,
                                                  fontWeight: FontWeight.w300)),
                                          Text(" \$",
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.05,
                                                  fontWeight: FontWeight.w300)),
                                        ],
                                      ),
                                      SizedBox(
                                        height: deviceHeight * 0.02,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            children: [
                                              Text("Started:",
                                                  style: TextStyle(
                                                      fontSize:
                                                          deviceWidth * 0.04,
                                                      fontWeight:
                                                          FontWeight.w400)),
                                              Text(_trips[index].startTime,
                                                  style: TextStyle(
                                                      fontSize:
                                                          deviceWidth * 0.055,
                                                      fontWeight:
                                                          FontWeight.w300)),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text("Finished :",
                                                  style: TextStyle(
                                                      fontSize:
                                                          deviceWidth * 0.04,
                                                      fontWeight:
                                                          FontWeight.w400)),
                                              Text(_trips[index].endTime,
                                                  style: TextStyle(
                                                      fontSize:
                                                          deviceWidth * 0.055,
                                                      fontWeight:
                                                          FontWeight.w300)),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ))
                      ],
                    ),
                  ),
                )
              ],
            )
          : Center(
              child: Loading(),
            ),
      floatingActionButton: widget.allowedToServe != 2
          ? FloatingActionButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          "Once image is uploaded you can't take routes for"
                          " the day anymore. Are you sure you want to continue?",
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                setState(() {
                                  loaded = false;
                                });
                                List<String> imageFilePaths =
                                    await CameraData.getImages();
                                // because the first time the app is opened
                                // imageFilePaths will be null
                                if (imageFilePaths != null) {
                                  if (imageFilePaths.isNotEmpty) {
                                    int routesTaken = await DatabaseService()
                                        .routesTakenForTheDay(
                                            DateTime.now(),
                                            widget.driverDocID,
                                            widget.systemAccountID);
                                    // print("Route taken: " +
                                    //     routesTaken.toString() +
                                    //     " Images: " +
                                    //     imageFilePaths.length.toString());
                                    if (imageFilePaths.length >= routesTaken) {
                                      int randomNumber = Random()
                                          .nextInt(imageFilePaths.length);
                                      // print("rand: " +
                                      //     randomNumber.toString() +
                                      //     " LENG: " +
                                      //     imageFilePaths.length.toString());
                                      CloudStorageService()
                                          .uploadImage(
                                              File(
                                                  imageFilePaths[randomNumber]),
                                              "imageControl")
                                          .then((imageUrl) async {
                                        if (imageUrl == "f") {
                                          setState(() {
                                            loaded = true;
                                          });
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content:
                                                Text("Image failed to Upload."),
                                            backgroundColor: Colors.red,
                                          ));
                                        } else {
                                          DatabaseService()
                                              .updateDailyStatus(
                                                  widget.driverDocID, imageUrl)
                                              .then((value) async {
                                            if (value) {
                                              await CameraData
                                                  .deleteAllImages();
                                              setState(() {
                                                loaded = true;
                                              });
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                    "Daily Status Updated Successfully"),
                                                backgroundColor: Colors.green,
                                              ));
                                            } else {
                                              await CloudStorageService()
                                                  .deleteFile(imageUrl);
                                              setState(() {
                                                loaded = true;
                                              });
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                content: Text(
                                                    "Daily Status Failed to Update."),
                                                backgroundColor: Colors.red,
                                              ));
                                            }
                                          });
                                        }
                                      });
                                    } else {
                                      setState(() {
                                        loaded = true;
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "Your timeZone is not set to default or you have accidentaly cleared your cache."),
                                        backgroundColor: Colors.orange,
                                      ));
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    setState(() {
                                      loaded = true;
                                    });
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          "No trips taken toaday or today's image is already uploaded."),
                                      backgroundColor: Colors.orange,
                                    ));
                                    Navigator.pop(context);
                                  }
                                } else {
                                  setState(() {
                                    loaded = true;
                                  });
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "No trips taken toaday or today's image is already uploaded."),
                                    backgroundColor: Colors.orange,
                                  ));
                                  Navigator.pop(context);
                                }
                              },
                              child: Text(
                                "Yes",
                                style: TextStyle(fontSize: deviceWidth * 0.07),
                              )),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "No",
                                style: TextStyle(fontSize: deviceWidth * 0.07),
                              ))
                        ],
                      );
                    });
              },
              child: Icon(Icons.file_upload),
            )
          : null,
    );
  }
}
