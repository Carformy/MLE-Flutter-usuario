import 'package:fire_uber_customer/main_variables/main_variables.dart';
import 'package:fire_uber_customer/screens/order_details.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/geofire_provider.dart';
import '../providers/location_provider.dart';
import '../models/new_trip_history.dart';

class Orders extends StatefulWidget {
  Orders({Key? key}) : super(key: key);

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  DatabaseReference postListRef = FirebaseDatabase.instance.ref("orders");

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    print("GeoFireProviderInfo");
    print(GeoFireProvider.geoFireDriver);
    GeoFireProvider.geoFireDriver = [];
    print("GeoFireProviderAfter");
    print(GeoFireProvider.geoFireDriver);
  }

  shadowBox() {
    return BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: Colors.lightBlue.shade100,
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 0.25))
        ]);
  }

  nameLabel() {
    return TextStyle(fontFamily: 'medium', fontSize: 15);
  }

  boldLabel() {
    return TextStyle(fontFamily: 'medium');
  }

  greyLabel() {
    return TextStyle(color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.lightBlueAccent,
        automaticallyImplyLeading: false,
        title: Text(
          'My Trips',
          style: TextStyle(
              fontSize: 18, fontFamily: 'medium', color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: postListRef
            .orderByChild("userId")
            .equalTo(fAuth.currentUser!.uid)
            .onValue,
        builder: (context, snapshot) {
          List<NewTripHistory> messageList = [];
          if (snapshot.hasData &&
              snapshot.data != null &&
              (snapshot.data! as DatabaseEvent).snapshot.value != null) {
            final myMessages = Map<dynamic, dynamic>.from(
                (snapshot.data! as DatabaseEvent).snapshot.value
                    as Map<dynamic, dynamic>); //typecasting
            myMessages.forEach((key, value) {
              final currentMessage = Map<String, dynamic>.from(value);
              messageList.add(NewTripHistory(
                originAddress: currentMessage['originAddress'],
                destinationAddress: currentMessage['destinationAddress'],
                status: currentMessage['status'],
                driverName: currentMessage['driverName'],
                time: currentMessage['time'],
                timestamp: currentMessage['timestamp'].toString(),
                fareAmount: currentMessage['totalPayment'],
              ));
            }); //created a class called message and added all messages in a List of class message
            return ListView.builder(
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderDetails(
                                orderId: messageList[index].timestamp)));
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: shadowBox(),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Chip(
                                      backgroundColor: Colors.lightBlue,
                                      label: Text(
                                          "Order ID: " +
                                              messageList[index].timestamp!,
                                          style: nameLabel()),
                                    ),
                                    Chip(
                                      backgroundColor: Colors.white,
                                      label: RichText(
                                        text: TextSpan(
                                          text: '\$ ',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.lightBlue,
                                              fontFamily: 'regular'),
                                          children: <TextSpan>[
                                            TextSpan(
                                                text: messageList[index]
                                                    .fareAmount!,
                                                style: TextStyle(
                                                    fontFamily: 'medium',
                                                    color: Colors.lightBlue)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 3),
                                      child: Icon(
                                        Icons.fiber_manual_record,
                                        size: 16,
                                        color: Colors.lightBlue,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(messageList[index].originAddress!,
                                            style: boldLabel()),
                                      ],
                                    ))
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(top: 3),
                                      child: Icon(Icons.fiber_manual_record,
                                          size: 16, color: Colors.lightBlue),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                        child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            messageList[index]
                                                .destinationAddress!,
                                            style: boldLabel()),
                                      ],
                                    ))
                                  ],
                                ),
                                SizedBox(height: 10),
                                Chip(
                                  backgroundColor: Colors.white,
                                  label: Text(messageList[index].time!,
                                      style:
                                          TextStyle(color: Colors.lightBlue)),
                                ),
                              ],
                            ),
                          ))
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text(
                'Say Hi...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w400),
              ),
            );
          }
        },
      ),
    );
  }
}
