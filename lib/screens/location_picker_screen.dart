import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart'; // Paczka do zamiany adresu na współrzędne

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  final TextEditingController _searchCtrl = TextEditingController();
  
  LatLng _currentPos = const LatLng(52.2297, 21.0122); // Start: Warszawa
  String _currentAddress = "Warszawa";

  // 1. Szukanie po wpisanym adresie
  Future<void> _searchAddress() async {
    try {
      List<Location> locations = await locationFromAddress(_searchCtrl.text);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final newLatLng = LatLng(loc.latitude, loc.longitude);
        
        // Przesuwamy mapę i pina
        setState(() => _currentPos = newLatLng);
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
        _getAddressFromLatLng(newLatLng); // Pobieramy dokładny adres tego punktu
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nie znaleziono adresu")));
    }
  }

  // 2. Odwrócone geokodowanie (Współrzędne -> Adres)
  // Wywoływane gdy właściciel przesunie pina
  Future<void> _getAddressFromLatLng(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _currentAddress = "${place.street}, ${place.postalCode} ${place.locality}";
          _searchCtrl.text = _currentAddress; // Aktualizujemy pole tekstowe
        });
      }
    } catch (e) {
      print("Błąd adresu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ustaw wjazd na parking")),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentPos, zoom: 12),
            onMapCreated: (ctrl) => _mapController = ctrl,
            markers: {
              Marker(
                markerId: const MarkerId("picker"),
                position: _currentPos,
                draggable: true, // <--- TO POZWALA PRZESUWAĆ PINA (PRZETRZYMAJ)
                onDragEnd: (newPos) {
                  setState(() => _currentPos = newPos);
                  _getAddressFromLatLng(newPos); // Aktualizuj adres po upuszczeniu
                },
              ),
            },
            // Kliknięcie w mapę też przenosi pina
            onTap: (pos) {
              setState(() => _currentPos = pos);
              _getAddressFromLatLng(pos);
            },
          ),
          
          // Pasek wyszukiwania na dole
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(hintText: "Wpisz adres (np. Złota 44)"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _searchAddress, 
                          child: const Text("SZUKAJ")
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Zwracamy wybrane dane do formularza
                            Navigator.pop(context, {
                              'location': _currentPos,
                              'address': _currentAddress
                            });
                          }, 
                          child: const Text("WYBIERZ")
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}