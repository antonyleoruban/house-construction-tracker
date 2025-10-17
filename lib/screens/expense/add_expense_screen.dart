import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart'; // Ensure this path is correct

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat format = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    double value = double.parse(newText) / 100;
    String formatted = format.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _totalAmountController = TextEditingController();
  final TextEditingController _givenAmountController = TextEditingController();
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String? _selectedExpenseType;

  // 1. Declare FocusNodes for relevant TextFormFields
  late FocusNode _remarksFocusNode;
  late FocusNode _nameFocusNode; // Optional: For moving to next field or dismissing after name
  late FocusNode _totalAmountFocusNode; // Optional: For moving between amount fields

  DateTime? _selectedDate;

  bool get _isEditing => widget.expenseToEdit != null;

  @override
  void initState() {
    super.initState();

    // 2. Initialize FocusNodes
    _remarksFocusNode = FocusNode();
    _nameFocusNode = FocusNode();
    _totalAmountFocusNode = FocusNode();


    if (_isEditing) {
      final expense = widget.expenseToEdit!;
      _nameController.text = expense['expenseName'] ?? '';
      _totalAmountController.text = expense['totalAmount'] != null
          ? CurrencyInputFormatter().format.format(expense['totalAmount'])
          : '';
      _givenAmountController.text = expense['givenAmount'] != null
          ? CurrencyInputFormatter().format.format(expense['givenAmount'])
          : '';
      _personController.text = expense['personName'] ?? '';
      _remarksController.text = expense['remarks'] ?? '';
      _selectedExpenseType = expense['expenseType'] as String? ?? 'general';

      if (expense['date'] != null) {
        // Ensure consistent parsing of ISO 8601 string
        _selectedDate = DateTime.parse(expense['date']);
      } else {
        _selectedDate = DateTime.now();
      }
    } else {
      _selectedDate = DateTime.now();
      _selectedExpenseType = 'general';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _totalAmountController.dispose();
    _givenAmountController.dispose();
    _personController.dispose();
    _remarksController.dispose();

    // 3. Dispose FocusNodes
    _remarksFocusNode.dispose();
    _nameFocusNode.dispose();
    _totalAmountFocusNode.dispose();

    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveExpense(AppProvider provider) {
    // Dismiss keyboard before validation/save attempt
    FocusScope.of(context).unfocus(); // Dismisses whichever keyboard is open

    if (_formKey.currentState!.validate()) {

      final totalCleaned = _totalAmountController.text.replaceAll(RegExp(r'[₹,\s]'), '');
      String totalAmountString = totalCleaned.replaceAll(RegExp(r'[^0-9]'), '');

      final giveAmountCleaned = _totalAmountController.text.replaceAll(RegExp(r'[₹,\s]'), '');
      String givenAmountString = giveAmountCleaned.replaceAll(RegExp(r'[^0-9]'), '');

      double total = (double.tryParse(totalAmountString) ?? 0.0) / 100;
      double given = (double.tryParse(givenAmountString) ?? 0.0) / 100;

      if (total <= 0) {
        _showSnackBar('Total Amount must be greater than zero.');
        return;
      }
      if (given > total) {
        _showSnackBar('Given Amount cannot be greater than Total Amount.');
        return;
      }

      final expenseData = {
        // Ensure consistent storage format using toIso8601String()
        'date': _selectedDate!.toIso8601String(),
        'expenseName': _nameController.text.trim(),
        'totalAmount': total,
        'givenAmount': given,
        'balanceAmount': total - given,
        'personName': _personController.text.trim(),
        'expenseType': _selectedExpenseType,
        'remarks': _remarksController.text.trim(),
      };

      if (_isEditing) {
        provider.updateExpense(widget.expenseToEdit!['id'], expenseData);
        _showSnackBar('Expense updated successfully!');
      } else {
        provider.addExpense(expenseData);
        _showSnackBar('Expense added successfully!');
      }

      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var provider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add New Expense'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector( // Add a GestureDetector to dismiss keyboard on tap outside
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expense Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedExpenseType,
                  decoration: InputDecoration(
                    labelText: 'Expense Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: ['general', 'building']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type[0].toUpperCase() + type.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedExpenseType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an expense type';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Expense Name
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocusNode, // Assign FocusNode
                  decoration: InputDecoration(
                    labelText: 'Expense Name',
                    hintText: 'e.g., Labour cos, Material',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.shopping_bag_outlined),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Expense Name is required';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next, // Move to next field
                  onFieldSubmitted: (value) {
                    FocusScope.of(context).requestFocus(_totalAmountFocusNode); // Move focus to total amount
                  },
                ),
                const SizedBox(height: 20),

                // Date Selector - No text input here, so no textInputAction needed
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus(); // Dismiss keyboard before showing date picker
                    _selectDate(context);
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: TextEditingController(
                        text: _selectedDate == null ? '' : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      ),
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date of Expense',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today_outlined),
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (v) {
                        if (_selectedDate == null) {
                          return 'Date is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Total Amount
                TextFormField(
                  controller: _totalAmountController,
                  focusNode: _totalAmountFocusNode, // Assign FocusNode
                  decoration: InputDecoration(
                    labelText: 'Total Amount',
                    hintText: 'e.g., 1500.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  validator: (v) {
                    print('Validating Total Amount: $v');
                    if (v == null || v.trim().isEmpty) {
                      return 'Total Amount is required';
                    }
                    final cleaned = v.replaceAll(RegExp(r'[₹,\s]'), '');

                    if (double.tryParse(cleaned) == null) {
                      return 'Please enter a valid number';
                    }
                    if (double.parse(cleaned) <= 0) {
                      return 'Amount must be positive';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next, // Move to next field
                  onFieldSubmitted: (value) {
                    FocusScope.of(context).nextFocus(); // Move to the next field (Given Amount)
                  },
                ),
                const SizedBox(height: 20),

                // Given Amount
                TextFormField(
                  controller: _givenAmountController,
                  // No specific focusNode needed if just going to next/done by default
                  decoration: InputDecoration(
                    labelText: 'Amount Paid',
                    hintText: 'e.g., 1000.00 (how much you paid)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.currency_rupee),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Amount Paid is required';
                    }
                    final cleaned = v.replaceAll(RegExp(r'[₹,\s]'), '');
                    if (double.tryParse(cleaned) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next, // Move to next field
                  onFieldSubmitted: (value) {
                    FocusScope.of(context).nextFocus(); // Move to the next field (Person Name)
                  },
                ),
                const SizedBox(height: 20),

                // Person Name
                TextFormField(
                  controller: _personController,
                  decoration: InputDecoration(
                    labelText: 'Paid To/From (Optional)',
                    hintText: 'e.g., John Doe, Vendor Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textInputAction: TextInputAction.next, // Move to next field
                  onFieldSubmitted: (value) {
                    FocusScope.of(context).nextFocus(); // Move to the next field (Remarks)
                  },
                ),
                const SizedBox(height: 20),

                // Remarks
                TextFormField(
                  controller: _remarksController,
                  focusNode: _remarksFocusNode, // Assign the FocusNode here
                  decoration: InputDecoration(
                    labelText: 'Remarks (Optional)',
                    hintText: 'e.g., For house rent of April',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.done, // Shows "Done" on keyboard
                  onFieldSubmitted: (value) {
                    _remarksFocusNode.unfocus(); // Dismiss the keyboard when "Done" is pressed
                    // Optionally, you can also trigger save here if this is the last field
                    // _saveExpense(provider);
                  },
                ),
                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () => _saveExpense(provider),
                    icon: Icon(_isEditing ? Icons.save : Icons.add_circle_outline),
                    label: Text(
                      _isEditing ? 'Update Expense' : 'Add Expense',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}