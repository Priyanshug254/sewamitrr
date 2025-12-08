import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/issue_service.dart';
import '../../services/notification_service.dart';
import '../../models/issue_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import '../../utils/category_helper.dart';
import 'feed_screen.dart';
import 'my_reports_screen.dart';
import 'report_issue_screen.dart';
import 'notifications_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  List<IssueModel> _userIssues = [];
  bool _isLoading = true;

  Map<String, int> _communityStats = {
    'total_users': 0,
    'total_issues': 0,
    'resolved_issues': 0
  };

  @override
  void initState() {
    super.initState();
    _loadUserIssues();
    _loadCommunityStats();
    _setupNotifications();
  }



  Future<void> _loadCommunityStats() async {
    final stats = await IssueService().getCommunityStats();
    if (mounted) {
      setState(() => _communityStats = stats);
    }
  }

  void _setupNotifications() async {
    final authService = context.read<AuthService>();
    final notificationService = context.read<NotificationService>();
    if (authService.currentUser != null) {
      // Initialize local notifications first
      await notificationService.initialize();
      
      // Then load and subscribe
      notificationService.loadNotifications(authService.currentUser!.id);
      notificationService.subscribeToNotifications(authService.currentUser!.id);
    }
  }

  Future<void> _loadUserIssues() async {
    final authService = context.read<AuthService>();
    if (authService.currentUser != null) {
      try {
        setState(() => _isLoading = true);
        final issues = await IssueService().getUserIssues(authService.currentUser!.id);
        if (!mounted) return;
        setState(() {
          _userIssues = issues;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final authService = Provider.of<AuthService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    


    final List<Widget> screens = [
      _buildHomeTab(languageService, authService),
      const MyReportsScreen(),
      const FeedScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppTheme.primary.withOpacity(0.1),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: AppTheme.primary),
              label: languageService.translate('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined),
              selectedIcon: const Icon(Icons.assignment, color: AppTheme.primary),
              label: languageService.translate('my_reports'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.public_outlined),
              selectedIcon: const Icon(Icons.public, color: AppTheme.primary),
              label: languageService.translate('feed'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outlined),
              selectedIcon: const Icon(Icons.person, color: AppTheme.primary),
              label: languageService.translate('profile'),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportIssueScreen()),
          );
          _loadUserIssues();
          _loadCommunityStats();
        },
        child: Container(
          padding: _currentIndex == 0 
              ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
              : const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _currentIndex == 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_a_photo, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      languageService.translate('report_issue'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              : const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: _currentIndex == 0 
          ? FloatingActionButtonLocation.centerFloat 
          : FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHomeTab(LanguageService languageService, AuthService authService) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          backgroundColor: AppTheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              child: Stack(
                children: [
                  // Decorative circles
                  Positioned(
                    top: -50,
                    right: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -30,
                    left: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getGreeting(languageService),
                            style: GoogleFonts.outfit(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  authService.userProfile?.name ?? 'User',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                ),
                                child: ClipOval(
                                  child: authService.userProfile?.photoUrl != null
                                      ? Image.network(
                                          authService.userProfile!.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(Icons.person, color: Colors.white.withOpacity(0.7), size: 28),
                                        )
                                      : Icon(Icons.person, color: Colors.white.withOpacity(0.7), size: 28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.volunteer_activism, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Making your community better',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                    );
                  },
                ),
                Consumer<NotificationService>(
                  builder: (context, service, child) {
                    if (service.unreadCount > 0) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.error,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${service.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stats Row
                FadeInSlide(
                  delay: 0.1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: languageService.translate('reported'),
                          value: _userIssues.length,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8A7BF0), Color(0xFFA599F3)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.assignment,
                          delay: 0.2,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          title: languageService.translate('resolved'),
                          value: _userIssues.where((i) => i.status == 'completed').length,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9B8DF2), Color(0xFFB5AAF5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          icon: Icons.check_circle,
                          delay: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Community Stats
                FadeInSlide(
                  delay: 0.4,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                        _buildCommunityStat(
                          _communityStats['total_users'] ?? 0,
                          'Citizens',
                          Icons.people_outline,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[200]),
                        _buildCommunityStat(
                          _communityStats['total_issues'] ?? 0,
                          'Reports',
                          Icons.report_problem_outlined,
                        ),
                        Container(width: 1, height: 40, color: Colors.grey[200]),
                        _buildCommunityStat(
                          _communityStats['resolved_issues'] ?? 0,
                          'Solved',
                          Icons.task_alt,
                          color: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Recent Activity Header
                FadeInSlide(
                  delay: 0.5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        languageService.translate('recent_activity'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => setState(() => _currentIndex = 1),
                        child: Text(languageService.translate('view_all')),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Recent Activity List
                FutureBuilder<List<IssueModel>>(
                  future: IssueService().getUserIssues(authService.currentUser?.id ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState(languageService);
                    }
                    final issues = snapshot.data!.take(3).toList();
                    return ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: issues.length,
                      itemBuilder: (context, index) {
                        final issue = issues[index];
                        return FadeInSlide(
                          delay: 0.6 + (index * 0.1),
                          child: _buildActivityItem(issue),
                        );
                      },
                    );
                  },
                ),
                  
                const SizedBox(height: 80), // Bottom padding for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required Gradient gradient,
    required IconData icon,
    required double delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient.colors.first).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          AnimatedCounter(
            value: value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityStat(int value, String label, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        AnimatedCounter(
          value: value,
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3436),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(IssueModel issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: issue.mediaUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(issue.mediaUrls.first),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Colors.grey[100],
            ),
            child: issue.mediaUrls.isEmpty
                ? Icon(Icons.image_not_supported, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issue.category.toUpperCase(),
                  style: TextStyle(
                    color: CategoryHelper.getCategoryColor(issue.category),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  issue.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  issue.address,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(issue.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              issue.status,
              style: TextStyle(
                color: _getStatusColor(issue.status),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageService languageService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              languageService.translate('no_issues_reported'),
              style: TextStyle(color: Colors.grey[500]),
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
      case 'pending':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getGreeting(LanguageService languageService) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return languageService.currentLanguage == 'hi' ? 'सुप्रभात' : 'Good Morning';
    } else if (hour < 17) {
      return languageService.currentLanguage == 'hi' ? 'नमस्ते' : 'Good Afternoon';
    } else {
      return languageService.currentLanguage == 'hi' ? 'शुभ संध्या' : 'Good Evening';
    }
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 17) return '☀️';
    return '🌆';
  }
}