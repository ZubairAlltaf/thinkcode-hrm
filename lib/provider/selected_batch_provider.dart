import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectedBatchProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, List<DocumentSnapshot<Object?>>> _batchesPerSubject = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<DocumentSnapshot<Object?>> getBatchesForSubject(String subject) {
    return _batchesPerSubject[subject] ?? [];
  }

  Future<void> fetchOngoingBatchesForSubject(String subject) async {
    _isLoading = true;
    notifyListeners();

    final snapshot = await _firestore
        .collection('batches')
        .where('subject', isEqualTo: subject)
        .where('status', isEqualTo: 'ongoing')
        .orderBy('createdAt', descending: true)
        .get();

    _batchesPerSubject[subject] = snapshot.docs;

    _isLoading = false;
    notifyListeners();
  }
}
