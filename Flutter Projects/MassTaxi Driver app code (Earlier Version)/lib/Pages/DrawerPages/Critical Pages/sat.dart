import 'dart:async';
import 'dart:io';

import 'package:audio_record/Pages/DrawerPages/Critical%20Pages/vap.dart';
import 'package:audio_record/Service/cloudStorageServ.dart';
import 'package:audio_record/Service/databaseServ.dart';
// import 'package:audio_record/Shared/constant.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:audio_record/Widgets/listeningAnimation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:downloads_path_provider_28/downloads_path_provider_28.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:volume/volume.dart';

class SAT extends StatefulWidget {
  final double caliber;
  final String driverID, systemAccountID;
  SAT({this.caliber, this.driverID, this.systemAccountID});
  @override
  _SATState createState() => _SATState();
}

class _SATState extends State<SAT> {
  FlutterAudioQuery audioQuery = FlutterAudioQuery();
  // List<SongInfo> audios;
  String audioPath = "";
  AudioPlayer _audioPlayer = AudioPlayer();

  bool loaded = false;
  bool standardAudioExist = false;

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
  double oldSoundLevel = 0.0;
  bool pause = false;

  bool isCompromised = false;
  bool status = false;

  double lmz = 68, hmz = 92;

  // bool standardAudioDownloaded = false;

  final ValueNotifier<double> _soundLevel = ValueNotifier<double>(0);

  // final _formKey = GlobalKey<FormState>();
  // String cspIdentifier;

  Future getStandardAudio(String standardAudioName) async {
    DatabaseService()
        .getStandardAudiourl(widget.systemAccountID)
        .then((audioUrl) async {
      if (audioUrl != "f") {
        // print("audioUrl: " + audioUrl);
        Directory downDirectory =
            await DownloadsPathProvider.downloadsDirectory;
        List<String> urlSplit = audioUrl.split(".");
        String split2 = urlSplit[urlSplit.length - 1];
        List<String> fileFormat = split2.split("?");
        audioPath =
            downDirectory.path + "/" + standardAudioName + "." + fileFormat[0];
        bool fileExist = await File(audioPath).exists();
        if (fileExist) {
          _audioPlayer.play(audioPath);
          standardAudioExist = true;
          setState(() {
            loaded = true;
          });
        } else {
          // print("downloading...");
          CloudStorageService()
              .downloadAudio(audioUrl, "sat2761723156")
              .then((value) async {
            if (value) {
              fileExist = await File(audioPath).exists();
              if (fileExist) {
                _audioPlayer.play(audioPath);
                standardAudioExist = true;
              }
              setState(() {
                loaded = true;
              });
            }
          });
        }
      }
    });
  }

  void onData(NoiseReading noiseReading) {
    this.setState(() {
      if (!this._isRecording) {
        this._isRecording = true;
      }
    });
    setState(() {
      soundLevel = double.parse(noiseReading.maxDecibel.toString());
      oldSoundLevel = soundLevel;
      // _soundLevel.value = soundLevel;
      // double caliberCheck = caliber.abs();
      if (soundLevel > 30) {
        soundLevel += widget.caliber;
      }
      // print("Sound Level: " + soundLevel.toString());
      if (!pause && soundLevel.isFinite) {
        countner++;
        totalNoise += soundLevel;
        average = totalNoise / countner;
        // print("Noise : " + totalNoise.toStringAsPrecision(6));
      } else if (!pause && !soundLevel.isFinite) {
        isCompromised = true;
        // print("Is compromised : " + isCompromised.toString());
      }
      // print("Average: " + average.toString());
      _soundLevel.value = average;
      if (time >= 40 && !status) {
        // print("lmz: " + lmz.toString() + "hmz: " + hmz.toString());
        if (average >= lmz && average <= hmz) {
          status = true;
        }
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

  void retry() {
    if (_audioPlayer.state == PlayerState.COMPLETED) {
      _audioPlayer.play(audioPath);
    } else {
      _audioPlayer.seek(Duration(seconds: 0));
    }
    totalNoise = 0;
    countner = 0;
    average = 0;
    time = 0;
    pause = false;
    isCompromised = false;
    status = false;
  }

  int standardVolumeDecrease = 3;
  int maxVol = 0;

  Future<void> initAudioStreamType() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  getMaxVol() async {
    // get Max Volume
    maxVol = await Volume.getMaxVol;
    // print("Max Vol init : " + maxVol.toString());
    setVol(maxVol - standardVolumeDecrease);
  }

  setVol(int i) async {
    await Volume.setVol(i, showVolumeUI: ShowVolumeUI.HIDE);
    int vol = await Volume.getVol;
    print("Current Vol: " + vol.toString());
  }

  @override
  void initState() {
    initAudioStreamType();
    getMaxVol();
    DatabaseService().getTVforSat(widget.driverID).then((tv) {
      if (tv != null) {
        DatabaseService().getCarModelForSat(tv.carModelID).then((car) async {
          if (car != null) {
            lmz = car.lemz;
            hmz = car.hemz;
            await getStandardAudio("sat2761723156");
            _noiseMeter = new NoiseMeter(onError);
            start();
            a = Timer.periodic(Duration(seconds: 1), (timer) {
              if (_isRecording) {
                setState(() {
                  if (!pause) {
                    time++;
                    // print("Time: " + time.toString());
                  }
                });
              }
              // if(_audioPlayer.state == PlayerState.COMPLETED){
              // }
            });
          }
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;
    return Scaffold(
      appBar: AppBar(
        title: Text("SAT"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: deviceWidth,
          height: deviceHeight * 0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Retry If there is Sound Interference while Listening",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.07,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300),
                ),
              ),
              loaded
                  ? standardAudioExist
                      ? Listening()
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Standard Audio failed to download. Try again" +
                                " by re-entering this page.",
                            style: TextStyle(
                                fontSize: deviceWidth * 0.06,
                                color: Colors.red),
                          ),
                        )
                  : Loading(),
              Text(
                standardAudioExist ? "Listening..." : "No Audio",
                style: TextStyle(
                    fontSize: deviceWidth * 0.08, fontWeight: FontWeight.w500),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      iconSize: deviceWidth * 0.12,
                      icon: Icon(
                        Icons.refresh,
                      ),
                      onPressed: () {
                        if (_audioPlayer.state == PlayerState.COMPLETED) {
                          _audioPlayer.play(audioPath);
                        } else {
                          _audioPlayer.seek(Duration(seconds: 0));
                        }
                        totalNoise = 0;
                        countner = 0;
                        average = 0;
                        time = 0;
                        pause = false;
                        isCompromised = false;
                        status = false;
                      }),
                ],
              ),
              SizedBox(
                height: deviceHeight * 0.02,
              ),
              Text(
                "Status",
                style: TextStyle(
                    fontSize: deviceWidth * 0.08,
                    fontWeight: FontWeight.w400,
                    fontStyle: FontStyle.italic),
              ),
              Text(
                status
                    ? isCompromised
                        ? "COMPROMISED"
                        : "GOOD"
                    : isCompromised
                        ? "COMPROMISED"
                        : "INADEQUATE",
                style: TextStyle(
                    color: status ? Colors.green : Colors.orange,
                    fontSize: deviceWidth * 0.12,
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.normal),
              ),
              SizedBox(
                height: deviceHeight * 0.05,
              ),
              ElevatedButton(
                onPressed: loaded
                    ? () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => VAP(
                                      soundLevel: _soundLevel,
                                      retry: retry,
                                      lmz: lmz,
                                      hmz: hmz,
                                    )));
                      }
                    : null,
                child: Text(
                  "VAP",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.1, color: Colors.white),
                ),
              ),
              // SizedBox(
              //   height: deviceHeight * 0.025,
              // ),
              // Container(
              //   child: Form(
              //       key: _formKey,
              //       child: Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //         children: [
              //           Container(
              //             width: deviceWidth * 0.5,
              //             child: TextFormField(
              //               decoration: textInputDecoration.copyWith(
              //                   hintText: "CSP Identifier"),
              //               validator: (value) =>
              //                   (value.isEmpty || int.tryParse(value) == null)
              //                       ? "Enter CSP Identifier"
              //                       : null,
              //               onChanged: (value) {
              //                 setState(() {
              //                   cspIdentifier = value;
              //                 });
              //               },
              //               obscureText: true,
              //               keyboardType: TextInputType.number,
              //             ),
              //           ),
              //           ElevatedButton(
              //               onPressed: status
              //                   ? () {
              //                       if (_formKey.currentState.validate()) {}
              //                     }
              //                   : null,
              //               child: Text("Write DB"))
              //         ],
              //       )),
              // )
            ],
          ),
        ),
      ),
    );
  }
}
