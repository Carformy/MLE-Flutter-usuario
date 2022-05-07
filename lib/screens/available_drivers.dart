import 'dart:async';
import 'dart:math';

import 'package:fire_uber_customer/screens/currentTripInfo.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:fire_uber_customer/providers/google_map_functions.dart';
import 'package:fire_uber_customer/main_variables/main_variables.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fire_uber_customer/main_variables/main_variables.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/geofire_provider.dart';
import '../models/nearest_drivers.dart';

class AvailableDrivers extends StatefulWidget {
  String? originLocationLatitude;
  String? originLocationLongitude;
  String? destinationLocationLatitude;
  String? destinationLocationLongitude;
  String? userName;
  String? userPhone;
  String? userEmail;
  String? userPhoto;
  String? originAddress;
  String? destinationAddress;
  double? currentLatitude;
  double? currentLongitude;
  List<nearestDrivers>? onlineNearByAvailable = [];

  AvailableDrivers(
      {Key? key,
      this.originLocationLatitude,
      this.originLocationLongitude,
      this.destinationLocationLatitude,
      this.destinationLocationLongitude,
      this.userName,
      this.userPhone,
      this.userEmail,
      this.userPhoto,
      this.originAddress,
      this.destinationAddress,
      this.currentLatitude,
      this.currentLongitude,
      this.onlineNearByAvailable})
      : super(key: key);

  @override
  State<AvailableDrivers> createState() => _AvailableDriversState();
}

class _AvailableDriversState extends State<AvailableDrivers> {
  String fareAmount = "";
  bool activeNearbyDriverKeysLoaded = false;

  List<nearestDrivers> onlineNearByAvailableDriversList = [];
  List driversList = [];

  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;
  String userRideRequestStatus = "";
  DatabaseReference? referenceRideRequest;

  @override
  void initState() {
    super.initState();

    print("widget.currentLatitude");
    print(widget.currentLatitude);
    print(widget.currentLongitude);

    print("widget.onlineNearByAvailable");
    print(widget.onlineNearByAvailable);

    searchNearestOnlineDrivers(widget.onlineNearByAvailable);
    //initializeGeoFireListener(widget.currentLatitude, widget.currentLongitude);
  }

  getFareAmountAccordingToVehicleType(int index) {
    if (tripDirectionDetailsInfo != null) {
      if (driversList[index]["carType"].toString() == "bike") {
        fareAmount =
            (GoogleMapFunctions.calculateFareAmountFromOriginToDestination(
                        tripDirectionDetailsInfo!) /
                    2)
                .toStringAsFixed(1);
      }
      if (driversList[index]["carType"].toString() ==
          "Elegant") //means executive type of car - more comfortable pro level
      {
        fareAmount =
            (GoogleMapFunctions.calculateFareAmountFromOriginToDestination(
                        tripDirectionDetailsInfo!) *
                    2)
                .toStringAsFixed(1);
      }
      if (driversList[index]["carType"].toString() ==
          "uber-go") // non - executive car - comfortable
      {
        fareAmount =
            (GoogleMapFunctions.calculateFareAmountFromOriginToDestination(
                    tripDirectionDetailsInfo!))
                .toString();
      }
    }
    return fareAmount;
  }

  searchNearestOnlineDrivers(onlineNearByAvailable) async {
    //no active driver available
    if (onlineNearByAvailable.length == 0) {
      //cancel/delete the RideRequest Information
      // referenceRideRequest!.remove();

      // setState(() {
      //   polyLineSet.clear();
      //   markersSet.clear();
      //   circlesSet.clear();
      //   pLineCoOrdinatesList.clear();
      // });

      Fluttertoast.showToast(
          msg:
              "No Online Nearest Driver Available. Search Again after some time, Restarting App Now.");

      // Future.delayed(const Duration(milliseconds: 4000), () {
      //   SystemNavigator.pop();
      // });

      return;
    }

    //active driver available
    await retrieveOnlineDriversInformation(onlineNearByAvailable);
  }

  retrieveOnlineDriversInformation(List onlineNearestDriversList) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");
    for (int i = 0; i < onlineNearestDriversList.length; i++) {
      await ref
          .child(onlineNearestDriversList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;
        //  dList.add(driverKeyInfo);

        setState(() {
          driversList.add(driverKeyInfo);
        });
        print("dListInfo");
        print(driversList);
        print("driversList.length");
        print(driversList.length);
      });
    }
  }

  sendNotificationToDriverNow(String chosenDriverId) {
    //assign/SET rideRequestId to newRideStatus in
    // Drivers Parent node for that specific choosen driver
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriverId)
        .child("newRideStatus")
        .set(chosenDriverId);

    //automate the push notification service
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriverId)
        .child("token")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String deviceRegistrationToken = snap.snapshot.value.toString();

        //send Notification Now
        GoogleMapFunctions.sendNotificationToDriverNow(
          deviceRegistrationToken,
          chosenDriverId,
          context,
        );

        Fluttertoast.showToast(msg: "Notification sent Successfully.");
      } else {
        Fluttertoast.showToast(msg: "Please choose another driver.");
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildAppBar(),
      body: ListView.builder(
        itemCount: driversList.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              DatabaseReference? referenceRideRequest = FirebaseDatabase
                  .instance
                  .ref()
                  .child("deals")
                  .child(driversList[index]["id"].toString());

              Map originLocationMap = {
                //"key": value,
                "latitude": widget.originLocationLatitude,
                "longitude": widget.originLocationLongitude,
              };

              Map destinationLocationMap = {
                //"key": value,
                "latitude": widget.destinationLocationLatitude,
                "longitude": widget.destinationLocationLongitude,
              };

              print(userModelCurrentInfo);

              var currentUser_uid = FirebaseAuth.instance.currentUser!.uid;

              var rng = new Random();
              var code = rng.nextInt(9000) + 999;
              String pincode = code.toString();

              print("index print");
              print(index);
              String farePayment = getFareAmountAccordingToVehicleType(index);

              Map userInformationMap = {
                "origin": originLocationMap,
                "destination": destinationLocationMap,
                "time": DateTime.now().toString(),
                "userName": widget.userName,
                "userPhone": widget.userPhone,
                "userEmail": widget.userEmail,
                "userId": currentUser_uid,
                "userPhoto": widget.userPhoto,
                "originAddress": widget.originAddress,
                "destinationAddress": widget.destinationAddress,
                "driverId": driversList[index]["id"].toString(),
                "status": "waiting",
                "driverName": driversList[index]["name"].toString(),
                "driverPhone": driversList[index]["phone"].toString(),
                "driverPhoto": driversList[index]["photoURL"].toString(),
                "driverType": driversList[index]["carType"].toString(),
                "driverRating": driversList[index]["ratings"].toString(),
                "carBrand": driversList[index]["carBrand"].toString(),
                "carModel": driversList[index]["carModel"].toString(),
                "carNumber": driversList[index]["carNumber"].toString(),
                "timestamp": ServerValue.timestamp,
                "totalPayment": farePayment,
                "duration": tripDirectionDetailsInfo!.duration_value,
                "distance": tripDirectionDetailsInfo!.distance_value,
                "pincode": pincode,
              };

              referenceRideRequest.set(userInformationMap);

              setState(() {
                chosenDriverId = driversList[index]["id"].toString();
              });

              FirebaseDatabase.instance
                  .ref()
                  .child("drivers")
                  .child(driversList[index]["id"].toString())
                  .once()
                  .then((snap) {
                if (snap.snapshot.value != null) {
                  //send notification to that specific driver
                  sendNotificationToDriverNow(chosenDriverId!);

                  tripRideRequestInfoStreamSubscription =
                      referenceRideRequest.onValue.listen((eventSnap) async {
                    if (eventSnap.snapshot.value == null) {
                      return;
                    }

                    if ((eventSnap.snapshot.value as Map)["status"] != null) {
                      userRideRequestStatus =
                          (eventSnap.snapshot.value as Map)["status"]
                              .toString();
                    }

                    //status = accepted
                    if (userRideRequestStatus == "accepted") {
                      print("accepted");

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CurrentTripInfo(
                                    dealId: driversList[index]["id"],
                                    timestamp: driversList[index]["timestamp"]
                                        .toString(),
                                    driverId: driversList[index]["driverId"],
                                  )));
                    }
                  });
                } else {
                  Fluttertoast.showToast(
                      msg: "This driver do not exist. Try again.");
                }
              });

              // setState(() {
              //   chosenDriverId = driversList[index]["id"].toString();
              // });
              // Navigator.pop(context, "driverChoosed");
            },
            child: Container(
              margin: EdgeInsets.only(bottom: 20),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(left: 24, right: 24, top: 50),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$ ' + getFareAmountAccordingToVehicleType(index),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SmoothStarRating(
                          rating: driversList[index]["ratings"] == null
                              ? 0.0
                              : double.parse(driversList[index]["ratings"]),
                          color: Colors.white,
                          borderColor: Colors.white,
                          allowHalfRating: true,
                          starCount: 5,
                          size: 25,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Name",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  driversList[index]["name"],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Brand",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  driversList[index]["carBrand"],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Model",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  driversList[index]["carModel"],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Car No",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  driversList[index]["carNumber"],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                )
                              ],
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    right: 40,
                    child: Image.asset(
                      "images/" +
                          driversList[index]["carType"].toString() +
                          ".png",
                      height: 100,
                    ),
                  )
                ],
              ),
            ),
            // child: Card(
            //   color: Colors.grey,
            //   elevation: 3,
            //   shadowColor: Colors.green,
            //   margin: const EdgeInsets.all(8),
            //   child: ListTile(
            //     leading: Padding(
            //       padding: const EdgeInsets.only(top: 2.0),
            //       child: Image.asset(
            //         "images/" +
            //             driversList[index]["carType"].toString() +
            //             ".png",
            //         width: 70,
            //       ),
            //     ),
            //     title: Column(
            //       mainAxisAlignment: MainAxisAlignment.start,
            //       children: [
            //         Text(
            //           driversList[index]["name"],
            //           style: const TextStyle(
            //             fontSize: 14,
            //             color: Colors.black54,
            //           ),
            //         ),
            //         Text(
            //           driversList[index]["carModel"],
            //           style: const TextStyle(
            //             fontSize: 12,
            //             color: Colors.white54,
            //           ),
            //         ),
            //         SmoothStarRating(
            //           rating: driversList[index]["ratings"] == null
            //               ? 0.0
            //               : double.parse(driversList[index]["ratings"]),
            //           color: Colors.black,
            //           borderColor: Colors.black,
            //           allowHalfRating: true,
            //           starCount: 5,
            //           size: 15,
            //         ),
            //       ],
            //     ),
            //     trailing: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         Text(
            //           "\$ " + getFareAmountAccordingToVehicleType(index),
            //           style: const TextStyle(
            //             fontWeight: FontWeight.bold,
            //           ),
            //         ),
            //         const SizedBox(
            //           height: 2,
            //         ),
            //         Text(
            //           tripDirectionDetailsInfo != null
            //               ? tripDirectionDetailsInfo!.duration_text!
            //               : "",
            //           style: const TextStyle(
            //               fontWeight: FontWeight.bold,
            //               color: Colors.black54,
            //               fontSize: 12),
            //         ),
            //         const SizedBox(
            //           height: 2,
            //         ),
            //         Text(
            //           tripDirectionDetailsInfo != null
            //               ? tripDirectionDetailsInfo!.distance_text!
            //               : "",
            //           style: const TextStyle(
            //               fontWeight: FontWeight.bold,
            //               color: Colors.black54,
            //               fontSize: 12),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          );
        },
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      backgroundColor: Colors.lightBlueAccent,
      elevation: 0,
      title: Text(
        'Available Car',
        style: TextStyle(color: Colors.white),
      ),
      // actions: [
      //   IconButton(
      //     icon: Icon(
      //       Icons.menu,
      //       color: Colors.white,
      //     ),
      //     onPressed: () {},
      //   )
      // ],
    );
  }
}
