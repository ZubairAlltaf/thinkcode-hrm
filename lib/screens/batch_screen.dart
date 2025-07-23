import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/batch_provider.dart';
import 'package:thinkcode/provider/subject_provider.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

class BatchScreen extends StatefulWidget {
  const BatchScreen({super.key});

  @override
  State<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends State<BatchScreen> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _amountController = TextEditingController();

  String? _selectedSubject;
  String? _selectedStatus = 'ongoing';
  DateTime? _selectedValidityDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
    });
  }

  bool get _isFormValid {
    return _selectedSubject != null &&
        _nameController.text.trim().isNotEmpty &&
        _numberController.text.trim().isNotEmpty &&
        _amountController.text.trim().isNotEmpty;
  }

  void _submit() {
    final name = _nameController.text.trim();
    final number = _numberController.text.trim();
    final amount = _amountController.text.trim();

    if (!_isFormValid) {
      _showGlassySnackBar("All required fields must be filled.");
      return;
    }

    Provider.of<BatchProvider>(context, listen: false).createBatch(
      name: name,
      number: number,
      validity: _selectedValidityDate?.toIso8601String(),
      subject: _selectedSubject!,
      courseAmount: amount,
      status: _selectedStatus!,
    );

    _nameController.clear();
    _numberController.clear();
    _amountController.clear();
    setState(() {
      _selectedSubject = null;
      _selectedValidityDate = null;
      _selectedStatus = 'ongoing';
    });

    _showGlassySnackBar("Batch created successfully.");
  }

  void _showGlassySnackBar(String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80,
        left: 20,
        right: 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final subjects = subjectProvider.subjects;
    final isLoading = subjectProvider.isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Create Batch'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.pushNamed(context, '/subjects'),
          )
        ],
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
          Positioned(
            top: -40,
            left: -30,
            child: GlowCircle(size: 150),
          ),
          const Positioned(
            bottom: -40,
            right: -30,
            child: GlowCircle(size: 120),
          ),
          Align(
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : subjects.isEmpty
                      ? _buildNoSubjectsUI()
                      : _buildFormUI(subjects),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSubjectsUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.info_outline, size: 50, color: Colors.blueGrey),
        const SizedBox(height: 10),
        const Text("No subjects found.", style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/subjects'),
          icon: const Icon(Icons.add),
          label: const Text("Add Subject"),
        )
      ],
    );
  }

  Widget _buildFormUI(List<String> subjects) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedSubject,
            items: subjects.map((s) {
              return DropdownMenuItem(value: s, child: Text(s));
            }).toList(),
            decoration: _inputDecoration('Select Subject'),
            onChanged: (val) => setState(() => _selectedSubject = val),
          ),
          const SizedBox(height: 16),
          _customInputField(_nameController, 'Batch Name'),
          const SizedBox(height: 12),
          _customInputField(_numberController, 'Batch Number', keyboard: TextInputType.number),
          const SizedBox(height: 12),

          // Date picker field
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: now,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now.add(const Duration(days: 365 * 5)),
              );
              if (picked != null) {
                setState(() => _selectedValidityDate = picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                _selectedValidityDate != null
                    ? 'Valid Until: ${_selectedValidityDate!.toLocal().toString().split(' ')[0]}'
                    : 'Select Validity Date (Optional)',
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _customInputField(_amountController, 'Course Amount per Month', keyboard: TextInputType.number),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _selectedStatus,
            items: ['ongoing', 'completed']
                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                .toList(),
            decoration: _inputDecoration('Batch Status'),
            onChanged: (val) => setState(() => _selectedStatus = val),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _isFormValid ? _submit : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isFormValid ? 1 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: _isFormValid
                      ? const LinearGradient(
                    colors: [Color(0xFF90CAF9), Color(0xFFBBDEFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : const LinearGradient(colors: [Colors.grey, Colors.grey]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text(
                    'Create Batch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _customInputField(TextEditingController controller, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(label),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      fillColor: Colors.white.withOpacity(0.6),
      filled: true,
    );
  }
}
