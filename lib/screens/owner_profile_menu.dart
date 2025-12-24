import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'owner_login_screen.dart'; // <--- ZMIANA: Importujemy logowanie partnera
import 'owner_edit_subscreens.dart';
import 'owner_my_parkings_screen.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      // <--- ZMIANA: Przekierowanie do OwnerLoginScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const OwnerLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("Twoje Konto", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 20),
                child: Column(
                  children: [
                    _buildMenuOption(
                      icon: Icons.person,
                      title: "Dane osobowe",
                      subtitle: "Imię, nazwisko, telefon, email",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerPersonalDataScreen())),
                    ),

                    _buildMenuOption(
                      icon: Icons.account_balance,
                      title: "Dane bankowe",
                      subtitle: "Konto Stripe i wypłaty",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerBankDataScreen())),
                    ),

                    _buildMenuOption(
                      icon: Icons.local_parking,
                      title: "Moje Parkingi",
                      subtitle: "Zarządzaj i dodawaj nowe",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerMyParkingsScreen())),
                    ),

                    _buildMenuOption(
                      icon: Icons.report_problem,
                      title: "Zgłoś problem",
                      subtitle: "Napisz do wsparcia",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerReportScreen())),
                    ),
                  ],
                ),
              ),
            ),

            // Przycisk Wyloguj
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), 
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Color(0xFF007AFF),
                  ),
                  onPressed: () => _signOut(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Wyloguj się", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF007AFF)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}