// lib/screens/owner_profile_menu.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'owner_edit_subscreens.dart'; // Import ekranów edycji
import 'owner_my_parkings_screen.dart'; // Import listy parkingów

class OwnerProfileMenu extends StatelessWidget {
  const OwnerProfileMenu({super.key});

  void _nav(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Ustawienia Profilu", style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _menuItem(Icons.person, "Dane osobowe", () => _nav(context, const OwnerPersonalDataScreen())),
          // NOWE:
          _menuItem(Icons.account_balance, "Dane konta bankowego", () => _nav(context, const OwnerBankDataScreen())),
          _menuItem(Icons.local_parking, "Moje parkingi", () => _nav(context, const OwnerMyParkingsScreen())),
          //
          _menuItem(Icons.mail, "Zgłoś problem", () => _nav(context, const OwnerReportScreen())),
          
          const SizedBox(height: 30),
          OutlinedButton(
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
            child: const Text("WYLOGUJ SIĘ"),
          )
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}