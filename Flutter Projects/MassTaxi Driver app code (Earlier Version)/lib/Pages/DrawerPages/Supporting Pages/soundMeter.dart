import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:noise_meter/noise_meter.dart';

class SoundMeterPage extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<SoundMeterPage> {
  bool _isRecording = false;
  StreamSubscription<NoiseReading> _noiseSubscription;
  NoiseMeter _noiseMeter;
  int countner = 0;
  double soundLevel = 0.0;
  Timer a;
  int time = 0;
  // double perSec = 0;
  double totalNoise = 0.0;
  double average = 0.0;
  double caliber = 0.0;
  // double caliber60 = 0.0, caliber70 = 0.0;
  double oldSoundLevel = 0.0;
  bool pause = false;

  bool isCompromised = false;

  @override
  void initState() {
    super.initState();
    _noiseMeter = new NoiseMeter(onError);
    a = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isRecording) {
        setState(() {
          if (!pause) {
            time++;
          }
        });
      }
    });
  }

  void onData(NoiseReading noiseReading) {
    this.setState(() {
      if (!this._isRecording) {
        this._isRecording = true;
      }
    });
    // print(noiseReading.toString());
    setState(() {
      soundLevel = double.parse(noiseReading.maxDecibel.toString());
      oldSoundLevel = soundLevel;
      // double caliberCheck = caliber.abs();
      if (soundLevel > 30) {
        soundLevel += caliber;
        // print("abbr: " + soundLevel.toString());
      }

      if (!pause && soundLevel.isFinite) {
        countner++;
        totalNoise += soundLevel;
        average = totalNoise / countner;
        // print("Noise : " + totalNoise.toStringAsPrecision(6));
      } else if (!pause && !soundLevel.isFinite) {
        isCompromised = true;
        // print("Is compromised : " + isCompromised.toString());
      }
    });
  }

  void onError(PlatformException e) {
    print(e.toString());
    _isRecording = false;
  }

  void start() async {
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
      countner = 0;
      totalNoise = 0.0;
      average = 0.0;
      time = 0;
      pause = false;
    } catch (err) {
      print(err);
    }
  }

  void stop() async {
    try {
      if (_noiseSubscription != null) {
        _noiseSubscription.cancel();
        _noiseSubscription = null;
      }
      this.setState(() {
        this._isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  @override
  void dispose() {
    if (_isRecording) {
      stop();
    }
    if (a != null) {
      a.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    double deviceWidth = deviceSize.width;
    double deviceHeight = deviceSize.height;
    List<Widget> getContent() => <Widget>[
          Container(
              margin: EdgeInsets.all(25),
              child: Column(children: [
                Container(
                  child: Text(_isRecording ? "Mic: ON" : "Mic: OFF",
                      style: TextStyle(fontSize: 25, color: Colors.blue)),
                  margin: EdgeInsets.only(top: 20),
                )
              ])),
          Container(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Average : " +
                    average.toStringAsPrecision(3) +
                    "    SPL : " +
                    soundLevel.toStringAsPrecision(3) +
                    "    Time : " +
                    time.toString(),
                style: TextStyle(fontSize: deviceWidth * 0.12),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.refresh),
                iconSize: deviceWidth * 0.14,
                enableFeedback: true,
                onPressed: () {
                  totalNoise = 0;
                  countner = 0;
                  average = 0;
                  time = 0;
                  pause = false;
                  isCompromised = false;
                },
              ),
              IconButton(
                icon: pause ? Icon(Icons.play_arrow) : Icon(Icons.pause),
                iconSize: deviceWidth * 0.14,
                enableFeedback: true,
                onPressed: () {
                  if (pause) {
                    pause = false;
                  } else {
                    pause = true;
                  }
                },
              ),
              Text(
                "Old sound Level : " + oldSoundLevel.toStringAsPrecision(3),
                style: TextStyle(fontSize: deviceWidth * 0.05),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                height: deviceHeight * 0.01,
              ),
              Text(
                " caliber : " + caliber.toString(),
                style: TextStyle(fontSize: deviceWidth * 0.08),
              ),
              SizedBox(
                height: deviceHeight * 0.02,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        caliber += 0.5;
                      });
                    },
                    child: Text("Plus"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        caliber -= 0.5;
                      });
                    },
                    child: Text("Minus"),
                  ),
                ],
              ),
            ],
          ),
        ];
    return MaterialApp(
      home: Scaffold(
        body: Center(
            child: Column(
          children: [
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: getContent()),
          ],
        )),
        floatingActionButton: FloatingActionButton(
            backgroundColor: _isRecording ? Colors.red : Colors.green,
            onPressed: _isRecording ? stop : start,
            child: _isRecording ? Icon(Icons.stop) : Icon(Icons.mic)),
      ),
    );
  }
}
