import 'package:flutter/material.dart';
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

class _WorksheetCreatorScreenState extends State<WorksheetCreatorScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _base64Image;
  List<int> _selectedGrades = [3];
  bool _isLoading = false;
  String? _generatedWorksheet;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worksheet Creator'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Creating worksheets...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 16),
                  _buildGradeSelector(),
                  const SizedBox(height: 24),
                  _buildGenerateButton(),
                  if (_generatedWorksheet != null) ...[
                    const SizedBox(height: 24),
                    _buildWorksheetCard(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildImagePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Textbook Page',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _imageFile!,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Grades',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose grades for differentiated worksheets',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(8, (index) {
                final grade = index + 1;
                final isSelected = _selectedGrades.contains(grade);
                return FilterChip(
                  label: Text('Grade $grade'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGrades.add(grade);
                      } else {
                        _selectedGrades.remove(grade);
                      }
                      _selectedGrades.sort();
                    });
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _imageFile != null && _selectedGrades.isNotEmpty
            ? _generateWorksheet
            : null,
        icon: const Icon(Icons.assignment),
        label: const Text('Generate Worksheets'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildWorksheetCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Generated Worksheets',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyWorksheet,
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: _printWorksheet,
                      tooltip: 'Print',
                    ),
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _saveWorksheet,
                      tooltip: 'Save',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              _generatedWorksheet!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyWorksheet() {
    // Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Worksheet copied to clipboard!')),
    );
  }

  Future<void> _printWorksheet() async {
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
          pw.SizedBox(height: 10),
          pw.Text('Grades: ${_selectedGrades.join(", ")}'),
          pw.SizedBox(height: 20),
          pw.Text(_generatedWorksheet ?? ''),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  void _saveWorksheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Worksheet saved to library!')),
    );
  }
}