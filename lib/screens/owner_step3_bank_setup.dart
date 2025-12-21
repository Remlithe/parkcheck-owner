// lib/screens/owner_step3_bank_setup.dart
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart'; 
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
  bool _isOnboardingStarted = false;


Future<void> _startStripeOnboarding() async {
    // Zabezpieczenie: sprawdzamy czy linki zostały uzupełnione
    

    setState(() => _isLoading = true);

    try {
      String ownerUid;
      
      // 1. INTELIGENTNA OBSŁUGA AUTH (Logowanie LUB Rejestracja)
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // A. Użytkownik już jest zalogowany
        ownerUid = currentUser.uid;
      } else {
        try {
          // B. Próbujemy się ZALOGOWAĆ
          UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );
          ownerUid = cred.user!.uid;
        } on FirebaseAuthException catch (authError) {
          // C. Jeśli logowanie nie wyszło (bo nie ma usera), to REJESTRUJEMY
          if (authError.code == 'user-not-found' || 
              authError.code == 'invalid-credential' || 
              authError.code == 'wrong-password') {
            
            UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
              email: widget.email,
              password: widget.password,
            );
            ownerUid = cred.user!.uid;
          } else {
            // Inny błąd (np. brak sieci) - przerywamy
            rethrow;
          }
        }
      }
      
      if (!mounted) return;

      // 2. Wywołanie funkcji createConnectedAccount (POPRAWKA: przekazujemy String)
      // Używamy httpsCallableFromUrl bo masz funkcje Gen 2
      final HttpsCallable createAccount = FirebaseFunctions.instance.httpsCallable(
        'createConnectedAccount' 
      );
      
      final accountResult = await createAccount.call({'email': widget.email});
      
      if (accountResult.data == null) throw "Brak danych z funkcji createConnectedAccount";
      final stripeAccountId = accountResult.data['stripeAccountId'];

      // 3. Wywołanie funkcji createAccountLink (POPRAWKA: przekazujemy String)
      final HttpsCallable createLink = FirebaseFunctions.instance.httpsCallable(
        'createAccountLink'
      );

      final linkResult = await createLink.call({'accountId': stripeAccountId});
      
      if (linkResult.data == null) throw "Brak danych z funkcji createAccountLink";
      final String onboardingUrl = linkResult.data['url'];

      // 4. Zapisanie danych w Firestore
      await _saveDataToFirestore(ownerUid, stripeAccountId);

      if (!mounted) return;

      // 5. Otwarcie przeglądarki
      final Uri url = Uri.parse(onboardingUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        
        if (!mounted) return;
        
        setState(() {
          _isOnboardingStarted = true;
          _isLoading = false;
        });
      } else {
        throw 'Nie można otworzyć linku Stripe';
      }

    } catch (e) {
      if (!mounted) return;
      debugPrint("Błąd: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd: $e")));
      setState(() => _isLoading = false);
    }
  }
  Future<void> _saveDataToFirestore(String uid, String stripeId) async {
      final newOwner = OwnerModel(
        uid: uid,
        email: widget.email,
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phone,
        stripeAccountId: stripeId,
      );
      await FirebaseFirestore.instance.collection('owners').doc(uid).set(newOwner.toFirestore());

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
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rejestracja zakończona! Zaloguj się.")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, 
      appBar: AppBar(
        title: const Text("Wypłaty", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // GÓRA: Pasek postępu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF007AFF),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 10),
                  const Text("Krok 3 z 3", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            
            // ŚRODEK: Treść
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 80, color: Color(0xFF007AFF)),
                      const SizedBox(height: 20),
                      
                      const Text(
                        "Skonfiguruj wypłaty",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Zostaniesz przeniesiony na bezpieczną stronę Stripe, aby podać dane bankowe i zweryfikować tożsamość.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      
                      const SizedBox(height: 20),
                      if (_isLoading) const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),

            // DÓŁ: Guzik
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: _isOnboardingStarted
                  ? ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("GOTOWE - ZAKOŃCZ REJESTRACJĘ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton.icon(
                      onPressed: _isLoading ? null : _startStripeOnboarding,
                      icon: const Icon(Icons.open_in_new, color: Colors.white),
                      label: const Text("ROZPOCZNIJ KONFIGURACJĘ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}