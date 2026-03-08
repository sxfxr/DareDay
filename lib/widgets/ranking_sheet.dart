import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../screens/profile_screen.dart';

class RankingSheet extends StatefulWidget {
  const RankingSheet({super.key});

  @override
  State<RankingSheet> createState() => _RankingSheetState();
}

class _RankingSheetState extends State<RankingSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF22D3EE);
    const backgroundDark = Color(0xFF191022);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text('RANKING', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.white24, size: 20),
                  onPressed: () => _showRankInfo(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: neonCyan,
            indicatorWeight: 3,
            labelColor: neonCyan,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'GLOBAL'),
              Tab(text: 'FRIENDS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardList(isGlobal: true),
                _buildLeaderboardList(isGlobal: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList({required bool isGlobal}) {
    final currentUserId = _supabase.auth.currentUser?.id;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: isGlobal ? _fetchGlobalLeaderboard() : _fetchFriendsLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white24)));
        }
        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No entries found.', style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isMe = user['id'] == currentUserId;
            final rank = index + 1;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(userId: user['id'])),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF22D3EE).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe ? const Color(0xFF22D3EE).withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  children: [
                    _buildRankBadge(rank),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: Colors.white10,
                      child: Text(user['username'][0].toUpperCase(), style: const TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['username'],
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Text(
                            user['rank_status'] ?? 'GHOST',
                            style: TextStyle(color: _getRankColor(user['rank_status']), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${user['coins']}',
                          style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text('pts', style: TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color = Colors.white24;
    if (rank == 1) color = const Color(0xFFFFD700);
    if (rank == 2) color = const Color(0xFFC0C0C0);
    if (rank == 3) color = const Color(0xFFCD7F32);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(
          '$rank',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchGlobalLeaderboard() async {
    final response = await _supabase.from('leaderboard').select().limit(50);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> _fetchFriendsLeaderboard() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return [];
    final followingIds = await _supabaseService.fetchFollowingIds(currentUserId);
    followingIds.add(currentUserId);
    final response = await _supabase.from('leaderboard').select().inFilter('id', followingIds);
    final results = List<Map<String, dynamic>>.from(response);
    results.sort((a, b) => (b['coins'] as int).compareTo(a['coins'] as int));
    return results;
  }

  Color _getRankColor(String? rank) {
    switch (rank) {
      case 'CHALLENGER': return const Color(0xFF22D3EE);
      case 'ADRENALINE JUNKIE': return const Color(0xFFA855F7);
      case 'DAREDEVIL': return Colors.orangeAccent;
      default: return Colors.white38;
    }
  }

  void _showRankInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191022),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white10)),
        title: const Text('RANKING SYSTEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRankInfoRow('GHOST', '0-49 pts', Colors.white38),
            const SizedBox(height: 12),
            _buildRankInfoRow('CHALLENGER', '50-199 pts', const Color(0xFF22D3EE)),
            const SizedBox(height: 12),
            _buildRankInfoRow('ADRENALINE JUNKIE', '200-499 pts', const Color(0xFFA855F7)),
            const SizedBox(height: 12),
            _buildRankInfoRow('DAREDEVIL', '500+ pts', Colors.orangeAccent),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT', style: TextStyle(color: Color(0xFF22D3EE), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRankInfoRow(String title, String threshold, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
        Text(threshold, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
