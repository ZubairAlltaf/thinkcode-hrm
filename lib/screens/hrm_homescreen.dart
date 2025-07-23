import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/components/greetings_header.dart';
import 'package:thinkcode/provider/income_expense_provider.dart';
import 'package:thinkcode/provider/student_provider.dart';
import 'package:thinkcode/widgets/custom_drawer.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

const Color kAccentColor = Color(0xFF3A5160);

class HRMHomeScreen extends StatelessWidget {

  const HRMHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final incomeExpenseProvider = Provider.of<IncomeExpenseProvider>(context, listen: false);
    incomeExpenseProvider.fetchIncomeAndExpenses();

    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    studentProvider.fetchFeeStats();

    return Scaffold(drawer: CustomDrawer(
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

          // Glow Decorations
          const Positioned(top: -40, left: -30, child: GlowCircle(size: 150)),
          const Positioned(
            bottom: -40,
            right: -30,
            child: GlowCircle(size: 120),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Builder(
                      builder: (context) => IconButton(
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        icon: const Icon(
                          IconlyBold.category,
                          color: Colors.white,
                          size: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          padding: const EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  const GreetingHeader(),
                  const SizedBox(height: 28),

                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),


                  Row(
                    children: [
                      _RealtimeStatCard(
                        collection: 'subjects',
                        title: 'Total Subjects',
                        icon: Icons.menu_book_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0BA360), Color(0xFF3CBA92)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const _RealtimeStatCard(
                        collection: 'batches',
                        title: 'Batches',
                        icon: IconlyBold.calendar,
                        gradient: LinearGradient(
                          colors: [Color(0xFFB24592), Color(0xFFF15F79)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ],
                  ),


                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(child: CombinedFeeStatCard()),
                      const SizedBox(width: 16),
                      Expanded(child: NetIncomeCard())
                    ],
                  ),
                  SizedBox(height: 16),


                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    children: const [
                      _QuickButton(
                        title: 'Create Subject',
                        icon: Icons.auto_stories,
                        routeName: '/subjects',
                      ),
                      _QuickButton(
                        title: 'Create Batch',
                        icon: Icons.add_to_photos_rounded,
                        routeName: '/batches',
                      ),
                      _QuickButton(
                        title: 'Add Student',
                        icon: Icons.person_add_alt,
                        routeName: '/add-student',
                      ),
                      _QuickButton(
                        title: 'All Students',
                        icon: Icons.people_outline,
                        routeName: '/allstudents',
                      ),
                      _QuickButton(
                        title: 'Manage Fee',
                        icon: Icons.payments_outlined,
                        routeName: '/feemarkscreen',
                      ),
                      _QuickButton(
                        title: 'Expense Screen',
                        icon: Icons.money_off,
                        routeName: '/expensescreen',
                      ),
                      _QuickButton(
                        title: 'Manage',
                        icon: Icons.edit,
                        routeName: '/managebatchscreen',
                      ),

                    ],
                  ),

                  const SizedBox(height: 16),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final String routeName;

  const _QuickButton({
    required this.title,
    required this.icon,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withOpacity(0.12),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, routeName),
            child: Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 30, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
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
  final Gradient gradient;

  const _RealtimeStatCard({
    required this.collection,
    required this.title,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snapshot) {
          final count = snapshot.data?.docs.length ?? 0;

          return Container(
            height: 130,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
                const Spacer(),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
class CombinedFeeStatCard extends StatelessWidget {
  const CombinedFeeStatCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        final paidCount = provider.paidCount;
        final unpaidCount = provider.unpaidCount;

        return Container(
          height: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00FFEA), Color(0xFF00FFEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.payments_outlined, color: Colors.white, size: 28),
              const Spacer(),
              Text(
                'Paid: $paidCount    Unpaid: $unpaidCount',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'Student Fee Status',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
class NetIncomeCard extends StatelessWidget {
  const NetIncomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IncomeExpenseProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF40D53B), Color(0xFF40D53B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.monetization_on_outlined, color: Colors.white,
                  size: 28),
              const Spacer(),
              Text(
                'PKR ${provider.netProfit.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Net Income (This Month)',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}