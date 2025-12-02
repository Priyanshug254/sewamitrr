class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String language;
  final DateTime? createdAt;
  final int totalReports;
  final int resolvedIssues;
  final int communityRank;
  final int points;
  final String? location;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.language = 'en',
    this.createdAt,
    this.totalReports = 0,
    this.resolvedIssues = 0,
    this.communityRank = 0,
    this.points = 0,
    this.location,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['id'] ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photo_url'],
      language: map['language'] ?? 'en',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      totalReports: map['total_reports'] ?? 0,
      resolvedIssues: map['resolved_issues'] ?? 0,
      communityRank: map['community_rank'] ?? 0,
      points: map['points'] ?? 0,
      location: map['location'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'language': language,
      'created_at': createdAt?.toIso8601String(),
      'total_reports': totalReports,
      'resolved_issues': resolvedIssues,
      'community_rank': communityRank,
      'points': points,
      'location': location,
    };
  }
}