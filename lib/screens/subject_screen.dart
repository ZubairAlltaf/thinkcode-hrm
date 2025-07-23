import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/subject_provider.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubjectProvider>(context, listen: false).fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectProvider>(context);
    final subjects = provider.subjects;
    final isLoading = provider.isLoading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Manage Subjects'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // 🎨 Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027), // dark navy
                  Color(0xFF134E5E), // dark emerald
                  Color(0xFF203A43), // slightly teal
                  Color(0xFF2C5364), // soft cyan
                  Color(0xFF71B280), // mint green
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          const Positioned(
            top: -40,
            left: -30,
            child: GlowCircle(size: 150),
          ),
          const Positioned(
            bottom: -40,
            right: -30,
            child: GlowCircle(size: 120),
          ),

          // 💎 Glassy Content
          Center(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✍️ Input
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Enter Subject Name',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ➕ Button
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_controller.text.trim().isNotEmpty) {
                            provider.addSubject(_controller.text.trim());
                            _controller.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Subject'),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: Colors.white54),

                      const SizedBox(height: 10),
                      const Text(
                        'Subjects',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      // 📜 Subject List
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : subjects.isEmpty
                            ? const Text(
                          "No subjects yet.",
                          style: TextStyle(color: Colors.black54),
                        )
                            : ListView.separated(
                          itemCount: subjects.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12,),
                            title: Text(
                              subjects[index],
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                provider.deleteSubject(subjects[index]);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
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