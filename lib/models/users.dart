import 'package:firebase_database/firebase_database.dart';

class Users {
  final String? id;
  final String? address;
  final String? displayName;
  final String? email;
  final String? lastName;
  final String? phone;
  final String? photoURL;

  Users({
    this.id,
    this.address,
    this.displayName,
    this.email,
    this.lastName,
    this.phone,
    this.photoURL,
  });

  factory Users.fromSnapshot(DataSnapshot dataSnapshot) {
    return Users(
      id: dataSnapshot.key,
      address: (dataSnapshot.value as dynamic)["address"],
      displayName: (dataSnapshot.value as dynamic)["displayName"],
      email: (dataSnapshot.value as dynamic)["email"],
      lastName: (dataSnapshot.value as dynamic)["lastName"],
      phone: (dataSnapshot.value as dynamic)["phone"],
      photoURL: (dataSnapshot.value as dynamic)["photoURL"],
    );
  }
}
