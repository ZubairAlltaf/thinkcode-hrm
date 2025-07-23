import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentProvider with ChangeNotifier {
  int _paidCount = 0;
  int _unpaidCount = 0;
  bool _isSubmitting = false;

  int get paidCount => _paidCount;
  int get unpaidCount => _unpaidCount;
  bool get isSubmitting => _isSubmitting;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getCurrentMonthPK() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5));
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<void> addStudent(Map<String, dynamic> data) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _firestore.collection('students').add(data);
      await fetchFeeStats();
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> fetchFeeStats() async {
    try {
      final snapshot = await _firestore.collection('students').where('status', isEqualTo: 'ongoing').get();
      final currentMonth = _getCurrentMonthPK();
      int paid = 0;
      int unpaid = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final payments = data['monthlyPayments'] as Map<String, dynamic>? ?? {};
        if (payments.containsKey(currentMonth)) {
          paid++;
        } else {
          unpaid++;
        }
      }

      _paidCount = paid;
      _unpaidCount = unpaid;
      notifyListeners();
    } catch (e) {
      print('Error fetching fee stats: $e');
    }
  }
}