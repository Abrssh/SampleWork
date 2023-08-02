import 'dart:io';

import 'package:audio_record/Classes/camera_data.dart';
import 'package:audio_record/Service/cloudStorageServ.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/constant.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_ui/firebase_auth_ui.dart';
import 'package:flutter/material.dart';

class ChangePhonePage extends StatefulWidget {
  final String driverID, phoneID, systemAccountID;
  ChangePhonePage({this.driverID, this.phoneID, this.systemAccountID});
  @override
  _ChangePhonePageState createState() => _ChangePhonePageState();
}

class _ChangePhonePageState extends State<ChangePhonePage> {
  List<CameraDescription> cameras;
  CameraController controller;
  XFile imageFile;

  final _formKey = GlobalKey<FormState>();
  bool loaded = true;
  String cspIdentifier;

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

  void logOut() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuthUi.instance().logout().then((value) => null);
    }
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
  void initState() {
    setupCameras();
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

    Future<bool> _onBackPressed() {
      return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Log Out'),
                content: Text(
                  'Are you sure you want to exit this page?',
                  style: TextStyle(fontSize: deviceWidth * 0.05),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      logOut();
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text('Yes',
                        style: TextStyle(fontSize: deviceWidth * 0.06)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('No',
                        style: TextStyle(fontSize: deviceWidth * 0.06)),
                  )
                ],
              );
            },
          ) ??
          false;
    }

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Change Phone"),
          centerTitle: true,
        ),
        body: loaded
            ? SingleChildScrollView(
                child: Container(
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
                              if (_formKey.currentState.validate()) {
                                setState(() {
                                  loaded = false;
                                });
                                String imageUrl =
                                    await onTakePictureButtonPressed();
                                if (imageUrl != "f") {
                                  int cspIdent = int.parse(cspIdentifier);
                                  DatabaseService()
                                      .changePhone(
                                          widget.phoneID,
                                          widget.driverID,
                                          widget.systemAccountID,
                                          imageUrl,
                                          cspIdent)
                                      .then((value) {
                                    setState(() {
                                      loaded = true;
                                    });
                                    if (value) {
                                      logOut();
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "New Phone Registered in" +
                                                " the System Successfully."),
                                        backgroundColor: Colors.green,
                                      ));
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: Text(
                                            "Failed to Register New Phone."),
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
                                  fontSize: deviceWidth * 0.1,
                                  fontWeight: FontWeight.w400),
                            ))
                      ],
                    ),
                  ),
                ),
              )
            : Center(
                child: Loading(),
              ),
      ),
    );
  }
}
