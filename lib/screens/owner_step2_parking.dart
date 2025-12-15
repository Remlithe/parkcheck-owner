// lib/screens/owner_step2_parking.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/registration_layout.dart';
import 'owner_step3_bank_setup.dart'; // Przejście do KROKU 3 (Płatności)
import 'location_picker_screen.dart'; // Narzędzie Mapy

class OwnerStep2Parking extends StatefulWidget {
  final String firstName, lastName, email, phone, password;

  const OwnerStep2Parking({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<OwnerStep2Parking> createState() => _OwnerStep2ParkingState();
}

class _OwnerStep2ParkingState extends State<OwnerStep2Parking> {
  final _parkingNameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  
  LatLng? _pickedLocation;
  String _pickedAddress = "Nie wybrano lokalizacji";

  // Otwiera mapę jako narzędzie i czeka na powrót
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

  void _goToNextStep() {
    if (_parkingNameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _capacityCtrl.text.isEmpty || _pickedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uzupełnij wszystkie dane i wskaż lokalizację.")));
      return;
    }

    // Przechodzimy do Kroku 3 (Płatności), przekazując wszystkie zebrane dane
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => OwnerStep3BankSetup(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        phone: widget.phone,
        password: widget.password,
        parkingName: _parkingNameCtrl.text.trim(),
        pricePerHour: double.tryParse(_priceCtrl.text) ?? 0.0,
        capacity: int.tryParse(_capacityCtrl.text) ?? 0,
        location: _pickedLocation!, // <--- Dane z mapy
        address: _pickedAddress,      // <--- Dane z mapy
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationLayout(
      currentStep: 2,
      title: "Dane Parkingu (2/3)",
      child: Column(
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
          
          // LOKALIZACJA (TERAZ W KROKU 2)
          const Text("Wskaż lokalizację wjazdu", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              label: const Text("OTWÓRZ MAPĘ I WSKAŻ")
            ),
          ),
          
          const Spacer(),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _goToNextStep,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: const Text("DALEJ (KROK 3)"),
            ),
          ),
        ],
      ),
    );
  }
}