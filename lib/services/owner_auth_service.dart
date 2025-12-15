// lib/services/owner_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/owner_model.dart';

class OwnerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Rejestracja Właściciela
  Future<void> registerOwner({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    try {
      // 1. Tworzymy konto w Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2. Tworzymy model właściciela (bez Stripe, bez isOwner)
        final newOwner = OwnerModel(
          uid: user.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
        );

        // 3. Zapisujemy do kolekcji 'owners' (ZMIANA KOLEKCJI)
        await _db.collection('owners').doc(user.uid).set(newOwner.toFirestore());
      }
    } catch (e) {
      rethrow; // Rzucamy błąd dalej, żeby ekran mógł go wyświetlić
    }
  }

  // Logowanie Właściciela
  Future<OwnerModel?> signInOwner(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      if (user != null) {
        // Sprawdzamy, czy ten użytkownik jest w kolekcji 'owners'
        DocumentSnapshot doc = await _db.collection('owners').doc(user.uid).get();
        
        if (doc.exists) {
          return OwnerModel.fromFirestore(doc.data() as Map<String, dynamic>);
        } else {
          // Jeśli zalogował się, ale nie ma go w 'owners' (np. jest klientem), wyloguj go
          await _auth.signOut();
          throw FirebaseAuthException(code: 'not-owner', message: 'To konto nie ma uprawnień właściciela.');
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
}