import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' show cos, sin, asin, sqrt;
import 'package:latlong2/latlong.dart';
import '../../services/language_service.dart';
import '../../services/issue_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../models/issue_model.dart';
import '../../widgets/osm_feed_map.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import '../../utils/category_helper.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<IssueModel> _issues = [];
  bool _isLoading = true;
  String _selectedFilter = 'Nearby';
  String? _currentLocation;
  double? _currentLat;
  double? _currentLng;
  final double _radiusKm = 1.0;
  Set<String> _votedIssues = {};
  bool _showMap = true;
  bool _showHeatmap = false;

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadIssues();
  }

  Future<void> _loadLocation() async {
    try {
      final location = await LocationService().getCurrentLocation();
      if (!mounted) return;
      final address = await LocationService().getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (!mounted) return;
      setState(() {
        _currentLat = location.latitude;
        _currentLng = location.longitude;
        _currentLocation = address;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLat = 28.6139;
        _currentLng = 77.2090;
        _currentLocation = 'Location unavailable';
      });
    }
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await IssueService().getAllIssues();
      if (!mounted) return;
      await _loadUserVotes();
      if (!mounted) return;
      setState(() {
        _issues = issues;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserVotes() async {
    try {
      final authService = context.read<AuthService>();
      if (authService.currentUser == null) return;
      
      final votes = await IssueService().getUserVotes(authService.currentUser!.id);
      if (mounted) {
        setState(() {
          _votedIssues = votes;
        });
      }
    } catch (e) {
      // Silently fail if votes table doesn't exist
    }
  }

  List<IssueModel> get _filteredIssues {
    // First filter by distance (1km radius)
    List<IssueModel> nearbyIssues = _issues;
    
    if (_currentLat != null && _currentLng != null) {
      nearbyIssues = _issues.where((issue) {
        final distance = _calculateDistance(
          _currentLat!,
          _currentLng!,
          issue.latitude,
          issue.longitude,
        );
        return distance <= _radiusKm;
      }).toList();
    }

    // Then apply additional filters
    switch (_selectedFilter) {
      case 'Trending':
        return nearbyIssues.where((issue) => issue.upvotes > 5).toList();
      case 'Highest Priority':
        return nearbyIssues.where((issue) => issue.status == 'pending').toList();
      case 'New':
        final now = DateTime.now();
        return nearbyIssues.where((issue) {
          final diff = now.difference(issue.createdAt).inDays;
          return diff <= 1;
        }).toList();
      default: // Nearby
        return nearbyIssues;
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * 3.141592653589793 / 180;
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: _showMap ? 300 : 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.background,
            flexibleSpace: FlexibleSpaceBar(
              background: _showMap
                  ? _buildMapView()
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageService.translate('community_feed'),
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _currentLocation ?? 'Loading...',
                                      style: const TextStyle(color: Colors.white70),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            actions: [
              if (_showMap)
                IconButton(
                  icon: Icon(
                    _showHeatmap ? Icons.layers : Icons.layers_outlined,
                    color: _showHeatmap ? Colors.orange : Colors.white,
                  ),
                  onPressed: () => setState(() => _showHeatmap = !_showHeatmap),
                  tooltip: _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
                ),
              IconButton(
                icon: Icon(
                  _showMap ? Icons.list : Icons.map,
                  color: _showMap ? AppTheme.primary : Colors.white,
                ),
                onPressed: () => setState(() => _showMap = !_showMap),
                tooltip: _showMap ? 'Show List' : 'Show Map',
              ),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Nearby', languageService.translate('nearby')),
                        _buildFilterChip('Trending', languageService.translate('trending')),
                        _buildFilterChip('Highest Priority', languageService.translate('highest_priority')),
                        _buildFilterChip('New', languageService.translate('new')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Feed Stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_filteredIssues.length} ${languageService.translate('issues_nearby')}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Icon(Icons.filter_list, color: Colors.grey[600]),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredIssues.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feed_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No issues found nearby',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final issue = _filteredIssues[index];
                  return FadeInSlide(
                    delay: index * 0.1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: _buildFeedCard(issue),
                    ),
                  );
                },
                childCount: _filteredIssues.length,
              ),
            ),
            
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return _isLoading || _currentLat == null || _currentLng == null
        ? Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          )
        : OSMFeedMap(
            issues: _filteredIssues,
            showHeatmap: _showHeatmap,
            userLocation: LatLng(_currentLat!, _currentLng!),
          );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ScaleButton(
        onPressed: () => setState(() => _selectedFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.primary : Colors.grey.withOpacity(0.2),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedCard(IssueModel issue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          if (issue.mediaUrls.isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    issue.mediaUrls.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[100],
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(issue.status),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: Text(
                      issue.status.toUpperCase().replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CategoryHelper.getCategoryColor(issue.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        issue.category.toUpperCase(),
                        style: TextStyle(
                          color: CategoryHelper.getCategoryColor(issue.category),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(issue.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  issue.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        issue.address,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(
                      icon: _votedIssues.contains(issue.id) ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: '${issue.upvotes}',
                      color: _votedIssues.contains(issue.id) ? AppTheme.primary : Colors.grey[600],
                      onTap: () => _handleUpvote(issue),
                    ),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      color: Colors.grey[600],
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color? color,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onPressed: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpvote(IssueModel issue) async {
    if (_votedIssues.contains(issue.id)) return;

    final authService = context.read<AuthService>();
    final success = await IssueService().upvoteIssue(
      issue.id.toString(),
      authService.currentUser!.id,
    );
    
    if (success) {
      setState(() {
        _votedIssues.add(issue.id!);
      });
      _loadIssues(); // Reload to get updated count
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}