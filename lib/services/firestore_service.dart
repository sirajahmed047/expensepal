import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/budget.dart';

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _expensesCollection => _firestore.collection('expenses');
  CollectionReference get _categoriesCollection => _firestore.collection('categories');
  CollectionReference get _budgetsCollection => _firestore.collection('user_budgets');

  // Get user's expenses
  Stream<List<Expense>> getExpenses() {
    final userId = _auth.currentUser?.uid;
    print("Current user ID: $userId");
    
    if (userId == null) {
      print("No user logged in, returning empty expenses list");
      return Stream.value([]);
    }

    print("Attempting to fetch expenses for user: $userId");
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      print("Expenses snapshot received, documents count: ${snapshot.docs.length}");
      final expenses = snapshot.docs.map((doc) {
        // Get expense data
        final data = doc.data() as Map<String, dynamic>;
        
        // If the ID in the data isn't set or doesn't match the document ID,
        // make sure we use the document ID
        if (data['id'] == null || data['id'] == '' || data['id'] != doc.id) {
          data['id'] = doc.id;
        }
        
        return Expense.fromMap(data);
      }).toList();
      
      print("Processed ${expenses.length} expenses");
      return expenses;
    });
  }

  // Add an expense
  Future<void> addExpense(Expense expense) async {
    print("Adding expense: ${expense.title} (${expense.amount})");
    // Create a document reference first to get the ID
    final docRef = _expensesCollection.doc();
    
    // Create an updated expense with the document ID
    final updatedExpense = expense.copyWith(id: docRef.id);
    
    // Save the expense with the correct ID
    await docRef.set(updatedExpense.toMap());
    print("Expense added successfully with ID: ${docRef.id}");
  }

  // Update an expense
  Future<void> updateExpense(Expense expense) async {
    if (expense.id.isEmpty) {
      print("Error: Attempting to update expense with empty ID");
      throw Exception("Cannot update expense with empty ID");
    }
    
    print("Updating expense: ${expense.id} - ${expense.title}");
    await _expensesCollection.doc(expense.id).update(expense.toMap());
    print("Expense updated successfully");
  }

  // Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    if (expenseId.isEmpty) {
      print("Error: Attempting to delete expense with empty ID");
      throw Exception("Cannot delete expense with empty ID");
    }
    
    print("Deleting expense: $expenseId");
    await _expensesCollection.doc(expenseId).delete();
    print("Expense deleted successfully");
  }

  // Get user's categories
  Stream<List<ExpenseCategory>> getCategories() {
    final userId = _auth.currentUser?.uid;
    print("Getting categories for user ID: $userId");
    
    if (userId == null) {
      print("No user logged in, returning empty categories list");
      return Stream.value([]);
    }

    print("Attempting to fetch categories for user: $userId");
    return _categoriesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      print("Categories snapshot received, documents count: ${snapshot.docs.length}");
      final categories = snapshot.docs
          .map((doc) => ExpenseCategory.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      if (categories.isEmpty) {
        print("No categories found, creating default categories");
        // If no categories exist, create default ones
        final defaultCategories = ExpenseCategory.defaultCategories(userId);
        for (var category in defaultCategories) {
          addCategory(category);
        }
        return defaultCategories;
      } else {
        // Check if we have income categories
        final hasIncomeCategories = categories.any((category) => category.isIncome);
        final hasExpenseCategories = categories.any((category) => !category.isIncome);
        
        if (!hasIncomeCategories || !hasExpenseCategories) {
          print("Missing income or expense categories, adding default ones");
          final defaultCategories = ExpenseCategory.defaultCategories(userId);
          
          if (!hasIncomeCategories) {
            print("Adding default income categories");
            final incomeCategories = defaultCategories.where((c) => c.isIncome).toList();
            for (var category in incomeCategories) {
              addCategory(category);
            }
            categories.addAll(incomeCategories);
          }
          
          if (!hasExpenseCategories) {
            print("Adding default expense categories");
            final expenseCategories = defaultCategories.where((c) => !c.isIncome).toList();
            for (var category in expenseCategories) {
              addCategory(category);
            }
            categories.addAll(expenseCategories);
          }
        }
      }

      print("Processed ${categories.length} categories");
      return categories;
    });
  }

  // Add a category
  Future<void> addCategory(ExpenseCategory category) async {
    print("Adding category: ${category.name} (isIncome: ${category.isIncome})");
    // Use the category ID as the document ID to avoid duplicates
    await _categoriesCollection.doc(category.id).set(category.toMap());
    print("Category added successfully");
  }

  // Update a category
  Future<void> updateCategory(ExpenseCategory category) async {
    print("Updating category: ${category.id} - ${category.name} (isIncome: ${category.isIncome})");
    await _categoriesCollection.doc(category.id).update(category.toMap());
    print("Category updated successfully");
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    print("Deleting category: $categoryId");
    await _categoriesCollection.doc(categoryId).delete();
    print("Category deleted successfully");
  }

  // Get monthly expenses by category
  Stream<Map<String, double>> getMonthlyExpensesByCategory(DateTime month) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({});
    }
    
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    
    print("Getting monthly expenses for ${startOfMonth.toString()} to ${endOfMonth.toString()}");
    
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .where('isIncome', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      Map<String, double> categoryTotals = {};
      
      for (var doc in snapshot.docs) {
        final expense = Expense.fromMap(doc.data() as Map<String, dynamic>);
        categoryTotals[expense.category] = 
            (categoryTotals[expense.category] ?? 0) + expense.amount;
      }
      
      print("Processed monthly expense totals: $categoryTotals");
      return categoryTotals;
    });
  }
  
  // Get total balance (income - expenses)
  Stream<double> getTotalBalance() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0.0);
    }
    
    print("Calculating total balance for user: $userId");
    
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      double totalIncome = 0.0;
      double totalExpense = 0.0;
      
      for (var doc in snapshot.docs) {
        final expense = Expense.fromMap(doc.data() as Map<String, dynamic>);
        if (expense.isIncome) {
          totalIncome += expense.amount;
        } else {
          totalExpense += expense.amount;
        }
      }
      
      final balance = totalIncome - totalExpense;
      print("Total balance: Income($totalIncome) - Expenses($totalExpense) = $balance");
      return balance;
    });
  }

  // Budget related methods
  
  // Get budget for a specific month
  Stream<Budget?> getBudget(int year, int month) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(null);
    }
    
    final budgetId = Budget.createBudgetId(year, month);
    print("Getting budget for ${year}-${month} (ID: $budgetId)");
    
    return _budgetsCollection
        .doc(budgetId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            print("No budget found for $budgetId");
            return null;
          }
          
          final data = snapshot.data() as Map<String, dynamic>;
          // Check if this budget belongs to the current user
          if (data['userId'] != userId) {
            print("Budget exists but belongs to a different user");
            return null;
          }
          
          print("Budget found for $budgetId");
          return Budget.fromMap(data);
        });
  }
  
  // Create or update a budget
  Future<void> saveBudget(Budget budget) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("No user logged in");
    }
    
    if (budget.userId != userId) {
      throw Exception("Cannot save budget for a different user");
    }
    
    print("Saving budget to Firestore:");
    print("ID: ${budget.id}");
    print("Total Budget: ${budget.totalBudget}");
    print("Is Category Based: ${budget.isCategoryBased}");
    print("Category Budgets: ${budget.categoryBudgets}");
    
    try {
      await _budgetsCollection.doc(budget.id).set(budget.toMap());
      print("Budget saved successfully to Firestore");
      
      // Verify the save by reading it back
      final docRef = await _budgetsCollection.doc(budget.id).get();
      if (docRef.exists) {
        final data = docRef.data() as Map<String, dynamic>;
        print("Verified saved data:");
        print("Total Budget: ${data['totalBudget']}");
        print("Is Category Based: ${data['isCategoryBased']}");
        print("Category Budgets: ${data['categoryBudgets']}");
      }
    } catch (e) {
      print("Error saving budget to Firestore: $e");
      throw e;
    }
  }
  
  // Delete a budget
  Future<void> deleteBudget(String budgetId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception("No user logged in");
    }
    
    print("Deleting budget: $budgetId");
    
    // First check if the budget belongs to the current user
    final budgetDoc = await _budgetsCollection.doc(budgetId).get();
    if (!budgetDoc.exists) {
      throw Exception("Budget does not exist");
    }
    
    final budgetData = budgetDoc.data() as Map<String, dynamic>;
    if (budgetData['userId'] != userId) {
      throw Exception("Cannot delete budget that belongs to a different user");
    }
    
    await _budgetsCollection.doc(budgetId).delete();
    print("Budget deleted successfully");
  }
  
  // Get all budgets for the current user
  Stream<List<Budget>> getUserBudgets() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    
    print("Getting all budgets for user: $userId");
    
    return _budgetsCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final budgets = snapshot.docs
              .map((doc) => Budget.fromMap(doc.data() as Map<String, dynamic>))
              .toList();
          
          print("Found ${budgets.length} budgets for user");
          return budgets;
        });
  }
  
  // Get monthly spending for budget calculations
  Stream<Map<String, double>> getMonthlySpending(int year, int month) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value({});
    }
    
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);
    
    print("Getting monthly spending for ${startOfMonth.toString()} to ${endOfMonth.toString()}");
    
    return _expensesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfMonth.toIso8601String())
        .where('isIncome', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          Map<String, double> categorySpending = {};
          double totalSpending = 0.0;
          
          for (var doc in snapshot.docs) {
            final expense = Expense.fromMap(doc.data() as Map<String, dynamic>);
            final expenseDate = expense.date;
            
            // Ensure the expense date is within the month range (additional validation)
            if (expenseDate.isAfter(startOfMonth.subtract(const Duration(seconds: 1))) && 
                expenseDate.isBefore(endOfMonth.add(const Duration(seconds: 1)))) {
              categorySpending[expense.category] = 
                  (categorySpending[expense.category] ?? 0) + expense.amount;
              totalSpending += expense.amount;
            }
          }
          
          // Add total spending with a special key
          categorySpending['__total__'] = totalSpending;
          
          print("Processed monthly spending totals: $categorySpending");
          return categorySpending;
        });
  }
} 