import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OwnerParkedScreen extends StatefulWidget {
  const OwnerParkedScreen({super.key});

  @override
  State<OwnerParkedScreen> createState() => _OwnerParkedScreenState();
}

class _OwnerParkedScreenState extends State<OwnerParkedScreen> {
  // --- STAN APLIKACJI ---
  String? _selectedParkingId;
  bool _showFailedPaymentsOnly = false; 
  
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  // --- LOGIKA BIZNESOWA ---

  void _handleSettleRequest(String sessionId, Map<String, dynamic> sessionData) {
    String? paymentStatus = sessionData['paymentStatus']; 
    String? lastError = sessionData['lastError'];
    // Pobieramy ID parkingu, żeby móc zaktualizować jego licznik!
    String parkingId = sessionData['parkingId']; 
    
    bool hasPaymentIssue = (paymentStatus == 'failed' || paymentStatus == 'error');

    if (hasPaymentIssue) {
      _showPaymentWarningDialog(sessionId, parkingId, lastError);
    } else {
      _finalizeSettlement(sessionId, parkingId);
    }
  }

  void _showPaymentWarningDialog(String sessionId, String parkingId, String? errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("BŁĄD PŁATNOŚCI ONLINE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: Icon(Icons.credit_card_off, size: 50, color: Colors.red)),
            const SizedBox(height: 15),
            const Text("Kierowca próbował zapłacić w aplikacji, ale transakcja została odrzucona.", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: Text(
                "Błąd: ${errorMsg ?? 'Brak szczegółów'}", 
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)
              ),
            ),
            const SizedBox(height: 20),
            const Text("Czy pobrałeś opłatę w gotówce i chcesz zakończyć parkowanie?", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Anuluj"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _finalizeSettlement(sessionId, parkingId);
            },
            child: const Text("Tak, Rozliczono"),
          ),
        ],
      ),
    );
  }

  // --- KLUCZOWA POPRAWKA TUTAJ ---
  Future<void> _finalizeSettlement(String sessionId, String parkingId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final sessionRef = firestore.collection('parking_sessions').doc(sessionId);
      final parkingRef = firestore.collection('parking_spots').doc(parkingId);

      await firestore.runTransaction((transaction) async {
        // 1. Pobierz aktualny stan parkingu
        final parkingSnapshot = await transaction.get(parkingRef);
        
        if (parkingSnapshot.exists) {
          int currentOccupied = parkingSnapshot.data()?['occupiedSpots'] ?? 0;
          // Zabezpieczenie, żeby nie zejść poniżej zera
          int newOccupancy = currentOccupied > 0 ? currentOccupied - 1 : 0;

          // 2. Zmniejsz licznik zajętych miejsc
          transaction.update(parkingRef, {
            'occupiedSpots': newOccupancy
          });
        }

        // 3. Zakończ sesję
        transaction.update(sessionRef, {
          'status': 'cash_settled',
          'endTime': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Rozliczono pomyślnie i zwolniono miejsce."), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd bazy: $e")));
    }
  }

  void _removeSession(String sessionId) async {
    try {
      // UWAGA: Usunięcie sesji z listy ("Usuń z listy") zazwyczaj
      // nie powinno wpływać na licznik parkingu (zakładamy, że to sprzątanie starych wpisów),
      // ale jeśli usuwasz AKTYWNĄ sesję, to też powinieneś zmniejszyć licznik.
      // Dla bezpieczeństwa zostawiam tu proste usuwanie, ale miej to na uwadze.
      await FirebaseFirestore.instance.collection('parking_sessions').doc(sessionId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Usunięto sesję.")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Błąd: $e")));
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text("Zaparkowani (Live)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // PANEL STEROWANIA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. WYSZUKIWARKA
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Szukaj rejestracji...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),

                // 2. CHECKBOX
                GestureDetector(
                  onTap: () => setState(() => _showFailedPaymentsOnly = !_showFailedPaymentsOnly),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showFailedPaymentsOnly ? Colors.red.shade50 : Colors.white,
                      border: Border.all(
                        color: _showFailedPaymentsOnly ? Colors.red.shade200 : Colors.grey.shade300
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24, height: 24,
                          child: Checkbox(
                            value: _showFailedPaymentsOnly,
                            activeColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) => setState(() => _showFailedPaymentsOnly = val ?? false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Pokaż tylko problemy z płatnością",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _showFailedPaymentsOnly ? Colors.red : Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. DROPDOWN (PEŁNA SZEROKOŚĆ)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('parking_spots').where('ownerUid', isEqualTo: uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const LinearProgressIndicator();
                    final docs = snapshot.data!.docs;
                    
                    if (_selectedParkingId == null && docs.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() => _selectedParkingId = docs.first.id);
                      });
                    }

                    String currentParkingName = "Wybierz parking";
                    if (_selectedParkingId != null && docs.isNotEmpty) {
                      try {
                        final selectedDoc = docs.firstWhere((d) => d.id == _selectedParkingId);
                        currentParkingName = (selectedDoc.data() as Map<String, dynamic>)['name'] ?? "Bez nazwy";
                      } catch (_) {}
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return PopupMenuButton<String>(
                          offset: const Offset(0, 60), 
                          constraints: BoxConstraints.tightFor(width: constraints.maxWidth),
                          elevation: 4,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          
                          onSelected: (val) {
                            setState(() => _selectedParkingId = val);
                          },
                          
                          itemBuilder: (context) => docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final isSelected = doc.id == _selectedParkingId;
                            
                            return PopupMenuItem<String>(
                              value: doc.id,
                              height: 50,
                              child: SizedBox(
                                width: double.infinity,
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                      color: isSelected ? Colors.blue : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        data['name'] ?? "Bez nazwy",
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: Colors.black87
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          child: Container(
                            height: 55,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    currentParkingName,
                                    style: const TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.w600, 
                                      color: Colors.black87
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87),
                              ],
                            ),
                          ),
                        );
                      }
                    );
                  },
                ),
              ],
            ),
          ),
          
          // LISTA
          Expanded(
            child: _selectedParkingId == null 
              ? const Center(child: Text("Wybierz parking powyżej")) 
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('parking_sessions')
                      .where('parkingId', isEqualTo: _selectedParkingId)
                      .where('status', isEqualTo: 'active') 
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return Center(child: Text("Błąd: ${snapshot.error}"));
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                    final docs = snapshot.data!.docs;
                    
                    var filteredDocs = docs.where((doc) {
                       final data = doc.data() as Map<String, dynamic>;
                       final plate = (data['licensePlate'] ?? "").toString().toLowerCase();
                       final paymentStatus = data['paymentStatus'];

                       bool matchesSearch = plate.contains(_searchQuery);
                       if (!matchesSearch) return false;

                       if (_showFailedPaymentsOnly) {
                         return paymentStatus == 'failed' || paymentStatus == 'error';
                       }
                       return true;
                    }).toList();

                    filteredDocs.sort((a, b) {
                      Timestamp t1 = a['startTime'];
                      Timestamp t2 = b['startTime'];
                      return t2.compareTo(t1); 
                    });

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_outlined, size: 60, color: Colors.grey[300]),
                            const SizedBox(height: 10),
                            Text(
                              _showFailedPaymentsOnly ? "Brak błędnych płatności" : "Parking jest pusty",
                              style: const TextStyle(color: Colors.grey)
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDocs.length,
                      itemBuilder: (ctx, i) {
                        final data = filteredDocs[i].data() as Map<String, dynamic>;
                        final sessionId = filteredDocs[i].id;
                        
                        final startTime = (data['startTime'] as Timestamp).toDate();
                        final plate = data['licensePlate'] ?? "???";
                        final paymentStatus = data['paymentStatus'];
                        
                        final duration = DateTime.now().difference(startTime);
                        final h = duration.inHours;
                        final m = duration.inMinutes % 60;

                        bool isError = paymentStatus == 'failed' || paymentStatus == 'error';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: isError ? 4 : 1, 
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isError ? const BorderSide(color: Colors.red, width: 1.5) : BorderSide.none
                          ),
                          color: isError ? Colors.red.shade50 : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: isError ? Colors.red.shade100 : Colors.blue.shade100,
                              child: Icon(
                                isError ? Icons.priority_high : Icons.directions_car, 
                                color: isError ? Colors.red : Colors.blue
                              ),
                            ),
                            title: Text(plate, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (isError) 
                                  const Text("⚠️ ODRZUCONA PŁATNOŚĆ ONLINE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                                Text("Czas: ${h}h ${m}m   •   Start: ${DateFormat('HH:mm').format(startTime)}"),
                              ],
                            ),
                            
                            // MENU 3 KROPEK
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'settle') {
                                  _handleSettleRequest(sessionId, data);
                                }
                                if (value == 'remove') {
                                  _removeSession(sessionId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'settle',
                                  child: Row(children: [
                                    Icon(Icons.monetization_on, color: Colors.green), 
                                    SizedBox(width: 10), 
                                    Text("Rozlicz (Gotówka)")
                                  ]),
                                ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Row(children: [
                                    Icon(Icons.delete_outline, color: Colors.red), 
                                    SizedBox(width: 10), 
                                    Text("Usuń z listy")
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}