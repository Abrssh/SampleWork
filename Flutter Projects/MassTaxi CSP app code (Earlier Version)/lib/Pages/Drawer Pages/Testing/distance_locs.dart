import 'package:csp_app/Classes/location_data.dart';
import 'package:csp_app/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DistanceLocs extends StatefulWidget {
  final LocationData currentLocation;

  const DistanceLocs({Key key, this.currentLocation}) : super(key: key);
  @override
  _DistanceLocsState createState() => _DistanceLocsState();
}

class _DistanceLocsState extends State<DistanceLocs> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _startingController = TextEditingController();
  final TextEditingController _endingController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();
  List<LocationData> locations = [];
  bool addLoc = false;
  bool locsLoad = false;
  bool listenLoc = true;

  void showSnack({String message, var context, int type = 1}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: type == 1 ? Colors.black : Colors.red,
      duration: Duration(seconds: 2),
    ));
  }

  @override
  void initState() {
    super.initState();
    _startingController.text = LocationData.startingRange.toString();
    _endingController.text = LocationData.endingRange.toString();
    getLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('App Settings'),
        ),
        body: SafeArea(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
            child: SingleChildScrollView(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    !addLoc
                        ? Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Starting Range",
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    TextFormField(
                                      maxLines: 1,
                                      keyboardType: TextInputType.text,
                                      controller: _startingController,
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return "The Starting Range cannot be empty";
                                        }
                                        return null;
                                      },
                                    )
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 25,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Ending Range",
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    TextFormField(
                                      maxLines: 1,
                                      keyboardType: TextInputType.text,
                                      controller: _endingController,
                                      validator: (value) {
                                        if (value.isEmpty) {
                                          return "The Ending Range cannot be empty";
                                        }
                                        return null;
                                      },
                                    )
                                  ],
                                ),
                              ),
                              // SizedBox(
                              //   width: 25,
                              // ),
                              // Expanded(
                              //   child: Column(
                              //     crossAxisAlignment: CrossAxisAlignment.start,
                              //     children: [
                              //       Text(
                              //         "Accuracy Limit",
                              //         style: TextStyle(fontSize: 10),
                              //       ),
                              //       TextFormField(
                              //         maxLines: 1,
                              //         keyboardType: TextInputType.text,
                              //         controller: _startingController,
                              //         validator: (value) {
                              //           if (value.isEmpty) {
                              //             return "The Starting Range cannot be empty";
                              //           }
                              //           return null;
                              //         },
                              //       )
                              //     ],
                              //   ),
                              // ),
                            ],
                          )
                        : SizedBox(
                            height: 0,
                          ),
                    !addLoc
                        ? RaisedButton(
                            color: Colors.black,
                            onPressed: () async {
                              try {
                                LocationData.setRanges(
                                        startingRange: double.parse(
                                            _startingController.text),
                                        endingRange: double.parse(
                                            _endingController.text))
                                    .then((value) {
                                  if (value) {
                                    showSnack(
                                        message: "Ranges are Saved",
                                        context: context);
                                  } else {
                                    showSnack(
                                        message: "Ranges are Not Saved",
                                        context: context,
                                        type: 0);
                                  }
                                });
                              } catch (e) {
                                showSnack(
                                    message:
                                        "Ranges are Not Saved ${e.toString()}",
                                    context: context,
                                    type: 0);
                              }
                            },
                            child: Text("Save Ranges",
                                style: TextStyle(
                                  color: Colors.white,
                                )))
                        : SizedBox(
                            height: 0,
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    !addLoc
                        ? RaisedButton(
                            color: Colors.black,
                            onPressed: () {
                              setState(() {
                                addLoc = true;
                                listenLoc = false;
                                _latController.text = widget
                                        .currentLocation.latitude
                                        .toString() ??
                                    '-';
                                _longController.text = widget
                                        .currentLocation.longitude
                                        .toString() ??
                                    '-';
                              });
                            },
                            child: Text("Add Location",
                                style: TextStyle(
                                  color: Colors.white,
                                )))
                        : SizedBox(
                            height: 0,
                          ),
                    addLoc
                        ? Column(
                            children: [
                              TextFormField(
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: "Name",
                                ),
                                keyboardType: TextInputType.name,
                                controller: _nameController,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return "The Name cannot be empty";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              TextFormField(
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: "Latitude",
                                ),
                                keyboardType: TextInputType.text,
                                controller: _latController,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return "The Latitude cannot be empty";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              TextFormField(
                                maxLines: 1,
                                decoration: InputDecoration(
                                  hintText: "Longitude",
                                ),
                                keyboardType: TextInputType.text,
                                controller: _longController,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return "The Longitude cannot be empty";
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Container(
                                  padding: EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Accuracy:",
                                        style: TextStyle(fontSize: 17),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "${widget.currentLocation.accuracy ?? '-'}",
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )),
                              Row(
                                children: [
                                  Expanded(
                                    child: RaisedButton(
                                        color: Colors.black,
                                        onPressed: () {
                                          setState(() {
                                            addLoc = false;
                                            listenLoc = true;
                                          });
                                        },
                                        child: Text("Cancel",
                                            style: TextStyle(
                                                color: Colors.white))),
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: RaisedButton(
                                        color: Colors.black,
                                        onPressed: () async {
                                          bool success = await saveLocation();
                                          if (success) {
                                            setState(() {
                                              addLoc = false;
                                              listenLoc = true;
                                            });
                                          }
                                        },
                                        child: Text(
                                          "Save",
                                          style: TextStyle(color: Colors.white),
                                        )),
                                  ),
                                ],
                              )
                            ],
                          )
                        : SizedBox(
                            height: 0,
                          ),
                    SizedBox(
                      height: 10,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    locsLoad
                        ? Center(child: CircularProgressIndicator())
                        : locations.length > 0
                            ? Container(
                                height: MediaQuery.of(context).size.height / 2,
                                child: ListView.builder(
                                  itemCount: locations.length,
                                  itemBuilder: (context, i) {
                                    return _savedLocs(locations[i]);
                                  },
                                ),
                              )
                            : SizedBox(
                                height: 5,
                              )
                  ]),
            ),
          ),
        ));
  }

  Future<bool> saveLocation() async {
    bool returnbool = false;
    final SharedPreferences prefs = await AppMain.mainPrefs;
    LocationData destination = LocationData.withName(
        latitude: double.parse(_latController.text),
        longitude: double.parse(_longController.text),
        name: _nameController.text);

    List<String> locations = prefs.getStringList('dist_locations');
    if (locations == null) {
      locations = [];
    }
    locations.add(destination.toString());
    returnbool = await prefs.setStringList("dist_locations", locations);
    await getLocations();
    return returnbool;
  }

  Widget _savedLocs(LocationData cp) {
    return Container(
      key: Key(cp.name + ":" + cp.latitude.toString()),
      height: 60,
      margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300],
              blurRadius: 2.0,
            ),
          ]),
      child: Container(
        height: 50,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                cp.name,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cp.latitude.toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    cp.longitude.toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Expanded(
                    child: Row(
                  children: [
                    IconButton(
                        icon: Icon(
                          Icons.exit_to_app,
                          color: Colors.green,
                        ),
                        onPressed: () async {
                          Navigator.pop(context, cp);
                        }),
                    IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          await _showMyDialog(cp);
                        })
                  ],
                )),
              ],
            )
          ],
        ),
      ),
    );
  }

  deleteLocation(String name) async {
    List<LocationData> locs = [];
    final SharedPreferences prefs = await AppMain.mainPrefs;

    List<String> strlocations = prefs.getStringList('dist_locations');
    if (strlocations == null) {
      setState(() {
        locations = [];
      });
    } else {
      for (String locStr in strlocations) {
        List<String> locList = locStr.split(';');
        if (locList[2] != name) {
          locs.add(LocationData.withName(
              latitude: double.parse(locList[0]),
              longitude: double.parse(locList[1]),
              name: locList[2]));
        }
      }
      List<String> locStrings = [];
      for (LocationData loco in locs) {
        locStrings.add(loco.toString());
      }
      await prefs.setStringList('dist_locations', locStrings);
    }
    setState(() {
      locations = locs;
    });
  }

  getLocations() async {
    setState(() {
      locsLoad = true;
    });
    List<LocationData> locs = [];
    final SharedPreferences prefs = await AppMain.mainPrefs;

    List<String> strlocations = prefs.getStringList('dist_locations');

    if (strlocations == null) {
      setState(() {
        locations = [];
        locsLoad = false;
      });
    } else {
      for (String locStr in strlocations) {
        List<String> locList = locStr.split(';');
        locs.add(LocationData.withName(
            latitude: double.parse(locList[0]),
            longitude: double.parse(locList[1]),
            name: locList[2]));
      }
    }
    //print(locs);
    setState(() {
      locations = locs;
      locsLoad = false;
    });
  }

  Future<void> _showMyDialog(LocationData cp) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Are You Sure?"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                    "Are you sure, you want to delete ${cp.name} from your list?"),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text("Yes"),
              onPressed: () async {
                await deleteLocation(cp.name);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
