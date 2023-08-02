import 'package:audio_record/Models/penality.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class Penalities extends StatefulWidget {
  final String driverDocID;
  Penalities({this.driverDocID});
  @override
  _PenalitiesState createState() => _PenalitiesState();
}

class _PenalitiesState extends State<Penalities> {
  bool loaded = false, penaltyExist = false;
  List<PenalityModel> _penalities = [];
  @override
  void initState() {
    DatabaseService().getPenalities(widget.driverDocID).then((value) {
      setState(() {
        if (value.isNotEmpty) {
          penaltyExist = true;
        }
        _penalities = value;
        loaded = true;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    return Scaffold(
        appBar: AppBar(
          title: Text("Penalities"),
          centerTitle: true,
        ),
        body: loaded
            ? penaltyExist
                ? SingleChildScrollView(
                    child: Container(
                      height: deviceHeight * 0.88,
                      child: Column(
                        children: [
                          Expanded(
                              child: ListView.builder(
                            itemCount: _penalities.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Card(
                                  elevation: 5,
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text("Type:",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.08,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                            Text(_penalities[index].type,
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.08,
                                                    fontWeight:
                                                        FontWeight.w300)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text("Description",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.06,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                          ],
                                        ),
                                        Text(_penalities[index].description,
                                            style: TextStyle(
                                                fontSize: deviceWidth * 0.055,
                                                fontWeight: FontWeight.w300)),
                                        Row(
                                          children: [
                                            Text("Suspension Length:",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.06,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                            SizedBox(
                                              width: deviceWidth * 0.02,
                                            ),
                                            Text(
                                                _penalities[index]
                                                        .suspensionLength
                                                        .toString() +
                                                    " Days",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.06,
                                                    fontWeight:
                                                        FontWeight.w300))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("Date of Suspension:",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.06,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                            SizedBox(
                                              width: deviceWidth * 0.02,
                                            ),
                                            Text(
                                                _penalities[index]
                                                    .suspensionDate,
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.06,
                                                    fontWeight:
                                                        FontWeight.w300))
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Text("Return Date:",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.06,
                                                    fontWeight:
                                                        FontWeight.w400)),
                                            SizedBox(
                                              width: deviceWidth * 0.02,
                                            ),
                                            Text(_penalities[index].returnDate,
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.06,
                                                    fontWeight:
                                                        FontWeight.w300)),
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
                : Center(
                    child: Text(
                      "You Have No Penalities!",
                      style: TextStyle(fontSize: deviceWidth * 0.08),
                    ),
                  )
            : Center(child: Loading()));
  }
}
