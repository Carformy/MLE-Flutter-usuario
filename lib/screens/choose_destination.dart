import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocode/geocode.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import '../providers/google_map_functions.dart';
import '../providers/http_request_provider.dart';
import 'package:fire_uber_customer/main_variables/main_variables.dart';
import '../providers/location_provider.dart';
import '../models/directions.dart';

class ChooseDestination extends StatefulWidget {
  ChooseDestination({Key? key}) : super(key: key);

  @override
  State<ChooseDestination> createState() => _ChooseDestinationState();
}

class _ChooseDestinationState extends State<ChooseDestination> {
  late GoogleMapController googleMapController;

  GeoCode geoCode = GeoCode();
  static const LatLng _center = const LatLng(45.343434, -122.545454);

  LatLng _lastMapPosition = _center;

  late CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(37.42796133580664, -122.085749655962), zoom: 5);

  //late CameraPosition initialCameraPosition;
  Set<Marker> markers = {};

  String _title = "";
  String _detail = "";
  late TextEditingController _lane1;

  late LatLng currentPostion;
  Position? userCurrentPosition;

  double? currentUserLat;
  double? currentUserLong;

  String userName = "your Name";
  String userEmail = "your Email";

  late final Completer<GoogleMapController> _googleMapController = Completer();

  @override
  void initState() {
    super.initState();

    _determinePosition();
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;

    print("onCameraMove");
    print(_lastMapPosition);
    _handleTap(_lastMapPosition);
  }

  _handleTap(LatLng point) {
    markers.clear();
    //_getLocation(point);
    setState(() {
      _lastMapPosition = point;

      markers.add(Marker(
        markerId: MarkerId(point.toString()),
        position: point,
        infoWindow: InfoWindow(title: _title, snippet: _detail),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ));
    });
  }

  // _getLocation(LatLng point) async {

  //   Coordinates coordinates = await geoCode.forwardGeocoding(
  //       address: "532 S Olive St, Los Angeles, CA 90013");
  //   final coordinates = new Coordinates(point.latitude, point.longitude);
  //   var addresses =
  //       await Geocoder.local.findAddressesFromCoordinates(coordinates);
  //   var first = addresses.first;
  //   print("${first.featureName} : ${first.addressLine}");

  //   setState(() {
  //     _title = first.featureName;
  //     _detail = first.addressLine;
  //     _lane1.text = _title + "   " + _detail;
  //   });
  // }

  _moveBackScreen() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        elevation: 0,
        title: Text(
          "Choose Destination",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _moveBackScreen();
          },
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        // initialCameraPosition: CameraPosition(
        //   target: currentPostion,
        //   zoom: 10,
        // ),
        markers: markers,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        onCameraMove: _onCameraMove,
        //onTap: _handleTap,
        onMapCreated: (GoogleMapController controller) {
          googleMapController = controller;

          locateUserPosition();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.lightBlueAccent,
        onPressed: () async {
          print(_lastMapPosition.latitude);
          print(_lastMapPosition.longitude);

          String apiUrl =
              "https://maps.googleapis.com/maps/api/geocode/json?latlng=${_lastMapPosition.latitude},${_lastMapPosition.longitude}&key=$googleMapKey";
          String humanReadableAddress = "";

          var requestResponse =
              await HttpRequestProvider.receiveRequest(apiUrl);

          if (requestResponse != "Error Occurred, Failed. No Response.") {
            humanReadableAddress =
                requestResponse["results"][0]["formatted_address"];

            Directions dropOffAddress = Directions();
            dropOffAddress.locationLatitude = _lastMapPosition.latitude;
            dropOffAddress.locationLongitude = _lastMapPosition.longitude;
            dropOffAddress.locationName = humanReadableAddress;
            dropOffAddress.locationId = humanReadableAddress;

            Provider.of<AppInfo>(context, listen: false)
                .updateEndLocation(dropOffAddress);

            setState(() {
              userDropOffAddress = dropOffAddress.locationName!;
            });
          }

          Navigator.pop(context, "obtainedDropoff");

          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: (context) => AddNewAddress(
          //             latitude: _lastMapPosition.latitude,
          //             longitude: _lastMapPosition.longitude)));
        },
        label: const Text("Choose Destination"),
        icon: const Icon(Icons.edit_road),
      ),
    );
  }

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

    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress =
        await GoogleMapFunctions.searchAddressForGeographicCoOrdinates(
            userCurrentPosition!, context);
    print("this is your addresss = " + humanReadableAddress);

    setState(() {
      userStartAddress = humanReadableAddress;
    });

    userName = userModelCurrentInfo!.displayName!;
    print(userName);
    userEmail = userModelCurrentInfo!.email!;
    print(userEmail);

    // initializeGeoFireListener();

    // GoogleMapFunctions.readTripsKeysForOnlineUser(context);
  }

  Future<LatLng> getCenter() async {
    final GoogleMapController controller = await _googleMapController.future;
    LatLngBounds visibleRegion = await controller.getVisibleRegion();
    LatLng centerLatLng = LatLng(
      (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
      (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) /
          2,
    );

    return centerLatLng;
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return Future.error("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition();

    setState(() {
      currentPostion = LatLng(position.latitude, position.longitude);
    });

    final CameraPosition initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude), zoom: 14);

    return position;
  }
}
