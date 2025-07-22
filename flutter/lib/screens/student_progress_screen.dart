import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen>
    with TickerProviderStateMixin {
  String? _selectedStudentId;
  Map<String, dynamic>? _progressData;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredStudents = [];

  // Mock student data - replace with actual data
  final List<Map<String, String>> _students = [
    {'id': 'student001', 'name': 'Raj Kumar', 'grade': '3', 'avatar': 'R'},
    {'id': 'student002', 'name': 'Priya Sharma', 'grade': '4', 'avatar': 'P'},
    {'id': 'student003', 'name': 'Amit Patel', 'grade': '3', 'avatar': 'A'},
    {'id': 'student004', 'name': 'Anita Singh', 'grade': '5', 'avatar': 'A'},
    {'id': 'student005', 'name': 'Vikram Reddy', 'grade': '4', 'avatar': 'V'},
    {'id': 'student006', 'name': 'Sita Devi', 'grade': '3', 'avatar': 'S'},
    {'id': 'student007', 'name': 'Ravi Gupta', 'grade': '5', 'avatar': 'R'},
    {'id': 'student008', 'name': 'Meera Joshi', 'grade': '4', 'avatar': 'M'},
  ];

  @override
  void initState() {
    super.initState();
    _filteredStudents = _students;
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
    _searchController.dispose();
    super.dispose();
  }

  bool _isLargeScreen(double width) => width >= 1200;
  bool _isTablet(double width) => width >= 600 && width < 1200;
  bool _isMobile(double width) => width < 600;

  double _getResponsivePadding(double width) {
    if (_isMobile(width)) return 16.0;
    if (_isTablet(width)) return 24.0;
    return 32.0;
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((student) =>
        student['name']!.toLowerCase().contains(query.toLowerCase()) ||
            student['grade']!.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final padding = _getResponsivePadding(screenWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, screenWidth),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildResponsiveLayout(context, screenWidth, padding),
            ),
          );
        },
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
                colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.trending_up,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Student Progress',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        if (screenWidth >= 600)
          _buildActionButton(
            icon: Icons.person_add_outlined,
            label: 'Add Student',
            onPressed: _addNewStudent,
          ),
        const SizedBox(width: 16),
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

  Widget _buildResponsiveLayout(BuildContext context, double screenWidth, double padding) {
    if (_isMobile(screenWidth)) {
      return _buildMobileLayout(padding);
    } else {
      return _buildDesktopLayout(screenWidth, padding);
    }
  }

  Widget _buildMobileLayout(double padding) {
    return Column(
      children: [
        // Header with current student if selected
        if (_selectedStudentId != null) _buildMobileStudentHeader(padding),

        // Student List or Progress Details
        Expanded(
          child: _selectedStudentId == null
              ? _buildMobileStudentList(padding)
              : _buildMobileProgressDetails(padding),
        ),
      ],
    );
  }

  Widget _buildMobileStudentHeader(double padding) {
    final selectedStudent = _students.firstWhere(
          (s) => s['id'] == _selectedStudentId,
    );

    return Container(
      margin: EdgeInsets.all(padding),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              selectedStudent['avatar']!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedStudent['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Grade ${selectedStudent['grade']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedStudentId = null),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStudentList(double padding) {
    return Column(
      children: [
        // Search bar
        Container(
          margin: EdgeInsets.symmetric(horizontal: padding, vertical: padding / 2),
          child: _buildSearchBar(),
        ),

        // Student grid
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _filteredStudents.length,
              itemBuilder: (context, index) {
                return _buildStudentCard(_filteredStudents[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileProgressDetails(double padding) {
    return _isLoading
        ? const LoadingWidget(message: 'Loading progress...')
        : SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: _buildProgressContent(true),
    );
  }

  Widget _buildDesktopLayout(double screenWidth, double padding) {
    return Row(
      children: [
        // Student List Sidebar
        Container(
          width: _isLargeScreen(screenWidth) ? 350 : 300,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: _buildStudentListSidebar(padding),
        ),

        // Progress Details
        Expanded(
          child: _selectedStudentId == null
              ? _buildEmptyState()
              : _isLoading
              ? const LoadingWidget(message: 'Loading progress...')
              : SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: _buildProgressContent(false),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentListSidebar(double padding) {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Students',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_filteredStudents.length} students',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: EdgeInsets.all(padding),
          child: _buildSearchBar(),
        ),

        // Student list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: padding / 2),
            itemCount: _filteredStudents.length,
            itemBuilder: (context, index) {
              return _buildStudentListTile(_filteredStudents[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search students...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: _filterStudents,
      ),
    );
  }

  Widget _buildStudentCard(Map<String, String> student) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
      const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
    ];

    final gradient = gradients[student['name']!.hashCode % gradients.length];

    return GestureDetector(
      onTap: () => _selectStudent(student['id']!),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  student['avatar']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                student['name']!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Grade ${student['grade']}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentListTile(Map<String, String> student) {
    final isSelected = student['id'] == _selectedStudentId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectStudent(student['id']!),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B82F6).withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF64748B),
                  child: Text(
                    student['avatar']!,
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
                        student['name']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Grade ${student['grade']}',
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.person_search,
                size: 60,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select a student to view progress',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose from the student list to see detailed progress information',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressContent(bool isMobile) {
    final selectedStudent = _students.firstWhere(
          (s) => s['id'] == _selectedStudentId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Student Header (desktop only)
        if (!isMobile) _buildStudentHeader(selectedStudent),
        if (!isMobile) const SizedBox(height: 24),

        // Progress Overview
        _buildProgressOverview(isMobile),
        const SizedBox(height: 24),

        // Strengths & Areas for Improvement
        if (isMobile)
          Column(
            children: [
              _buildSection(
                'Strengths',
                _progressData?['strengths'] ?? ['Good reading comprehension', 'Strong mathematical skills'],
                Icons.star,
                const Color(0xFF10B981),
                isMobile,
              ),
              const SizedBox(height: 16),
              _buildSection(
                'Areas for Improvement',
                _progressData?['areas_for_improvement'] ?? ['Writing skills', 'Attention span'],
                Icons.trending_up,
                const Color(0xFFF59E0B),
                isMobile,
              ),
            ],
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSection(
                  'Strengths',
                  _progressData?['strengths'] ?? ['Good reading comprehension', 'Strong mathematical skills'],
                  Icons.star,
                  const Color(0xFF10B981),
                  isMobile,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSection(
                  'Areas for Improvement',
                  _progressData?['areas_for_improvement'] ?? ['Writing skills', 'Attention span'],
                  Icons.trending_up,
                  const Color(0xFFF59E0B),
                  isMobile,
                ),
              ),
            ],
          ),
        const SizedBox(height: 24),

        // Recent Assessments
        _buildAssessmentsSection(isMobile),
      ],
    );
  }

  Widget _buildStudentHeader(Map<String, String> student) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14B8A6), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF14B8A6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              student['avatar']!,
              style: const TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Grade ${student['grade']} • Student ID: $_selectedStudentId',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: _updateProgress,
              icon: const Icon(Icons.edit, color: Colors.white, size: 18),
              label: const Text(
                'Update Progress',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(bool isMobile) {
    final stats = [
      {
        'title': 'Activities Completed',
        'value': _progressData?['activities_completed']?.toString() ?? '12',
        'icon': Icons.check_circle,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Reading Level',
        'value': _progressData?['reading_level'] ?? 'Grade 4',
        'icon': Icons.menu_book,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Assessments',
        'value': '${_progressData?['assessments']?.length ?? 5}',
        'icon': Icons.assignment,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Overall Score',
        'value': '85%',
        'icon': Icons.school,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) => _buildStatCard(stats[index], true),
      );
    } else {
      return Row(
        children: stats
            .map((stat) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: stat == stats.last ? 0 : 16,
            ),
            child: _buildStatCard(stat, false),
          ),
        ))
            .toList(),
      );
    }
  }

  Widget _buildStatCard(Map<String, dynamic> stat, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stat['color'].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              stat['icon'],
              color: stat['color'],
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            stat['value'],
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat['title'],
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      String title,
      List<dynamic> items,
      IconData icon,
      Color color,
      bool isMobile,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[500], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No items recorded yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAssessmentsSection(bool isMobile) {
    final assessments = _progressData?['assessments'] ?? [
      {'type': 'Math Quiz', 'score': 85, 'date': '2024-01-15', 'notes': 'Good understanding of fractions'},
      {'type': 'Reading Test', 'score': 92, 'date': '2024-01-10', 'notes': 'Excellent comprehension skills'},
      {'type': 'Science Project', 'score': 78, 'date': '2024-01-05', 'notes': 'Creative approach to problem solving'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recent Assessments',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _viewAllAssessments,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (assessments.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No assessments recorded yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assessments.length > 3 ? 3 : assessments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final assessment = assessments[index];
                return _buildAssessmentTile(assessment, isMobile);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAssessmentTile(Map<String, dynamic> assessment, bool isMobile) {
    final score = assessment['score'] ?? 0;
    final scoreColor = _getScoreColor(score);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scoreColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '$score%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment['type'] ?? 'Assessment',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assessment['date'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (assessment['notes'] != null)
            IconButton(
              icon: const Icon(Icons.notes_outlined, color: Color(0xFF64748B)),
              onPressed: () => _showNotes(assessment['notes']),
            ),
        ],
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    if (score == null) return const Color(0xFF64748B);
    final scoreNum = int.tryParse(score.toString()) ?? 0;
    if (scoreNum >= 80) return const Color(0xFF10B981);
    if (scoreNum >= 60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Future<void> _selectStudent(String studentId) async {
    setState(() {
      _selectedStudentId = studentId;
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _progressData = {
          'activities_completed': 12,
          'reading_level': 'Grade 4',
          'assessments': [
            {'type': 'Math Quiz', 'score': 85, 'date': '2024-01-15', 'notes': 'Good understanding of fractions'},
            {'type': 'Reading Test', 'score': 92, 'date': '2024-01-10', 'notes': 'Excellent comprehension skills'},
            {'type': 'Science Project', 'score': 78, 'date': '2024-01-05', 'notes': 'Creative approach to problem solving'},
          ],
          'strengths': ['Good reading comprehension', 'Strong mathematical skills', 'Creative thinking'],
          'areas_for_improvement': ['Writing skills', 'Attention span', 'Following instructions'],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _progressData = {
          'activities_completed': 0,
          'reading_level': 'Not Assessed',
          'assessments': [],
          'strengths': [],
          'areas_for_improvement': [],
        };
      });
    }
  }

  void _addNewStudent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Student'),
        content: const Text('Add student functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Progress'),
        content: const Text('Progress update functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _viewAllAssessments() {
    // Navigate to assessments page
  }

  void _showNotes(String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Assessment Notes'),
        content: Text(notes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}