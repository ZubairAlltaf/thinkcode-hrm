import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomeExpenseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _payments = [];
  String? _errorMessage;


  double get totalIncome => _totalIncome;
  double get totalExpenses => _totalExpenses;
  double get netProfit => _totalIncome - _totalExpenses;
  List<Map<String, dynamic>> get expenses => _expenses;
  List<Map<String, dynamic>> get payments => _payments;
  String? get errorMessage => _errorMessage;

  // Fetching income from student payments and expenses
  Future<void> fetchIncomeAndExpenses({DateTime? start, DateTime? end}) async {
    try {
      _errorMessage = null;

      // Default to current month if no date range
      final now = DateTime.now();
      start ??= DateTime(now.year, now.month, 1);
      end ??= DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);

      // Normalize start and end to start/end of day
      final startDate = DateTime(start.year, start.month, start.day);
      final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);

      // Log for the date range for debugging
      print('Fetching data for range: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}');

      // Fetching payments for income also printing in debug to check the errors if any occurs
      _totalIncome = 0.0;
      _payments = [];
      final studentSnapshot = await _firestore.collection('students').where('status', isEqualTo: 'ongoing').get();
      print('Found ${studentSnapshot.docs.length} ongoing students');
      for (var student in studentSnapshot.docs) {
        final data = student.data();
        final name = data['name']?.toString() ?? 'Unnamed';
        final payments = data['monthlyPayments'] as Map<String, dynamic>? ?? {};
        print('Student: $name, Payments: ${payments.length} months');
        payments.forEach((month, payment) {
          if (payment is Map && payment['date'] is Timestamp && payment['amount'] is num) {
            final paymentDate = (payment['date'] as Timestamp).toDate();
            final paymentDateOnly = DateTime(paymentDate.year, paymentDate.month, paymentDate.day);
            print('Payment for $month: ${payment['amount']} PKR on ${DateFormat('yyyy-MM-dd HH:mm:ss').format(paymentDate)}');


            if (!paymentDateOnly.isBefore(startDate) && !paymentDateOnly.isAfter(endDate)) {
              final amount = payment['amount'].toDouble();
              _totalIncome += amount;
              _payments.add({
                'studentName': name,
                'month': month,
                'amount': amount,
                'date': paymentDate,
                'note': payment['note']?.toString() ?? '',
              });
              print('Included payment for $month: $amount PKR');
            } else {
              print('Excluded payment for $month: Date ${DateFormat('yyyy-MM-dd').format(paymentDateOnly)} outside range');
            }
          } else {
            print('Invalid payment data for $month: $payment');
          }
        });
      }
      print('Total payments included: ${_payments.length}, Total Income: $_totalIncome');

      // Fetching expenses
      Query query = _firestore.collection('expenses');
      if (start != null && end != null) {
        query = query
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      final expenseSnapshot = await query.get();
      _expenses = expenseSnapshot.docs.map((doc) => {
        'id': doc.id,
        'title': doc['title']?.toString() ?? 'Unnamed',
        'amount': (doc['amount'] as num?)?.toDouble() ?? 0.0,
        'date': (doc['date'] as Timestamp?)?.toDate(),
      }).toList();
      _totalExpenses = _expenses.fold(0.0, (sum, e) => sum + (e['amount'] ?? 0.0));
      print('Total expenses: ${_expenses.length}, Total Expense Amount: $_totalExpenses');

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load data: $e';
      _totalIncome = 0.0;
      _totalExpenses = 0.0;
      _expenses = [];
      _payments = [];
      print('Error fetching data: $e');
      notifyListeners();
    }
  }

  // Adding the new expense
  Future<void> addExpense(String title, double amount, DateTime date) async {
    try {
      _errorMessage = null;
      final dateNormalized = DateTime(date.year, date.month, date.day);
      await _firestore.collection('expenses').add({
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(dateNormalized),
      });
      print('Added expense: $title, $amount PKR on ${DateFormat('yyyy-MM-dd').format(dateNormalized)}');
      await fetchIncomeAndExpenses(); // Refresh data
    } catch (e) {
      _errorMessage = 'Failed to add expense: $e';
      print('Error adding expense: $e');
      notifyListeners();
    }
  }
}