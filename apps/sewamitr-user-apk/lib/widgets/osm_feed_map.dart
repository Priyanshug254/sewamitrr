import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/issue_model.dart';
import '../utils/category_helper.dart';

class OSMFeedMap extends StatelessWidget {
  final List<IssueModel> issues;
  final Function(IssueModel)? onMarkerTap;
  final bool showHeatmap;
  final LatLng? userLocation;

  const OSMFeedMap({
    super.key,
    required this.issues,
    this.onMarkerTap,
    this.showHeatmap = false,
    this.userLocation,
  });

  @override
  Widget build(BuildContext context) {
    final center = userLocation ?? 
        (issues.isNotEmpty
            ? LatLng(issues.first.latitude, issues.first.longitude)
            : const LatLng(28.6139, 77.2090));

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 11,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sewamitr.app',
        ),
        if (showHeatmap)
          ..._buildHeatmapCircles()
        else
          MarkerLayer(
            markers: [
              // User location marker
              if (userLocation != null)
                Marker(
                  point: userLocation!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
              // Issue markers
              ...issues.map((issue) {
                return Marker(
                  point: LatLng(issue.latitude, issue.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => onMarkerTap?.call(issue),
                    child: Icon(
                      Icons.location_pin,
                      color: _getCategoryColor(issue.category),
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
      ],
    );
  }

  List<Widget> _buildHeatmapCircles() {
    // Group issues by location to create density-based heatmap
    final Map<String, List<IssueModel>> groupedIssues = {};
    
    for (var issue in issues) {
      // Round to 3 decimal places to group nearby issues
      final key = '${issue.latitude.toStringAsFixed(3)},${issue.longitude.toStringAsFixed(3)}';
      groupedIssues.putIfAbsent(key, () => []).add(issue);
    }

    return groupedIssues.entries.map((entry) {
      final issueGroup = entry.value;
      final count = issueGroup.length;
      final firstIssue = issueGroup.first;
      final center = LatLng(firstIssue.latitude, firstIssue.longitude);
      
      // Calculate radius and opacity based on issue count
      final radius = (20.0 + (count * 10)).clamp(20.0, 100.0);
      final opacity = (0.3 + (count * 0.1)).clamp(0.3, 0.7);
      
      return CircleLayer(
        circles: [
          CircleMarker(
            point: center,
            radius: radius,
            useRadiusInMeter: true,
            color: _getHeatmapColor(count).withOpacity(opacity),
            borderColor: _getHeatmapColor(count),
            borderStrokeWidth: 2,
          ),
        ],
      );
    }).toList();
  }

  Color _getHeatmapColor(int count) {
    if (count >= 10) return Colors.red;
    if (count >= 5) return Colors.orange;
    if (count >= 3) return Colors.yellow;
    return Colors.green;
  }

  Color _getCategoryColor(String category) => CategoryHelper.getCategoryColor(category);
}
