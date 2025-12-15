// lib/models/parking_session_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSessionModel {
  final String id;           // ID sesji
  final String userId;       // ID kierowcy (z auth)
  final String driverName;   // Imię i nazwisko kierowcy
  final String licensePlate; // Rejestracja
  final DateTime startTime;  // Kiedy wjechał
  final DateTime? endTime;   // Kiedy wyjedzie (opcjonalne)
  final double cost;         // Aktualny koszt

  ParkingSessionModel({
    required this.id,
    required this.userId,
    required this.driverName,
    required this.licensePlate,
    required this.startTime,
    this.endTime,
    this.cost = 0.0,
  });

  factory ParkingSessionModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ParkingSessionModel(
      id: id,
      userId: data['userId'] ?? '',
      driverName: data['driverName'] ?? 'Nieznany',
      licensePlate: data['licensePlate'] ?? 'BRAK',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      cost: (data['cost'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'driverName': driverName,
      'licensePlate': licensePlate,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'cost': cost,
    };
  }
}