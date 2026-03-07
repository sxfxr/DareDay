class DareModel {
  final String id;
  final String title;
  final String instructions;
  final String difficulty; // 'Easy', 'Medium', 'Hard', 'Insane'
  final String? category;
  final int xpReward; // Still in DB as xp_reward but UI uses 'pts'
  final int gemReward;
  final bool isChallenge;
  final String? senderName;
  final String? challengeStatus; // 'pending', 'accepted', 'completed', 'rejected'
  final DateTime createdAt;

  DareModel({
    required this.id,
    required this.title,
    required this.instructions,
    required this.difficulty,
    this.category,
    this.xpReward = 10,
    this.gemReward = 0,
    this.isChallenge = false,
    this.senderName,
    this.challengeStatus,
    required this.createdAt,
  });

  factory DareModel.fromJson(Map<String, dynamic> json) {
    return DareModel(
      id: json['id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      difficulty: json['difficulty'] as String? ?? 'Medium',
      category: json['category'] as String?,
      xpReward: json['xp_reward'] as int? ?? 10,
      gemReward: json['gem_reward'] as int? ?? 0,
      isChallenge: json['is_challenge'] as bool? ?? false,
      senderName: json['sender_name'] as String?,
      challengeStatus: json['status'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructions': instructions,
      'difficulty': difficulty,
      'category': category,
      'xp_reward': xpReward,
      'gem_reward': gemReward,
      'is_challenge': isChallenge,
      'sender_name': senderName,
      'status': challengeStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserAttemptModel {
  final String id;
  final String userId;
  final String username;
  final String? dareId;
  final String? dareTitle;
  final String videoUrl;
  final String status; // 'pending', 'verified', 'flagged'
  final String? caption;
  final DateTime completedAt;

  UserAttemptModel({
    required this.id,
    required this.userId,
    required this.username,
    this.dareId,
    this.dareTitle,
    required this.videoUrl,
    this.status = 'pending',
    this.caption,
    required this.completedAt,
  });

  factory UserAttemptModel.fromJson(Map<String, dynamic> json) {
    // Handle joined profiles for username
    String username = 'Anonymous';
    if (json['profiles'] != null && json['profiles']['username'] != null) {
      username = json['profiles']['username'];
    } else if (json['username'] != null) {
      username = json['username'];
    }

    return UserAttemptModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: username,
      dareId: json['dare_id'] as String?,
      dareTitle: json['dares_master'] != null ? json['dares_master']['title'] as String? : null,
      videoUrl: json['video_url'] as String,
      status: json['status'] as String? ?? 'pending',
      caption: json['caption'] as String?,
      completedAt: DateTime.parse(json['completed_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'dare_id': dareId,
      'video_url': videoUrl,
      'status': status,
      'caption': caption,
      'completed_at': completedAt.toIso8601String(),
    };
  }
}
