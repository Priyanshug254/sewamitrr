import 'package:flutter/material.dart';
import '../models/issue_model.dart';

class FeedMapWidget extends StatelessWidget {
  final List<IssueModel> issues;
  final double? centerLat;
  final double? centerLng;

  const FeedMapWidget({
    super.key,
    required this.issues,
    this.centerLat,
    this.centerLng,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'Map view',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              '${issues.length} issues nearby',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
