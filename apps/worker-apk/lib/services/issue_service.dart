import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/issue_model.dart';

class IssueService {
  final _supabase = Supabase.instance.client;

  // Get issues assigned to the current worker
  Future<List<IssueModel>> getAssignedIssues(String workerId) async {
    try {
      final response = await _supabase
          .from('issues')
          .select()
          .eq('assigned_to', workerId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((data) => IssueModel.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting assigned issues: $e');
      return [];
    }
  }

  // Upload progress image
  Future<String?> uploadFile(XFile file, String path, String issueId) async {
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
      return null;
    }
  }

  // Update issue with worker progress
  Future<bool> updateIssueProgress({
    required String issueId,
    required String workerId,
    required String description,
    required List<String> imageUrls,
    required int progress,
    required String status,
  }) async {
    try {
      // Create update log
      final updateLog = UpdateLog(
        workerId: workerId,
        description: description,
        imageUrls: imageUrls,
        progress: progress,
        status: status,
        timestamp: DateTime.now(),
      );

      // Get current issue to append update log
      final issue = await _supabase
          .from('issues')
          .select('update_logs')
          .eq('id', issueId)
          .single();

      List<dynamic> updateLogs = issue['update_logs'] ?? [];
      updateLogs.add(updateLog.toMap());

      // Update issue with new progress, status, and update logs
      await _supabase
          .from('issues')
          .update({
            'status': status,
            'progress': progress,
            'update_logs': updateLogs,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', issueId);

      return true;
    } catch (e) {
      print('Error updating issue progress: $e');
      return false;
    }
  }

  // Get issue by ID
  Future<IssueModel?> getIssueById(String issueId) async {
    try {
      final response = await _supabase
          .from('issues')
          .select()
          .eq('id', issueId)
          .single();
      
      return IssueModel.fromMap(response);
    } catch (e) {
      print('Error getting issue: $e');
      return null;
    }
  }
}
