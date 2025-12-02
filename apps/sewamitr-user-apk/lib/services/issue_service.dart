import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../models/issue_model.dart';
import 'notification_service.dart';

class IssueService {
  final _supabase = Supabase.instance.client;

  Future<String> uploadFile(XFile file, String path, String issueId) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final fullPath = '$path/$issueId/$fileName';
    
    try {
      final bytes = await file.readAsBytes();
      await _supabase.storage.from('sewamitr').uploadBinary(
        fullPath,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      return _supabase.storage.from('sewamitr').getPublicUrl(fullPath);
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  Future<String> uploadFileBytes(Uint8List bytes, String fileName, String path, String issueId) async {
    final fullFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
    final fullPath = '$path/$issueId/$fullFileName';
    
    await _supabase.storage.from('sewamitr').uploadBinary(
      fullPath, 
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    return _supabase.storage.from('sewamitr').getPublicUrl(fullPath);
  }

  Future<String> createIssue(IssueModel issue) async {
    final response = await _supabase.from('issues').insert(issue.toMap()).select('id').single();
    return response['id'];
  }

  Future<void> updateIssueMedia(String issueId, List<String> mediaUrls, String? audioUrl) async {
    await _supabase.from('issues').update({
      'media_urls': mediaUrls,
      'audio_url': audioUrl,
    }).eq('id', issueId);
  }

  Future<void> deleteIssue(String issueId) async {
    // Delete from storage
    try {
      final issueFiles = await _supabase.storage.from('sewamitr').list(path: 'issues/$issueId');
      if (issueFiles.isNotEmpty) {
        final issuePaths = issueFiles.map((f) => 'issues/$issueId/${f.name}').toList();
        await _supabase.storage.from('sewamitr').remove(issuePaths);
      }
      
      final audioFiles = await _supabase.storage.from('sewamitr').list(path: 'audio/$issueId');
      if (audioFiles.isNotEmpty) {
        final audioPaths = audioFiles.map((f) => 'audio/$issueId/${f.name}').toList();
        await _supabase.storage.from('sewamitr').remove(audioPaths);
      }
    } catch (e) {
      print('Storage delete error: $e');
    }
    // Delete from database
    await _supabase.from('issues').delete().eq('id', issueId);
  }

  Future<List<IssueModel>> getUserIssues(String userId) async {
    final response = await _supabase
        .from('issues')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    if (response == null) return [];
    
    return (response as List)
        .map((data) => IssueModel.fromMap(data))
        .toList();
  }

  Future<List<IssueModel>> getAllIssues() async {
    final response = await _supabase
        .from('issues')
        .select()
        .order('created_at', ascending: false);
    
    if (response == null) return [];

    return (response as List)
        .map((data) => IssueModel.fromMap(data))
        .toList();
  }

  Future<List<IssueModel>> getNearbyIssues(double lat, double lng, double radiusKm) async {
    final response = await _supabase.rpc('get_nearby_issues', params: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    
    if (response == null) return [];

    return (response as List)
        .map((data) => IssueModel.fromMap(data))
        .toList();
  }

  Future<void> updateIssueStatus(String issueId, String status, int progress, NotificationService notificationService) async {
    // Get issue to find user_id
    final issue = await _supabase
        .from('issues')
        .select('user_id')
        .eq('id', issueId)
        .single();
    
    await _supabase
        .from('issues')
        .update({
          'status': status,
          'progress': progress,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', issueId);
    
    // Create notification for milestone progress
    if (progress == 25 || progress == 50 || progress == 75 || progress == 100) {
      await notificationService.createProgressNotification(
        issue['user_id'],
        issueId,
        progress,
      );
    }
  }

  Future<bool> upvoteIssue(String issueId, String userId) async {
    try {
      // Check if user already voted
      final existing = await _supabase
          .from('votes')
          .select()
          .eq('issue_id', issueId)
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existing != null) {
        return false; // Already voted
      }
      
      // Add vote
      await _supabase.from('votes').insert({
        'issue_id': issueId,
        'user_id': userId,
      });
      
      // Increment upvote count
      await _supabase.rpc('upvote_issue', params: {'issue_id': issueId});
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Set<String>> getUserVotes(String userId) async {
    try {
      final response = await _supabase
          .from('votes')
          .select('issue_id')
          .eq('user_id', userId);
      
      if (response == null) return {};

      return (response as List)
          .map((data) => data['issue_id'].toString())
          .toSet();
    } catch (e) {
      // Return empty set if votes table doesn't exist yet
      return {};
    }
  }

  Future<Map<String, int>> getCommunityStats() async {
    try {
      final response = await _supabase.rpc('get_community_stats');
      if (response != null && response is List && response.isNotEmpty) {
        final data = response.first;
        if (data != null) {
          return {
            'total_users': (data['total_users'] ?? 0) as int,
            'total_issues': (data['total_issues'] ?? 0) as int,
            'resolved_issues': (data['resolved_issues'] ?? 0) as int,
          };
        }
      }
      return {'total_users': 0, 'total_issues': 0, 'resolved_issues': 0};
    } catch (e) {
      return {'total_users': 0, 'total_issues': 0, 'resolved_issues': 0};
    }
  }
}