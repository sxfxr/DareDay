import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class GlassmorphicButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const GlassmorphicButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ReactionOverlay extends StatefulWidget {
  final String attemptId;
  const ReactionOverlay({super.key, required this.attemptId});

  @override
  State<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends State<ReactionOverlay> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<String, int> _counts = {'fire': 0, 'laugh': 0, 'highfive': 0, 'share': 0};

  @override
  void initState() {
    super.initState();
    _loadReactions();
  }

  Future<void> _loadReactions() async {
    final counts = await _supabaseService.fetchReactionCounts(widget.attemptId);
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _react(String type) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await _supabaseService.submitReaction(userId, widget.attemptId, type);
    _loadReactions();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlassmorphicButton(
          icon: Icons.local_fire_department,
          label: _formatCount(_counts['fire']!),
          onTap: () => _react('fire'),
        ),
        const SizedBox(height: 16),
        GlassmorphicButton(
          icon: Icons.sentiment_very_satisfied,
          label: _formatCount(_counts['laugh']!),
          onTap: () => _react('laugh'),
        ),
        const SizedBox(height: 16),
        GlassmorphicButton(
          icon: Icons.pan_tool,
          label: _formatCount(_counts['highfive']!),
          onTap: () => _react('highfive'),
        ),
        const SizedBox(height: 16),
        GlassmorphicButton(
          icon: Icons.reply,
          label: _formatCount(_counts['share']!),
          onTap: () {
            _react('share');
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard!')));
          },
        ),
        const SizedBox(height: 20),
        // Simple avatar fallback (Gap #17)
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).primaryColor, width: 2),
            color: Colors.white10,
          ),
          child: const Icon(Icons.person, color: Colors.white38),
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
