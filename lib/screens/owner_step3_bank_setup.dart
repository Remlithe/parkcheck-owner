// lib/screens/owner_step3_bank_setup.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- Potrzebne do otwarcia linku
import '../widgets/registration_layout.dart';
import '../models/owner_model.dart';
import '../models/parking_area_model.dart';

class OwnerStep3BankSetup extends StatefulWidget {
  final String firstName, lastName, email, phone, password, parkingName, address;
  final double pricePerHour;
  final int capacity;
  final dynamic location; // LatLng

  const OwnerStep3BankSetup({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.parkingName,
    required this.pricePerHour,
    required this.capacity,
    required this.location,
    required this.address,
  });

  @override
  State<OwnerStep3BankSetup> createState() => _OwnerStep3BankSetupState();
}

class _OwnerStep3BankSetupState extends State<OwnerStep3BankSetup> {
  bool _isLoading = false;
  
  // Czy proces Stripe został rozpoczęty?
  bool _isOnboardingStarted = false;

  Future<void> _startStripeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      // 1. Rejestracja w Firebase Auth (jeśli jeszcze nie ma konta)
      UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );
      final ownerUid = cred.user!.uid;

      // 2. Utworzenie konta Stripe (Express)
      final HttpsCallable createAccount = FirebaseFunctions.instance.httpsCallable('createConnectedAccount');
      final accountResult = await createAccount.call({'email': widget.email});
      final stripeAccountId = accountResult.data['stripeAccountId'];

      // 3. Wygenerowanie Linku do Onboardingu
      final HttpsCallable createLink = FirebaseFunctions.instance.httpsCallable('createAccountLink');
      final linkResult = await createLink.call({'accountId': stripeAccountId});
      final String onboardingUrl = linkResult.data['url'];

      // 4. Zapisanie danych w Firestore (zanim wyjdziemy do przeglądarki)
      await _saveDataToFirestore(ownerUid, stripeAccountId);

      // 5. Otwarcie przeglądarki z formularzem Stripe
      final Uri url = Uri.parse(onboardingUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        setState(() {
          _isOnboardingStarted = true;
          _isLoading = false;
        });
      } else {
        throw 'Nie można otworzyć linku Stripe';
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveDataToFirestore(String uid, String stripeId) async {
      // Zapis Właściciela
      final newOwner = OwnerModel(
        uid: uid,
        email: widget.email,
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phone,
        stripeAccountId: stripeId,
      );
      await FirebaseFirestore.instance.collection('owners').doc(uid).set(newOwner.toFirestore());

      // Zapis Parkingu
      final newSpot = ParkingAreaModel(
        id: "",
        ownerUid: uid,
        name: widget.parkingName,
        address: widget.address,
        location: widget.location,
        pricePerHour: widget.pricePerHour,
        totalCapacity: widget.capacity,
        occupiedSpots: 0,
        features: ['Ochrona'],
      );
      await FirebaseFirestore.instance.collection('parking_spots').add(newSpot.toFirestore());
  }

  void _finish() async {
    // W normalnej aplikacji tutaj sprawdzilibyśmy w Stripe API, czy onboarding się udał.
    // W MVP zakładamy, że user wrócił z przeglądarki i kliknął "Gotowe".
    await FirebaseAuth.instance.signOut();
    if(mounted) {
       Navigator.of(context).popUntil((route) => route.isFirst);
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rejestracja zakończona! Zaloguj się.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RegistrationLayout(
      currentStep: 3,
      totalSteps: 3,
      title: "Wypłaty",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            
            const Text(
              "Skonfiguruj wypłaty",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Zostaniesz przeniesiony na bezpieczną stronę Stripe, aby podać dane bankowe i zweryfikować tożsamość.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            if (_isLoading)
              const CircularProgressIndicator()
            else if (!_isOnboardingStarted)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _startStripeOnboarding,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text("ROZPOCZNIJ KONFIGURACJĘ"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800], 
                    foregroundColor: Colors.white
                  ),
                ),
              )
            else
              Column(
                children: [
                  const Text("Formularz otwarty w przeglądarce...", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        foregroundColor: Colors.white
                      ),
                      child: const Text("GOTOWE - ZAKOŃCZ REJESTRACJĘ"),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}