// lib/screens/owner_edit_subscreens.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

// --- SZABLON (POPRAWIONY) ---
class BaseOwnerEditScreen extends StatelessWidget {
  final String title;
  final Widget body;
  final VoidCallback? onSave;

  const BaseOwnerEditScreen({super.key, required this.title, required this.body, this.onSave});

  @override
  Widget build(BuildContext context) {
    // Pobieramy wysokość klawiatury
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      // 1. To sprawia, że guzik na dole nie "skacze" nad klawiaturę
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // 2. SafeArea chroni przed nachodzeniem na dolny pasek (navbar) iPhone'a/Androida
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                // 3. Dodajemy padding wewnątrz listy, żeby można było przewinąć treść
                // nad klawiaturę, mimo że guzik i scaffold się nie ruszają.
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 20.0,
                  bottom: bottomPadding + 20.0, // Klawiatura + margines
                ),
                child: body,
              ),
            ),
            
            // Guzik jest poza ScrollView, więc zawsze "siedzi" na samym dole
            if (onSave != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0), // Margines wokół guzika
                decoration: BoxDecoration(
                  color: Colors.grey[50], // Kolor tła pod guzikiem
                ),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, 
                      foregroundColor: Colors.white
                    ),
                    child: const Text("ZAPISZ"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 1. DANE OSOBOWE (Z Emailem!) - BEZ ZMIAN W LOGICE
class OwnerPersonalDataScreen extends StatefulWidget {
  const OwnerPersonalDataScreen({super.key});
  @override
  State<OwnerPersonalDataScreen> createState() => _OwnerPersonalDataScreenState();
}

class _OwnerPersonalDataScreenState extends State<OwnerPersonalDataScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); 
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final doc = await FirebaseFirestore.instance.collection('owners').doc(user?.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _firstNameCtrl.text = data['firstName'] ?? '';
        _lastNameCtrl.text = data['lastName'] ?? '';
        _phoneCtrl.text = data['phoneNumber'] ?? '';
        _emailCtrl.text = data['email'] ?? user?.email ?? ''; 
      });
    }
  }

  void _saveData() async {
    await FirebaseFirestore.instance.collection('owners').doc(user?.uid).update({
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dane zaktualizowane!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseOwnerEditScreen(
      title: "Dane osobowe",
      onSave: _saveData,
      body: Column(
        children: [
          TextField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: "Imię", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: "Nazwisko", border: OutlineInputBorder())),
          const SizedBox(height: 15),
          TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: "Telefon", border: OutlineInputBorder()), keyboardType: TextInputType.phone),
          const SizedBox(height: 15),
          TextField(
            controller: _emailCtrl,
            enabled: false, 
            decoration: const InputDecoration(
              labelText: "Email (Login)", 
              border: OutlineInputBorder(),
              fillColor: Colors.white,
              filled: true
            ),
          ),
        ],
      ),
    );
  }
}

// 2. ZGŁOŚ PROBLEM - BEZ ZMIAN W LOGICE
class OwnerReportScreen extends StatefulWidget {
  const OwnerReportScreen({super.key});
  @override
  State<OwnerReportScreen> createState() => _OwnerReportScreenState();
}

class _OwnerReportScreenState extends State<OwnerReportScreen> {
  final _msgCtrl = TextEditingController();

  void _send() {
    if (_msgCtrl.text.isEmpty) return;
    FirebaseFirestore.instance.collection('reports').add({
      'uid': FirebaseAuth.instance.currentUser?.uid,
      'type': 'owner',
      'message': _msgCtrl.text,
      'date': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Wysłano!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseOwnerEditScreen(
      title: "Zgłoś problem",
      onSave: _send,
      body: TextField(
        controller: _msgCtrl,
        maxLines: 5,
        decoration: const InputDecoration(labelText: "Opisz problem...", border: OutlineInputBorder()),
      ),
    );
  }
}

// 3. DANE KONTA BANKOWEGO - BEZ ZMIAN W LOGICE
class OwnerBankDataScreen extends StatefulWidget {
  const OwnerBankDataScreen({super.key});

  @override
  State<OwnerBankDataScreen> createState() => _OwnerBankDataScreenState();
}

class _OwnerBankDataScreenState extends State<OwnerBankDataScreen> {
  bool _isLoading = false;

  Future<void> _openStripeDashboard(String stripeAccountId) async {
    setState(() => _isLoading = true);
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('createLoginLink');
      final result = await callable.call({'accountId': stripeAccountId});
      final url = Uri.parse(result.data['url']);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Nie można otworzyć linku do panelu Stripe.")),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Błąd funkcji Cloud: ${e.message}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Wystąpił nieoczekiwany błąd: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return BaseOwnerEditScreen(
      title: "Konto Bankowe (Stripe)",
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('owners').doc(uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final stripeId = data?['stripeAccountId'];

          if (stripeId == null) {
            return const Center(child: Text("Nie podpięto konta bankowego."));
          }

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Column(
              children: [
                const Icon(Icons.account_balance, size: 50, color: Colors.green),
                const SizedBox(height: 20),
                const Text("Status: AKTYWNE", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                const Divider(height: 30),
                ListTile(
                  title: const Text("Identyfikator Stripe"),
                  subtitle: Text(stripeId, style: const TextStyle(fontFamily: 'monospace')),
                  leading: const Icon(Icons.numbers),
                ),
                const SizedBox(height: 30),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: () => _openStripeDashboard(stripeId),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text("ZARZĄDZAJ KONTEM W STRIPE"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text(
                  "Wypłaty są realizowane automatycznie przez platformę Stripe.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}