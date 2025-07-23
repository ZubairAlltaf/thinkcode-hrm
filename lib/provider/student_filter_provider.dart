import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentFilterProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _courses = [];
  List<DocumentSnapshot> _batches = [];
  String? _selectedCourse;
  String? _selectedBatch;
  bool _isLoading = false;

  List<String> get courses => _courses;
  List<DocumentSnapshot> get batches => _batches;
  String? get selectedCourse => _selectedCourse;
  String? get selectedBatch => _selectedBatch;
  bool get isLoading => _isLoading;

  StudentFilterProvider() {
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('subjects').get();
      _courses = snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching courses: $e');
      _courses = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchBatchesForCourse(String? course) async {
    if (course == null) {
      _batches = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('batches')
          .where('subject', isEqualTo: course)
          .where('status', isEqualTo: 'ongoing')
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

  void setSelectedCourse(String? course) {
    _selectedCourse = course;
    _selectedBatch = null;
    fetchBatchesForCourse(course);
    notifyListeners();
  }

  void setSelectedBatch(String? batchId) {
    _selectedBatch = batchId;
    notifyListeners();
  }

  Stream<QuerySnapshot> getFilteredStudentsStream() {
    Query<Map<String, dynamic>> query = _firestore
        .collection('students')
        .where('status', isEqualTo: 'ongoing');

    if (_selectedCourse != null) {
      query = query.where('course', isEqualTo: _selectedCourse);
    }

    if (_selectedBatch != null) {
      query = query.where('batchId', isEqualTo: _selectedBatch);
    }

    return query.snapshots();
  }

  String getBatchName(DocumentSnapshot? batch) {
    if (batch == null) return 'Unknown';
    final data = batch.data() as Map<String, dynamic>?;
    return data?['name']?.toString() ?? 'Unknown';
  }
}