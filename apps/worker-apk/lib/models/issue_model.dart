class IssueModel {
  final String? id;
  final String userId;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> mediaUrls;
  final String? audioUrl;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int upvotes;
  final int progress;
  final String? assignedTo;
  final List<UpdateLog> updateLogs;

  IssueModel({
    this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.mediaUrls = const [],
    this.audioUrl,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.upvotes = 0,
    this.progress = 0,
    this.assignedTo,
    this.updateLogs = const [],
  });

  factory IssueModel.fromMap(Map<String, dynamic> map) {
    return IssueModel(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
      audioUrl: map['audio_url'],
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      upvotes: map['upvotes'] ?? 0,
      progress: map['progress'] ?? 0,
      assignedTo: map['assigned_to'],
      updateLogs: map['update_logs'] != null 
          ? (map['update_logs'] as List).map((log) => UpdateLog.fromMap(log)).toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'media_urls': mediaUrls,
      'audio_url': audioUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'upvotes': upvotes,
      'progress': progress,
      'assigned_to': assignedTo,
    };
  }
}

class UpdateLog {
  final String workerId;
  final String description;
  final List<String> imageUrls;
  final int progress;
  final String status;
  final DateTime timestamp;

  UpdateLog({
    required this.workerId,
    required this.description,
    this.imageUrls = const [],
    required this.progress,
    required this.status,
    required this.timestamp,
  });

  factory UpdateLog.fromMap(Map<String, dynamic> map) {
    return UpdateLog(
      workerId: map['worker_id'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      progress: map['progress'] ?? 0,
      status: map['status'] ?? 'pending',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'worker_id': workerId,
      'description': description,
      'image_urls': imageUrls,
      'progress': progress,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
