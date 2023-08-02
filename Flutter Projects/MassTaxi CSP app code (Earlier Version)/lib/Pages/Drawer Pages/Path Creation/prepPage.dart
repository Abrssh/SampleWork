import 'package:csp_app/Classes/location_data.dart';
import 'package:csp_app/Classes/superPath.dart';
import 'package:csp_app/Pages/Drawer%20Pages/Path%20Creation/inPath.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/constant.dart';
import 'package:csp_app/Shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_location/flutter_background_location.dart';

class PathPreparation extends StatefulWidget {
  final String systemAccountId, cspID;
  PathPreparation({this.systemAccountId, this.cspID});
  @override
  _PathPreparationState createState() => _PathPreparationState();
}

class _PathPreparationState extends State<PathPreparation> {
  List<SuperPath> superPaths = [];
  int superPathIndex = 0;
  String pathName = '';

  bool startingSaved = false;
  final _formKey = GlobalKey<FormState>();
  LocationData nft;

  bool loading = false;

  @override
  void initState() {
    DatabaseService().getSuperPaths(widget.systemAccountId).then((value) {
      setState(() {
        superPaths = value;
        loading = true;
      });
    });

    LocationData.clearProgress();

    // Starts Location Service
    FlutterBackgroundLocation.startLocationService();

    FlutterBackgroundLocation.getLocationUpdates((location) => {
          setState(() {
            this.nft = LocationData.withAccuracy(
                latitude: location.latitude,
                longitude: location.longitude,
                speed: location.speed,
                accuracy: location.accuracy);
          })
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
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              SizedBox(
                width: deviceWidth * 0.125,
              ),
              Text(
                "Add New Path",
              )
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
                vertical: deviceHeight * 0.05, horizontal: deviceWidth * 0.1),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        textInputDecoration.copyWith(hintText: "Path Name"),
                    validator: (value) =>
                        value.isEmpty ? "Enter Path name" : null,
                    onChanged: (value) {
                      setState(() {
                        pathName = value;
                        // email = value;
                      });
                    },
                  ),
                  SizedBox(
                    height: deviceHeight * 0.025,
                  ),
                  Text(
                    "Choose One Super Path",
                    style: TextStyle(
                        fontSize: deviceWidth * 0.07,
                        fontWeight: FontWeight.w300),
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
                            loading
                                ? Expanded(
                                    child: ListView.builder(
                                      itemCount: superPaths.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Card(
                                            clipBehavior: Clip.hardEdge,
                                            elevation: 8,
                                            child: CheckboxListTile(
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                title: Text(
                                                  (
                                                                  // (superPaths[index].startingLocation +
                                                                  //                 " - " +
                                                                  superPaths[
                                                                          index]
                                                                      .destination)
                                                              .length <
                                                          20
                                                      ? (
                                                          // ? (superPaths[index]
                                                          //         .startingLocation +
                                                          //     " - " +
                                                          superPaths[index]
                                                              .destination)
                                                      : (
                                                                  // superPaths[index]
                                                                  //               .startingLocation +
                                                                  //           " - " +
                                                                  superPaths[
                                                                          index]
                                                                      .destination)
                                                              .substring(
                                                                  0, 20) +
                                                          "...",
                                                  style: TextStyle(
                                                      color: index ==
                                                              superPathIndex
                                                          ? Colors.white
                                                          : Colors.black),
                                                ),
                                                tileColor: Colors.white,
                                                selectedTileColor: Colors.green,
                                                checkColor: Colors.white,
                                                activeColor: Colors.green,
                                                selected:
                                                    index == superPathIndex
                                                        ? true
                                                        : false,
                                                value: index == superPathIndex
                                                    ? true
                                                    : false,
                                                onChanged: (value) {
                                                  setState(() {
                                                    superPathIndex = index;
                                                  });
                                                }),
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
                  ),
                  SizedBox(
                    height: deviceHeight * 0.025,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Accuracy :",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300)),
                      SizedBox(
                        width: deviceWidth * 0.018,
                      ),
                      Text(nft != null ? nft.accuracy.toStringAsFixed(2) : '-',
                          style: TextStyle(
                              fontSize: deviceWidth * 0.07,
                              fontWeight: FontWeight.w300))
                    ],
                  ),
                  SizedBox(
                    height: deviceHeight * 0.018,
                  ),
                  ElevatedButton(
                      onPressed: this.pathName.length >= 4
                          ? () async {
                              LocationData.saveStart(nft).then((value) => {
                                    // print("Save Starting Location")
                                    setState(() {
                                      startingSaved = true;
                                    })
                                  });
                            }
                          : null,
                      child: Text(
                        "SAVE STARTING LOCATION",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.05,
                            fontWeight: FontWeight.w400),
                      )),
                  SizedBox(
                    height: deviceHeight * 0.025,
                  ),
                  ElevatedButton(
                      onPressed: this.pathName.length >= 4 &&
                              superPaths.length >= 1 &&
                              startingSaved
                          //&& inStartRange
                          ? () async {
                              await LocationData.savePathName(this.pathName);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => InPath(
                                            systemAccountId:
                                                widget.systemAccountId,
                                            superPathDocID:
                                                superPaths[superPathIndex]
                                                    .docID,
                                            // startingLocation:
                                            //     superPaths[superPathIndex]
                                            //         .startingLocation,
                                            destination:
                                                superPaths[superPathIndex]
                                                    .destination,
                                            cspID: widget.cspID,
                                          )));
                            }
                          : null,
                      child: Text(
                        "START RECORDING",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w400),
                      ))
                ],
              ),
            ),
          ),
        ));
  }
}
