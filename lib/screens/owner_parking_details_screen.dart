// lib/screens/owner_parking_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parkingareamodel.dart';

class OwnerParkingDetailsScreen extends StatefulWidget {
  final ParkingAreaModel parking;

  const OwnerParkingDetailsScreen({super.key, required this.parking});

  @override
  State<OwnerParkingDetailsScreen> createState() => _OwnerParkingDetailsScreenState();
}

class _OwnerParkingDetailsScreenState extends State<OwnerParkingDetailsScreen> {
  bool _showOnlyUnpaid = false; // Przełącznik "Pokaż tylko nieopłacone"

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Zaparkowani", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // --- PRZEŁĄCZNIK ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Pokaż tylko nieopłacone", style: TextStyle(color: Colors.grey)),
                Switch(
                  value: _showOnlyUnpaid,
                  onChanged: (val) => setState(() => _showOnlyUnpaid = val),
                  activeColor: Colors.blue,
                )
              ],
            ),
          ),

          // --- LISTA SAMOCHODÓW ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Pobieramy podkolekcję 'active_sessions' z danego parkingu
              stream: FirebaseFirestore.instance
                  .collection('parking_spots')
                  .doc(widget.parking.id)
                  .collection('active_sessions')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var docs = snapshot.data!.docs;

                // Filtrowanie (przykładowe pole 'isPaid')
                if (_showOnlyUnpaid) {
                   // Zakładamy, że w bazie jest pole 'isPaid'. Jeśli nie ma, pomin to.
                   // docs = docs.where((d) => d['isPaid'] == false).toList();
                }

                if (docs.isEmpty) {
                  return const Center(child: Text("Parking pusty"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    // Symulacja statusu (czy opłacony) - normalnie weź to z bazy
                    bool isPaid = i % 2 == 0; 

                    return _buildCarCard(
                      data['licensePlate'] ?? 'BRAK',
                      data['driverName'] ?? 'Nieznany',
                      isPaid,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarCard(String plate, String name, bool isPaid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
      ),
      child: Row(
        children: [
          // Ikona P (Niebieska) lub X (Czerwona)
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: isPaid ? Colors.blue : Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPaid ? Icons.local_parking : Icons.close,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          // Dane
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end, // Do prawej jak na screenie
              children: [
                Text("NR REJ: $plate", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}