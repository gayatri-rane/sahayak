import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class WorksheetCreatorScreen extends StatefulWidget {
  const WorksheetCreatorScreen({super.key});

  @override
  State<WorksheetCreatorScreen> createState() => _WorksheetCreatorScreenState();
}

class _WorksheetCreatorScreenState extends State<WorksheetCreatorScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _base64Image;
  List<int> _selectedGrades = [3];
  bool _isLoading = false;
  String? _generatedWorksheet;

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
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Worksheet Creator',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: _getResponsiveFontSize(screenWidth, 20),
            ),
          ),
        ],
      ),
      actions: [
        if (_generatedWorksheet != null) ...[
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copyWorksheet,
            tooltip: 'Copy Worksheet',
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveWorksheet,
            tooltip: 'Save Worksheet',
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
            Color(0xFF10B981),
            Color(0xFF059669),
            Color(0xFF047857),
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
              Icons.assignment,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Creating worksheets...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Analyzing your textbook page',
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
                  _buildImageSection(screenWidth),
                  const SizedBox(height: 24),
                  _buildGradeSection(screenWidth),
                  const SizedBox(height: 32),
                  _buildGenerateButton(screenWidth),
                  if (_generatedWorksheet != null) ...[
                    const SizedBox(height: 24),
                    _buildWorksheetSection(screenWidth),
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
            Color(0xFF10B981),
            Color(0xFF059669),
            Color(0xFF047857),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
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
                  Icons.assignment,
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
                      'Create Worksheets',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveFontSize(screenWidth, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Upload textbook page to generate differentiated worksheets',
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

  Widget _buildImageSection(double screenWidth) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Upload Textbook Page',
                style: TextStyle(
                  color: const Color(0xFF1E293B),
                  fontSize: _getResponsiveFontSize(screenWidth, 18),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Take a photo or choose from gallery',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: _getResponsiveFontSize(screenWidth, 14),
            ),
          ),
          const SizedBox(height: 20),

          // Image Display or Placeholder
          if (_imageFile != null) ...[
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: screenWidth < 600 ? 250 : 350,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _imageFile = null;
                      _base64Image = null;
                    }),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.edit),
                    label: const Text('Change'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              width: double.infinity,
              height: screenWidth < 600 ? 200 : 250,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  style: BorderStyle.solid,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No image selected',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: _getResponsiveFontSize(screenWidth, 16),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload a textbook page to get started',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: _getResponsiveFontSize(screenWidth, 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            screenWidth >= 600
                ? Row(
              children: [
                Expanded(child: _buildCameraButton()),
                const SizedBox(width: 16),
                Expanded(child: _buildGalleryButton()),
              ],
            )
                : Column(
              children: [
                _buildCameraButton(),
                const SizedBox(height: 12),
                _buildGalleryButton(),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _pickImage(ImageSource.camera),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text('Camera', style: TextStyle(color: Colors.white)),
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

  Widget _buildGalleryButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF10B981), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _pickImage(ImageSource.gallery),
        icon: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
        label: const Text('Gallery', style: TextStyle(color: Color(0xFF10B981))),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeSection(double screenWidth) {
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.school,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Grades',
                    style: TextStyle(
                      color: const Color(0xFF1E293B),
                      fontSize: _getResponsiveFontSize(screenWidth, 18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Choose grades for differentiated worksheets',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: _getResponsiveFontSize(screenWidth, 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
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
      ),
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
            colors: [Color(0xFF10B981), Color(0xFF059669)],
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
              color: const Color(0xFF10B981).withOpacity(0.3),
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

  Widget _buildGenerateButton(double screenWidth) {
    final canGenerate = _imageFile != null && _selectedGrades.isNotEmpty;

    return Container(
      width: double.infinity,
      height: screenWidth < 600 ? 56 : 64,
      decoration: BoxDecoration(
        gradient: canGenerate
            ? const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        )
            : null,
        color: canGenerate ? null : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
        boxShadow: canGenerate
            ? [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: ElevatedButton.icon(
        onPressed: canGenerate ? _generateWorksheet : null,
        icon: Icon(
          Icons.assignment,
          color: canGenerate ? Colors.white : const Color(0xFF94A3B8),
        ),
        label: Text(
          'Generate Worksheets',
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

  Widget _buildWorksheetSection(double screenWidth) {
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
                      'Generated Worksheets',
                      style: TextStyle(
                        color: const Color(0xFF1E293B),
                        fontSize: _getResponsiveFontSize(screenWidth, 18),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Grades: ${_selectedGrades.join(", ")}',
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontSize: _getResponsiveFontSize(screenWidth, 12),
                      ),
                    ),
                  ],
                ),
              ),
              _buildActionButtons(screenWidth),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SelectableText(
              _generatedWorksheet!,
              style: TextStyle(
                fontSize: _getResponsiveFontSize(screenWidth, 16),
                height: 1.6,
                color: const Color(0xFF1E293B),
              ),
            ),
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
          onPressed: _copyWorksheet,
          tooltip: 'Copy',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.print_outlined,
          onPressed: _printWorksheet,
          tooltip: 'Print',
          color: const Color(0xFF06B6D4),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.save_outlined,
          onPressed: _saveWorksheet,
          tooltip: 'Save',
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

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF10B981)),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });

        // Convert to base64
        final bytes = await _imageFile!.readAsBytes();
        _base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Image uploaded successfully!'),
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
    } catch (e) {
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

  Future<void> _generateWorksheet() async {
    if (_base64Image == null || _selectedGrades.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedWorksheet = null;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.createWorksheet(
        base64Image: _base64Image!,
        grades: _selectedGrades,
      );

      setState(() {
        _generatedWorksheet = result['worksheet'];
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
                Text('Worksheets generated successfully!'),
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

  void _copyWorksheet() {
    if (_generatedWorksheet != null) {
      Clipboard.setData(ClipboardData(text: _generatedWorksheet!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Worksheet copied to clipboard!'),
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

  Future<void> _printWorksheet() async {
    if (_generatedWorksheet == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Differentiated Worksheets',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Grades: ${_selectedGrades.join(", ")}'),
          pw.Text('Generated on: ${DateTime.now().toString().split(' ')[0]}'),
          pw.SizedBox(height: 30),
          pw.Text(
            _generatedWorksheet!,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 1.5),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  void _saveWorksheet() {
    if (_generatedWorksheet != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Worksheet saved to library!'),
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