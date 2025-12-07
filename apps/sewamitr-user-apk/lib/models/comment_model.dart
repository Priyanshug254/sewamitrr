class CommentModel {
  final String? id;
  final String issueId;
  final String userId;
  final String userName;
  final String commentText;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CommentModel({
    this.id,
    required this.issueId,
    required this.userId,
    required this.userName,
    required this.commentText,
    required this.createdAt,
    this.updatedAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id']?.toString(),
      issueId: map['issue_id']?.toString() ?? '',
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? 'Anonymous',
      commentText: map['comment_text'] ?? '',
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'issue_id': issueId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
