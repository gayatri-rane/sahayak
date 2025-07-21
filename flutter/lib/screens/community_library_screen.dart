import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../widgets/loading_widget.dart';

class CommunityLibraryScreen extends StatefulWidget {
  const CommunityLibraryScreen({super.key});

  @override
  State<CommunityLibraryScreen> createState() => _CommunityLibraryScreenState();
}

class _CommunityLibraryScreenState extends State<CommunityLibraryScreen> {
  final _searchController = TextEditingController();
  
  bool _isLoading = false;
  List<dynamic> _resources = [];
  
  // Filters
  String? _selectedType;
  int? _selectedGrade;
  String? _selectedSubject;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _searchResources();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Library'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: _uploadResource,
            tooltip: 'Upload Resource',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search resources...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchResources();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _searchResources(),
                ),
                const SizedBox(height: 16),
                
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        'Type',
                        _selectedType,
                        ['story', 'worksheet', 'lesson_plan', 'game'],
                        (value) => setState(() {
                          _selectedType = value;
                          _searchResources();
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Grade',
                        _selectedGrade?.toString(),
                        List.generate(8, (i) => (i + 1).toString()),
                        (value) => setState(() {
                          _selectedGrade = value != null ? int.parse(value) : null;
                          _searchResources();
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Subject',
                        _selectedSubject,
                        AppConfig.subjects,
                        (value) => setState(() {
                          _selectedSubject = value;
                          _searchResources();
                        }),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Language',
                        _selectedLanguage,
                        AppConfig.supportedLanguages,
                        (value) => setState(() {
                          _selectedLanguage = value;
                          _searchResources();
                        }),
                      ),
                      const SizedBox(width: 16),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear Filters'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Results
          Expanded(
            child: _isLoading
                ? const LoadingWidget(message: 'Searching resources...')
                : _resources.isEmpty
                    ? _buildEmptyState()
                    : _buildResourceGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? selectedValue,
    List<String> options,
    Function(String?) onSelected,
  ) {
    return PopupMenuButton<String?>(
      child: Chip(
        label: Text(selectedValue ?? label),
        deleteIcon: selectedValue != null ? const Icon(Icons.close, size: 18) : null,
        onDeleted: selectedValue != null ? () => onSelected(null) : null,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('All'),
        ),
        ...options.map((option) => PopupMenuItem(
              value: option,
              child: Text(option),
            )),
      ],
      onSelected: onSelected,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No resources found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _resources.length,
      itemBuilder: (context, index) {
        final resource = _resources[index];
        return _buildResourceCard(resource);
      },
    );
  }

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final metadata = resource['metadata'] ?? {};
    final ratings = metadata['ratings'] ?? [];
    final avgRating = ratings.isEmpty
        ? 0.0
        : ratings.map((r) => r['rating']).reduce((a, b) => a + b) / ratings.length;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _viewResource(resource),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(resource['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  resource['type']?.toUpperCase() ?? 'RESOURCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(resource['type']),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Preview
              Expanded(
                child: Text(
                  resource['preview'] ?? resource['content'] ?? '',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              
              // Metadata
              if (metadata['grades'] != null)
                Text(
                  'Grades: ${metadata['grades'].join(", ")}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 4),
              
              // Rating and stats
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                        i < avgRating ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      )),
                  const SizedBox(width: 4),
                  Text(
                    '(${ratings.length})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.download,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${metadata['downloads'] ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'story':
        return Colors.blue;
      case 'worksheet':
        return Colors.green;
      case 'lesson_plan':
        return Colors.orange;
      case 'game':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _searchResources() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.searchResources(
        query: _searchController.text.isNotEmpty ? _searchController.text : null,
        type: _selectedType,
        grade: _selectedGrade,
        subject: _selectedSubject,
        language: _selectedLanguage,
      );

      setState(() {
        _resources = result['resources'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resources = [];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching resources: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedGrade = null;
      _selectedSubject = null;
      _selectedLanguage = null;
    });
    _searchResources();
  }

  void _viewResource(Map<String, dynamic> resource) {
    showDialog(
      context: context,
      builder: (context) => _ResourceDetailDialog(resource: resource),
    );
  }

  void _uploadResource() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Resource'),
        content: const Text('Resource upload functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Resource Detail Dialog
class _ResourceDetailDialog extends StatelessWidget {
  final Map<String, dynamic> resource;

  const _ResourceDetailDialog({required this.resource});

  @override
  Widget build(BuildContext context) {
    final metadata = resource['metadata'] ?? {};
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resource['type']?.toUpperCase() ?? 'RESOURCE',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          metadata['topic'] ?? 'Community Resource',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metadata chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (metadata['grades'] != null)
                          Chip(
                            label: Text('Grades: ${metadata['grades'].join(", ")}'),
                            backgroundColor: Colors.blue.withOpacity(0.1),
                          ),
                        if (metadata['subject'] != null)
                          Chip(
                            label: Text(metadata['subject']),
                            backgroundColor: Colors.green.withOpacity(0.1),
                          ),
                        if (metadata['language'] != null)
                          Chip(
                            label: Text(metadata['language']),
                            backgroundColor: Colors.orange.withOpacity(0.1),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Content
                    Text(
                      resource['content'] ?? resource['preview'] ?? '',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    
                    // Stats
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'By ${metadata['teacher_id'] ?? 'Anonymous'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.download, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${metadata['downloads'] ?? 0} downloads',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Copy functionality
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Resource copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      // Remix functionality
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Remix feature coming soon!')),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Remix'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Download functionality
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Downloading resource...')),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
