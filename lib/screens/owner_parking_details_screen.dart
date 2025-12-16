import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/parking_area_model.dart';
import 'package:intl/intl.dart';

class OwnerParkingDetailsScreen extends StatelessWidget {
  final ParkingAreaModel parking;

  const OwnerParkingDetailsScreen({super.key, required this.parking});

  // Funkcje zarządzania sesją
  void _manageSession(BuildContext context, String sessionId, String action) async {
    try {
      if (action == 'stop') {
        // Zatrzymaj czas (np. rozliczenie gotówkowe)
        await FirebaseFirestore.instance.collection('parking_sessions').doc(sessionId).update({
          'status': 'cash_settled',
          'endTime': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zatrzymano czas (Gotówka).")));
      } else if (action == 'remove') {
        // Usuń całkowicie z bazy
        await FirebaseFirestore.instance.collection('parking_sessions').doc(sessionId).delete();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usunięto sesję.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(parking.name),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "Informacje"),
              Tab(text: "Kierowcy (Live)"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Informacje ogólne
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.location_on, parking.address),
                  const SizedBox(height: 15),
                  _infoRow(Icons.attach_money, "${parking.pricePerHour} zł / godzina"),
                  const SizedBox(height: 15),
                  _infoRow(Icons.local_parking, "${parking.totalCapacity} miejsc łącznie"),
                ],
              ),
            ),

            // TAB 2: Aktywne sesje (Live)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parking_sessions')
                  .where('parkingId', isEqualTo: parking.id)
                  .where('status', isEqualTo: 'active') // Tylko trwające
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("Brak aktywnych kierowców.", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final startTime = (data['startTime'] as Timestamp).toDate();
                    final duration = DateTime.now().difference(startTime);
                    
                    // Formatowanie
                    final h = duration.inHours;
                    final m = duration.inMinutes % 60;
                    final plate = data['licensePlate'] ?? "???";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.directions_car, color: Colors.blue),
                        ),
                        title: Text(plate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text("Czas: ${h}h ${m}m\nStart: ${DateFormat('HH:mm').format(startTime)}"),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => _manageSession(context, docs[i].id, value),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'stop',
                              child: Row(children: [
                                Icon(Icons.stop_circle_outlined, color: Colors.orange), 
                                SizedBox(width: 10), 
                                Text("Zatrzymaj Czas")
                              ]),
                            ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(children: [
                                Icon(Icons.delete_outline, color: Colors.red), 
                                SizedBox(width: 10), 
                                Text("Usuń z listy")
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 24),
        const SizedBox(width: 15),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
      ],
    );
  }
}