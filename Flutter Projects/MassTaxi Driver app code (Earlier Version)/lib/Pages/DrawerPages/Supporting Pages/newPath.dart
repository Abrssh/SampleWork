import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/constant.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class NewPath extends StatefulWidget {
  final String systemAccountId;
  NewPath({this.systemAccountId});
  @override
  _NewPathState createState() => _NewPathState();
}

class _NewPathState extends State<NewPath> {
  final _formKey = GlobalKey<FormState>();
  bool loaded = true;
  String additionalInfo, endLocationName, startingLocationName, nickname;
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Report New Path"),
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
                            hintText: "Starting Location name"),
                        validator: (value) => value.isEmpty
                            ? "Enter the name of the Location"
                            : null,
                        onChanged: (value) {
                          setState(() {
                            startingLocationName = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                            hintText: "Ending Location name"),
                        validator: (value) => value.isEmpty
                            ? "Enter the name of the Location"
                            : null,
                        onChanged: (value) {
                          setState(() {
                            endLocationName = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                            hintText: "Route Nickname (If any)"),
                        // validator: (value) => value.isEmpty ? "Enter the name of the Location" : null,
                        onChanged: (value) {
                          setState(() {
                            nickname = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      TextFormField(
                        maxLines: 5,
                        decoration: textInputDecoration.copyWith(
                            hintText:
                                "Additional Information about the route (If any)"),
                        // validator: (value) => value.isEmpty ? "Enter the name of the Location" : null,
                        onChanged: (value) {
                          setState(() {
                            additionalInfo = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState.validate()) {
                              setState(() {
                                loaded = false;
                              });
                              DatabaseService()
                                  .createNewPathReport(
                                      additionalInfo,
                                      endLocationName,
                                      startingLocationName,
                                      nickname,
                                      widget.systemAccountId)
                                  .then((value) {
                                setState(() {
                                  loaded = true;
                                });
                                if (value) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content:
                                        Text("New Path Reported Successfully."),
                                    backgroundColor: Colors.green,
                                  ));
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text("Failed To Report New Path"),
                                    backgroundColor: Colors.red,
                                  ));
                                }
                              });
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
    );
  }
}
