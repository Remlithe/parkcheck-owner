import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parking_area_model.dart';

class OwnerHomeScreen extends StatelessWidget {
  const OwnerHomeScreen({super.key});

  // Funkcja wylogowania (zostawiamy ją, bo się przydaje)

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? ''; 

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("OWN CHECK", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
       
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATYSTYKI GLOBALNE
            const Text("Twoje Statystyki", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildGlobalStats(uid),

            const SizedBox(height: 30),

            // 2. DANE WŁAŚCICIELA
            const Text("Twoje Dane", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildOwnerInfoCard(uid),

            const SizedBox(height: 30),

            // 3. LISTA PARKINGÓW (Tylko podgląd)
            const Text("Twoje Parkingi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildParkingList(context, uid),
            
            const SizedBox(height: 80), // Margines na navbar
          ],
        ),
      ),
    );
  }

 Widget _buildGlobalStats(String uid) {
    if (uid.isEmpty) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parking_sessions')
          // POPRAWKA: Zmieniono 'ownerUid' na 'ownerId', bo tak zapisujesz w parking_screen.dart
          .where('ownerId', isEqualTo: uid) 
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        
        // --- LOGIKA OBLICZEŃ ---
        int activeSessions = 0;
        double todayEarnings = 0.0;

        // Resetujemy datę do północy dzisiaj, żeby liczyć zarobek tylko z dzisiaj
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'];

          // 1. Licznik aktywnych
          if (status == 'active') {
            activeSessions++;
          }

          // 2. Licznik kasy (tylko zakończone i opłacone)
          if (status == 'completed' && data['paid'] == true) {
            // Sprawdź czy data zakończenia istnieje
            if (data['endTime'] != null) {
              Timestamp endTs = data['endTime'];
              DateTime endDate = endTs.toDate();

              // Jeśli sesja zakończyła się dzisiaj (po północy)
              if (endDate.isAfter(startOfDay)) {
                // Bezpieczne rzutowanie na double (obsługuje int i double)
                todayEarnings += (data['cost'] as num? ?? 0.0).toDouble();
              }
            }
          }
        }

        return Row(
          children: [
            Expanded(child: _statCard("Aktywni teraz", "$activeSessions", Colors.blue)),
            const SizedBox(width: 15),
            // Wyświetlamy z dwoma miejscami po przecinku
            Expanded(child: _statCard("Zarobek dziś", "${todayEarnings.toStringAsFixed(2)} zł", Colors.green)), 
          ],
        );
      },
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16), // Mniejszy padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildOwnerInfoCard(String uid) {
    if (uid.isEmpty) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('owners').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final data = snapshot.data!.data() as Map<String, dynamic>?;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoText("Partner", "${data?['firstName'] ?? '-'} ${data?['lastName'] ?? '-'}"),
              const Divider(height: 15), // Cieńszy divider
              _infoText("Email", "${data?['email'] ?? '-'}"),
            ],
          ),
        );
      },
    );
  }

  Widget _infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildParkingList(BuildContext context, String uid) {
    if (uid.isEmpty) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('parking_spots')
          .where('ownerUid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text("Brak parkingów");

        return SizedBox(
          height: 110, // ZMNIEJSZONE Z 160
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              final parking = ParkingAreaModel.fromFirestore(docs[i].data() as Map<String, dynamic>, docs[i].id);
              
              // Usunąłem GestureDetector - karta jest teraz tylko informacyjna
              return Container(
                width: 240, // Trochę węższe
                margin: const EdgeInsets.only(right: 12, bottom: 5),
                padding: const EdgeInsets.all(12), // Mniejszy padding wewnątrz (było 15)
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_parking, color: Colors.blue, size: 24), // Mniejsza ikona (było 30)
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parking.name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      parking.address, 
                      style: const TextStyle(color: Colors.grey, fontSize: 11), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${parking.pricePerHour} zł/h", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}