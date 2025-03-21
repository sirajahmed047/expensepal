import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../models/budget.dart';
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _totalBudgetController = TextEditingController();
  final Map<String, TextEditingController> _categoryControllers = {};
  
  // Form state
  bool _isCategoryBased = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
      
      // Initialize controllers for all expense categories
      for (var category in expenseProvider.categories.where((c) => !c.isIncome)) {
        _categoryControllers[category.id] = TextEditingController();
      }
      
      // Set initial values from existing budget if available
      if (budgetProvider.currentBudget != null) {
        final budget = budgetProvider.currentBudget!;
        setState(() {
          _isCategoryBased = budget.isCategoryBased;
        });
        
        _totalBudgetController.text = budget.totalBudget > 0 
            ? budget.totalBudget.toString() 
            : '';
            
        // Set category budget values
        budget.categoryBudgets.forEach((categoryId, amount) {
          if (_categoryControllers.containsKey(categoryId) && amount > 0) {
            _categoryControllers[categoryId]!.text = amount.toString();
          }
        });
      }
    });
  }
  
  @override
  void dispose() {
    _totalBudgetController.dispose();
    for (var controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
  
  // Save the budget
  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
    
    // Get total budget amount
    double totalBudget = 0;
    if (_totalBudgetController.text.isNotEmpty) {
      totalBudget = double.parse(_totalBudgetController.text);
    }
    
    // Get category budgets
    Map<String, double> categoryBudgets = {};
    if (_isCategoryBased) {
      _categoryControllers.forEach((categoryId, controller) {
        if (controller.text.isNotEmpty) {
          final budget = double.parse(controller.text);
          if (budget > 0) {
            categoryBudgets[categoryId] = budget;
          }
        }
      });
      
      // Debug information
      print("Category budgets to save:");
      categoryBudgets.forEach((key, value) {
        print("Category ID: $key, Budget: $value");
      });
    }
    
    // Save budget
    await budgetProvider.saveBudget(
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets,
      isCategoryBased: _isCategoryBased,
    );
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final budgetProvider = Provider.of<BudgetProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Settings'),
        actions: [
          if (budgetProvider.currentBudget != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Budget'),
                    content: Text('Are you sure you want to delete the budget for ${budgetProvider.selectedMonthFormatted}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  await budgetProvider.deleteBudget();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Budget deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: budgetProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month selector
                  _buildMonthSelector(budgetProvider),
                  
                  // Budget type toggle
                  _buildBudgetTypeToggle(),
                  
                  // Main budget form content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total budget field
                          _buildTotalBudgetField(),
                          
                          const SizedBox(height: 24),
                          
                          // Category-based budget fields
                          if (_isCategoryBased)
                            _buildCategoryBudgets(expenseProvider.categories.where((c) => !c.isIncome).toList()),
                          
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  
                  // Display current spending vs budget if budget exists
                  if (budgetProvider.currentBudget != null)
                    _buildBudgetProgress(budgetProvider),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveBudget,
        icon: const Icon(Icons.save),
        label: const Text('Save Budget'),
      ),
    );
  }
  
  // Month selector widget
  Widget _buildMonthSelector(BudgetProvider budgetProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: budgetProvider.previousMonth,
          ),
          Text(
            budgetProvider.selectedMonthFormatted,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: budgetProvider.nextMonth,
          ),
        ],
      ),
    );
  }
  
  // Budget type toggle widget
  Widget _buildBudgetTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Budget Type:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 8),
          Text('Total Only'),
          Switch(
            value: _isCategoryBased,
            onChanged: (value) {
              setState(() {
                _isCategoryBased = value;
              });
            },
          ),
          Text('Category Based'),
        ],
      ),
    );
  }
  
  // Total budget input field
  Widget _buildTotalBudgetField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Monthly Budget',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _totalBudgetController,
          decoration: InputDecoration(
            prefixText: '₹ ',
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          validator: (value) {
            if (!_isCategoryBased && (value == null || value.isEmpty)) {
              return 'Please enter a total budget amount';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  // Category budgets list
  Widget _buildCategoryBudgets(List<ExpenseCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Budgets',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return _buildCategoryBudgetItem(category);
          },
        ),
      ],
    );
  }
  
  // Individual category budget item
  Widget _buildCategoryBudgetItem(ExpenseCategory category) {
    final controller = _categoryControllers[category.id] ?? TextEditingController();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // Category icon and name
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: category.color,
                  child: Icon(category.icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          // Budget amount input
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: '0.00',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Budget progress section
  Widget _buildBudgetProgress(BudgetProvider budgetProvider) {
    if (budgetProvider.currentBudget == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Spending',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Budget:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      BudgetProvider.formatCurrency(budgetProvider.currentBudget!.totalBudget),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      BudgetProvider.formatCurrency(budgetProvider.totalSpending),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: budgetProvider.totalSpending > budgetProvider.currentBudget!.totalBudget
                            ? Colors.red
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: budgetProvider.totalBudgetProgress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation(
              budgetProvider.totalBudgetProgress >= 1.0
                  ? Colors.red
                  : budgetProvider.totalBudgetProgress >= 0.9
                      ? Colors.orange
                      : Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(budgetProvider.totalBudgetProgress * 100).toStringAsFixed(1)}% of budget used',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          
          // Show category budget progress if it's a category-based budget
          if (budgetProvider.currentBudget!.isCategoryBased && 
              budgetProvider.currentBudget!.categoryBudgets.isNotEmpty)
            _buildCategoryBudgetProgress(budgetProvider),
        ],
      ),
    );
  }
  
  // Category budget progress indicators
  Widget _buildCategoryBudgetProgress(BudgetProvider budgetProvider) {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final categoryBudgets = budgetProvider.currentBudget!.categoryBudgets;
    
    // Get categories that have budgets set
    final categoriesWithBudget = expenseProvider.categories
        .where((category) => !category.isIncome && categoryBudgets.containsKey(category.id))
        .toList();
    
    if (categoriesWithBudget.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Category Budget Progress',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categoriesWithBudget.length,
          itemBuilder: (context, index) {
            final category = categoriesWithBudget[index];
            final budget = categoryBudgets[category.id] ?? 0.0;
            final spending = budgetProvider.getCategorySpending(category.id);
            final progress = budget > 0 ? (spending / budget).clamp(0.0, 1.0) : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: category.color,
                        child: Icon(category.icon, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${BudgetProvider.formatCurrency(spending)} / ${BudgetProvider.formatCurrency(budget)}',
                        style: TextStyle(
                          color: progress >= 1.0 ? Colors.red : null,
                          fontWeight: progress >= 1.0 ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation(
                      progress >= 1.0
                          ? Colors.red
                          : progress >= 0.9
                              ? Colors.orange
                              : category.color,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
} 