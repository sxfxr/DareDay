class CommentModel {
  final String id;
  final String attemptId;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.attemptId,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Handling potential nested join for username
    String username = 'Anonymous';
    if (json['profiles'] != null && json['profiles']['username'] != null) {
      username = json['profiles']['username'];
    } else if (json['username'] != null) {
      username = json['username'];
    }

    return CommentModel(
      id: json['id'] as String,
      attemptId: json['attempt_id'] as String,
      userId: json['user_id'] as String,
      username: username,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attempt_id': attemptId,
      'user_id': userId,
      'text': text,
    };
  }
}
