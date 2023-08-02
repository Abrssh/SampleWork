import 'dart:async';

import 'package:csp_app/Classes/newPath.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/loading.dart';
import 'package:flutter/material.dart';

class NewPathReports extends StatefulWidget {
  final String systemAccountId;
  NewPathReports({this.systemAccountId});
  @override
  _NewPathReportsState createState() => _NewPathReportsState();
}

class _NewPathReportsState extends State<NewPathReports> {
  StreamSubscription _newPathSubscription;
  List<NewPathReport> newPathreports = [];

  bool loaded = false;

  @override
  void initState() {
    _newPathSubscription = DatabaseService()
        .newPathReports(widget.systemAccountId)
        .listen((event) {
      setState(() {
        newPathreports = event;
        if (!loaded) {
          loaded = true;
        }
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_newPathSubscription != null) {
      _newPathSubscription.cancel();
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
        title: Text("New Path Reports"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          height: deviceHeight * 0.9,
          child: Column(
            children: [
              (loaded)
                  ? Expanded(
                      child: ListView.builder(
                      itemCount: newPathreports.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            elevation: 5,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "Date :",
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.07,
                                                fontWeight: FontWeight.w400),
                                          ),
                                          SizedBox(
                                            width: deviceWidth * 0.02,
                                          ),
                                          Text(
                                            newPathreports[index].date,
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.06,
                                                fontWeight: FontWeight.w300),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "NEW",
                                        style: TextStyle(
                                            fontSize: deviceWidth * 0.1,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: deviceHeight * 0.01,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Nickname :",
                                        style: TextStyle(
                                            fontSize: deviceWidth * 0.055,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      SizedBox(
                                        width: deviceWidth * 0.02,
                                      ),
                                      Text(
                                        newPathreports[index].nickName.length <
                                                17
                                            ? newPathreports[index].nickName
                                            : newPathreports[index]
                                                    .nickName
                                                    .substring(0, 17) +
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
                                        "Starting Location :",
                                        style: TextStyle(
                                            fontSize: deviceWidth * 0.055,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      SizedBox(
                                        width: deviceWidth * 0.02,
                                      ),
                                      Text(
                                        newPathreports[index]
                                                    .startingLocation
                                                    .length <
                                                9
                                            ? newPathreports[index]
                                                .startingLocation
                                            : newPathreports[index]
                                                    .startingLocation
                                                    .substring(0, 9) +
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
                                        "Ending Location :",
                                        style: TextStyle(
                                            fontSize: deviceWidth * 0.055,
                                            fontWeight: FontWeight.w400),
                                      ),
                                      SizedBox(
                                        width: deviceWidth * 0.02,
                                      ),
                                      Text(
                                        newPathreports[index]
                                                    .endingLocation
                                                    .length <
                                                9
                                            ? newPathreports[index]
                                                .endingLocation
                                            : newPathreports[index]
                                                    .endingLocation
                                                    .substring(0, 9) +
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
                                    height: deviceHeight * 0.22,
                                    child: Column(
                                      children: [
                                        Text(
                                          "Additional Information about the Route",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.07,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          newPathreports[index]
                                                      .additionalInfo
                                                      .length <
                                                  130
                                              ? newPathreports[index]
                                                  .additionalInfo
                                              : newPathreports[index]
                                                      .startingLocation
                                                      .substring(0, 130) +
                                                  "...",
                                          maxLines: 5,
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: deviceHeight * 0.01,
                                  ),
                                  // Useful to know the paths you have attended
                                  // attended path report will only be shown to CSP
                                  // who attended it
                                  // Row(
                                  //   children: [
                                  //     Text(
                                  //       "Attended :",
                                  //       style: TextStyle(
                                  //           fontSize: deviceWidth * 0.07,
                                  //           fontWeight: FontWeight.w400),
                                  //     ),
                                  //     SizedBox(
                                  //       width: deviceWidth * 0.02,
                                  //     ),
                                  //     Icon(
                                  //       Icons.schedule,
                                  //       size: deviceWidth * 0.12,
                                  //       color: Colors.orange,
                                  //     )
                                  //   ],
                                  // ),
                                  Container(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Are you sure you want to mark this" +
                                                        " as Attended?"),
                                                actions: [
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        DatabaseService()
                                                            .markAsAttended(
                                                                newPathreports[
                                                                        index]
                                                                    .docID);
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("YES")),
                                                  ElevatedButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: Text("NO"))
                                                ],
                                              );
                                            });
                                      },
                                      child: Text(
                                        "Mark As Attended",
                                        style: TextStyle(
                                          fontSize: deviceWidth * 0.07,
                                        ),
                                      ),
                                    ),
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
    );
  }
}
