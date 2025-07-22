class AppConfig {
  // static const String baseUrl = String.fromEnvironment(
  //   'API_URL',
  //   defaultValue: 'http://localhost:5000'
  // );
  
  // For production
  static const String baseUrl = 'https://sahayak-backend-eseqqxofka-uc.a.run.app';
  
  static const Duration apiTimeout = Duration(seconds: 30);
  
  static const List<String> supportedLanguages = [
    'Hindi',
    'English', 
    'Marathi',
    'Tamil',
    'Telugu',
    'Kannada',
    'Malayalam',
    'Bengali',
    'Gujarati',
    'Punjabi',
    'Odia'
  ];
  
  static const List<String> subjects = [
    'Mathematics',
    'Science',
    'Social Studies',
    'Language',
    'Environmental Studies',
    'Computer Basics',
    'Art & Craft',
    'Physical Education',
    'Moral Science'
  ];
  
  static const Map<String, String> gameTypes = {
    'vocabulary_bingo': 'Vocabulary Bingo',
    'math_puzzle': 'Math Puzzles',
    'science_quiz': 'Science Quiz',
    'memory_game': 'Memory Game',
    'word_building': 'Word Building',
    'number_race': 'Number Race',
    'story_sequence': 'Story Sequencing',
    'shape_hunt': 'Shape Hunt'
  };
}