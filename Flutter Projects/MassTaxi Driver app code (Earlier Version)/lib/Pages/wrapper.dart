import 'package:audio_record/Classes/adBreakAlgorithm.dart';
import 'package:audio_record/Pages/Home/startPage.dart';
import 'package:audio_record/Pages/Home/trackPlayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:headset_event/headset_event.dart';
import 'package:system_shortcuts/system_shortcuts.dart';

class Wrapper extends StatefulWidget {
  final String phoneNumber, phoneID, driverDocID;
  final Function logOutStatus;
  Wrapper(
      {this.phoneNumber, this.logOutStatus, this.phoneID, this.driverDocID});
  static bool speakConnection;
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  bool showTrackPlayer = false;
  void toggleView() {
    setState(() {
      showTrackPlayer = !showTrackPlayer;
    });
  }

  FlutterBluetoothSerial fls;
  bool bluetoothState = false;
  bool wiredState = false;
  bool speakerConnected = false;

  HeadsetEvent headsetPlugin = new HeadsetEvent();

  final ValueNotifier<bool> _speakerConnected = ValueNotifier<bool>(false);
  final ValueNotifier<int> _numberOfAdBrake = ValueNotifier<int>(0);

  // NEW
  final ValueNotifier<CompilationForServe> _compilationForServe =
      ValueNotifier<CompilationForServe>(new CompilationForServe());

  @override
  void initState() {
    _numberOfAdBrake.value = 1;
    // used to check speaker connection
    fls = FlutterBluetoothSerial.instance;

    fls.onStateChanged().listen((event) {
      bluetoothState = (event == 1) ? true : false;

      if (bluetoothState) {
        speakerConnected = bluetoothState;
      } else if (!bluetoothState && wiredState) {
        speakerConnected = true;
      } else {
        speakerConnected = bluetoothState;
      }

      _speakerConnected.value = speakerConnected;
      Wrapper.speakConnection = _speakerConnected.value;
      // print("Bstate : " + speakerConnected.toString());
    });

    /// if headset is plugged
    headsetPlugin.getCurrentState.then((_val) {
      if (_val.index == 0 || bluetoothState) {
        _speakerConnected.value = true;
        wiredState = true;
      } else {
        _speakerConnected.value = false;
        wiredState = false;
      }
      Wrapper.speakConnection = _speakerConnected.value;
      // print("Headset : " + headsetEvent.index.toString());
    });

    /// Detect the moment headset is plugged or unplugged
    headsetPlugin.setListener((_val) {
      if (_val.index == 0 || bluetoothState) {
        _speakerConnected.value = true;
        wiredState = true;
      } else {
        _speakerConnected.value = false;
        wiredState = false;
      }
      Wrapper.speakConnection = _speakerConnected.value;
    });

    // Turns off the bluetooth and turns is it on againif its on
    // when the app is started because our bluetooth state listener
    // wont know if the bluetooth is connected or
    // not if it was turned on before the app started and if it was off it will
    // turn it on
    SystemShortcuts.checkBluetooth.then((value) async {
      if (value) {
        SystemShortcuts.bluetooth();
        await Future.delayed(Duration(seconds: 1));
        SystemShortcuts.bluetooth();
      } else {
        SystemShortcuts.bluetooth();
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Future<bool> _onBackPressed() {
      return showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Existing this way is not allowed.'),
                content: Text('To Exist Swipe it Off!'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    child: Text('OK'),
                  )
                ],
              );
            },
          ) ??
          false;
    }

    return WillPopScope(
      child: showTrackPlayer
          ? TrackPlayer(
              toggleView: toggleView,
              compilationForServe: _compilationForServe.value,
            )
          : StartPage(
              toggleView: toggleView,
              speakCon: _speakerConnected,
              compilationForServeVN: _compilationForServe,
              driverDocID: widget.driverDocID,
              logOutStatus: widget.logOutStatus,
            ),
      onWillPop: _onBackPressed,
    );
  }
}
