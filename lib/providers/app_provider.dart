import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  double totalExpense = 0.0;
  double totalLoan = 0.0;

  Future<void> fetchTotals() async {
    var expensesSnapshot = await firestore.collection('expenses').get();
    totalExpense = expensesSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc['totalAmount'] ?? 0));

    var loansSnapshot = await firestore.collection('loans').get();
    totalLoan = loansSnapshot.docs.fold(0.0, (sum, doc) => sum + (doc['loanAmount'] ?? 0));

    notifyListeners();
  }

  Future<void> addExpense(Map<String, dynamic> data) async {
    await firestore.collection('expenses').add(data);
    await fetchTotals();
  }

  Future<void> updateExpense(String expenseId, Map<String, dynamic> data) async {
    await firestore.collection('expenses').doc(expenseId).update(data);
    await fetchTotals();  // Refresh totals if required
  }


  Future<void> addLoan(Map<String, dynamic> data) async {
    await firestore.collection('loans').add(data);
    await fetchTotals();
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    var snapshot = await firestore.collection('expenses').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> getLoans() async {
    var snapshot = await firestore.collection('loans').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> getImages() async {
    var snapshot = await firestore.collection('construction_images').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<void> uploadImage(String name, String filePath) async {
    var ref = _storage.ref().child('construction_images/$name.jpg');
    await ref.putFile(File(filePath));
    String downloadUrl = await ref.getDownloadURL();

    await firestore.collection('constructionImages').add({
      'name': name,
      'url': downloadUrl,
      'uploadedAt': Timestamp.now(),
    });

    notifyListeners();
  }
}
