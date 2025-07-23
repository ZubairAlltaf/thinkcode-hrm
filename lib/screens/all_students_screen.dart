import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:thinkcode/screens/edit_user_profile_screen.dart';

class AllStudentsScreen extends StatelessWidget {
  const AllStudentsScreen({super.key});

  Future<String> getBatchName(String batchId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('batches').doc(batchId).get();
      if (doc.exists) {
        return "${doc['name']} (No. ${doc['number']})";
      } else {
        return 'Batch not found';
      }
    } catch (e) {
      print('Error fetching batch $batchId: $e');
      return 'Error fetching batch';
    }
  }

  Future<void> updateStatus(String studentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .update({'status': newStatus});
      print('Status updated for student $studentId: $newStatus');
    } catch (e) {
      print('Error updating status for student $studentId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('All Students'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF134E5E),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                  Color(0xFF71B280),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Students List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No students found.", style: TextStyle(color: Colors.white)),
                );
              }

              final students = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final name = student['name']?.toString() ?? 'N/A';
                  final parentName = student['parentName']?.toString() ?? 'N/A';
                  final course = student['course']?.toString() ?? 'N/A';
                  final contact = student['contact']?.toString() ?? 'N/A';
                  final fatherContact = student['fatherContact']?.toString() ?? 'N/A';
                  final email = student['email']?.toString() ?? 'N/A';
                  final nic = student['nic']?.toString() ?? 'N/A';
                  final currentAddress = student['currentAddress']?.toString() ?? 'N/A';
                  final homeAddress = student['homeAddress']?.toString() ?? 'N/A';
                  final imageUrl = student['imageurl']?.toString();
                  final Timestamp? createdAt = student['createdAt'] as Timestamp?;
                  final fee = student['fee']?.toString() ?? 'N/A';
                  final batchId = student['batchId']?.toString();
                  final studentId = student.id;
                  final status = student['status']?.toString() ?? 'unknown';

                  return FutureBuilder<String>(
                    future: batchId != null ? getBatchName(batchId) : Future.value('N/A'),
                    builder: (context, batchSnapshot) {
                      final batchName = batchSnapshot.data ?? 'Loading...';

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: ExpansionTile(
                              collapsedIconColor: Colors.white70,
                              iconColor: Colors.white,
                              title: ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.lightBlue.shade100,
                                  backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl == null || imageUrl.isEmpty
                                      ? Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.black),
                                  )
                                      : null,
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      backgroundColor: _getStatusColor(status),
                                    ),
                                  ],
                                ),
                                subtitle: Text(
                                  "Guardian: $parentName",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _infoRow("Course", course),
                                      _infoRow("Batch", batchName),
                                      _infoRow("Email", email),
                                      _infoRow("NIC", nic),
                                      _infoRow("Student Contact", contact),
                                      _infoRow("Guardian Contact", fatherContact),
                                      _infoRow("Current Address", currentAddress),
                                      _infoRow("Home Address", homeAddress),
                                      _infoRow("Joining Date", createdAt != null ? _formatDate(createdAt) : 'N/A'),
                                      _infoRow("Fee", fee),
                                      const SizedBox(height: 10),
                                      _statusDropdown(studentId, status),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditUserProfileScreen(userId: studentId),
                                              ),
                                            );
                                          },
                                          child: const Text("Edit Info", style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        "$label: $value",
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _statusDropdown(String studentId, String currentStatus) {
    final statuses = ['ongoing', 'completed', 'left', 'removed'];

    return Row(
      children: [
        const Text("Change Status: ", style: TextStyle(color: Colors.white70)),
        const SizedBox(width: 10),
        DropdownButton<String>(
          value: currentStatus,
          dropdownColor: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(color: Colors.white),
          items: statuses
              .map((status) => DropdownMenuItem(
            value: status,
            child: Text(status.toUpperCase()),
          ))
              .toList(),
          onChanged: (newStatus) {
            if (newStatus != null && newStatus != currentStatus) {
              updateStatus(studentId, newStatus);
            }
          },
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ongoing':
        return Colors.green.withOpacity(0.7);
      case 'completed':
        return Colors.green.withOpacity(0.7);
      case 'left':
        return Colors.orange.withOpacity(0.7);
      case 'removed':
        return Colors.red.withOpacity(0.7);
      default:
        return Colors.grey.withOpacity(0.6);
    }
  }
}