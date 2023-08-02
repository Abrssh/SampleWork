import 'dart:async';

import 'package:csp_app/Classes/fixClaim.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/loading.dart';
import 'package:flutter/material.dart';

class ReportedIssues extends StatefulWidget {
  final String systemAccountId;
  final String cspID;
  ReportedIssues({this.systemAccountId, this.cspID});
  @override
  _ReportedIssuesState createState() => _ReportedIssuesState();
}

class _ReportedIssuesState extends State<ReportedIssues> {
  StreamSubscription _personalfixClaimSubscription,
      _unScheduledFixClaimSubscription;
  List<FixClaim> personalfixClaims = [],
      unScheduledFixClaims = [],
      combined = [];

  bool loaded = false;

  @override
  void initState() {
    _personalfixClaimSubscription = DatabaseService()
        .personalScheduledfixClaims(widget.systemAccountId, widget.cspID)
        .listen((event) {
      setState(() {
        if (!loaded) {
          loaded = true;
        }
        personalfixClaims.clear();
        personalfixClaims.addAll(event);
        combined.clear();
        combined.addAll(personalfixClaims + unScheduledFixClaims);
      });
    });
    _unScheduledFixClaimSubscription = DatabaseService()
        .unScheduledfixClaims(widget.systemAccountId)
        .listen((event) {
      // print("FixCl: " + event.length.toString());
      setState(() {
        if (!loaded) {
          loaded = true;
        }
        unScheduledFixClaims.clear();
        unScheduledFixClaims.addAll(event);
        combined.clear();
        combined.addAll(personalfixClaims + unScheduledFixClaims);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    if (_personalfixClaimSubscription != null) {
      _personalfixClaimSubscription.cancel();
    }
    if (_unScheduledFixClaimSubscription != null) {
      _unScheduledFixClaimSubscription.cancel();
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
          title: Text("Reported Issues"),
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
                        itemCount: combined.length,
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
                                      children: [
                                        Text(
                                          "Plate Number :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          combined[index].plateNumber.length <
                                                  12
                                              ? combined[index].plateNumber
                                              : combined[index]
                                                      .plateNumber
                                                      .substring(0, 12) +
                                                  "...",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w300),
                                        ), // last two can be used
                                        // identify the Region and its main number
                                        // which is used to know if its government,
                                        // private,e.t.c., vehicle.
                                      ],
                                    ),
                                    SizedBox(
                                      height: deviceHeight * 0.01,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Reported Date :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          combined[index].createdDate,
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
                                              fontSize: deviceWidth * 0.06,
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
                                      height: deviceHeight * 0.008,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Type :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          combined[index].type,
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w300),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: deviceHeight * 0.008,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Priority :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Text(
                                          combined[index].urgent
                                              ? "Urgent"
                                              : "Non-Urgent",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.bold,
                                              color: combined[index].urgent
                                                  ? Colors.red
                                                  : Colors.orange),
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Scheduled :",
                                          style: TextStyle(
                                              fontSize: deviceWidth * 0.06,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        SizedBox(
                                          width: deviceWidth * 0.02,
                                        ),
                                        Icon(
                                          combined[index].scheduled
                                              ? Icons.done
                                              : Icons.schedule,
                                          size: deviceWidth * 0.12,
                                          color: combined[index].scheduled
                                              ? Colors.green
                                              : Colors.orange,
                                        )
                                      ],
                                    ),
                                    Container(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                          onPressed: combined[index].scheduled
                                              ? () {
                                                  // unschedule
                                                  DatabaseService()
                                                      .unScheduleFixClaim(
                                                    combined[index].docID,
                                                  );
                                                }
                                              : () {
                                                  // schedule
                                                  DatabaseService()
                                                      .scheduleFixClaim(
                                                          combined[index].docID,
                                                          widget.cspID);
                                                },
                                          child: Text(
                                            combined[index].scheduled
                                                ? "UNSCHEDULE"
                                                : "SCHEDULE",
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.07),
                                          )),
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
        ));
  }
}
