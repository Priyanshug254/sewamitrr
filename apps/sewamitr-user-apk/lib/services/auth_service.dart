import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _currentUser;
  UserModel? _userProfile;

  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    _currentUser = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
    if (_currentUser != null) {
      await _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) return;
    
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();
      
      if (response != null) {
        _userProfile = UserModel.fromMap(response);
      } else {
        // If profile doesn't exist, create it
        await _createUserProfileFromAuth();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      // If it's an RLS error, try to create the profile
      if (e.toString().contains('RLS') || e.toString().contains('policy')) {
        await _createUserProfileFromAuth();
      }
    }
  }

  Future<void> _createUserProfileFromAuth() async {
    if (_currentUser == null) return;
    
    try {
      final name = _currentUser!.userMetadata?['name'] ?? 'User';
      final language = _currentUser!.userMetadata?['language'] ?? 'en';
      
      await _createUserProfile(_currentUser!, name, language);
      await _loadUserProfile(); // Reload after creation
    } catch (e) {
      debugPrint('Error creating profile from auth: $e');
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUser = response.user;
        await _loadUserProfile();
        notifyListeners();
      }
      
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('SignIn error: $e');
      if (e.toString().contains('Failed to fetch') || e.toString().contains('ClientException')) {
        return 'Network error. Please check your internet connection.';
      }
      return 'An error occurred: ${e.toString()}';
    }
  }

  Future<String?> signUp(String email, String password, String name, String language) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'language': language},
      );
      
      // If user is created and confirmed, create profile
      if (response.user != null) {
        await _createUserProfile(response.user!, name, language);
      }
      
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('SignUp error: $e');
      return 'An error occurred';
    }
  }

  Future<void> _createUserProfile(User user, String name, String language) async {
    try {
      // First check if profile already exists (created by trigger)
      final existing = await _supabase
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      
      if (existing != null) return;

      // If not, try to create it
      final userProfile = {
        'id': user.id,
        'email': user.email!,
        'name': name,
        'language': language,
        'total_reports': 0,
        'resolved_issues': 0,
        'community_rank': 0,
        'points': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await _supabase.from('users').upsert(userProfile);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserModel?> getUserProfile() async {
    if (_currentUser == null) return null;
    
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();
      
      if (response == null) return null;
      return UserModel.fromMap(response);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    if (_currentUser == null) return;
    
    try {
      await _supabase
          .from('users')
          .update(user.toMap())
          .eq('id', _currentUser!.id);
      
      _userProfile = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    }
  }

  Future<String?> uploadProfilePicture(String filePath, Uint8List bytes) async {
    if (_currentUser == null) return null;
    
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await _supabase.storage
          .from('sewamitr')
          .uploadBinary('profiles/${_currentUser!.id}/$fileName', bytes);
      
      final photoUrl = _supabase.storage
          .from('sewamitr')
          .getPublicUrl('profiles/${_currentUser!.id}/$fileName');
      
      await _supabase
          .from('users')
          .update({'photo_url': photoUrl})
          .eq('id', _currentUser!.id);
      
      await _loadUserProfile();
      return photoUrl;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }
}