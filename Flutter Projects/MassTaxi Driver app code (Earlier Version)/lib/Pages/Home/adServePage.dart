import 'dart:async';
import 'package:audio_record/Classes/location_data.dart';
import 'package:audio_record/Classes/recorded_data.dart';
import 'package:audio_record/Pages/Home/trackPlayer.dart';
import 'package:flutter_background_location/flutter_background_location.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:volume/volume.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';

class AdServePage extends StatefulWidget {
  // final Function toggleView;
  final int numberOfAds;
  final int adBreakNo;
  final double caliber;

  final Map<String, int> adVolumes;
  AdServePage({
    this.numberOfAds,
    this.adBreakNo,
    this.adVolumes,
    this.caliber,
  });
  @override
  _AdServePageState createState() => _AdServePageState();
}

class _AdServePageState extends State<AdServePage> {
  StreamSubscription playingSubscription,
      currentMediaSubscription,
      noiseSubscription,
      durationSubscription;
  NoiseMeter noiseMeter;
  bool playing = false;
  MediaItem currentlyPlaying;
  String prevSong;
  int adLengthMinute = 0, adLengthSecond = 0;
  int currentMinute = 0, currentSecond = 0;
  int adPlayed = 0;
  int adCompleted = 0;
  double distanceleft = 0;
  bool runOnce = false;
  bool loaded = false;
  bool silencetime = false;
  LocationData nft;
  int maxVol = 0;
  Timer _timer;
  int counterTimer = 0;
  bool isRecording = false;
  double soundLevel = 0.0;
  double oldSoundLevel = 0.0;
  double caliber = 0.0;
  double totalStTimeVoice = 0.0;
  int totalStTimeVoiceNo = 0;
  double totalAdTimeVoice = 0.0;
  int totalAdTimeVoiceNo = 0;
  double totalPrevAdTimeVoice = 0.0;
  int totalPrevAdTimeVoiceNo = 0;
  bool isCompromised = false;

  @override
  void initState() {
    caliber = widget.caliber;
    // Starts Location Service
    //FlutterBackgroundLocation.startLocationService();

    // Activates the Listener for Location Updates
    FlutterBackgroundLocation.getLocationUpdates((location) {
      // Update the State of the current location object
      setState(() {
        nft = LocationData.withAccuracy(
            latitude: location.latitude,
            longitude: location.longitude,
            speed: location.speed,
            accuracy: location.accuracy);
      });
      // print("SAVE ADD: " +
      //     widget.adBreakNo.toString() +
      //     "-" +
      //     currentlyPlaying.title +
      //     "-" +
      //     prevSong);
      if (playing) {
        String nm = "AD#*#" + TrackPlayer.adCounter.toString() + "#*#";
        if (currentlyPlaying.title == prevSong) {
          nm += TrackPlayer.adCounter.toString() + "#*#";
        } else {
          nm += (TrackPlayer.adCounter - 1).toString() + "#*#";
        }
        nm += widget.adBreakNo.toString() + "#*#";
        nm += (adPlayed + 1).toString() + "#*#";
        nm += currentlyPlaying.title + "#*#";
        nm += prevSong;
        print("NAME: " + nm);
        LocationData adDataToBeSaved = LocationData.forAD(
            latitude: nft.latitude,
            longitude: nft.longitude,
            name: nm,
            speed: nft.speed,
            accuracy: nft.accuracy,
            timestamp: nft.timestamp);
        //LocationData.saveProgress(adDataToBeSaved).then((value) => {});
        LocationData.checkRouteEnd(currentLocation: this.nft).then((ve) {
          this.setState(() {
            distanceleft = ve;
          });
          LocationData.checkADStop(currentLocation: this.nft)
              .then((value) async {
            if (value) {
              //Add the follow up here
              AudioService.customAction("stopAD");
            } else {
              LocationData.saveProgress(adDataToBeSaved).then((value) {
                // print("Progress Saved");
              });
            }
          });
        });
      } else {
        LocationData.saveProgress(this.nft).then((value) {
          //print("Progress Saved");
        });
      }
      // else {
      //   LocationData.checkADStop(currentLocation: this.nft).then((value) async {
      //     if (value) {
      //       //Add the follow up here
      //       AudioService.customAction("stopAD");
      //     } else {
      //       LocationData.saveProgress(this.nft).then((value) {
      //         print("Progress Saved");
      //       });
      //     }
      //   });
      // }
    });

    // Initialize Noise Meter
    noiseMeter = new NoiseMeter((e) {
      setState(() {
        isRecording = false;
      });
      print("ERROR NOISE INIT: " + e.toString());
    });

    if (!isRecording) {
      //print("SAVED RECORDING");
      startRecording();
    }

    super.initState();
    initAudioStreamType();
    getMaxVol();
  }

  @override
  void dispose() {
    playingSubscription.cancel();
    currentMediaSubscription.cancel();
    durationSubscription.cancel();
    //FlutterBackgroundLocation.stopLocationService();
    print("status stopped track player location");
    isRecording = false;
    if (noiseSubscription != null) {
      noiseSubscription.cancel();
    }
    // this sets the volume to the standard level
    setVol(maxVol - 3);
    if (_timer != null) {
      _timer.cancel();
    }
    super.dispose();
  }

  Future<void> initAudioStreamType() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  getMaxVol() async {
    // get Max Volume
    maxVol = await Volume.getMaxVol;
    // print("Max Vol init : " + maxVol.toString());
  }

  setVol(int i) async {
    await Volume.setVol(i, showVolumeUI: ShowVolumeUI.HIDE);
    int vol = await Volume.getVol;
    print("Current Vol: " + vol.toString());
  }

  // Start Recording
  void startRecording() async {
    try {
      setState(() {
        isRecording = true;
      });
      noiseSubscription = noiseMeter.noiseStream.listen(onData);
      print("NOISE SUB: " + noiseSubscription.toString());
    } catch (err) {
      setState(() {
        isRecording = false;
      });
      print("ERROR NOISE SUB: " + err.toString());
    }
  }

  // On Data
  void onData(NoiseReading noiseReading) {
    //print("RECORD : " + isRecording.toString());
    //showSnack(message: "${this.isRecording}", context: context);

    if (isRecording &&
        double.parse(noiseReading.maxDecibel.toString()).isFinite) {
      setState(() {
        soundLevel = double.parse(noiseReading.maxDecibel.toString());
        soundLevel += caliber;
        // print("RECORDED SOUND LEVEL : $soundLevel");
        // oldSoundLevel = soundLevel;
      });

      if (soundLevel < 40) {
        // print("GOT ONE ----- RECORDED SOUND LEVEL : $soundLevel");
        isCompromised = true;
      }

      if (playing) {
        // Record it anyway
        try {
          setState(() {
            totalPrevAdTimeVoice += soundLevel;
            totalPrevAdTimeVoiceNo++;
          });
          // print("totalPrevAdTimeVoice: " +
          //     totalPrevAdTimeVoice.toString() +
          //     ", totalPrevAdTimeVoiceNo: " +
          //     totalPrevAdTimeVoiceNo.toString());
        } catch (e) {
          print("Prev Volume Error: " + e.toString());
        }

        try {
          // If Prev Adv == Adv
          if (prevSong != currentlyPlaying.title) {
            setState(() {
              totalAdTimeVoice += soundLevel;
              totalAdTimeVoiceNo++;
            });
          }
          // print("Sound AD Recorded " +
          //     (totalPrevAdTimeVoice.toString()) +
          //     " - " +
          //     totalPrevAdTimeVoiceNo.toString());
        } catch (e) {
          print("Final Volume Error: " + e.toString());
        }
      } else {
        // If the status is on Silent Time
        if (silencetime) {
          try {
            setState(() {
              totalStTimeVoice += soundLevel;
              totalStTimeVoiceNo++;
            });
            print("status silencetime increments : " +
                totalStTimeVoiceNo.toString());

            // print("Sound Silence Recorded " +
            //     (totalStTimeVoice.toString()) +
            //     " - " +
            //     totalStTimeVoiceNo.toString());
          } catch (e) {
            print("Silence Time Volume Error: " + e.toString());
          }
        }
      }
    } else if (!noiseReading.maxDecibel.isFinite && isRecording) {
      isCompromised = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    if (!runOnce) {
      //FlutterBackgroundLocation.startLocationService();
      playingSubscription =
          AudioService.playbackStateStream.listen((PlaybackState state) {
        if (this.mounted) {
          setState(() {
            if (state.processingState == AudioProcessingState.skippingToNext) {
              // this is only used for ui purpose so its fine
              // it wont add the last Ad of the Ad brake which at
              // the time this page will be poped
              print("PROCESSING STATUS SKIPPED "
                  // +
                  //     widget.adBreakNo.toString() +
                  //     "-" +
                  //     (adPlayed + 1).toString() +
                  //     "-" +
                  //     silencetime.toString() +
                  //     "-" +
                  //     totalStTimeVoiceNo.toString()
                  );

              adPlayed++;

              print("Saved ST-Recording " +
                  totalStTimeVoiceNo.toString() +
                  " " +
                  widget.adBreakNo.toString() +
                  "-" +
                  adPlayed.toString() +
                  "-" +
                  prevSong);

              if (totalStTimeVoiceNo > 0) {
                String id = (TrackPlayer.adCounter - 1).toString() + "#*#";
                if (currentlyPlaying.title == prevSong) {
                  id += (TrackPlayer.adCounter - 1).toString() + "#*#";
                } else {
                  id += (TrackPlayer.adCounter - 2).toString() + "#*#";
                }
                id += widget.adBreakNo.toString() + "#*#";
                id += (adPlayed + 1).toString() + "#*#";
                id += prevSong;
                RecordedData.saveAverage(RecordedData(
                        name: "ST",
                        id: id,
                        average: isCompromised
                            ? -1
                            : totalStTimeVoice / totalStTimeVoiceNo))
                    .then(
                        (value) => {print("SILENCE DDD: " + value.toString())});
              }
              setState(() {
                totalStTimeVoice = 0;
                totalStTimeVoiceNo = 0;
                silencetime = false;
              });
            }
            if (state.processingState == AudioProcessingState.completed) {
              adCompleted++;
              print("PROCESSING STATUS COMPLETED $adPlayed : $prevSong"
                  // +
                  //     widget.adBreakNo.toString() +
                  //     "-" +
                  //     (adPlayed + 1).toString() +
                  //     "-" +
                  //     silencetime.toString() +
                  //     "-" +
                  //     totalStTimeVoiceNo.toString()
                  );
              //adPlayed < widget.numberOfAds - 1
              if (adCompleted <= widget.numberOfAds) {
                TrackPlayer.adCounter++;
                if (totalPrevAdTimeVoiceNo > 0) {
                  String id = (TrackPlayer.adCounter - 1).toString() + "#*#";
                  if (currentlyPlaying.title == prevSong) {
                    id += (TrackPlayer.adCounter - 1).toString() + "#*#";
                  } else {
                    id += (TrackPlayer.adCounter - 2).toString() + "#*#";
                  }
                  id += widget.adBreakNo.toString() + "#*#";
                  id += (adPlayed + 1).toString() + "#*#";
                  id += prevSong;
                  // (TrackPlayer.adCounter - 1).toString() +
                  //                     "-" +
                  //                     currentlyPlaying.title ==
                  //                 prevSong
                  //             ? TrackPlayer.adCounter.toString()
                  //             : (TrackPlayer.adCounter - 1).toString() +
                  //                 "-" +
                  //                 widget.adBreakNo.toString() +
                  //                 "-" +
                  //                 (adPlayed + 1).toString() +
                  //                 "-" +
                  //                 prevSong
                  RecordedData.saveAverage(RecordedData(
                          name: "AD",
                          id: id,
                          average: isCompromised
                              ? -1
                              : totalPrevAdTimeVoice / totalPrevAdTimeVoiceNo))
                      .then((value) => null);
                  setState(() {
                    totalPrevAdTimeVoice = totalAdTimeVoice;
                    totalPrevAdTimeVoiceNo = totalAdTimeVoiceNo;
                    totalAdTimeVoice = 0;
                    totalAdTimeVoiceNo = 0;
                  });
                }
                if (widget.numberOfAds - adPlayed != 1) {
                  setState(() {
                    silencetime = true;
                  });
                }
              }
            }
            playing = state.playing;

            print("Ad Serve Playing: " +
                playing.toString() +
                " APl: " +
                adPlayed.toString());
          });
        }
      });
      currentMediaSubscription =
          AudioService.currentMediaItemStream.listen((MediaItem item) {
        if (this.mounted) {
          setState(() {
            currentlyPlaying = item;

            if (maxVol != 0 &&
                widget.adVolumes.containsKey(currentlyPlaying.id) &&
                playing) {
              print("MAX vol: " + maxVol.toString());
              int volumeDecrease = widget.adVolumes[currentlyPlaying.id];
              print("Vol decrease: " + volumeDecrease.toString());
              int newVolume = maxVol - volumeDecrease;
              setVol(newVolume);
            }
            int adlEngth = currentlyPlaying.duration.inSeconds;
            adLengthMinute = adlEngth ~/ 60;
            adLengthSecond = adlEngth % 60;
            print("Curr Ad Plyy: " + currentlyPlaying.title);
            loaded = true;
          });
          if (adPlayed == 0 && adPlayed < widget.numberOfAds) {
            setState(() {
              prevSong = currentlyPlaying.title;
            });
          }
        }
      });
      durationSubscription = AudioService.positionStream.listen((event) {
        setState(() {
          int currentDuration = event.inSeconds;
          currentSecond = currentDuration % 60;
          currentMinute = currentDuration ~/ 60;
          // print("Current secon : " + event.inSeconds.toString());
        });
        // if (currentSecond == 3 && adPlayed != 0) {
        //   // print("Save Average : " +
        //   //     totalPrevAdTimeVoiceNo.toString() +
        //   //     " : " +
        //   //     totalPrevAdTimeVoice.toString() +
        //   //     " : " +
        //   //     totalPrevAdTimeVoiceNo.toString());
        //   //print("b-status second 3 : " + totalPrevAdTimeVoiceNo.toString());
        //   if (totalPrevAdTimeVoiceNo > 0) {
        //     RecordedData.saveAverage(RecordedData(
        //             name: "AD",
        //             id: widget.adBreakNo.toString() +
        //                 "-" +
        //                 (adPlayed + 1).toString() +
        //                 "-" +
        //                 prevSong,
        //             average: totalPrevAdTimeVoice / totalPrevAdTimeVoiceNo))
        //         .then((value) => {
        //               // print("3 saved" +
        //               //     widget.adBreakNo.toString() +
        //               //     "-" +
        //               //     (adPlayed + 1).toString())
        //             });

        //     setState(() {
        //       totalPrevAdTimeVoice = totalAdTimeVoice;
        //       totalPrevAdTimeVoiceNo = totalAdTimeVoiceNo;
        //       totalAdTimeVoice = 0;
        //       totalAdTimeVoiceNo = 0;
        //     });
        //     //print("a-status second 3 : " + totalPrevAdTimeVoiceNo.toString());
        //   }
        // }

        if (currentSecond == 3) {
          print("status 33: " + adPlayed.toString() + " : " + prevSong);
          setState(() {
            prevSong = currentlyPlaying.title;
          });
        }

        // print("Duration Sub: " +
        //     currentSecond.toString() +
        //     " - " +
        //     currentMinute.toString());
      });
      runOnce = true;
    }
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        // appBar: AppBar(
        //   leading: new IconButton(
        //     icon: new Icon(null),
        //     onPressed: () => Navigator.of(context).pop(),
        //   ),
        // ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //distanceleft
                // Text(
                //   "Ad Served : ",
                //   style: TextStyle(
                //       fontSize: deviceWidth * 0.1, fontWeight: FontWeight.w300),
                // ),
                Text(
                  distanceleft.toInt().toString() + " : ",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.1, fontWeight: FontWeight.w300),
                ),
                Text(
                  adPlayed.toString(),
                  style: TextStyle(
                      fontSize: deviceWidth * 0.1, fontWeight: FontWeight.w400),
                ),
                Text(
                  " / " + widget.numberOfAds.toString(),
                  style: TextStyle(
                      fontSize: deviceWidth * 0.1, fontWeight: FontWeight.w300),
                )
              ],
            ),
            SizedBox(
              height: deviceHeight * 0.01,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Ad Name : ",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.08,
                      fontWeight: FontWeight.w300),
                ),
                Text(
                  loaded
                      ? currentlyPlaying.title.length <= 11
                          ? currentlyPlaying.title
                          : currentlyPlaying.title.substring(0, 11) + "..."
                      : "Loading...",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.08,
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
            SizedBox(
              height: deviceHeight * 0.013,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Duration:",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.08,
                      fontWeight: FontWeight.w300),
                ),
                Text(
                  " " + currentMinute.toString() + ":",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.08,
                      fontWeight: FontWeight.w300),
                ),
                currentSecond > 9
                    ? Text(
                        currentSecond.toString(),
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w300),
                      )
                    : Text(
                        "0" + currentSecond.toString(),
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w300),
                      ),
                Text(
                  " / " + adLengthMinute.toString() + ":",
                  style: TextStyle(
                      fontSize: deviceWidth * 0.08,
                      fontWeight: FontWeight.w300),
                ),
                adLengthSecond > 9
                    ? Text(
                        adLengthSecond.toString(),
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w300),
                      )
                    : Text(
                        "0" + adLengthSecond.toString(),
                        style: TextStyle(
                            fontSize: deviceWidth * 0.08,
                            fontWeight: FontWeight.w300),
                      ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                    iconSize: deviceWidth * 0.2,
                    icon: Icon(
                      playing ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      playing ? AudioService.pause() : AudioService.play();
                    }),
                IconButton(
                    iconSize: deviceWidth * 0.2,
                    icon: Icon(
                      Icons.stop,
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text(
                                "Are you sure you want to quit serving Ads ?",
                                style: TextStyle(fontWeight: FontWeight.w400),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      AudioService.customAction("stopAD");
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Yes",
                                      style: TextStyle(
                                          fontSize: deviceWidth * 0.07),
                                    )),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "No",
                                      style: TextStyle(
                                          fontSize: deviceWidth * 0.07),
                                    ))
                              ],
                            );
                          });
                    }),
                // IconButton(
                //     iconSize: deviceWidth * 0.2,
                //     icon: Icon(
                //       Icons.local_gas_station_outlined,
                //     ),
                //     onPressed: () {}),
              ],
            )
          ],
        ),
      ),
    );
  }
}
