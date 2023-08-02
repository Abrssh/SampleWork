import 'dart:async';

import 'package:csp_app/Classes/bookedSpots.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/loading.dart';
import 'package:flutter/material.dart';

class BookedSpots extends StatefulWidget {
  final String cspID;
  final String systemAccountId;
  BookedSpots({this.cspID, this.systemAccountId});
  @override
  _BookedSpotsState createState() => _BookedSpotsState();
}

class _BookedSpotsState extends State<BookedSpots> {
  StreamSubscription _personalBookedspot, _unattendedBookedSpot;
  List<BookedSpot> personal = [], unattended = [], combined = [];

  bool loaded = false;

  @override
  void initState() {
    _personalBookedspot = DatabaseService()
        .personalBookedSpot(widget.cspID, widget.systemAccountId)
        .listen((event) {
      setState(() {
        personal.clear();
        personal.addAll(event);
        combined.clear();
        combined.addAll(personal + unattended);
        if (!loaded) {
          loaded = true;
        }
      });
    });
    _unattendedBookedSpot = DatabaseService()
        .unattendedBookedSpots(widget.systemAccountId)
        .listen((event) {
      setState(() {
        unattended.clear();
        unattended.addAll(event);
        combined.clear();
        combined.addAll(personal + unattended);
        if (!loaded) {
          loaded = true;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_personalBookedspot != null) {
      _personalBookedspot.cancel();
    }
    if (_unattendedBookedSpot != null) {
      _unattendedBookedSpot.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;
    return Scaffold(
      appBar: AppBar(
        title: Text("Booked Spots"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          height: deviceHeight * 0.9,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              (loaded)
                  ? Expanded(
                      child: ListView.builder(
                        itemCount: combined.length,
                        itemBuilder: (context, index) {
                          List<String> mainRoutes = combined[index].mainRoutes;
                          String mainRoutesCombined = "";
                          bool first = false;
                          mainRoutes.forEach((element) {
                            if (!first) {
                              first = true;
                              mainRoutesCombined += element;
                            } else {
                              mainRoutesCombined += ", " + element;
                            }
                          });
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 5,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "Name :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.05,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          combined[index].name.length < 18
                                              ? combined[index].name
                                              : combined[index]
                                                      .name
                                                      .substring(0, 18) +
                                                  "...",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
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
                                          "Plate Number :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.05,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          combined[index].plateNumber,
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
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
                                          "Phone Number :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.05,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          combined[index].phoneNumber,
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
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
                                          "Phone Model :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.05,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        Text(
                                          combined[index].phoneModel.length < 15
                                              ? combined[index].phoneModel
                                              : combined[index]
                                                      .phoneModel
                                                      .substring(0, 15) +
                                                  "...",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: deviceHeight * 0.008,
                                    ),
                                    Container(
                                      height: deviceHeight * 0.14,
                                      child: Column(
                                        children: [
                                          Text(
                                            "Main Routes :",
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.05,
                                                fontWeight: FontWeight.w400),
                                          ),
                                          SizedBox(
                                            width: deviceWidth * 0.02,
                                          ),
                                          Text(
                                            mainRoutesCombined,
                                            maxLines: 5,
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.06,
                                                fontWeight: FontWeight.w300),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        ElevatedButton(
                                          onPressed: combined[index].scheduled
                                              ? () {
                                                  // unschedule
                                                  DatabaseService()
                                                      .unScheduleSpot(
                                                          widget.cspID,
                                                          combined[index]
                                                              .docID);
                                                }
                                              : () {
                                                  // schedule
                                                  DatabaseService()
                                                      .scheduleSpot(
                                                          widget.cspID,
                                                          combined[index]
                                                              .docID);
                                                },
                                          child: combined[index].scheduled
                                              ? Text("UNSCHEDULE")
                                              : Text("SCHEDULE"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                        "Are you sure you want to mark this" +
                                                            " as Registered?"),
                                                    actions: [
                                                      ElevatedButton(
                                                          onPressed: () {
                                                            DatabaseService()
                                                                .markBookedSpotAsRegistered(
                                                                    combined[
                                                                            index]
                                                                        .docID);
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text("YES")),
                                                      ElevatedButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text("NO"))
                                                    ],
                                                  );
                                                });
                                          },
                                          child: Text("Mark as Registered"),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Loading()
            ],
          ),
        ),
      ),
    );
  }
}
