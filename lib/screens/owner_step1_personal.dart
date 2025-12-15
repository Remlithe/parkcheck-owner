// lib/screens/owner_step1_personal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/registration_layout.dart'; // <--- Import szablonu
import 'owner_step2_parking.dart'; // Przejście do kroku 2

class OwnerStep1Personal extends StatefulWidget {
  const OwnerStep1Personal({super.key});

  @override
  State<OwnerStep1Personal> createState() => _OwnerStep1PersonalState();
}

class _OwnerStep1PersonalState extends State<OwnerStep1Personal> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  void _goToNextStep() {
    // Prosta walidacja
    if (_firstNameCtrl.text.isEmpty || _lastNameCtrl.text.isEmpty || 
        _emailCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wypełnij wszystkie pola")));
      return;
    }
    if (_phoneCtrl.text.length != 9) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Telefon musi mieć 9 cyfr")));
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hasła nie są identyczne")));
      return;
    }

    // PRZEJŚCIE DO KROKU 2 (Przekazujemy dane)
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => OwnerStep2Parking(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // UŻYCIE SZABLONU (Step 1/3)
    return RegistrationLayout(
      currentStep: 1,
      title: "Dane Partnera",
      // onBackPressed: null -> Domyślnie cofa do poprzedniego ekranu (np. startowego)
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: "Imię")),
            const SizedBox(height: 15),
            TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: "Nazwisko")),
            const SizedBox(height: 15),
            TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email"), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneCtrl, 
              decoration: const InputDecoration(labelText: "Telefon", prefixText: "+48 "), 
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)],
            ),
            const SizedBox(height: 15),
            TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: "Hasło"), obscureText: true),
            const SizedBox(height: 15),
            TextField(controller: _confirmPassCtrl, decoration: const InputDecoration(labelText: "Powtórz hasło"), obscureText: true),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _goToNextStep,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: const Text("DALEJ"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}