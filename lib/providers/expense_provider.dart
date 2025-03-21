import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../services/firestore_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];
  bool _isLoading = false;
  String? _error;
  
  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get categories => _categories;
  
  // Get only expense categories
  List<ExpenseCategory> get expenseCategories {
    final result = _categories.where((category) => !category.isIncome).toList();
    print("Expense categories count: ${result.length}");
    return result;
  }
  
  // Get only income categories
  List<ExpenseCategory> get incomeCategories {
    final result = _categories.where((category) => category.isIncome).toList();
    print("Income categories count: ${result.length}");
    return result;
  }
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> initializeData() async {
    await _loadCategories();
    await _loadExpenses();
  }

  ExpenseProvider() {
    initializeData();
  }

  Future<void> _loadExpenses() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Loading expenses...');
      _firestoreService.getExpenses().listen(
        (expenses) {
          print('Expenses loaded: ${expenses.length}');
          _expenses = expenses;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          print('Error loading expenses: $error');
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Error in _loadExpenses: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCategories() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      print('Loading categories...');
      _firestoreService.getCategories().listen(
        (categories) {
          print('Categories loaded: ${categories.length}');
          print('Income categories: ${categories.where((c) => c.isIncome).length}');
          print('Expense categories: ${categories.where((c) => !c.isIncome).length}');
          _categories = categories;
          _isLoading = false;
          _error = null;
          notifyListeners();
        },
        onError: (error) {
          print('Error loading categories: $error');
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Error in _loadCategories: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      await _firestoreService.addExpense(expense);
      return;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _firestoreService.updateExpense(expense);
      return;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestoreService.deleteExpense(expenseId);
      return;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> addCategory(ExpenseCategory category) async {
    try {
      await _firestoreService.addCategory(category);
      return;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    try {
      await _firestoreService.updateCategory(category);
      return;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestoreService.deleteCategory(categoryId);
      return;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      throw e;
    }
  }
} 