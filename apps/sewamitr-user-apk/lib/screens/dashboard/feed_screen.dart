import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';
import '../../services/location_service.dart';
import '../../services/issue_service.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../models/issue_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_helper.dart';
import '../../utils/animations.dart';
import '../../widgets/osm_feed_map.dart';
import 'comments_bottom_sheet.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<IssueModel> _issues = [];
  Set<String> _votedIssues = <String>{};
  bool _isLoading = true;
  String? _currentLocation;
  double? _currentLat;
  double? _currentLng;
  String _selectedSort = 'New';
  final Set<String> _selectedCategories = <String>{};
  bool _showMap = true;
  bool _showHeatmap = false;
  final double _radiusKm = 5.0;
  final Map<String, int> _commentCounts = {};

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _loadIssues();
    _loadUserVotes();
  }

  Future<void> _loadIssues() async {
    try {
      final issues = await IssueService().getAllIssues();
      
      for (var issue in issues) {
        if (issue.id != null) {
          final count = await IssueService().getCommentCount(issue.id!);
          _commentCounts[issue.id!] = count;
        }
      }

      if (mounted) {
        setState(() {
          _issues = issues;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    try {
      final location = await LocationService().getCurrentLocation();
      final address = await LocationService().getAddressFromCoordinates(location.latitude, location.longitude);
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

  Future<void> _loadUserVotes() async {
    try {
      final authService = context.read<AuthService>();
      if (authService.currentUser == null) return;
      
      final votes = await IssueService().getUserVotes(authService.currentUser!.id);
      if (mounted) {
        setState(() => _votedIssues = votes);
      }
    } catch (e) {}
  }

  List<IssueModel>? _cachedFilteredIssues;
  String? _lastFilterKey;

  List<IssueModel> get _filteredIssues {
    // Create a key based on current filter state
    final filterKey = '$_selectedSort|${_selectedCategories.join(',')}|${_currentLat}_${_currentLng}|${_issues.length}';
    
    // Return cached result if filter hasn't changed
    if (_lastFilterKey == filterKey && _cachedFilteredIssues != null) {
      return _cachedFilteredIssues!;
    }
    
    List<IssueModel> filtered = _issues;
    
    if (_currentLat != null && _currentLng != null) {
      filtered = _issues.where((issue) {
        final distance = _calculateDistance(_currentLat!, _currentLng!, issue.latitude, issue.longitude);
        return distance <= _radiusKm;
      }).toList();
    }

    if (_selectedCategories.isNotEmpty) {
      filtered = filtered.where((issue) => _selectedCategories.contains(issue.category.toLowerCase())).toList();
    }

    switch (_selectedSort) {
      case 'Trending':
        // Trending: Show issues with >5 upvotes, sorted by highest votes
        filtered = filtered.where((issue) => issue.upvotes > 5).toList();
        filtered.sort((a, b) => b.upvotes.compareTo(a.upvotes));
        break;
      case 'Highest Priority':
        // Highest Priority: Sort by newest first (not by votes)
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'New':
        final now = DateTime.now();
        filtered = filtered.where((issue) => now.difference(issue.createdAt).inDays <= 1).toList();
        break;
      case 'All Issues':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    
    // Cache the result
    _cachedFilteredIssues = filtered;
    _lastFilterKey = filterKey;
    
    return filtered;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) + cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  Future<void> _shareIssue(IssueModel issue) async {
    final languageService = context.read<LanguageService>();
    final statusEmoji = issue.status == 'resolved' ? '✅' : issue.status == 'in_progress' ? '🚧' : '🆕';
    final shareText = '$statusEmoji *${languageService.translate('civic_issue_reporting_platform')}*\n\n📍 *${languageService.translate('location')}:* ${issue.address}\n🏷️ *${languageService.translate('category')}:* ${issue.category}\n📝 *${languageService.translate('description')}:* ${issue.description}\n👍 *${languageService.translate('upvotes')}:* ${issue.upvotes}\n\n${languageService.translate('help_improve_your_community')}!\n#SewaMitr #CivicIssue #${issue.category.replaceAll(' ', '')}';
    await Share.share(shareText);
  }

  Future<void> _handleUpvote(IssueModel issue) async {
    if (_votedIssues.contains(issue.id)) return;
    
    final authService = context.read<AuthService>();
    
    // Optimistic UI update - update immediately for instant feedback
    setState(() {
      _votedIssues.add(issue.id!);
      // Find and update the issue in the list
      final index = _issues.indexWhere((i) => i.id == issue.id);
      if (index != -1) {
        _issues[index] = IssueModel(
          id: _issues[index].id,
          userId: _issues[index].userId,
          category: _issues[index].category,
          description: _issues[index].description,
          address: _issues[index].address,
          latitude: _issues[index].latitude,
          longitude: _issues[index].longitude,
          mediaUrls: _issues[index].mediaUrls,
          audioUrl: _issues[index].audioUrl,
          audioDescription: _issues[index].audioDescription,
          status: _issues[index].status,
          upvotes: _issues[index].upvotes + 1, // Increment locally
          assignedTo: _issues[index].assignedTo,
          createdAt: _issues[index].createdAt,
          updatedAt: _issues[index].updatedAt,
          progress: _issues[index].progress,
          completedAt: _issues[index].completedAt,
        );
      }
    });
    
    // Make API call in background
    final success = await IssueService().upvoteIssue(issue.id.toString(), authService.currentUser!.id);
    
    // If failed, revert the optimistic update
    if (!success) {
      setState(() {
        _votedIssues.remove(issue.id);
        final index = _issues.indexWhere((i) => i.id == issue.id);
        if (index != -1) {
          _issues[index] = IssueModel(
            id: _issues[index].id,
            userId: _issues[index].userId,
            category: _issues[index].category,
            description: _issues[index].description,
            address: _issues[index].address,
            latitude: _issues[index].latitude,
            longitude: _issues[index].longitude,
            mediaUrls: _issues[index].mediaUrls,
            audioUrl: _issues[index].audioUrl,
            audioDescription: _issues[index].audioDescription,
            status: _issues[index].status,
            upvotes: _issues[index].upvotes - 1, // Revert
            assignedTo: _issues[index].assignedTo,
            createdAt: _issues[index].createdAt,
            updatedAt: _issues[index].updatedAt,
            progress: _issues[index].progress,
            completedAt: _issues[index].completedAt,
          );
        }
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Filters', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('Sort By', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Nearby', 'Trending', 'Highest Priority', 'New', 'All Issues'].map((sort) {
                    final isSelected = _selectedSort == sort;
                    return FilterChip(
                      label: Text(sort),
                      selected: isSelected,
                      onSelected: (selected) => setModalState(() => _selectedSort = sort),
                      backgroundColor: Colors.grey[100],
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      labelStyle: TextStyle(color: isSelected ? AppTheme.primary : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                      checkmarkColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primary : Colors.transparent)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text('Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['road', 'water', 'electricity', 'garbage', 'others'].map((cat) {
                        final isSelected = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CategoryHelper.getCategoryIcon(cat), size: 16, color: isSelected ? AppTheme.primary : Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(cat.toUpperCase().replaceAll('_', ' ')),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                _selectedCategories.add(cat);
                              } else {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(color: isSelected ? AppTheme.primary : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          checkmarkColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppTheme.primary : Colors.transparent)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedSort = 'Nearby';
                            _selectedCategories.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
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
                      decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(languageService.translate('community_feed'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(_currentLocation ?? 'Loading...', style: const TextStyle(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
            actions: [
              if (_showMap) IconButton(icon: Icon(_showHeatmap ? Icons.layers : Icons.layers_outlined, color: _showHeatmap ? Colors.orange : Colors.white), onPressed: () => setState(() => _showHeatmap = !_showHeatmap)),
              IconButton(icon: Icon(_showMap ? Icons.list : Icons.map, color: _showMap ? AppTheme.primary : Colors.white), onPressed: () => setState(() => _showMap = !_showMap)),
            ],
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: AppTheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Filter Issues', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('$_selectedSort${_selectedCategories.isNotEmpty ? " • ${_selectedCategories.length} categories" : ""}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${_filteredIssues.length} ${languageService.translate('issues_nearby')}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[800])),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_filteredIssues.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feed_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('No issues found nearby', style: TextStyle(color: Colors.grey[500])),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final issue = _filteredIssues[index];
                  return FadeInSlide(delay: index * 0.1, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _buildFeedCard(issue)));
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
        ? Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator()))
        : OSMFeedMap(issues: _filteredIssues, showHeatmap: _showHeatmap, userLocation: LatLng(_currentLat!, _currentLng!));
  }

  Widget _buildFeedCard(IssueModel issue) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (issue.mediaUrls.isNotEmpty)
            Stack(
              children: [
                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: Image.network(issue.mediaUrls.first, height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 200, color: Colors.grey[100], child: Icon(Icons.image_not_supported, color: Colors.grey[400])))),
                Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: _getStatusColor(issue.status), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5)), child: Text(issue.status.toUpperCase().replaceAll('_', ' '), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)))),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: CategoryHelper.getCategoryColor(issue.category).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(issue.category.toUpperCase(), style: TextStyle(color: CategoryHelper.getCategoryColor(issue.category), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1))),
                    const Spacer(),
                    Text(_formatDate(issue.createdAt), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(issue.description, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(issue.address, style: TextStyle(color: Colors.grey[500], fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton(icon: _votedIssues.contains(issue.id) ? Icons.thumb_up : Icons.thumb_up_outlined, label: '${issue.upvotes}', color: _votedIssues.contains(issue.id) ? AppTheme.primary : Colors.grey[600], onTap: () => _handleUpvote(issue)),
                    _buildActionButton(icon: Icons.comment_outlined, label: '${_commentCounts[issue.id] ?? 0}', color: Colors.grey[600], onTap: () {
                      showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => CommentsBottomSheet(issue: issue)).then((_) async {
                        final count = await IssueService().getCommentCount(issue.id!);
                        setState(() => _commentCounts[issue.id!] = count);
                      });
                    }),
                    _buildActionButton(icon: Icons.share_outlined, label: 'Share', color: Colors.grey[600], onTap: () => _shareIssue(issue)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color? color, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14))]));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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
