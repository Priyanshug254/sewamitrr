import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/issue_model.dart';
import '../../models/issue_update_model.dart';
import '../../services/language_service.dart';
import '../../services/issue_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/category_helper.dart';
import '../../widgets/milestone_tracker.dart';
import 'comments_bottom_sheet.dart';
import 'reopen_issue_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final IssueModel issue;

  const ReportDetailScreen({super.key, required this.issue});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  List<IssueUpdateModel> _updates = [];
  bool _isLoading = true;
  int _commentCount = 0;
  bool _showAllUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final updates = await IssueService().getIssueUpdates(widget.issue.id!);
      final commentCount = await IssueService().getCommentCount(widget.issue.id!);
      
      if (!mounted) return;
      
      setState(() {
        _updates = updates;
        _commentCount = commentCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareIssue() async {
    final languageService = context.read<LanguageService>();
    final statusEmoji = widget.issue.status == 'resolved' ? '✅' : 
                       widget.issue.status == 'in_progress' ? '🚧' : '🆕';
    
    final shareText = '''
$statusEmoji *${languageService.translate('civic_issue_reporting_platform')}*

📍 *${languageService.translate('location')}:* ${widget.issue.address}
🏷️ *${languageService.translate('category')}:* ${widget.issue.category}
📝 *${languageService.translate('description')}:* ${widget.issue.description}
👍 *${languageService.translate('upvotes')}:* ${widget.issue.upvotes}

${languageService.translate('help_improve_your_community')}!
#SewaMitr #CivicIssue #${widget.issue.category.replaceAll(' ', '')}
''';

    await Share.share(shareText);
  }

  Future<void> _confirmDelete() async {
    final languageService = context.read<LanguageService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Issue'),
        content: const Text('Are you sure you want to delete this issue? This will permanently remove all photos, audio, and data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageService.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.issue.id != null) {
      try {
        await IssueService().deleteIssue(widget.issue.id!);
        if (!mounted) return;
        Navigator.pop(context, true); // Return to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue deleted successfully'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting issue: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  bool _canReopenIssue() {
    // Only allow reopening if issue is completed
    if (widget.issue.status != 'completed') return false;
    
    // Check if within 48 hours of completion
    if (widget.issue.completedAt != null) {
      final now = DateTime.now();
      final hoursSinceCompletion = now.difference(widget.issue.completedAt!).inHours;
      return hoursSinceCompletion <= 48;
    }
    
    return false;
  }

  Future<void> _reopenIssue() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReopenIssueScreen(issue: widget.issue)),
    );
    
    if (result == true) {
      Navigator.pop(context, true); // Return to refresh parent screen
    }
  }

  DateTime? _getStartedAt() {
    if (_updates.isEmpty) return null;
    // Find first in_progress update
    final firstInProgress = _updates.firstWhere(
      (u) => u.status == 'in_progress',
      orElse: () => _updates.first,
    );
    return firstInProgress.createdAt;
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.issue.mediaUrls.isNotEmpty
                  ? Image.network(
                      widget.issue.mediaUrls.first,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            CategoryHelper.getCategoryColor(widget.issue.category).withOpacity(0.7),
                            CategoryHelper.getCategoryColor(widget.issue.category),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          CategoryHelper.getCategoryIcon(widget.issue.category),
                          size: 80,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and Status Tags
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CategoryHelper.getCategoryColor(widget.issue.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CategoryHelper.getCategoryIcon(widget.issue.category),
                              size: 16,
                              color: CategoryHelper.getCategoryColor(widget.issue.category),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.issue.category.toUpperCase(),
                              style: TextStyle(
                                color: CategoryHelper.getCategoryColor(widget.issue.category),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.issue.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.issue.status.toUpperCase().replaceAll('_', ' '),
                          style: TextStyle(
                            color: _getStatusColor(widget.issue.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    widget.issue.description,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.issue.address,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(widget.issue.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Milestone Tracker
                  MilestoneTracker(
                    currentStatus: widget.issue.status,
                    progress: widget.issue.progress,
                    createdAt: widget.issue.createdAt,
                    isAssigned: widget.issue.assignedTo != null,
                    assignedAt: widget.issue.assignedTo != null ? widget.issue.updatedAt : null,
                    startedAt: _getStartedAt(),
                    completedAt: widget.issue.completedAt,
                  ),

                  const SizedBox(height: 24),

                  // Image Gallery
                  if (widget.issue.mediaUrls.length > 1) ...[
                    Text(
                      'Photos',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.issue.mediaUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.issue.mediaUrls[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Audio Transcription Section
                  if (widget.issue.audioDescription != null && widget.issue.audioDescription!.isNotEmpty) ...[
                    Text(
                      'Voice Description',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple[50]!, Colors.purple[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple[200]!, width: 2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.mic, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transcribed from audio',
                                  style: TextStyle(
                                    color: Colors.purple[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.issue.audioDescription!,
                                  style: TextStyle(
                                    color: Colors.purple[900],
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Worker Updates Section
                  if (_updates.isNotEmpty) ...[
                    Text(
                      'Worker Updates',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_updates.length} update${_updates.length > 1 ? 's' : ''} from assigned worker',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Worker update cards - show only first one or all based on state
                    ...(_showAllUpdates ? _updates.reversed : _updates.reversed.take(1)).map((update) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(update.status).withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status and progress badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(update.status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getStatusIcon(update.status),
                                      size: 14,
                                      color: _getStatusColor(update.status),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      update.status.toUpperCase().replaceAll('_', ' '),
                                      style: TextStyle(
                                        color: _getStatusColor(update.status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${update.progress}%',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _formatDate(update.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Worker message
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.message, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    update.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Worker photos
                          if (update.imageUrls.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.photo_library, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  '${update.imageUrls.length} photo${update.imageUrls.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: update.imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        update.imageUrls[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: Icon(Icons.image_not_supported, color: Colors.grey[500]),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    )),
                    
                    // View More / Show Less button
                    if (_updates.length > 1) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllUpdates = !_showAllUpdates;
                            });
                          },
                          icon: Icon(
                            _showAllUpdates ? Icons.expand_less : Icons.expand_more,
                            color: AppTheme.primary,
                          ),
                          label: Text(
                            _showAllUpdates ? 'Show Less' : 'View More (${_updates.length - 1} more)',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionButton(
                          icon: Icons.thumb_up,
                          label: '${widget.issue.upvotes}',
                          color: AppTheme.primary,
                          onTap: () {}, // User can't upvote their own issue
                        ),
                        _buildActionButton(
                          icon: Icons.comment_outlined,
                          label: '$_commentCount',
                          color: Colors.grey[600]!,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CommentsBottomSheet(issue: widget.issue),
                            ).then((_) async {
                              // Refresh comment count
                              final count = await IssueService().getCommentCount(widget.issue.id!);
                              if (mounted) setState(() => _commentCount = count);
                            });
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: Colors.grey[600]!,
                          onTap: _shareIssue,
                        ),
                        if (_canReopenIssue())
                          _buildActionButton(
                            icon: Icons.refresh,
                            label: 'Reopen',
                            color: Colors.orange[700]!,
                            onTap: _reopenIssue,
                          ),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          color: Colors.red,
                          onTap: _confirmDelete,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.construction;
      default:
        return Icons.pending;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
