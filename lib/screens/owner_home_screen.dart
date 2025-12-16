// lib/screens/owner_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_area_model.dart';
import 'owner_parking_details_screen.dart'; // Zaraz stworzymy
import 'owner_profile_menu.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("OWN CHECK", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- KARTA GŁÓWNA ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parking_spots')
                  .where('ownerUid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) return const Text("Brak parkingów. Dodaj pierwszy!");
                
                // Bierzemy pierwszy parking jako "główny"
                final mainParking = ParkingAreaModel.fromFirestore(
                  docs.first.data() as Map<String, dynamic>, 
                  docs.first.id
                );

                return _buildMainParkingCard(context, mainParking);
              },
            ),
           
            const SizedBox(height: 30),
            const Text("Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

             StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('owners').doc(uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
                
                // Bezpieczne pobranie danych
                final data = snapshot.data!.data() as Map<String, dynamic>?; 
                final firstName = data?['firstName'] ?? 'Partnerze';
                final lastName = data?['lastName'] ?? '';
                final email = data?['email'] ?? '';

                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerProfileMenu())),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[800], // Ciemniejszy niebieski dla kontrastu
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,5))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white,
                          child: Text(firstName[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("$firstName $lastName", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Text(email, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                            ],
                          ),
                        ),
                        const Icon(Icons.edit, color: Colors.white70),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            const Text("Inne parkingi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // --- LISTA INNYCH PARKINGÓW ---
            // (Tu można dodać ListView poziome, jeśli masz więcej parkingów)
             StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parking_spots')
                  .where('ownerUid', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final docs = snapshot.data!.docs;
                
                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                       final parking = ParkingAreaModel.fromFirestore(docs[i].data() as Map<String, dynamic>, docs[i].id);
                       return _buildSmallParkingCard(context, parking);
                    }
                  ),
                );
              },
             ),
          ],
        ),
      ),
    );
    
  }

  Widget _buildMainParkingCard(BuildContext context, ParkingAreaModel parking) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerParkingDetailsScreen(parking: parking))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2)),
                  child: const Icon(Icons.local_parking, color: Colors.blue, size: 40),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("TWÓJ PARKING", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(parking.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(parking.address, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
            const Divider(height: 30),
            _buildStatRow("dzisiejsza liczba transakcji", "24"),
            _buildStatRow("Średni czas parkowania", "3h 21m 2s"),
            _buildStatRow("popularne godziny", "15 → 17"),
            _buildStatRow("popularne dni", "Środa"),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallParkingCard(BuildContext context, ParkingAreaModel parking) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OwnerParkingDetailsScreen(parking: parking))),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Icon(Icons.local_parking, size: 40, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(parking.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  Text(parking.address, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
        ],
      ),
    );
  }
}