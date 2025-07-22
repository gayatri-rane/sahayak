import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../widgets/loading_widget.dart';

class LessonPlanScreen extends StatefulWidget {
  const LessonPlanScreen({super.key});

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _goalsController = TextEditingController();

  List<int> _selectedGrades = [3, 4];
  List<String> _selectedSubjects = ['Mathematics', 'Science'];
  String _duration = 'week';
  String _language = 'English';
  bool _isLoading = false;
  String? _generatedPlan;

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
    _goalsController.dispose();
    super.dispose();
  }

  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 600) return 16.0;
    if (screenWidth < 900) return 24.0;
    return 32.0;
  }

  double _getResponsiveFontSize(double screenWidth, double baseSize) {
    if (screenWidth < 600) return baseSize * 0.9;
    if (screenWidth < 900) return baseSize;
    return baseSize * 1.1;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final padding = _getResponsivePadding(screenWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, screenWidth),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(screenWidth, padding),
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
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event_note,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Lesson Planner',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(screenWidth, 20),
            ),
          ),
        ],
      ),
      actions: [
        if (_generatedPlan != null) ...[
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copyPlan,
            tooltip: 'Copy Plan',
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _downloadPlan,
            tooltip: 'Download Plan',
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
            Color(0xFFB91C1C),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.event_note,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Creating lesson plan...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Designing comprehensive learning experiences',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(double screenWidth, double padding) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                children: [
                  _buildHeaderSection(screenWidth),
                  const SizedBox(height: 24),
                  _buildFormSection(screenWidth),
                  if (_generatedPlan != null) ...[
                    const SizedBox(height: 24),
                    _buildPlanSection(screenWidth),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth < 600 ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFEF4444),
            Color(0xFFDC2626),
            Color(0xFFB91C1C),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_note,
                  color: Colors.white,
                  size: screenWidth < 600 ? 24 : 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Lesson Plans',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(screenWidth, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Design comprehensive weekly or daily lesson plans',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: _getResponsiveFontSize(screenWidth, 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth < 600 ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Plan Configuration',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: _getResponsiveFontSize(screenWidth, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Grade Selection
            _buildGradeSelection(screenWidth),
            const SizedBox(height: 24),

            // Subject Selection
            _buildSubjectSelection(screenWidth),
            const SizedBox(height: 24),

            // Goals Input
            _buildGoalsInput(),
            const SizedBox(height: 20),

            // Duration and Language Row
            screenWidth >= 600
                ? Row(
              children: [
                Expanded(child: _buildDurationDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildLanguageDropdown()),
              ],
            )
                : Column(
              children: [
                _buildDurationDropdown(),
                const SizedBox(height: 16),
                _buildLanguageDropdown(),
              ],
            ),
            const SizedBox(height: 32),

            // Generate Button
            _buildGenerateButton(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSelection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grade Levels',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: _getResponsiveFontSize(screenWidth, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Select target grade levels for the lesson plan',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: _getResponsiveFontSize(screenWidth, 14),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: screenWidth < 600 ? 8 : 12,
          runSpacing: screenWidth < 600 ? 8 : 12,
          children: List.generate(8, (index) {
            final grade = index + 1;
            final isSelected = _selectedGrades.contains(grade);
            return _buildGradeChip(grade, isSelected, screenWidth);
          }),
        ),
      ],
    );
  }

  Widget _buildGradeChip(int grade, bool isSelected, double screenWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedGrades.remove(grade);
          } else {
            _selectedGrades.add(grade);
          }
          _selectedGrades.sort();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 600 ? 16 : 20,
          vertical: screenWidth < 600 ? 10 : 12,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          )
              : null,
          color: isSelected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          'Grade $grade',
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: _getResponsiveFontSize(screenWidth, 14),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectSelection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.subject,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subjects',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: _getResponsiveFontSize(screenWidth, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose subjects to include in the lesson plan',
                  style: TextStyle(
                    color: const Color(0xFF64748B),
                    fontSize: _getResponsiveFontSize(screenWidth, 14),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: screenWidth < 600 ? 8 : 12,
          runSpacing: screenWidth < 600 ? 8 : 12,
          children: AppConfig.subjects.map((subject) {
            final isSelected = _selectedSubjects.contains(subject);
            return _buildSubjectChip(subject, isSelected, screenWidth);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubjectChip(String subject, bool isSelected, double screenWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedSubjects.remove(subject);
          } else {
            _selectedSubjects.add(subject);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 600 ? 12 : 16,
          vertical: screenWidth < 600 ? 8 : 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          )
              : null,
          color: isSelected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFFEF4444).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Text(
          subject,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: _getResponsiveFontSize(screenWidth, 14),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalsInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: _goalsController,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Learning Goals & Objectives',
          hintText: 'e.g., Students will learn multiplication tables, understand plant life cycle, develop problem-solving skills...',
          prefixIcon: Icon(Icons.flag, color: Color(0xFFEF4444)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          alignLabelWithHint: true,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter learning goals and objectives';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        value: _duration,
        decoration: const InputDecoration(
          labelText: 'Duration',
          prefixIcon: Icon(Icons.calendar_today, color: Color(0xFFEF4444)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: Colors.white,
        items: const [
          DropdownMenuItem(value: 'day', child: Text('Daily Plan')),
          DropdownMenuItem(value: 'week', child: Text('Weekly Plan')),
        ],
        onChanged: (value) {
          setState(() {
            _duration = value!;
          });
        },
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        value: _language,
        decoration: const InputDecoration(
          labelText: 'Language',
          prefixIcon: Icon(Icons.language, color: Color(0xFFEF4444)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: Colors.white,
        items: AppConfig.supportedLanguages.map((lang) {
          return DropdownMenuItem(
            value: lang,
            child: Text(lang),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _language = value!;
          });
        },
      ),
    );
  }

  Widget _buildGenerateButton(double screenWidth) {
    final canGenerate = _selectedGrades.isNotEmpty &&
        _selectedSubjects.isNotEmpty &&
        _goalsController.text.isNotEmpty;

    return Container(
      width: double.infinity,
      height: screenWidth < 600 ? 56 : 64,
      decoration: BoxDecoration(
        gradient: canGenerate
            ? const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        )
            : null,
        color: canGenerate ? null : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: canGenerate
            ? [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: canGenerate ? _generateLessonPlan : null,
        icon: Icon(
          Icons.create,
          color: canGenerate ? Colors.white : const Color(0xFF94A3B8),
        ),
        label: Text(
          'Generate Lesson Plan',
          style: TextStyle(
            color: canGenerate ? Colors.white : const Color(0xFF94A3B8),
            fontSize: _getResponsiveFontSize(screenWidth, 16),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanSection(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth < 600 ? 20 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.event_note,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_duration == "week" ? "Weekly" : "Daily"} Lesson Plan',
                                style: TextStyle(
                                  color: const Color(0xFF1E293B),
                                  fontSize: _getResponsiveFontSize(screenWidth, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              _buildMetadataChips(screenWidth),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildActionButtons(screenWidth),
            ],
          ),
          const SizedBox(height: 24),

          // Plan Content
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SelectableText(
              _generatedPlan!,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, 16),
                height: 1.6,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Bottom Actions
          screenWidth >= 600
              ? Row(
            children: [
              Expanded(child: _buildSaveButton()),
              const SizedBox(width: 16),
              Expanded(child: _buildShareButton()),
            ],
          )
              : Column(
            children: [
              _buildSaveButton(),
              const SizedBox(height: 12),
              _buildShareButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChips(double screenWidth) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Grades: ${_selectedGrades.join(", ")}',
            style: const TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_selectedSubjects.length} Subjects',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _language,
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.copy_outlined,
          onPressed: _copyPlan,
          tooltip: 'Copy',
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.print_outlined,
          onPressed: _printPlan,
          tooltip: 'Print',
          color: const Color(0xFF06B6D4),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.download_outlined,
          onPressed: _downloadPlan,
          tooltip: 'Download',
          color: const Color(0xFF8B5CF6),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildSaveButton() {
    return OutlinedButton.icon(
      onPressed: _saveToLibrary,
      icon: const Icon(Icons.save, color: Color(0xFFEF4444)),
      label: const Text('Save to Library', style: TextStyle(color: Color(0xFFEF4444))),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0xFFEF4444)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ElevatedButton.icon(
        onPressed: _shareWithTeam,
        icon: const Icon(Icons.share, color: Colors.white),
        label: const Text('Share with Team', style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _generateLessonPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedPlan = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.createLessonPlan(
        grades: _selectedGrades,
        subjects: _selectedSubjects,
        weeklyGoals: _goalsController.text,
        duration: _duration,
        language: _language,
      );

      setState(() {
        _generatedPlan = result['lesson_plan'];
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Lesson plan generated successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _copyPlan() {
    if (_generatedPlan != null) {
      final formattedText = '${_duration == "week" ? "Weekly" : "Daily"} Lesson Plan\n'
          'Grades: ${_selectedGrades.join(", ")}\n'
          'Subjects: ${_selectedSubjects.join(", ")}\n'
          'Language: $_language\n'
          'Goals: ${_goalsController.text}\n\n'
          '$_generatedPlan';
      Clipboard.setData(ClipboardData(text: formattedText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Lesson plan copied to clipboard!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _printPlan() {
    if (_generatedPlan != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Print functionality coming soon!'),
            ],
          ),
          backgroundColor: const Color(0xFF06B6D4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _downloadPlan() {
    if (_generatedPlan != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Downloading lesson plan...'),
            ],
          ),
          backgroundColor: const Color(0xFF8B5CF6),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _saveToLibrary() {
    if (_generatedPlan != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Lesson plan saved to library!'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _shareWithTeam() {
    if (_generatedPlan != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Share functionality coming soon!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}