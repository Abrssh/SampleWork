import 'package:audio_record/Pages/DrawerPages/AccountPages/driverPage.dart';
import 'package:audio_record/Pages/DrawerPages/AccountPages/vehiclePage.dart';
import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  final String driverDocID;
  Account({this.driverDocID});
  @override
  _AccountState createState() => _AccountState();
}

class _AccountState extends State<Account> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;

    final _tabs = [
      VehiclePage(
        driverDocID: widget.driverDocID,
      ),
      DriverPage(
        driverDocID: widget.driverDocID,
      )
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(
              width: deviceWidth * 0.18,
            ),
            Text("Account")
          ],
        ),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: deviceHeight * 0.1,
        iconSize: deviceWidth * 0.08,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.local_taxi_rounded), label: "Vehicle"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Driver"),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
