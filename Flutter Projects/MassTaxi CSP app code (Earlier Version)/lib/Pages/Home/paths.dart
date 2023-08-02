import 'dart:async';

import 'package:csp_app/Classes/csp.dart';
import 'package:csp_app/Classes/pathClass.dart';
import 'package:csp_app/Classes/systemAccount.dart';
import 'package:csp_app/Pages/Home/pathEdit.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/loading.dart';
import 'package:csp_app/Widgets/drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_ui/firebase_auth_ui.dart';
import 'package:flutter/material.dart';

class Paths extends StatefulWidget {
  final String phoneNumber;
  static List<PathClass> pathsRetrived = [];
  Paths({this.phoneNumber});
  @override
  _PathsState createState() => _PathsState();
}

class _PathsState extends State<Paths> {
  StreamSubscription _pathSubscription, _cspSubscription;
  Csp _cspAccount;
  bool loaded = false, bodyLoaded = false;

  // NEW
  SystemRequirementAccount _systemRequirementAccount;
  //

  Future<bool> logOut() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await FirebaseAuthUi.instance().logout();
    } else {
      return false;
    }
  }

  @override
  void initState() {
    DatabaseService().retrieveAccount(widget.phoneNumber).then((value) {
      _cspAccount = value;
      setState(() {
        loaded = true;
      });
      // NEW
      DatabaseService()
          .getSystemAccount(value.systemAccountId)
          .then((value) async {
        _systemRequirementAccount = value;
      });
      //
      _pathSubscription = DatabaseService()
          .getPaths(value.systemAccountId, value.cspID)
          .listen((event) {
        setState(() {
          if (!bodyLoaded) {
            bodyLoaded = true;
          }
          Paths.pathsRetrived = event;
        });
      });
      _cspSubscription =
          DatabaseService().getCspStatus(value.cspID).listen((event) {
        if (!event.status || event.disabled) {
          logOut().then((value) => Navigator.pop(context));
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_pathSubscription != null) {
      _pathSubscription.cancel();
    }
    if (_cspSubscription != null) {
      _cspSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;

    Future<bool> _onBackPressed() {
      return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                "Are you sure you want to Logout ?",
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      logOut().then((value) {
                        if (value) {
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text("Failed to Logout. Try Again."),
                            backgroundColor: Colors.red,
                          ));
                        }
                        Navigator.pop(context);
                      });
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
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Paths"),
          centerTitle: true,
          actions: [
            IconButton(
                icon: Icon(Icons.logout),
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                            "Are you sure you want to Logout ?",
                            style: TextStyle(fontWeight: FontWeight.w400),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  logOut().then((value) {
                                    if (value) {
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "Failed to Logout. Try Again."),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                    Navigator.pop(context);
                                  });
                                },
                                child: Text(
                                  "Yes",
                                  style:
                                      TextStyle(fontSize: deviceWidth * 0.07),
                                )),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "No",
                                  style:
                                      TextStyle(fontSize: deviceWidth * 0.07),
                                ))
                          ],
                        );
                      });
                })
          ],
        ),
        drawer: loaded
            ? MyDrawer(
                cspName: _cspAccount.name,
                cspIdendtifier: _cspAccount.identifier,
                systemAccountId: _cspAccount.systemAccountId,
                cspID: _cspAccount.cspID)
            : Drawer(),
        body: SingleChildScrollView(
          child: Container(
            height: deviceHeight * 0.88,
            child: Column(
              children: [
                bodyLoaded
                    ? Expanded(
                        child: ListView.builder(
                        itemCount: Paths.pathsRetrived.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Card(
                              elevation: 8,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       "Starting Location :",
                                    //       style: TextStyle(
                                    //           fontSize: deviceWidth * 0.065,
                                    //           fontWeight: FontWeight.w400),
                                    //     ),
                                    //     SizedBox(
                                    //       width: deviceWidth * 0.02,
                                    //     ),
                                    //     Text(
                                    //       Paths
                                    //                   .pathsRetrived[index]
                                    //                   .startingLocationName
                                    //                   .length <
                                    //               10
                                    //           ? Paths.pathsRetrived[index]
                                    //               .startingLocationName
                                    //           : Paths.pathsRetrived[index]
                                    //                   .startingLocationName
                                    //                   .substring(0, 10) +
                                    //               "...",
                                    //       style: TextStyle(
                                    //           fontSize: deviceWidth * 0.06,
                                    //           fontWeight: FontWeight.w300),
                                    //     ),
                                    //   ],
                                    // ),
                                    // SizedBox(
                                    //   height: deviceHeight * 0.006,
                                    // ),
                                    Row(
                                      children: [
                                        Text(
                                          // "Ending Location:",
                                          "Destination:",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          Paths.pathsRetrived[index]
                                                      .destinationName.length <
                                                  14
                                              ? Paths.pathsRetrived[index]
                                                  .destinationName
                                              : Paths.pathsRetrived[index]
                                                      .destinationName
                                                      .substring(0, 14) +
                                                  "...",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.055,
                                              fontWeight: FontWeight.w300),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: deviceHeight * 0.006,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Path Name:",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          Paths.pathsRetrived[index].pathName
                                                      .length <
                                                  14
                                              ? Paths
                                                  .pathsRetrived[index].pathName
                                              : Paths.pathsRetrived[index]
                                                      .pathName
                                                      .substring(0, 14) +
                                                  "...",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.055,
                                              fontWeight: FontWeight.w300),
                                        )
                                      ],
                                    ),
                                    SizedBox(
                                      height: deviceHeight * 0.006,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              "Time Span",
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.075,
                                                  fontWeight: FontWeight.w400),
                                            ),
                                            Text(
                                              Paths.pathsRetrived[index]
                                                      .timetaken
                                                      .toString() +
                                                  " Min",
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.065,
                                                  fontWeight: FontWeight.w300),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: deviceHeight * 0.006,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                            icon: Icon(Icons.edit),
                                            onPressed: () {
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditPath(
                                                            pathIndex: index,
                                                          )));
                                            },
                                            label: Text(
                                              "EDIT",
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.06),
                                            )),
                                        ElevatedButton.icon(
                                            label: Text(
                                              "Delete",
                                              style: TextStyle(
                                                  fontSize: deviceWidth * 0.06),
                                            ),
                                            icon: Icon(
                                              Icons.delete,
                                            ),
                                            onPressed: () {
                                              DateTime now =
                                                  DateTime.now().toLocal();
                                              bool timeZoneSimilar =
                                                  _systemRequirementAccount
                                                              .timeZoneOffset ==
                                                          now.timeZoneOffset
                                                              .inMinutes
                                                      ? true
                                                      : false;
                                              bool allowedTime = false;
                                              DateTime endTime = DateTime
                                                  .fromMillisecondsSinceEpoch(
                                                      _systemRequirementAccount
                                                              .allowedEndingTime
                                                              .millisecondsSinceEpoch +
                                                          // -1 added to protect from endTime.hour becoming zero if system account end time is set to 10:00:00
                                                          (2 * 60 * 60 * 1000) -
                                                          1);
                                              // print("now: " +
                                              //     now.hour.toString() +
                                              //     " " +
                                              //     endTime.hour.toString());
                                              print(endTime);
                                              if (now.hour >= endTime.hour ||
                                                  now.hour < 6) {
                                                allowedTime = true;
                                              } else {
                                                allowedTime = false;
                                              }

                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: allowedTime &&
                                                              timeZoneSimilar
                                                          ? Text(
                                                              "Are you sure you want to Delete the Path ?",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400),
                                                            )
                                                          : Text(
                                                              "Not allowed to delete at this time. Or check if the TimeZone of your phone is Correct.",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400),
                                                            ),
                                                      actions: [
                                                        (allowedTime &&
                                                                timeZoneSimilar)
                                                            ? TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                  DatabaseService().deletePath(Paths
                                                                      .pathsRetrived[
                                                                          index]
                                                                      .docID);
                                                                },
                                                                child: Text(
                                                                  "Yes",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          deviceWidth *
                                                                              0.07),
                                                                ))
                                                            : null,
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: Text(
                                                              (allowedTime &&
                                                                      timeZoneSimilar)
                                                                  ? "No"
                                                                  : "OK",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      deviceWidth *
                                                                          0.07),
                                                            ))
                                                      ],
                                                    );
                                                  });
                                            })
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ))
                    : Column(
                        children: [
                          SizedBox(
                            height: deviceHeight * 0.35,
                          ),
                          Loading()
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
