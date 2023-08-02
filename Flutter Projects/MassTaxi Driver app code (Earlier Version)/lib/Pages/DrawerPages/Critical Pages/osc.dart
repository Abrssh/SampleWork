import 'dart:async';

import 'package:audio_record/Models/carModel.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:audio_record/Widgets/listeningAnimation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:volume/volume.dart';

class OSC extends StatefulWidget {
  final String driverID, systemAccountID;
  final double caliber;
  OSC({this.driverID, this.caliber, this.systemAccountID});

  @override
  _OSCState createState() => _OSCState();
}

class _OSCState extends State<OSC> {
  final List<String> _ads = [];
  final List<String> _uniqueNames = [];
  final List<String> _docIds = [];
  final List<bool> _adServedList = [];

  List<DropdownMenuItem<String>> _adItems;

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

  String _selectedAd, _selectedtvAdDocID;
  int _selectedIndex = 0;

  onSelectedAdChange(String selectedAd) {
    setState(() {
      _selectedAd = selectedAd;
      int uniqueNameIndex = 0;
      for (var i = 0; i < _ads.length; i++) {
        if (selectedAd == _ads[i]) {
          uniqueNameIndex = i;
          break;
        }
      }
      _selectedtvAdDocID = _docIds[uniqueNameIndex];
      _selectedIndex = uniqueNameIndex;
      getAdAudio(_uniqueNames[uniqueNameIndex]);
    });
  }

  FlutterAudioQuery audioQuery = FlutterAudioQuery();
  List<SongInfo> audios;
  AudioPlayer _audioPlayer = AudioPlayer();

  bool loaded = false;
  bool autoOn = true, finished = false;

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
  double autoPreviousAverage = 0;

  CarModel carModel;
  bool soundLevelValid = false, noAdTobePreProcessed = false;

  getAdAudio(String adName) async {
    audios = await audioQuery.searchSongs(query: adName);
    if (!loaded) {
      loaded = true;
    }
    _audioPlayer.play(audios[0].filePath);
    totalNoise = 0;
    countner = 0;
    average = 0;
    time = 0;
    pause = false;
    isCompromised = false;
    finished = false;
    autoPreviousAverage = 0;
    standardVolumeDecrease = 3;
    setVol(maxVol - standardVolumeDecrease);
    setState(() {});
  }

  void onData(NoiseReading noiseReading) {
    // this.setState(() {
    if (!this._isRecording) {
      this._isRecording = true;
    }
    // });
    // print(noiseReading.toString());
    // setState(() {
    soundLevel = double.parse(noiseReading.maxDecibel.toString());
    oldSoundLevel = soundLevel;
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
    // });
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
    // int vol = await Volume.getVol;
    // print("Current Vol: " + vol.toString());
  }

  @override
  void initState() {
    initAudioStreamType();
    getMaxVol();
    DatabaseService().getCarForOsc(widget.driverID).then((car) {
      if (car != null) {
        carModel = car;
        DatabaseService().getTvAds(widget.driverID).then((value) {
          if (value.isNotEmpty) {
            for (var item in value) {
              _ads.add(item.adName);
              _uniqueNames.add(item.uniqueName);
              _docIds.add(item.docID);
              _adServedList.add(false);
            }
            _adItems = buildDropDownItem(_ads);
            _selectedAd = _adItems[0].value;
            _selectedtvAdDocID = _docIds[0];
            // print("Selectd : " + _selectedAd);
            getAdAudio(_uniqueNames[0]);
            _noiseMeter = new NoiseMeter(onError);
            start();
            a = Timer.periodic(Duration(seconds: 1), (timer) {
              if (_isRecording) {
                // setState(() {
                if (!pause) {
                  time++;
                  // print("Time: " + time.toString());
                }
                // });
              }
            });
            _audioPlayer.onPlayerCompletion.listen((event) {
              // print("Ad finished => Avg: " + average.toString());
              if (autoPreviousAverage != 0) {
                double difference = (average - autoPreviousAverage).abs();
                if (difference > 1) {
                  autoOn = true;
                }
              }
              if (average >= carModel.lemz || standardVolumeDecrease == 0) {
                soundLevelValid = true;
              } else {
                soundLevelValid = false;
              }
              if (soundLevelValid) {
                if (autoOn || isCompromised) {
                  _audioPlayer.play(audios[0].filePath);
                  setState(() {
                    autoPreviousAverage = isCompromised ? 0 : average;
                    autoOn = isCompromised ? true : false;
                    totalNoise = 0;
                    countner = 0;
                    average = 0;
                    time = 0;
                    pause = false;
                    isCompromised = false;
                    finished = false;
                  });
                } else {
                  bool loud = false;
                  if (average > carModel.hemz) {
                    loud = true;
                    // the reason we just mark it loud instead of retrying
                    // is because there might be rare situations in which
                    // decreasing the volume by one will make it lower than
                    // lemz which will cause in flip floping trying to get
                    // average sound level into the measurment zone that
                    // will go on endlessly
                  }

                  // print("Write Average : " + average.toString());
                  bool silent = false;
                  // bool loud = false;
                  if (average < carModel.lemz) {
                    silent = true;
                  }
                  // make sure that already checked
                  // ADs table is not updated again
                  if (!_adServedList[_selectedIndex]) {
                    DatabaseService()
                        .updateTvAd(
                            _selectedtvAdDocID,
                            average,
                            standardVolumeDecrease,
                            silent,
                            loud,
                            widget.systemAccountID)
                        .then((value) {
                      if (value) {
                        // write was successfull
                        finished = true;
                        _adServedList[_selectedIndex] = true;
                        // goesTo the next Ad
                        if (_selectedIndex < _ads.length - 1) {
                          _selectedIndex++;
                          _selectedAd = _ads[_selectedIndex];
                          _selectedtvAdDocID = _docIds[_selectedIndex];
                          getAdAudio(_uniqueNames[_selectedIndex]);
                          autoOn = true;
                        }
                      } else {
                        // restart the process for the selected ad
                        // if the write to the database fails
                        getAdAudio(_uniqueNames[_selectedIndex]);
                      }
                      setState(() {});
                    });
                  } else {
                    setState(() {
                      finished = true;
                    });
                  }
                }
              } else {
                if (standardVolumeDecrease > 0) {
                  standardVolumeDecrease--;
                  setVol(maxVol - standardVolumeDecrease);
                }
                _audioPlayer.play(audios[0].filePath);
                setState(() {
                  // autoPreviousAverage = average;
                  // autoOn = false;
                  // _audioPlayer.seek(Duration(seconds: 0));
                  totalNoise = 0;
                  countner = 0;
                  average = 0;
                  time = 0;
                  pause = false;
                  isCompromised = false;
                });
              }
            });
          } else {
            setState(() {
              noAdTobePreProcessed = true;
              loaded = true;
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
        title: Text("OSC"),
        centerTitle: true,
        // title: widget.adName.length > 23
        //     ? Text("Ad: " + widget.adName.substring(0, 23) + "...")
        //     : Text("Ad: " + widget.adName),
      ),
      body: loaded
          ? noAdTobePreProcessed
              ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Center(
                    child: Text(
                      "Every Ad downloaded is pre-processed. Or wait until ads" +
                          " downloaded becomes processed. You must always go to Ads" +
                          " page and make sure its processed other wise it won't " +
                          "show up in this Page.",
                      style: TextStyle(
                          fontSize: deviceWidth * 0.07,
                          fontWeight: FontWeight.w300),
                    ),
                  ),
                )
              : Container(
                  width: deviceWidth,
                  height: deviceHeight * 0.88,
                  child: Column(
                    children: [
                      SizedBox(
                        height: deviceHeight * 0.025,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text("AD Playing :",
                                  style: TextStyle(
                                      fontSize: deviceWidth * 0.08,
                                      fontWeight: FontWeight.w300)),
                            ),
                            Expanded(
                                child: DropdownButton(
                              items: _adItems,
                              style: TextStyle(
                                fontSize: deviceWidth * 0.1,
                                color: Colors.black,
                                fontWeight: FontWeight.w300,
                              ),
                              onChanged: onSelectedAdChange,
                              value: _selectedAd,
                            )),
                          ],
                        ),
                      ),
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
                          ? finished
                              ? Icon(
                                  Icons.done_outline_rounded,
                                  color: Colors.green,
                                  size: deviceWidth * 0.1,
                                )
                              : _adServedList[_selectedIndex]
                                  ? Icon(
                                      Icons.done_all_rounded,
                                      color: Colors.green,
                                      size: deviceWidth * 0.1,
                                    )
                                  : Listening()
                          : Loading(),
                      Text(
                        finished || _adServedList[_selectedIndex]
                            ? "AD Checked"
                            : "Listening...",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w500),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: deviceWidth * 0.28,
                          ),
                          IconButton(
                              iconSize: deviceWidth * 0.12,
                              icon: Icon(
                                Icons.refresh,
                              ),
                              onPressed: () {
                                _audioPlayer.seek(Duration(seconds: 0));
                                totalNoise = 0;
                                countner = 0;
                                average = 0;
                                time = 0;
                                pause = false;
                                isCompromised = false;
                              }),
                          SizedBox(
                            width: deviceWidth * 0.1,
                          ),
                          // IconButton(
                          //     iconSize: deviceWidth * 0.12,
                          //     icon: Icon(
                          //       Icons.stop,
                          //     ),
                          //     onPressed: () {}),
                          SizedBox(
                            width: deviceWidth * 0.07,
                          ),
                          ElevatedButton(
                              onPressed: autoOn
                                  ? () {
                                      setState(() {
                                        autoOn = false;
                                      });
                                    }
                                  : () {
                                      setState(() {
                                        autoOn = true;
                                      });
                                    },
                              child: Text(
                                autoOn ? "Auto off" : "Auto on",
                                style: TextStyle(
                                  fontSize: deviceWidth * 0.05,
                                  fontWeight: FontWeight.w400,
                                ),
                              ))
                        ],
                      ),
                      SizedBox(
                        height: deviceHeight * 0.03,
                      ),
                      Text(
                        "Status",
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.italic),
                      ),
                      // this becomes done when the value is written to the
                      // database
                      Text(
                        finished
                            ? "DONE"
                            : isCompromised
                                ? "Was Compromised"
                                : "On Going",
                        style: TextStyle(
                            color: finished ? Colors.green : Colors.orange,
                            fontSize: deviceWidth * 0.12,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.normal),
                      )
                    ],
                  ),
                )
          : Loading(),
    );
  }
}
