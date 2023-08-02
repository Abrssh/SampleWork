import 'package:flutter/material.dart';

class Help extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // final deviceSize = MediaQuery.of(context).size;
    // final deviceHeight = deviceSize.height;
    // final deviceWidth = deviceSize.width;
    return Scaffold(
        appBar: AppBar(
          title: Text("Help Example"),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                margin: EdgeInsets.all(8),
                color: Colors.grey[50],
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Explain One Feature",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "These lines are to be used to explain one feature in detail in an easily understandable manner in which the user can easily understand and refer back to.",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            wordSpacing: 10),
                      )
                    ],
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.all(8),
                color: Colors.grey[50],
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "Before we start I will like to show you how to register into our system which is the first step of a lot of apps out there. When you first open the app you will be greeted by the sign in page with the register button up there in the top right corner. ",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            wordSpacing: 10),
                      )
                    ],
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.all(8),
                color: Colors.grey[50],
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Sign In",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "As I have mentioned above the first page of our app is the sign in page which if you already have an account you can go in and sign in to the system. Once you have signed in our system will store a refresh token which will be used to let the user enter into the system without writing the email and password every time they get into the app. This will be disabled if the account gets deleted, modified or the user sign out of the app. ",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            wordSpacing: 10),
                      )
                    ],
                  ),
                ),
              ),
              Card(
                margin: EdgeInsets.all(8),
                color: Colors.grey[50],
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Map",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        "In the ticket page you will find a bottom navigation bar at the bottom of the app containing two buttons one which is highlighted is the ticket page your currently in and the other one is the map page button which has a train sign in it.",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            wordSpacing: 10),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}
