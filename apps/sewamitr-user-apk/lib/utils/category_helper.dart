import 'package:flutter/material.dart';

class CategoryHelper {
  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Colors.orange;
      case 'water':
        return Colors.blue;
      case 'electricity':
        return Colors.amber;
      case 'garbage':
        return Colors.green;
      case 'others':
      default:
        return Colors.grey;
    }
  }

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'road':
        return Icons.add_road;
      case 'water':
        return Icons.water_drop;
      case 'electricity':
        return Icons.electric_bolt;
      case 'garbage':
        return Icons.delete_outline;
      case 'others':
      default:
        return Icons.more_horiz;
    }
  }

  static List<String> get categories => [
    'road',
    'water',
    'electricity',
    'garbage',
    'others',
  ];
}
