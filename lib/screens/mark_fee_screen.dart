import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/mark_student_paid.dart';
import 'package:thinkcode/provider/student_filter_provider.dart';
import 'package:thinkcode/widgets/custom_snackbar.dart';
import 'package:thinkcode/widgets/glow_circle.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MarkStudentPaidScreen extends StatelessWidget {
  const MarkStudentPaidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MarkStudentPaidProvider()),
        ChangeNotifierProvider(create: (_) => StudentFilterProvider()),
      ],
      child: const _MarkStudentPaidScreenContent(),
    );
  }
}

class _MarkStudentPaidScreenContent extends StatefulWidget {
  const _MarkStudentPaidScreenContent();

  @override
  State<_MarkStudentPaidScreenContent> createState() => _MarkStudentPaidScreenContentState();
}

class _MarkStudentPaidScreenContentState extends State<_MarkStudentPaidScreenContent> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markPaidProvider = Provider.of<MarkStudentPaidProvider>(context);
    final filterProvider = Provider.of<StudentFilterProvider>(context);
    final currentMonth = markPaidProvider.getCurrentMonthPK();
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mark Students Paid"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (markPaidProvider.selectedStudentIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
              tooltip: 'Mark Selected as Paid',
              onPressed: () => _markBulkPaid(context, markPaidProvider, screenWidth),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (value) => markPaidProvider.setSortBy(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'paidMonths', child: Text('Sort by Paid Months', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'unpaidCurrent', child: Text('Sort by Unpaid Current Month', style: TextStyle(color: Colors.white))),
            ],
          ),
        ],
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButton<String>(
                              value: filterProvider.selectedCourse,
                              hint: const Text('Course', style: TextStyle(color: Colors.white70)),
                              dropdownColor: Colors.grey[850],
                              borderRadius: BorderRadius.circular(12),
                              style: const TextStyle(color: Colors.white),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('All Courses')),
                                ...filterProvider.courses.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                              ],
                              onChanged: (value) => filterProvider.setSelectedCourse(value),
                            ),
                          ),
                          if (filterProvider.selectedCourse != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: DropdownButton<String>(
                                value: filterProvider.selectedBatch,
                                hint: const Text('Batch', style: TextStyle(color: Colors.white70)),
                                dropdownColor: Colors.grey[850],
                                borderRadius: BorderRadius.circular(12),
                                style: const TextStyle(color: Colors.white),
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Batches')),
                                  ...filterProvider.batches.map((b) => DropdownMenuItem(value: b.id, child: Text(filterProvider.getBatchName(b)))),
                                ],
                                onChanged: (value) => filterProvider.setSelectedBatch(value),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth > 600 ? 32 : 16),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: filterProvider.getFilteredStudentsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting || filterProvider.isLoading) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No ongoing students found', style: TextStyle(color: Colors.white70)));
                        }

                        final students = snapshot.data!.docs;

                        students.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          if (markPaidProvider.sortBy == 'paidMonths') {
                            final aPaid = ((aData['monthlyPayments'] as Map?)?.keys.length ?? 0);
                            final bPaid = ((bData['monthlyPayments'] as Map?)?.keys.length ?? 0);
                            return bPaid.compareTo(aPaid);
                          } else {
                            final aPaidCurrent = ((aData['monthlyPayments'] as Map?)?.containsKey(currentMonth) ?? false);
                            final bPaidCurrent = ((bData['monthlyPayments'] as Map?)?.containsKey(currentMonth) ?? false);
                            return aPaidCurrent == bPaidCurrent ? 0 : (aPaidCurrent ? 1 : -1);
                          }
                        });

                        return ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final doc = students[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name']?.toString() ?? 'Unnamed';
                            final course = data['course']?.toString() ?? 'Unknown Course';
                            final batchId = data['batchId']?.toString();
                            final fee = data['fee']?.toString() ?? '0';
                            final imageUrl = data['imageurl']?.toString();
                            final rawPayments = data['monthlyPayments'] as Map<String, dynamic>? ?? {};
                            final monthlyPayments = <String, Map<String, dynamic>>{};
                            rawPayments.forEach((k, v) {
                              if (v is Map && v['amount'] is num && v['date'] is Timestamp) {
                                monthlyPayments[k] = {
                                  'amount': v['amount'] as num,
                                  'date': v['date'] as Timestamp,
                                  'note': v['note']?.toString() ?? '',
                                };
                              }
                            });
                            final paidMonths = monthlyPayments.keys.toList()..sort();
                            final studentFee = double.tryParse(fee) ?? 0.0;
                            final isPaidThisMonth = monthlyPayments.containsKey(currentMonth) &&
                                (monthlyPayments[currentMonth]?['amount'] as num?)?.toDouble() == studentFee;
                            final currentMonthAmount = monthlyPayments[currentMonth]?['amount']?.toDouble() ?? 0.0;
                            final fullyPaidMonths = paidMonths.where((m) => (monthlyPayments[m]?['amount'] as num?)?.toDouble() == studentFee).length;
                            final partiallyPaidMonths = paidMonths.where((m) => (monthlyPayments[m]?['amount'] as num?)!.toDouble() < studentFee).length;

                            return FutureBuilder<DocumentSnapshot>(
                              future: batchId != null ? _firestore.collection('batches').doc(batchId).get() : Future.value(null),
                              builder: (context, batchSnapshot) {
                                final batchName = filterProvider.getBatchName(batchSnapshot.data);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isPaidThisMonth
                                                ? Colors.greenAccent.withOpacity(0.3)
                                                : Colors.redAccent.withOpacity(0.3),
                                          ),
                                        ),
                                        child: ExpansionTile(
                                          title: Row(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Checkbox(
                                                value: markPaidProvider.selectedStudentIds.contains(doc.id),
                                                onChanged: (value) => markPaidProvider.toggleStudentSelection(doc.id),
                                                activeColor: Colors.greenAccent,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              CircleAvatar(
                                                radius: screenWidth > 600 ? 24 : 20,
                                                backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                                                    ? NetworkImage(imageUrl)
                                                    : null,
                                                child: imageUrl == null || imageUrl.isEmpty
                                                    ? Text(
                                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: screenWidth > 600 ? 18 : 16,
                                                  ),
                                                )
                                                    : null,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: screenWidth > 600 ? 18 : 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      "Course: $course | Batch: $batchName",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: screenWidth > 600 ? 14 : 12,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                    Text(
                                                      "Fee: $fee PKR | Paid this month: ${currentMonthAmount.toStringAsFixed(2)} PKR",
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: screenWidth > 600 ? 14 : 12,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => _markPaid(context, markPaidProvider, doc.id, paidMonths, fee, monthlyPayments, screenWidth),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: isPaidThisMonth ? Colors.greenAccent.withOpacity(0.8) : Colors.redAccent.withOpacity(0.8),
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                  minimumSize: Size(screenWidth > 600 ? 100 : 80, 36),
                                                ),
                                                child: Text(
                                                  isPaidThisMonth ? 'Paid' : 'Pay',
                                                  style: TextStyle(
                                                    fontSize: screenWidth > 600 ? 14 : 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Text(
                                            "Payment Status: $fullyPaidMonths fully paid, $partiallyPaidMonths partially paid",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: screenWidth > 600 ? 14 : 12,
                                            ),
                                          ),
                                          children: paidMonths.isEmpty
                                              ? [
                                            Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Text(
                                                'No payments recorded',
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: screenWidth > 600 ? 14 : 12,
                                                ),
                                              ),
                                            ),
                                          ]
                                              : paidMonths.map((month) {
                                            final payment = monthlyPayments[month];
                                            final amount = payment?['amount']?.toDouble() ?? 0.0;
                                            final date = payment?['date'] as Timestamp?;
                                            final note = payment?['note']?.toString() ?? '';
                                            final isPartial = amount < studentFee;
                                            return Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '$month: ${amount.toStringAsFixed(2)} PKR${isPartial ? ' (Partial)' : ''}',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: screenWidth > 600 ? 14 : 12,
                                                          ),
                                                        ),
                                                        Text(
                                                          date != null
                                                              ? "Paid on: ${DateFormat('dd/MM/yyyy').format(date.toDate())}"
                                                              : "N/A",
                                                          style: TextStyle(
                                                            color: Colors.white70,
                                                            fontSize: screenWidth > 600 ? 12 : 10,
                                                          ),
                                                        ),
                                                        if (note.isNotEmpty)
                                                          Text(
                                                            "Note: $note",
                                                            style: TextStyle(
                                                              color: Colors.white70,
                                                              fontSize: screenWidth > 600 ? 12 : 10,
                                                            ),
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.redAccent,
                                                      size: screenWidth > 600 ? 20 : 18,
                                                    ),
                                                    onPressed: () => markPaidProvider.markUnpaid(context, doc.id, month),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaid(
      BuildContext context,
      MarkStudentPaidProvider provider,
      String docId,
      List<String> paidMonths,
      String fee,
      Map<String, Map<String, dynamic>> monthlyPayments,
      double screenWidth,
      ) async {
    final studentFee = double.tryParse(fee) ?? 0.0;
    final upcomingMonths = provider.getUpcomingMonths();
    final unpaidMonths = upcomingMonths.where((m) {
      if (!paidMonths.contains(m)) return true;
      final amount = (monthlyPayments[m]?['amount'] as num?)?.toDouble() ?? 0.0;
      return amount < studentFee;
    }).toList();

    if (unpaidMonths.isEmpty && paidMonths.every((m) => (monthlyPayments[m]?['amount'] as num?)?.toDouble() == studentFee)) {
      showGlassySnackBar(context, "All upcoming months are fully paid");
      return;
    }

    final selectedMonths = <String>{};
    _amountController.clear();
    _noteController.clear();

    // Calculate total remaining fee for upcoming months
    double totalPaid = 0.0;
    for (var month in paidMonths) {
      totalPaid += (monthlyPayments[month]?['amount'] as num?)?.toDouble() ?? 0.0;
    }
    final maxAllowedPayment = (studentFee * 12) - totalPaid;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900]?.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Submit Fee",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount (PKR, max: ${maxAllowedPayment.toStringAsFixed(2)})',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.currency_rupee, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final amount = double.tryParse(value) ?? 0.0;
                      selectedMonths.clear();
                      if (amount > 0 && studentFee > 0) {
                        final cappedAmount = amount > maxAllowedPayment ? maxAllowedPayment : amount;
                        final monthsToPay = (cappedAmount / studentFee).floor();
                        final remaining = cappedAmount % studentFee;
                        selectedMonths.addAll(unpaidMonths.take(monthsToPay));
                        if (remaining > 0 && monthsToPay < unpaidMonths.length) {
                          selectedMonths.add(unpaidMonths[monthsToPay]);
                        }
                        setState(() {});
                      }
                    },
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 12),
                  Text(
                    'Will pay for: ${selectedMonths.isEmpty ? 'None' : selectedMonths.join(', ')}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth > 600 ? 14 : 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (e.g., Partial payment)',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Submit Fee"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () async {
                          final date = DateTime.now();
                          if (_amountController.text.isNotEmpty) {
                            final totalAmount = double.tryParse(_amountController.text) ?? 0.0;
                            if (totalAmount <= 0) {
                              showGlassySnackBar(context, 'Enter a valid amount');
                              return;
                            }
                            if (totalAmount > maxAllowedPayment) {
                              showGlassySnackBar(context, 'Amount exceeds maximum allowed (${maxAllowedPayment.toStringAsFixed(2)} PKR)');
                              return;
                            }
                            if (selectedMonths.isNotEmpty) {
                              final payments = <String, Map<String, dynamic>>{};
                              double remainingAmount = totalAmount;
                              for (var month in selectedMonths) {
                                final existingPayment = await provider.getExistingPayment(docId, month);
                                final currentPaid = existingPayment?['amount']?.toDouble() ?? 0.0;
                                final amountToAssign = (remainingAmount + currentPaid) >= studentFee ? studentFee - currentPaid : remainingAmount;
                                if (amountToAssign <= 0) continue;
                                payments[month] = {
                                  'amount': amountToAssign + currentPaid,
                                  'date': Timestamp.fromDate(date),
                                  'note': amountToAssign + currentPaid < studentFee
                                      ? (_noteController.text.isEmpty ? 'Partial payment' : _noteController.text)
                                      : _noteController.text,
                                };
                                remainingAmount -= amountToAssign;
                                if (remainingAmount <= 0) break;
                              }
                              if (payments.isNotEmpty) {
                                await provider.updatePayments(context, docId, payments);
                              } else {
                                showGlassySnackBar(context, 'No valid payments to record');
                              }
                            } else {
                              showGlassySnackBar(context, 'Enter an amount to select months');
                              return;
                            }
                            if (mounted) {
                              Navigator.pop(context);
                              showGlassySnackBar(context, 'Payment marked successfully');
                            }
                          }
                        },
                      ).animate().fadeIn(duration: 700.ms).scale(),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ).animate().fadeIn(duration: 700.ms).scale(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markBulkPaid(
      BuildContext context,
      MarkStudentPaidProvider provider,
      double screenWidth,
      ) async {
    final unpaidMonths = provider.getUpcomingMonths();
    final selectedMonths = <String>{};
    _amountController.clear();
    _noteController.clear();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900]?.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Bulk Payment",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: unpaidMonths.map((m) {
                      return ChoiceChip(
                        label: Text(m, style: const TextStyle(color: Colors.white)),
                        selected: selectedMonths.contains(m),
                        selectedColor: Colors.greenAccent.withOpacity(0.6),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedMonths.add(m);
                            } else {
                              selectedMonths.remove(m);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Amount per Student (PKR) for ${selectedMonths.length} month(s)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.currency_rupee, color: Colors.white70),
                    ),
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (e.g., Partial payment for all)',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Submit Fee"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () async {
                          final date = DateTime.now();
                          if (_amountController.text.isNotEmpty) {
                            final amount = double.tryParse(_amountController.text) ?? 0.0;
                            if (amount <= 0) {
                              showGlassySnackBar(context, 'Enter a valid amount');
                              return;
                            }
                            await provider.markBulkPaid(
                              context,
                              provider.selectedStudentIds.toList(),
                              selectedMonths.toList(),
                              amount,
                              _noteController.text,
                              date,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              showGlassySnackBar(context, 'Bulk payment marked successfully');
                            }
                          }
                        },
                      ).animate().fadeIn(duration: 700.ms).scale(),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ).animate().fadeIn(duration: 700.ms).scale(),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}