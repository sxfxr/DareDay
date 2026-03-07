import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import 'comments_sheet.dart';

class SocialBar extends StatefulWidget {
  final String attemptId;
  final String videoUrl;
  const SocialBar({super.key, required this.attemptId, required this.videoUrl});

  @override
  State<SocialBar> createState() => _SocialBarState();
}

class _SocialBarState extends State<SocialBar> {
  final SupabaseService _supabaseService = SupabaseService();
  final Map<String, int> _counts = {'heart': 0, 'comment': 0};
  bool _isHearted = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final counts = await _supabaseService.fetchReactionCounts(widget.attemptId);
    final commentCount = await _supabaseService.fetchCommentCount(widget.attemptId);
    if (mounted) {
      setState(() {
        _counts['heart'] = counts['heart'] ?? 0;
        _counts['comment'] = commentCount;
      });
    }
  }

  Future<void> _handleHeart() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _isHearted = !_isHearted;
      _counts['heart'] = (_counts['heart'] ?? 0) + (_isHearted ? 1 : -1);
    });

    try {
      await _supabaseService.submitReaction(userId, widget.attemptId, 'heart');
    } catch (e) {
      debugPrint('Error hearting: $e');
    }
  }

  Future<void> _showComments() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(attemptId: widget.attemptId),
    );
    _fetchStats();
  }

  void _handleShare() {
    Share.share('Check out this dare attempt on Dare Day! ${widget.videoUrl}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _socialIcon(
          icon: _isHearted ? Icons.favorite : Icons.favorite_border,
          label: '${_counts['heart']}',
          color: _isHearted ? Colors.redAccent : Colors.white,
          onTap: _handleHeart,
        ),
        const SizedBox(height: 20),
        _socialIcon(
          icon: Icons.chat_bubble_outline,
          label: '${_counts['comment']}',
          onTap: _showComments,
        ),
        const SizedBox(height: 20),
        _socialIcon(
          icon: Icons.share_outlined,
          label: 'Share',
          onTap: _handleShare,
        ),
      ],
    );
  }

  Widget _socialIcon({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
