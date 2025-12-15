// lib/screens/owner_login_screen.dart
import 'package:flutter/material.dart';
import '../services/owner_auth_service.dart';
import 'owner_step1_personal.dart'; // Żeby móc przejść do rejestracji

class OwnerLoginScreen extends StatefulWidget {
  const OwnerLoginScreen({super.key});

  @override
  State<OwnerLoginScreen> createState() => _OwnerLoginScreenState();
}

class _OwnerLoginScreenState extends State<OwnerLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final OwnerAuthService _authService = OwnerAuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Podaj email i hasło")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Logowanie przez nasz serwis (sprawdza czy to właściciel)
      await _authService.signInOwner(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
      
      // Nie musimy robić Navigator.push, bo AuthWrapper w main.dart
      // sam wykryje zmianę stanu i przełączy na AddParkingScreen.

    } catch (e) {
      String msg = "Błąd logowania";
      if (e.toString().contains("user-not-found")) {
        msg = "Nie znaleziono takiego użytkownika.";
      } else if (e.toString().contains("wrong-password")) {
        msg = "Błędne hasło.";
      } else if (e.toString().contains("not-owner")) {
        msg = "To konto nie ma uprawnień Właściciela.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToRegistration() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OwnerStep1Personal()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Partnera")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_parking, size: 80, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  "Witaj ponownie!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passCtrl,
                  decoration: const InputDecoration(labelText: "Hasło"),
                  obscureText: true,
                ),
                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text("ZALOGUJ SIĘ"),
                        ),
                      ),
                
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _goToRegistration,
                  child: const Text("Nie masz konta? Zostań partnerem"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}