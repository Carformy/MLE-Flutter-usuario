import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fire_uber_customer/providers/google_map_functions.dart';

import 'package:fire_uber_customer/main_variables/main_variables.dart';
import 'package:fire_uber_customer/screens/tabs.dart';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  _MySplashScreenState createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {
  startTimer() {
    fAuth.currentUser != null
        ? GoogleMapFunctions.readCurrentOnlineUserInfo()
        : null;

    Timer(const Duration(seconds: 4), () async {
      currentFirebaseUser = fAuth.currentUser;
      Navigator.push(context, MaterialPageRoute(builder: (c) => TabsScreen()));
    });
  }

  @override
  void initState() {
    super.initState();

    startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.lightBlue.shade100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset('images/splash.json'),
              Text(
                "Uber Customer Application",
                style: TextStyle(
                    fontSize: 24,
                    color: Colors.lightBlue,
                    fontWeight: FontWeight.bold),
              ),
              // Image.asset("images/logo.png"),
              // const SizedBox(
              //   height: 10,
              // ),
              // const Text(
              //   "Uber & inDriver Clone App",
              //   style: TextStyle(
              //       fontSize: 24,
              //       color: Colors.white,
              //       fontWeight: FontWeight.bold),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
