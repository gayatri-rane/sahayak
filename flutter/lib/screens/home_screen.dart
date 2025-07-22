import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/feature_card.dart';
import 'story_generator_screen.dart';
import 'worksheet_creator_screen.dart';
import 'visual_aid_screen.dart';
import 'game_generator_screen.dart';
import 'lesson_plan_screen.dart';
import 'student_progress_screen.dart';
import 'community_library_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int _getGridColumns(double screenWidth) {
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    if (screenWidth < 1200) return 4;
    return 5;
  }

  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 900) return 24.0;
    return 32.0;
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth < 600) return 0.95; // Mobile - slightly taller
    if (screenWidth < 900) return 1.0;  // Tablet - square
    if (screenWidth < 1200) return 1.1; // Small desktop - slightly wider
    return 1.15; // Large desktop - wider
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final isLargeScreen = screenWidth >= 1200;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, screenWidth),
      drawer: isLargeScreen ? null : _buildDrawer(context, auth),
      body: Row(
        children: [
          if (isLargeScreen) _buildNavigationRail(context, auth),
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildMainContent(context, screenWidth),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double screenWidth) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1E293B),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.school,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Sahayak',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        if (screenWidth >= 600) ...[
          _buildActionButton(
            icon: Icons.library_books_outlined,
            label: 'Library',
            onPressed: () => _navigateTo(context, const CommunityLibraryScreen()),
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onPressed: () => _navigateTo(context, const SettingsScreen()),
          ),
          const SizedBox(width: 16),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            onPressed: () => _navigateTo(context, const CommunityLibraryScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _navigateTo(context, const SettingsScreen()),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
      label: Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B)),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, double screenWidth) {
    final auth = Provider.of<AuthService>(context);
    final padding = _getResponsivePadding(screenWidth);

    return Column(
      children: [
        // Fixed Welcome header
        Container(
          margin: EdgeInsets.all(padding),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF1D4ED8),
                Color(0xFF1E40AF),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth < 600 ? 20 : 24,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Icon(
                      Icons.waving_hand,
                      color: Colors.white,
                      size: screenWidth < 600 ? 18 : 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${auth.userProfile?['name'] ?? 'Teacher'}!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 600 ? 18 : 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Ready to create something amazing today?',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: screenWidth < 600 ? 14 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Feature cards
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getGridColumns(screenWidth),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: _getChildAspectRatio(screenWidth),
                  ),
                  itemCount: _getFeatureCards(context).length,
                  itemBuilder: (context, index) {
                    return _getFeatureCards(context)[index];
                  },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(double screenWidth) {
    // Removed stats cards - keeping method for backward compatibility
    return const SizedBox.shrink();
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required double screenWidth,
  }) {
    // Removed stat cards - keeping method for backward compatibility
    return const SizedBox.shrink();
  }

  List<Widget> _getFeatureCards(BuildContext context) {
    final features = [
      {
        'title': 'Story Generator',
        'icon': Icons.auto_stories,
        'color': const Color(0xFF06B6D4),
        'gradient': const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
        'screen': const StoryGeneratorScreen(),
      },
      {
        'title': 'Worksheet Creator',
        'icon': Icons.assignment,
        'color': const Color(0xFF10B981),
        'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        'screen': const WorksheetCreatorScreen(),
      },
      {
        'title': 'Visual Aids',
        'icon': Icons.palette,
        'color': const Color(0xFFF59E0B),
        'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        'screen': const VisualAidScreen(),
      },
      {
        'title': 'Educational Games',
        'icon': Icons.sports_esports,
        'color': const Color(0xFF8B5CF6),
        'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        'screen': const GameGeneratorScreen(),
      },
      {
        'title': 'Lesson Plans',
        'icon': Icons.event_note,
        'color': const Color(0xFFEF4444),
        'gradient': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
        'screen': const LessonPlanScreen(),
      },
      {
        'title': 'Student Progress',
        'icon': Icons.trending_up,
        'color': const Color(0xFF14B8A6),
        'gradient': const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]),
        'screen': const StudentProgressScreen(),
      },
    ];

    return features.map((feature) {
      return EnhancedFeatureCard(
        title: feature['title'] as String,
        icon: feature['icon'] as IconData,
        gradient: feature['gradient'] as LinearGradient,
        onTap: () => _navigateTo(context, feature['screen'] as Widget),
      );
    }).toList();
  }

  List<Widget> _buildFeatureCards(BuildContext context) {
    final features = [
      {
        'title': 'Story Generator',
        'icon': Icons.auto_stories,
        'color': const Color(0xFF06B6D4),
        'gradient': const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
        'screen': const StoryGeneratorScreen(),
      },
      {
        'title': 'Worksheet Creator',
        'icon': Icons.assignment,
        'color': const Color(0xFF10B981),
        'gradient': const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
        'screen': const WorksheetCreatorScreen(),
      },
      {
        'title': 'Visual Aids',
        'icon': Icons.palette,
        'color': const Color(0xFFF59E0B),
        'gradient': const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        'screen': const VisualAidScreen(),
      },
      {
        'title': 'Educational Games',
        'icon': Icons.sports_esports,
        'color': const Color(0xFF8B5CF6),
        'gradient': const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        'screen': const GameGeneratorScreen(),
      },
      {
        'title': 'Lesson Plans',
        'icon': Icons.event_note,
        'color': const Color(0xFFEF4444),
        'gradient': const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
        'screen': const LessonPlanScreen(),
      },
      {
        'title': 'Student Progress',
        'icon': Icons.trending_up,
        'color': const Color(0xFF14B8A6),
        'gradient': const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF0D9488)]),
        'screen': const StudentProgressScreen(),
      },
    ];

    return features.map((feature) {
      return EnhancedFeatureCard(
        title: feature['title'] as String,
        icon: feature['icon'] as IconData,
        gradient: feature['gradient'] as LinearGradient,
        onTap: () => _navigateTo(context, feature['screen'] as Widget),
      );
    }).toList();
  }

  Widget _buildNavigationRail(BuildContext context, AuthService auth) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // User profile section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    (auth.userProfile?['name'] ?? 'T')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userProfile?['name'] ?? 'Teacher',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        auth.userProfile?['school'] ?? 'School',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(Icons.home, 'Home', true, () {}),
                _buildNavItem(Icons.library_books, 'Library', false,
                        () => _navigateTo(context, const CommunityLibraryScreen())),
                _buildNavItem(Icons.assessment, 'Reports', false, () {}),
                _buildNavItem(Icons.help_outline, 'Help & Support', false, () {}),
              ],
            ),
          ),

          // Logout button
          Container(
            margin: const EdgeInsets.all(16),
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, bool selected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(
          icon,
          color: selected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        selected: selected,
        selectedTileColor: const Color(0xFF3B82F6).withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthService auth) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        (auth.userProfile?['name'] ?? 'T')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      auth.userProfile?['name'] ?? 'Teacher',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      auth.userProfile?['school'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(Icons.home, 'Home', true, () => Navigator.pop(context)),
                _buildDrawerItem(Icons.library_books, 'Community Library', false, () {
                  Navigator.pop(context);
                  _navigateTo(context, const CommunityLibraryScreen());
                }),
                _buildDrawerItem(Icons.assessment, 'Reports', false, () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.help_outline, 'Help & Support', false, () {
                  Navigator.pop(context);
                }),
                const Divider(height: 1),
                _buildDrawerItem(Icons.logout, 'Logout', false, () async {
                  Navigator.pop(context);
                  await auth.logout();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool selected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: const Color(0xFF3B82F6).withOpacity(0.1),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

// Enhanced Feature Card Widget
class EnhancedFeatureCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const EnhancedFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<EnhancedFeatureCard> createState() => _EnhancedFeatureCardState();
}

class _EnhancedFeatureCardState extends State<EnhancedFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    // Responsive sizing
    final cardPadding = isMobile ? 12.0 : 16.0;
    final iconSize = isMobile ? 24.0 : isTablet ? 28.0 : 32.0;
    final titleFontSize = isMobile ? 12.0 : isTablet ? 14.0 : 16.0;
    final buttonFontSize = isMobile ? 10.0 : 12.0;
    final iconPadding = isMobile ? 10.0 : 12.0;
    final verticalSpacing = isMobile ? 8.0 : 12.0;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first.withOpacity(0.3),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: Offset(0, _isHovered ? 8 : 4),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(_isHovered ? 0.2 : 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon container
                            Flexible(
                              flex: 2,
                              child: Container(
                                padding: EdgeInsets.all(iconPadding),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.icon,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: verticalSpacing),

                            // Title
                            Flexible(
                              flex: 2,
                              child: Text(
                                widget.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(height: verticalSpacing * 0.5),

                            // Action button
                            Flexible(
                              flex: 1,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 8 : 10,
                                  vertical: isMobile ? 3 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Create Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: buttonFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}