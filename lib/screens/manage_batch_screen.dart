import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/batch_provider.dart';
import 'package:thinkcode/provider/subject_provider.dart';
import 'package:thinkcode/provider/manage_batch_provider.dart';
import 'package:thinkcode/widgets/custom_snackbar.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

class ManageBatchScreen extends StatefulWidget {
  const ManageBatchScreen({super.key});

  @override
  State<ManageBatchScreen> createState() => _ManageBatchScreenState();
}

class _ManageBatchScreenState extends State<ManageBatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BatchProvider>(context, listen: false).fetchBatches();
      Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
    });
  }

  Future<void> _showEditBatchDialog(BuildContext context, String batchId, String name, String number, String? validity, String subject, String courseAmount, String status) async {
    final nameController = TextEditingController(text: name);
    final numberController = TextEditingController(text: number);
    final validityController = TextEditingController(text: validity ?? '');
    final subjectController = TextEditingController(text: subject);
    final courseAmountController = TextEditingController(text: courseAmount);
    String? selectedStatus = status;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900]!.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Batch', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Batch Number',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: validityController,
                  decoration: const InputDecoration(
                    labelText: 'Validity (optional)',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: courseAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Course Amount',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButton<String>(
                  value: selectedStatus,
                  items: ['ongoing', 'completed'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedStatus = newValue;
                    });
                  },
                  dropdownColor: Colors.grey[900],
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),

                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nameController.text.isNotEmpty && numberController.text.isNotEmpty && subjectController.text.isNotEmpty && courseAmountController.text.isNotEmpty && selectedStatus != null) {
                  Provider.of<BatchProvider>(context, listen: false).updateBatch(
                    batchId,
                    name: nameController.text,
                    number: numberController.text,
                    validity: validityController.text.isEmpty ? null : validityController.text,
                    subject: subjectController.text,
                    courseAmount: courseAmountController.text,
                    status: selectedStatus!,
                  );
                  final messengerContext = context;
                  Navigator.pop(context);
                  showGlassySnackBar(messengerContext, 'Batch updated successfully');


                } else {
                  showGlassySnackBar(context, 'Please fill all required fields');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteBatch(BuildContext context, String batchId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900]!.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this batch?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final manageBatchProvider = Provider.of<ManageBatchProvider>(context, listen: false);
              manageBatchProvider.deleteBatch(batchId);
              Navigator.pop(context);
              showGlassySnackBar(context, 'Batch deleted successfully');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, String subjectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900]!.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this subject?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final manageBatchProvider = Provider.of<ManageBatchProvider>(context, listen: false);
              manageBatchProvider.deleteSubject(subjectName);
              Navigator.pop(context);
              showGlassySnackBar(context, 'Subject deleted successfully');
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batchProvider = Provider.of<BatchProvider>(context);
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final manageBatchProvider = Provider.of<ManageBatchProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Batches'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
          const Positioned(top: -40, left: -30, child: GlowCircle(size: 150)),
          const Positioned(bottom: -40, right: -30, child: GlowCircle(size: 120)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: batchProvider.isLoading || subjectProvider.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
                  : batchProvider.batches.isEmpty
                  ? const Center(
                child: Text(
                  'No batches found',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: batchProvider.batches.length,
                itemBuilder: (context, index) {
                  final batch = batchProvider.batches[index];
                  final data = batch.data() as Map<String, dynamic>;
                  // Filter subjects by matching the batch's subject name
                  final relevantSubjects = subjectProvider.subjects
                      .where((subjectName) => subjectName == data['subject'])
                      .toList();
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: ExpansionTile(

                        title: Text(
                            data['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Number: ${data['number']} | Created: ${DateFormat('yyyy-MM-dd').format((data['createdAt'] as Timestamp).toDate())}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          children: [
                            if (relevantSubjects.isNotEmpty)
                              ...relevantSubjects.map((subjectName) => ListTile(
                                title: Text(
                                  subjectName,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _confirmDeleteSubject(context, subjectName),
                                ),
                              )),
                            if (relevantSubjects.isEmpty)
                              const ListTile(
                                title: Text('No subjects', style: TextStyle(color: Colors.white70)),
                              ),
                          ],
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.greenAccent),
                                onPressed: () => _showEditBatchDialog(
                                  context,
                                  batch.id,
                                  data['name'],
                                  data['number'],
                                  data['validity'],
                                  data['subject'],
                                  data['courseAmount'],
                                  data['status'],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _confirmDeleteBatch(context, batch.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}