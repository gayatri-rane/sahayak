import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';

class VisualAidScreen extends StatefulWidget {
  const VisualAidScreen({super.key});

  @override
  State<VisualAidScreen> createState() => _VisualAidScreenState();
}

class _VisualAidScreenState extends State<VisualAidScreen> {
  final _formKey = GlobalKey<FormState>();
  final _conceptController = TextEditingController();
  String _selectedMedium = 'blackboard';
  bool _isLoading = false;
  String? _visualInstructions;

  final List<String> _drawingMediums = [
    'blackboard',
    'whiteboard',
    'chart paper',
    'notebook',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Aid Creator'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Creating visual aid instructions...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildForm(),
                  if (_visualInstructions != null) ...[
                    const SizedBox(height: 24),
                    _buildInstructionsCard(),
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
                'Create Visual Aid',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _conceptController,
                decoration: const InputDecoration(
                  labelText: 'Concept to Illustrate',
                  hintText: 'e.g., Water Cycle, Parts of a Plant',
                  prefixIcon: Icon(Icons.lightbulb),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a concept';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _selectedMedium,
                decoration: const InputDecoration(
                  labelText: 'Drawing Medium',
                  prefixIcon: Icon(Icons.draw),
                ),
                items: _drawingMediums.map((medium) {
                  return DropdownMenuItem(
                    value: medium,
                    child: Text(medium[0].toUpperCase() + medium.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMedium = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateVisualAid,
                  icon: const Icon(Icons.brush),
                  label: const Text('Generate Instructions'),
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

  Widget _buildInstructionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Drawing Instructions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: _copyInstructions,
                  tooltip: 'Copy',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text('For $_selectedMedium'),
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            const SizedBox(height: 16),
            
            // Instructions with step highlighting
            ..._parseInstructions(_visualInstructions!),
          ],
        ),
      ),
    );
  }

  List<Widget> _parseInstructions(String instructions) {
    final lines = instructions.split('\n');
    final widgets = <Widget>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (RegExp(r'^\d+\.').hasMatch(line)) {
        // Numbered step
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      line.split('.')[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    line.substring(line.indexOf('.') + 1).trim(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: const TextStyle(fontSize: 16),
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

  void _copyInstructions() {
    // Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Instructions copied to clipboard!')),
    );
  }

  @override
  void dispose() {
    _conceptController.dispose();
    super.dispose();
  }
}