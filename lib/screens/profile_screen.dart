import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../models/user_model.dart';
import '../models/dare_model.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

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
  final ImagePicker _picker = ImagePicker();
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _currentViewedId = widget.userId ?? Supabase.instance.client.auth.currentUser!.id;
    _profileFuture = _supabaseService.fetchProfile(_currentViewedId);
    _checkInitialFollowStatus();
  }

  Future<void> _checkInitialFollowStatus() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId != null && myId != _currentViewedId) {
      final isFollowing = await _supabaseService.checkFollowStatus(myId, _currentViewedId);
      if (mounted) setState(() => _isFollowing = isFollowing);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      try {
        await _supabaseService.uploadProfilePicture(_currentViewedId, File(image.path));
        setState(() {
          _profileFuture = _supabaseService.fetchProfile(_currentViewedId);
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated! ✨')));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFFA855F7);
    const accentCyan = Color(0xFF22D3EE);
    const backgroundDark = Color(0xFF0F0814);
    const goldMetallic = Color(0xFFFFD700);

    final myId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnProfile = myId == _currentViewedId;

    return Scaffold(
      backgroundColor: backgroundDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: !isOwnProfile ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ) : null,
        actions: isOwnProfile ? [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () => _showSettingsMenu(context),
          ),
          const SizedBox(width: 8),
        ] : null,
      ),
      body: Stack(
        children: [
          // Background Gradient Blobs
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryPurple.withValues(alpha: 0.15),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentCyan.withValues(alpha: 0.1),
              ),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container()),
            ),
          ),

          FutureBuilder<UserModel>(
            future: _profileFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: primaryPurple));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }
              final user = snapshot.data!;

              return FutureBuilder<Map<String, int>>(
                future: _supabaseService.fetchSocialCounts(user.id),
                builder: (context, socialSnapshot) {
                  final stats = socialSnapshot.data ?? {'followers': 0, 'following': 0};

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _profileFuture = _supabaseService.fetchProfile(_currentViewedId);
                      });
                    },
                    color: primaryPurple,
                    backgroundColor: backgroundDark,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 120),
                          // Avatar Section
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                GestureDetector(
                                  onTap: isOwnProfile ? _pickImage : null,
                                  child: Container(
                                    width: 128,
                                    height: 128,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white10, width: 2),
                                      boxShadow: [
                                        BoxShadow(color: primaryPurple.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: -5)
                                      ],
                                      image: DecorationImage(
                                        image: NetworkImage(user.avatarUrl ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=${user.username}&backgroundColor=b6e3f4,c0aede,d1d4f9'), 
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isOwnProfile)
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
                                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Username & Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.username,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (isOwnProfile) ...[
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => _showEditProfileSheet(user),
                                  child: const Icon(Icons.edit_rounded, color: Colors.white38, size: 18),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // Glowing metallic badge
                          _buildGlowingBadge(user.rankStatus),
                          
                          if (user.bio != null && user.bio!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              child: Text(
                                user.bio!,
                                style: GoogleFonts.inter(color: Colors.white60, fontSize: 15, height: 1.4),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          
                          const SizedBox(height: 24),

                          // Social stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialStat('${stats['followers']}', 'Followers', () => _showFollowersList(user.id)),
                              Container(width: 1, height: 24, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 24)),
                              _buildSocialStat('${stats['following']}', 'Following', () => _showFollowingList(user.id)),
                            ],
                          ),
                          
                          if (!isOwnProfile) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: _isFollowLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentCyan))
                                : GestureDetector(
                                    onTap: _toggleFollow,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _isFollowing ? Colors.white.withValues(alpha: 0.05) : accentCyan,
                                        borderRadius: BorderRadius.circular(12),
                                        border: _isFollowing ? Border.all(color: Colors.white10) : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          _isFollowing ? 'UNFOLLOW' : 'FOLLOW',
                                          style: GoogleFonts.inter(
                                            color: _isFollowing ? Colors.white70 : backgroundDark,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ],
                          
                          const SizedBox(height: 40),

                          // Stats Grid
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.5,
                              children: [
                                _buildTactileStatCard('STREAK', '${user.streak} 🔥', primaryPurple, Icons.bolt_rounded),
                                _buildTactileStatCard('TOTAL PTS', '${user.coins}', accentCyan, Icons.stars_rounded),
                                _buildTactileStatCard('GEMS', '${user.gems}', Colors.pinkAccent, Icons.diamond_rounded, onTap: isOwnProfile ? () => _showGemsShop(user.id) : null),
                                _buildTactileStatCard('SKIPS', '${user.skipTokens}', goldMetallic, Icons.electric_bolt_rounded),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          if (isOwnProfile) ...[
                            // Gradient Pill Button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildGradientPillButton(
                                label: 'BUY SKIP TOKEN',
                                subtitle: '5 Gems each',
                                icon: Icons.bolt_rounded,
                                onTap: () => _buySkipTokens(user.id),
                              ),
                            ),
                            const SizedBox(height: 32),
                            // De-emphasized Sign Out
                            TextButton(
                              onPressed: () => Supabase.instance.client.auth.signOut(),
                              child: Text('SIGN OUT', style: GoogleFonts.inter(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
                            ),
                          ] else ...[
                            // Actions for others
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildSecondaryButton('MESSAGE', Icons.chat_bubble_outline_rounded, () {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Messaging coming soon! 💬')));
                                    }),
                                  ),
                                  const SizedBox(width: 12),
                                  FutureBuilder<bool>(
                                    future: _supabaseService.isMutualFollow(myId!, _currentViewedId),
                                    builder: (context, mutualSnapshot) {
                                      final isMutual = mutualSnapshot.data ?? false;
                                      if (!isMutual) return const SizedBox.shrink();
                                      return Expanded(
                                        child: _buildGradientPillButton(
                                          label: 'DARE',
                                          icon: Icons.bolt_rounded,
                                          onTap: () => _showSendDareSheet(user),
                                          small: true,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 48),

                          // Memories Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.03),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                              border: const Border(top: BorderSide(color: Colors.white10, width: 1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('MEMORIES', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                                    const Icon(Icons.grid_view_rounded, color: Colors.white38, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                ProfileMemories(userId: user.id, isOwnProfile: isOwnProfile),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFollow() async {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _isFollowLoading = true);
    try {
      if (_isFollowing) {
        await _supabaseService.unfollowUser(myId, _currentViewedId);
      } else {
        await _supabaseService.followUser(myId, _currentViewedId);
      }
      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isFollowLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isFollowLoading = false);
      }
    }
  }

  Widget _buildGlowingBadge(String rank) {
    Color rankColor = _getRankColor(rank);
    bool isDaredevil = rank == 'DAREDEVIL';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDaredevil ? Colors.amber.withValues(alpha: 0.1) : rankColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: isDaredevil ? Colors.amber.withValues(alpha: 0.5) : rankColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          if (isDaredevil)
            BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 15, spreadRadius: 0)
        ],
      ),
      child: Text(
        rank,
        style: GoogleFonts.inter(
          color: isDaredevil ? const Color(0xFFFFD700) : rankColor,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          shadows: isDaredevil ? [const Shadow(color: Colors.amber, blurRadius: 10)] : null,
        ),
      ),
    );
  }

  Widget _buildTactileStatCard(String label, String value, Color color, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientPillButton({required String label, String? subtitle, required IconData icon, required VoidCallback onTap, bool small = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: small ? 16 : 20, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFA855F7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(small ? 20 : 24),
          boxShadow: [
            BoxShadow(color: const Color(0xFFA855F7).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: small ? 20 : 24),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: small ? 14 : 16, letterSpacing: 1)),
                if (subtitle != null)
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  void _showSendDareSheet(UserModel targetUser) {
    final titleController = TextEditingController();
    final instrController = TextEditingController();
    final aiService = AiService();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('DARE ${targetUser.username.toUpperCase()}', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text('Custom dares are checked by AI for safety.', style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Dare Title', Icons.title_rounded),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: instrController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Instructions...', Icons.description_rounded),
              ),
              const SizedBox(height: 24),
              if (isVerifying)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFFA855F7)),
                      SizedBox(height: 12),
                      Text('Gemma is verifying your dare...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ))
              else
                _buildGradientPillButton(
                  label: 'SEND DARE',
                  icon: Icons.send_rounded,
                  onTap: () async {
                    final title = titleController.text.trim();
                    final instr = instrController.text.trim();
                    
                    if (title.isEmpty || instr.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }

                    setSheetState(() => isVerifying = true);
                    
                    try {
                      final myId = Supabase.instance.client.auth.currentUser?.id;
                      if (myId == null) return;

                      // 1. AI Verification
                      final verification = await aiService.verifyCustomDare(title, instr);
                      
                      if (!verification['is_safe']) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('AI Blocked: ${verification['reason']}'),
                            backgroundColor: Colors.redAccent,
                          ));
                        }
                        setSheetState(() => isVerifying = false);
                        return;
                      }

                      // 2. Send Challenge
                      await _supabaseService.sendChallenge(
                        senderId: myId,
                        recipientId: targetUser.id,
                        title: title,
                        instructions: instr,
                      );

                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dare sent! 🔥')));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      setSheetState(() => isVerifying = false);
                    }
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialStat(String value, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'GHOST': return Colors.white38;
      case 'CHALLENGER': return const Color(0xFF22D3EE);
      case 'ADRENALINE JUNKIE': return const Color(0xFFA855F7);
      case 'DAREDEVIL': return Colors.orangeAccent;
      default: return Colors.white;
    }
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 32),
            _buildSettingsItem(Icons.person_outline_rounded, 'Manage Profile', () {
              Navigator.pop(context);
              _profileFuture.then((user) => _showEditProfileSheet(user));
            }),
            _buildSettingsItem(Icons.security_rounded, 'Security', () {
              Navigator.pop(context);
              _showSecurity();
            }),
            _buildSettingsItem(Icons.diamond_outlined, 'Gem Shop', () {
              Navigator.pop(context);
              _showGemsShop(_currentViewedId);
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
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
      onTap: onTap,
    );
  }

  void _showSecurity() {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF191022),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Colors.white10)),
          title: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Color(0xFFA855F7), size: 28),
              const SizedBox(width: 12),
              Text('Security', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UPDATE PASSWORD', style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: isObscured,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('New Password', Icons.lock_outline_rounded).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                    onPressed: () => setDialogState(() => isObscured = !isObscured),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: isObscured,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Confirm Password', Icons.lock_reset_rounded),
              ),
              const SizedBox(height: 8),
              Text('• Minimum 6 characters', style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.bold))
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFA855F7)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final pwd = passwordController.text.trim();
                  final confirm = confirmController.text.trim();
                  
                  if (pwd.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                    return;
                  }
                  if (pwd != confirm) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                    return;
                  }

                  try {
                    await Supabase.instance.client.auth.updateUser(UserAttributes(password: pwd));
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Password updated successfully! 🔐'),
                        backgroundColor: Colors.green,
                      ));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('UPDATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191022),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Account?', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'This will permanently disable your account. This action cannot be undone.',
          style: GoogleFonts.inter(color: Colors.white54),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              final myId = Supabase.instance.client.auth.currentUser?.id;
              if (myId != null) {
                await _supabaseService.deleteProfile(myId);
                await Supabase.instance.client.auth.signOut();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _showGemsShop(String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GEM SHOP', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Fuel your bravery with gems! 💎', style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
            const SizedBox(height: 32),
            _buildShopItem(userId, '10 Gems', '0.99 USD', 10),
            const SizedBox(height: 16),
            _buildShopItem(userId, '50 Gems', '4.49 USD', 50),
            const SizedBox(height: 16),
            _buildShopItem(userId, '100 Gems', '7.99 USD', 100),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildShopItem(String userId, String title, String price, int amount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.diamond, color: Colors.pinkAccent, size: 28),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(price, style: GoogleFonts.inter(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bought $amount gems! 💎')));
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('BUY', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 32, right: 32, top: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EDIT PROFILE', style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 32),
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Username', Icons.person_outline_rounded),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: bioController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Bio', Icons.info_outline_rounded),
            ),
            const SizedBox(height: 32),
            _buildGradientPillButton(
              label: 'SAVE CHANGES',
              icon: Icons.check_circle_outline_rounded,
              onTap: () async {
                await _supabaseService.updateProfile(user.id, 
                  username: usernameController.text.trim(), 
                  bio: bioController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                setState(() {
                  _profileFuture = _supabaseService.fetchProfile(user.id);
                });
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _showFollowingList(String userId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => FutureBuilder<List<UserModel>>(
        future: _supabaseService.fetchFollowingDetailed(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFA855F7))),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent))),
            );
          }
          final users = snapshot.data ?? [];
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('FOLLOWING', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                if (users.isEmpty)
                  const Expanded(child: Center(child: Text('Not following anyone yet.', style: TextStyle(color: Colors.white24)))),
                if (users.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final followedUser = users[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            backgroundImage: followedUser.avatarUrl != null ? NetworkImage(followedUser.avatarUrl!) : null,
                            child: followedUser.avatarUrl == null ? Text(followedUser.username[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
                          ),
                          title: Text(followedUser.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFollowersList(String userId) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191022),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => FutureBuilder<List<UserModel>>(
        future: _supabaseService.fetchFollowersDetailed(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Color(0xFFA855F7))),
            );
          }
          if (snapshot.hasError) {
            return SizedBox(
              height: 200,
              child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent))),
            );
          }
          final users = snapshot.data ?? [];
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('FOLLOWERS', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ),
                if (users.isEmpty)
                  const Expanded(child: Center(child: Text('No followers yet.', style: TextStyle(color: Colors.white24)))),
                if (users.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final follower = users[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white10,
                            backgroundImage: follower.avatarUrl != null ? NetworkImage(follower.avatarUrl!) : null,
                            child: follower.avatarUrl == null ? Text(follower.username[0].toUpperCase(), style: const TextStyle(color: Colors.white)) : null,
                          ),
                          title: Text(follower.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191022),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Send Feedback', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Tell us anything...', Icons.chat_bubble_outline),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: const TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback sent! ❤️')));
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFA855F7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration_rounded, color: Colors.amber, size: 64),
            const SizedBox(height: 24),
            Text('INVITE FRIENDS', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 12),
            Text('Share your code to earn 10 Gems!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(referralCode, style: GoogleFonts.inter(color: const Color(0xFF22D3EE), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  IconButton(icon: const Icon(Icons.copy_rounded, color: Colors.white38), onPressed: () {}),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildGradientPillButton(label: 'SHARE LINK', icon: Icons.share_rounded, onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: const Color(0xFFA855F7), size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1)),
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
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFA855F7))));
        }
        final attempts = snapshot.data ?? [];
        if (attempts.isEmpty) {
          return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('No memories yet. Go prove your bravery!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.white24, fontSize: 13))));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1),
          itemCount: attempts.length,
          itemBuilder: (context, index) {
            final attempt = attempts[index];
            return GestureDetector(
              onTap: () => _showVideoPlayer(context, attempt),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.play_circle_fill_rounded, color: Colors.white24, size: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showVideoPlayer(BuildContext context, UserAttemptModel attempt) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: AspectRatio(aspectRatio: 9/16, child: SimpleVideoPlayer(url: attempt.videoUrl)),
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
      _chewieController = ChewieController(videoPlayerController: _controller, autoPlay: true, looping: true, aspectRatio: 9/16);
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
