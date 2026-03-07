class ReactionModel {
  final String id;
  final String dareId;
  final String userId;
  final String type;
  final DateTime createdAt;

  ReactionModel({
    required this.id,
    required this.dareId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  factory ReactionModel.fromJson(Map<String, dynamic> json) {
    return ReactionModel(
      id: json['id'] as String,
      dareId: json['dare_id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dare_id': dareId,
      'user_id': userId,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
