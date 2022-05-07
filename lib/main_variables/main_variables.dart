import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fire_uber_customer/models/direction_details_info.dart';
import 'package:geolocator/geolocator.dart';

import '../models/users.dart';

final FirebaseAuth fAuth = FirebaseAuth.instance;
User? currentFirebaseUser;
Users? userModelCurrentInfo;
List dList = []; //online-active drivers Information List
DirectionDetailsInfo? tripDirectionDetailsInfo;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;
String? chosenDriverId = "";
String cloudMessagingServerToken =
    "key=AAAAIrA5hZM:APA91bH_wunjuhDwPIRNMzLWPv1_pQ5dXo-SjM7eN0viY2eoBSGHO1vgzxRWrX_PyhtqrfdMYx0VWYKAlOmlaRVNZlaXcg0_fRhBkfeSh3VVJZGBYVQhVf8s-fWpQj56kj_PxVqadh40";
String userDropOffAddress = "";
String userStartAddress = "";
String driverCarDetails = "";
String driverName = "";
String driverPhone = "";
double countRatingStars = 0.0;
String titleStarsRating = "";
String googleMapKey = "Your Google Map Api Key";
