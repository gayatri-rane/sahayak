import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _authToken;
  Map<String, dynamic>? _userProfile;
  
  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  Map<String, dynamic>? get userProfile => _userProfile;
  
  AuthService() {
    _loadAuthState();
  }
  
  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _isAuthenticated = _authToken != null;
    
    if (_isAuthenticated) {
      // Load user profile from storage
      final profileJson = prefs.getString('user_profile');
      if (profileJson != null) {
        _userProfile = Map<String, dynamic>.from(
          jsonDecode(profileJson) as Map
        );
      }
    }
    
    notifyListeners();
  }
  
  Future<void> login(String username, String password) async {
    // For demo purposes, accept any credentials
    // In production, validate with backend
    _authToken = 'demo-token-123';
    _isAuthenticated = true;
    _userProfile = {
      'username': username,
      'name': 'Teacher',
      'school': 'Rural Primary School',
    };
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', _authToken!);
    await prefs.setString('user_profile', jsonEncode(_userProfile));
    
    notifyListeners();
  }
  
  Future<void> logout() async {
    _isAuthenticated = false;
    _authToken = null;
    _userProfile = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
    
    notifyListeners();
  }
}