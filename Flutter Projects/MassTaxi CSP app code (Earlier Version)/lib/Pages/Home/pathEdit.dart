import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csp_app/Classes/pathClass.dart';
import 'package:csp_app/Pages/Home/dropOffEdit.dart';
import 'package:csp_app/Pages/Home/paths.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/loading.dart';
import 'package:flutter/material.dart';

class EditPath extends StatefulWidget {
  final int pathIndex;
  EditPath({this.pathIndex});
  @override
  _EditPathState createState() => _EditPathState();
}

class _EditPathState extends State<EditPath> {
  TextEditingController _efficiencyRange = TextEditingController();
  TextEditingController _startingRange = TextEditingController();
  TextEditingController _endingRange = TextEditingController();
  TextEditingController _destinationBuffer = TextEditingController();

  List<String> dropOffKeys = [];

  PathClass previousPaths;

  Timer forStaticPaths;

  bool loading = false;

  @override
  void initState() {
    _efficiencyRange.text = Paths
        .pathsRetrived[widget.pathIndex].efficiencyAccuracyRange
        .toString();
    _destinationBuffer.text =
        Paths.pathsRetrived[widget.pathIndex].destinationBuffer.toString();
    _startingRange.text =
        Paths.pathsRetrived[widget.pathIndex].boardingRange.toString();
    _endingRange.text =
        Paths.pathsRetrived[widget.pathIndex].destinationRange.toString();
    Paths.pathsRetrived[widget.pathIndex].dropOffLocations
        .forEach((key, value) {
      dropOffKeys.add(key);
    });
    previousPaths = Paths.pathsRetrived[widget.pathIndex];
    forStaticPaths = Timer.periodic(Duration(seconds: 1), (timer) {
      if (previousPaths != Paths.pathsRetrived[widget.pathIndex]) {
        setState(() {
          dropOffKeys.clear();
          Paths.pathsRetrived[widget.pathIndex].dropOffLocations
              .forEach((key, value) {
            dropOffKeys.add(key);
          });
        });
        previousPaths = Paths.pathsRetrived[widget.pathIndex];
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    forStaticPaths.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;
    print("pathChan: " + Paths.pathsRetrived[widget.pathIndex].pathName);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text("Route Name : "),
            Text(Paths.pathsRetrived[widget.pathIndex].pathName.length < 14
                ? Paths.pathsRetrived[widget.pathIndex].pathName
                : Paths.pathsRetrived[widget.pathIndex].pathName
                        .substring(0, 14) +
                    "..."),
          ],
        ),
      ),
      body: Center(
        child: loading
            ? Loading()
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Flexible(
                              flex: 6,
                              fit: FlexFit.tight,
                              child: Text(
                                "Efficiency Range (%) :",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.07,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: true,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.08,
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
                                    }
                                    _efficiencyRange.text = temp.toString();
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
                                "Starting Range (m):",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.07,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: false,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                              ),
                              controller: _startingRange,
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
                                    int temp = int.parse(_startingRange.text);
                                    temp += 15;
                                    _startingRange.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp = int.parse(_startingRange.text);
                                    if (temp > 15) {
                                      temp -= 15;
                                    }
                                    _startingRange.text = temp.toString();
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
                                "Ending Range (m):",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.07,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: false,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                              ),
                              controller: _endingRange,
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
                                    int temp = int.parse(_endingRange.text);
                                    temp += 15;
                                    _endingRange.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp = int.parse(_endingRange.text);
                                    if (temp > 15) {
                                      temp -= 15;
                                    }
                                    _endingRange.text = temp.toString();
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
                                "Ad stop Range (m):",
                                style: TextStyle(
                                    fontSize: deviceWidth * 0.07,
                                    fontWeight: FontWeight.w300),
                              )),
                          Flexible(
                            flex: 2,
                            fit: FlexFit.tight,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              readOnly: false,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.08,
                              ),
                              controller: _destinationBuffer,
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
                                        int.parse(_destinationBuffer.text);
                                    temp += 50;
                                    _destinationBuffer.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () {
                                    int temp =
                                        int.parse(_destinationBuffer.text);
                                    if (temp > 0) {
                                      temp -= 50;
                                    }
                                    _destinationBuffer.text = temp.toString();
                                  },
                                  iconSize: deviceWidth * 0.08,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Drop Off Locations",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.07,
                                fontWeight: FontWeight.w400),
                          )
                        ],
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      Container(
                        height: deviceHeight * 0.2,
                        // color: Colors.amber,
                        child: SingleChildScrollView(
                          child: Container(
                            height: deviceHeight * 0.2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                    child: ListView.builder(
                                  itemCount: Paths
                                      .pathsRetrived[widget.pathIndex]
                                      .dropOffLocations
                                      .length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: deviceWidth,
                                      child: Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                dropOffKeys[index].length < 15
                                                    ? dropOffKeys[index]
                                                    : dropOffKeys[index]
                                                            .substring(0, 15) +
                                                        "...",
                                                style: TextStyle(
                                                    fontSize:
                                                        deviceWidth * 0.07,
                                                    fontWeight:
                                                        FontWeight.w300),
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                      icon: Icon(Icons.edit),
                                                      onPressed: () {
                                                        Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        DropOffEdit(
                                                                          add:
                                                                              false,
                                                                          dropOffName:
                                                                              dropOffKeys[index],
                                                                          pathIndex:
                                                                              widget.pathIndex,
                                                                        )));
                                                      }),
                                                  IconButton(
                                                      icon: Icon(Icons.delete),
                                                      onPressed: () {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                title: Text(
                                                                  "Are you sure you want to Delete this Drop Off Location ?",
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w400),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        GeoPoint
                                                                            dropLoc =
                                                                            Paths.pathsRetrived[widget.pathIndex].dropOffLocations[dropOffKeys[index]];
                                                                        String
                                                                            dropLocKey =
                                                                            dropOffKeys[index];
                                                                        Paths
                                                                            .pathsRetrived[widget.pathIndex]
                                                                            .dropOffLocations
                                                                            .remove(dropOffKeys[index]);
                                                                        DatabaseService()
                                                                            .updateDropOff(Paths.pathsRetrived[widget.pathIndex].dropOffLocations,
                                                                                Paths.pathsRetrived[widget.pathIndex].docID)
                                                                            .then((value) {
                                                                          if (value) {
                                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                              content: Text("Drop Off Location Deleted"),
                                                                              backgroundColor: Colors.green,
                                                                            ));
                                                                          } else {
                                                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                                              content: Text("Failed to delete Drop Off Location"),
                                                                              backgroundColor: Colors.red,
                                                                            ));
                                                                            Paths.pathsRetrived[widget.pathIndex].dropOffLocations[dropLocKey] =
                                                                                dropLoc;
                                                                          }
                                                                          Navigator.pop(
                                                                              context);
                                                                        });
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        "Yes",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                deviceWidth * 0.07),
                                                                      )),
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        "No",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                deviceWidth * 0.07),
                                                                      ))
                                                                ],
                                                              );
                                                            });
                                                      }),
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
                        ),
                      ),
                      SizedBox(
                        height: deviceHeight * 0.02,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => DropOffEdit(
                                              add: true,
                                              pathIndex: widget.pathIndex,
                                            )));
                              },
                              child: Text(
                                "ADD DROP OFF",
                                // style: TextStyle(fontSize: deviceWidth * 0.08),
                              )),
                          ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  loading = true;
                                });
                                DatabaseService()
                                    .savePathChanges(
                                        Paths.pathsRetrived[widget.pathIndex]
                                            .dropOffLocations,
                                        int.parse(_efficiencyRange.text),
                                        int.parse(_startingRange.text),
                                        int.parse(_endingRange.text),
                                        int.parse(_destinationBuffer.text),
                                        Paths.pathsRetrived[widget.pathIndex]
                                            .docID)
                                    .then((value) {
                                  setState(() {
                                    loading = false;
                                  });
                                  if (value) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content:
                                          Text("Changes saved Successfullly"),
                                      backgroundColor: Colors.green,
                                    ));
                                    Navigator.pop(context);
                                  } else {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text("Failed to save Changes"),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                });
                              },
                              child: Text("SAVE CHANGES")),
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
