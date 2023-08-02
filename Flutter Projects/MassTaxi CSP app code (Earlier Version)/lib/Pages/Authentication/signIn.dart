import 'package:csp_app/Pages/Home/paths.dart';
import 'package:csp_app/Services/databaseServ.dart';
import 'package:csp_app/Shared/loading.dart';
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

  @override
  void initState() {
    _checkLoginState().then((userVal) {
      if (userVal != null) {
        DatabaseService().cspAccountExist(userVal.phoneNumber).then((value) {
          if (value.docs.length == 1) {
            if (value.docs[0].get("status") == true &&
                !value.docs[0].get("disabled")) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Paths(
                            phoneNumber: userVal.phoneNumber,
                          )));
              setState(() {
                loaded = true;
              });
            } else {
              err = "Access Denied";
              logOut();
              setState(() {
                loaded = true;
              });
            }
          } else {
            err = "This number is not registered";
            logOut();
            setState(() {
              loaded = true;
            });
          }
        });
      } else {
        setState(() {
          loaded = true;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    loaded = true;
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    err,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: Colors.red),
                  ),
                  Text(
                    "Tap the button below to login",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300),
                  ),
                  ElevatedButton(onPressed: logIn, child: Text("Login"))
                ],
              )
            : Loading(),
      ),
    );
  }

  void logOut() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseAuthUi.instance().logout();
    }
  }

  Future<User> _checkLoginState() async {
    await Firebase.initializeApp();
    return FirebaseAuth.instance.currentUser;
  }

  void logIn() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirebaseAuthUi.instance()
          .launchAuth([AuthProvider.phone()]).then((userVal) {
        setState(() {
          loaded = false;
        });
        DatabaseService().cspAccountExist(userVal.phoneNumber).then((value) {
          if (value.docs.length == 1) {
            if (value.docs[0].get("status") == true &&
                !value.docs[0].get("disabled")) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => Paths(
                            phoneNumber: userVal.phoneNumber,
                          )));
              setState(() {
                loaded = true;
              });
            } else {
              err = "Access Denied";
              logOut();
              setState(() {
                loaded = true;
              });
            }
          } else {
            err = "This number is not registered";
            logOut();
            setState(() {
              loaded = true;
            });
          }
          // loaded = true;
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
}
