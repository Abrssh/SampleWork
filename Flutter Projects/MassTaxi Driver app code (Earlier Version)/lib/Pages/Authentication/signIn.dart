import 'package:audio_record/Pages/Authentication/changePhonePage.dart';
import 'package:audio_record/Pages/Authentication/createDrivePage.dart';
import 'package:audio_record/Pages/wrapper.dart';
import 'package:audio_record/Service/databaseServ.dart';
import 'package:audio_record/Shared/loading.dart';
import 'package:device_info/device_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_ui/firebase_auth_ui.dart';
import 'package:firebase_auth_ui/providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String err = "";
  bool loaded = false;

  Future<String> getPhoneID() async {
    DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
    return androidDeviceInfo.androidId;
  }

  String phoneId = "";

  @override
  void initState() {
    getPhoneID().then((phoneVal) {
      print("phone------------" + phoneVal);
      phoneId = phoneVal;
      _checkLoginState().then((userVal) {
        if (userVal != null) {
          DatabaseService()
              .driverAccountExist(userVal.phoneNumber)
              .then((value) {
            setState(() {
              loaded = true;
            });
            if (value.isNotEmpty) {
              // print("val leng: " + value.length.toString());
              if (value.length == 1 &&
                  !value[0].banned &&
                  value[0].phoneID == phoneId) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Wrapper(
                              phoneNumber: userVal.phoneNumber,
                              phoneID: phoneId,
                              driverDocID: value[0].docID,
                              logOutStatus: logOutStatus,
                            )));
              } else if (value.length == 1 && value[0].banned) {
                logOut();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Your Account has been banned."),
                  backgroundColor: Colors.red,
                ));
              } else if (value.length == 1 &&
                  !value[0].banned &&
                  value[0].phoneID != phoneId) {
                logOut();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      "Changing your smartphone without the proper process is " +
                          "not allowed."),
                  backgroundColor: Colors.red,
                ));
              }
            } else {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateDriverPage(
                          phoneNumber: userVal.phoneNumber,
                          phoneID: phoneId,
                          logOutStatus: logOutStatus)));
            }
          });
        } else {
          setState(() {
            loaded = true;
          });
        }
      });
    });
    super.initState();
  }

  void logOut() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuthUi.instance().logout().then((value) => logOutStatus());
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final deviceHeight = deviceSize.height;
    final deviceWidth = deviceSize.width;
    // err = "unable to login";
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign In"),
        centerTitle: true,
      ),
      body: Center(
        child: loaded
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "STATUS",
                    style: TextStyle(
                        fontSize: deviceWidth * 0.08,
                        fontWeight: FontWeight.bold),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      err,
                      style: TextStyle(
                          fontSize: deviceWidth * 0.07,
                          fontWeight: FontWeight.w300,
                          color: Colors.red),
                    ),
                  ),
                  SizedBox(
                    height: deviceHeight * 0.01,
                  ),
                  Text(
                    "Tap the button below to login",
                    style: TextStyle(
                        fontSize: deviceWidth * 0.06,
                        fontWeight: FontWeight.w300),
                  ),
                  ElevatedButton(
                      onPressed: logIn,
                      child: Text(
                        "Login",
                        style: TextStyle(fontSize: deviceWidth * 0.06),
                      )),
                  ElevatedButton(
                      onPressed: goToChangeSmartPhone,
                      child: Text(
                        "Change Phone",
                        style: TextStyle(fontSize: deviceWidth * 0.06),
                      ))
                ],
              )
            : Loading(),
      ),
    );
  }

  Future<User> _checkLoginState() async {
    await Firebase.initializeApp();
    return FirebaseAuth.instance.currentUser;
  }

  logOutStatus() {
    setState(() {
      err = "Logged Out";
    });
  }

  void logIn() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirebaseAuthUi.instance()
          .launchAuth([AuthProvider.phone()]).then((userVal) {
        setState(() {
          err = "Logged In";
          loaded = false;
        });
        DatabaseService().driverAccountExist(userVal.phoneNumber).then((value) {
          setState(() {
            loaded = true;
          });
          if (value.length == 1 &&
              !value[0].banned &&
              value[0].phoneID == phoneId) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Wrapper(
                          phoneNumber: userVal.phoneNumber,
                          phoneID: phoneId,
                          driverDocID: value[0].docID,
                          logOutStatus: logOutStatus,
                        )));
          } else if (value.length == 1 && value[0].banned) {
            logOut();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("Your Account has been banned."),
              backgroundColor: Colors.red,
            ));
          } else if (value.length == 1 &&
              !value[0].banned &&
              value[0].phoneID != phoneId) {
            logOut();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Changing your smartphone without the proper process is " +
                      "not allowed."),
              backgroundColor: Colors.red,
            ));
          } else {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateDriverPage(
                        phoneNumber: userVal.phoneNumber,
                        phoneID: phoneId,
                        logOutStatus: logOutStatus)));
          }
        });
      }).catchError((e) {
        setState(() {
          loaded = true;
          if (e is PlatformException) {
            if (e.code == FirebaseAuthUi.kUserCancelledError) {
              err = "You have cancelled Login";
            } else {
              err = e.message ?? "unk error";
            }
          }
        });
      });
    }
  }

  void goToChangeSmartPhone() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirebaseAuthUi.instance()
          .launchAuth([AuthProvider.phone()]).then((userVal) {
        setState(() {
          loaded = false;
        });
        DatabaseService()
            .driverAccountExist(userVal.phoneNumber)
            .then((value) async {
          if (value.isNotEmpty) {
            err = "";
            setState(() {
              loaded = true;
            });
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChangePhonePage(
                          driverID: value[0].docID,
                          systemAccountID: value[0].systemAccountID,
                          phoneID: phoneId,
                        )));
          } else {
            await logOut();
            err = "No driver registered with this number";
            setState(() {
              loaded = true;
            });
          }
        });
      }).catchError((e) {
        if (e is PlatformException) {
          if (e.code == FirebaseAuthUi.kUserCancelledError) {
            err = "You have cancelled Login";
          } else {
            err = e.message ?? "unk error";
          }
        }
        setState(() {});
      });
    }
  }
}
