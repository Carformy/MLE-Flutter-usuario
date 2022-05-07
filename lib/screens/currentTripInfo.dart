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

import 'ride_summary.dart';

class CurrentTripInfo extends StatefulWidget {
  String? dealId;
  String? timestamp;
  String? driverId;
  CurrentTripInfo({Key? key, this.dealId, this.timestamp, this.driverId})
      : super(key: key);

  @override
  State<CurrentTripInfo> createState() => _CurrentTripInfoState();
}

class _CurrentTripInfoState extends State<CurrentTripInfo> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 220;
  double waitingResponseFromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoOrdinatesList = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  String userName = "your Name";
  String userEmail = "your Email";

  bool openNavigationDrawer = true;

  bool activeNearbyDriverKeysLoaded = false;
  BitmapDescriptor? activeNearbyIcon;

  List<nearestDrivers> onlineNearByAvailableDriversList = [];

  DatabaseReference? referenceRideRequest;
  DatabaseReference? driverLocationRequest;
  String driverRideStatus = "Show Trip Info";
  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;

  String userRideRequestStatus = "";
  bool requestPositionInfo = true;

  double? currentUserLat;
  double? currentUserLong;

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
  String? timestamp;
  String? driverId;

  bool _isTripInfo = true;
  bool _isPaymentInfo = false;

  Position? onlineDriverCurrentPosition;

  var _value;

  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    setState(() {
      currentUserLat = userCurrentPosition!.latitude;
      currentUserLong = userCurrentPosition!.longitude;
    });

    LatLng latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress =
        await GoogleMapFunctions.searchAddressForGeographicCoOrdinates(
            userCurrentPosition!, context);
    print("this is your addresss = " + humanReadableAddress);

    userName = userModelCurrentInfo!.displayName!;
    print("userName");
    print(userName);
    userEmail = userModelCurrentInfo!.email!;
    print("userEmail");
    print(userEmail);
  }

  @override
  void initState() {
    super.initState();

    print("widget.current.trip.id");
    print(widget.dealId);

    referenceRideRequest =
        FirebaseDatabase.instance.ref().child("deals").child(widget.dealId!);

    //Response from a Driver
    tripRideRequestInfoStreamSubscription =
        referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null) {
        return;
      }

      if ((eventSnap.snapshot.value as Map)["status"] != null) {
        userRideRequestStatus =
            (eventSnap.snapshot.value as Map)["status"].toString();
      }

      //status = accepted
      if (userRideRequestStatus == "accepted") {
        print("accepted");
      }

      if (userRideRequestStatus == "arrived") {
        //Navigator.pop(context);
        setState(() {
          _isTripInfo = false;
          _isPaymentInfo = true;

          driverRideStatus = "Show Trip Info";
        });

        Fluttertoast.showToast(msg: "Driver arrived at your Start Address");
      }

      //status = ontrip
      if (userRideRequestStatus == "ontrip") {
        setState(() {
          driverRideStatus = "Show Trip Info";
        });

        Fluttertoast.showToast(msg: "Driver started your trip");
      }

      if (userRideRequestStatus == "ended") {
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (c) => RideSummary()));

        // print("assignedDriverId");
        // print((eventSnap.snapshot.value as Map)["timestamp"]);

        // String assignedDriverId =
        //     (eventSnap.snapshot.value as Map)["driverId"].toString();

        // print("assignedDriverId");
        // print(assignedDriverId);

        Fluttertoast.showToast(msg: "Driver finished your trip");

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    RideSummary(orderId: timestamp, driverId: driverId)));
      }

      if (eventSnap.snapshot.value == null) {
        // Navigator.push(
        //     context, MaterialPageRoute(builder: (c) => RideSummary()));

        // print("assignedDriverId");
        // print((eventSnap.snapshot.value as Map)["timestamp"]);

        // String assignedDriverId =
        //     (eventSnap.snapshot.value as Map)["driverId"].toString();

        // print("assignedDriverId");
        // print(assignedDriverId);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    RideSummary(orderId: timestamp, driverId: driverId)));
      }
    });

    FirebaseDatabase.instance
        .ref()
        .child("deals")
        .child(widget.dealId!)
        .once()
        .then((snap) async {
      if (snap.snapshot.value != null) {
        print("new info");
        print((snap.snapshot.value as Map)["origin"]["latitude"]);
        print((snap.snapshot.value as Map)["origin"]["latitude"]);
        print((snap.snapshot.value as Map)["destination"]["longitude"]);

        double timeTraveledFareAmountPerMinute =
            ((snap.snapshot.value as Map)["duration"] / 60)
                .truncate()
                .toDouble();
        double distanceTraveledFareAmountPerKilometer =
            ((snap.snapshot.value as Map)["distance"] / 1000)
                .truncate()
                .toDouble();
        await drawPolyLineFromOriginToDestination(
            (snap.snapshot.value! as Map)["origin"]["latitude"] ?? '',
            (snap.snapshot.value! as Map)["origin"]["longitude"] ?? '',
            (snap.snapshot.value! as Map)["destination"]["latitude"] ?? '',
            (snap.snapshot.value! as Map)["destination"]["longitude"] ?? '',
            (snap.snapshot.value! as Map)["originAddress"] ?? '',
            (snap.snapshot.value! as Map)["destinationAddress"] ?? '');

        setState(() async {
          driverPhoto = await (snap.snapshot.value as Map)["driverPhoto"];
          driverName = await (snap.snapshot.value as Map)["driverName"];
          driverPhone = await (snap.snapshot.value as Map)["driverPhone"];
          driverType = await (snap.snapshot.value as Map)["driverType"];
          driverRating = await (snap.snapshot.value as Map)["driverRating"];
          carBrand = await (snap.snapshot.value as Map)["carBrand"];
          carModel = await (snap.snapshot.value as Map)["carModel"];
          carNumber = await (snap.snapshot.value as Map)["carNumber"];
          pincode = await (snap.snapshot.value as Map)["pincode"];
          driverId = await (snap.snapshot.value as Map)["driverId"];
          timestamp =
              await (snap.snapshot.value as Map)["timestamp"].toString();
          duration = timeTraveledFareAmountPerMinute.toString() + " min";
          distance = distanceTraveledFareAmountPerKilometer.toString() + " km";
          totalPayment =
              await (snap.snapshot.value as Map)["totalPayment"] + "\$";
        });
      } else {
        Fluttertoast.showToast(msg: "This driver do not exist. Try again.");
      }
    });
  }

  getDriversLocationUpdatesAtRealTime() {
    // LatLng oldLatLng = LatLng(0, 0);

    driverLocationRequest = FirebaseDatabase.instance
        .ref()
        .child("locations")
        .child(widget.dealId!)
        .child("driverLocation");

    //Response from a Driver
    tripRideRequestInfoStreamSubscription =
        driverLocationRequest!.onValue.listen((eventSnap) async {
      LatLng latLngLiveDriverPosition = LatLng(
        double.parse((eventSnap.snapshot.value as Map)["latitude"]),
        double.parse((eventSnap.snapshot.value as Map)["longitude"]),
      );

      Marker animatingMarker = Marker(
        markerId: const MarkerId("AnimatedMarker"),
        position: latLngLiveDriverPosition,
        icon: activeNearbyIcon!,
        infoWindow: const InfoWindow(title: "That is your Driver Position"),
      );

      setState(() {
        CameraPosition cameraPosition =
            CameraPosition(target: latLngLiveDriverPosition, zoom: 16);
        newGoogleMapController!
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

        markersSet.removeWhere(
            (element) => element.markerId.value == "AnimatedMarker");
        markersSet.add(animatingMarker);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    createActiveNearByDriverIconMarker();

    return Scaffold(
      key: sKey,
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            initialCameraPosition: _kGooglePlex,
            polylines: polyLineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              locateUserPosition();

              getDriversLocationUpdatesAtRealTime();
            },
          ),
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, top: 40, bottom: 20),
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.lightBlueAccent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_city,
                                color: Colors.white,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Provider.of<AppInfo>(context)
                                                  .userPickUpLocation !=
                                              null
                                          ? (Provider.of<AppInfo>(context)
                                                      .userPickUpLocation!
                                                      .locationName!)
                                                  .substring(0, 24) +
                                              "..."
                                          : "not getting address",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.lightBlueAccent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_searching,
                                color: Colors.white,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      Provider.of<AppInfo>(context)
                                                  .userDropOffLocation !=
                                              null
                                          ? Provider.of<AppInfo>(context)
                                              .userDropOffLocation!
                                              .locationName!
                                          : "Where to go?",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade100,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 20.0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                image: DecorationImage(
                                    image: NetworkImage(
                                        driverPhoto ?? 'images/Elegant.png'),
                                    fit: BoxFit.cover)),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName ?? "Driver name",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'semi-bold',
                                        fontSize: 18),
                                  ),
                                  SmoothStarRating(
                                    rating: double.parse(driverRating ?? "0"),
                                    color: Colors.white,
                                    borderColor: Colors.black,
                                    allowHalfRating: true,
                                    starCount: 5,
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Distance',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(distance ?? "0 km",
                                        style: TextStyle(
                                          color: Colors.white,
                                        )),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Duration',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(duration ?? "0",
                                        style: TextStyle(
                                          color: Colors.white,
                                        )),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Total',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(totalPayment ?? "0",
                                        style: TextStyle(
                                          color: Colors.white,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      gradientButton(() {}, driverRideStatus)
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  gradientButton(route, text) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: Colors.lightBlue,
      ),
      child: InkWell(
        onTap: () {
          print("clicked");

          _settingModalBottomSheet(context);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'bold', fontSize: 16, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  createActiveNearByDriverIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(1, 1));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png")
          .then((value) {
        activeNearbyIcon = value;
      });
    }
  }

  Future<void> drawPolyLineFromOriginToDestination(
      originLat, originLong, destLat, destLong, originName, destName) async {
    print("draw polyline");
    print(originLat);
    print(originLong);
    print(destLat);
    print(destLong);
    print(originName);
    print(destName);

    var originLatLng =
        LatLng(double.parse(originLat), double.parse(originLong));
    var destinationLatLng =
        LatLng(double.parse(destLat), double.parse(destLong));

    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: "Please wait...",
      ),
    );

    var directionDetailsInfo =
        await GoogleMapFunctions.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);
    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    Navigator.pop(context);

    print("These are points = ");
    print(directionDetailsInfo!.e_points);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList =
        pPoints.decodePolyline(directionDetailsInfo.e_points!);

    pLineCoOrdinatesList.clear();

    if (decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        pLineCoOrdinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.red,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        width: 4,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      infoWindow: InfoWindow(title: originName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      infoWindow: InfoWindow(title: destName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markersSet.add(originMarker);
      markersSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
  }

  void _settingModalBottomSheet(context) {
    FirebaseDatabase.instance
        .ref()
        .child("deals")
        .child(widget.dealId!)
        .once()
        .then((snap) async {
      if (snap.snapshot.value != null) {
        //send notification to that specific driver

        print("new info");
        print((snap.snapshot.value as Map)["origin"]["latitude"]);
        print((snap.snapshot.value as Map)["origin"]["latitude"]);
        print((snap.snapshot.value as Map)["destination"]["longitude"]);

        double timeTraveledFareAmountPerMinute =
            ((snap.snapshot.value as Map)["duration"] / 60)
                .truncate()
                .toDouble();
        double distanceTraveledFareAmountPerKilometer =
            ((snap.snapshot.value as Map)["distance"] / 1000)
                .truncate()
                .toDouble();

        setState(() async {
          driverPhoto = await (snap.snapshot.value as Map)["driverPhoto"];
          driverName = await (snap.snapshot.value as Map)["driverName"];
          driverPhone = await (snap.snapshot.value as Map)["driverPhone"];
          driverType = await (snap.snapshot.value as Map)["driverType"];
          driverRating = await (snap.snapshot.value as Map)["driverRating"];
          carBrand = await (snap.snapshot.value as Map)["carBrand"];
          carModel = await (snap.snapshot.value as Map)["carModel"];
          carNumber = await (snap.snapshot.value as Map)["carNumber"];
          pincode = await (snap.snapshot.value as Map)["pincode"];
          duration = timeTraveledFareAmountPerMinute.toString() + " min";
          distance = distanceTraveledFareAmountPerKilometer.toString() + " km";
          driverId = await (snap.snapshot.value as Map)["driverId"];
          timestamp =
              await (snap.snapshot.value as Map)["timestamp"].toString();
          totalPayment =
              await (snap.snapshot.value as Map)["totalPayment"] + "\$";
        });
      } else {
        Fluttertoast.showToast(msg: "This driver do not exist. Try again.");
        FirebaseDatabase.instance
            .ref()
            .child("deals")
            .child(widget.dealId!)
            .once()
            .then((snap) async {
          if (snap.snapshot.value == null) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        RideSummary(orderId: timestamp, driverId: driverId)));
          }
        });
      }
    });

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext bc) {
          return Container(
            height: 340,
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade100,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(driverPhoto!),
                  ),
                  SizedBox(height: 5),
                  Chip(
                    shadowColor: Colors.lightBlueAccent,
                    backgroundColor: Colors.lightBlueAccent,
                    label: Text(driverName!,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontFamily: "bold")),
                  ),
                  SizedBox(height: 5),
                  SmoothStarRating(
                    rating: double.parse(driverRating ?? "0"),
                    color: Colors.white,
                    borderColor: Colors.lightBlueAccent,
                    allowHalfRating: true,
                    starCount: 5,
                    size: 25,
                  ),

                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            color: Colors.lightBlueAccent, size: 25),
                        const SizedBox(),
                        Expanded(
                          child: Chip(
                            shadowColor: Colors.lightBlueAccent,
                            backgroundColor: Colors.lightBlueAccent,
                            label: Text(
                              Provider.of<AppInfo>(context)
                                          .userPickUpLocation !=
                                      null
                                  ? (Provider.of<AppInfo>(context)
                                      .userPickUpLocation!
                                      .locationName!)
                                  : "not getting address",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Row(
                      children: [
                        Icon(Icons.pin_drop,
                            color: Colors.lightBlueAccent, size: 25),
                        const SizedBox(),
                        Chip(
                          shadowColor: Colors.lightBlueAccent,
                          backgroundColor: Colors.lightBlueAccent,
                          label: Text(
                            Provider.of<AppInfo>(context).userDropOffLocation !=
                                    null
                                ? Provider.of<AppInfo>(context)
                                    .userDropOffLocation!
                                    .locationName!
                                : "Where to go?",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(),
                        SizedBox(),
                        SizedBox(),
                        Chip(
                          shadowColor: Colors.lightBlueAccent,
                          backgroundColor: Colors.lightBlueAccent,
                          label: Text("Pincode :",
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                              )),
                        ),
                        Chip(
                          shadowColor: Colors.lightBlueAccent,
                          backgroundColor: Colors.lightBlueAccent,
                          label: Text(pincode!,
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.white,
                              )),
                        )
                      ]),
                  // _buildbtn(),
                ],
              ),
            ),
          );
        });
  }
}
