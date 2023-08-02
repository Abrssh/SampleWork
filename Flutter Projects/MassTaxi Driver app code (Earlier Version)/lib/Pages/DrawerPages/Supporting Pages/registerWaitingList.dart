import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/constant.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class RegisterWaitingList extends StatefulWidget {
  final String systemAccountId;
  RegisterWaitingList({this.systemAccountId});
  @override
  _RegisterWaitingListState createState() => _RegisterWaitingListState();
}

class _RegisterWaitingListState extends State<RegisterWaitingList> {
  bool loaded = true;
  String name, phoneModel, phoneNumber, plateNumber, mainRoutes;
  final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Register To Waiting List"),
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
                            hintText: "Name of the Driver"),
                        validator: (value) =>
                            value.isEmpty ? "Enter the name" : null,
                        onChanged: (value) {
                          setState(() {
                            name = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      TextFormField(
                        decoration:
                            textInputDecoration.copyWith(hintText: "Plate"),
                        validator: (value) =>
                            (value.isEmpty) ? "Enter your Plate number" : null,
                        onChanged: (value) {
                          setState(() {
                            plateNumber = value;
                          });
                        },
                        keyboardType: TextInputType.name,
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                            hintText: "Phone number"),
                        validator: (value) =>
                            (value.isEmpty || double.tryParse(value) == null)
                                ? "Enter your Phone Number"
                                : null,
                        onChanged: (value) {
                          setState(() {
                            phoneNumber = value;
                          });
                        },
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                            hintText: "Phone Model"),
                        validator: (value) =>
                            value.isEmpty ? "Enter Your Phone Model" : null,
                        onChanged: (value) {
                          setState(() {
                            phoneModel = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      TextFormField(
                        decoration:
                            textInputDecoration.copyWith(hintText: "Tapela"),
                        validator: (value) => value.isEmpty
                            ? "Enter Your Main Routes (Separate with a comma)"
                            : null,
                        onChanged: (value) {
                          setState(() {
                            mainRoutes = value;
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
                              List<String> routes = mainRoutes.split(",");
                              DatabaseService()
                                  .scheduleForRegistration(
                                      routes,
                                      name,
                                      phoneModel,
                                      phoneNumber,
                                      plateNumber,
                                      widget.systemAccountId)
                                  .then((value) {
                                setState(() {
                                  loaded = true;
                                });
                                if (value) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          backgroundColor: Colors.green,
                                          content: Text(
                                              "Driver successfully booked spot  " +
                                                  "for registration.")));
                                  Navigator.pop(context);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          backgroundColor: Colors.red,
                                          content:
                                              Text("Failed to Book Driver.")));
                                }
                              });
                            }
                          },
                          child: Text(
                            "BOOK",
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
