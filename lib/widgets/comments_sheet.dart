import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import '../services/supabase_service.dart';

class CommentsSheet extends StatefulWidget {
  final String attemptId;
  const CommentsSheet({super.key, required this.attemptId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _commentController = TextEditingController();
  late Future<List<CommentModel>> _commentsFuture;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  void _fetchComments() {
    _commentsFuture = _supabaseService.fetchComments(widget.attemptId);
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isSending = true);
    try {
      await _supabaseService.addComment(userId, widget.attemptId, text);
      _commentController.clear();
      setState(() {
        _fetchComments();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF191022),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Comments', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(color: Colors.white10),
          Expanded(
            child: FutureBuilder<List<CommentModel>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent, fontSize: 12)));
                }
                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return const Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: Colors.white38)));
                }
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFA855F7).withValues(alpha: 0.2),
                        child: Text(comment.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFFA855F7))),
                      ),
                      title: Text(comment.username, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text(comment.text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSending ? null : _sendComment,
                  icon: Icon(_isSending ? Icons.hourglass_empty : Icons.send, color: const Color(0xFFA855F7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
