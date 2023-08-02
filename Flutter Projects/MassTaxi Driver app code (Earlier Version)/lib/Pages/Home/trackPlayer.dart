import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:audio_record/Classes/adBreakAlgorithm.dart';
import 'package:audio_record/Classes/location_data.dart';
//import 'package:audio_record/Classes/recorded_data.dart';
import 'package:audio_record/Pages/Home/adServePage.dart';
import 'package:audio_record/Pages/Home/routeEndPage.dart';
import 'package:audio_record/Pages/wrapper.dart';
// import 'package:audio_record/Pages/Home/startPage.dart';
import 'package:audio_record/Service/backgroundTask.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:audio_record/main.dart';
// import 'package:audio_record/Widgets/drawer.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:audio_record/Pages/NavBarPages/playlistPage.dart';
import 'package:audio_record/Pages/NavBarPages/albumPage.dart';
import 'package:audio_record/Pages/NavBarPages/artistPage.dart';
import 'package:flutter_background_location/flutter_background_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:noise_meter/noise_meter.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class TrackPlayer extends StatefulWidget {
  static int adCounter = 1;
  final Function toggleView;
  // final int numberOfAdBrake;
  // final int totalAdtoBeServed;
  // final String path;
  final CompilationForServe compilationForServe;
  TrackPlayer({
    this.toggleView,
    this.compilationForServe,
    // this.numberOfAdBrake,
    // this.totalAdtoBeServed,
    // this.path
  });
  @override
  _TrackPlayerState createState() => _TrackPlayerState();
}

_backgroundTaskEntrypoint() {
  AudioServiceBackground.run(() => MyBackgroundTask());
}

class _TrackPlayerState extends State<TrackPlayer> {
  FlutterAudioQuery audioQuery = FlutterAudioQuery();

  List<SongInfo> songs;
  List<PlaylistInfo> playlists;
  List<AlbumInfo> albums;
  List<ArtistInfo> artists;
  MediaItem item;
  LocationData nft;
  double distanceleft = 0;
  bool routeStarted = false;
  bool adStop = false;
  bool resulttime = false;
  bool startingSaved = false;
  int adBreakNo = 0;
  double totalDistance = 0.0;
  double totalCalculatedDistance = 0;
  double totalTime = 0;
  List<LocationData> savedLocations = [];

  // used to hold mediaItem list of loaded songs
  // to be turned to dynamic value and passed as
  // params to background audio task
  List<MediaItem> _queueMediaItem = [];

  MediaItem assignMediaItem(SongInfo songInfo) {
    MediaItem mediaItem = MediaItem(
        id: songInfo.filePath != null ? songInfo.filePath : null,
        album: songInfo.album != null ? songInfo.album : null,
        title: songInfo.title != null ? songInfo.title : null,
        duration: Duration(milliseconds: int.parse(songInfo.duration)),
        artUri: songInfo.albumArtwork != null
            ? Uri(path: songInfo.albumArtwork)
            : null);
    return mediaItem;
  }

  generateStats() async {
    final prefs = await AppMain.mainPrefs;
    List<String> savedProgresses = prefs.getStringList('dist_progress');
    //print("Saved Progress: " + savedProgresses.toString());
    //List<RecordedData> recordings = await RecordedData.getAverageRecordings();
    //print("Saved Recording: " + recordings.toString());
    // Check whether there were any Saved Progresses by checking if its null or less than 3
    if (savedProgresses != null) {
      if (savedProgresses.length >= 3) {
        // Get Saved Starting and Stopping Locations
        // LocationData startingLocation =
        //     await LocationData.getStartingPosition();
        // LocationData stoppingLocation = this.nft;
        // double distance = Geolocator.distanceBetween(
        //     startingLocation.latitude,
        //     startingLocation.longitude,
        //     stoppingLocation.latitude,
        //     stoppingLocation.longitude);
        // // Save the ideal and complete distance as a total distance
        // setState(() {
        //   totalDistance = distance;
        // });
        // Loop through all Saved Progress and Save them in the Saved Locations list EXCEPT FOR PAUSED LOCATIONS
        for (String svstr in savedProgresses) {
          LocationData retreivedData = LocationData.fromString(
            ldString: svstr,
          );
          if (retreivedData.name != null) {
            if (retreivedData.name.contains('PS')) {
              continue;
            }
          }
          savedLocations.add(retreivedData);
        }
        //print("Saved Locations: " + savedLocations.toString());
        // Instantiate Calculated Distance
        setState(() {
          totalCalculatedDistance = 0;
        });
        if (savedLocations.length >= 3) {
          // Calculate the distance traveled by evaluating each leap taken and incrementing it to the Calculated Distance Variable
          for (int i = 1; i < savedLocations.length; i++) {
            setState(() {
              totalCalculatedDistance = totalCalculatedDistance +
                  Geolocator.distanceBetween(
                      savedLocations[i - 1].latitude,
                      savedLocations[i - 1].longitude,
                      savedLocations[i].latitude,
                      savedLocations[i].longitude);
            });
          }
        }
        //Calculate total Route Duration by Subtracting the timestamps between the Last and First Saved Locations
        totalTime = LocationData.calculateTime(
            savedLocations[0], savedLocations[savedLocations.length - 1]);
      }
    }
  }

  void cleanHistory() async {
    final prefs = await AppMain.mainPrefs;
    await prefs.remove('start_location');
    await prefs.remove('dist_progress');
    await prefs.remove('recorded_data');
  }

  bool loaded = false;
  bool finishLoading = false;
  bool playlistLoading = false;
  bool playlistLoaded = false;
  bool albumLoading = false;
  bool albumLoaded = false;
  bool artistLoading = false;
  bool artistLoaded = false;
  bool runOnce = false;
  // used to hold the index of the currently selected song
  int songIndex = 0;

  // Used for UI (recent)
  bool playing = false;
  bool hasBeenPlayed = false;
  MediaItem currentlyPlaying;
  bool shuffleOn = false;
  bool connectBackground = false;
  bool subscribed = false;
  int _currentIndex = 0;
  Timer _timer, _timer2;
  // bufferLength is a time value in seconds
  // that is used to know how long do we
  // have to wait to get another Ad brake
  int bufferLength = 15;
  // buffer time is used for control
  // needs to be set at 15 just to
  // be safe that everything is loaded
  int bufferTime = 30;
  bool push = false;
  bool called = false;
  // used to know the number of Ad brakes
  // that passed in this route
  int adBrakes = 0;
  // holds the total number of ad Served in
  // our length (in which 1 means 30 second)
  // in all the Ad brakes
  int totalAdServed = 0;
  // retrieved from current setup data
  // by multiplying sp*ts*cm
  double pricePerSlot = 0.68;
  int accuracyThreshold = 200;

  // NEW (Used for Dagim)
  bool routeEnd = false;
  // should be false at the begining
  // bool readyToServe = true;

  fetchTracks() async {
    songs = await audioQuery.getSongs();
    songs.sort((a, b) => a.displayName.compareTo(b.displayName));
    // print("First : " + songs[0].displayName);
    // print("songs leng : " + songs.length.toString());
    finishLoading = true;
    setState(() {
      if (finishLoading == true) {
        currentlyPlaying = assignMediaItem(songs[songIndex]);
        loaded = true;
      }
    });
  }

  fetchPlaylists() async {
    playlists = await audioQuery.getPlaylists();
    playlists.sort((a, b) => a.name.compareTo(b.name));
    playlistLoading = true;
    setState(() {
      if (playlistLoading == true) {
        playlistLoaded = true;
      }
    });
  }

  fetchAlbums() async {
    albums = await audioQuery.getAlbums();
    albums.sort((a, b) => a.title.compareTo(b.title));
    albumLoading = true;
    setState(() {
      if (albumLoading == true) {
        albumLoaded = true;
      }
    });
  }

  fetchArtists() async {
    artists = await audioQuery.getArtists();
    artists.sort((a, b) => a.name.compareTo(b.name));
    artistLoading = true;
    setState(() {
      if (artistLoading == true) {
        artistLoaded = true;
      }
    });
  }

  double volume = 1;

  NoiseMeter noiseMeter;
  StreamSubscription playingSubscription, currentMediaSubscription;

  bool previous = true, firstTime = false;

  // Ad brake 1 Ad cards
  List<String> ads1 = [];
  // must be equal number with the Ad Cards
  // tells us how many volume to decrease from the maximum volume
  // for the particular Ad. this data is retrived from TvAd table
  Map<String, int> adsVolume1 = new Map<String, int>();
  // Ad Brake 2 Ad cards
  List<String> ads2 = [];
  Map<String, int> adsVolume2 = new Map<String, int>();
  // Ad Brake 3 Ad cards.
  List<String> ads3 = [];
  Map<String, int> adsVolume3 = new Map<String, int>();

  @override
  void initState() {
    bufferLength = widget.compilationForServe.bufferLength * 60;
    // print("status trackplayer");
    cleanHistory();

    // audioPlayer = AudioPlayer();

    // Starts Location Service
    FlutterBackgroundLocation.startLocationService();

    setState(() {
      resulttime = false;
    });

    fetchTracks();
    fetchAlbums();
    fetchArtists();
    fetchPlaylists();

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

      if (!resulttime) {
        if (this.nft != null) {
          if (this.nft.accuracy < this.accuracyThreshold) {
            if (routeStarted && startingSaved) {
              LocationData.checkRouteEnd(currentLocation: this.nft).then((ve) {
                this.setState(() {
                  distanceleft = ve;
                });
                LocationData.checkADStop(currentLocation: this.nft)
                    .then((val) async {
                  LocationData.saveProgress(this.nft).then((value) {
                    //print("Progress Saved");
                  });
                  if (val) {
                    print("ABOUT TO CHECK STOP 1");
                    setState(() {
                      adStop = true;
                    });

                    LocationData.checkRouteStop(currentLocation: this.nft)
                        .then((value) async {
                      if (value) {
                        TrackPlayer.adCounter = 1;
                        if (_timer != null) {
                          _timer.cancel();
                        }
                        await generateStats();
                        FlutterBackgroundLocation.stopLocationService();
                        setState(() {
                          resulttime = true;
                        });
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RouteEndPage(
                                      toggleView: widget.toggleView,
                                      adServed: totalAdServed,
                                      compilationForServe:
                                          widget.compilationForServe,
                                      // totalAdTobeServed: widget.totalAdtoBeServed,
                                      totalAdTobeServed: widget
                                          .compilationForServe.totalAdLength,
                                      totalCalculatedDistance:
                                          totalCalculatedDistance,
                                      duration: totalTime,
                                      savedLocations: savedLocations,
                                      success: true,
                                    )));
                      }
                    });
                  }
                });
              });
            } else {
              if (!startingSaved) {
                LocationData.saveStart(this.nft).then((value) => {
                      setState(() {
                        startingSaved = value;
                      })
                    });
              } else {
                LocationData.checkRouteStart(currentLocation: this.nft)
                    .then((value) {
                  LocationData.checkRoutetartingRange(currentLocation: this.nft)
                      .then((disvalue) {
                    this.setState(() {
                      distanceleft = disvalue * -1;
                    });
                    if (value) {
                      LocationData.saveProgress(nft).then((val) {
                        setState(() {
                          routeStarted = true;
                        });
                      });
                    }
                  });
                });
              }
            }
          } else {
            print("Accuracy Problem " + this.nft.accuracy.toStringAsFixed(3));
          }
        }
      }
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (loaded && routeStarted && !adStop) {
        if (bufferTime > 0) {
          bufferTime--;
        }
        if (bufferTime == 10 &&
            adBrakes < widget.compilationForServe.adBreakNum) {
          if (!called) {
            AudioService.customAction("decreaseVolume");
            called = true;
          }
        }
        if (bufferTime == 0 &&
            adBrakes < widget.compilationForServe.adBreakNum) {
          if (!push) {
            // && routeStarted
            List<String> ads = [];
            Map<String, int> adsVolume = new Map<String, int>();
            if (adBrakes == 0) {
              ads = ads1;
              adsVolume = adsVolume1;
            } else if (adBrakes == 1) {
              ads = ads2;
              adsVolume = adsVolume2;
            } else if (adBrakes == 2) {
              ads = ads3;
              adsVolume = adsVolume3;
            }
            // Play Ad
            adBrakes++;
            // // Ad brake 1 Ad cards
            // List<String> ads = [];
            // MediaItem songMedia = assignMediaItem(songs[0]);
            // MediaItem songMedia1 = assignMediaItem(songs[1]);
            // ads.add(songMedia.id);
            // ads.add(songMedia1.id);
            // // must be equal number with the Ad Cards
            // // tells us how many volume to decrease from the maximum volume
            // // for the particular Ad. this data is retrived from Tv ad table
            // Map<String, int> adsVolume = {songMedia.id: 7, songMedia1.id: 8};
            // // Ad Brake 2 Ad cards
            // List<String> ads2 = [];
            // Map<String, int> adsVolume2 = new Map<String, int>();
            // // Ad Brake 3 Ad cards.
            // List<String> ads3 = [];
            // Map<String, int> adsVolume3 = new Map<String, int>();
            setState(() {
              // resulttime = true;
              adBreakNo = adBreakNo + 1;
            });

            //FlutterBackgroundLocation.stopLocationService();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AdServePage(
                          // toggleView: widget.toggleView,
                          adBreakNo: adBreakNo,
                          numberOfAds: ads.length,
                          adVolumes: adsVolume,
                          caliber: widget.compilationForServe.calibrationValue,
                        )));
            push = true;
            print("ADSa: " + ads.length.toString());
            AudioService.customAction("playAD", ads).then((value) async {
              // AD Stopped
              //FlutterBackgroundLocation.startLocationService();
              totalAdServed += value;
              // print("Ad Served : " + totalAdServed.toString());

              //await Future.delayed(Duration(seconds: 5));
              Navigator.pop(context);

              // Activates the Listener for Location Updates
              FlutterBackgroundLocation.getLocationUpdates((location) {
                print("NEW LOC UPDATE");
                // Update the State of the current location object
                setState(() {
                  nft = LocationData.withAccuracy(
                      latitude: location.latitude,
                      longitude: location.longitude,
                      speed: location.speed,
                      accuracy: location.accuracy);
                });
                if (!resulttime) {
                  if (this.nft != null) {
                    if (this.nft.accuracy < this.accuracyThreshold) {
                      if (routeStarted && startingSaved) {
                        LocationData.checkRouteEnd(currentLocation: this.nft)
                            .then((ve) {
                          this.setState(() {
                            distanceleft = ve;
                          });
                          LocationData.checkADStop(currentLocation: this.nft)
                              .then((val) async {
                            LocationData.saveProgress(this.nft).then((value) {
                              //print("Progress Saved");
                            });
                            if (val) {
                              print("ABOUT TO CHECK STOP 2");
                              setState(() {
                                adStop = true;
                              });
                              LocationData.checkRouteStop(
                                      currentLocation: this.nft)
                                  .then((value) async {
                                if (value) {
                                  TrackPlayer.adCounter = 1;
                                  if (_timer != null) {
                                    _timer.cancel();
                                  }
                                  await generateStats();
                                  FlutterBackgroundLocation
                                      .stopLocationService();
                                  setState(() {
                                    resulttime = true;
                                  });
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => RouteEndPage(
                                                toggleView: widget.toggleView,
                                                adServed: totalAdServed,
                                                compilationForServe:
                                                    widget.compilationForServe,
                                                // totalAdTobeServed: widget.totalAdtoBeServed,
                                                totalAdTobeServed: widget
                                                    .compilationForServe
                                                    .totalAdLength,
                                                totalCalculatedDistance:
                                                    totalCalculatedDistance,
                                                duration: totalTime,
                                                savedLocations: savedLocations,
                                                success: true,
                                              )));
                                }
                              });
                            }
                          });
                        });
                      } else {
                        if (!startingSaved) {
                          LocationData.saveStart(this.nft).then((value) => {
                                setState(() {
                                  startingSaved = value;
                                })
                              });
                        } else {
                          LocationData.checkRouteStart(
                                  currentLocation: this.nft)
                              .then((value) {
                            LocationData.checkRoutetartingRange(
                                    currentLocation: this.nft)
                                .then((disvalue) {
                              this.setState(() {
                                distanceleft = disvalue * -1;
                              });
                              if (value) {
                                LocationData.saveProgress(nft).then((val) {
                                  setState(() {
                                    routeStarted = true;
                                  });
                                });
                              }
                            });
                          });
                        }
                      }
                    } else {
                      print("Accuracy Problem " +
                          this.nft.accuracy.toStringAsFixed(3));
                    }
                  }
                }
              });

              bufferTime = bufferLength;
              push = false;
              called = false;
            });
          }
        }
        //  else if (bufferTime != 0) {
        //   print("Buffer time :" + bufferTime.toString()
        //       // + " : " +
        //       // this.nft.toString()
        //       );
        // }
      }
    });
    // we go to the routeEndPage when the route stops which
    // is notified by the location tracking code
    _timer2 = Timer.periodic(Duration(milliseconds: 800), (timer) {
      if (!firstTime && runOnce) {
        AudioService.customAction("speakerStream", Wrapper.speakConnection);
        print("First time: " + Wrapper.speakConnection.toString());
        firstTime = true;
      }
      if (previous != Wrapper.speakConnection && runOnce) {
        AudioService.customAction("speakerStream", Wrapper.speakConnection);
        previous = Wrapper.speakConnection;
        print("Changed speak" + previous.toString());
      }
    });
    super.initState();
  }

  @mustCallSuper
  @protected
  void dispose() async {
    super.dispose();
    if (playingSubscription != null) {
      playingSubscription.cancel();
    }
    if (currentMediaSubscription != null) {
      currentMediaSubscription.cancel();
    }

    FlutterBackgroundLocation.stopLocationService();
    print("status trackplayer dispose");
    // we have to use custom action first
    // to notify to not close the app when
    // the track player widget is removed
    AudioService.customAction("dispose");
    if (_timer != null) {
      _timer.cancel();
    }
    if (_timer2 != null) {
      _timer2.cancel();
    }
    await AudioService.stop();
  }

  // TO DO
  // Check if recorded file will show up -- Done
  // Slow Transition to AD -- Done
  // Make sure headphones are plugged or bluetooth connected means car speaker
  // Timer functionality -- Done
  // play next song using on song completion event and listen to it -- DONE

  // Missing
  // For now we dont track speaker connection in track player
  // but to do that all we have to do is listen to value notifier
  // through valuelistenablebuilder which we have to call in all four
  // columns

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;

    // print("Result " + resulttime.toString());

    final tabs = [
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ValueListenableBuilder(
          //   valueListenable: widget.speakCon,
          //   builder: (BuildContext context, bool value, Widget child) {
          //     print("Speak Conn : " + value.toString());
          //     return Container(
          //       width: 0,
          //       height: 0,
          //     );
          //   },
          // ),
          Container(
            width: deviceWidth,
            height: deviceHeight * 0.7,
            child: albumLoaded
                ? ListView.builder(
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Container(
                              height: deviceHeight * 0.055,
                              child: Icon(Icons.album)),
                          title: albums[index].title.length > 24
                              ? Text(
                                  albums[index].title.substring(0, 24) + "...")
                              : Text(albums[index].title),
                          subtitle: Text("Number of Songs: " +
                              albums[index].numberOfSongs),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => AlbumPage(
                                          albumInfo: albums[index],
                                          hasBeenPlayed: hasBeenPlayed,
                                          shuffleOn: shuffleOn,
                                          currentlyPlaying: currentlyPlaying,
                                        )));
                          },
                        ),
                      );
                    },
                    itemCount: albums.length,
                  )
                : Loading(),
          ),
          loaded
              ? Container(
                  height: deviceHeight * 0.08,
                  color: Colors.black54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: deviceWidth * 0.011,
                      ),
                      Container(
                        height: deviceHeight * 0.065,
                        width: deviceWidth * 0.15,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0))),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: currentlyPlaying.artUri != null
                              ? Image.file(
                                  new File(currentlyPlaying.artUri.path),
                                  fit: BoxFit.fill,
                                )
                              : Image.asset("assets/audio-tune.png"),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.43,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                currentlyPlaying.title.length > 17
                                    ? currentlyPlaying.title.substring(0, 17) +
                                        "..."
                                    : currentlyPlaying.title,
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                currentlyPlaying.album != null
                                    ? (currentlyPlaying.album.length > 17
                                        ? currentlyPlaying.album
                                                .substring(0, 17) +
                                            "..."
                                        : currentlyPlaying.album)
                                    : "Unknown",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_previous),
                              onPressed: () {
                                AudioService.skipToPrevious();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: (playing == false)
                                  ? Icon(
                                      Icons.play_arrow,
                                    )
                                  : Icon(
                                      Icons.pause,
                                    ),
                              onPressed: (playing == false)
                                  ? () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                        AudioService.playFromMediaId(
                                            _queueMediaItem[songIndex].id);
                                      } else {
                                        AudioService.play();
                                      }
                                      // print("someapadfh");
                                      // AudioService.play();
                                    }
                                  : () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                      }
                                      AudioService.pause();
                                    },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_next),
                              onPressed: () {
                                AudioService.skipToNext();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.07,
                              color: shuffleOn ? Colors.white60 : Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.shuffle),
                              onPressed: () {
                                if (shuffleOn) {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.none);
                                  setState(() {
                                    shuffleOn = false;
                                  });
                                } else {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.all);
                                  setState(() {
                                    shuffleOn = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.008,
                      ),
                    ],
                  ),
                )
              : Text(""),
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: deviceWidth,
            height: deviceHeight * 0.09,
            color: Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Current Profit",
                        style: TextStyle(
                            fontSize: deviceHeight * 0.023,
                            fontWeight: FontWeight.w400),
                      ),
                      Text(
                        "Ad Served",
                        style: TextStyle(
                            fontSize: deviceHeight * 0.023,
                            fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            (totalAdServed *
                                        (widget.compilationForServe
                                                .availableprofit /
                                            widget.compilationForServe
                                                .totalAdLength)) <
                                    100
                                ? (totalAdServed *
                                        (widget.compilationForServe
                                                .availableprofit /
                                            widget.compilationForServe
                                                .totalAdLength))
                                    .toStringAsFixed(2)
                                : (totalAdServed *
                                        (widget.compilationForServe
                                                .availableprofit /
                                            widget.compilationForServe
                                                .totalAdLength))
                                    .toStringAsPrecision(2),
                            style: TextStyle(
                                fontSize: deviceSize.height * 0.032,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            // "/ 00.00 ETB",
                            widget.compilationForServe.availableprofit < 100
                                ? " / " +
                                    widget.compilationForServe.availableprofit
                                        .toStringAsFixed(2) +
                                    " \$"
                                : " / " +
                                    widget.compilationForServe.availableprofit
                                        .toStringAsPrecision(2) +
                                    " \$",
                            style: TextStyle(
                                fontSize: deviceSize.height * 0.032,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            totalAdServed.toString(),
                            style: TextStyle(
                                fontSize: deviceSize.height * 0.032,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            " / " +
                                widget.compilationForServe.totalAdLength
                                    .toString(),
                            style: TextStyle(
                                fontSize: deviceSize.height * 0.032,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Container(
            width: deviceWidth,
            height: deviceHeight * 0.615,
            color: Colors.black,
            child: loaded
                ? ListView.builder(
                    itemBuilder: (context, index) {
                      // can be used to create list of songs
                      // based on folders
                      // // List<String> folder =
                      // //     songs[songIndex].filePath.split("0");
                      // print(folder[0] + folder[1]);
                      // print(
                      //     "file path: " + songs[songIndex].filePath.toString());
                      String display = songs[index].title;
                      String artist = songs[index].artist;
                      double inMilliSecond =
                          double.parse(songs[index].duration);
                      int min = 60 * 1000;
                      double minute = inMilliSecond / min;
                      double seconds = ((inMilliSecond / 1000) % 60);

                      int roundedMinutes = minute.floor();
                      int roundedSeconds = seconds.floor();
                      String stringSeconds = (roundedSeconds > 9)
                          ? roundedSeconds.toString()
                          : "0" + roundedSeconds.toString();
                      String stringMinutes = (roundedMinutes > 9)
                          ? roundedMinutes.toString()
                          : "0" + roundedMinutes.toString();

                      // String image = "a";
                      bool imageExist = false;
                      File imageFile;

                      if (songs[index].albumArtwork != null) {
                        print("Image : " + songs[index].artist.toString());
                        // image = songs[index].albumArtwork;
                        // image = image.substring(0, 2);
                        imageExist = true;
                        imageFile = new File(songs[index].albumArtwork);
                      }

                      if (display.length > 20) {
                        display = display.substring(0, 20);
                        display = display + "...";
                      }
                      if (artist.length > 14) {
                        artist = artist.substring(0, 14);
                        artist += "...";
                      }
                      return Container(
                        color: Colors.grey[50],
                        child: Card(
                          child: ListTile(
                              onTap: () {
                                songIndex = index;
                                AudioService.playFromMediaId(
                                    _queueMediaItem[songIndex].id);
                                if (hasBeenPlayed == false) {
                                  hasBeenPlayed = true;
                                }
                              },
                              leading: Container(
                                height: deviceHeight * 0.06,
                                width: deviceHeight * 0.06,
                                child: Container(
                                  color: Colors.grey[200],
                                  child: imageExist
                                      ? Image.file(imageFile)
                                      : Padding(
                                          padding: const EdgeInsets.all(11),
                                          child: Image.asset(
                                              "assets/audio-tune.png"),
                                        ),
                                ),
                              ),
                              title: Text(display),
                              subtitle: Text(
                                artist +
                                    "  " +
                                    stringMinutes +
                                    ":" +
                                    stringSeconds,
                              )),
                        ),
                      );
                    },
                    itemCount: songs.length,
                    addAutomaticKeepAlives: false,
                    itemExtent: 70,
                  )
                : Loading(),
          ),
          // Text("Connec : " + speakerConnected.toString())
          // ValueListenableBuilder(
          //     valueListenable: widget.speak,
          //     builder: (BuildContext context, bool value, Widget child) {
          //       return Text("Track Player " + value.toString());
          //     }),
          loaded
              ? Container(
                  height: deviceHeight * 0.08,
                  color: Colors.black54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: deviceWidth * 0.011,
                      ),
                      Container(
                        height: deviceHeight * 0.065,
                        width: deviceWidth * 0.15,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0))),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: currentlyPlaying.artUri != null
                              ? Image.file(
                                  new File(currentlyPlaying.artUri.path),
                                  fit: BoxFit.fill,
                                )
                              : Image.asset("assets/audio-tune.png"),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.43,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                currentlyPlaying.title.length > 17
                                    ? currentlyPlaying.title.substring(0, 17) +
                                        "..."
                                    : currentlyPlaying.title,
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                currentlyPlaying.album != null
                                    ? (currentlyPlaying.album.length > 17
                                        ? currentlyPlaying.album
                                                .substring(0, 17) +
                                            "..."
                                        : currentlyPlaying.album)
                                    : "Unknown",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_previous),
                              onPressed: () {
                                AudioService.skipToPrevious();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: (playing == false)
                                  ? Icon(
                                      Icons.play_arrow,
                                    )
                                  : Icon(
                                      Icons.pause,
                                    ),
                              onPressed: (playing == false)
                                  ? () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                        AudioService.playFromMediaId(
                                            _queueMediaItem[songIndex].id);
                                      } else {
                                        AudioService.play();
                                      }
                                      // print("someapadfh");
                                      // AudioService.play();
                                    }
                                  : () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                      }
                                      AudioService.pause();
                                    },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_next),
                              onPressed: () {
                                AudioService.skipToNext();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.07,
                              color: shuffleOn ? Colors.white60 : Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.shuffle),
                              onPressed: () {
                                if (shuffleOn) {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.none);
                                  setState(() {
                                    shuffleOn = false;
                                  });
                                } else {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.all);
                                  setState(() {
                                    shuffleOn = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.008,
                      ),
                    ],
                  ),
                )
              : Text("")
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: deviceWidth,
            height: deviceHeight * 0.7,
            child: artistLoaded
                ? ListView.builder(
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Container(
                              height: deviceHeight * 0.055,
                              child: Icon(Icons.person)),
                          title: artists[index].name.length > 24
                              ? Text(
                                  artists[index].name.substring(0, 24) + "...")
                              : Text(artists[index].name),
                          subtitle: Text("Albums: " +
                              artists[index].numberOfAlbums +
                              " Songs: " +
                              artists[index].numberOfTracks),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ArtistPage(
                                          artistInfo: artists[index],
                                          hasBeenPlayed: hasBeenPlayed,
                                          shuffleOn: shuffleOn,
                                          currentlyPlaying: currentlyPlaying,
                                        )));
                          },
                        ),
                      );
                    },
                    itemCount: artists.length,
                  )
                : Loading(),
          ),
          loaded
              ? Container(
                  height: deviceHeight * 0.08,
                  color: Colors.black54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: deviceWidth * 0.011,
                      ),
                      Container(
                        height: deviceHeight * 0.065,
                        width: deviceWidth * 0.15,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0))),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: currentlyPlaying.artUri != null
                              ? Image.file(
                                  new File(currentlyPlaying.artUri.path),
                                  fit: BoxFit.fill,
                                )
                              : Image.asset("assets/audio-tune.png"),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.43,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                currentlyPlaying.title.length > 17
                                    ? currentlyPlaying.title.substring(0, 17) +
                                        "..."
                                    : currentlyPlaying.title,
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                currentlyPlaying.album != null
                                    ? (currentlyPlaying.album.length > 17
                                        ? currentlyPlaying.album
                                                .substring(0, 17) +
                                            "..."
                                        : currentlyPlaying.album)
                                    : "Unknown",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_previous),
                              onPressed: () {
                                AudioService.skipToPrevious();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: (playing == false)
                                  ? Icon(
                                      Icons.play_arrow,
                                    )
                                  : Icon(
                                      Icons.pause,
                                    ),
                              onPressed: (playing == false)
                                  ? () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                        AudioService.playFromMediaId(
                                            _queueMediaItem[songIndex].id);
                                      } else {
                                        AudioService.play();
                                      }
                                      // print("someapadfh");
                                      // AudioService.play();
                                    }
                                  : () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                      }
                                      AudioService.pause();
                                    },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_next),
                              onPressed: () {
                                AudioService.skipToNext();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.07,
                              color: shuffleOn ? Colors.white60 : Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.shuffle),
                              onPressed: () {
                                if (shuffleOn) {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.none);
                                  setState(() {
                                    shuffleOn = false;
                                  });
                                } else {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.all);
                                  setState(() {
                                    shuffleOn = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.008,
                      ),
                    ],
                  ),
                )
              : Text("")
        ],
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: deviceWidth,
            height: deviceHeight * 0.7,
            child: playlistLoaded
                ? ListView.builder(
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Container(
                              height: deviceHeight * 0.055,
                              child: Icon(Icons.playlist_play)),
                          title: playlists[index].name.length > 24
                              ? Text(playlists[index].name.substring(0, 24) +
                                  "...")
                              : Text(playlists[index].name),
                          subtitle: Text("Number of Songs: " +
                              playlists[index].memberIds.length.toString()),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => PlaylistPage(
                                          playlistInfo: playlists[index],
                                          hasBeenPlayed: hasBeenPlayed,
                                          shuffleOn: shuffleOn,
                                          currentlyPlaying: currentlyPlaying,
                                        )));
                          },
                        ),
                      );
                    },
                    itemCount: playlists.length,
                  )
                : Loading(),
          ),
          loaded
              ? Container(
                  height: deviceHeight * 0.08,
                  color: Colors.black54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: deviceWidth * 0.011,
                      ),
                      Container(
                        height: deviceHeight * 0.065,
                        width: deviceWidth * 0.15,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                                BorderRadius.all(Radius.circular(5.0))),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: currentlyPlaying.artUri != null
                              ? Image.file(
                                  new File(currentlyPlaying.artUri.path),
                                  fit: BoxFit.fill,
                                )
                              : Image.asset("assets/audio-tune.png"),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.43,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(
                                currentlyPlaying.title.length > 17
                                    ? currentlyPlaying.title.substring(0, 17) +
                                        "..."
                                    : currentlyPlaying.title,
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                currentlyPlaying.album != null
                                    ? (currentlyPlaying.album.length > 17
                                        ? currentlyPlaying.album
                                                .substring(0, 17) +
                                            "..."
                                        : currentlyPlaying.album)
                                    : "Unknown",
                                style: TextStyle(color: Colors.white),
                              )
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: deviceWidth * 0.4,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_previous),
                              onPressed: () {
                                AudioService.skipToPrevious();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: (playing == false)
                                  ? Icon(
                                      Icons.play_arrow,
                                    )
                                  : Icon(
                                      Icons.pause,
                                    ),
                              onPressed: (playing == false)
                                  ? () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                        AudioService.playFromMediaId(
                                            _queueMediaItem[songIndex].id);
                                      } else {
                                        AudioService.play();
                                      }
                                      // print("someapadfh");
                                      // AudioService.play();
                                    }
                                  : () {
                                      if (hasBeenPlayed == false) {
                                        hasBeenPlayed = true;
                                      }
                                      AudioService.pause();
                                    },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.09,
                              color: Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.skip_next),
                              onPressed: () {
                                AudioService.skipToNext();
                              },
                            ),
                            IconButton(
                              alignment: Alignment.center,
                              iconSize: deviceWidth * 0.07,
                              color: shuffleOn ? Colors.white60 : Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.shuffle),
                              onPressed: () {
                                if (shuffleOn) {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.none);
                                  setState(() {
                                    shuffleOn = false;
                                  });
                                } else {
                                  print("Shuffle: " + shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.all);
                                  setState(() {
                                    shuffleOn = true;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: deviceWidth * 0.008,
                      ),
                    ],
                  ),
                )
              : Text("")
        ],
      ),
    ];

    if (loaded == true && runOnce == false) {
      // print("loaded : " + songs.length.toString());
      for (var item in songs) {
        MediaItem holder = assignMediaItem(item);
        _queueMediaItem.add(holder);
      }
      List<dynamic> list = [];
      for (var item in _queueMediaItem) {
        var holder = item.toJson();
        list.add(holder);
      }

      var params = {"data": list};
      // used for background audio control
      AudioService.start(
          backgroundTaskEntrypoint: _backgroundTaskEntrypoint,
          // androidNotificationColor: 0xFF2196f3,
          // androidNotificationIcon: "mip",
          androidNotificationColor: 0xFF02061f,
          androidNotificationChannelName: "AD",
          params: params);
      playingSubscription =
          AudioService.playbackStateStream.listen((PlaybackState state) {
        if (mounted && state != null) {
          setState(() {
            playing = state.playing;
            // print("status : " + playing.toString());
          });
        }
      });
      // NEW
      int adBreakAdCardsCounter = 0;
      widget.compilationForServe.adbreakAdCards.forEach((element) {
        if (adBreakAdCardsCounter == 0) {
          element.forEach((adCard) {
            // print("Ad: " +
            //     adCard.uniqueName +
            //     " Index: " +
            //     adCard.songIndex.toString() +
            //     " Song: " +
            //     songs[adCard.songIndex].title +
            //     " vd: " +
            //     adCard.volumeDecrease.toString());
            MediaItem adMedia = assignMediaItem(songs[adCard.songIndex]);
            ads1.add(adMedia.id);
            adsVolume1[adMedia.id] = adCard.volumeDecrease;
          });
        } else if (adBreakAdCardsCounter == 1) {
          element.forEach((adCard) {
            MediaItem adMedia = assignMediaItem(songs[adCard.songIndex]);
            ads2.add(adMedia.id);
            adsVolume2[adMedia.id] = adCard.volumeDecrease;
          });
        } else if (adBreakAdCardsCounter == 2) {
          element.forEach((adCard) {
            MediaItem adMedia = assignMediaItem(songs[adCard.songIndex]);
            ads3.add(adMedia.id);
            adsVolume3[adMedia.id] = adCard.volumeDecrease;
          });
        }
        adBreakAdCardsCounter++;
      });
      //
      runOnce = true;
    }

    if ((hasBeenPlayed && subscribed == false) ||
        (playing && hasBeenPlayed == false && subscribed == false)) {
      currentMediaSubscription =
          AudioService.currentMediaItemStream.listen((MediaItem item) {
        if (this.mounted) {
          setState(() {
            currentlyPlaying = item;
            print("Curr Plyy: " + currentlyPlaying.title);
          });
          subscribed = true;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: Icon(null),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Path   $adStop : "),
            Text(distanceleft.toInt().toString())
            // Text("Path : "),
            // widget.compilationForServe.pathName.length < 18
            //     ? Text(widget.compilationForServe.pathName)
            //     : Text(widget.compilationForServe.pathName.substring(0, 18) +
            //         "...")
          ],
        ),
        // centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(Icons.cancel_outlined),
              onPressed: () async {
                showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(
                          "Are you sure you want to cancel the Route ?",
                          style: TextStyle(fontWeight: FontWeight.w400),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () async {
                                Navigator.pop(context);
                                // Stop The route and the route will be disqualified
                                // without penalty and immediatly send to the routeEndPage
                                if (_timer != null) {
                                  _timer.cancel();
                                }
                                await generateStats();
                                FlutterBackgroundLocation.stopLocationService();
                                setState(() {
                                  resulttime = true;
                                });
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => RouteEndPage(
                                              toggleView: widget.toggleView,
                                              adServed: 0,
                                              compilationForServe:
                                                  widget.compilationForServe,
                                              // totalAdTobeServed: widget.totalAdtoBeServed,
                                              totalAdTobeServed: widget
                                                  .compilationForServe
                                                  .totalAdLength,
                                              totalCalculatedDistance:
                                                  totalDistance,
                                              savedLocations: savedLocations,
                                              duration: totalTime,
                                              success: false,
                                            )));
                              },
                              child: Text(
                                "Yes",
                                style: TextStyle(fontSize: deviceWidth * 0.07),
                              )),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                "No",
                                style: TextStyle(fontSize: deviceWidth * 0.07),
                              ))
                        ],
                      );
                    });
              })
        ],
        // backgroundColor: Colors.blueGrey,
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 40,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.album), label: "Albums"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tracks"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Artists"),
          BottomNavigationBarItem(
            icon: Icon(Icons.playlist_play),
            label: "Playlists",
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 1) {
              List<String> mediasID = [];
              for (var item in _queueMediaItem) {
                mediasID.add(item.id);
              }
              AudioService.customAction("addQueue", mediasID);
            }
          });
          // setQueue(_queueMediaItem);
        },
      ),
      // use the code below when you connect with
      // dagim code and delete the floatingActionButton
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.ac_unit),
        onPressed: () async {
          // this needs to be called when the route stops according
          // to the location tracking code
          TrackPlayer.adCounter = 1;
          if (_timer != null) {
            _timer.cancel();
          }
          await generateStats();
          FlutterBackgroundLocation.stopLocationService();
          setState(() {
            resulttime = true;
          });
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RouteEndPage(
                        toggleView: widget.toggleView,
                        adServed: totalAdServed,
                        compilationForServe: widget.compilationForServe,
                        // totalAdTobeServed: widget.totalAdtoBeServed,
                        totalAdTobeServed:
                            widget.compilationForServe.totalAdLength,
                        totalCalculatedDistance: totalCalculatedDistance,
                        duration: totalTime,
                        savedLocations: savedLocations,
                        success: true,
                      )));
        },
      ),
    );
  }
}
