// lib/screens/owner_step2_parking.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'owner_step3_bank_setup.dart';
import 'location_picker_screen.dart';

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
  String _pickedAddress = "Kliknij, aby wybrać z mapy";

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
        location: _pickedLocation!,
        address: _pickedAddress,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Pobieramy wysokość klawiatury
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      // 1. ZMIANA: Blokujemy przesuwanie layoutu przez klawiaturę
      resizeToAvoidBottomInset: false,
      
      appBar: AppBar(
        title: const Text("Dodaj Parking", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- PASEK POSTĘPU ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.66, // Krok 2
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF007AFF),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 10),
                  const Text("Krok 2 z 3", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                // 2. ZMIANA: Dodajemy padding dynamiczny na dole listy inputów
                padding: EdgeInsets.only(
                  left: 24.0, 
                  right: 24.0, 
                  top: 24.0, 
                  bottom: bottomPadding + 24.0 // Klawiatura + margines
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Twój pierwszy parking", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    const Text("Zdefiniuj parametry swojego parkingu. Będziesz mógł je później edytować.", style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 30),

                    _buildInput(_parkingNameCtrl, "Nazwa parkingu", Icons.business),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(child: _buildInput(_priceCtrl, "Cena (zł/h)", Icons.attach_money, type: TextInputType.number)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildInput(_capacityCtrl, "Liczba miejsc", Icons.local_parking, type: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // SEKCJA MAPY
                    const Text("LOKALIZACJA WJAZDU", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    
                    InkWell(
                      onTap: _openMapPicker,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50], 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _pickedLocation != null ? Icons.check_circle : Icons.map, 
                              color: _pickedLocation != null ? Colors.green : const Color(0xFF007AFF)
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _pickedAddress, 
                                style: TextStyle(
                                  color: _pickedLocation != null ? Colors.black : Colors.grey,
                                  fontWeight: _pickedLocation != null ? FontWeight.bold : FontWeight.normal
                                )
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    if (_pickedLocation == null)
                       const Padding(
                         padding: EdgeInsets.only(top: 8.0),
                         child: Text("Wymagane wybranie lokalizacji na mapie", style: TextStyle(color: Colors.red, fontSize: 12)),
                       ),
                  ],
                ),
              ),
            ),

            // Przycisk jest POZA SingleChildScrollView -> Sztywno na dole
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _goToNextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("DALEJ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Input
  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
        ),
      ),
    );
  }
}