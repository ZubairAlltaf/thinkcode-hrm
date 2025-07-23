import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:thinkcode/widgets/custom_snackbar.dart';
import 'package:intl/intl.dart';

class MarkStudentPaidProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String? _selectedCourse;
  String? _selectedBatch;
  String _sortBy = 'name';
  List<String> _selectedStudentIds = [];

  String get searchQuery => _searchQuery;
  String? get selectedCourse => _selectedCourse;
  String? get selectedBatch => _selectedBatch;
  String get sortBy => _sortBy;
  List<String> get selectedStudentIds => _selectedStudentIds;

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  void setSelectedCourse(String? course) {
    _selectedCourse = course;
    _selectedBatch = null;
    notifyListeners();
  }

  void setSelectedBatch(String? batch) {
    _selectedBatch = batch;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    notifyListeners();
  }

  void toggleStudentSelection(String studentId) {
    if (_selectedStudentIds.contains(studentId)) {
      _selectedStudentIds.remove(studentId);
    } else {
      _selectedStudentIds.add(studentId);
    }
    notifyListeners();
  }

  String getCurrentMonthPK() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5));
    return DateFormat('yyyy-MM').format(now);
  }

  List<String> getUpcomingMonths() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 5));
    final months = <String>[];
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month + i, 1);
      months.add(DateFormat('yyyy-MM').format(date));
    }
    return months;
  }

  Future<List<String>> getCourses() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching courses: $e');
      return [];
    }
  }

  Future<List<String>> getBatchesForCourse(String? course) async {
    if (course == null) return [];
    try {
      final snapshot = await _firestore
          .collection('batches')
          .where('course', isEqualTo: course)
          .get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Error fetching batches: $e');
      return [];
    }
  }

  Future<String> getBatchName(String? batchId) async {
    if (batchId == null) return 'N/A';
    try {
      final doc = await _firestore.collection('batches').doc(batchId).get();
      return doc.exists ? doc['name'] as String : 'Unknown';
    } catch (e) {
      print('Error fetching batch name: $e');
      return 'Unknown';
    }
  }

  Future<void> markPaid(
      BuildContext context,
      String studentId,
      List<String> selectedMonths,
      double amount,
      String note,
      DateTime date,
      ) async {
    try {
      if (amount <= 0 || selectedMonths.isEmpty) {
        showGlassySnackBar(context, 'Invalid amount or no months selected');
        return;
      }

      final studentDoc = await _firestore.collection('students').doc(studentId).get();
      final studentFee = double.tryParse(studentDoc['fee']?.toString() ?? '0') ?? 0.0;
      if (studentFee <= 0) {
        showGlassySnackBar(context, 'Invalid student fee');
        return;
      }

      final payments = <String, Map<String, dynamic>>{};
      final existingPayments = studentDoc['monthlyPayments'] as Map<String, dynamic>? ?? {};
      for (var month in selectedMonths) {
        final currentPaid = (existingPayments[month]?['amount'] as num?)?.toDouble() ?? 0.0;
        payments[month] = {
          'amount': amount + currentPaid,
          'date': Timestamp.fromDate(date),
          'note': amount + currentPaid < studentFee ? (note.isEmpty ? 'Partial payment' : note) : note,
        };
      }

      if (payments.isNotEmpty) {
        await _firestore.collection('students').doc(studentId).update({
          'monthlyPayments': payments,
        });
        showGlassySnackBar(context, 'Payment marked successfully');
      } else {
        showGlassySnackBar(context, 'No valid payments to record');
      }
    } catch (e) {
      showGlassySnackBar(context, 'Failed to mark payment: $e');
    }
  }

  Future<void> updatePayments(
      BuildContext context,
      String studentId,
      Map<String, Map<String, dynamic>> payments,
      ) async {
    try {
      if (payments.isEmpty) {
        showGlassySnackBar(context, 'No payments to update');
        return;
      }
      await _firestore.collection('students').doc(studentId).update({
        'monthlyPayments': payments,
      });
      showGlassySnackBar(context, 'Payments updated successfully');
    } catch (e) {
      showGlassySnackBar(context, 'Failed to update payments: $e');
    }
  }

  Future<void> markBulkPaid(
      BuildContext context,
      List<String> studentIds,
      List<String> selectedMonths,
      double amount,
      String note,
      DateTime date,
      ) async {
    try {
      if (amount <= 0 || selectedMonths.isEmpty || studentIds.isEmpty) {
        showGlassySnackBar(context, 'Invalid amount, months, or students selected');
        return;
      }

      for (var studentId in studentIds) {
        final studentDoc = await _firestore.collection('students').doc(studentId).get();
        if (!studentDoc.exists) continue;
        final studentFee = double.tryParse(studentDoc['fee']?.toString() ?? '0') ?? 0.0;
        if (studentFee <= 0) continue;

        final payments = <String, Map<String, dynamic>>{};
        double remainingAmount = amount;
        for (var month in selectedMonths) {
          final existingPayment = await getExistingPayment(studentId, month);
          final currentPaid = existingPayment?['amount']?.toDouble() ?? 0.0;
          final amountToAssign = (remainingAmount + currentPaid) >= studentFee ? studentFee - currentPaid : remainingAmount;
          if (amountToAssign <= 0) continue;

          payments[month] = {
            'amount': amountToAssign + currentPaid,
            'date': Timestamp.fromDate(date),
            'note': amountToAssign + currentPaid < studentFee ? (note.isEmpty ? 'Partial payment' : note) : note,
          };
          remainingAmount -= amountToAssign;
          if (remainingAmount <= 0) break;
        }

        if (payments.isNotEmpty) {
          await _firestore.collection('students').doc(studentId).update({
            'monthlyPayments': payments,
          });
        }
      }
      showGlassySnackBar(context, 'Bulk payment marked successfully');
    } catch (e) {
      showGlassySnackBar(context, 'Failed to mark bulk payment: $e');
    }
  }

  Future<void> markUnpaid(BuildContext context, String studentId, String month) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'monthlyPayments.$month': FieldValue.delete(),
      });
      showGlassySnackBar(context, 'Payment unmarked successfully');
    } catch (e) {
      showGlassySnackBar(context, 'Failed to unmark payment: $e');
    }
  }

  Future<Map<String, dynamic>?> getExistingPayment(String studentId, String month) async {
    final doc = await _firestore.collection('students').doc(studentId).get();
    final payments = doc.data()?['monthlyPayments'] as Map<String, dynamic>? ?? {};
    return payments[month] as Map<String, dynamic>?;
  }
}