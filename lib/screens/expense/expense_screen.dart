// Only used for web
import 'dart:html' show AnchorElement;
import 'dart:html' show Blob, Url;
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:new_home/providers/app_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  bool descending = true;

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AppProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: Icon(
              descending ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: descending ? "Sort Descending" : "Sort Ascending",
            onPressed: () {
              setState(() {
                descending = !descending;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadExcel(context, provider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
      ),
      body: FutureBuilder(
        future: provider.getExpenses(sortByDate: true, descending: descending),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
            return const Center(child: Text('No expenses found'));
          }

          var expenses = snapshot.data as List<Map<String, dynamic>>;

          return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  var expense = expenses[index];
                  double balanceAmount = expense['balanceAmount'] ?? 0.0;
                  return Card(
                    elevation: 2, // Keep subtle elevation
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showEditExpenseDialog(context, expense), // Tap entire card to edit
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Expense Name & Date Header ---
                            Row(children: [
                              Expanded(
                                child: Text(
                                  expense['expenseName'] ?? 'Unnamed Expense',
                                  style: const TextStyle(
                                    fontSize: 20, // Slightly larger
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent, // A more vibrant color
                                  ),
                                ),
                              ),
                            ]),
                            Text(
                              formatDate(expense['date'] ?? ''),
                              style: TextStyle(
                                color: Colors.grey[500], // Slightly lighter grey
                                fontSize: 13, // Slightly smaller
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // --- Amounts Section ---
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildAmountRow(
                                  'Total Amount',
                                  expense['totalAmount'],
                                  Colors.red,
                                ),
                                const SizedBox(height: 6),
                                _buildAmountRow(
                                  'Amount Paid',
                                  expense['givenAmount'],
                                  Colors.green,
                                ),
                                const SizedBox(height: 6),
                                if (balanceAmount != 0)
                                  _buildAmountRow(
                                    'Balance Due',
                                    expense['balanceAmount'],
                                    Colors.orange,
                                    isBalance: true, // Indicate balance for potential bolding/special styling
                                  ),
                              ],
                            ),

                            // Add a subtle divider if needed
                            if ((expense['personName'] != null && expense['personName'].isNotEmpty) || (expense['remarks'] != null && expense['remarks'].isNotEmpty))
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, thickness: 0.5, color: Colors.grey),
                              ),

                            // --- Person & Remarks Section ---
                            if (expense['personName'] != null && expense['personName'].isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6), // More space
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 18, color: Colors.blueGrey[400]), // Filled icon, new color
                                    const SizedBox(width: 8),
                                    Text(
                                      expense['personName'],
                                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            if (expense['remarks'] != null && expense['remarks'].isNotEmpty)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.description, size: 18, color: Colors.blueGrey[400]), // Filled icon, new color
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      expense['remarks'],
                                      style: TextStyle(color: Colors.blueGrey[700], fontSize: 15),
                                      maxLines: 2, // Limit remarks to 2 lines
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                            //  const SizedBox(height: 12), // Add more space before actions

                            // --- Actions Section ---
                            Align(
                              // Align actions to the right
                              alignment: Alignment.bottomRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Wrap content
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _showEditExpenseDialog(context, expense),
                                    icon: const Icon(Icons.edit_note, size: 22, color: Colors.blue), // Different icon
                                    label: const Text('Edit', style: TextStyle(color: Colors.blue)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _showDeleteConfirmation(context, expense['id']),
                                    icon: const Icon(Icons.delete_forever, size: 22, color: Colors.red), // Different icon
                                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ));
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, String expenseId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_rounded, size: 60, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Delete Expense?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will permanently remove the expense record.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.red[400],
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close the dialog
                          await Provider.of<AppProvider>(context, listen: false).firestore.collection('expenses').doc(expenseId).delete();
                          setState(() {});
                          // Show snackbar with animation
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Expense deleted'),
                              backgroundColor: Colors.red[400],
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.all(20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'OK',
                                textColor: Colors.white,
                                onPressed: () {},
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper function for amount rows (put this outside your ListView.builder)
  Widget _buildAmountRow(String label, dynamic amount, Color color, {bool isBalance = false}) {
    final formattedAmount = amount != null ? amount.toStringAsFixed(2) : '0.00';

    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '₹ $formattedAmount', // Format amount
          style: TextStyle(
            fontSize: 17,
            fontWeight: isBalance ? FontWeight.bold : FontWeight.w600, // Balance is bolder
            color: color,
          ),
        ),
      ],
    );
  }

  String formatDate(String dateString) {
    if (dateString.isEmpty) return ''; // Handle empty date string
    try {
      final dateTime = DateTime.parse(dateString);
      final formatter = DateFormat("d MMM, yyyy");
      return formatter.format(dateTime);
    } catch (e) {
      return dateString; // fallback if parsing fails
    }
  }

  // In your main list screen:
  void _showEditExpenseDialog(BuildContext context, Map<String, dynamic> expense) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => AddExpenseScreen(
                expenseToEdit: expense,
              )),
    ).then((_) {
      // This runs when UploadImageScreen is popped
      setState(() {}); // Rebuild the widget to refresh data
    });
  }

  Future<void> _downloadExcel(BuildContext context, AppProvider provider) async {
    final expenses = await provider.getExpenses(sortByDate: true, descending: descending);

    final excel = Excel.createExcel();
    final sheet = excel[excel.getDefaultSheet()!];

    // Add headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Expense Name'),
      TextCellValue('Total Amount'),
    ]);

    double grandTotal = 0.0;

    // Add data rows
    for (final expense in expenses) {
      final amount = (expense['totalAmount'] ?? 0).toDouble();
      grandTotal += amount;

      sheet.appendRow([
        TextCellValue(formatDate(expense['date'] ?? '')),
        TextCellValue(expense['expenseName'] ?? 'Unnamed Expense'),
        TextCellValue(amount.toStringAsFixed(2)),
      ]);
    }

    // ✅ Add final row for total
    sheet.appendRow([
      TextCellValue(''),
      TextCellValue('Total'),
      TextCellValue(grandTotal.toStringAsFixed(2)),
    ]);

    // Encode the file
    final bytes = excel.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate Excel file.')),
      );
      return;
    }

    if (kIsWeb) {
      // ✅ Web: trigger browser download
      final blob = Blob([bytes]);
      final url = Url.createObjectUrlFromBlob(blob);

      final anchor = AnchorElement(href: url)
        ..setAttribute("download", "expenses.xlsx")
        ..click();

      Url.revokeObjectUrl(url);
    } else {
      // ✅ Mobile/Desktop: use path_provider
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/expenses.xlsx';
      final file = File(filePath);

      await file.writeAsBytes(bytes);
      OpenFile.open(filePath);
    }
  }
}
