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

class _OwnerStep3BankSetupState extends State<OwnerStep3BankSetup> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isOnboardingStarted = false;
  String? _createdOwnerUid;
  String? _tempStripeAccountId; // Pamięć ulotna (nie zapisujemy w bazie dopóki nie ma sukcesu)

  // Linki Cloud Functions
  final String _createAccountUrl = "https://createconnectedaccount-scpllyrlna-uc.a.run.app";
  final String _createLinkUrl = "https://createaccountlink-scpllyrlna-uc.a.run.app";
  final String _checkStatusUrl = "https://checkstripeaccountstatus-scpllyrlna-uc.a.run.app"; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Automatyczne sprawdzenie przy powrocie do aplikacji
      if (_isOnboardingStarted && !_isLoading) {
        _verifyStripeStatusAndFinish(silent: false); 
      }
    }
  }

  Future<void> _startStripeOnboarding() async {
    setState(() => _isLoading = true);

    try {
      String ownerUid;
      
      // 1. Logika Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        ownerUid = currentUser.uid;
      } else {
        try {
          UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );
          ownerUid = cred.user!.uid;
        } on FirebaseAuthException {
          UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: widget.email,
            password: widget.password,
          );
          ownerUid = cred.user!.uid;
        }
      }

      _createdOwnerUid = ownerUid; 
      
      if (!mounted) return;

      // 2. Utworzenie konta Stripe (lub pobranie istniejącego w przyszłości)
      final HttpsCallable createAccount = FirebaseFunctions.instance.httpsCallableFromUrl(_createAccountUrl);
      final accountResult = await createAccount.call({'email': widget.email});
      
      final stripeAccountId = (accountResult.data is Map) 
          ? accountResult.data['stripeAccountId'] 
          : accountResult.data;

      if (stripeAccountId == null) throw "Brak stripeAccountId";

      _tempStripeAccountId = stripeAccountId; // Zapisujemy w RAM

      // 3. Link Onboarding
      final HttpsCallable createLink = FirebaseFunctions.instance.httpsCallableFromUrl(_createLinkUrl);
      final linkResult = await createLink.call({'accountId': stripeAccountId});
      
      final String onboardingUrl = (linkResult.data is Map)
          ? linkResult.data['url']
          : linkResult.data;

      if (!mounted) return;

      final Uri url = Uri.parse(onboardingUrl);
      if (await canLaunchUrl(url)) {
        setState(() {
          _isOnboardingStarted = true;
          _isLoading = false; 
        });
        await launchUrl(url, mode: LaunchMode.externalApplication);
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

  // Funkcja Weryfikująca (Sędzia)
  Future<void> _verifyStripeStatusAndFinish({bool silent = false}) async {
    if (_createdOwnerUid == null || _tempStripeAccountId == null) return;

    setState(() => _isLoading = true);
    
    try {
      final HttpsCallable checkStatus = FirebaseFunctions.instance.httpsCallableFromUrl(_checkStatusUrl);
      final result = await checkStatus.call({'accountId': _tempStripeAccountId});
      
      final data = result.data as Map<dynamic, dynamic>;
      final bool isDetailsSubmitted = data['detailsSubmitted'] ?? false;
      // Możesz też sprawdzać data['chargesEnabled'] jeśli chcesz być bardziej restrykcyjny
      
      if (isDetailsSubmitted) {
        // --- SUKCES! ---
        // Tylko tutaj mamy prawo zapisać dane do bazy.
        await _createAccountInDatabase(); 
      } else {
        // --- PORAŻKA ---
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        if (!silent) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Konfiguracja nieukończona"),
              content: const Text("Stripe informuje, że proces nie został zakończony.\nMusisz wypełnić wszystkie dane w formularzu bankowym."),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Rozumiem")),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Błąd weryfikacji: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd weryfikacji: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  // Fizyczny zapis do bazy (uruchamiany tylko przez weryfikator)
  Future<void> _createAccountInDatabase() async {
    try {
      // 1. Zapisz Właściciela
      final newOwner = OwnerModel(
        uid: _createdOwnerUid!,
        email: widget.email,
        firstName: widget.firstName,
        lastName: widget.lastName,
        phoneNumber: widget.phone,
        stripeAccountId: _tempStripeAccountId!,
      );
      await FirebaseFirestore.instance.collection('owners').doc(_createdOwnerUid!).set(
        newOwner.toFirestore(), 
        SetOptions(merge: true)
      );

      // 2. Zapisz Parking
      final newSpot = ParkingAreaModel(
        id: "", 
        ownerUid: _createdOwnerUid!,
        name: widget.parkingName,
        address: widget.address,
        location: widget.location,
        pricePerHour: widget.pricePerHour,
        totalCapacity: widget.capacity,
        occupiedSpots: 0,
        features: ['Ochrona'],
      );
      
      await FirebaseFirestore.instance.collection('parking_spots').add(newSpot.toFirestore());

      if (!mounted) return;

      // Wyjście
      Navigator.of(context).popUntil((route) => route.isFirst);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Weryfikacja pomyślna! Konto utworzone."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        )
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd zapisu danych: $e")));
      setState(() => _isLoading = false);
    }
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
            
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isOnboardingStarted ? Icons.hourglass_top : Icons.account_balance_wallet, 
                        size: 80, 
                        color: const Color(0xFF007AFF)
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        _isOnboardingStarted ? "Weryfikacja w toku..." : "Skonfiguruj wypłaty",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isOnboardingStarted 
                          ? "Wypełnij dane na stronie Stripe, a następnie wróć tutaj. Aplikacja automatycznie sprawdzi status."
                          : "Zostaniesz przeniesiony na bezpieczną stronę Stripe, aby podać dane bankowe.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      
                      const SizedBox(height: 20),
                      if (_isLoading) const CircularProgressIndicator(),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: _isOnboardingStarted
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // <--- 1. To wymusza rozciągnięcie do wysokości rodzica (55)
                      children: [
                        // Guzik 1: Powrót do Stripe
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _startStripeOnboarding,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              // minimumSize nie jest już konieczne przy CrossAxisAlignment.stretch, 
                              // ale można zostawić dla pewności:
                              minimumSize: const Size(0, 55), 
                            ),
                            child: const Text("Otwórz Stripe ponownie", 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black87, fontSize: 12)
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // Guzik 2: Ręczne sprawdzenie
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _verifyStripeStatusAndFinish(silent: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF), 
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              // 2. DODANO TO SAMO CO W PIERWSZYM GUZIKU:
                              minimumSize: const Size(0, 55), 
                            ),
                            child: _isLoading 
                              ? const SizedBox(
                                  height: 20, 
                                  width: 20, 
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                )
                              : const Text("SPRAWDŹ STATUS", 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)
                                ),
                          ),
                        ),
                      ],
                    )
                  // Stan początkowy (Jeden duży guzik)
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