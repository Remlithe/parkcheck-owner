// lib/screens/location_picker_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _initialPosition = LatLng(52.2297, 21.0122);
  
  // Kontroler jest nullable, żeby uniknąć błędów LateInitializationError
  GoogleMapController? _mapController;
  
  LatLng _pickedLocation = _initialPosition;
  final TextEditingController _addressController = TextEditingController();
  
  bool _isLoadingAddress = false;
  bool _isDragging = false;
  bool _isSearchMode = true; 
  bool _hasInteracted = false; 

  @override
  void dispose() {
    _addressController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // --- LOGIKA ADRESOWANIA ---
  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!_hasInteracted) return;

    if (mounted) {
      setState(() {
        _isLoadingAddress = true;
        _isSearchMode = false;
      });
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = "${place.street ?? ''} ${place.name ?? ''}, ${place.locality ?? ''}".trim();
        
        if (address.startsWith(',')) address = address.substring(1).trim();
        if (address.isEmpty) address = "Nieznany adres";

        if (mounted) {
          setState(() {
            _addressController.text = address;
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressController.text = "Błąd pobierania adresu";
          _isLoadingAddress = false;
        });
      }
    }
  }

  // --- LOGIKA SZUKANIA ---
  Future<void> _searchPlace() async {
    String query = _addressController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus(); 
    
    setState(() {
      _isLoadingAddress = true;
      _hasInteracted = true; 
    });

    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        LatLng newPos = LatLng(loc.latitude, loc.longitude);

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newPos, 18.0));
        
        setState(() {
          _pickedLocation = newPos;
          _isSearchMode = false;
          _isLoadingAddress = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nie znaleziono adresu")));
          setState(() => _isLoadingAddress = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Błąd wyszukiwania")));
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // --- LOGIKA GPS ---
  Future<void> _goToMyLocation() async {
    try {
      // 1. Sprawdzamy czy usługi są włączone
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Włącz GPS w telefonie")));
        return;
      }

      // 2. Sprawdzamy uprawnienia (To tutaj wcześniej wywalało błąd bez AndroidManifest)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Brak uprawnień GPS")));
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uprawnienia GPS trwale zablokowane")));
        return;
      }

      // 3. Pobieramy pozycję
      Position position = await Geolocator.getCurrentPosition();
      LatLng myPos = LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() => _hasInteracted = true);

      // 4. Bezpieczne przesunięcie kamery
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(myPos, 18.0));
      }
    } catch (e) {
      print("Błąd GPS: $e");
    }
  }

  void _confirmSelection() {
    Navigator.of(context).pop({
      'location': _pickedLocation,
      'address': _addressController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    const double pinHeight = 50.0;
    
    // 1. Wysokość klawiatury
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // 2. Wysokość systemowego paska nawigacji (tego na dole ekranu)
    final double safeAreaBottom = MediaQuery.of(context).padding.bottom;

    // Suma odstępów: Klawiatura + Pasek Systemowy + Nasz Margines (20)
    final double bottomPosition = keyboardHeight + safeAreaBottom + 20;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Mapa się nie skaluje
      body: Stack(
        children: [
          // 1. MAPA
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true, 
            myLocationButtonEnabled: false, 
            padding: EdgeInsets.zero, // Mapa na pełen ekran
            
            onCameraMoveStarted: () {
              setState(() {
                _isDragging = true;
                _hasInteracted = true; 
              });
            },
            onCameraMove: (position) {
              _pickedLocation = position.target;
            },
            onCameraIdle: () {
              setState(() => _isDragging = false);
              if (_hasInteracted) {
                _getAddressFromLatLng(_pickedLocation);
              }
            },
            zoomControlsEnabled: false,
          ),

          // 2. PRZYCISK WSTECZ
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // 3. CELOWNIK
          if (_hasInteracted)
            Center(
              child: Container(
                width: 8, 
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5), 
                  shape: BoxShape.circle,
                ),
              ),
            ),

          // 4. PIN
          if (_hasInteracted)
            Center(
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: _isDragging ? (pinHeight + 25) : pinHeight),
                child: Image.asset(
                  _isDragging 
                    ? 'assets/images/pin_black.png' 
                    : 'assets/images/pin_blue.png',
                  height: pinHeight, 
                ),
              ),
            ),

          // 5. PRZYCISK LOKALIZACJI
          // Przesuwa się w górę razem z dolnym panelem
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            right: 20,
            // Lokalizacja jest zawsze 220px nad dolnym panelem
            bottom: bottomPosition + 220, 
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // 6. DOLNY PANEL (ADRES I PRZYCISK)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: 20,
            right: 20,
            // To naprawia problem: Jest nad systemowym navbar (safeAreaBottom)
            // I nad klawiaturą (keyboardHeight)
            bottom: bottomPosition, 
            
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), spreadRadius: 5, blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Zajmuje tylko tyle miejsca ile potrzebuje
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _addressController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _searchPlace(),
                      onChanged: (text) {
                        if (!_isSearchMode && text.isNotEmpty) {
                          setState(() => _isSearchMode = true);
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: "Wpisz tutaj adres parkingu",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                         if (_isLoadingAddress) return;
                         
                         if (!_hasInteracted && _addressController.text.isEmpty) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wpisz adres lub przesuń mapę")));
                           return;
                         }

                         if (_isSearchMode || !_hasInteracted) {
                           _searchPlace();
                         } else {
                           _confirmSelection();
                           // Reset klawiatury po wyborze
                           FocusScope.of(context).unfocus(); 
                         }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoadingAddress 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            (!_hasInteracted || _isSearchMode) ? "Szukaj" : "Wybierz adres",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}