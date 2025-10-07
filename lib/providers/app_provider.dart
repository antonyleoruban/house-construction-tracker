import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  double totalGeneralExpense = 0.0;
  double totalBuildExpense = 0.0;
  double totalLoan = 0.0;

  Future<void> fetchTotals() async {
    var expensesSnapshot = await firestore.collection('expenses').get();
    totalGeneralExpense = expensesSnapshot.docs
        .where((doc) {
          final data = doc.data();
          return data['expenseType'] == 'general' || data['expenseType'] == null;
        })
        .fold(0.0, (total, doc) => total + (doc['totalAmount'] ?? 0));

    totalBuildExpense = expensesSnapshot.docs
        .where((doc) => doc.data()['expenseType'] == 'building')
        .fold(0.0, (total, doc) => total + (doc['totalAmount'] ?? 0));

    var loansSnapshot = await firestore.collection('loans').get();
    totalLoan = loansSnapshot.docs.fold(0.0, (total, doc) => total + (doc['loanAmount'] ?? 0));

    notifyListeners();
  }



  Future<void> addExpense(Map<String, dynamic> data) async {
    await firestore.collection('expenses').add(data);
    await fetchTotals();
  }

  Future<void> updateExpense(String expenseId, Map<String, dynamic> data) async {
    await firestore.collection('expenses').doc(expenseId).update(data);
    await fetchTotals(); // Refresh totals if required
  }

  Future<void> addLoan(Map<String, dynamic> data) async {
    await firestore.collection('loans').add(data);
    await fetchTotals();
  }

  Future<List<Map<String, dynamic>>> getExpenses1() async {
    var snapshot = await firestore.collection('expenses').get();
    return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
  }

  Future<List<Map<String, dynamic>>> getExpenses({
    bool sortByDate = false,
    bool descending = true,
    String? expenseType,
  }) async {
    var snapshot = await firestore.collection('expenses').get();

    var expenses = snapshot.docs
        .map((doc) => {
              ...doc.data() as Map<String, dynamic>,
              'id': doc.id,
            })
        .toList();

    if (expenseType != null) {
      expenses = expenses.where((expense) {
        if (expenseType == 'general') {
          return expense['expenseType'] == 'general' || expense['expenseType'] == null;
        } else {
          return expense['expenseType'] == expenseType;
        }
      }).toList();
    }

    if (sortByDate) {
      expenses.sort((a, b) {
        final dateA = a['date'];
        final dateB = b['date'];

        // If Firestore stores dates as Timestamp
        if (dateA is Timestamp && dateB is Timestamp) {
          return descending ? dateB.toDate().compareTo(dateA.toDate()) : dateA.toDate().compareTo(dateB.toDate());
        }

        // If stored as String (e.g. "2025-08-24")
        if (dateA is String && dateB is String) {
          final parsedA = DateTime.tryParse(dateA) ?? DateTime(1970);
          final parsedB = DateTime.tryParse(dateB) ?? DateTime(1970);
          return descending ? parsedB.compareTo(parsedA) : parsedA.compareTo(parsedB);
        }

        return 0;
      });
    }

    return expenses;
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
