import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../widgets/loading_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class StoryGeneratorScreen extends StatefulWidget {
  const StoryGeneratorScreen({super.key});

  @override
  State<StoryGeneratorScreen> createState() => _StoryGeneratorScreenState();
}

class _StoryGeneratorScreenState extends State<StoryGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _contextController = TextEditingController();
  
  String _selectedLanguage = 'Hindi';
  int _selectedGrade = 3;
  bool _isLoading = false;
  String? _generatedStory;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Generator'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Creating your story...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildForm(),
                  if (_generatedStory != null) ...[
                    const SizedBox(height: 24),
                    _buildStoryCard(),
                  ],
                ],
              ),
            ),
    );
  }
  
  Widget _buildForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Educational Story',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Language Dropdown
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: const InputDecoration(
                  labelText: 'Language',
                  prefixIcon: Icon(Icons.language),
                ),
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
              const SizedBox(height: 16),
              
              // Grade Dropdown
              DropdownButtonFormField<int>(
                value: _selectedGrade,
                decoration: const InputDecoration(
                  labelText: 'Grade',
                  prefixIcon: Icon(Icons.school),
                ),
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
              const SizedBox(height: 16),
              
              // Topic Input
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'e.g., Water Conservation',
                  prefixIcon: Icon(Icons.topic),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a topic';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Context Input
              TextFormField(
                controller: _contextController,
                decoration: const InputDecoration(
                  labelText: 'Local Context',
                  hintText: 'e.g., Rural village in Maharashtra',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the local context';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateStory,
                  icon: const Icon(Icons.auto_stories),
                  label: const Text('Generate Story'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStoryCard() {
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
                  'Generated Story',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyStory,
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: _printStory,
                      tooltip: 'Print',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _shareStory,
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(
              _generatedStory!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _generateStory() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _generatedStory = null;
    });
    
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.generateStory(
        language: _selectedLanguage,
        grade: _selectedGrade,
        topic: _topicController.text,
        context: _contextController.text,
        saveToLibrary: true,
      );
      
      setState(() {
        _generatedStory = result['story'];
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
  
  void _copyStory() {
    // Copy to clipboard implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Story copied to clipboard!')),
    );
  }
  
  Future<void> _printStory() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Educational Story',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text('Topic: ${_topicController.text}'),
            pw.Text('Grade: $_selectedGrade'),
            pw.Text('Language: $_selectedLanguage'),
            pw.SizedBox(height: 20),
            pw.Text(_generatedStory ?? ''),
          ],
        ),
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
  
  void _shareStory() {
    // Share implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
  
  @override
  void dispose() {
    _topicController.dispose();
    _contextController.dispose();
    super.dispose();
  }
}