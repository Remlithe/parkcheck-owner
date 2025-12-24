// lib/screens/owner_login_screen.dart
import 'package:flutter/material.dart';
import '../services/owner_auth_service.dart';
import 'owner_step1_personal.dart';
import 'owner_main_screen.dart'; // <--- 1. DODANO IMPORT

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
      // Logowanie w Firebase
      await _authService.signInOwner(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      // <--- 2. ZMIANA: Ręczne przekierowanie do EKRANU Z NAVBAREM
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OwnerMainScreen()),
          (route) => false, // Usuwa historię (nie można cofnąć do logowania)
        );
      }
      
    } catch (e) {
      String msg = "Błąd logowania";
      if (e.toString().contains("user-not-found")) {
        msg = "Nie znaleziono takiego partnera.";
      } else if (e.toString().contains("wrong-password")) {
        msg = "Błędne hasło.";
      } else if (e.toString().contains("not-owner")) {
        msg = "To konto nie ma uprawnień Partnera.";
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(Icons.business_center, size: 80, color: Color(0xFF007AFF)),
                    const SizedBox(height: 20),
                    const Text(
                      "Panel Partnera",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Zarządzaj swoimi parkingami",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),

                    _buildInput(_emailCtrl, "Email firmowy", Icons.email),
                    const SizedBox(height: 16),
                    _buildInput(_passCtrl, "Hasło", Icons.lock, isObscure: true),
                    
                    const SizedBox(height: 30),

                    // Link do rejestracji
                    TextButton(
                      onPressed: _goToRegistration,
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.grey, fontSize: 14, fontFamily: 'Roboto'),
                          children: [
                            TextSpan(text: "Nie masz konta? "),
                            TextSpan(
                              text: "Zostań Partnerem", 
                              style: TextStyle(
                                color: Color(0xFF007AFF),
                                fontWeight: FontWeight.bold, 
                                decoration: TextDecoration.underline
                              )
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Przycisk Logowania na dole
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ZALOGUJ SIĘ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon, {bool isObscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: isObscure,
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