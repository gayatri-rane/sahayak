import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../widgets/loading_widget.dart';

class GameGeneratorScreen extends StatefulWidget {
  const GameGeneratorScreen({super.key});

  @override
  State<GameGeneratorScreen> createState() => _GameGeneratorScreenState();
}

class _GameGeneratorScreenState extends State<GameGeneratorScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();

  String _selectedGameType = 'vocabulary_bingo';
  String _selectedLanguage = 'English';
  int _selectedGrade = 3;
  bool _isLoading = false;
  String? _generatedGame;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _gameTypes = [
    {
      'key': 'vocabulary_bingo',
      'name': 'Vocabulary Bingo',
      'icon': Icons.grid_on,
      'description': 'Interactive word recognition game',
    },
    {
      'key': 'math_puzzle',
      'name': 'Math Puzzle',
      'icon': Icons.calculate,
      'description': 'Number-based problem solving',
    },
    {
      'key': 'science_quiz',
      'name': 'Science Quiz',
      'icon': Icons.science,
      'description': 'Scientific concept exploration',
    },
    {
      'key': 'memory_game',
      'name': 'Memory Game',
      'icon': Icons.psychology,
      'description': 'Memory and concentration training',
    },
    {
      'key': 'word_building',
      'name': 'Word Building',
      'icon': Icons.abc,
      'description': 'Letter and spelling activities',
    },
    {
      'key': 'number_race',
      'name': 'Number Race',
      'icon': Icons.speed,
      'description': 'Fast-paced number challenges',
    },
    {
      'key': 'story_sequence',
      'name': 'Story Sequence',
      'icon': Icons.reorder,
      'description': 'Narrative order and logic',
    },
    {
      'key': 'shape_hunt',
      'name': 'Shape Hunt',
      'icon': Icons.category,
      'description': 'Geometry and pattern recognition',
    },
  ];

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
    _topicController.dispose();
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
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_esports,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Game Generator',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(screenWidth, 20),
            ),
          ),
        ],
      ),
      actions: [
        if (_generatedGame != null) ...[
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copyGame,
            tooltip: 'Copy Game',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareGame,
            tooltip: 'Share Game',
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
            Color(0xFF8B5CF6),
            Color(0xFF7C3AED),
            Color(0xFF6D28D9),
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
              Icons.sports_esports,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Creating your game...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Designing fun learning activities',
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
                  if (_generatedGame != null) ...[
                    const SizedBox(height: 24),
                    _buildGameSection(screenWidth),
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
            Color(0xFF8B5CF6),
            Color(0xFF7C3AED),
            Color(0xFF6D28D9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
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
                  Icons.sports_esports,
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
                      'Create Educational Games',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(screenWidth, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Design fun, interactive learning games for your students',
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
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Game Configuration',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: _getResponsiveFontSize(screenWidth, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Game Type Selection
            _buildGameTypeSelection(screenWidth),
            const SizedBox(height: 24),

            // Topic Input
            _buildTopicInput(),
            const SizedBox(height: 20),

            // Grade and Language Row
            screenWidth >= 600
                ? Row(
              children: [
                Expanded(child: _buildGradeDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildLanguageDropdown()),
              ],
            )
                : Column(
              children: [
                _buildGradeDropdown(),
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

  Widget _buildGameTypeSelection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.games,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Type',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: _getResponsiveFontSize(screenWidth, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose the type of educational game',
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth < 600 ? 2 : screenWidth < 900 ? 3 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: screenWidth < 600 ? 1.0 : 1.2,
          ),
          itemCount: _gameTypes.length,
          itemBuilder: (context, index) {
            final gameType = _gameTypes[index];
            final isSelected = _selectedGameType == gameType['key'];
            return _buildGameTypeCard(gameType, isSelected, screenWidth);
          },
        ),
      ],
    );
  }

  Widget _buildGameTypeCard(Map<String, dynamic> gameType, bool isSelected, double screenWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGameType = gameType['key'];
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(screenWidth < 600 ? 12 : 16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
          )
              : null,
          color: isSelected ? null : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
            width: 2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                gameType['icon'],
                size: screenWidth < 600 ? 20 : 24,
                color: isSelected ? Colors.white : const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              gameType['name'],
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B),
                fontSize: _getResponsiveFontSize(screenWidth, 12),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (screenWidth >= 600) ...[
              const SizedBox(height: 4),
              Text(
                gameType['description'],
                style: TextStyle(
                  color: isSelected ? Colors.white.withOpacity(0.8) : const Color(0xFF64748B),
                  fontSize: _getResponsiveFontSize(screenWidth, 10),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopicInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: _topicController,
        decoration: const InputDecoration(
          labelText: 'Game Topic',
          hintText: 'e.g., Animals, Numbers, Colors, Planets',
          prefixIcon: Icon(Icons.topic, color: Color(0xFF8B5CF6)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a topic for the game';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<int>(
        value: _selectedGrade,
        decoration: const InputDecoration(
          labelText: 'Grade Level',
          prefixIcon: Icon(Icons.school, color: Color(0xFF8B5CF6)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dropdownColor: Colors.white,
        items: List.generate(8, (i) => i + 1).map((grade) {
          return DropdownMenuItem(
            value: grade,
            child: Text('Grade $grade'),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedGrade = value!;
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
        value: _selectedLanguage,
        decoration: const InputDecoration(
          labelText: 'Language',
          prefixIcon: Icon(Icons.language, color: Color(0xFF8B5CF6)),
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
            _selectedLanguage = value!;
          });
        },
      ),
    );
  }

  Widget _buildGenerateButton(double screenWidth) {
    return Container(
      width: double.infinity,
      height: screenWidth < 600 ? 56 : 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _generateGame,
        icon: const Icon(Icons.casino, color: Colors.white),
        label: Text(
          'Generate Game',
          style: TextStyle(
            color: Colors.white,
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

  Widget _buildGameSection(double screenWidth) {
    final selectedGameType = _gameTypes.firstWhere((game) => game['key'] == _selectedGameType);

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
                              colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            selectedGameType['icon'],
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
                                selectedGameType['name'],
                                style: TextStyle(
                                  color: const Color(0xFF1E293B),
                                  fontSize: _getResponsiveFontSize(screenWidth, 18),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _topicController.text,
                                      style: const TextStyle(
                                        color: Color(0xFF8B5CF6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Grade $_selectedGrade',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

          // Game Instructions
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SelectableText(
              _generatedGame!,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, 16),
                height: 1.6,
                color: const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ElevatedButton.icon(
                  onPressed: _playGame,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('Play Instructions', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _saveGame,
                icon: const Icon(Icons.save, color: Color(0xFF8B5CF6)),
                label: const Text('Save to Library', style: TextStyle(color: Color(0xFF8B5CF6))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF8B5CF6)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.copy_outlined,
          onPressed: _copyGame,
          tooltip: 'Copy',
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.print_outlined,
          onPressed: _printGame,
          tooltip: 'Print',
          color: const Color(0xFF06B6D4),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.share_outlined,
          onPressed: _shareGame,
          tooltip: 'Share',
          color: const Color(0xFFEF4444),
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

  Future<void> _generateGame() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _generatedGame = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.generateGame(
        gameType: _selectedGameType,
        topic: _topicController.text,
        grade: _selectedGrade,
        language: _selectedLanguage,
      );

      setState(() {
        _generatedGame = result['game'];
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
                Text('Game generated successfully!'),
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

  void _copyGame() {
    if (_generatedGame != null) {
      final selectedGameType = _gameTypes.firstWhere((game) => game['key'] == _selectedGameType);
      final formattedText = '${selectedGameType['name']} - ${_topicController.text}\nGrade: $_selectedGrade | Language: $_selectedLanguage\n\n$_generatedGame';
      Clipboard.setData(ClipboardData(text: formattedText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Game copied to clipboard!'),
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

  void _printGame() {
    if (_generatedGame != null) {
      // Print implementation would go here
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

  void _shareGame() {
    if (_generatedGame != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Share functionality coming soon!'),
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

  void _playGame() {
    if (_generatedGame != null) {
      final selectedGameType = _gameTypes.firstWhere((game) => game['key'] == _selectedGameType);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(selectedGameType['icon'], color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('How to Play'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedGameType['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedGameType['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Instructions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1. Gather the materials mentioned in the game\n'
                      '2. Follow the setup instructions carefully\n'
                      '3. Explain the rules to your students\n'
                      '4. Let them play and have fun learning!',
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                child: const Text('Got it!', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _saveGame() {
    if (_generatedGame != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Game saved to library!'),
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
}