// lib/screens/owner_my_parkings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parkingareamodel.dart';
import 'owner_manage_parking_screen.dart'; // <--- Ten plik odpowiada za wygląd "jak w rejestracji"

class OwnerMyParkingsScreen extends StatefulWidget {
  const OwnerMyParkingsScreen({super.key});

  @override
  State<OwnerMyParkingsScreen> createState() => _OwnerMyParkingsScreenState();
}

class _OwnerMyParkingsScreenState extends State<OwnerMyParkingsScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // --- FUNKCJA USUWANIA Z POTWIERDZENIEM ---
  void _deleteParking(String parkingId, String parkingName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuń parking"),
        content: Text("Czy na pewno chcesz usunąć parking \"$parkingName\"?\n\nTej operacji nie można cofnąć."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), // Zamknij
            child: const Text("ANULUJ", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Zamknij dialog
              
              // Usuwamy z Firebase
              await FirebaseFirestore.instance.collection('parking_spots').doc(parkingId).delete();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Parking został usunięty."))
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("USUŃ"),
          ),
        ],
      ),
    );
  }

  // Funkcja otwierająca formularz "jak w rejestracji"
  void _addNewParking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OwnerManageParkingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Zarządzaj Parkingami", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_spots')
            .where('ownerUid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_parking, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("Brak parkingów", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
               final parking = ParkingAreaModel.fromFirestore(docs[i].data() as Map<String, dynamic>, docs[i].id);
               return _buildParkingCard(parking);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewParking,
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text("DODAJ PARKING"),
      ),
    );
  }

  Widget _buildParkingCard(ParkingAreaModel parking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        // Ikona po lewej
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8)
          ),
          child: const Icon(Icons.local_parking, color: Colors.blue, size: 28),
        ),
        // Treść
        title: Text(parking.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(parking.address, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text("${parking.pricePerHour} zł/h • ${parking.totalCapacity} miejsc", 
              style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold, fontSize: 12)
            ),
          ],
        ),
        // Przycisk usuwania (Kosz)
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteParking(parking.id, parking.name),
        ),
      ),
    );
  }
}