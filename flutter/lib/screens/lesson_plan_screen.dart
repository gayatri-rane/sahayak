import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../widgets/loading_widget.dart';

class LessonPlanScreen extends StatefulWidget {
  const LessonPlanScreen({super.key});

  @override
  State<LessonPlanScreen> createState() => _LessonPlanScreenState();
}

class _LessonPlanScreenState extends State<LessonPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalsController = TextEditingController();
  
  List<int> _selectedGrades = [3, 4];
  List<String> _selectedSubjects = ['Mathematics', 'Science'];
  String _duration = 'week';
  String _language = 'English';
  bool _isLoading = false;
  String? _generatedPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lesson Plan Creator'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Creating lesson plan...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildForm(),
                  if (_generatedPlan != null) ...[
                    const SizedBox(height: 24),
                    _buildPlanCard(),
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
                'Create Lesson Plan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Grade Selection
              _buildSectionTitle('Select Grades'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(8, (index) {
                  final grade = index + 1;
                  return FilterChip(
                    label: Text('Grade $grade'),
                    selected: _selectedGrades.contains(grade),
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
              const SizedBox(height: 20),
              
              // Subject Selection
              _buildSectionTitle('Select Subjects'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConfig.subjects.map((subject) {
                  return FilterChip(
                    label: Text(subject),
                    selected: _selectedSubjects.contains(subject),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSubjects.add(subject);
                        } else {
                          _selectedSubjects.remove(subject);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              // Weekly Goals
              TextFormField(
                controller: _goalsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Weekly Goals',
                  hintText: 'e.g., Teach multiplication tables, introduce plant life cycle',
                  prefixIcon: Icon(Icons.flag),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter weekly goals';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Duration and Language
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _duration,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'day', child: Text('Daily')),
                        DropdownMenuItem(value: 'week', child: Text('Weekly')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _duration = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _language,
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
                          _language = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _canGenerate() ? _generateLessonPlan : null,
                  icon: const Icon(Icons.create),
                  label: const Text('Generate Lesson Plan'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
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
                  '${_duration == "week" ? "Weekly" : "Daily"} Lesson Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyPlan,
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: _printPlan,
                      tooltip: 'Print',
                    ),
                    IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: _downloadPlan,
                      tooltip: 'Download',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Metadata chips
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('Grades: ${_selectedGrades.join(", ")}'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
                Chip(
                  label: Text('${_selectedSubjects.length} Subjects'),
                  backgroundColor: Colors.green.withOpacity(0.1),
                ),
                Chip(
                  label: Text(_language),
                  backgroundColor: Colors.orange.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Plan content
            SelectableText(
              _generatedPlan!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveToLibrary,
                    icon: const Icon(Icons.save),
                    label: const Text('Save to Library'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareWithTeam,
                    icon: const Icon(Icons.share),
                    label: const Text('Share with Team'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _canGenerate() {
    return _selectedGrades.isNotEmpty && 
           _selectedSubjects.isNotEmpty && 
           _goalsController.text.isNotEmpty;
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

  void _copyPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lesson plan copied!')),
    );
  }

  void _printPlan() {
    // Print implementation
  }

  void _downloadPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading lesson plan...')),
    );
  }

  void _saveToLibrary() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to library!')),
    );
  }

  void _shareWithTeam() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing feature coming soon!')),
    );
  }

  @override
  void dispose() {
    _goalsController.dispose();
    super.dispose();
  }
}