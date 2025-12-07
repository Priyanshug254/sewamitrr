import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class MilestoneTracker extends StatelessWidget {
  final String currentStatus;
  final int progress;
  final DateTime? createdAt;
  final DateTime? assignedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isAssigned; // NEW: Check if issue is assigned

  const MilestoneTracker({
    super.key,
    required this.currentStatus,
    required this.progress,
    this.createdAt,
    this.assignedAt,
    this.startedAt,
    this.completedAt,
    this.isAssigned = false, // NEW: Default to false
  });

  @override
  Widget build(BuildContext context) {
    final milestones = _getMilestones();
    
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Tracking',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (int i = 0; i < milestones.length; i++) ...[
                Expanded(
                  child: _buildMilestone(milestones[i], i == milestones.length - 1),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<_Milestone> _getMilestones() {
    return [
      _Milestone(
        title: 'Reported',
        isCompleted: true,
        timestamp: createdAt,
        icon: Icons.flag,
      ),
      _Milestone(
        title: 'Assigned',
        isCompleted: isAssigned, // Use isAssigned flag instead of timestamp
        timestamp: assignedAt,
        icon: Icons.person_add,
      ),
      _Milestone(
        title: 'In Progress',
        isCompleted: currentStatus == 'in_progress' || currentStatus == 'completed',
        timestamp: startedAt,
        icon: Icons.construction,
      ),
      _Milestone(
        title: 'Completed',
        isCompleted: currentStatus == 'completed',
        timestamp: completedAt,
        icon: Icons.check_circle,
      ),
    ];
  }

  Widget _buildMilestone(_Milestone milestone, bool isLast) {
    return Column(
      children: [
        Row(
          children: [
            // Milestone circle and icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: milestone.isCompleted ? AppTheme.primary : Colors.grey[200],
                shape: BoxShape.circle,
                boxShadow: milestone.isCompleted ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : [],
              ),
              child: Icon(
                milestone.icon,
                color: milestone.isCompleted ? Colors.white : Colors.grey[400],
                size: 20,
              ),
            ),
            
            // Connecting line (except for last milestone)
            if (!isLast)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: milestone.isCompleted ? AppTheme.primary : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Milestone label
        SizedBox(
          width: 80,
          child: Column(
            children: [
              Text(
                milestone.title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: milestone.isCompleted ? AppTheme.primary : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (milestone.timestamp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatDate(milestone.timestamp!),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _Milestone {
  final String title;
  final bool isCompleted;
  final DateTime? timestamp;
  final IconData icon;

  _Milestone({
    required this.title,
    required this.isCompleted,
    this.timestamp,
    required this.icon,
  });
}
