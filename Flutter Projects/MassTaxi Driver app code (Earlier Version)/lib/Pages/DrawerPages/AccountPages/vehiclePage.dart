import 'dart:io';

import 'package:audio_record/Classes/camera_data.dart';
import 'package:audio_record/Models/carModel.dart';
import 'package:audio_record/Models/systemAccount.dart';
import 'package:audio_record/Service/cloudStorageServ.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/constant.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class VehiclePage extends StatefulWidget {
  final String driverDocID;
  VehiclePage({this.driverDocID});
  @override
  _VehiclePageState createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final _formKey = GlobalKey<FormState>();
  List<CameraDescription> cameras;
  CameraController controller;
  XFile imageFile;
  final List<String> _regions = {"Addis Ababa", "Nairobi"}.toList();
  final List<String> _speakerQualities = {"Good", "Great"}.toList();
  final List<String> _speakerPositions = {"Front", "Middle", "Back"}.toList();
  final List<String> _engineSoundPollutions = {"Good", "Great"}.toList();
  // final List<String> _carModels = {"Mini-bus"}.toList();

  String _selectedRegion,
      _selectedSpeakerQuality,
      _selectedSpeakerPosition,
      _selectedEngineSoundPollution,
      _selectedCarModel;

  List<DropdownMenuItem<String>> _regionItems;
  List<DropdownMenuItem<String>> _speakerQualityItems;
  List<DropdownMenuItem<String>> _speakerPositionItems;
  List<DropdownMenuItem<String>> _engineSoundPollutionItems;

  List<SystemRequirementAccount> systemAccounts = [];
  List<CarModel> carmodels = [];
  var checkBoxValues = [];

  bool loaded = false, carModelLoaded = false, regionExist = false;

  String plateNumber = "", cspIdentifier, systemAccountID = "", tvDocID = "";

  int uploadPicture = 0;
  String tvImageUrl = "", interiorPicUrl = "";

  List<String> cars = [];

  List<DropdownMenuItem<String>> buildDropDownItem(List places) {
    List<DropdownMenuItem<String>> items = [];
    for (var place in places) {
      items.add(DropdownMenuItem(
        value: place,
        child: Text(
          place,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
        ),
      ));
    }
    return items;
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

  Future<String> onTakePictureButtonPressed(String folderName) async {
    return takePicture().then((XFile file) async {
      if (mounted) {
        setState(() {
          imageFile = file;
        });
        if (file != null) {
          // This is the file path  =  file.path
          // Upload the picture here
          String url = await CloudStorageService()
              .uploadImage(File(file.path), folderName);
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

  onRegionChange(String selectedRegion) {
    setState(() {
      carModelLoaded = false;
      _selectedRegion = selectedRegion;
      for (var i = 0; i < systemAccounts.length; i++) {
        if (systemAccounts[i].name == selectedRegion) {
          systemAccountID = systemAccounts[i].docID;
          break;
        }
      }
      DatabaseService().getCarModels(systemAccountID).then((carModels) {
        if (carModels.isNotEmpty) {
          setState(() {
            carmodels = carModels;
            cars.clear();
            for (var item in carModels) {
              cars.add(item.name);
            }
            // _carModelItems.clear();
            // _carModelItems = buildDropDownItem(cars);
            _selectedCarModel = cars[0];
            carModelLoaded = true;
          });
        }
      });
    });
  }

  onCarModelChange(String selectedCarModel) {
    setState(() {
      _selectedCarModel = selectedCarModel;
    });
  }

  onSpeakerQualityChange(String selectedQuality) {
    setState(() {
      _selectedSpeakerQuality = selectedQuality;
    });
  }

  onSpeakerPositionChange(String speakerPosition) {
    setState(() {
      _selectedSpeakerPosition = speakerPosition;
    });
  }

  onEngineSoundPollutionChange(String selectedEngineSoundPollution) {
    setState(() {
      _selectedEngineSoundPollution = selectedEngineSoundPollution;
    });
  }

  @override
  void initState() {
    setupCameras();
    DatabaseService().getRegions().then((value) {
      if (value.isNotEmpty) {
        systemAccounts.addAll(value);
        _regions.clear();
        value.forEach((element) {
          _regions.add(element.name);
        });
        _regionItems = buildDropDownItem(_regions);
        _speakerQualityItems = buildDropDownItem(_speakerQualities);
        _engineSoundPollutionItems = buildDropDownItem(_engineSoundPollutions);
        _speakerPositionItems = buildDropDownItem(_speakerPositions);
        DatabaseService().getTVdata(widget.driverDocID).then((value) {
          for (var i = 0; i < systemAccounts.length; i++) {
            if (systemAccounts[i].docID == value.systemAccountId) {
              _selectedRegion = _regionItems[i].value;
              systemAccountID = systemAccounts[i].docID;
              regionExist = true;
              break;
            }
          }
          if (!regionExist) {
            _selectedRegion = _regionItems[0].value;
          }
          if (value.speakerQuality) {
            _selectedSpeakerQuality = _speakerQualityItems[1].value;
          } else {
            _selectedSpeakerQuality = _speakerQualityItems[0].value;
          }
          if (value.engineSoundPollution) {
            _selectedEngineSoundPollution = _engineSoundPollutionItems[1].value;
          } else {
            _selectedEngineSoundPollution = _engineSoundPollutionItems[0].value;
          }
          _selectedSpeakerPosition =
              _speakerPositionItems[value.speakerPosition].value;
          plateNumber = value.plateNumber;
          tvDocID = value.tvDocID;
          tvImageUrl = value.imageUrl;
          if (regionExist) {
            DatabaseService()
                .getCarModels(value.systemAccountId)
                .then((carModels) {
              setState(() {
                loaded = true;
                // print("system acco: " + value.systemAccountId);
                if (carModels.isNotEmpty) {
                  carmodels = carModels;
                  // List<String> cars = [];
                  cars.clear();
                  for (var item in carModels) {
                    if (item.carModelDocID == value.carModelID) {
                      cars.add(item.name);
                      break;
                    }
                  }
                  // _carModelItems.clear();
                  // _carModelItems = buildDropDownItem(cars);
                  _selectedCarModel = cars[0];
                  carModelLoaded = true;
                }
              });
            });
          } else {
            DatabaseService()
                .getCarModels(systemAccounts[0].docID)
                .then((carModels) {
              setState(() {
                loaded = true;
                if (carModels.isNotEmpty) {
                  carmodels = carModels;
                  cars.clear();
                  for (var item in carModels) {
                    cars.add(item.name);
                  }
                  // _carModelItems.clear();
                  // _carModelItems = buildDropDownItem(cars);
                  _selectedCarModel = cars[0];
                  carModelLoaded = true;
                }
              });
            });
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
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
                      "Create/Edit Vehicle Account",
                      style: TextStyle(
                          fontSize: deviceWidth * 0.1,
                          fontWeight: FontWeight.w400),
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    TextFormField(
                      initialValue: plateNumber,
                      readOnly: regionExist,
                      decoration: textInputDecoration.copyWith(
                          hintText: "Plate Number"),
                      validator: (value) =>
                          value.isEmpty ? "Enter your plate number" : null,
                      onChanged: (value) {
                        setState(() {
                          plateNumber = value;
                        });
                      },
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(
                      height: deviceHeight * 0.015,
                    ),
                    // Row(
                    //   children: [
                    //     Flexible(
                    //         flex: 5,
                    //         fit: FlexFit.tight,
                    //         child: Text(
                    //           "Calibration >60 :",
                    //           style: TextStyle(
                    //               fontSize: deviceWidth * 0.06,
                    //               fontWeight: FontWeight.w300),
                    //         )),
                    //     Flexible(
                    //       flex: 2,
                    //       fit: FlexFit.tight,
                    //       child: TextFormField(
                    //         textAlign: TextAlign.center,
                    //         readOnly: true,
                    //         style: TextStyle(
                    //           fontSize: deviceWidth * 0.1,
                    //         ),
                    //         controller: _calibration60,
                    //         keyboardType: TextInputType.number,
                    //       ),
                    //     ),
                    //     Flexible(
                    //       flex: 2,
                    //       fit: FlexFit.tight,
                    //       child: Column(
                    //         children: [
                    //           IconButton(
                    //             icon: Icon(Icons.add),
                    //             onPressed: () {
                    //               int temp = int.parse(_calibration60.text);
                    //               temp++;
                    //               _calibration60.text = temp.toString();
                    //             },
                    //             iconSize: deviceWidth * 0.06,
                    //           ),
                    //           IconButton(
                    //             icon: Icon(Icons.remove),
                    //             onPressed: () {
                    //               int temp = int.parse(_calibration60.text);
                    //               temp--;
                    //               _calibration60.text = temp.toString();
                    //             },
                    //             iconSize: deviceWidth * 0.06,
                    //           )
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(
                    //   height: deviceHeight * 0.015,
                    // ),
                    // Row(
                    //   children: [
                    //     Flexible(
                    //         flex: 5,
                    //         fit: FlexFit.tight,
                    //         child: Text(
                    //           "Calibration >70 :",
                    //           style: TextStyle(
                    //               fontSize: deviceWidth * 0.06,
                    //               fontWeight: FontWeight.w300),
                    //         )),
                    //     Flexible(
                    //       flex: 2,
                    //       fit: FlexFit.tight,
                    //       child: TextFormField(
                    //         textAlign: TextAlign.center,
                    //         readOnly: true,
                    //         style: TextStyle(
                    //           fontSize: deviceWidth * 0.1,
                    //         ),
                    //         controller: _calibration70,
                    //         keyboardType: TextInputType.number,
                    //       ),
                    //     ),
                    //     Flexible(
                    //       flex: 2,
                    //       fit: FlexFit.tight,
                    //       child: Column(
                    //         children: [
                    //           IconButton(
                    //             icon: Icon(Icons.add),
                    //             onPressed: () {
                    //               int temp = int.parse(_calibration70.text);
                    //               temp++;
                    //               _calibration70.text = temp.toString();
                    //             },
                    //             iconSize: deviceWidth * 0.06,
                    //           ),
                    //           IconButton(
                    //             icon: Icon(Icons.remove),
                    //             onPressed: () {
                    //               int temp = int.parse(_calibration70.text);
                    //               temp--;
                    //               _calibration70.text = temp.toString();
                    //             },
                    //             iconSize: deviceWidth * 0.06,
                    //           )
                    //         ],
                    //       ),
                    //     ),
                    //   ],
                    // ),
                    // SizedBox(
                    //   height: deviceHeight * 0.015,
                    // ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Region :",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.06,
                                  fontWeight: FontWeight.w300)),
                        ),
                        Expanded(
                            child: DropdownButton(
                          items: _regionItems,
                          style: TextStyle(
                            fontSize: deviceWidth * 0.1,
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                          ),
                          onChanged: regionExist ? null : onRegionChange,
                          value: _selectedRegion,
                        )),
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    carModelLoaded
                        ?
                        //  Container(
                        //   height: deviceHeight * 0.2,
                        //   // color: Colors.amber,
                        //   child: SingleChildScrollView(
                        //     child: Container(
                        //       height: deviceHeight * 0.2,
                        //       child: Column(
                        //           mainAxisAlignment: MainAxisAlignment.center,
                        //           children: [
                        //               carModelLoaded? Expanded(
                        //                     child: ListView.builder(
                        //                     itemCount: mainRoutes.length,
                        //                     itemBuilder: (context, index) {
                        //                       return Padding(
                        //                         padding: const EdgeInsets.all(8.0),
                        //                         child: Card(
                        //                           clipBehavior: Clip.hardEdge,
                        //                           elevation: 8,
                        //                           child: CheckboxListTile(
                        //                               controlAffinity:
                        //                                   ListTileControlAffinity
                        //                                       .leading,
                        //                               title: Text(
                        //                                 (mainRoutes[index].startingLocation +
                        //                                                 " - " +
                        //                                                 mainRoutes[
                        //                                                         index]
                        //                                                     .destination)
                        //                                             .length <
                        //                                         20
                        //                                     ? (mainRoutes[index]
                        //                                             .startingLocation +
                        //                                         " - " +
                        //                                         mainRoutes[index]
                        //                                             .destination)
                        //                                     : (mainRoutes[index]
                        //                                                     .startingLocation +
                        //                                                 " - " +
                        //                                                 mainRoutes[
                        //                                                         index]
                        //                                                     .destination)
                        //                                             .substring(
                        //                                                 0, 20) +
                        //                                         "...",
                        //                                 style: TextStyle(
                        //                                     color: checkBoxValues[
                        //                                             index]
                        //                                         ? Colors.white
                        //                                         : Colors.black),
                        //                               ),
                        //                               tileColor: Colors.white,
                        //                               selectedTileColor:
                        //                                   Colors.green,
                        //                               checkColor: Colors.white,
                        //                               activeColor: Colors.green,
                        //                               selected:
                        //                                   checkBoxValues[index],
                        //                               value: checkBoxValues[index],
                        //                               onChanged: (value) {
                        //                                 setState(() {
                        //                                   checkBoxValues[index] =
                        //                                       value;
                        //                                 });
                        //                               }),
                        //                         ),
                        //                       );
                        //                     },
                        //                   ))
                        //                 : Loading()
                        //           ]),
                        //     ),
                        //   ),
                        // )
                        Row(
                            children: [
                              Expanded(
                                child: Text("Car Model :",
                                    style: TextStyle(
                                        fontSize: deviceWidth * 0.06,
                                        fontWeight: FontWeight.w300)),
                              ),
                              Expanded(
                                  child: DropdownButton<String>(
                                items: cars.map((e) {
                                  return DropdownMenuItem<String>(
                                    child: Text(
                                      e,
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w300),
                                    ),
                                    value: e,
                                  );
                                }).toList(),
                                style: TextStyle(
                                  fontSize: deviceWidth * 0.1,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                ),
                                onChanged:
                                    regionExist ? null : onCarModelChange,
                                value: _selectedCarModel,
                              )),
                            ],
                          )
                        : Loading(),

                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Speaker Quality :",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.06,
                                  fontWeight: FontWeight.w300)),
                        ),
                        Expanded(
                            child: DropdownButton(
                          items: _speakerQualityItems,
                          style: TextStyle(
                            fontSize: deviceWidth * 0.1,
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                          ),
                          onChanged: onSpeakerQualityChange,
                          value: _selectedSpeakerQuality,
                        )),
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Speaker Position :",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.06,
                                  fontWeight: FontWeight.w300)),
                        ),
                        Expanded(
                            child: DropdownButton(
                          items: _speakerPositionItems,
                          style: TextStyle(
                            fontSize: deviceWidth * 0.1,
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                          ),
                          onChanged: onSpeakerPositionChange,
                          value: _selectedSpeakerPosition,
                        )),
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text("Engine Sound Pollution :",
                              style: TextStyle(
                                  fontSize: deviceWidth * 0.06,
                                  fontWeight: FontWeight.w300)),
                        ),
                        Expanded(
                            child: DropdownButton(
                          items: _engineSoundPollutionItems,
                          style: TextStyle(
                            fontSize: deviceWidth * 0.1,
                            color: Colors.black,
                            fontWeight: FontWeight.w300,
                          ),
                          onChanged: onEngineSoundPollutionChange,
                          value: _selectedEngineSoundPollution,
                        )),
                      ],
                    ),
                    SizedBox(
                      height: deviceHeight * 0.025,
                    ),
                    tvImageUrl == ""
                        ? Container(
                            child: ElevatedButton.icon(
                              onPressed: uploadPicture == 0
                                  ? () async {
                                      setState(() {
                                        uploadPicture = 1;
                                      });
                                      onTakePictureButtonPressed("tvPics")
                                          .then((value) {
                                        if (value == "f") {
                                          setState(() {
                                            uploadPicture = 0;
                                          });
                                        } else {
                                          interiorPicUrl = value;
                                          setState(() {
                                            uploadPicture = 2;
                                          });
                                        }
                                      });
                                    }
                                  : null,
                              icon: Icon(Icons.camera),
                              label: Text(uploadPicture == 0
                                  ? "Upload TV Pic"
                                  : uploadPicture == 1
                                      ? "Uploading..."
                                      : "Uploaded"),
                            ),
                          )
                        : Container(),
                    tvImageUrl == ""
                        ? SizedBox(
                            height: deviceHeight * 0.025,
                          )
                        : Container(),
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
                        onPressed: carModelLoaded &&
                                ((tvImageUrl == "" && uploadPicture == 2) ||
                                    (tvImageUrl != ""))
                            ? () async {
                                if (_formKey.currentState.validate()) {
                                  setState(() {
                                    loaded = false;
                                  });
                                  int speakerPosition = 0;
                                  bool engineSoundPollution, speakerQuality;
                                  String carModelID;
                                  if (_selectedSpeakerPosition == "Front") {
                                    speakerPosition = 0;
                                  } else if (_selectedSpeakerPosition ==
                                      "Middle") {
                                    speakerPosition = 1;
                                  } else if (_selectedSpeakerPosition ==
                                      "Back") {
                                    speakerPosition = 2;
                                  }
                                  if (_selectedEngineSoundPollution ==
                                      "Great") {
                                    engineSoundPollution = true;
                                  } else {
                                    engineSoundPollution = false;
                                  }
                                  if (_selectedSpeakerQuality == "Great") {
                                    speakerQuality = true;
                                  } else {
                                    speakerQuality = false;
                                  }
                                  for (var item in carmodels) {
                                    if (item.name == _selectedCarModel) {
                                      carModelID = item.carModelDocID;
                                      break;
                                    }
                                  }
                                  if (regionExist && tvDocID != "") {
                                    String imageUrl =
                                        await onTakePictureButtonPressed(
                                            "fixClaim");
                                    if (imageUrl != "f") {
                                      DatabaseService()
                                          .updateTV(
                                              tvDocID,
                                              plateNumber,
                                              speakerPosition,
                                              engineSoundPollution,
                                              speakerQuality,
                                              int.parse(cspIdentifier),
                                              imageUrl,
                                              interiorPicUrl,
                                              widget.driverDocID,
                                              systemAccountID)
                                          .then((value) async {
                                        if (value) {
                                          setState(() {
                                            loaded = true;
                                            interiorPicUrl = "";
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                "Transport Vehicle Updated Successfully"),
                                            backgroundColor: Colors.green,
                                          ));
                                        } else {
                                          if (tvImageUrl == "" &&
                                              interiorPicUrl != "") {
                                            await CloudStorageService()
                                                .deleteFile(interiorPicUrl);
                                          }
                                          await CloudStorageService()
                                              .deleteFile(imageUrl);
                                          setState(() {
                                            loaded = true;
                                            uploadPicture = 0;
                                          });
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text(
                                                "Failed To Update Transport Vehicle"),
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
                                  } else {
                                    DatabaseService()
                                        .createTV(
                                            plateNumber,
                                            speakerPosition,
                                            engineSoundPollution,
                                            speakerQuality,
                                            int.parse(cspIdentifier),
                                            carModelID,
                                            interiorPicUrl,
                                            systemAccountID)
                                        .then((value) async {
                                      if (value) {
                                        setState(() {
                                          loaded = true;
                                          uploadPicture = 0;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              "Transport Vehicle Created Successfully"),
                                          backgroundColor: Colors.green,
                                        ));
                                        // Navigator.pop(context);
                                      } else {
                                        await CloudStorageService()
                                            .deleteFile(interiorPicUrl);
                                        setState(() {
                                          loaded = true;
                                          uploadPicture = 0;
                                        });
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              "Failed To Create Transport Vehicle"),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                    });
                                  }
                                }
                              }
                            : null,
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
