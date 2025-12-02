import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  User? _currentUser;
  String? _workerName;
  String? _workerId;

  User? get currentUser => _currentUser;
  String? get workerName => _workerName;
  String? get workerId => _workerId;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    _currentUser = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      _currentUser = data.session?.user;
      if (_currentUser != null) {
        _loadWorkerProfile();
      } else {
        _workerName = null;
        _workerId = null;
      }
      notifyListeners();
    });
    if (_currentUser != null) {
      await _loadWorkerProfile();
    }
  }

  Future<void> _loadWorkerProfile() async {
    if (_currentUser == null) return;
    
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', _currentUser!.id)
          .maybeSingle();
      
      if (response != null) {
        _workerName = response['name'] ?? 'Worker';
        _workerId = response['id'];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading worker profile: $e');
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
        await _loadWorkerProfile();
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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _workerName = null;
    _workerId = null;
    notifyListeners();
  }
}
