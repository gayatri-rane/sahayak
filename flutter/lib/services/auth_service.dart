import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  User? _user;
  bool _isLoading = false;
  Map<String, dynamic>? _userProfile;

  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  User? get user => _user;
  String? get authToken => _user?.uid;
  Map<String, dynamic>? get userProfile => _userProfile;

  AuthService() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _isLoading = true;
    notifyListeners();

    // Get current user immediately
    _user = _auth.currentUser;
    if (_user != null) {
      await _loadUserProfile();
    }

    _isLoading = false;
    notifyListeners();

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) async {
      print('Auth state changed: ${user?.email ?? 'null'}');

      if (_user?.uid != user?.uid) {
        _user = user;

        if (user != null) {
          await _loadUserProfile();
          print('User profile loaded: ${_userProfile?['name']}');
        } else {
          _userProfile = null;
          print('User signed out');
        }

        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile_${_user!.uid}');

      if (profileJson != null) {
        _userProfile = Map<String, dynamic>.from(
            jsonDecode(profileJson) as Map
        );
      } else {
        // Create default profile from user data
        _userProfile = {
          'uid': _user!.uid,
          'name': _user!.displayName ?? 'User',
          'email': _user!.email ?? '',
          'photoUrl': _user!.photoURL ?? '',
          'school': '',
          'phone': _user!.phoneNumber ?? '',
          'subject': '',
          'gradeLevel': '',
          'experience': '',
          'isAnonymous': _user!.isAnonymous,
          'profileCompleted': false,
          'createdAt': DateTime.now().toIso8601String(),
          'lastUpdated': DateTime.now().toIso8601String(),
        };
        await _saveUserProfile();
      }
      print('Profile loaded for: ${_userProfile?['name']}');
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _saveUserProfile() async {
    if (_user == null || _userProfile == null) return;

    try {
      // Update lastUpdated timestamp
      _userProfile!['lastUpdated'] = DateTime.now().toIso8601String();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'user_profile_${_user!.uid}',
          jsonEncode(_userProfile)
      );
      print('Profile saved successfully');
    } catch (e) {
      print('Error saving user profile: $e');
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Starting Google Sign In...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('Google Sign In cancelled by user');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('Google account selected: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      print('Got Google auth tokens');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Created Firebase credential');

      // Once signed in, return the UserCredential
      final UserCredential result = await _auth.signInWithCredential(credential);

      print('Firebase sign in completed: ${result.user?.email}');

      _isLoading = false;

      // Force immediate update
      _user = result.user;
      if (_user != null) {
        await _loadUserProfile();
      }

      notifyListeners();

      return result.user != null;

    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      throw Exception('Firebase Auth Error: ${e.message}');
    } catch (e) {
      print('Google sign-in error: $e');
      _isLoading = false;
      notifyListeners();
      throw Exception('Google sign-in failed: $e');
    }
  }

  // Anonymous Sign In
  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Starting anonymous sign in...');

      final UserCredential result = await _auth.signInAnonymously();

      print('Anonymous sign in completed: ${result.user?.uid}');

      _isLoading = false;

      // Force immediate update
      _user = result.user;
      if (_user != null) {
        await _loadUserProfile();
      }

      notifyListeners();

      return result.user != null;

    } on FirebaseAuthException catch (e) {
      print('Anonymous sign-in error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      throw Exception('Anonymous sign-in failed: ${e.message}');
    } catch (e) {
      print('Anonymous sign-in error: $e');
      _isLoading = false;
      notifyListeners();
      throw Exception('Anonymous sign-in failed: $e');
    }
  }

  // Link Anonymous Account with Google
  Future<bool> linkAnonymousWithGoogle() async {
    if (_user == null || !_user!.isAnonymous) return false;

    try {
      print('Linking anonymous account with Google...');

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Link the anonymous user with Google credentials
      await _user!.linkWithCredential(credential);

      // Update profile to reflect it's no longer anonymous
      if (_userProfile != null) {
        _userProfile!['isAnonymous'] = false;
        _userProfile!['email'] = _user!.email ?? '';
        _userProfile!['photoUrl'] = _user!.photoURL ?? '';
        if (_userProfile!['name'] == 'User' || _userProfile!['name'].isEmpty) {
          _userProfile!['name'] = _user!.displayName ?? 'User';
        }
        await _saveUserProfile();
      }

      notifyListeners();

      print('Account linked successfully');

      return true;
    } on FirebaseAuthException catch (e) {
      print('Link account error: ${e.code} - ${e.message}');
      if (e.code == 'credential-already-in-use') {
        throw Exception('This Google account is already linked to another user.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists with this email address.');
      }
      throw Exception('Failed to link account: ${e.message}');
    } catch (e) {
      print('Link account error: $e');
      throw Exception('Failed to link account: $e');
    }
  }

  // Update User Profile
  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    if (_user == null) return;

    try {
      _userProfile = {..._userProfile ?? {}, ...profileData};
      await _saveUserProfile();
      notifyListeners();
      print('Profile updated successfully');
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get profile completion status
  bool get isProfileComplete {
    if (_userProfile == null) return false;

    final requiredFields = ['name', 'school'];
    return requiredFields.every((field) =>
    _userProfile![field] != null &&
        _userProfile![field].toString().trim().isNotEmpty
    );
  }

  // Get profile completion percentage
  double get profileCompletionPercentage {
    if (_userProfile == null) return 0.0;

    final fields = ['name', 'school', 'phone', 'subject', 'gradeLevel', 'experience'];
    int completedFields = 0;

    for (String field in fields) {
      if (_userProfile![field] != null &&
          _userProfile![field].toString().trim().isNotEmpty) {
        completedFields++;
      }
    }

    return completedFields / fields.length;
  }

  // Sign Out
  Future<void> logout() async {
    try {
      print('Starting logout...');

      // Sign out from Google
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();

      _userProfile = null;
      _user = null;
      notifyListeners();

      print('Logout completed');

    } catch (e) {
      print('Logout error: $e');
      throw Exception('Logout failed: $e');
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    if (_user == null) return;

    try {
      print('Deleting account...');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_profile_${_user!.uid}');

      // Sign out from Google if needed
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      await _user!.delete();

      print('Account deleted successfully');

    } on FirebaseAuthException catch (e) {
      print('Delete account error: ${e.code} - ${e.message}');
      if (e.code == 'requires-recent-login') {
        throw Exception('Please sign in again before deleting your account.');
      }
      throw Exception('Failed to delete account: ${e.message}');
    } catch (e) {
      print('Delete account error: $e');
      throw Exception('Failed to delete account: $e');
    }
  }
}