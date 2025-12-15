import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'screens/owner_login_screen.dart';
import 'screens/owner_home_screen.dart';
import 'screens/owner_step1_personal.dart';
void main() async {
  // 1. Obowiązkowa inicjalizacja silnika przed Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅✅✅ FIREBASE: POŁĄCZONO POMYŚLNIE! ✅✅✅");
  } catch (e) {
    print("❌❌❌ FIREBASE ERROR: Nie udało się połączyć z bazą danych! ❌❌❌");
    print("Szczegóły błędu: $e");
  }

  // --- SPRAWDZACZ 2: STRIPE ---
  try {
    // Twój klucz testowy (Publiczny)
    Stripe.publishableKey = 'pk_test_51SZtQM6TqOz44N4yRz4j6AiysVbnL3NjnCgm2zXtNSTlKYVaGkChUWPixVGmrKpEwNR5rG6A7S1GVnrd7O6boe5B004IwZL1aWg'; 
    await Stripe.instance.applySettings();
    print("✅✅✅ STRIPE: ZAINICJOWANO POMYŚLNIE! ✅✅✅");
  } catch (e) {
    print("❌❌❌ STRIPE ERROR: Płatności mogą nie działać! ❌❌❌");
    print("Szczegóły błędu: $e");
  }

  // 2. Start Firebase z konfiguracją
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ParkCheckOwnerApp());
}

class ParkCheckOwnerApp extends StatelessWidget {
  const ParkCheckOwnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkCheck Owner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Nowoczesny wygląd
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      // Ustawiamy naszą "Bramkę Autoryzacji" jako ekran startowy
      home: const OwnerAuthWrapper(),
    );
  }
}

// --- BRAMKA AUTORYZACJI ---
// Decyduje, który ekran pokazać na starcie
class OwnerAuthWrapper extends StatelessWidget {
  const OwnerAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return const OwnerHomeScreen(); // Zalogowany -> Panel
        }

        // 3. ZMIANA TUTAJ: Niezalogowany -> Ekran Logowania
        return const OwnerLoginScreen(); 
      },
    );
  }
}