import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Categories {
  static const List<Category> defaults = [
    Category(
      id: 'food',
      name: 'Food',
      icon: Icons.restaurant,
      color: Colors.orange,
    ),
    Category(
      id: 'transport',
      name: 'Transport',
      icon: Icons.directions_bus,
      color: Colors.blue,
    ),
    Category(
      id: 'entertainment',
      name: 'Entertainment',
      icon: Icons.movie,
      color: Colors.purple,
    ),
    Category(
      id: 'shopping',
      name: 'Shopping',
      icon: Icons.shopping_bag,
      color: Colors.pink,
    ),
    Category(
      id: 'utilities',
      name: 'Utilities',
      icon: Icons.bolt,
      color: Colors.yellow,
    ),
    Category(
      id: 'accommodation',
      name: 'Accommodation',
      icon: Icons.home,
      color: Colors.green,
    ),
    Category(
      id: 'other',
      name: 'Other',
      icon: Icons.more_horiz,
      color: Colors.grey,
    ),
  ];

  static Category getById(String? id) {
    if (id == null) return defaults.last; // Default to 'Other' if null, or maybe we want a specific 'Uncategorized'?
    // Actually, distinct handling for 'Uncategorized' might be better, but for now fallback to Other or find match.
    return defaults.firstWhere(
      (c) => c.id == id,
      orElse: () => defaults.last,
    );
  }
}
