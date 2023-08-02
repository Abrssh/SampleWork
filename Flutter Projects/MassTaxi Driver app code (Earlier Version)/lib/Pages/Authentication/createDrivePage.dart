import 'package:audio_record/Models/superPath.dart';
import 'package:audio_record/Models/systemAccount.dart';
import 'package:audio_record/Pages/wrapper.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/constant.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_ui/firebase_auth_ui.dart';
import 'package:flutter/material.dart';

class CreateDriverPage extends StatefulWidget {
  final String phoneNumber, phoneID;
  final Function logOutStatus;
  const CreateDriverPage({
    Key key,
    this.phoneNumber,
    this.logOutStatus,
    this.phoneID,
  }) : super(key: key);
  @override
  _CreateDriverPageState createState() => _CreateDriverPageState();
}

class _CreateDriverPageState extends State<CreateDriverPage> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _regions = {"Addis Ababa", "Nairobi"}.toList();

  String _selectedRegion;

  List<DropdownMenuItem<String>> _dropDownItem;

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

  onDropdownChange(String selectedRegion) {
    setState(() {
      String selectedRegionDocID = "";
      _selectedRegion = selectedRegion;
      routesLoaded = false;
      systemAccounts.forEach((element) {
        if (element.name == selectedRegion) {
          selectedRegionDocID = element.docID;
          systemAccountDocID = element.docID;
        }
      });
      DatabaseService().getMainRoutes(selectedRegionDocID).then((value) {
        setState(() {
          mainRoutes = value;
          checkBoxValues.clear();
          value.forEach((element) {
            checkBoxValues.add(false);
          });
          routesLoaded = true;
        });
      });
    });
  }

  var checkBoxValues = [];

  bool loaded = false;
  bool routesLoaded = false;

  List<SystemRequirementAccount> systemAccounts = [];
  List<SuperPath> mainRoutes = [];

  String name, systemAccountDocID, licenseNumber, bankAccount;
  String cspIdentifier;

  List<String> mainRouteDocIDs = [];

  @override
  void initState() {
    DatabaseService().getRegions().then((value) {
      systemAccounts.addAll(value);
      _regions.clear();
      value.forEach((element) {
        _regions.add(element.name);
      });
      _dropDownItem = buildDropDownItem(_regions);
      // print("LengDrop: " + _dropDownItem.length.toString());
      if (_dropDownItem.isNotEmpty) {
        _selectedRegion = _dropDownItem[0].value;
      }
      if (systemAccounts.isNotEmpty) {
        systemAccountDocID = systemAccounts[0].docID;
        DatabaseService().getMainRoutes(systemAccounts[0].docID).then((value) {
          setState(() {
            mainRoutes = value;
            checkBoxValues.clear();
            value.forEach((element) {
              checkBoxValues.add(false);
            });
            loaded = true;
            routesLoaded = true;
          });
        });
      } else {
        setState(() {
          loaded = true;
        });
      }
    });
    super.initState();
  }

  void logOut() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuthUi.instance()
          .logout()
          .then((value) => Navigator.pop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            leading: Icon(null),
            title: Text("Register a Driver"),
            centerTitle: true,
            actions: [
              IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          content: Text(
                            "Are you sure you want to Logout?",
                            style: TextStyle(fontSize: deviceWidth * 0.06),
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                logOut();
                                Navigator.pop(context);
                                widget.logOutStatus();
                              },
                              child: Text(
                                'Yes',
                                style: TextStyle(fontSize: deviceWidth * 0.06),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'No',
                                style: TextStyle(fontSize: deviceWidth * 0.06),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  })
            ],
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
                          Text(
                            "Create Driver Account",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.1,
                                fontWeight: FontWeight.w400),
                          ),
                          SizedBox(
                            height: deviceHeight * 0.025,
                          ),
                          TextFormField(
                            decoration:
                                textInputDecoration.copyWith(hintText: "Name"),
                            validator: (value) =>
                                // NEW
                                value.isEmpty || value.length > 40
                                    ? value.length > 30
                                        ? "Name length too long"
                                        : "Enter your name"
                                    : null,
                            //
                            onChanged: (value) {
                              setState(() {
                                name = value;
                              });
                            },
                          ),
                          SizedBox(
                            height: deviceHeight * 0.025,
                          ),
                          // TextFormField(
                          //   decoration: textInputDecoration.copyWith(
                          //       hintText: "Plate Number"),
                          //   validator: (value) => value.isEmpty
                          //       ? "Enter your plate number"
                          //       : null,
                          //   onChanged: (value) {
                          //     setState(() {
                          //       plateNumber = value;
                          //     });
                          //   },
                          //   // keyboardType: TextInputType.number,
                          // ),
                          // SizedBox(
                          //   height: deviceHeight * 0.025,
                          // ),
                          TextFormField(
                            decoration: textInputDecoration.copyWith(
                                hintText: "License Number"),
                            validator: (value) => value.isEmpty
                                ? "Enter your Licesnse Number"
                                : null,
                            onChanged: (value) {
                              setState(() {
                                licenseNumber = value;
                              });
                            },
                            // keyboardType: TextInputType.number,
                          ),
                          SizedBox(
                            height: deviceHeight * 0.025,
                          ),
                          TextFormField(
                            readOnly: true,
                            decoration: textInputDecoration.copyWith(
                                hintText: "Phone Number"),
                            // validator: (value) =>
                            //     (value.isEmpty || double.tryParse(value) == null)
                            //         ? "Enter your phone Number"
                            //         : null,
                            // onChanged: (value) {
                            //   setState(() {
                            //     // email = value;
                            //   });
                            // },
                            initialValue: widget.phoneNumber,
                            keyboardType: TextInputType.number,
                          ),
                          SizedBox(
                            height: deviceHeight * 0.025,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text("Region :",
                                    style: TextStyle(
                                        fontSize: deviceWidth * 0.08,
                                        fontWeight: FontWeight.w300)),
                              ),
                              Expanded(
                                  child: DropdownButton(
                                items: _dropDownItem,
                                style: TextStyle(
                                  fontSize: deviceWidth * 0.1,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w300,
                                ),
                                onChanged: onDropdownChange,
                                value: _selectedRegion,
                              )),
                            ],
                          ),
                          SizedBox(
                            height: deviceHeight * 0.025,
                          ),
                          TextFormField(
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
                                                  padding:
                                                      const EdgeInsets.all(8.0),
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
                                                                          mainRoutes[index]
                                                                              .destination)
                                                                      .length <
                                                                  20
                                                              ? (
                                                                  // mainRoutes[
                                                                  //           index]
                                                                  //       .startingLocation +
                                                                  //   " - " +
                                                                  mainRoutes[
                                                                          index]
                                                                      .destination)
                                                              : (
                                                                          // mainRoutes[index]
                                                                          //               .startingLocation +
                                                                          //           " - " +
                                                                          mainRoutes[index]
                                                                              .destination)
                                                                      .substring(
                                                                          0,
                                                                          20) +
                                                                  "...",
                                                          style: TextStyle(
                                                              color:
                                                                  checkBoxValues[
                                                                          index]
                                                                      ? Colors
                                                                          .white
                                                                      : Colors
                                                                          .black),
                                                        ),
                                                        tileColor: Colors.white,
                                                        selectedTileColor:
                                                            Colors.green,
                                                        checkColor:
                                                            Colors.white,
                                                        activeColor:
                                                            Colors.green,
                                                        selected:
                                                            checkBoxValues[
                                                                index],
                                                        value: checkBoxValues[
                                                            index],
                                                        onChanged: (value) {
                                                          setState(() {
                                                            checkBoxValues[
                                                                index] = value;
                                                          });
                                                        }),
                                                  ),
                                                );
                                              },
                                            ))
                                          : Loading()
                                      // Padding(
                                      //   padding: const EdgeInsets.all(8.0),
                                      //   child: Card(
                                      //     clipBehavior: Clip.hardEdge,
                                      //     elevation: 8,
                                      //     child: CheckboxListTile(
                                      //         controlAffinity:
                                      //             ListTileControlAffinity.leading,
                                      //         title: Text(
                                      //           "Mexico - 4 Kilo",
                                      //           style: TextStyle(
                                      //               color: checkBoxValues[1]
                                      //                   ? Colors.white
                                      //                   : Colors.black),
                                      //         ),
                                      //         tileColor: Colors.white,
                                      //         selectedTileColor: Colors.green,
                                      //         checkColor: Colors.white,
                                      //         activeColor: Colors.green,
                                      //         selected: checkBoxValues[1],
                                      //         value: checkBoxValues[1],
                                      //         onChanged: (value) {
                                      //           setState(() {
                                      //             checkBoxValues[1] = value;
                                      //           });
                                      //         }),
                                      //   ),
                                      // ),

                                      // Padding(
                                      //   padding: const EdgeInsets.all(8.0),
                                      //   child: Card(
                                      //     clipBehavior: Clip.hardEdge,
                                      //     elevation: 8,
                                      //     child: CheckboxListTile(
                                      //         controlAffinity:
                                      //             ListTileControlAffinity.leading,
                                      //         title: Text(
                                      //           "Piasa - Bole",
                                      //           style: TextStyle(
                                      //               color: checkBoxValues[2]
                                      //                   ? Colors.white
                                      //                   : Colors.black),
                                      //         ),
                                      //         tileColor: Colors.white,
                                      //         selectedTileColor: Colors.green,
                                      //         checkColor: Colors.white,
                                      //         activeColor: Colors.green,
                                      //         selected: checkBoxValues[2],
                                      //         value: checkBoxValues[2],
                                      //         onChanged: (value) {
                                      //           setState(() {
                                      //             checkBoxValues[2] = value;
                                      //           });
                                      //         }),
                                      //   ),
                                      // ),
                                    ]),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: deviceHeight * 0.025,
                          ),
                          // TextFormField(
                          //   decoration: textInputDecoration.copyWith(hintText: "Password"),
                          //   validator: (value) =>
                          //       (value.isEmpty || double.tryParse(value) == null)
                          //           ? "Enter password"
                          //           : null,
                          //   onChanged: (value) {
                          //     setState(() {
                          //       // email = value;
                          //     });
                          //   },
                          //   obscureText: true,
                          //   keyboardType: TextInputType.text,
                          // ),
                          // SizedBox(
                          //   height: deviceHeight * 0.025,
                          // ),
                          // TextFormField(
                          //   decoration:
                          //       textInputDecoration.copyWith(hintText: "Confirm Password"),
                          //   validator: (value) =>
                          //       (value.isEmpty || double.tryParse(value) == null)
                          //           ? (value.isEmpty)
                          //               ? "Enter password agian"
                          //               : "Password doesn't Match"
                          //           : null,
                          //   onChanged: (value) {
                          //     setState(() {
                          //       // email = value;
                          //     });
                          //   },
                          //   obscureText: true,
                          // ),
                          // SizedBox(
                          //   height: deviceHeight * 0.025,
                          // ),
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
                              onPressed: () {
                                mainRouteDocIDs.clear();
                                for (var i = 0;
                                    i < checkBoxValues.length;
                                    i++) {
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
                                  int cspID = int.parse(cspIdentifier);
                                  DatabaseService()
                                      .createDriver(
                                          name,
                                          widget.phoneNumber,
                                          widget.phoneID,
                                          systemAccountDocID,
                                          licenseNumber,
                                          bankAccount,
                                          cspID,
                                          mainRouteDocIDs)
                                      .then((value) {
                                    setState(() {
                                      loaded = true;
                                    });
                                    if (value != "false") {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => Wrapper(
                                                    phoneNumber:
                                                        widget.phoneNumber,
                                                    phoneID: widget.phoneID,
                                                    driverDocID: value,
                                                  )));
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content:
                                            Text("Failed To Create Driver"),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  });
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
                )),
    );
  }
}
