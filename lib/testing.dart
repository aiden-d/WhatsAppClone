import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;
void main() async {
  print('test');
  final _auth = FirebaseAuth.instance;
  await _auth.signInWithEmailAndPassword(
      email: 'aidendawes@gmail.com', password: '31bextonlane');
  print(loggedInUser);
  //_firestore.collection('messages').document('abcdefg');
}
