class IssueModel {
  final String? id;
  final String userId;
  final String? cityId;      // NEW: Auto-assigned by database trigger
  final String? wardId;      // NEW: Auto-assigned by database trigger
  final String? zoneId;      // NEW: Auto-assigned by database trigger
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> mediaUrls;
  final String? audioUrl;
  final String? audioDescription;
  final String priority;     // NEW: User selects (low, medium, high, critical)
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final int upvotes;
  final int progress;
  final String? assignedTo;

  IssueModel({
    this.id,
    required this.userId,
    this.cityId,
    this.wardId,
    this.zoneId,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.mediaUrls = const [],
    this.audioUrl,
    this.audioDescription,
    this.priority = 'medium',
    this.status = 'submitted',  // FIXED: Changed from 'pending' to 'submitted'
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.upvotes = 0,
    this.progress = 0,
    this.assignedTo,
  });

  factory IssueModel.fromMap(Map<String, dynamic> map) {
    return IssueModel(
      id: map['id']?.toString(),
      userId: map['user_id'] ?? '',
      cityId: map['city_id'],
      wardId: map['ward_id'],
      zoneId: map['zone_id'],
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      address: map['address'] ?? '',
      mediaUrls: List<String>.from(map['media_urls'] ?? []),
      audioUrl: map['audio_url'],
      audioDescription: map['audio_description'],
      priority: map['priority'] ?? 'medium',
      status: map['status'] ?? 'submitted',  // FIXED: Changed from 'pending' to 'submitted'
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()).toLocal(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']).toLocal() : null,
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']).toLocal() : null,
      upvotes: map['upvotes'] ?? 0,
      progress: map['progress'] ?? 0,
      assignedTo: map['assigned_to'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'city_id': cityId,
      'ward_id': wardId,
      'zone_id': zoneId,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'media_urls': mediaUrls,
      'audio_url': audioUrl,
      'audio_description': audioDescription,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'upvotes': upvotes,
      'progress': progress,
      'assigned_to': assignedTo,
    };
  }
}