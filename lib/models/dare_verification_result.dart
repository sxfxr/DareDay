class DareVerificationResult {
  final int score;
  final String description;
  final String reasoning;

  DareVerificationResult({
    required this.score,
    required this.description,
    required this.reasoning,
  });

  bool get passed => score >= 80;

  factory DareVerificationResult.fromJson(Map<String, dynamic> json) {
    return DareVerificationResult(
      score: json['relevance_score'] as int? ?? 0,
      description: json['description'] as String? ?? 'No description provided.',
      reasoning: json['reasoning'] as String? ?? 'No reasoning provided.',
    );
  }
}
