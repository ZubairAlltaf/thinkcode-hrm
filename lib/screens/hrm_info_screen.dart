import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/student_provider.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

const Color kAccentColor = Color(0xFF3A5160);

class HRMInfoScreen extends StatelessWidget {
  const HRMInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          SafeArea(
            child: Consumer<StudentProvider>(
              builder: (context, provider, _) {
                provider.fetchFeeStats();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'HRM Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          _RealtimeStatCard(
                            collection: 'subjects',
                            title: 'Subjects',
                            icon: Icons.menu_book_rounded,
                          ),
                          SizedBox(width: 12),
                          _RealtimeStatCard(
                            collection: 'batches',
                            title: 'Batches',
                            icon: Icons.layers_outlined,
                          ),
                          SizedBox(width: 12),
                          _RealtimeStatCard(
                            collection: 'students',
                            title: 'Students',
                            icon: Icons.people_alt_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _FilteredStatCard(
                            title: 'Paid Students',
                            icon: Icons.check_circle_outline,
                            isPaid: true,
                            count: provider.paidCount,
                          ),
                          const SizedBox(width: 12),
                          _FilteredStatCard(
                            title: 'Unpaid Students',
                            icon: Icons.cancel_outlined,
                            isPaid: false,
                            count: provider.unpaidCount,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}

class _RealtimeStatCard extends StatelessWidget {
  final String collection;
  final String title;
  final IconData icon;

  const _RealtimeStatCard({
    required this.collection,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  '$count',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilteredStatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isPaid;
  final int count;

  const _FilteredStatCard({
    required this.title,
    required this.icon,
    required this.isPaid,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isPaid ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPaid ? Colors.green : Colors.red),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: isPaid ? Colors.green : Colors.red),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isPaid ? Colors.green[200] : Colors.red[200],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isPaid ? Colors.green[200] : Colors.red[200],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
