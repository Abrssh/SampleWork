import 'dart:async';
import 'dart:io';

import 'package:audio_record/Shared/loading.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

class ArtistPage extends StatefulWidget {
  final ArtistInfo artistInfo;
  bool hasBeenPlayed = false;
  bool shuffleOn = false;
  final MediaItem currentlyPlaying;
  @override
  _ArtistPageState createState() => _ArtistPageState();
  ArtistPage(
      {this.artistInfo,
      this.hasBeenPlayed,
      this.shuffleOn,
      this.currentlyPlaying});
}

class _ArtistPageState extends State<ArtistPage> {
  FlutterAudioQuery audioQuery = FlutterAudioQuery();
  List<SongInfo> songs;
  List<MediaItem> _queueMediaItems = [];
  List<String> mediaItemsId = [];
  int songIndex = 0;
  bool shuffleMode = false;

  bool loaded = false, runOnce = false;

  bool playing = false;
  MediaItem currentlyPlaying;

  bool subscribed = false;

  StreamSubscription playingSubscription, currentMediaSubscription;

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

  fetchTracks() async {
    print("Fetching");
    songs = await audioQuery.getSongsFromArtist(artistId: widget.artistInfo.id);
    songs.sort((a, b) => a.displayName.compareTo(b.displayName));
    currentlyPlaying = widget.currentlyPlaying;
    setState(() {
      loaded = true;
    });
  }

  @override
  void initState() {
    fetchTracks();
    super.initState();
  }

  @mustCallSuper
  @protected
  void dispose() {
    playingSubscription.cancel();
    if (currentMediaSubscription != null) {
      currentMediaSubscription.cancel();
    }
    print("Dispose");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var deviceSize = MediaQuery.of(context).size;
    var deviceWidth = deviceSize.width;
    var deviceHeight = deviceSize.height;

    if (loaded == true && runOnce == false) {
      print("artist song Loaded : " + songs.length.toString());
      for (var item in songs) {
        MediaItem holder = assignMediaItem(item);
        mediaItemsId.add(holder.id);
        _queueMediaItems.add(holder);
      }
      AudioService.customAction("addQueue", mediaItemsId);
      print("_queue Loaded : " + _queueMediaItems.length.toString());
      playingSubscription =
          AudioService.playbackStateStream.listen((PlaybackState state) {
        if (this.mounted) {
          setState(() {
            playing = state.playing;
            print("pla Playing: " + playing.toString());
          });
        }
      });
      runOnce = true;
    }

    if ((widget.hasBeenPlayed && subscribed == false) ||
        (playing && widget.hasBeenPlayed == false && subscribed == false)) {
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
        title: Text(widget.artistInfo.name),
        backgroundColor: Colors.blueGrey,
        actions: [
          Container(
            width: deviceWidth * 0.35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.play_arrow),
                  iconSize: deviceWidth * 0.1,
                  onPressed: () {
                    if (_queueMediaItems.length != 0) {
                      AudioService.playFromMediaId(
                          _queueMediaItems[songIndex].id);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: shuffleMode ? Colors.white54 : Colors.white,
                  ),
                  iconSize: deviceWidth * 0.1,
                  onPressed: () {
                    if (shuffleMode) {
                      print("SH: " + shuffleMode.toString());
                      AudioService.setShuffleMode(AudioServiceShuffleMode.none);
                      setState(() {
                        shuffleMode = false;
                        widget.shuffleOn = false;
                      });
                    } else {
                      print("SH: " + shuffleMode.toString());
                      AudioService.setShuffleMode(AudioServiceShuffleMode.all);
                      setState(() {
                        shuffleMode = true;
                        widget.shuffleOn = true;
                      });
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              width: deviceWidth,
              height: deviceHeight * 0.78,
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
                                      _queueMediaItems[songIndex].id);
                                },
                                leading: Container(
                                    height: deviceHeight * 0.06,
                                    child: Container(
                                      color: Colors.grey[200],
                                      child: imageExist
                                          ? Image.file(imageFile)
                                          : Padding(
                                              padding: const EdgeInsets.all(13),
                                              child: Image.asset(
                                                  "assets/audio-tune.png"),
                                            ),
                                    ),
                                    width: deviceWidth * 0.145),
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
                    )
                  : Loading()),
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
                                      AudioService.play();
                                    }
                                  : () {
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
                              color: widget.shuffleOn
                                  ? Colors.white60
                                  : Colors.white,
                              constraints: BoxConstraints.tight(Size(
                                  deviceWidth * 0.09, deviceHeight * 0.09)),
                              icon: Icon(Icons.shuffle),
                              onPressed: () {
                                if (widget.shuffleOn) {
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.none);
                                  setState(() {
                                    widget.shuffleOn = false;
                                    shuffleMode = false;
                                  });
                                } else {
                                  print("Shuffle: " +
                                      widget.shuffleOn.toString());
                                  AudioService.setShuffleMode(
                                      AudioServiceShuffleMode.all);
                                  setState(() {
                                    widget.shuffleOn = true;
                                    shuffleMode = true;
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
    );
  }
}
