import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/batch_provider.dart';
import 'package:thinkcode/provider/subject_provider.dart';
import 'package:thinkcode/provider/student_provider.dart';
import 'package:thinkcode/widgets/custom_snackbar.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _contactController = TextEditingController();
  final _fatherContactController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _feeControler = TextEditingController();

  String? _selectedCourse;
  DocumentSnapshot? _selectedBatch;
  String? _selectedBatchFee;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
      final batchProvider = Provider.of<BatchProvider>(context, listen: false);
      await subjectProvider.fetchSubjects();
      await batchProvider.fetchBatches();
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCourse == null || _selectedBatch == null) return;

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);

    final studentData = {
      'name': _nameController.text.trim(),
      'parentName': _parentNameController.text.trim(),
      'nic': _nicController.text.trim(),
      'contact': _contactController.text.trim(),
      'fatherContact': _fatherContactController.text.trim(),
      'email': _emailController.text.trim(),
      'currentAddress': _currentAddressController.text.trim(),
      'homeAddress': _homeAddressController.text.trim(),
      'course': _selectedCourse,
      'batchId': _selectedBatch!.id,
      'status': 'ongoing',
      'createdAt': Timestamp.now(),
      'imageurl': '',
      'fee': _feeControler.text.trim(),
    };

    try {
      await studentProvider.addStudent(studentData);
      if (mounted) {
        showGlassySnackBar(context, 'Student added successfully');
        _formKey.currentState!.reset();
        _clearControllers();
        setState(() {
          _selectedCourse = null;
          _selectedBatch = null;
          _selectedBatchFee = null;
        });
      }
    } catch (e) {
      if (mounted) showGlassySnackBar(context, 'Error: $e');
    }
  }

  void _clearControllers() {
    _nameController.clear();
    _parentNameController.clear();
    _nicController.clear();
    _contactController.clear();
    _fatherContactController.clear();
    _emailController.clear();
    _currentAddressController.clear();
    _homeAddressController.clear();
    _feeControler.clear();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label, {
        bool isEmail = false,
        bool isPhone = false,
        bool isNic = false,
        bool isNumber = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : isPhone || isNic || isNumber
            ? TextInputType.number
            : TextInputType.text,
        inputFormatters: isPhone || isNic
            ? [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(isNic ? 13 : 11),
        ]
            : isNumber
            ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
            : null,
        validator: (val) {
          if (val == null || val.trim().isEmpty) return 'Required';
          if (isEmail &&
              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
            return 'Invalid email';
          }
          if (isPhone && val.length != 11) return 'Must be 11 digits';
          if (isNic && val.length != 13) return 'NIC must be 13 digits';
          return null;
        },
        decoration: _inputDecoration(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final batchProvider = Provider.of<BatchProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);

    final availableBatches = _selectedCourse != null
        ? batchProvider.getOngoingBatchesBySubject(_selectedCourse!)
        : <DocumentSnapshot>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Add Student'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: 600,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(_nameController, 'Student Name'),
                          _buildField(_parentNameController, "Parent's Name"),
                          _buildField(_nicController, 'NIC / Birth Certificate No', isNic: true),
                          _buildField(_contactController, 'Student Contact Number', isPhone: true),
                          _buildField(_fatherContactController, 'Parent Contact Number', isPhone: true),
                          _buildField(_emailController, 'Email Address', isEmail: true),
                          _buildField(_currentAddressController, 'Current Address'),
                          _buildField(_homeAddressController, 'Home Address'),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedCourse,
                            decoration: _inputDecoration('Select Course'),
                            dropdownColor: Colors.black87,
                            style: const TextStyle(color: Colors.white),
                            items: subjectProvider.subjects
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCourse = val;
                                _selectedBatch = null;
                                _selectedBatchFee = null;
                                _feeControler.clear();
                              });
                            },
                            validator: (val) => val == null ? 'Select a course' : null,
                          ),
                          const SizedBox(height: 12),
                          if (_selectedCourse != null)
                            availableBatches.isNotEmpty
                                ? DropdownButtonFormField<DocumentSnapshot>(
                              value: _selectedBatch,
                              decoration: _inputDecoration('Select Batch'),
                              dropdownColor: Colors.black87,
                              style: const TextStyle(color: Colors.white),
                              items: availableBatches.map((doc) {
                                return DropdownMenuItem(
                                  value: doc,
                                  child: Text('${doc['name']} (Batch ${doc['number']})'),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedBatch = val;
                                  _selectedBatchFee = val?['courseAmount']?.toString();
                                  _feeControler.text = _selectedBatchFee ?? '';
                                });
                              },
                              validator: (val) => val == null ? 'Select a batch' : null,
                            )
                                : const Text("No ongoing batches for this course", style: TextStyle(color: Colors.white)),
                          if (_selectedBatchFee != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                "Batch Course Fee: PKR $_selectedBatchFee",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          _buildField(_feeControler, 'Fee', isNumber: true),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: studentProvider.isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black.withOpacity(0.7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: studentProvider.isSubmitting
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                                : const Text('Add Student'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
