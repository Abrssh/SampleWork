import 'dart:io';

import 'package:audio_record/Classes/camera_data.dart';
import 'package:audio_record/Service/cloudStorageServ.dart';
import 'package:camera/camera.dart';
import 'package:audio_record/Models/superPath.dart';
import 'package:audio_record/Models/systemAccount.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/constant.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class DriverPage extends StatefulWidget {
  final String driverDocID;
  DriverPage({this.driverDocID});
  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  List<CameraDescription> cameras;
  CameraController controller;
  XFile imageFile;

  final _formKey = GlobalKey<FormState>();

  var checkBoxValues = [];

  bool loaded = false;
  bool routesLoaded = false;

  List<SystemRequirementAccount> systemAccounts = [];
  List<SuperPath> mainRoutes = [];

  String name, systemAccountDocID, plateNumber, bankAccount;
  String cspIdentifier;

  List<String> mainRouteDocIDs = [];

  TextEditingController _calibration = TextEditingController();

  @override
  void initState() {
    setupCameras();
    DatabaseService().getDriverData(widget.driverDocID).then((driver) {
      systemAccountDocID = driver.systemAccountID;
      if (driver.calibration == 0.1) {
        _calibration.text = "0";
      } else {
        _calibration.text = driver.calibration.toString();
      }
      plateNumber = driver.plateNumber;
      bankAccount = driver.bankAccount;
      name = driver.name;
      DatabaseService().getMainRoutes(systemAccountDocID).then((value) {
        setState(() {
          mainRoutes = value;
          checkBoxValues.clear();
          value.forEach((element) {
            bool routeExist = false;
            for (var item in driver.mainRoutes) {
              if (item == element.docID) {
                routeExist = true;
                break;
              }
            }
            if (routeExist) {
              checkBoxValues.add(true);
            } else {
              checkBoxValues.add(false);
            }
          });
          loaded = true;
          routesLoaded = true;
        });
      });
    });
    if (_calibration.text == null) {
      _calibration.text = "0";
    }
    super.initState();
  }

  Future<XFile> takePicture() async {
    final CameraController cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      print('Error: select a camera first.');
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print(e);
      return null;
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<String> onTakePictureButtonPressed() async {
    return takePicture().then((XFile file) async {
      if (mounted) {
        setState(() {
          imageFile = file;
        });
        if (file != null) {
          // This is the file path  =  file.path
          // Upload the picture here
          String url = await CloudStorageService()
              .uploadImage(File(file.path), "fixClaim");
          print("Image file: " + file.path.toString());
          // Delete the picture here
          await CameraData.deleteImage(file.path);
          return url;
        } else {
          return "f";
        }
      } else {
        print('Not Mounted');
        return "f";
      }
    });
  }

  void setupCameras() async {
    cameras = await availableCameras();
    if (cameras != null) {
      controller = CameraController(cameras[1], ResolutionPreset.max);
      controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;

    return loaded
        ? SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.symmetric(
                  vertical: deviceHeight * 0.05, horizontal: deviceWidth * 0.1),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text(
                      "Edit Driver",
                      style: TextStyle(
                          fontSize: deviceWidth * 0.1,
                          fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    TextFormField(
                      initialValue: name != null ? name : null,
                      decoration:
                          textInputDecoration.copyWith(hintText: "Name"),
                      validator: (value) =>
                          value.isEmpty ? "Enter your name" : null,
                      onChanged: (value) {
                        setState(() {
                          name = value;
                        });
                      },
                    ),
                    SizedBox(
                      height: deviceHeight * 0.015,
                    ),
                    Row(
                      children: [
                        Flexible(
                            flex: 5,
                            fit: FlexFit.tight,
                            child: Text(
                              "Calibration :",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.06,
                                  fontWeight: FontWeight.w300),
                            )),
                        Flexible(
                          flex: 3,
                          fit: FlexFit.tight,
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            readOnly: true,
                            style: TextStyle(
                              fontSize: deviceWidth * 0.1,
                            ),
                            controller: _calibration,
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
                                  double temp = double.parse(_calibration.text);
                                  temp += 0.5;
                                  _calibration.text = temp.toString();
                                },
                                iconSize: deviceWidth * 0.06,
                              ),
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  double temp = double.parse(_calibration.text);
                                  temp -= 0.5;
                                  _calibration.text = temp.toString();
                                },
                                iconSize: deviceWidth * 0.06,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    TextFormField(
                      initialValue: plateNumber != null ? plateNumber : null,
                      decoration: textInputDecoration.copyWith(
                          hintText: "Plate Number"),
                      validator: (value) =>
                          value.isEmpty ? "Enter your plate number" : null,
                      onChanged: (value) {
                        setState(() {
                          plateNumber = value;
                        });
                      },
                      // keyboardType: TextInputType.number,
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    // TextFormField(
                    //   decoration: textInputDecoration.copyWith(
                    //       hintText: "License Number"),
                    //   validator: (value) =>
                    //       value.isEmpty ? "Enter your Licesnse Number" : null,
                    //   onChanged: (value) {
                    //     setState(() {
                    //       licenseNumber = value;
                    //     });
                    //   },
                    //   // keyboardType: TextInputType.number,
                    // ),
                    // SizedBox(
                    //   height: deviceHeight * 0.025,
                    // ),
                    // TextFormField(
                    //   readOnly: true,
                    //   decoration: textInputDecoration.copyWith(
                    //       hintText: "Phone Number"),
                    //   // validator: (value) =>
                    //   //     (value.isEmpty || double.tryParse(value) == null)
                    //   //         ? "Enter your phone Number"
                    //   //         : null,
                    //   // onChanged: (value) {
                    //   //   setState(() {
                    //   //     // email = value;
                    //   //   });
                    //   // },
                    //   initialValue: widget.phoneNumber,
                    //   keyboardType: TextInputType.number,
                    // ),
                    // SizedBox(
                    //   height: deviceHeight * 0.025,
                    // ),

                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: Text("Region :",
                    //           style: TextStyle(
                    //               fontSize: deviceWidth * 0.08,
                    //               fontWeight: FontWeight.w300)),
                    //     ),
                    //     Expanded(
                    //         child: DropdownButton(
                    //       items: _dropDownItem,
                    //       style: TextStyle(
                    //         fontSize: deviceWidth * 0.1,
                    //         color: Colors.black,
                    //         fontWeight: FontWeight.w300,
                    //       ),
                    //       onChanged: onDropdownChange,
                    //       value: _selectedRegion,
                    //     )),
                    //   ],
                    // ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    TextFormField(
                      initialValue: bankAccount != null ? bankAccount : null,
                      decoration: textInputDecoration.copyWith(
                          hintText: "Bank Account"),
                      // validator: (value) => (value.isEmpty ||
                      //         double.tryParse(value) == null)
                      validator: (value) => value.isEmpty
                          ? "Enter your bank account number"
                          : null,
                      onChanged: (value) {
                        setState(() {
                          bankAccount = value;
                        });
                      },
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    Text(
                      "Select Your Main Routes",
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
                                routesLoaded
                                    ? Expanded(
                                        child: ListView.builder(
                                        itemCount: mainRoutes.length,
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
                                                                    // mainRoutes[index].startingLocation +
                                                                    //               " - " +
                                                                    mainRoutes[
                                                                            index]
                                                                        .destination)
                                                                .length <
                                                            20
                                                        ? (
                                                            // mainRoutes[index]
                                                            //       .startingLocation +
                                                            //   " - " +
                                                            mainRoutes[index]
                                                                .destination)
                                                        : (
                                                                    // mainRoutes[index]
                                                                    //               .startingLocation +
                                                                    //           " - " +
                                                                    mainRoutes[
                                                                            index]
                                                                        .destination)
                                                                .substring(
                                                                    0, 20) +
                                                            "...",
                                                    style: TextStyle(
                                                        color: checkBoxValues[
                                                                index]
                                                            ? Colors.white
                                                            : Colors.black),
                                                  ),
                                                  tileColor: Colors.white,
                                                  selectedTileColor:
                                                      Colors.green,
                                                  checkColor: Colors.white,
                                                  activeColor: Colors.green,
                                                  selected:
                                                      checkBoxValues[index],
                                                  value: checkBoxValues[index],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      checkBoxValues[index] =
                                                          value;
                                                    });
                                                  }),
                                            ),
                                          );
                                        },
                                      ))
                                    : Loading()
                              ]),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),

                    TextFormField(
                      decoration: textInputDecoration.copyWith(
                          hintText: "CSP Identifier"),
                      validator: (value) =>
                          (value.isEmpty || int.tryParse(value) == null)
                              ? "Enter CSP Identifier"
                              : null,
                      onChanged: (value) {
                        setState(() {
                          cspIdentifier = value;
                        });
                      },
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          mainRouteDocIDs.clear();
                          for (var i = 0; i < checkBoxValues.length; i++) {
                            if (checkBoxValues[i] == true) {
                              mainRouteDocIDs.add(mainRoutes[i].docID);
                            }
                          }
                          if (_formKey.currentState.validate() &&
                              systemAccountDocID != null &&
                              mainRouteDocIDs.length >= 1) {
                            setState(() {
                              loaded = false;
                            });
                            String imageUrl =
                                await onTakePictureButtonPressed();
                            if (imageUrl != "f") {
                              int cspID = int.parse(cspIdentifier);
                              DatabaseService()
                                  .updateDriverAccount(
                                      name,
                                      systemAccountDocID,
                                      plateNumber,
                                      double.parse(_calibration.text),
                                      bankAccount,
                                      widget.driverDocID,
                                      imageUrl,
                                      cspID,
                                      mainRouteDocIDs)
                                  .then((value) async {
                                if (value) {
                                  setState(() {
                                    loaded = true;
                                  });
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        "Driver Account Updated Successfully"),
                                    backgroundColor: Colors.green,
                                  ));
                                } else {
                                  await CloudStorageService()
                                      .deleteFile(imageUrl);
                                  setState(() {
                                    loaded = true;
                                  });
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text("Failed To Update Driver Account"),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              });
                            } else {
                              setState(() {
                                loaded = true;
                              });
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("Failed To Upload Image"),
                                backgroundColor: Colors.red,
                              ));
                            }
                          }
                        },
                        child: Text(
                          "SUBMIT",
                          style: TextStyle(
                              fontSize: deviceWidth * 0.08,
                              fontWeight: FontWeight.w400),
                        ))
                  ],
                ),
              ),
            ),
          )
        : Center(
            child: Loading(),
          );
  }
}
