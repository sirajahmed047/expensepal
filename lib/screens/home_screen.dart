import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';
import 'transaction_history_screen.dart';
import 'budget_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpensePal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ExpenseProvider>().initializeData();
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // User greeting and total balance card
              _buildBalanceCard(context),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // Monthly Overview
              _buildMonthlyOverview(context),
              const SizedBox(height: 24),

              // Recent Transactions
              _buildRecentTransactions(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final expenseProvider = context.watch<ExpenseProvider>();
    final isLoading = expenseProvider.isLoading;
    final error = expenseProvider.error;
    
    // Calculate total balance from actual expense data
    double totalIncome = 0.0;
    double totalExpense = 0.0;
    
    for (var expense in expenseProvider.expenses) {
      if (expense.isIncome) {
        totalIncome += expense.amount;
      } else {
        totalExpense += expense.amount;
      }
    }
    
    final totalBalance = totalIncome - totalExpense;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: CircularProgressIndicator(),
              ),
            )
          : error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error loading data',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        context.read<ExpenseProvider>().initializeData();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(totalBalance),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBalanceInfo(
                        context,
                        'Income',
                        totalIncome,
                        Colors.green,
                        Icons.arrow_upward,
                      ),
                      _buildBalanceInfo(
                        context,
                        'Expenses',
                        totalExpense,
                        Colors.red,
                        Icons.arrow_downward,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBalanceInfo(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            Text(
              currencyFormat.format(amount),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickActionButton(
                  context,
                  Icons.receipt_long,
                  'Bills',
                  () {
                    // Will be implemented later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!'))
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.account_balance,
                  'Bank',
                  () {
                    // Will be implemented later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!'))
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.pie_chart,
                  'Budget',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BudgetScreen(),
                      ),
                    );
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.analytics,
                  'Analytics',
                  () {
                    // Will be implemented later
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!'))
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOverview(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final categories = expenseProvider.categories;
    final expenses = expenseProvider.expenses;
    final isLoading = expenseProvider.isLoading || budgetProvider.isLoading;
    final error = expenseProvider.error ?? budgetProvider.errorMessage;
    
    // Calculate category spending
    Map<String, double> categorySpending = {};
    
    for (var category in categories) {
      categorySpending[category.id] = 0.0;
    }
    
    // Calculate current month expenses
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    for (var expense in expenses) {
      if (!expense.isIncome && 
          expense.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && 
          expense.date.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
        categorySpending[expense.category] = (categorySpending[expense.category] ?? 0) + expense.amount;
      }
    }
    
    // Get top 3 categories with spending
    final topCategories = categorySpending.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Error loading data',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context.read<ExpenseProvider>().initializeData();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : topCategories.isEmpty 
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Add expenses to see your monthly overview'),
                      ),
                    )
                  : Column(
                      children: [
                        // Total budget vs spending
                        if (budgetProvider.currentBudget != null && budgetProvider.currentBudget!.totalBudget > 0) ... [
                          _buildCategoryProgress(
                            context,
                            'Total Budget',
                            budgetProvider.totalSpending,
                            budgetProvider.currentBudget!.totalBudget,
                            Theme.of(context).primaryColor,
                            categoryId: '__total__',
                          ),
                          const Divider(height: 24),
                        ],
                        
                        // Category budgets
                        for (int i = 0; i < topCategories.length.clamp(0, 3); i++) ... [
                          _buildCategoryProgress(
                            context,
                            categories.firstWhere(
                              (c) => c.id == topCategories[i].key,
                              orElse: () => categories.first,
                            ).name,
                            topCategories[i].value,
                            _getCategoryBudget(budgetProvider, topCategories[i].key, topCategories[i].value),
                            categories.firstWhere(
                              (c) => c.id == topCategories[i].key,
                              orElse: () => categories.first,
                            ).color,
                            categoryId: topCategories[i].key,
                          ),
                          if (i < topCategories.length.clamp(0, 3) - 1)
                            const SizedBox(height: 16),
                        ],
                        
                        // Link to budget screen
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BudgetScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Manage Budgets'),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(36),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to get category budget from BudgetProvider
  double _getCategoryBudget(BudgetProvider budgetProvider, String categoryId, double fallbackValue) {
    // First check if we have a valid budget set
    if (budgetProvider.currentBudget == null) {
      return fallbackValue * 1.5; // Use fallback if no budget at all
    }
    
    // If using category-based budget, retrieve the category budget
    if (budgetProvider.currentBudget!.isCategoryBased) {
      final budget = budgetProvider.currentBudget!.categoryBudgets[categoryId] ?? 0.0;
      
      // If this specific category has a budget set, use it
      if (budget > 0) {
        return budget;
      }
    }
    
    // If not category-based or no specific category budget set, 
    // use the total budget proportionally distributed
    if (budgetProvider.currentBudget!.totalBudget > 0) {
      // Get an estimate of how much of the total budget should go to this category
      // based on spending patterns (20% of total budget as reasonable default)
      return budgetProvider.currentBudget!.totalBudget * 0.2;
    }
    
    // Last resort fallback
    return fallbackValue * 1.5;
  }

  // Add a helper method to check if a category has an actual budget set
  bool _hasCategoryBudget(BudgetProvider budgetProvider, String categoryId) {
    if (budgetProvider.currentBudget == null || !budgetProvider.currentBudget!.isCategoryBased) {
      return false;
    }
    
    final budget = budgetProvider.currentBudget!.categoryBudgets[categoryId] ?? 0.0;
    return budget > 0;
  }

  Widget _buildCategoryProgress(
    BuildContext context,
    String category,
    double spent,
    double budget,
    Color color, {
    String? categoryId,
  }) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final progress = (spent / budget).clamp(0.0, 1.0);
    final isOverBudget = spent > budget;
    
    // Check if this is using a real budget or a default value
    final budgetProvider = context.read<BudgetProvider>();
    final hasRealBudget = categoryId != null && 
        budgetProvider.currentBudget != null && 
        ((category == 'Total Budget' && budgetProvider.currentBudget!.totalBudget > 0) ||
        _hasCategoryBudget(budgetProvider, categoryId));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (!hasRealBudget && category != 'Total Budget')
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Tooltip(
                      message: 'No budget set for this category. Using an estimated budget.',
                      child: Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                if (isOverBudget)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                Text(
                  '${currencyFormat.format(spent)} / ${currencyFormat.format(budget)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverBudget ? Colors.red : Colors.grey,
                    fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            isOverBudget ? Colors.red : color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();
    final expenses = expenseProvider.expenses;
    final categories = expenseProvider.categories;
    final isLoading = expenseProvider.isLoading;
    final error = expenseProvider.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (error != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error loading transactions',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.read<ExpenseProvider>().initializeData();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (expenses.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No transactions yet'),
            ),
          )
        else
          ...expenses.take(5).map((expense) {
            final category = categories.firstWhere(
              (c) => c.id == expense.category,
              orElse: () => categories.first,
            );
            
            return _buildTransactionItem(
              context,
              expense,
              category.icon,
            );
          }).toList(),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Expense expense,
    IconData icon,
  ) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final expenseProvider = context.read<ExpenseProvider>();
    final categories = expenseProvider.categories;
    
    final category = categories.firstWhere(
      (c) => c.id == expense.category,
      orElse: () => categories.first,
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(expense.title),
        subtitle: Text(category.name),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(expense.amount),
              style: TextStyle(
                color: expense.isIncome ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('MMM d').format(expense.date),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditExpenseScreen(expense: expense),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Force refresh of data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final expenseProvider = context.read<ExpenseProvider>();
      expenseProvider.initializeData();
      
      // Ensure BudgetProvider is initialized with the current month's data
      final now = DateTime.now();
      final budgetProvider = context.read<BudgetProvider>();
      budgetProvider.fetchBudgetForMonth(DateTime(now.year, now.month));
    });
  }
} 