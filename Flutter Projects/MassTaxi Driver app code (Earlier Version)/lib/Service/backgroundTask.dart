import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';

class MyBackgroundTask extends BackgroundAudioTask {
  var _queue = <MediaItem>[];
  List<MediaItem> _allSongs = [];
  List<MediaItem> newqueue = [];
  // List<MediaItem> oldQueue = [];
  int _queueIndex = 0;
  AudioPlayer _audioPlayer = new AudioPlayer();
  MediaItem get mediaItem => _queue[_queueIndex];

  double volume = 1;
  Timer _timer;
  // int time = 10;
  bool playerActivated = false;
  bool newQueuePlayed = false;
  bool connectBackground = false;
  bool connected = false;
  int connectionCounter = 0;

  bool dispose = false;

  // check for audio
  // List<bool> adServed = [true, false];
  // used to hold the current position of the audio
  int currentDuration = 0;

  bool playAd = false;
  bool adLastPlay = false;
  List<MediaItem> _previosQueue;

  // bool fullVolume = true;
  bool decreaseVolume = false;
  int numberOfAdServed = 0;

  bool speakerConnected = true;

  void _handleInterruptions(AudioSession audioSession) {
    bool playInterrupted = false;
    audioSession.becomingNoisyEventStream.listen((_) {
      print("Driver unplug headphones");
      AudioService.pause();
    });
    _audioPlayer.onPlayerStateChanged.listen((playing) {
      playInterrupted = false;
      if (playing == PlayerState.PLAYING) {
        audioSession.setActive(true);
      }
    });
    audioSession.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            if (audioSession.androidAudioAttributes.usage ==
                AndroidAudioUsage.game) {
              // system shold warn user to stop gaming
              _audioPlayer.setVolume(volume * 0.5);
            }
            playInterrupted = false;
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            if (_audioPlayer.state == PlayerState.PLAYING) {
              AudioService.pause();

              // Although pause is async and sets playInterrupted = false,
              // this is done in the sync portion.
              playInterrupted = true;
            }
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _audioPlayer.setVolume(min(1.0, volume * 2));
            playInterrupted = false;
            break;
          case AudioInterruptionType.pause:
            if (playInterrupted) {
              AudioService.play();
            }
            playInterrupted = false;
            break;
          case AudioInterruptionType.unknown:
            playInterrupted = false;
            break;
        }
      }
    });
  }

  @override
  onStart(Map<String, dynamic> params) async {
    _queue.clear();
    List mediaItems = params["data"];
    for (var item in mediaItems) {
      MediaItem mediaItem = MediaItem.fromJson(item);
      _queue.add(mediaItem);
    }
    for (var item in _queue) {
      _allSongs.add(item);
    }
    print("ALL background: " + _allSongs.length.toString());
    AudioSession.instance.then((audioSession) async {
      await audioSession.configure(AudioSessionConfiguration.music());
      _handleInterruptions(audioSession);
    });
    AudioServiceBackground.setState(
        controls: [MediaControl.pause, MediaControl.play],
        playing: false,
        processingState: AudioProcessingState.connecting);
    AudioServiceBackground.setQueue(_queue);

    AudioServiceBackground.setState(controls: [
      MediaControl.skipToPrevious,
      MediaControl.pause,
      MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop
    ], systemActions: [
      MediaAction.seekTo,
      MediaAction.play,
      MediaAction.stop
    ], playing: false, processingState: AudioProcessingState.ready);

    _audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == PlayerState.COMPLETED) {
        print("Completed Status backgrounddd" +
            _queue[_queueIndex].title.toString());
        AudioService.skipToNext();
      }
    });

    await AudioService.playFromMediaId(_queue[_queueIndex].id);

    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!speakerConnected && _audioPlayer.state == PlayerState.PLAYING) {
        AudioService.pause();
      }

      if (connected == false) {
        AudioService.pause();
        connected = true;
      }

      if (playAd && volume < 1) {
        volume += 0.25;
        _audioPlayer.setVolume(volume);
        print("Ad VOl: " + volume.toString());
      }

      if (decreaseVolume && volume > 0 && !playAd) {
        if (volume < 0.2) {
          volume = 0;
          AudioService.pause();
        } else {
          volume = volume - 0.1;
        }
        print("vol down: " + volume.toString());
        _audioPlayer.setVolume(volume);
      } else if (!decreaseVolume && volume < 1) {
        volume += 0.2;
        print("vol up: " + volume.toString());
        _audioPlayer.setVolume(volume);
      }

      // if (time > 10 && playAd) {
      //   // if (time < playTime) {
      //   if (time == playTime) {
      //     if (_audioPlayer.state != PlayerState.COMPLETED &&
      //         playerActivated == true) {
      //       if (PlayerState.PAUSED == _audioPlayer.state) {
      //         _audioPlayer.getCurrentPosition().then((value) {
      //           currentDuration = value;
      //           AudioService.play();
      //         });
      //       }
      //     }
      //   }
      //   print("time : " + time.toString() + "volume : " + volume.toString());
      //   if (_audioPlayer.state == PlayerState.PLAYING) {
      //     time--;
      //   }
      //   // }
      //   if (volume < 1 && _audioPlayer.state == PlayerState.PLAYING) {
      //     volume = volume + 0.2;
      //     print("vol 1: " + volume.toString());
      //     _audioPlayer.setVolume(volume);
      //   }
      // } else if (time <= 10 && playAd) {
      //   if (_audioPlayer.state == PlayerState.PLAYING && adBreakStart) {
      //     if (volume < 0.2) {
      //       volume = 0;
      //     } else {
      //       volume = volume - 0.1;
      //     }
      //     print("vol 2: " + volume.toString());
      //     _audioPlayer.setVolume(volume);
      //     time--;
      //   } else if (_audioPlayer.state == PlayerState.PLAYING &&
      //       !adBreakStart) {
      //     if (volume < 0.5 && time <= 4) {
      //       volume = 0;
      //       _audioPlayer.setVolume(volume);
      //     } else if (time <= 4) {
      //       volume = volume - 0.25;
      //       _audioPlayer.setVolume(volume);
      //     }
      //     print("vol 22: " + volume.toString());
      //     time--;
      //   }
      //   if (time == 0) {
      //     if (_audioPlayer.state != PlayerState.COMPLETED &&
      //         playerActivated == true) {
      //       AudioService.pause();
      //     }
      //     if (adBreakStart) {
      //       time = playTime;
      //       adBreakStart = false;
      //     } else {
      //       // Ad stops Playing
      //       // Play Content
      //       time = 10;
      //       playAd = false;
      //       fullVolume = false;
      //       // volume = 0;
      //     }
      //   }
      // } else if (!playAd && !fullVolume) {
      //   if (PlayerState.PAUSED == _audioPlayer.state && volume == 0) {
      //     _audioPlayer.getCurrentPosition().then((value) {
      //       currentDuration = value;
      //       AudioService.play();
      //     });
      //   }
      //   if (volume < 1) {
      //     volume = volume + 0.2;
      //     print("vol 1 Na: " + volume.toString());
      //     _audioPlayer.setVolume(volume);
      //   } else {
      //     fullVolume = true;
      //   }
      // }
    });
  }

  @override
  Future<void> onTaskRemoved() {
    onStop();
    return super.onTaskRemoved();
  }

  @override
  Future<void> onPlay() {
    if (_audioPlayer.state != PlayerState.COMPLETED && speakerConnected) {
      _audioPlayer.resume();
    } else if (!playAd && speakerConnected) {
      AudioService.playFromMediaId(_queue[_queueIndex].id);
    }
    if ((speakerConnected && _audioPlayer.state != PlayerState.COMPLETED) ||
        (speakerConnected && !playAd)) {
      // notifies everyone about the current state
      // of the audio to playing by making it true
      AudioServiceBackground.setState(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
            MediaControl.rewind,
            MediaControl.fastForward,
          ],
          systemActions: [
            MediaAction.seekTo,
            MediaAction.play,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          ],
          position: Duration(milliseconds: currentDuration),
          playing: true,
          processingState: AudioProcessingState.ready);
      AudioServiceBackground.setMediaItem(mediaItem);
    }
    return super.onPlay();
  }

  @override
  Future<void> onPause() async {
    _audioPlayer.pause();
    currentDuration = await _audioPlayer.getCurrentPosition();
    // notifies everyone about the current state
    // of the audio to not playing by making it false
    AudioServiceBackground.setState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.rewind,
          MediaControl.fastForward,
        ],
        systemActions: [
          MediaAction.seekTo,
          MediaAction.pause,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          MediaAction.seekTo,
        ],
        position: Duration(milliseconds: currentDuration),
        playing: false,
        processingState: AudioProcessingState.ready);
    AudioServiceBackground.setMediaItem(mediaItem);
  }

  @override
  Future<void> onPlayFromMediaId(String mediaId) {
    if (newQueuePlayed == false && connectBackground == true) {
      _queue.clear();
      for (var item in newqueue) {
        _queue.add(item);
      }
      AudioServiceBackground.setQueue(_queue);
      newQueuePlayed = true;
    }
    if (_queue.length != 0) {
      for (var i = 0; i < _queue.length; i++) {
        if (mediaId == _queue[i].id) {
          _queueIndex = i;
          break;
        }
      }
      _audioPlayer.play(_queue[_queueIndex].id);
      if (playerActivated == false) {
        playerActivated = true;
      }
      if (connectionCounter == 1) {
        connectBackground = true;
      }
      connectionCounter++;
    }
    currentDuration = 0;
    AudioServiceBackground.setState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
          MediaControl.rewind,
          MediaControl.fastForward,
        ],
        systemActions: [
          MediaAction.seekTo,
          MediaAction.play
        ],
        playing: true,
        processingState: AudioProcessingState.ready,
        position: Duration(milliseconds: currentDuration));
    // updates background UI to the current audio
    if (_queue.length != 0) {
      AudioServiceBackground.setMediaItem(_queue[_queueIndex]);
    }

    if (adLastPlay) {
      adLastPlay = false;
      newqueue.clear();
      newqueue = _previosQueue;
      newQueuePlayed = false;
    }
    return super.onPlayFromMediaId(mediaId);
  }

  @override
  Future<void> onSkipToPrevious() {
    if (_queueIndex > 0 && _queueIndex < _queue.length && !playAd) {
      _queueIndex--;
      // notifies everyone about the current state
      // of the audio to skipping to previous audio
      AudioServiceBackground.setState(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
            MediaControl.rewind,
            MediaControl.fastForward,
          ],
          playing: true,
          processingState: AudioProcessingState.skippingToPrevious);
      currentDuration = 0;
      _audioPlayer.play(_queue[_queueIndex].id);
      // notifies everyone about the current state
      // of the audio to playing audio
      AudioServiceBackground.setState(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
            MediaControl.rewind,
            MediaControl.fastForward,
          ],
          systemActions: [
            MediaAction.seekTo,
            MediaAction.play,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious
          ],
          playing: true,
          processingState: AudioProcessingState.ready,
          position: Duration(milliseconds: currentDuration));
      // updates background UI to the current audio
      AudioServiceBackground.setMediaItem(_queue[_queueIndex]);
    }
    return super.onSkipToPrevious();
  }

  @override
  Future<void> onSkipToNext() async {
    if (_queueIndex < _queue.length - 1 &&
        (!playAd || _audioPlayer.state == PlayerState.COMPLETED)) {
      double adDuration = _queue[_queueIndex].duration.inSeconds.toDouble();
      double slot = adDuration / 30;
      // print("ad: " +
      //     _queue[_queueIndex].title +
      //     " slot: " +
      //     slot.ceil().toString() +
      //     " duration: " +
      //     adDuration.toString());
      _queueIndex++;
      if (playAd) {
        numberOfAdServed += slot.ceil();
        // 2 second silence used for Audio Source check
        AudioServiceBackground.setState(
            controls: [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
              MediaControl.rewind,
              MediaControl.fastForward,
            ],
            playing: false,
            position: Duration(milliseconds: currentDuration),
            processingState: AudioProcessingState.completed);
        print("PROCESSING STATUS: Completed");
        await Future.delayed(Duration(seconds: 2));
      }
      // notifies everyone about the current state
      // of the audio to skipping to next
      AudioServiceBackground.setState(controls: [
        MediaControl.skipToPrevious,
        MediaControl.pause,
        MediaControl.skipToNext,
        MediaControl.rewind,
        MediaControl.fastForward,
      ], playing: true, processingState: AudioProcessingState.skippingToNext);
      _audioPlayer.play(_queue[_queueIndex].id);
      currentDuration = 0;
      // print("PROCESSING STATUS: Skip Next back");
      await Future.delayed(Duration(milliseconds: 300));
      // notifies everyone about the current state
      // of the audio to playing audio
      AudioServiceBackground.setState(
          controls: [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
            MediaControl.rewind,
            MediaControl.fastForward,
          ],
          systemActions: [
            MediaAction.seekTo,
            MediaAction.play,
            MediaAction.skipToNext,
            MediaAction.skipToPrevious,
          ],
          playing: true,
          processingState: AudioProcessingState.ready,
          position: Duration(milliseconds: currentDuration));
      // updates background UI to the current audio
      AudioServiceBackground.setMediaItem(_queue[_queueIndex]);
    } else {
      if (PlayerState.COMPLETED == _audioPlayer.state) {
        AudioServiceBackground.setState(controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.rewind,
          MediaControl.fastForward,
        ], playing: false, processingState: AudioProcessingState.completed);
        double adDuration = _queue[_queueIndex].duration.inSeconds.toDouble();
        double slot = adDuration / 30;
        numberOfAdServed += slot.ceil();
        // print("ad: " +
        //     _queue[_queueIndex].title +
        //     " slot: " +
        //     slot.ceil().toString() +
        //     " duration: " +
        //     adDuration.toString());
        playAd = false;
      }
    }
    return super.onSkipToNext();
  }

  @override
  Future<void> onSeekTo(Duration position) {
    if (!playAd) {
      AudioServiceBackground.setState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
          MediaControl.rewind,
          MediaControl.fastForward,
        ],
        systemActions: [MediaAction.seekTo, MediaAction.play],
        playing: false,
        processingState: AudioProcessingState.buffering,
        // the position after the seek
        position: position,
      );
      _audioPlayer.seek(position);
      _audioPlayer.resume();

      AudioServiceBackground.setState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
          MediaControl.rewind,
          MediaControl.fastForward,
        ],
        systemActions: [
          MediaAction.seekTo,
          MediaAction.play,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        ],
        playing: true,
        processingState: AudioProcessingState.ready,
        // the position after the seek
        position: position,
      );
    } else {
      print("elsfa");
      AudioServiceBackground.setState(
        controls: [
          MediaControl.skipToPrevious,
          _audioPlayer.state != PlayerState.PLAYING
              ? MediaControl.play
              : MediaControl.pause,
          MediaControl.skipToNext,
          MediaControl.rewind,
          MediaControl.fastForward,
        ],
        systemActions: [
          MediaAction.seekTo,
          MediaAction.play,
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
        ],
        playing: _audioPlayer.state != PlayerState.PLAYING ? false : true,
        // the position after the seek
        position: _audioPlayer.state != PlayerState.PLAYING
            ? Duration(milliseconds: currentDuration)
            : null,
      );
    }
    return super.onSeekTo(position);
  }

  @override
  Future<void> onRewind() async {
    if (!playAd) {
      int substraction = 10 * 1000;
      int tempCurrentDuration = await _audioPlayer.getCurrentPosition();
      tempCurrentDuration -= substraction;
      if (tempCurrentDuration >= 0) {
        AudioService.seekTo(Duration(milliseconds: tempCurrentDuration));
      } else {
        AudioService.seekTo(Duration(milliseconds: 0));
      }
    }
    return super.onRewind();
  }

  @override
  Future<void> onFastForward() async {
    if (!playAd) {
      int addition = 10 * 1000;
      int tempCurrentDuration = await _audioPlayer.getCurrentPosition();
      tempCurrentDuration += addition;
      if (tempCurrentDuration <= await _audioPlayer.getDuration()) {
        AudioService.seekTo(Duration(milliseconds: tempCurrentDuration));
      } else {
        AudioService.seekTo(
            Duration(milliseconds: await _audioPlayer.getDuration()));
      }
    }
    return super.onFastForward();
  }

  @override
  Future<void> onSetShuffleMode(AudioServiceShuffleMode shuffleMode) {
    if (newQueuePlayed == false &&
        AudioServiceShuffleMode.all == shuffleMode &&
        newqueue.length != 0) {
      _queue.clear();
      for (var item in newqueue) {
        _queue.add(item);
      }
      AudioServiceBackground.setQueue(_queue);
      newQueuePlayed = true;
      _queue.shuffle();
      _queueIndex = 0;
      onPlayFromMediaId(_queue[_queueIndex].id);
      print("Entered");
    } else {
      if (AudioServiceShuffleMode.all == shuffleMode && newqueue.length != 0) {
        _queue.shuffle();
        _queueIndex = 0;
        onPlayFromMediaId(_queue[_queueIndex].id);
      } else if (AudioServiceShuffleMode.none == shuffleMode &&
          newqueue.length != 0 &&
          !playAd) {
        String _currentlyPlayingID = _queue[_queueIndex].id;
        _queue.sort((a, b) => a.title.compareTo(b.title));
        // for (var i = 0; i < _queue.length; i++) {
        //   print("Sorted: " + i.toString() + " " + _queue[i].title);
        // }
        for (var i = 0; i < _queue.length; i++) {
          if (_queue[i].id == _currentlyPlayingID) {
            print("CP: " + _queue[i].title);
            _queueIndex = i;
            break;
          }
        }
        print("new index: " + _queueIndex.toString());
      }
    }
    return super.onSetShuffleMode(shuffleMode);
  }

  @override
  Future<int> onCustomAction(String name, arguments) async {
    print("Custom Action" + _allSongs.length.toString());
    // Future<bool> a;
    if (name == "addQueue") {
      List<MediaItem> _newQueue = [];
      for (var item in arguments) {
        for (var media in _allSongs) {
          if (item == media.id) {
            _newQueue.add(media);
          }
        }
      }
      newqueue.clear();
      newqueue = _newQueue;
      newQueuePlayed = false;
      print("Inside : " + newqueue.length.toString());
    } else if (name == "dispose") {
      dispose = true;
    } else if (name == "decreaseVolume") {
      decreaseVolume = true;
    } else if (name == "playAD") {
      playAd = true;
      numberOfAdServed = 0;
      List<String> mediaIds = [];
      for (var item in arguments) {
        mediaIds.add(item);
      }
      List<MediaItem> _newQueues = assignMediaItems(mediaIds, _allSongs);
      List<String> oldqueueMediaIds = [];
      List<String> originalQueueMediaIds = [];
      int _oldDuration = 0;
      String _oldMediaID = _queue[_queueIndex].id;
      for (var item in newqueue) {
        oldqueueMediaIds.add(item.id);
        // print("a: " + item.title);
      }
      for (var item in _queue) {
        originalQueueMediaIds.add(item.id);
        // print("b: " + item.title);
      }
      _previosQueue = assignMediaItems(oldqueueMediaIds, _allSongs);
      List<MediaItem> _originalQueue =
          assignMediaItems(originalQueueMediaIds, _allSongs);
      if (_audioPlayer.state != PlayerState.COMPLETED &&
          playerActivated == true) {
        _audioPlayer.getCurrentPosition().then((value) {
          _oldDuration = value;
        });
      }
      newqueue.clear();
      newqueue = _newQueues;
      newQueuePlayed = false;
      AudioService.setShuffleMode(AudioServiceShuffleMode.all);
      await waitUntilAdFinishes();
      print("Finished");
      volume = 0;
      decreaseVolume = false;
      newqueue.clear();
      newqueue = _originalQueue;
      newQueuePlayed = false;
      adLastPlay = true;
      // NEW
      await Future.delayed(Duration(milliseconds: 1500));
      //
      AudioService.playFromMediaId(_oldMediaID);
      AudioService.seekTo(Duration(milliseconds: _oldDuration));
      return numberOfAdServed;
    } else if (name == "stopAD") {
      AudioService.pause();
      playAd = false;
    } else if (name == "speakerStream") {
      if (arguments == false) {
        AudioService.pause();
      }
      speakerConnected = arguments;
      print("Back : " + speakerConnected.toString());
    }
    return null;
    // return super.onCustomAction(name, arguments);
  }

  @override
  Future<void> onStop() async {
    _audioPlayer.stop();
    await AudioServiceBackground.setState(
        controls: [],
        processingState: AudioProcessingState.stopped,
        playing: false);
    print("STOP ");
    if (!dispose) {
      exit(0); // closes the app
    } else {
      dispose = false;
      _timer.cancel();
    }
    return await super.onStop();
  }

  Future<bool> waitUntilAdFinishes() async {
    return await Future.doWhile(() {
      return Future.delayed(Duration(seconds: 1), () {
        return playAd;
      });
    });
  }

  List<MediaItem> assignMediaItems(
      List<String> mediaIds, List<MediaItem> allSo) {
    List<MediaItem> _localQueue = [];
    for (var item in mediaIds) {
      for (var media in allSo) {
        if (item == media.id) {
          _localQueue.add(media);
        }
      }
    }
    return _localQueue;
  }
}
