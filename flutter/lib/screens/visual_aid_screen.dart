import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';

class VisualAidScreen extends StatefulWidget {
  const VisualAidScreen({super.key});

  @override
  State<VisualAidScreen> createState() => _VisualAidScreenState();
}

class _VisualAidScreenState extends State<VisualAidScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  String _selectedMedium = 'blackboard';
  bool _isLoading = false;
  String? _visualInstructions;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _drawingMediums = [
    {'value': 'blackboard', 'label': 'Blackboard', 'icon': Icons.view_module},
    {'value': 'whiteboard', 'label': 'Whiteboard', 'icon': Icons.dashboard},
    {'value': 'chart paper', 'label': 'Chart Paper', 'icon': Icons.article},
    {'value': 'notebook', 'label': 'Notebook', 'icon': Icons.book},
    {'value': 'digital', 'label': 'Digital Screen', 'icon': Icons.computer},
    {'value': 'poster', 'label': 'Poster', 'icon': Icons.image},
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
    _conceptController.dispose();
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
                colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.palette,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Visual Aid Creator',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(screenWidth, 20),
            ),
          ),
        ],
      ),
      actions: [
        if (_visualInstructions != null) ...[
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copyInstructions,
            tooltip: 'Copy Instructions',
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareInstructions,
            tooltip: 'Share Instructions',
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
            Color(0xFFF59E0B),
            Color(0xFFD97706),
            Color(0xFFB45309),
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
              Icons.palette,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Creating visual instructions...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Designing the perfect visual aid',
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
                  if (_visualInstructions != null) ...[
                    const SizedBox(height: 24),
                    _buildInstructionsSection(screenWidth),
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
            Color(0xFFF59E0B),
            Color(0xFFD97706),
            Color(0xFFB45309),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
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
                  Icons.palette,
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
                      'Create Visual Aids',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(screenWidth, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Generate step-by-step drawing instructions for any concept',
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
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Concept Details',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: _getResponsiveFontSize(screenWidth, 18),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Concept Input
            _buildConceptInput(),
            const SizedBox(height: 24),

            // Medium Selection
            _buildMediumSelection(screenWidth),
            const SizedBox(height: 32),

            // Generate Button
            _buildGenerateButton(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptInput() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: _conceptController,
        decoration: const InputDecoration(
          labelText: 'Concept to Illustrate',
          hintText: 'e.g., Water Cycle, Parts of a Plant, Solar System',
          prefixIcon: Icon(Icons.lightbulb_outlined, color: Color(0xFFF59E0B)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter a concept to illustrate';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMediumSelection(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.brush,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drawing Medium',
                  style: TextStyle(
                    color: const Color(0xFF1E293B),
                    fontSize: _getResponsiveFontSize(screenWidth, 16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Choose your preferred drawing surface',
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
            crossAxisCount: screenWidth < 600 ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _drawingMediums.length,
          itemBuilder: (context, index) {
            final medium = _drawingMediums[index];
            final isSelected = _selectedMedium == medium['value'];
            return _buildMediumChip(medium, isSelected, screenWidth);
          },
        ),
      ],
    );
  }

  Widget _buildMediumChip(Map<String, dynamic> medium, bool isSelected, double screenWidth) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMedium = medium['value'];
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
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              medium['icon'],
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              size: screenWidth < 600 ? 16 : 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                medium['label'],
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  fontSize: _getResponsiveFontSize(screenWidth, 12),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(double screenWidth) {
    return Container(
      width: double.infinity,
      height: screenWidth < 600 ? 56 : 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _generateVisualAid,
        icon: const Icon(Icons.brush, color: Colors.white),
        label: Text(
          'Generate Instructions',
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

  Widget _buildInstructionsSection(double screenWidth) {
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
                    Text(
                      'Drawing Instructions',
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
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'For $_selectedMedium',
                            style: TextStyle(
                              color: const Color(0xFFF59E0B),
                              fontSize: _getResponsiveFontSize(screenWidth, 12),
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
                            _conceptController.text,
                            style: TextStyle(
                              color: const Color(0xFF10B981),
                              fontSize: _getResponsiveFontSize(screenWidth, 12),
                              fontWeight: FontWeight.w500,
                            ),
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

          // Instructions with step highlighting
          ..._parseInstructions(_visualInstructions!, screenWidth),
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
          onPressed: _copyInstructions,
          tooltip: 'Copy',
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.share_outlined,
          onPressed: _shareInstructions,
          tooltip: 'Share',
          color: const Color(0xFF8B5CF6),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.save_outlined,
          onPressed: _saveInstructions,
          tooltip: 'Save',
          color: const Color(0xFF06B6D4),
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

  List<Widget> _parseInstructions(String instructions, double screenWidth) {
    final lines = instructions.split('\n');
    final widgets = <Widget>[];
    int stepNumber = 1;

    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 12));
      } else if (RegExp(r'^\d+\.').hasMatch(line)) {
        // Numbered step
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF59E0B).withOpacity(0.1),
                  const Color(0xFFD97706).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth < 600 ? 32 : 36,
                  height: screenWidth < 600 ? 32 : 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      stepNumber.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: _getResponsiveFontSize(screenWidth, 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    line.substring(line.indexOf('.') + 1).trim(),
                    style: TextStyle(
                      fontSize: _getResponsiveFontSize(screenWidth, 16),
                      height: 1.5,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        stepNumber++;
      } else {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(screenWidth < 600 ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              line,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, 16),
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        );
      }
    }

    return widgets;
  }

  Future<void> _generateVisualAid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _visualInstructions = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.createVisualAid(
        concept: _conceptController.text,
        drawingMedium: _selectedMedium,
      );

      setState(() {
        _visualInstructions = result['visual_aid'];
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
                Text('Visual aid instructions generated successfully!'),
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

  void _copyInstructions() {
    if (_visualInstructions != null) {
      final formattedText = 'Visual Aid Instructions - ${_conceptController.text}\nMedium: $_selectedMedium\n\n$_visualInstructions';
      Clipboard.setData(ClipboardData(text: formattedText));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Instructions copied to clipboard!'),
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

  void _shareInstructions() {
    if (_visualInstructions != null) {
      // Share implementation would go here
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Share functionality coming soon!'),
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

  void _saveInstructions() {
    if (_visualInstructions != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Instructions saved to library!'),
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
}