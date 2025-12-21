// lib/screens/owner_step1_personal.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'owner_step2_parking.dart';

class OwnerStep1Personal extends StatefulWidget {
  const OwnerStep1Personal({super.key});

  @override
  State<OwnerStep1Personal> createState() => _OwnerStep1PersonalState();
}

class _OwnerStep1PersonalState extends State<OwnerStep1Personal> {
  // Kontrolery
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Focus Nodes (do nawigacji i scrollowania)
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();

  // Zmienne na błędy (pod inputami)
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _phoneError;
  String? _passError;
  String? _confirmPassError;

  @override
  void dispose() {
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  // --- WALIDACJE (Skopiowane z registration_screen.dart) ---

  bool _isEmailValid(String email) {
    // Używamy wersji bezpiecznej dla domen typu .online (min. 2 znaki na końcu)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool _hasDigits(String text) {
    return RegExp(r'[0-9]').hasMatch(text);
  }

  void _goToNextStep() {
    // 1. Reset błędów
    setState(() {
      _firstNameError = null;
      _lastNameError = null;
      _emailError = null;
      _phoneError = null;
      _passError = null;
      _confirmPassError = null;
    });

    String firstName = _firstNameCtrl.text.trim();
    String lastName = _lastNameCtrl.text.trim();
    String email = _emailCtrl.text.trim();
    String phone = _phoneCtrl.text.trim();
    String password = _passCtrl.text.trim();
    String confirmPassword = _confirmPassCtrl.text.trim();
    
    bool isValid = true;

    // 2. Logika sprawdzania (1:1 jak u kierowcy + Telefon)
    
    // Imię
    if (firstName.isEmpty) {
      setState(() => _firstNameError = "Podaj imię");
      isValid = false;
    } else if (_hasDigits(firstName)) {
      setState(() => _firstNameError = "Bez cyfr");
      isValid = false;
    }

    // Nazwisko
    if (lastName.isEmpty) {
      setState(() => _lastNameError = "Podaj nazwisko");
      isValid = false;
    } else if (_hasDigits(lastName)) {
      setState(() => _lastNameError = "Bez cyfr");
      isValid = false;
    }

    // Email
    if (email.isEmpty) {
      setState(() => _emailError = "Podaj email");
      isValid = false;
    } else if (!_isEmailValid(email)) {
      setState(() => _emailError = "Zły format");
      isValid = false;
    }

    // Telefon (Partner ma telefon, kierowca nie miał, dodajemy analogiczną walidację)
    if (phone.isEmpty) {
      setState(() => _phoneError = "Podaj telefon");
      isValid = false;
    } else if (phone.length < 9) {
      setState(() => _phoneError = "Min. 9 cyfr");
      isValid = false;
    }

    // Hasło
    if (password.isEmpty) {
      setState(() => _passError = "Podaj hasło");
      isValid = false;
    } else if (password.length < 6) {
      setState(() => _passError = "Min. 6 znaków");
      isValid = false;
    }

    // Powtórz hasło
    if (confirmPassword.isEmpty) {
      setState(() => _confirmPassError = "Powtórz hasło");
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() => _confirmPassError = "Różne hasła");
      isValid = false;
    }

    if (!isValid) return;

    // JEŚLI WSZYSTKO OK -> Przejdź dalej
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => OwnerStep2Parking(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        password: password,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Rejestracja Partnera", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // GÓRA: PROGRESS BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: 0.33,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF007AFF),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 10),
                  const Text("Krok 1 z 3", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

            // ŚRODEK: FORMULARZ
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24.0, 
                    right: 24.0, 
                    bottom: bottomPadding + 20
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text("Dane Partnera", textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      const Text("Wprowadź swoje dane, abyśmy mogli skontaktować się w sprawach rozliczeń.", 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey)
                      ),
                      const SizedBox(height: 30),

                      _buildInput(_firstNameCtrl, "Imię", Icons.person, 
                        errorText: _firstNameError,
                        focusNode: _firstNameFocus,
                        nextFocus: _lastNameFocus
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInput(_lastNameCtrl, "Nazwisko", Icons.person_outline, 
                        errorText: _lastNameError,
                        focusNode: _lastNameFocus,
                        nextFocus: _emailFocus
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInput(_emailCtrl, "Email", Icons.email, 
                        type: TextInputType.emailAddress,
                        errorText: _emailError,
                        focusNode: _emailFocus,
                        nextFocus: _phoneFocus
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInput(_phoneCtrl, "Telefon", Icons.phone, 
                        type: TextInputType.phone,
                        errorText: _phoneError,
                        focusNode: _phoneFocus,
                        nextFocus: _passFocus,
                        // Pozwalamy tylko na cyfry i max 9 znaków
                        formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(9)]
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInput(_passCtrl, "Hasło", Icons.lock, 
                        isObscure: true,
                        errorText: _passError,
                        focusNode: _passFocus,
                        nextFocus: _confirmFocus
                      ),
                      const SizedBox(height: 16),
                      
                      _buildInput(_confirmPassCtrl, "Powtórz hasło", Icons.lock_outline, 
                        isObscure: true,
                        errorText: _confirmPassError,
                        focusNode: _confirmFocus,
                        isLast: true,
                        onSubmitted: (_) => _goToNextStep(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // DÓŁ: GUZIK
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

  // Helper Input (Wzorowany na registration_screen.dart)
  Widget _buildInput(
    TextEditingController ctrl, 
    String label, 
    IconData icon, 
    {
      bool isObscure = false, 
      TextInputType? type, 
      String? errorText,
      FocusNode? focusNode,
      FocusNode? nextFocus,
      bool isLast = false,
      Function(String)? onSubmitted,
      List<TextInputFormatter>? formatters,
    }) {
    
    return _AutoScrollWhenFocused(
      focusNode: focusNode!,
      child: TextField(
        controller: ctrl,
        obscureText: isObscure,
        keyboardType: type,
        focusNode: focusNode,
        inputFormatters: formatters,
        textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
        onSubmitted: onSubmitted ?? (_) {
          if (nextFocus != null) {
            FocusScope.of(context).requestFocus(nextFocus);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
          errorText: errorText, // Tutaj pojawia się błąd pod inputem
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF007AFF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
        ),
      ),
    );
  }
}

// --- KLASA POMOCNICZA DO AUTOMATYCZNEGO SCROLLOWANIA ---
class _AutoScrollWhenFocused extends StatefulWidget {
  final FocusNode focusNode;
  final Widget child;

  const _AutoScrollWhenFocused({required this.focusNode, required this.child});

  @override
  State<_AutoScrollWhenFocused> createState() => _AutoScrollWhenFocusedState();
}

class _AutoScrollWhenFocusedState extends State<_AutoScrollWhenFocused> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_ensureVisible);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_ensureVisible);
    super.dispose();
  }

  void _ensureVisible() {
    if (widget.focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}