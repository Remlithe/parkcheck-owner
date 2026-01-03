// lib/screens/owner_manage_parking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/parking_area_model.dart'; // Upewnij się co do nazwy pliku
import 'location_picker_screen.dart'; // Mapa

class OwnerManageParkingScreen extends StatefulWidget {
  const OwnerManageParkingScreen({super.key});

  @override
  State<OwnerManageParkingScreen> createState() => _OwnerManageParkingScreenState();
}

class _OwnerManageParkingScreenState extends State<OwnerManageParkingScreen> {
  final _parkingNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  
  LatLng? _pickedLocation;
  String _pickedAddress = "Nie wybrano lokalizacji";
  bool _isLoading = false;

  // Funkcja otwierająca mapę
  void _openMapPicker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null && result is Map) {
      setState(() {
        _pickedLocation = result['location'];
        _pickedAddress = result['address'];
      });
    }
  }

  // --- LOGIKA ZAPISU (Inna niż w Step 2) ---
  Future<void> _saveParking() async {
    if (_parkingNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _capacityCtrl.text.isEmpty || _pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uzupełnij wszystkie dane.")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      
      // Tworzymy obiekt parkingu
      final newSpot = ParkingAreaModel(
        id: "", 
        ownerUid: user!.uid,
        name: _parkingNameCtrl.text.trim(),
        address: _pickedAddress,
        location: _pickedLocation!,
        pricePerHour: double.tryParse(_priceCtrl.text) ?? 0.0,
        totalCapacity: int.tryParse(_capacityCtrl.text) ?? 0,
        occupiedSpots: 0,
        features: ['Ochrona'],
      );

      // Zapisujemy bezpośrednio do bazy
      await FirebaseFirestore.instance.collection('parking_spots').add(newSpot.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Parking dodany pomyślnie!")));
        Navigator.pop(context); // <--- TU JEST RÓŻNICA: Wracamy do listy, a nie idziemy do Step 3
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Dodaj Parking", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: _parkingNameCtrl, decoration: const InputDecoration(labelText: "Nazwa Parkingu")),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _priceCtrl, decoration: const InputDecoration(labelText: "Cena (zł/h)"), keyboardType: TextInputType.number)),
                    const SizedBox(width: 15),
                    Expanded(child: TextField(controller: _capacityCtrl, decoration: const InputDecoration(labelText: "Ilość miejsc"), keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 30),
                
                const Text("Lokalizacja", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100], 
                    borderRadius: BorderRadius.circular(8), 
                    border: _pickedLocation == null ? Border.all(color: Colors.red) : null
                  ),
                  child: Row(
                    children: [
                      Icon(_pickedLocation != null ? Icons.check : Icons.location_on, color: _pickedLocation != null ? Colors.green : Colors.blue),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_pickedAddress)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openMapPicker, 
                    icon: const Icon(Icons.map),
                    label: const Text("WSKAŻ NA MAPIE")
                  ),
                ),
                
                const SizedBox(height: 40),
                
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveParking, // <--- Wywołuje zapis i zamknięcie
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text("ZAPISZ PARKING"),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}