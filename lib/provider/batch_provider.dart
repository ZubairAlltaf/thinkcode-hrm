import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BatchProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DocumentSnapshot> _batches = [];
  bool _isLoading = false;

  List<DocumentSnapshot> get batches => _batches;
  bool get isLoading => _isLoading;

  // Creating a new batch
  Future<void> createBatch({
    required String name,
    required String number,
    String? validity,
    required String subject,
    required String courseAmount,
    required String status,
  }) async {
    await _firestore.collection('batches').add({
      'name': name,
      'number': number,
      'validity': validity ?? '',
      'subject': subject,
      'courseAmount': courseAmount,
      'status': status,
      'createdAt': Timestamp.now(),
    });

    await fetchBatches();
  }

  // Fetching all the avaiable batches
  Future<void> fetchBatches() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('batches')
          .orderBy('createdAt', descending: true)
          .get();

      _batches = snapshot.docs;
    } catch (e) {
      print('Error fetching batches: $e');
      _batches = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Getting all batches for the subject
  List<DocumentSnapshot> getBatchesBySubject(String subject) {
    return _batches.where((batch) {
      final data = batch.data() as Map<String, dynamic>?;
      if (data == null) return false;
      return data['subject'] == subject;
    }).toList();
  }

  // Fetching only ongoing batches for a subject so that student will be added in only ongoing batch
  List<DocumentSnapshot> getOngoingBatchesBySubject(String subject) {
    return _batches.where((batch) {
      final data = batch.data() as Map<String, dynamic>?;
      if (data == null) return false;
      final subjectMatches = data['subject'] == subject;
      final isOngoing = data['status'] == 'ongoing';
      return subjectMatches && isOngoing;
    }).toList();
  }

  // updating the batch info
  Future<void> updateBatch(String batchId, {
    required String name,
    required String number,
    String? validity,
    required String subject,
    required String courseAmount,
    required String status,
  }) async {
    try {
      await _firestore.collection('batches').doc(batchId).update({
        'name': name,
        'number': number,
        'validity': validity ?? '',
        'subject': subject,
        'courseAmount': courseAmount,
        'status': status,
      });
      await fetchBatches();
    } catch (e) {
      print('Error updating batch: $e');
    }
  }

  // Deleting the batch for somereason
  Future<void> deleteBatch(String batchId) async {
    try {
      await _firestore.collection('batches').doc(batchId).delete();
      await fetchBatches();
    } catch (e) {
      print('Error deleting batch: $e');
    }
  }
}