import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  String getCurrentMonthPK() {
    final nowUtc = DateTime.now().toUtc();
    final pkTime = nowUtc.add(const Duration(hours: 5));
    return '${pkTime.year}-${pkTime.month.toString().padLeft(2, '0')}';
  }

  String getNextMonthPK() {
    final nowUtc = DateTime.now().toUtc();
    final pkTime = nowUtc.add(const Duration(hours: 5));
    final nextMonth = DateTime(pkTime.year, pkTime.month + 1);
    return '${nextMonth.year}-${nextMonth.month.toString().padLeft(2, '0')}';
  }

  Future<void> markMonthPaid(String month, String docId, BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('students').doc(docId).update({
        'lastPaidMonth': month,
        'lastPaidTimestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked paid for $month')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Student Detail'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('students').doc(studentId).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Student not found', style: TextStyle(color: Colors.white)));
              }

              final student = snapshot.data!.data() as Map<String, dynamic>;
              final name = student['name'] ?? 'Unnamed';
              final course = student['course'] ?? 'Unknown';
              final joined = (student['createdAt'] as Timestamp?)?.toDate();
              final lastPaidMonth = student['lastPaidMonth'] ?? 'None';
              final lastPaidDate = (student['lastPaidTimestamp'] as Timestamp?)?.toDate();
              final isCurrentMonthPaid = lastPaidMonth == getCurrentMonthPK();
              final nextMonth = getNextMonthPK();

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: $name', style: const TextStyle(color: Colors.white, fontSize: 18)),
                            Text('Course: $course', style: const TextStyle(color: Colors.white70)),
                            if (joined != null)
                              Text('Joined: ${joined.toLocal().toString().split(" ")[0]}', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 12),
                            Text('Last Paid Month: $lastPaidMonth', style: const TextStyle(color: Colors.white)),
                            if (lastPaidDate != null)
                              Text('Last Paid On: ${lastPaidDate.toLocal()}', style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: isCurrentMonthPaid ? null : () => markMonthPaid(getCurrentMonthPK(), studentId, context),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  child: const Text("Mark Current Month Paid"),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => markMonthPaid(nextMonth, studentId, context),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                                  child: Text("Mark $nextMonth Paid"),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}