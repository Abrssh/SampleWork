import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class ClaimForFix extends StatefulWidget {
  final String driverID, phoneNumber, plateNumber, systemAccountId;
  ClaimForFix(
      {this.driverID,
      this.phoneNumber,
      this.plateNumber,
      this.systemAccountId});
  @override
  _ClaimForFixState createState() => _ClaimForFixState();
}

class _ClaimForFixState extends State<ClaimForFix> {
  final List<String> _claims = {
    "Sound Setup Failure",
    "Change Smart Phone",
    "Taxi Interior Changed",
    "Sound Setup Upgrade",
    "Change Of Taxi"
  }.toList();

  String _selectedClaim;

  List<DropdownMenuItem<String>> _dropDownItem;

  bool loaded = false;
  bool urgentclaimForFixSent = false, claimForFixScheduled = false;
  // non urgent claim for fix can be replaced but old claim for fix
  // must be deleted if not scheduled

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

  onDropdownChange(String selectedClaim) {
    setState(() {
      _selectedClaim = selectedClaim;
    });
  }

  @override
  void initState() {
    DatabaseService().getFixClaim(widget.driverID).then((value) {
      if (value != null) {
        if (value.scheduled) {
          DatabaseService().solutionForInactiveCSP(value.docID).then((value) {
            if (value == 0) {
              claimForFixScheduled = true;
            } else if (value == 2) {
              Navigator.pop(context);
            }
          });
        }
        if (value.urgent) {
          urgentclaimForFixSent = true;
        }
      }
      setState(() {
        loaded = true;
      });
    });
    _dropDownItem = buildDropDownItem(_claims);
    // print("LengDrop: " + _dropDownItem.length.toString());
    _selectedClaim = _dropDownItem[0].value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    return Scaffold(
        appBar: AppBar(
          title: Text("Claim For Fix"),
          centerTitle: true,
        ),
        body: loaded
            ? (urgentclaimForFixSent || claimForFixScheduled)
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        (urgentclaimForFixSent)
                            ? "URGENT CLAIM FOR FIX HAS ALREADY BEEN SENT"
                            : "YOUR CLAIM FOR FIX HAS BEEN SCHEDULED",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.06,
                            fontWeight: FontWeight.w300),
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Claim Type",
                            style: TextStyle(
                              fontSize: deviceWidth * 0.1,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      DropdownButton(
                        items: _dropDownItem,
                        style: TextStyle(
                          fontSize: deviceWidth * 0.1,
                          color: Colors.black,
                          fontWeight: FontWeight.w300,
                        ),
                        onChanged: onDropdownChange,
                        value: _selectedClaim,
                      ),
                      SizedBox(
                        height: deviceHeight * 0.01,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              loaded = false;
                            });
                            String type = "";
                            bool urgency = false;
                            if (_selectedClaim == "Sound Setup Failure") {
                              type = "SSF";
                              urgency = true;
                            } else if (_selectedClaim == "Change Smart Phone") {
                              type = "CSP";
                              urgency = false;
                            } else if (_selectedClaim ==
                                "Taxi Interior Changed") {
                              type = "TIC";
                              urgency = true;
                            } else if (_selectedClaim ==
                                "Sound Setup Upgrade") {
                              type = "SSU";
                              urgency = false;
                            } else {
                              type = "COT";
                              urgency = true;
                            }
                            DatabaseService()
                                .createFixClaim(
                                    widget.driverID,
                                    type,
                                    urgency,
                                    widget.plateNumber,
                                    widget.phoneNumber,
                                    widget.systemAccountId)
                                .then((value) {
                              setState(() {
                                loaded = true;
                              });
                              if (value) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                      "Claim for Fix has been sent Successfully."),
                                  backgroundColor: Colors.green,
                                ));
                                // Useful because code that checks whether user can
                                // send a claim for fix is found in init state
                                Navigator.pop(context);
                                Navigator.pop(context);
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content:
                                      Text("Sending Claim for Fix has failed."),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            });
                          },
                          child: Text(
                            "SEND",
                            style: TextStyle(
                              fontSize: deviceWidth * 0.1,
                            ),
                          ))
                    ],
                  )
            : Center(
                child: Loading(),
              ));
  }
}
