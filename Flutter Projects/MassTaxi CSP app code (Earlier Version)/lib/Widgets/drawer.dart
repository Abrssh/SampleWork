import 'package:csp_app/Pages/Drawer%20Pages/Path%20Creation/prepPage.dart';
import 'package:csp_app/Pages/Drawer%20Pages/Testing/testing_page.dart';
import 'package:csp_app/Pages/Drawer%20Pages/bookedSpots.dart';
import 'package:csp_app/Pages/Drawer%20Pages/newPathReport.dart';
import 'package:csp_app/Pages/Drawer%20Pages/reportedIssues.dart';
import 'package:csp_app/Pages/Drawer%20Pages/soundMeter.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  final String cspName;
  final int cspIdendtifier;
  final String cspID;
  final String systemAccountId;
  MyDrawer(
      {this.cspName, this.cspIdendtifier, this.cspID, this.systemAccountId});
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceWidth = deviceSize.width;
    return Drawer(
        child: ListView(
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(
            "CSP Name:  " + cspName,
            style: TextStyle(fontSize: deviceWidth * 0.045),
          ),
          accountEmail: Text(
            "CSP Identifier:  " + cspIdendtifier.toString(),
            style: TextStyle(fontSize: deviceWidth * 0.05),
          ),
          currentAccountPicture: CircleAvatar(
            child: Icon(Icons.person, size: deviceWidth * 0.1),
          ),
        ),
        ListTile(
          leading: Icon(Icons.add_road),
          title: Text("Add Path"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => PathPreparation(
                          systemAccountId: systemAccountId,
                          cspID: cspID,
                        ),
                    settings: RouteSettings(name: "PathPrep")));
          },
        ),
        ListTile(
          leading: Icon(Icons.report_problem),
          title: Text("Reported Issues"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ReportedIssues(
                          cspID: cspID,
                          systemAccountId: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.new_releases),
          title: Text("New Path Reports"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewPathReports(
                          systemAccountId: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.schedule),
          title: Text("Booked Spots"),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => BookedSpots(
                          cspID: cspID,
                          systemAccountId: systemAccountId,
                        )));
          },
        ),
        ListTile(
          leading: Icon(Icons.surround_sound),
          title: Text("Noise Meter Test"),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => NoiseMeterTest()));
          },
        ),
        ListTile(
          leading: Icon(Icons.mic),
          title: Text("Sound Meter"),
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => SoundMeterPage()));
          },
        )
      ],
    ));
  }
}
