import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;

  const EditExpenseScreen({
    super.key,
    required this.expense,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  ExpenseCategory? _selectedCategory;
  late bool _isIncome;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing expense data
    _titleController = TextEditingController(text: widget.expense.title);
    _amountController = TextEditingController(text: widget.expense.amount.toString());
    _descriptionController = TextEditingController(text: widget.expense.description ?? '');
    _selectedDate = widget.expense.date;
    _isIncome = widget.expense.isIncome;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      final updatedExpense = widget.expense.copyWith(
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.replaceAll(',', '')),
        date: _selectedDate,
        category: _selectedCategory!.id,
        description: _descriptionController.text.trim(),
        isIncome: _isIncome,
      );

      context.read<ExpenseProvider>().updateExpense(updatedExpense).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_isIncome ? 'Income' : 'Expense'} updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update expense. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      });
    } else if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a category'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final categories = _isIncome 
        ? expenseProvider.incomeCategories 
        : expenseProvider.expenseCategories;
        
    // Find the matching category in our list
    if (_selectedCategory == null && categories.isNotEmpty) {
      try {
        _selectedCategory = categories.firstWhere(
          (c) => c.id == widget.expense.category,
        );
        print("Found matching category for editing: ${_selectedCategory!.id} - ${_selectedCategory!.name}");
      } catch (e) {
        // If no matching category is found, use the first one
        if (categories.isNotEmpty) {
          _selectedCategory = categories.first;
          print("No matching category found for ID: ${widget.expense.category}, using first category: ${_selectedCategory!.id} - ${_selectedCategory!.name}");
        }
      }
    }

    final indianRupees = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isIncome ? 'Edit Income' : 'Edit Expense'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Expense'),
                  content: const Text('Are you sure you want to delete this expense?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<ExpenseProvider>()
                          .deleteExpense(widget.expense.id)
                          .then((_) {
                            Navigator.pop(context); // Close dialog
                            Navigator.pop(context); // Close edit screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense deleted successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          });
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Income/Expense Switch
              SwitchListTile(
                title: const Text('Is this an income?'),
                value: _isIncome,
                onChanged: (value) {
                  setState(() {
                    _isIncome = value;
                    // Reset selected category when toggling between income/expense
                    _selectedCategory = null;
                  });
                },
              ),

              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  helperText: 'Enter amount in Indian Rupees',
                  prefixText: '₹ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value.replaceAll(',', '')) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              categories.isEmpty
                ? Card(
                    color: Colors.amber[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No ${_isIncome ? 'income' : 'expense'} categories available',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You need at least one category to continue. Try creating a category first.',
                          ),
                        ],
                      ),
                    ),
                  )
                : DropdownButtonFormField<ExpenseCategory>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Row(
                                children: [
                                  Icon(category.icon, color: category.color),
                                  const SizedBox(width: 8),
                                  Text(category.name),
                                ],
                              ),
                            ))
                        .toList(),
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                    onChanged: (category) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
              const SizedBox(height: 16),

              // Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                ),
                onTap: _selectDate,
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: categories.isEmpty ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Update',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 