import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:thinkcode/provider/income_expense_provider.dart';
import 'package:thinkcode/widgets/custom_snackbar.dart';
import 'package:thinkcode/widgets/glow_circle.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({super.key});

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> {
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<IncomeExpenseProvider>(context, listen: false).fetchIncomeAndExpenses();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.greenAccent,
              surface: Colors.grey,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedRange = picked);
      await Provider.of<IncomeExpenseProvider>(context, listen: false)
          .fetchIncomeAndExpenses(start: picked.start, end: picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Income & Expenses'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt, color: Colors.white),
            tooltip: 'Filter by Date',
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.info, color: Colors.white),
            tooltip: 'View Payment Details',
            onPressed: () => _showPaymentDetails(context),
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<IncomeExpenseProvider>(
                builder: (context, provider, child) {
                  if (provider.errorMessage != null) {
                    return Center(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Range Display
                      if (_selectedRange != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Showing data from ${DateFormat('yyyy-MM-dd').format(_selectedRange!.start)} to ${DateFormat('yyyy-MM-dd').format(_selectedRange!.end)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      // Summary Section
                      _SummarySection(
                        totalIncome: provider.totalIncome,
                        totalExpenses: provider.totalExpenses,
                        netProfit: provider.netProfit,
                        onIncomeTap: () => _showPaymentDetails(context),
                      ),
                      const SizedBox(height: 20),
                      // Expenses Section
                      const Text(
                        'Expenses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.white54),
                      Expanded(
                        child: _ExpensesSection(
                          expenses: provider.expenses,
                          screenWidth: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showAddExpenseDialog(context),
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900]!.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
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
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (PKR)',
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
          ],
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
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0;
              if (title.isNotEmpty && amount > 0) {
                Provider.of<IncomeExpenseProvider>(context, listen: false)
                    .addExpense(title, amount, DateTime.now());
                Navigator.pop(context);
                showGlassySnackBar(context, 'Expense added successfully');
              } else {
                showGlassySnackBar(context, 'Enter valid title and amount');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDetails(BuildContext context) {
    final provider = Provider.of<IncomeExpenseProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900]!.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _selectedRange != null
              ? 'Payments from ${DateFormat('yyyy-MM-dd').format(_selectedRange!.start)} to ${DateFormat('yyyy-MM-dd').format(_selectedRange!.end)}'
              : 'Payment Details (Current Month)',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: provider.payments.isEmpty
              ? const Text(
            'No payments found for the selected period',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: provider.payments.map((payment) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    '${payment['studentName']} - ${payment['month']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paid: PKR ${payment['amount'].toStringAsFixed(2)} on ${DateFormat('yyyy-MM-dd').format(payment['date'])}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      if (payment['note'].isNotEmpty)
                        Text(
                          'Note: ${payment['note']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final VoidCallback onIncomeTap;

  const _SummarySection({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.onIncomeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSummaryCard(
              label: 'Income',
              value: totalIncome,
              icon: Icons.trending_up,
              color: Colors.greenAccent,
              onTap: onIncomeTap,
            ),
            const SizedBox(width: 10),
            _buildSummaryCard(
              label: 'Expenses',
              value: totalExpenses,
              icon: Icons.trending_down,
              color: Colors.redAccent,
            ),
            const SizedBox(width: 10),
            _buildSummaryCard(
              label: 'Net Profit',
              value: netProfit,
              icon: Icons.account_balance_wallet_outlined,
              color: netProfit >= 0 ? Colors.lightGreenAccent : Colors.orangeAccent,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        height: 130,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              'PKR ${value.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ExpensesSection extends StatelessWidget {
  final List<Map<String, dynamic>> expenses;
  final double screenWidth;

  const _ExpensesSection({
    required this.expenses,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses found for the selected period',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    return ListView.builder(
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        final date = expense['date'] as DateTime?;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: ListTile(
                tileColor: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(
                  expense['title'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth > 600 ? 16 : 14,
                  ),
                ),
                subtitle: Text(
                  date != null ? DateFormat('yyyy-MM-dd').format(date) : 'No date',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth > 600 ? 14 : 12,
                  ),
                ),
                trailing: Text(
                  'PKR ${expense['amount'].toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth > 600 ? 14 : 12,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}