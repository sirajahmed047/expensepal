import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double? budget;
  final String userId;
  final bool isDefault;
  final bool isIncome;

  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.budget,
    required this.userId,
    this.isDefault = false,
    this.isIncome = false,
  });

  // Convert Category to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': color.value,
      'budget': budget,
      'userId': userId,
      'isDefault': isDefault,
      'isIncome': isIncome,
    };
  }

  // Create Category from Firestore Map
  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: IconData(
        map['iconCodePoint'] as int,
        fontFamily: map['iconFontFamily'] as String,
      ),
      color: Color(map['colorValue'] as int),
      budget: map['budget'] as double?,
      userId: map['userId'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
      isIncome: map['isIncome'] as bool? ?? false,
    );
  }

  // Default categories
  static List<ExpenseCategory> defaultCategories(String userId) {
    // Expense categories
    final expenseCategories = [
      ExpenseCategory(
        id: 'food_dining',
        name: 'Food & Dining',
        icon: Icons.restaurant,
        color: Colors.orange,
        userId: userId,
        isDefault: true,
        isIncome: false,
      ),
      ExpenseCategory(
        id: 'transportation',
        name: 'Transportation',
        icon: Icons.directions_car,
        color: Colors.blue,
        userId: userId,
        isDefault: true,
        isIncome: false,
      ),
      ExpenseCategory(
        id: 'shopping',
        name: 'Shopping',
        icon: Icons.shopping_bag,
        color: Colors.purple,
        userId: userId,
        isDefault: true,
        isIncome: false,
      ),
      ExpenseCategory(
        id: 'bills',
        name: 'Bills & Utilities',
        icon: Icons.receipt_long,
        color: Colors.red,
        userId: userId,
        isDefault: true,
        isIncome: false,
      ),
      ExpenseCategory(
        id: 'entertainment',
        name: 'Entertainment',
        icon: Icons.movie,
        color: Colors.pink,
        userId: userId,
        isDefault: true,
        isIncome: false,
      ),
      ExpenseCategory(
        id: 'health',
        name: 'Health',
        icon: Icons.medical_services,
        color: Colors.green,
        userId: userId,
        isDefault: true,
        isIncome: false,
      ),
    ];
    
    // Income categories
    final incomeCategories = [
      ExpenseCategory(
        id: 'salary',
        name: 'Salary',
        icon: Icons.account_balance_wallet,
        color: Colors.green,
        userId: userId,
        isDefault: true,
        isIncome: true,
      ),
      ExpenseCategory(
        id: 'bonus',
        name: 'Bonus',
        icon: Icons.card_giftcard,
        color: Colors.amber,
        userId: userId,
        isDefault: true,
        isIncome: true,
      ),
      ExpenseCategory(
        id: 'rent',
        name: 'Rent',
        icon: Icons.home,
        color: Colors.blue,
        userId: userId,
        isDefault: true,
        isIncome: true,
      ),
      ExpenseCategory(
        id: 'investment',
        name: 'Investment',
        icon: Icons.trending_up,
        color: Colors.purple,
        userId: userId,
        isDefault: true,
        isIncome: true,
      ),
      ExpenseCategory(
        id: 'other_income',
        name: 'Other Income',
        icon: Icons.attach_money,
        color: Colors.teal,
        userId: userId,
        isDefault: true,
        isIncome: true,
      ),
    ];
    
    return [...expenseCategories, ...incomeCategories];
  }

  // Create a copy of Category with some changes
  ExpenseCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    double? budget,
    String? userId,
    bool? isDefault,
    bool? isIncome,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      budget: budget ?? this.budget,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      isIncome: isIncome ?? this.isIncome,
    );
  }
} 