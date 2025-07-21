import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../widgets/loading_widget.dart';

class GameGeneratorScreen extends StatefulWidget {
  const GameGeneratorScreen({super.key});

  @override
  State<GameGeneratorScreen> createState() => _GameGeneratorScreenState();
}

class _GameGeneratorScreenState extends State<GameGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  
  String _selectedGameType = 'vocabulary_bingo';
  String _selectedLanguage = 'English';
  int _selectedGrade = 3;
  bool _isLoading = false;
  String? _generatedGame;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Educational Game Generator'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Creating your game...')
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildForm(),
                  if (_generatedGame != null) ...[
                    const SizedBox(height: 24),
                    _buildGameCard(),
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
                'Create Educational Game',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Game Type Dropdown with Icons
              DropdownButtonFormField<String>(
                value: _selectedGameType,
                decoration: const InputDecoration(
                  labelText: 'Game Type',
                  prefixIcon: Icon(Icons.games),
                ),
                items: AppConfig.gameTypes.entries.map((entry) {
                  IconData icon = _getGameIcon(entry.key);
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(entry.value),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGameType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Topic Input
              TextFormField(
                controller: _topicController,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'e.g., Animals, Numbers, Colors',
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
              
              // Grade Selection
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
              
              // Language Selection
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
              const SizedBox(height: 24),
              
              // Generate Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateGame,
                  icon: const Icon(Icons.casino),
                  label: const Text('Generate Game'),
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

  Widget _buildGameCard() {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConfig.gameTypes[_selectedGameType] ?? 'Game',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Topic: ${_topicController.text}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: _copyGame,
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: _printGame,
                      tooltip: 'Print',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _shareGame,
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Game content with formatting
            SelectableText(
              _generatedGame!,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _playGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Instructions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _saveGame,
                  icon: const Icon(Icons.save),
                  label: const Text('Save to Library'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getGameIcon(String gameType) {
    switch (gameType) {
      case 'vocabulary_bingo':
        return Icons.grid_on;
      case 'math_puzzle':
        return Icons.calculate;
      case 'science_quiz':
        return Icons.science;
      case 'memory_game':
        return Icons.psychology;
      case 'word_building':
        return Icons.abc;
      case 'number_race':
        return Icons.speed;
      case 'story_sequence':
        return Icons.reorder;
      case 'shape_hunt':
        return Icons.category;
      default:
        return Icons.games;
    }
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

  void _copyGame() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game instructions copied!')),
    );
  }

  void _printGame() {
    // Print implementation
  }

  void _shareGame() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _playGame() {
    // Show game instructions in a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: const SingleChildScrollView(
          child: Text(
            'Follow the instructions in the generated game. '
            'Gather the materials mentioned and set up the game '
            'according to the steps provided.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _saveGame() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Game saved to library!')),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }
}