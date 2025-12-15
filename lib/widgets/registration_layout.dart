// lib/widgets/registration_layout.dart
import 'package:flutter/material.dart';

class RegistrationLayout extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final Widget child;
  final VoidCallback? onBackPressed;

  const RegistrationLayout({
    super.key,
    required this.currentStep,
    this.totalSteps = 3, // Mamy 3 kroki rejestracji
    required this.title,
    required this.child,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Obliczamy długość paska (np. 1/3 = 0.33, 2/3 = 0.66)
    final double progress = currentStep / totalSteps;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // TYTUŁ KROKU
        title: Text(
          title, 
          style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        // STRZAŁKA POWROTNA
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        ),
        // LICZNIK KROKÓW PO PRAWEJ
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "$currentStep / $totalSteps",
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
        // PASEK POSTĘPU (PROGRESS BAR)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue), // Niebieski pasek
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: child,
        ),
      ),
    );
  }
}