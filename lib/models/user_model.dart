class UserModel {
  final String id;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final List<String>? interests;
  final int coins;
  final int gems;
  final int streak;
  final int skipTokens;
  final int streakFreezes;
  final DateTime? lastActive;
  final int weeklyProgress;
  final int totalStreaks;
  final bool multiplierActive;
  final String? lastDareDate;
  final DateTime? deletedAt;

  UserModel({
    required this.id,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.interests,
    this.coins = 0,
    this.gems = 0,
    this.streak = 0,
    this.skipTokens = 0,
    this.streakFreezes = 0,
    this.lastActive,
    this.weeklyProgress = 0,
    this.totalStreaks = 0,
    this.multiplierActive = false,
    this.lastDareDate,
    this.deletedAt,
  });

  String get rankStatus {
    if (coins < 50) return 'GHOST';
    if (coins < 200) return 'CHALLENGER';
    if (coins < 500) return 'ADRENALINE JUNKIE';
    return 'DAREDEVIL';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      interests: (json['interests'] as List<dynamic>?)?.map((e) => e as String).toList(),
      coins: json['coins'] as int? ?? 0,
      gems: json['gems'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      skipTokens: json['skip_tokens'] as int? ?? 0,
      streakFreezes: json['streak_freezes'] as int? ?? 0,
      lastActive: json['last_active'] != null ? DateTime.parse(json['last_active'] as String) : null,
      weeklyProgress: json['weekly_progress'] as int? ?? 0,
      totalStreaks: json['total_streaks'] as int? ?? 0,
      multiplierActive: json['multiplier_active'] as bool? ?? false,
      lastDareDate: json['last_dare_date'] as String?,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'interests': interests,
      'coins': coins,
      'gems': gems,
      'streak': streak,
      'skip_tokens': skipTokens,
      'streak_freezes': streakFreezes,
      'last_active': lastActive?.toIso8601String(),
      'weekly_progress': weeklyProgress,
      'total_streaks': totalStreaks,
      'multiplier_active': multiplierActive,
      'last_dare_date': lastDareDate,
    };
  }
}
