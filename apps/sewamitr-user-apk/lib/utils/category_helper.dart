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
      case 'street_light':
        return Colors.purple;
      case 'drainage':
        return Colors.brown;
      case 'park':
        return Colors.lightGreen;
      case 'traffic':
        return Colors.red;
      case 'noise':
        return Colors.deepOrange;
      case 'other':
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
      case 'street_light':
        return Icons.lightbulb_outline;
      case 'drainage':
        return Icons.water_damage;
      case 'park':
        return Icons.park;
      case 'traffic':
        return Icons.traffic;
      case 'noise':
        return Icons.volume_up;
      case 'other':
      default:
        return Icons.more_horiz;
    }
  }
}
