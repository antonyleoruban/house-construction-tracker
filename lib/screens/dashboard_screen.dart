import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/alert_dialog.dart';
import 'constrcution/image_screen.dart';
import 'expense/expense_screen.dart';
import 'loan/loan_screen.dart';
import 'login_screen.dart';
import 'notes/notes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await Provider.of<AppProvider>(context, listen: false).fetchTotals();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Logout',
      content: 'Are you sure you want to logout?',
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardCard(
                      'Total General Expenses',
                      provider.totalGeneralExpense,
                      Icons.account_balance_wallet,
                      Colors.redAccent,
                      type: 'expense',
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      'Total Building Expenses',
                      provider.totalBuildExpense,
                      Icons.account_balance_wallet,
                      Colors.redAccent,
                      type: 'building_expense',
                    ),

                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      'Total Expenses',
                      provider.totalBuildExpense + provider.totalGeneralExpense,
                      Icons.account_balance_wallet,
                      Colors.redAccent,
                      type: 'total_expense',
                    ),
                    const SizedBox(height: 16),
                    _buildDashboardCard(
                      'Total Loan',
                      provider.totalLoan,
                      Icons.account_balance,
                      Colors.green,
                      type: 'loan',
                    ),
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildMenuButton('Expenses', Icons.money_off, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen()));
                    }),
                    _buildMenuButton('Loans', Icons.attach_money, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanListScreen()));
                    }),
                    _buildMenuButton('Construction Images', Icons.image, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageListScreen()));
                    }),
                    _buildMenuButton('Notes', Icons.note, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesScreen()));
                    }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardCard(String title, double value, IconData icon, Color color, {String type = 'expense'}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: InkWell(
        onTap: () {
          if (type == 'expense') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen(expenseType: 'general')));
          } else if (type == 'loan') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanListScreen()));
          } else if (type == "building_expense"){
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseListScreen(expenseType: 'building')));
          }else{

          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 120, // Fixed height
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        formatINR(value),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                        overflow: TextOverflow.visible,
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
  }

  String formatINR(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN', // Indian locale
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }

  Widget _buildMenuButton(String title, IconData icon, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 60, // Fixed height
          child: Row(
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
