import 'package:flutter/material.dart';

class VAP extends StatefulWidget {
  final ValueNotifier<double> soundLevel;
  final Function retry;
  final double lmz, hmz;
  VAP({this.soundLevel, this.retry, this.lmz, this.hmz});
  @override
  _VAPState createState() => _VAPState();
}

class _VAPState extends State<VAP> {
  List<Color> _colors = [Colors.blue, Colors.orange, Colors.green, Colors.red];
  List<String> volumeStatus = ["Very Low", "Low", "Perfect!", "Too Loud"];
  int colorIndex = 0;

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Volume Adjustment Process"),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Adjust Your Speaker Volume until the Text becomes Green",
              style: TextStyle(
                fontSize: deviceWidth * 0.08,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text("Sound Level (dB):",
                    style: TextStyle(
                        fontSize: deviceWidth * 0.07,
                        fontStyle: FontStyle.normal,
                        fontWeight: FontWeight.w300)),
                ValueListenableBuilder(
                    valueListenable: widget.soundLevel,
                    builder:
                        (BuildContext context, double value, Widget child) {
                      if (value < widget.lmz - 8) {
                        colorIndex = 0;
                      } else if (value < widget.lmz) {
                        colorIndex = 1;
                      } else if (value < widget.hmz) {
                        colorIndex = 2;
                      } else {
                        colorIndex = 3;
                      }
                      // setState(() {});
                      return Text(value.toStringAsFixed(2),
                          style: TextStyle(
                              fontSize: deviceWidth * 0.16,
                              color: _colors[colorIndex],
                              fontStyle: FontStyle.normal,
                              fontWeight: FontWeight.bold));
                    }),
              ],
            ),
          ),
          ValueListenableBuilder(
              valueListenable: widget.soundLevel,
              builder: (BuildContext context, double value, Widget child) {
                if (value < widget.lmz - 8) {
                  colorIndex = 0;
                } else if (value < widget.lmz) {
                  colorIndex = 1;
                } else if (value < widget.hmz) {
                  colorIndex = 2;
                } else {
                  colorIndex = 3;
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("External Volume:",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.07,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w300)),
                    SizedBox(
                      width: deviceWidth * 0.03,
                    ),
                    Text(volumeStatus[colorIndex],
                        style: TextStyle(
                            color: _colors[colorIndex],
                            fontSize: deviceWidth * 0.07,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w300))
                  ],
                );
              }),
          SizedBox(
            height: deviceHeight * 0.02,
          ),
          Row(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: deviceWidth * 0.385,
              ),
              IconButton(
                  iconSize: deviceWidth * 0.2,
                  icon: Icon(
                    Icons.refresh,
                    // size: deviceWidth * 0.2,
                  ),
                  onPressed: () {
                    widget.retry();
                  })
            ],
          ),
          SizedBox(
            height: deviceHeight * 0.06,
          ),
          Text(
            "Click this button when you change speaker volume",
            style: TextStyle(fontSize: deviceWidth * 0.04),
          ),
        ],
      ),
    );
  }
}
