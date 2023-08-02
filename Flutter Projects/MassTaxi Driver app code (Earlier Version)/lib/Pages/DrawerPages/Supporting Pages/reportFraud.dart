import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:flutter/material.dart';

class ReportFraud extends StatefulWidget {
  final String systemAccountID;
  ReportFraud({this.systemAccountID});
  @override
  _ReportFraudState createState() => _ReportFraudState();
}

class _ReportFraudState extends State<ReportFraud> {
  bool loading = false;
  String phoneNumber = "";

  @override
  void initState() {
    DatabaseService().getPhoneNumber(widget.systemAccountID).then((value) {
      phoneNumber = value;
      setState(() {
        loading = true;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    // final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: deviceWidth * 0.15,
            ),
            Text("Report Fraud")
          ],
        ),
      ),
      body: loading
          ? Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    "If you have any information on ways to decieve the system you can" +
                        " call us and get a reward if your information is useful in " +
                        "showing the vulnerability of the system",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: deviceWidth * 0.06,
                        fontWeight: FontWeight.w500,
                        wordSpacing: 5),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      "Phone Number ",
                      style: TextStyle(
                          fontSize: deviceWidth * 0.07,
                          fontWeight: FontWeight.w400),
                    ),
                    Text(
                      phoneNumber,
                      style: TextStyle(
                          fontSize: deviceWidth * 0.07,
                          fontWeight: FontWeight.w400),
                    ),
                  ],
                )
              ],
            )
          : Loading(),
    );
  }
}
