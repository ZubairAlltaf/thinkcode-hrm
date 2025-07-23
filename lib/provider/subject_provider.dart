import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SubjectProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _subjects = [];
  bool _isLoading = false;

  List<String> get subjects => _subjects;
  bool get isLoading => _isLoading;

  Future<void> fetchSubjects() async {
    _isLoading = true;
    notifyListeners();

    final snapshot = await _firestore.collection('subjects').get();
    _subjects = snapshot.docs.map((doc) => doc['name'] as String).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addSubject(String name) async {
    if (name.isEmpty) return;
    await _firestore.collection('subjects').add({
      'name': name,
      'createdAt': Timestamp.now(),
    });
    await fetchSubjects();
  }

  Future<void> deleteSubject(String name) async {
    try {
      final querySnapshot = await _firestore
          .collection('subjects')
          .where('name', isEqualTo: name)
          .get();
      for (var doc in querySnapshot.docs) {
        await _firestore.collection('subjects').doc(doc.id).delete();
      }
      await fetchSubjects();
    } catch (e) {
      print('Error deleting subject: $e');
    }
  }
}