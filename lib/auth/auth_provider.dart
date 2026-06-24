import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthProviderMethod extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  AuthProviderMethod() {
    _auth.authStateChanges().listen((User? user) {
      this.user = user;
      notifyListeners();
    });
  }

  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.get('role') as String;
      }
      return 'passenger';
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      return 'passenger';
    }
  }

  Future<String?> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred.';
    }
  }


  Future<String> signUpWithEmailAndPassword(
      String name, String email, String password, String phone, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? firebaseUser = result.user;

      if (firebaseUser == null) {
        return "Authentication process failed. Please try again.";
      }

      await firebaseUser.updateDisplayName(name);
      await firebaseUser.reload();

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'name': name,
        'email': email.toLowerCase().trim(),
        'phone': phone.trim(),
        'role': role.toLowerCase().trim(),
        //'isVerified': role.toLowerCase() == 'passenger' ? true : false,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } on FirebaseException catch (e) {
      return e.message ?? "A database sync error occurred.";
    } catch (e) {
      return "Registration failed: ${e.toString()}";
    }
  }

  // SIGN OUT
  Future<void> signOut() async {
    await _auth.signOut();
    user = null;
    notifyListeners();
  }
}