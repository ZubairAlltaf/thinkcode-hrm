import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:thinkcode/provider/batch_provider.dart';
import 'package:thinkcode/provider/subject_provider.dart';

class ManageBatchProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BatchProvider _batchProvider;
  final SubjectProvider _subjectProvider;

  ManageBatchProvider({required BatchProvider batchProvider, required SubjectProvider subjectProvider})
      : _batchProvider = batchProvider,
        _subjectProvider = subjectProvider;

  Future<void> deleteBatch(String batchId) async {
    try {
      await _batchProvider.deleteBatch(batchId);
    } catch (e) {
      print('Error deleting batch: $e');
    }
  }

  Future<void> deleteSubject(String subjectName) async {
    try {
      await _subjectProvider.deleteSubject(subjectName);
    } catch (e) {
      print('Error deleting subject: $e');
    }
  }
}