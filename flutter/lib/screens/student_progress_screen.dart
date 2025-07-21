import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';

class StudentProgressScreen extends StatefulWidget {
  const StudentProgressScreen({super.key});

  @override
  State<StudentProgressScreen> createState() => _StudentProgressScreenState();
}

class _StudentProgressScreenState extends State<StudentProgressScreen> {
  String? _selectedStudentId;
  Map<String, dynamic>? _progressData;
  bool _isLoading = false;

  // Mock student data - replace with actual data
  final List<Map<String, String>> _students = [
    {'id': 'student001', 'name': 'Raj Kumar', 'grade': '3'},
    {'id': 'student002', 'name': 'Priya Sharma', 'grade': '4'},
    {'id': 'student003', 'name': 'Amit Patel', 'grade': '3'},
    {'id': 'student004', 'name': 'Anita Singh', 'grade': '5'},
    {'id': 'student005', 'name': 'Vikram Reddy', 'grade': '4'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Progress'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewStudent,
            tooltip: 'Add Student',
          ),
        ],
      ),
      body: Row(
        children: [
          // Student List
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: _buildStudentList(),
          ),
          
          // Progress Details
          Expanded(
            child: _selectedStudentId == null
                ? _buildEmptyState()
                : _isLoading
                    ? const LoadingWidget(message: 'Loading progress...')
                    : _buildProgressDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search students...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) {
              // Implement search
            },
          ),
        ),
        
        // Student tiles
        Expanded(
          child: ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              final isSelected = student['id'] == _selectedStudentId;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300],
                  child: Text(
                    student['name']![0],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                title: Text(student['name']!),
                subtitle: Text('Grade ${student['grade']}'),
                selected: isSelected,
                onTap: () => _selectStudent(student['id']!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a student to view progress',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDetails() {
    final selectedStudent = _students.firstWhere(
      (s) => s['id'] == _selectedStudentId,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      selectedStudent['name']![0],
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedStudent['name']!,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          'Grade ${selectedStudent['grade']} • Student ID: $_selectedStudentId',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _updateProgress,
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Progress'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Progress Overview
          Row(
            children: [
              _buildStatCard(
                'Activities Completed',
                _progressData?['activities_completed']?.toString() ?? '0',
                Icons.check_circle,
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Reading Level',
                _progressData?['reading_level'] ?? 'Not Assessed',
                Icons.menu_book,
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Assessments',
                '${_progressData?['assessments']?.length ?? 0}',
                Icons.assignment,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Strengths & Areas for Improvement
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSection(
                  'Strengths',
                  _progressData?['strengths'] ?? [],
                  Icons.star,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSection(
                  'Areas for Improvement',
                  _progressData?['areas_for_improvement'] ?? [],
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent Assessments
          _buildAssessmentsSection(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<dynamic> items,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              Text(
                'None recorded',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Text(item.toString()),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentsSection() {
    final assessments = _progressData?['assessments'] ?? [];
    
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
                  'Recent Assessments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _viewAllAssessments,
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (assessments.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No assessments recorded',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: assessments.length > 3 ? 3 : assessments.length,
                itemBuilder: (context, index) {
                  final assessment = assessments[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getScoreColor(assessment['score']),
                      child: Text(
                        '${assessment['score']}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(assessment['type'] ?? 'Assessment'),
                    subtitle: Text(assessment['date'] ?? ''),
                    trailing: assessment['notes'] != null
                        ? IconButton(
                            icon: const Icon(Icons.notes),
                            onPressed: () => _showNotes(assessment['notes']),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(dynamic score) {
    if (score == null) return Colors.grey;
    final scoreNum = int.tryParse(score.toString()) ?? 0;
    if (scoreNum >= 80) return Colors.green;
    if (scoreNum >= 60) return Colors.orange;
    return Colors.red;
  }

  Future<void> _selectStudent(String studentId) async {
    setState(() {
      _selectedStudentId = studentId;
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.getStudentProgress(studentId);
      
      setState(() {
        _progressData = result['progress'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _progressData = {
          'activities_completed': 0,
          'reading_level': 'Not Assessed',
          'assessments': [],
          'strengths': [],
          'areas_for_improvement': [],
        };
      });
    }
  }

  void _addNewStudent() {
    // Show add student dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Student'),
        content: const Text('Add student functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateProgress() {
    // Show update progress dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: const Text('Progress update functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _viewAllAssessments() {
    // Navigate to assessments page
  }

  void _showNotes(String notes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assessment Notes'),
        content: Text(notes),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}