import 'package:cloud_firestore/cloud_firestore.dart';

class Budget {
  final String id;
  final String userId;
  final int year;
  final int month;
  final double totalBudget;
  final Map<String, double> categoryBudgets;
  final bool isCategoryBased;

  Budget({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    required this.totalBudget,
    required this.categoryBudgets,
    required this.isCategoryBased,
  });

  // Helper to create budget ID in format 'budget_YYYY_MM'
  static String createBudgetId(int year, int month) {
    return 'budget_${year}_${month.toString().padLeft(2, '0')}';
  }

  // Convert Budget to Map for Firestore
  Map<String, dynamic> toMap() {
    // Ensure category budgets only include positive values
    final validCategoryBudgets = <String, double>{};
    categoryBudgets.forEach((key, value) {
      if (value > 0) {
        validCategoryBudgets[key] = value;
      }
    });
    
    return {
      'id': id,
      'userId': userId,
      'year': year,
      'month': month,
      'totalBudget': totalBudget,
      'categoryBudgets': validCategoryBudgets,
      'isCategoryBased': isCategoryBased,
    };
  }

  // Create Budget from Firestore Map
  factory Budget.fromMap(Map<String, dynamic> map) {
    // Convert the categoryBudgets from dynamic map to proper Map<String, double>
    Map<String, double> categoryBudgetsMap = {};
    final rawCategoryBudgets = map['categoryBudgets'] as Map<String, dynamic>?;
    
    if (rawCategoryBudgets != null) {
      rawCategoryBudgets.forEach((key, value) {
        final budget = (value is num) ? value.toDouble() : 0.0;
        if (budget > 0) {
          categoryBudgetsMap[key] = budget;
        }
      });
    }

    return Budget(
      id: map['id'] as String,
      userId: map['userId'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      totalBudget: (map['totalBudget'] is num) ? (map['totalBudget'] as num).toDouble() : 0.0,
      categoryBudgets: categoryBudgetsMap,
      isCategoryBased: map['isCategoryBased'] as bool,
    );
  }

  // Create a copy of Budget with some changes
  Budget copyWith({
    String? id,
    String? userId,
    int? year,
    int? month,
    double? totalBudget,
    Map<String, double>? categoryBudgets,
    bool? isCategoryBased,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      month: month ?? this.month,
      totalBudget: totalBudget ?? this.totalBudget,
      categoryBudgets: categoryBudgets ?? this.categoryBudgets,
      isCategoryBased: isCategoryBased ?? this.isCategoryBased,
    );
  }
  
  // Factory method to create a new budget for a specific month
  factory Budget.create({
    required String userId,
    required int year,
    required int month,
    double totalBudget = 0.0,
    Map<String, double>? categoryBudgets,
    bool isCategoryBased = false,
  }) {
    final id = createBudgetId(year, month);
    return Budget(
      id: id,
      userId: userId,
      year: year,
      month: month,
      totalBudget: totalBudget,
      categoryBudgets: categoryBudgets ?? {},
      isCategoryBased: isCategoryBased,
    );
  }
} 