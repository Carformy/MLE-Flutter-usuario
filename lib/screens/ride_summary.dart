import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fire_uber_customer/providers/google_map_functions.dart';
import 'package:fire_uber_customer/providers/geofire_provider.dart';
import 'package:fire_uber_customer/main_variables/main_variables.dart';
import 'package:fire_uber_customer/providers/location_provider.dart';
import 'package:fire_uber_customer/main.dart';
import 'package:fire_uber_customer/models/nearest_drivers.dart';
import 'package:fire_uber_customer/models/direction_details_info.dart';
import 'package:fire_uber_customer/progress/progress_dialog.dart';

import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:fire_uber_customer/providers/google_map_functions.dart';

class RideSummary extends StatefulWidget {
  String? orderId;
  String? driverId;
  RideSummary({Key? key, this.orderId, this.driverId}) : super(key: key);

  @override
  State<RideSummary> createState() => _RideSummaryState();
}

class _RideSummaryState extends State<RideSummary> {
  var _value;

  double? originLat;
  double? originLong;

  double? destLat;
  double? destLong;

  String? destName;
  String? originName;

  String? driverPhoto;
  String? driverName;
  String? driverPhone;
  String? driverType;
  String? driverRating;
  String? carBrand;
  String? carModel;
  String? carNumber;
  String? pincode;
  String? duration;
  String? distance;
  String? totalPayment;

  String? startAddress;
  String? destinationAddress;
  String? endAddress;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    FirebaseDatabase.instance
        .ref()
        .child("orders")
        .child(widget.orderId!)
        .once()
        .then((snap) async {
      if (snap.snapshot.value != null) {
        double timeTraveledFareAmountPerMinute =
            await ((snap.snapshot.value as Map)["duration"] / 60)
                .truncate()
                .toDouble();
        double distanceTraveledFareAmountPerKilometer =
            await ((snap.snapshot.value as Map)["distance"] / 1000)
                .truncate()
                .toDouble();

        setState(() {
          driverPhoto = (snap.snapshot.value as Map)["driverPhoto"];
          driverName = (snap.snapshot.value as Map)["driverName"];
          driverPhone = (snap.snapshot.value as Map)["driverPhone"];
          driverType = (snap.snapshot.value as Map)["driverType"];
          driverRating = (snap.snapshot.value as Map)["driverRating"];
          carBrand = (snap.snapshot.value as Map)["carBrand"];
          carModel = (snap.snapshot.value as Map)["carModel"];
          carNumber = (snap.snapshot.value as Map)["carNumber"];
          pincode = (snap.snapshot.value as Map)["pincode"];
          startAddress = (snap.snapshot.value as Map)["originAddress"];
          endAddress = (snap.snapshot.value as Map)["destinationAddress"];
          duration = timeTraveledFareAmountPerMinute.toString() + " min";
          distance = distanceTraveledFareAmountPerKilometer.toString() + " km";
          totalPayment = (snap.snapshot.value as Map)["totalPayment"] + "\$";
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 243, 243, 243),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.black87),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.lightBlueAccent,
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ' + widget.orderId!,
              style: TextStyle(
                  color: Colors.white, fontFamily: "semibold", fontSize: 16),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildbtn(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
        child: Column(
      children: [
        _buildDriver(),
        _buildDivider(),
        _buildLocation(),
        _buildDivider(),
        _buildRideDetail(),
        _buildDivider(),
        _buildBill(),
        _buildDivider(),
      ],
    ));
  }

  Widget _buildBill() {
    return Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Price",
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'bold',
                        color: Colors.lightBlue)),
                Text(totalPayment ?? "0\$",
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'bold',
                        color: Colors.lightBlue)),
              ],
            ),
          ],
        ));
  }

  Widget _buildLocation() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAddress(),
          SizedBox(height: 30),
          _buildDestination(),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildAddress() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.circle,
          size: 18,
          color: Colors.lightBlue,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            // width: ,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  startAddress ?? "not getting address",
                  style: const TextStyle(color: Colors.lightBlue, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDestination() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.circle,
          size: 18,
          color: Colors.lightBlue,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Container(
            // width: ,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  endAddress ?? "end address",
                  style: const TextStyle(color: Colors.lightBlue, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRideDetail() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text("Distance",
                  style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 14,
                      fontFamily: "medium")),
              Text(distance ?? "0 km",
                  style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 16,
                      fontFamily: "semibold")),
            ],
          ),
          Column(
            children: [
              Text("Duration",
                  style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 14,
                      fontFamily: "medium")),
              Text(duration ?? "0 min",
                  style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 16,
                      fontFamily: "semibold")),
            ],
          ),
          Column(
            children: [
              Text("Total",
                  style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 14,
                      fontFamily: "medium")),
              Text(totalPayment ?? "0\$",
                  style: TextStyle(
                      color: Colors.lightBlue,
                      fontSize: 16,
                      fontFamily: "semibold")),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriver() {
    return Container(
        color: Colors.white,
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(driverPhoto ?? "images/logo.png"),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(driverName ?? "driver Name",
                      style: TextStyle(
                          fontSize: 25,
                          fontFamily: "bold",
                          color: Colors.lightBlue)),
                  Column(
                    children: [
                      SmoothStarRating(
                        rating: countRatingStars,
                        allowHalfRating: false,
                        starCount: 5,
                        color: Colors.lightBlue,
                        borderColor: Colors.lightBlue,
                        size: 24,
                        onRatingChanged: (valueOfStarsChoosed) {
                          countRatingStars = valueOfStarsChoosed;

                          if (countRatingStars == 1) {
                            setState(() {
                              titleStarsRating = "Very Bad";
                            });
                          }
                          if (countRatingStars == 2) {
                            setState(() {
                              titleStarsRating = "Bad";
                            });
                          }
                          if (countRatingStars == 3) {
                            setState(() {
                              titleStarsRating = "Good";
                            });
                          }
                          if (countRatingStars == 4) {
                            setState(() {
                              titleStarsRating = "Very Good";
                            });
                          }
                          if (countRatingStars == 5) {
                            setState(() {
                              titleStarsRating = "Excellent";
                            });
                          }
                        },
                      ),
                      const SizedBox(
                        height: 12.0,
                      ),
                      Text(
                        titleStarsRating,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ));
  }

  Widget _buildbtn() {
    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      child: ElevatedButton(
        child: btnText("Rate Driver"),
        onPressed: () {
          DatabaseReference rateDriverRef = FirebaseDatabase.instance
              .ref()
              .child("drivers")
              .child(widget.driverId!)
              .child("ratings");

          rateDriverRef.once().then((snap) {
            if (snap.snapshot.value == null) {
              rateDriverRef.set(countRatingStars.toString());

              SystemNavigator.pop();
            } else {
              double pastRatings = double.parse(snap.snapshot.value.toString());
              double newAverageRatings = (pastRatings + countRatingStars) / 2;
              rateDriverRef.set(newAverageRatings.toString());

              SystemNavigator.pop();
            }

            Fluttertoast.showToast(msg: "Please Restart App Now");
          });
        },
        style: btnStyle(),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      thickness: 16,
      color: Color.fromARGB(255, 243, 243, 243),
    );
  }

  btnText(txt) {
    return Text(txt, style: TextStyle(fontSize: 16, fontFamily: 'semibold'));
  }

  btnStyle() {
    return ElevatedButton.styleFrom(
      primary: Colors.lightBlue,
      onPrimary: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
    );
  }
}
