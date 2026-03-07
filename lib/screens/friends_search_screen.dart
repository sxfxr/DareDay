import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';

class FriendsSearchScreen extends StatefulWidget {
  const FriendsSearchScreen({super.key});

  @override
  State<FriendsSearchScreen> createState() => _FriendsSearchScreenState();
}

class _FriendsSearchScreenState extends State<FriendsSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();
  List<UserModel> _searchResults = [];
  Set<String> _followingIds = {};
  bool _isSearching = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final following = await _supabaseService.fetchFollowingIds(userId);
      if (mounted) {
        setState(() {
          _followingIds = following.toSet();
        });
      }
    } catch (e) {
      debugPrint('Error loading following: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF22D3EE);
    const backgroundDark = Color(0xFF0F0814);
    final currentId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('SEARCH FRIENDS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by username...',
                  prefixIcon: const Icon(Icons.search, color: neonCyan),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: _onSearchChanged,
              ),
            ),
          ),
          Expanded(
            child: _isSearching 
              ? const Center(child: CircularProgressIndicator(color: neonCyan))
              : _searchResults.isEmpty && _searchController.text.isNotEmpty
                ? const Center(child: Text('No users found.', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final user = _searchResults[index];
                      final isFollowing = _followingIds.contains(user.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProfileScreen(userId: user.id),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: neonCyan.withOpacity(0.2),
                                child: Text(user.username[0].toUpperCase(), 
                                  style: const TextStyle(color: neonCyan, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(user.bio ?? 'New DareDay user', style: const TextStyle(fontSize: 12, color: Colors.white38)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FutureBuilder<bool>(
                                    future: _supabaseService.checkMutualFollow(currentId ?? '', user.id),
                                    builder: (context, snapshot) {
                                      final isMutual = snapshot.data ?? false;
                                      if (!isMutual) return const SizedBox.shrink();
                                      return ElevatedButton(
                                        onPressed: () => _sendCustomDare(user),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                                          foregroundColor: Colors.pinkAccent,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: const Text('DARE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _toggleFollow(user.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing ? neonCyan : neonCyan.withOpacity(0.1),
                                      foregroundColor: isFollowing ? Colors.black : neonCyan,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text(isFollowing ? 'FOLLOWING' : 'FOLLOW', 
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          if (_isProcessing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: neonCyan),
            ),
        ],
      ),
    );
  }

  Future<void> _onSearchChanged(String val) async {
    if (val.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final results = await _supabaseService.searchUsers(val);
      final currentId = Supabase.instance.client.auth.currentUser?.id;
      if (mounted) {
        setState(() {
          _searchResults = results.where((u) => u.id != currentId).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _toggleFollow(String targetId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    final isFollowing = _followingIds.contains(targetId);
    
    try {
      if (isFollowing) {
        await _supabaseService.unfollowUser(userId, targetId);
        if (mounted) {
          setState(() {
            _followingIds.remove(targetId);
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unfollowed!')));
        }
      } else {
        await _supabaseService.followUser(userId, targetId);
        if (mounted) {
          setState(() {
            _followingIds.add(targetId);
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Following user!')));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _sendCustomDare(UserModel targetUser) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final titleController = TextEditingController();
    final instrController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: Text('Dare ${targetUser.username}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Custom dares cost 15 Gems and must pass AI verification.', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(controller: titleController, decoration: _inputDecoration('Challenge Title')),
            const SizedBox(height: 12),
            TextField(controller: instrController, decoration: _inputDecoration('Instructions'), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            child: const Text('SEND (15 💎)'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (titleController.text.isEmpty || instrController.text.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields.')));
        return;
      }

      setState(() => _isProcessing = true);
      try {
        // [PHASE 3] Mutual Follow Gate
        final isMutual = await _supabaseService.isMutualFollow(userId, targetUser.id);
        if (!isMutual) {
          throw Exception('Mutual follow required! You both must follow each other to send custom dares.');
        }

        final profile = await _supabaseService.fetchProfile(userId);
        if (profile.gems < 15) throw Exception('Insufficient Gems! You need 15.');

        // [PLACEHOLDER] AI Verification (Disabled for testing)
        // final isSafe = await _aiService.verifyCustomDare(titleController.text, instrController.text);
        
        // Deduction and sending challenge follows

        // Deduct gems
        await _supabaseService.updateGems(userId, -15);
        
        // Send to real backend
        await _supabaseService.sendChallenge(
          senderId: userId,
          recipientId: targetUser.id,
          title: titleController.text,
          instructions: instrController.text,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dare sent to ${targetUser.username}! 💎 Verification passed.')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.redAccent));
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}
