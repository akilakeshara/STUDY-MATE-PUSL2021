import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<DocumentSnapshot> getUserData() async {
    User? user = _auth.currentUser;
    return await _firestore.collection('users').doc(user!.uid).get();
  }

  
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
