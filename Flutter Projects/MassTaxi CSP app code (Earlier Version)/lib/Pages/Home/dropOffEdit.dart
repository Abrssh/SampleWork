import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csp_app/Pages/Home/paths.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/constant.dart';
import 'package:csp_app/Shared/loading.dart';
import 'package:flutter/material.dart';

class DropOffEdit extends StatefulWidget {
  final String dropOffName;
  final int pathIndex;
  final bool add;
  DropOffEdit({this.dropOffName, this.pathIndex, this.add});
  @override
  _DropOffEditState createState() => _DropOffEditState();
}

class _DropOffEditState extends State<DropOffEdit> {
  final _formKey = GlobalKey<FormState>();
  String dropOffName = "";
  double lattitude = 0, longitude = 0;

  bool loading = false;
  bool saved = false;

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              SizedBox(
                width: deviceWidth * 0.1,
              ),
              Text("Add/Edit Drop Off"),
            ],
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
              child: loading
                  ? Loading()
                  : Container(
                      padding: EdgeInsets.symmetric(
                          vertical: deviceHeight * 0.05,
                          horizontal: deviceWidth * 0.1),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SizedBox(
                              height: deviceHeight * 0.025,
                            ),
                            TextFormField(
                              initialValue:
                                  widget.add ? null : widget.dropOffName,
                              decoration: textInputDecoration.copyWith(
                                  hintText: "Drop Off Name"),
                              validator: (value) =>
                                  value.isEmpty ? "Enter Drop Off Name" : null,
                              onChanged: (value) {
                                setState(() {
                                  dropOffName = value;
                                });
                              },
                            ),
                            SizedBox(
                              height: deviceHeight * 0.025,
                            ),
                            TextFormField(
                              initialValue: widget.add || (!widget.add && saved)
                                  ? null
                                  : Paths
                                      .pathsRetrived[widget.pathIndex]
                                      .dropOffLocations[widget.dropOffName]
                                      .latitude
                                      .toString(),
                              decoration: textInputDecoration.copyWith(
                                  hintText: "Latitude"),
                              validator: (value) => (value.isEmpty ||
                                      double.tryParse(value) == null ||
                                      !(double.tryParse(value.toString()) >=
                                              -90 &&
                                          double.tryParse(value.toString()) <=
                                              90))
                                  ? "Enter a valid Lattitude"
                                  : null,
                              onChanged: (value) {
                                setState(() {
                                  if (double.tryParse(value) != null) {
                                    lattitude =
                                        double.tryParse(value.toString());
                                  }
                                });
                              },
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(
                              height: deviceHeight * 0.025,
                            ),
                            TextFormField(
                              initialValue: widget.add || (!widget.add && saved)
                                  ? null
                                  : Paths
                                      .pathsRetrived[widget.pathIndex]
                                      .dropOffLocations[widget.dropOffName]
                                      .longitude
                                      .toString(),
                              decoration: textInputDecoration.copyWith(
                                  hintText: "Longitude"),
                              validator: (value) => (value.isEmpty ||
                                      double.tryParse(value) == null ||
                                      !(double.tryParse(value.toString()) >=
                                              -180 &&
                                          double.tryParse(value.toString()) <=
                                              180))
                                  ? "Enter a valid Longitude"
                                  : null,
                              onChanged: (value) {
                                setState(() {
                                  if (double.tryParse(value) != null) {
                                    longitude =
                                        double.tryParse(value.toString());
                                  }
                                });
                              },
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(
                              height: deviceHeight * 0.015,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "CANCEL",
                                      style: TextStyle(
                                          fontSize: deviceWidth * 0.07),
                                    )),
                                ElevatedButton(
                                    onPressed: () {
                                      if (_formKey.currentState.validate() &&
                                          widget.add) {
                                        setState(() {
                                          loading = true;
                                        });
                                        Paths.pathsRetrived[widget.pathIndex]
                                                .dropOffLocations[dropOffName] =
                                            GeoPoint(lattitude, longitude);
                                        DatabaseService()
                                            .updateDropOff(
                                                Paths
                                                    .pathsRetrived[
                                                        widget.pathIndex]
                                                    .dropOffLocations,
                                                Paths
                                                    .pathsRetrived[
                                                        widget.pathIndex]
                                                    .docID)
                                            .then((value) {
                                          setState(() {
                                            loading = false;
                                          });
                                          if (value) {
                                            Navigator.pop(context);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Failed to Add drop off"),
                                              backgroundColor: Colors.red,
                                            ));
                                            Paths
                                                .pathsRetrived[widget.pathIndex]
                                                .dropOffLocations
                                                .remove(dropOffName);
                                          }
                                        });
                                      } else if (_formKey.currentState
                                              .validate() &&
                                          !widget.add) {
                                        setState(() {
                                          loading = true;
                                          saved = true;
                                        });
                                        GeoPoint dropOffLocL = Paths
                                                .pathsRetrived[widget.pathIndex]
                                                .dropOffLocations[
                                            widget.dropOffName];
                                        if (lattitude == 0) {
                                          lattitude = dropOffLocL.latitude;
                                        }
                                        if (longitude == 0) {
                                          longitude = dropOffLocL.longitude;
                                        }
                                        if (dropOffName == "") {
                                          dropOffName = widget.dropOffName;
                                        }

                                        Paths.pathsRetrived[widget.pathIndex]
                                            .dropOffLocations
                                            .remove(widget.dropOffName);

                                        Paths.pathsRetrived[widget.pathIndex]
                                                .dropOffLocations[dropOffName] =
                                            GeoPoint(lattitude, longitude);

                                        DatabaseService()
                                            .updateDropOff(
                                                Paths
                                                    .pathsRetrived[
                                                        widget.pathIndex]
                                                    .dropOffLocations,
                                                Paths
                                                    .pathsRetrived[
                                                        widget.pathIndex]
                                                    .docID)
                                            .then((value) {
                                          setState(() {
                                            loading = false;
                                          });
                                          if (value) {
                                            Navigator.pop(context);
                                          } else {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                              content: Text(
                                                  "Failed to update drop off"),
                                              backgroundColor: Colors.red,
                                            ));
                                            Paths
                                                .pathsRetrived[widget.pathIndex]
                                                .dropOffLocations
                                                .remove(dropOffName);
                                            Paths
                                                    .pathsRetrived[widget.pathIndex]
                                                    .dropOffLocations[
                                                widget
                                                    .dropOffName] = dropOffLocL;
                                            setState(() {
                                              saved = false;
                                            });
                                          }
                                        });
                                      }
                                    },
                                    child: Text(
                                      "SAVE",
                                      style: TextStyle(
                                          fontSize: deviceWidth * 0.07),
                                    )),
                              ],
                            )
                          ],
                        ),
                      ),
                    )),
        ));
  }
}
