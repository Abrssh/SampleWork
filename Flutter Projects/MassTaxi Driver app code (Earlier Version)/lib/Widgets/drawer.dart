import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/ads.dart';
import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/claimForFix.dart';
import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/osc.dart';
import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/penalities.dart';
import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/sat.dart';
import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/transactions.dart';
import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/trips.dart';
import 'package:audio_record/Pages/DrawerPages/Supporting%20Pages/soundMeter.dart';
import 'package:audio_record/Pages/DrawerPages/accounts.dart';
// import 'package:audio_record/Pages/DrawerPages/Supporting%20Pages/help.dart';
import 'package:audio_record/Pages/DrawerPages/Supporting%20Pages/newPath.dart';
import 'package:audio_record/Pages/DrawerPages/Supporting%20Pages/registerWaitingList.dart';
import 'package:audio_record/Pages/DrawerPages/Supporting%20Pages/reportFraud.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  String driverName = "Abrham",
      driverDocID,
      systemAccountId,
      phoneNumber,
      plateNumber;
  List<String> mainRoutes;
  final int allowedToServe;
  final double calibrationValue;
  double balance = 0, potentialBalance = 0, totalProfit = 0;

  MyDrawer(
      {this.driverName,
      this.driverDocID,
      this.balance,
      this.potentialBalance,
      this.totalProfit,
      this.mainRoutes,
      this.phoneNumber,
      this.plateNumber,
      this.allowedToServe,
      this.calibrationValue,
      this.systemAccountId});
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceWidth = deviceSize.width;
    return Drawer(
        child: ListView(
      children: [
        UserAccountsDrawerHeader(
          accountName: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Driver: "),
                  Text(
                    driverName.length < 12
                        ? driverName
                        : driverName.substring(0, 9) + "...",
                    style: TextStyle(fontSize: deviceWidth * 0.05),
                  ),
                ],
              ),
              Container(
                width: deviceWidth * 0.39,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text("Balance: "),
                    Text(
                      balance < 10000
                          ? balance.toStringAsFixed(1) + " \$"
                          : balance.toStringAsExponential(1) + " \$",
                      style: TextStyle(
                          fontSize: deviceWidth * 0.05,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            ],
          ),
          accountEmail: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("Potential Balance: "),
              SizedBox(
                width: deviceWidth * 0.025,
              ),
              Text(
                potentialBalance < 100000
                    ? potentialBalance.toStringAsFixed(2) + " \$"
                    : potentialBalance.toStringAsExponential(4) + " \$",
                style: TextStyle(
                    fontSize: deviceWidth * 0.07, fontWeight: FontWeight.w500),
              )
            ],
          ),
          currentAccountPicture: CircleAvatar(
            child: Icon(Icons.person, size: deviceWidth * 0.1),
          ),
        ),
        ListTile(
          leading: Icon(Icons.person),
          title: Text("Account"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Account(
                          driverDocID: driverDocID,
                        )));
          },
          trailing: Icon(Icons.edit),
        ),
        ListTile(
          leading: Icon(Icons.whatshot),
          title: Text("Ads"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AdAudioFiles(
                          mainRoutes: mainRoutes,
                          systemAccountId: systemAccountId,
                          driverID: driverDocID,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.account_balance),
          title: Text("Payments"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Transactions(
                          balanceIntheSystem: balance,
                          driverDocID: driverDocID,
                          totalProfit: totalProfit,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.map_outlined),
          title: Text("Trips"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Trips(
                          driverDocID: driverDocID,
                          allowedToServe: allowedToServe,
                          systemAccountID: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.surround_sound),
          title: Text("Optimistic Sound Check"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => OSC(
                          // adName: "Nigid Bank CBE Birr New Year Tele Birr",
                          driverID: driverDocID,
                          caliber: calibrationValue,
                          systemAccountID: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.scatter_plot),
          title: Text("Standard Audio Test"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SAT(
                          caliber: calibrationValue,
                          driverID: driverDocID,
                          systemAccountID: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.report_problem),
          title: Text("Claim For Fix"),
          onTap: plateNumber != ""
              ? () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ClaimForFix(
                                driverID: driverDocID,
                                systemAccountId: systemAccountId,
                                phoneNumber: phoneNumber,
                                plateNumber: plateNumber,
                              )));
                }
              : null,
        ),
        ListTile(
          leading: Icon(Icons.error),
          title: Text("Penalities"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Penalities(
                          driverDocID: driverDocID,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.mic),
          title: Text("Sound Meter"),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SoundMeterPage()));
          },
        ),
        ListTile(
          leading: Icon(Icons.add_road),
          title: Text("Report New Path"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewPath(
                          systemAccountId: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.book),
          title: Text("Register To Waiting List"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RegisterWaitingList(
                          systemAccountId: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.bug_report),
          title: Text("Report Fraud"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ReportFraud(
                          systemAccountID: systemAccountId,
                        )));
          },
        ),
        // ListTile(
        //   leading: Icon(Icons.help),
        //   title: Text("Help"),
        //   onTap: () {
        //     Navigator.push(
        //         context, MaterialPageRoute(builder: (context) => Help()));
        //   },
        // ),
      ],
    ));
  }
}
