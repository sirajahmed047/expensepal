import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../providers/expense_provider.dart';
import 'edit_expense_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool? _isIncome;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final expenses = context.watch<ExpenseProvider>().expenses;
    final categories = context.watch<ExpenseProvider>().categories;

    // Apply filters
    final filteredExpenses = expenses.where((expense) {
      // Search query filter
      if (_searchQuery.isNotEmpty &&
          !expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !(expense.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)) {
        return false;
      }

      // Category filter
      if (_selectedCategory != null && expense.category != _selectedCategory) {
        return false;
      }

      // Income/Expense filter
      if (_isIncome != null && expense.isIncome != _isIncome) {
        return false;
      }

      // Date range filter
      if (_startDate != null &&
          expense.date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null &&
          expense.date.isAfter(_endDate!.add(const Duration(days: 1)))) {
        return false;
      }

      return true;
    }).toList();

    // Sort by date (most recent first)
    filteredExpenses.sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search transactions',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Category filter
                DropdownButton<String?>(
                  value: _selectedCategory,
                  hint: const Text('All Categories'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        )),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value),
                ),
                const SizedBox(width: 16),

                // Income/Expense filter
                DropdownButton<bool?>(
                  value: _isIncome,
                  hint: const Text('All Types'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Types'),
                    ),
                    DropdownMenuItem(
                      value: true,
                      child: Text('Income'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Expense'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _isIncome = value),
                ),
                const SizedBox(width: 16),

                // Date range filter
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    _startDate == null
                        ? 'Select Date Range'
                        : '${DateFormat('MMM d').format(_startDate!)} - ${_endDate == null ? 'Now' : DateFormat('MMM d').format(_endDate!)}',
                  ),
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: _startDate != null && _endDate != null
                          ? DateTimeRange(start: _startDate!, end: _endDate!)
                          : null,
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                    }
                  },
                ),
                if (_startDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                  ),
              ],
            ),
          ),

          // Clear filters button
          if (_searchQuery.isNotEmpty ||
              _selectedCategory != null ||
              _isIncome != null ||
              _startDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Clear Filters'),
                    onPressed: () => setState(() {
                      _searchQuery = '';
                      _selectedCategory = null;
                      _isIncome = null;
                      _startDate = null;
                      _endDate = null;
                    }),
                  ),
                ],
              ),
            ),

          // Transactions list
          Expanded(
            child: filteredExpenses.isEmpty
                ? const Center(
                    child: Text('No transactions found'),
                  )
                : ListView.builder(
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      final category = categories.firstWhere(
                        (c) => c.id == expense.category,
                        orElse: () => categories.first,
                      );

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: category.color.withOpacity(0.1),
                            child: Icon(category.icon, color: category.color),
                          ),
                          title: Text(expense.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category.name),
                              if (expense.description?.isNotEmpty ?? false)
                                Text(
                                  expense.description!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat.currency(
                                  locale: 'en_IN',
                                  symbol: '₹',
                                ).format(expense.amount),
                                style: TextStyle(
                                  color: expense.isIncome ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, y').format(expense.date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditExpenseScreen(expense: expense),
                              ),
                            );
                          },
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