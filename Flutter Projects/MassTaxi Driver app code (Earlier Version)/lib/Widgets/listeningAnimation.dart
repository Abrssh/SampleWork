import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Listening extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    // var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;
    return Container(
      child: Center(
        child: SpinKitRipple(
          size: deviceHeight * 0.3,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}
