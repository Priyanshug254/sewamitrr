class IssueUpdateModel {
  final String? id;
  final String issueId;
  final String workerId;
  final String description;
  final List<String> imageUrls;
  final int progress;
  final String status;
  final DateTime createdAt;

  IssueUpdateModel({
    this.id,
    required this.issueId,
    required this.workerId,
    required this.description,
    this.imageUrls = const [],
    required this.progress,
    required this.status,
    required this.createdAt,
  });

  factory IssueUpdateModel.fromMap(Map<String, dynamic> map) {
    return IssueUpdateModel(
      id: map['id']?.toString(),
      issueId: map['issue_id'] ?? '',
      workerId: map['worker_id'] ?? '',
      description: map['description'] ?? '',
      imageUrls: List<String>.from(map['image_urls'] ?? []),
      progress: map['progress'] ?? 0,
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()).toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issue_id': issueId,
      'worker_id': workerId,
      'description': description,
      'image_urls': imageUrls,
      'progress': progress,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
