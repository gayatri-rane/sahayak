import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  static const String baseUrl = AppConfig.baseUrl;
  
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  Future<Map<String, String>> getHeaders() async {
    final token = await getAuthToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
  
  // Health Check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(AppConfig.apiTimeout);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Generate Story
  Future<Map<String, dynamic>> generateStory({
    required String language,
    required int grade,
    required String topic,
    required String context,
    bool saveToLibrary = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-story'),
      headers: await getHeaders(),
      body: jsonEncode({
        'language': language,
        'grade': grade,
        'topic': topic,
        'context': context,
        'save_to_library': saveToLibrary,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate story: ${response.body}');
    }
  }
  
  // Create Worksheet from Image
  Future<Map<String, dynamic>> createWorksheet({
    required String base64Image,
    required List<int> grades,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-worksheet'),
      headers: await getHeaders(),
      body: jsonEncode({
        'image': base64Image,
        'grades': grades,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create worksheet: ${response.body}');
    }
  }
  
  // Explain Concept
  Future<Map<String, dynamic>> explainConcept({
    required String question,
    required String language,
    required int gradeLevel,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/explain-concept'),
      headers: await getHeaders(),
      body: jsonEncode({
        'question': question,
        'language': language,
        'grade_level': gradeLevel,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to explain concept: ${response.body}');
    }
  }
  
  // Create Visual Aid
  Future<Map<String, dynamic>> createVisualAid({
    required String concept,
    String drawingMedium = 'blackboard',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-visual-aid'),
      headers: await getHeaders(),
      body: jsonEncode({
        'concept': concept,
        'drawing_medium': drawingMedium,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create visual aid: ${response.body}');
    }
  }
  
  // Generate Game
  Future<Map<String, dynamic>> generateGame({
    required String gameType,
    required String topic,
    required int grade,
    String language = 'English',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-game'),
      headers: await getHeaders(),
      body: jsonEncode({
        'game_type': gameType,
        'topic': topic,
        'grade': grade,
        'language': language,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate game: ${response.body}');
    }
  }
  
  // Create Lesson Plan
  Future<Map<String, dynamic>> createLessonPlan({
    required List<int> grades,
    required List<String> subjects,
    required String weeklyGoals,
    String duration = 'week',
    String language = 'English',
    bool save = true,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create-lesson-plan'),
      headers: await getHeaders(),
      body: jsonEncode({
        'grades': grades,
        'subjects': subjects,
        'weekly_goals': weeklyGoals,
        'duration': duration,
        'language': language,
        'save': save,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create lesson plan: ${response.body}');
    }
  }
  
  // Get Student Progress
  Future<Map<String, dynamic>> getStudentProgress(String studentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/student-progress?student_id=$studentId'),
      headers: await getHeaders(),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get student progress: ${response.body}');
    }
  }
  
  // Update Student Progress
  Future<Map<String, dynamic>> updateStudentProgress({
    required String studentId,
    Map<String, dynamic>? assessment,
    bool? activityCompleted,
    String? readingLevel,
    List<String>? strengths,
    List<String>? areasForImprovement,
  }) async {
    final body = {
      'student_id': studentId,
      if (assessment != null) 'assessment': assessment,
      if (activityCompleted != null) 'activity_completed': activityCompleted,
      if (readingLevel != null) 'reading_level': readingLevel,
      if (strengths != null) 'strengths': strengths,
      if (areasForImprovement != null) 'areas_for_improvement': areasForImprovement,
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/analytics/student-progress'),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update student progress: ${response.body}');
    }
  }
  
  // Search Resources
  Future<Map<String, dynamic>> searchResources({
    String? query,
    int? grade,
    String? subject,
    String? language,
    String? type,
  }) async {
    final queryParams = {
      if (query != null) 'query': query,
      if (grade != null) 'grade': grade.toString(),
      if (subject != null) 'subject': subject,
      if (language != null) 'language': language,
      if (type != null) 'type': type,
    };
    
    final uri = Uri.parse('$baseUrl/resources/search')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search resources: ${response.body}');
    }
  }
  
  // Upload Image
  Future<String> imageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}