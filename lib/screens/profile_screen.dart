import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../models/dare_model.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<UserModel> _profileFuture;
  late String _currentViewedId;

  @override
  void initState() {
    super.initState();
    _currentViewedId = widget.userId ?? Supabase.instance.client.auth.currentUser!.id;
    _profileFuture = _supabaseService.fetchProfile(_currentViewedId);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFA855F7);
    const accentCyan = Color(0xFF06B6D4);
    const backgroundDark = Color(0xFF191022);

    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnProfile = myId == _currentViewedId;

    return Scaffold(
      backgroundColor: backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: !isOwnProfile ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: isOwnProfile ? [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _showSettingsMenu(context),
          ),
        ] : null,
      ),
      body: FutureBuilder<UserModel>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final user = snapshot.data!;

          return FutureBuilder<Map<String, int>>(
            future: _supabaseService.fetchSocialCounts(user.id),
            builder: (context, socialSnapshot) {
              final stats = socialSnapshot.data ?? {'followers': 0, 'following': 0};

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 64),
                    // Avatar Section
                    Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor, width: 2)),
                        child: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, size: 64, color: Colors.white38)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.username,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (isOwnProfile)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white54, size: 20),
                            onPressed: () => _showEditProfileSheet(user),
                          ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRankColor(user.rankStatus).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getRankColor(user.rankStatus).withValues(alpha: 0.5), width: 1),
                      ),
                      child: Text(
                        user.rankStatus,
                        style: TextStyle(
                          color: _getRankColor(user.rankStatus),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (user.bio != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          user.bio!,
                          style: const TextStyle(color: Colors.white54, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (user.lastActive != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Last active: ${_formatLastActive(user.lastActive!)}',
                          style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Social counts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialStat('${stats['followers']}', 'Followers', () {}),
                        const SizedBox(width: 32),
                        _buildSocialStat('${stats['following']}', 'Following', () => _showFollowingList(user.id)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Stats Grid
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(child: _buildStatBox(context, 'STREAK', '${user.streak} 🔥', primaryColor)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatBox(context, 'pts', '${user.coins}', accentCyan)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: isOwnProfile ? () => _showGemsShop(user.id) : null,
                              child: _buildStatBox(context, 'GEMS', '${user.gems} 💎', Colors.pinkAccent),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: _buildStatBox(context, 'SKIPS', '${user.skipTokens} ⚡', const Color(0xFFFFD700))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (isOwnProfile) ...[
                      // Buy Tokens
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () => _buySkipTokens(user.id),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: Colors.pinkAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Buy Skip Token (5 Gems)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Sign Out
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                          },
                          icon: const Icon(Icons.logout, size: 20),
                          label: const Text('SIGN OUT'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                            foregroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ] else ...[
                      // Actions for others' profiles
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging coming soon! 💬')));
                                },
                                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                                label: const Text('MESSAGE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 56),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FutureBuilder<bool>(
                              future: _supabaseService.isMutualFollow(myId!, _currentViewedId),
                              builder: (context, mutualSnapshot) {
                                final isMutual = mutualSnapshot.data ?? false;
                                if (!isMutual) return const SizedBox.shrink();
                                return Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showSendDareSheet(user),
                                    icon: const Icon(Icons.bolt, size: 20),
                                    label: const Text('DARE'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pinkAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 56),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Memories Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'MEMORIES',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileMemories(userId: user.id, isOwnProfile: isOwnProfile),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showSendDareSheet(UserModel targetUser) {
    final titleController = TextEditingController();
    final instrController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DARE ${targetUser.username.toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Dare Title',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: instrController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Instructions...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final myId = Supabase.instance.client.auth.currentUser?.id;
                if (myId == null) return;
                try {
                  await _supabaseService.sendChallenge(
                    senderId: myId,
                    recipientId: targetUser.id,
                    title: titleController.text.trim(),
                    instructions: instrController.text.trim(),
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dare sent! 🔥')));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('SEND DARE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialStat(String value, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatLastActive(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'GHOST':
        return Colors.white38;
      case 'CHALLENGER':
        return const Color(0xFF22D3EE); // Neon Cyan
      case 'ADRENALINE JUNKIE':
        return const Color(0xFFA855F7); // Purple
      case 'DAREDEVIL':
        return Colors.orangeAccent;
      default:
        return Colors.white;
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            _buildSettingsItem(Icons.person_outline, 'Manage Profile', () {
              Navigator.pop(context);
              _showManageProfile();
            }),
            _buildSettingsItem(Icons.security, 'Security', () {
              Navigator.pop(context);
              _showSecurity();
            }),
            _buildSettingsItem(Icons.diamond_outlined, 'Gem Shop', () {
              Navigator.pop(context);
              _showGemShop();
            }),
            _buildSettingsItem(Icons.bug_report_outlined, 'Report Bug / Feedback', () {
              Navigator.pop(context);
              _showFeedbackDialog();
            }),
            _buildSettingsItem(Icons.share_outlined, 'Invite Friends', () {
              Navigator.pop(context);
              _showInviteDialog();
            }),
            _buildSettingsItem(Icons.delete_forever_outlined, 'Delete Account', () {
              Navigator.pop(context);
              _showDeleteAccount();
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: onTap,
    );
  }

  void _showManageProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: const Text('Manage Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Profile settings coming soon! Update username and bio here.', style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE', style: TextStyle(color: Color(0xFFA855F7)))),
        ],
      ),
    );
  }

  void _showSecurity() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: const Text('Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Password', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 8),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Minimum 6 characters',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final pwd = passwordController.text.trim();
              if (pwd.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password too short')));
                return;
              }
              try {
                await Supabase.instance.client.auth.updateUser(UserAttributes(password: pwd));
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: const Text('Delete Account?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently disable your account and hide your profile from others. This action cannot be undone.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () async {
              final myId = Supabase.instance.client.auth.currentUser?.id;
              if (myId != null) {
                await _supabaseService.deleteProfile(myId);
                await Supabase.instance.client.auth.signOut();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showGemShop() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final packages = [
      {'gems': 10, 'price': '\$0.99', 'type': 'gems'},
      {'gems': 50, 'price': '\$4.49', 'type': 'gems'},
      {'gems': 100, 'price': '\$7.99', 'type': 'gems'},
      {'name': 'Streak Freeze', 'price': '15 💎', 'type': 'item', 'icon': Icons.ac_unit},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GEM SHOP', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 24),
            ...packages.map((pkg) {
              final isItem = pkg['type'] == 'item';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
                ),
                child: ListTile(
                  leading: Icon(isItem ? pkg['icon'] as IconData : Icons.diamond, color: Colors.pinkAccent),
                  title: Text(isItem ? pkg['name'] as String : '${pkg['gems']} Gems', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: ElevatedButton(
                    onPressed: () {
                      if (isItem) {
                        if (pkg['name'] == 'Streak Freeze') {
                          _purchaseStreakFreeze(userId);
                          Navigator.pop(context);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(pkg['price'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseStreakFreeze(String userId) async {
    try {
      await _supabaseService.buyStreakFreeze(userId);
      setState(() {
        _profileFuture = _supabaseService.fetchProfile(userId);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Streak Freeze purchased! ❄️')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent));
    }
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191022),
        title: const Text('Send Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Tell us anything...', Icons.chat_bubble_outline),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback sent! Thank you! ❤️')));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7)),
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() {
    final user = Supabase.instance.client.auth.currentUser;
    final referralCode = user?.email?.split('@')[0].toUpperCase() ?? 'DAREDAY2024';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191022),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text('INVITE FRIENDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text('Share your code to earn 10 Gems for every friend who joins!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(referralCode, style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share link generated!')));
              },
              icon: const Icon(Icons.share, size: 18),
              label: const Text('SHARE LINK'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA855F7),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFollowingList(String userId) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return FutureBuilder<List<String>>(
            future: _supabaseService.fetchFollowingIds(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)));
              }
              final ids = snapshot.data ?? [];
              if (ids.isEmpty) {
                return const Center(child: Text('Not following anyone yet.', style: TextStyle(color: Colors.white38)));
              }

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Following', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: ids.length,
                      itemBuilder: (context, index) {
                        return FutureBuilder<UserModel>(
                          future: _supabaseService.fetchProfile(ids[index]),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) return const SizedBox.shrink();
                            final followedUser = userSnapshot.data!;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFA855F7).withValues(alpha: 0.2),
                                child: Text(followedUser.username[0].toUpperCase(), style: const TextStyle(color: Color(0xFFA855F7))),
                              ),
                              title: Text(followedUser.username, style: const TextStyle(color: Colors.white)),
                              trailing: TextButton(
                                onPressed: () async {
                                  await _supabaseService.unfollowUser(userId, followedUser.id);
                                  setModalState(() {});
                                  setState(() {
                                    _profileFuture = _supabaseService.fetchProfile(userId);
                                  });
                                },
                                child: const Text('UNFOLLOW', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _buySkipTokens(String userId) async {
    try {
      await _supabaseService.buySkipToken(userId);
      setState(() {
        _profileFuture = _supabaseService.fetchProfile(userId);
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skip Token purchased! ⚡')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.redAccent));
    }
  }

  void _showGemsShop(String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Buy Gems', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Fuel your bravery with gems! 💎', style: TextStyle(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 24),
            _buildShopItem(userId, '5 Gems', '0.99 USD', 5),
            const SizedBox(height: 12),
            _buildShopItem(userId, '30 Gems', '4.99 USD', 30),
            const SizedBox(height: 12),
            _buildShopItem(userId, '80 Gems', '9.99 USD', 80),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(String userId, String title, String price, int amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond, color: Colors.pinkAccent, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(price, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _supabaseService.updateGems(userId, amount);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _profileFuture = _supabaseService.fetchProfile(userId);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Successfully bought $amount gems! 💎')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('PURCHASE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProfileSheet(UserModel user) {
    final usernameController = TextEditingController(text: user.username);
    final bioController = TextEditingController(text: user.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A1B3D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Username', Icons.person),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bioController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Bio', Icons.info_outline),
            ),
            const SizedBox(height: 24),
            const Text('Your Interests', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StatefulBuilder(
              builder: (context, setSheetState) {
                final categories = ['AI', 'Fitness', 'Tech', 'Nature', 'Extreme', 'Social'];
                final selected = List<String>.from(user.interests ?? []);
                
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selected.contains(cat);
                    return FilterChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: isSelected,
                      onSelected: (val) {
                        setSheetState(() {
                          if (val) selected.add(cat);
                          else selected.remove(cat);
                        });
                        // Update the outer user object interests locally to save later
                        (user.interests as List<String>?)?.clear();
                        (user.interests as List<String>?)?.addAll(selected);
                      },
                      selectedColor: const Color(0xFFA855F7).withValues(alpha: 0.3),
                      checkmarkColor: const Color(0xFFA855F7),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      labelStyle: TextStyle(color: isSelected ? const Color(0xFFA855F7) : Colors.white70),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Language', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButton<String>(
                value: 'English',
                dropdownColor: const Color(0xFF191022),
                underline: const SizedBox(),
                isExpanded: true,
                items: ['English', 'Spanish', 'French'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {},
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await _supabaseService.updateProfile(user.id, 
                  username: usernameController.text, 
                  bio: bioController.text,
                  interests: user.interests,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                setState(() {
                  _profileFuture = _supabaseService.fetchProfile(user.id);
                });
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: const Color(0xFFA855F7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('SAVE CHANGES'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: const Color(0xFFA855F7)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );
  }
}

class ProfileMemories extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;
  const ProfileMemories({super.key, required this.userId, this.isOwnProfile = false});

  @override
  State<ProfileMemories> createState() => _ProfileMemoriesState();
}

class _ProfileMemoriesState extends State<ProfileMemories> {
  late Future<List<UserAttemptModel>> _memoriesFuture;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  void _loadMemories() {
    setState(() {
      _memoriesFuture = SupabaseService().fetchUserAttempts(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserAttemptModel>>(
      future: _memoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)));
        }
        final attempts = snapshot.data ?? [];
        if (attempts.isEmpty) {
          return const Center(
            child: Text(
              'No dares recorded yet. Go prove your bravery!',
              style: TextStyle(color: Colors.white24, fontSize: 12),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.8,
          ),
          itemCount: attempts.length,
          itemBuilder: (context, index) {
            final attempt = attempts[index];
            return Stack(
              children: [
                GestureDetector(
                  onTap: () => _showVideoPlayer(context, attempt),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_circle_outline, color: Colors.white38, size: 32),
                          if (attempt.dareTitle != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                attempt.dareTitle!,
                                style: const TextStyle(color: Colors.white24, fontSize: 8),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.isOwnProfile)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _confirmDelete(context, attempt.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.redAccent, size: 14),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, String attemptId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: const Text('Delete Memory?'),
        content: const Text('This will remove this dare proof permanently from your profile and feed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService().deleteAttempt(attemptId);
                if (mounted) {
                  Navigator.pop(context);
                  _loadMemories();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Memory deleted')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showVideoPlayer(BuildContext context, UserAttemptModel attempt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: SimpleVideoPlayer(url: attempt.videoUrl),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleVideoPlayer extends StatefulWidget {
  final String url;
  const SimpleVideoPlayer({super.key, required this.url});

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller.initialize().then((_) {
      _controller.setVolume(0); // Mute audio outside feed
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: true,
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }
    return const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7)));
  }
}
