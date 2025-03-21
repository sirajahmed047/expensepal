import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BudgetProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Budget? _currentBudget;
  DateTime _selectedMonth = DateTime.now();
  Map<String, double> _monthlySpending = {};
  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  Budget? get currentBudget => _currentBudget;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Format for display
  String get selectedMonthFormatted => DateFormat('MMMM yyyy').format(_selectedMonth);
  
  // Get spending for a specific category
  double getCategorySpending(String categoryId) {
    return _monthlySpending[categoryId] ?? 0.0;
  }
  
  // Get total spending
  double get totalSpending => _monthlySpending['__total__'] ?? 0.0;
  
  // Calculate budget progress (0.0 to 1.0)
  double getBudgetProgress(String categoryId) {
    if (_currentBudget == null) return 0.0;
    
    final spending = getCategorySpending(categoryId);
    final budget = _currentBudget!.categoryBudgets[categoryId] ?? 0.0;
    
    if (budget <= 0) return 0.0;
    return (spending / budget).clamp(0.0, 1.0);
  }
  
  // Calculate total budget progress
  double get totalBudgetProgress {
    if (_currentBudget == null || _currentBudget!.totalBudget <= 0) return 0.0;
    
    final spending = totalSpending;
    return (spending / _currentBudget!.totalBudget).clamp(0.0, 1.0);
  }
  
  // Initialize the provider with current month's budget
  void initialize(List<ExpenseCategory> categories) {
    _categories = categories;
    fetchBudgetForMonth(_selectedMonth);
  }
  
  // Change the selected month and fetch its budget
  void changeMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    fetchBudgetForMonth(newMonth);
    notifyListeners();
  }
  
  // Move to next month
  void nextMonth() {
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    changeMonth(nextMonth);
  }
  
  // Move to previous month
  void previousMonth() {
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    changeMonth(prevMonth);
  }
  
  // Fetch budget for a specific month
  Future<void> fetchBudgetForMonth(DateTime month) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      print("Fetching budget for month: ${month.year}-${month.month}");
      
      // Stream subscriptions to handle both budget and spending data
      final budgetSubscription = _firestoreService
          .getBudget(month.year, month.month)
          .listen((budget) {
            _currentBudget = budget;
            
            // Debug information
            if (budget != null) {
              print("Budget found: ${budget.id}");
              print("Total budget: ${budget.totalBudget}");
              print("Is category based: ${budget.isCategoryBased}");
              print("Category budgets: ${budget.categoryBudgets}");
            } else {
              print("No budget found for ${month.year}-${month.month}");
            }
            
            notifyListeners();
          });
          
      final spendingSubscription = _firestoreService
          .getMonthlySpending(month.year, month.month)
          .listen((spending) {
            _monthlySpending = spending;
            print("Monthly spending received: $_monthlySpending");
            notifyListeners();
          });
          
      // Clean up after 2 seconds to ensure data is loaded
      await Future.delayed(const Duration(seconds: 2));
      
      budgetSubscription.cancel();
      spendingSubscription.cancel();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Error loading budget: ${e.toString()}";
      print("Error fetching budget: $_errorMessage");
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Create or update a budget
  Future<void> saveBudget({
    required double totalBudget,
    required Map<String, double> categoryBudgets,
    required bool isCategoryBased,
  }) async {
    if (_auth.currentUser == null) {
      _errorMessage = "Must be logged in to set a budget";
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Create or update the budget
      final userId = _auth.currentUser!.uid;
      final year = _selectedMonth.year;
      final month = _selectedMonth.month;
      
      // Clean any invalid values from categoryBudgets
      final cleanCategoryBudgets = <String, double>{};
      categoryBudgets.forEach((key, value) {
        if (value > 0) {
          cleanCategoryBudgets[key] = value;
        }
      });
      
      print("Saving budget - Total: $totalBudget, Category-based: $isCategoryBased");
      print("Category budgets: $cleanCategoryBudgets");
      
      final newBudget = Budget.create(
        userId: userId,
        year: year,
        month: month,
        totalBudget: totalBudget,
        categoryBudgets: cleanCategoryBudgets,
        isCategoryBased: isCategoryBased,
      );
      
      await _firestoreService.saveBudget(newBudget);
      print("Budget saved successfully");
      
      // Refresh the data
      fetchBudgetForMonth(_selectedMonth);
    } catch (e) {
      _errorMessage = "Error saving budget: ${e.toString()}";
      print("Error saving budget: $_errorMessage");
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Delete the current budget
  Future<void> deleteBudget() async {
    if (_currentBudget == null) return;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _firestoreService.deleteBudget(_currentBudget!.id);
      _currentBudget = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = "Error deleting budget: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check if a category has a budget set
  bool hasCategoryBudget(String categoryId) {
    if (_currentBudget == null) return false;
    return _currentBudget!.categoryBudgets.containsKey(categoryId) && 
           _currentBudget!.categoryBudgets[categoryId]! > 0;
  }
  
  // Get available expense categories (non-income categories)
  List<ExpenseCategory> get expenseCategories {
    return _categories.where((category) => !category.isIncome).toList();
  }
  
  // Get formatting for Indian Rupees
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }
} 