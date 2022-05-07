import 'dart:async';

import 'package:fire_uber_customer/screens/sign_screen.dart';
import 'package:fire_uber_customer/screens/splashscreen.dart';
import 'package:fire_uber_customer/screens/tabs.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthGate extends StatefulWidget {
  AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  startTimer() {
    Timer(const Duration(seconds: 5), () async {
      print("hello");

      StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SignScreen();
            }

            return TabsScreen();
          });
    });
  }

  @override
  void initState() {
    super.initState();

    //await startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SignScreen();
          }

          return MySplashScreen();
        });
  }
}
