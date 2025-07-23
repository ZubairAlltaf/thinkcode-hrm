import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/subject_provider.dart';
import 'package:thinkcode/provider/selected_batch_provider.dart';
import 'package:thinkcode/widgets/custom_snackbar.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

class EditUserProfileScreen extends StatefulWidget {
  final String userId;
  const EditUserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _contactController = TextEditingController();
  final _fatherContactController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentAddressController = TextEditingController();
  final _homeAddressController = TextEditingController();
  final _feeController = TextEditingController();
  String? _selectedCourse;
  DocumentSnapshot<Object?>? _selectedBatch;
  String? _selectedStatus;
  Timestamp? _createdAt;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;
  bool _isLoading = true;
  String? _batchError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadUserInfo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parentNameController.dispose();
    _nicController.dispose();
    _contactController.dispose();
    _fatherContactController.dispose();
    _emailController.dispose();
    _currentAddressController.dispose();
    _homeAddressController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      print('Loading student data for userId: ${widget.userId}');
      final doc = await FirebaseFirestore.instance.collection('students').doc(widget.userId).get();
      if (!doc.exists) {
        print('Student document does not exist');
        if (mounted) {
          showGlassySnackBar(context, 'Student not found');
          Navigator.pop(context);
        }
        return;
      }

      final data = doc.data();
      if (data == null) {
        print('Student document data is null');
        if (mounted) {
          showGlassySnackBar(context, 'Failed to load student data');
          Navigator.pop(context);
        }
        return;
      }

      print('Student data: $data');


      final subjectProvider = Provider.of<SubjectProvider>(context, listen: false);
      await subjectProvider.fetchSubjects();
      final subjects = subjectProvider.subjects;
      if (subjects.isEmpty) {
        print('No subjects available');
        setState(() {
          _batchError = 'No subjects available; please add subjects first';
          _isLoading = false;
        });
        return;
      }


      DocumentSnapshot<Object?>? batchDoc;
      final batchId = data['batchId'] as String?;
      final course = data['course'] as String?;
      if (course != null && subjects.contains(course)) {
        print('Fetching batches for course: $course');
        final batchProvider = Provider.of<SelectedBatchProvider>(context, listen: false);
        await batchProvider.fetchOngoingBatchesForSubject(course);
        final availableBatches = batchProvider.getBatchesForSubject(course);
        print('Available batches: ${availableBatches.map((b) => b.id).toList()}');

        if (batchId != null && availableBatches.isNotEmpty) {
          batchDoc = availableBatches.firstWhere(
                (b) => b.id == batchId,
          );
          if (batchDoc == null) {
            print('Batch $batchId is not ongoing');
            _batchError = 'Current batch is not ongoing; please select a new batch';
          } else {
            print('Batch $batchId found in available batches');
          }
        } else if (batchId != null) {
          final batchSnapshot = await FirebaseFirestore.instance.collection('batches').doc(batchId).get();
          if (!batchSnapshot.exists) {
            print('Batch $batchId not found');
            _batchError = 'Current batch not found; please select a new batch';
          } else {
            print('Batch $batchId is not ongoing');
            _batchError = 'Current batch is not ongoing; please select a new batch';
          }
        }
      } else {
        print('No valid course found in student data: $course');
        _batchError = 'No valid course assigned; please select a course';
      }

      setState(() {
        _nameController.text = data['name']?.toString() ?? '';
        _parentNameController.text = data['parentName']?.toString() ?? '';
        _nicController.text = data['nic']?.toString() ?? '';
        _contactController.text = data['contact']?.toString() ?? '';
        _fatherContactController.text = data['fatherContact']?.toString() ?? '';
        _emailController.text = data['email']?.toString() ?? '';
        _currentAddressController.text = data['currentAddress']?.toString() ?? '';
        _homeAddressController.text = data['homeAddress']?.toString() ?? '';
        _feeController.text = data['fee']?.toString() ?? '';
        _selectedCourse = course != null && subjects.contains(course) ? course : null;
        _selectedBatch = batchDoc;
        _selectedStatus = data['status']?.toString() ?? 'ongoing';
        _createdAt = data['createdAt'] as Timestamp?;
        _existingImageUrl = data['imageurl']?.toString().isNotEmpty == true ? data['imageurl'] : null;
        _isLoading = false;
      });
      print('Loaded data - Course: $_selectedCourse, Batch: ${_selectedBatch?.id}, Status: $_selectedStatus, Fee: ${_feeController.text}');
    } catch (e) {
      print('Error loading student data: $e');
      if (mounted) {
        showGlassySnackBar(context, 'Error loading student data: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        showGlassySnackBar(context, 'Error picking image: $e');
      }
    }
  }

  Future<String?> uploadImageToImageKit(File imageFile) async {
    try {
      final url = Uri.parse("https://upload.imagekit.io/api/v1/files/upload");
      const String privateApiKey = 'private_aYnGVRNsY0ndhin5+fXjG/e1png=';
      final String authHeader = 'Basic ${base64Encode(utf8.encode('$privateApiKey:'))}';

      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = authHeader
        ..fields['fileName'] = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..fields['useUniqueFileName'] = 'true'
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final imageUrl = RegExp(r'"url":"(.*?)"').firstMatch(responseBody)?.group(1);
        return imageUrl?.replaceAll(r'\/', '/');
      } else {
        print('Image upload failed: ${response.statusCode}');
        if (mounted) {
          showGlassySnackBar(context, 'Image upload failed: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        showGlassySnackBar(context, 'Error uploading image: $e');
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _selectedCourse == null || _selectedBatch == null) {
      showGlassySnackBar(context, 'Please fill all required fields');
      return;
    }

    setState(() => _isUploading = true);

    String? imageUrl = _existingImageUrl;
    if (_selectedImage != null) {
      imageUrl = await uploadImageToImageKit(_selectedImage!);
      if (imageUrl == null) {
        setState(() => _isUploading = false);
        return;
      }
    }

    try {
      await FirebaseFirestore.instance.collection('students').doc(widget.userId).set({
        'name': _nameController.text.trim(),
        'parentName': _parentNameController.text.trim(),
        'nic': _nicController.text.trim(),
        'contact': _contactController.text.trim(),
        'fatherContact': _fatherContactController.text.trim(),
        'email': _emailController.text.trim(),
        'currentAddress': _currentAddressController.text.trim(),
        'homeAddress': _homeAddressController.text.trim(),
        'fee': _feeController.text.trim(),
        'course': _selectedCourse,
        'batchId': _selectedBatch!.id,
        'status': _selectedStatus,
        'imageurl': imageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Profile updated for userId: ${widget.userId}, Fee: ${_feeController.text}');
      if (mounted) {
        showGlassySnackBar(context, 'Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        showGlassySnackBar(context, 'Error saving profile: $e');
      }
    }

    setState(() => _isUploading = false);
  }

  Widget _buildField(TextEditingController controller, String label, {bool isEmail = false, bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        validator: (val) {
          if (val!.isEmpty) return 'Required';
          if (isEmail && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
            return 'Enter a valid email';
          }
          if (isNumeric && double.tryParse(val) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
        keyboardType: isEmail
            ? TextInputType.emailAddress
            : (isNumeric ? TextInputType.number : TextInputType.text),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white.withOpacity(0.35),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectProvider = Provider.of<SubjectProvider>(context);
    final selectedBatchProvider = Provider.of<SelectedBatchProvider>(context);
    final subjects = subjectProvider.subjects;
    final availableBatches = _selectedCourse != null
        ? selectedBatchProvider.getBatchesForSubject(_selectedCourse!)
        : [];

    print('Building UI - Subjects: $subjects, Available Batches: ${availableBatches.map((b) => b.id).toList()}');
    print('Selected Course: $_selectedCourse, Selected Batch: ${_selectedBatch?.id}, Status: $_selectedStatus, Fee: ${_feeController.text}');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Student Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
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
          SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 500,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: _selectedImage != null
                                      ? FileImage(_selectedImage!)
                                      : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty
                                      ? NetworkImage(_existingImageUrl!)
                                      : null) as ImageProvider?,
                                  child: _selectedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 32, color: Colors.white)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildField(_nameController, 'Student Name'),
                              _buildField(_parentNameController, "Parent's Name"),
                              _buildField(_nicController, 'NIC / Birth Certificate No'),
                              _buildField(_contactController, 'Student Contact Number'),
                              _buildField(_fatherContactController, 'Parent Contact Number'),
                              _buildField(_emailController, 'Email Address', isEmail: true),
                              _buildField(_currentAddressController, 'Current Address'),
                              _buildField(_homeAddressController, 'Home Address'),
                              _buildField(_feeController, 'Fee (PKR)', isNumeric: true),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCourse,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                    dropdownColor: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                                      labelText: 'Select Subject',
                                      labelStyle: TextStyle(color: Colors.black87),
                                    ),
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                    items: subjects
                                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCourse = val;
                                        _selectedBatch = null;
                                        _batchError = null;
                                      });
                                      if (val != null) {
                                        Provider.of<SelectedBatchProvider>(context, listen: false)
                                            .fetchOngoingBatchesForSubject(val);
                                      }
                                    },
                                    validator: (val) => val == null ? 'Please select a course' : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_batchError != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    _batchError!,
                                    style: const TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              if (_selectedCourse != null)
                                selectedBatchProvider.isLoading
                                    ? const CircularProgressIndicator()
                                    : availableBatches.isNotEmpty
                                    ? DropdownButtonFormField<DocumentSnapshot<Object?>>(
                                  value: _selectedBatch,
                                  decoration: _inputDecoration('Select Batch (Ongoing)'),
                                  dropdownColor: Colors.white.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(14),
                                  items: availableBatches
                                      .map<DropdownMenuItem<DocumentSnapshot<Object?>>>((doc) {
                                    return DropdownMenuItem<DocumentSnapshot<Object?>>(
                                      value: doc,
                                      child: Text('${doc['name']} (No. ${doc['number']})'),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setState(() {
                                    _selectedBatch = val;
                                    _batchError = null;
                                  }),
                                  validator: (val) => val == null ? 'Please select a batch' : null,
                                )
                                    : const Text(
                                  'No ongoing batch available.',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              const SizedBox(height: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                                    dropdownColor: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                                      labelText: 'Select Status',
                                      labelStyle: TextStyle(color: Colors.black87),
                                    ),
                                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                    items: ['ongoing', 'completed', 'left', 'removed']
                                        .map((status) => DropdownMenuItem(value: status, child: Text(status.toUpperCase())))
                                        .toList(),
                                    onChanged: (val) => setState(() => _selectedStatus = val),
                                    validator: (val) => val == null ? 'Please select a status' : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Joining Date: ${_createdAt != null ? "${_createdAt!.toDate().day}/${_createdAt!.toDate().month}/${_createdAt!.toDate().year}" : 'N/A'}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: Text(_isUploading ? 'Saving...' : 'Save Profile'),
                                onPressed: _isUploading ? null : _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black.withOpacity(0.7),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        ),
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