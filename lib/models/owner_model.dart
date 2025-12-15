// lib/models/owner_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  // NOWE POLE:
  final String? stripeAccountId; // ID konta Stripe do otrzymywania wypłat

  OwnerModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.stripeAccountId, // <---
  });

  factory OwnerModel.fromFirestore(Map<String, dynamic> data) {
    return OwnerModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      stripeAccountId: data['stripeAccountId'], // <---
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'stripeAccountId': stripeAccountId, // <---
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}