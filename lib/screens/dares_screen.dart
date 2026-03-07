import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/dare_model.dart';
import '../providers/navigation_provider.dart';
import '../models/user_model.dart';
import '../widgets/ranking_sheet.dart';
import 'proof_preview_screen.dart';

class DaresScreen extends StatefulWidget {
  const DaresScreen({super.key});

  @override
  State<DaresScreen> createState() => _DaresScreenState();
}

class _DaresScreenState extends State<DaresScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  late Timer _timer;
  Duration _timeLeft = const Duration(hours: 14, minutes: 22, seconds: 5);
  DareModel? _dailyDare;
  bool _loadingDaily = true;
  String _dailyDifficulty = 'Medium';
  List<DareModel> _receivedChallenges = [];
  bool _loadingChallenges = false;
  bool _dailyCompleted = false;
  UserModel? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchDailyDare();
    _fetchReceivedChallenges();
    _startTimer();
    _checkStreakReset();
  }

  Future<void> _fetchUserProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final user = await _supabaseService.fetchProfile(userId);
      if (mounted) {
        setState(() => _userProfile = user);
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> _checkStreakReset() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await _supabaseService.checkAndResetStreak(userId);
  }

  Future<void> _fetchReceivedChallenges() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loadingChallenges = true);
    try {
      final challenges = await _supabaseService.fetchReceivedChallenges(userId);
      if (mounted) {
        setState(() {
          _receivedChallenges = challenges;
          _loadingChallenges = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingChallenges = false);
    }
  }

  Future<void> _fetchDailyDare() async {
    setState(() => _loadingDaily = true);
    try {
      final dare = await _supabaseService.fetchDailyChallenge(difficulty: _dailyDifficulty);
      if (mounted) {
        setState(() {
          _dailyDare = dare;
          _loadingDaily = false;
        });
        if (dare != null) {
          _checkDailyCompletion(dare.id);
        }
      }
    } catch (e) {
      debugPrint('Error fetching daily dare: $e');
      if (mounted) setState(() => _loadingDaily = false);
    }
  }

  Future<void> _checkDailyCompletion(String dareId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    
    final completed = await _supabaseService.isDareCompleted(userId, dareId);
    if (mounted) {
      setState(() => _dailyCompleted = completed);
    }
  }

  void _startTimer() {
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final difference = endOfDay.difference(now);

    if (mounted) {
      setState(() {
        _timeLeft = difference.isNegative ? Duration.zero : difference;
      });
    }

    // Refresh at midnight
    if (difference.inSeconds <= 0 && difference.inSeconds > -5) {
      _fetchDailyDare();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF22D3EE);
    const primaryColor = Color(0xFFA855F7);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F0814),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('DARES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined, color: Colors.white70),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const RankingSheet(),
              );
            },
          ),
        ],
      ),
      body: Consumer<NavigationProvider>(
        builder: (context, navProvider, child) {
          final grindDare = navProvider.activeGrindDare;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timer
                Center(
                  child: Text(
                    '${_timeLeft.inHours.toString().padLeft(2, "0")}:${(_timeLeft.inMinutes % 60).toString().padLeft(2, "0")}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, "0")}',
                    style: const TextStyle(
                      color: neonCyan, 
                      fontSize: 32, 
                      fontWeight: FontWeight.w900, 
                      shadows: [Shadow(color: neonCyan, blurRadius: 10)]
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Streak Progress
                _buildStreakProgress(),
                
                const SizedBox(height: 32),

                // SECTION: DAILY DARE
                _buildSectionHeader('DAILY DARE', Icons.calendar_today, neonCyan),
                const SizedBox(height: 12),
                _buildDailySection(context, primaryColor, neonCyan),

                const SizedBox(height: 32),

                // SECTION: CHALLENGES (Sent by friends)
                _buildSectionHeader('CHALLENGES', Icons.shield, Colors.pinkAccent), 
                const SizedBox(height: 12),
                _buildChallengesSection(context, navProvider, primaryColor, neonCyan),

                const SizedBox(height: 32),

                // SECTION: GRIND (AI)
                _buildSectionHeader('GRIND', Icons.bolt, primaryColor),
                const SizedBox(height: 12),
                _buildGrindSection(context, grindDare, navProvider, primaryColor, neonCyan),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDailySection(BuildContext context, Color primaryColor, Color neonCyan) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF191022),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: neonCyan.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Difficulty: $_dailyDifficulty',
                style: TextStyle(color: neonCyan.withValues(alpha: 0.7), fontWeight: FontWeight.bold, fontSize: 12),
              ),
              InkWell(
                onTap: _dailyCompleted ? null : _showDailyDifficultySelector,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _dailyCompleted ? Colors.white.withValues(alpha: 0.05) : neonCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _dailyCompleted ? 'LOCKED' : 'CHANGE', 
                    style: TextStyle(
                      color: _dailyCompleted ? Colors.white38 : Colors.white, 
                      fontSize: 10, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _loadingDaily
              ? const Center(child: CircularProgressIndicator())
              : _dailyDare == null
                  ? const Text('Syncing daily challenge...', style: TextStyle(color: Colors.white38))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dailyDare!.title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dailyDare!.instructions,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: (_dailyDare == null || _isProcessing || _dailyCompleted) ? null : () => _recordProof(_dailyDare!),
                                icon: Icon(_dailyCompleted ? Icons.check_circle : Icons.videocam, size: 18),
                                label: Text(_dailyCompleted ? 'COMPLETED ✅' : 'PROVE IT'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _dailyCompleted ? Colors.green.withValues(alpha: 0.6) : neonCyan.withValues(alpha: 0.8),
                                  minimumSize: const Size(0, 44),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            if (!_dailyCompleted) ...[
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: _isProcessing ? null : () => _skipDaily(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 44),
                                  side: const BorderSide(color: Colors.redAccent, width: 1),
                                  foregroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('SKIP (-50)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  Widget _buildGrindSection(BuildContext context, DareModel? grindDare, NavigationProvider navProvider, Color primaryColor, Color neonCyan) {
    if (grindDare == null) {
      return Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white24, size: 24),
            const SizedBox(height: 8),
            const Text('No active grind.', style: TextStyle(color: Colors.white24, fontSize: 12)),
            TextButton(
              onPressed: () => navProvider.setTab(3), // Switch to AI tab
              child: const Text('GENERATE ONE', style: TextStyle(color: Color(0xFFA855F7), fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF191022),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${grindDare.difficulty.toUpperCase()} • ${grindDare.xpReward} pts${grindDare.gemReward > 0 ? " • ${grindDare.gemReward} Gem" : ""}',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            grindDare.title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            grindDare.instructions,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _recordProof(grindDare),
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('PROVE IT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isProcessing ? null : () => _forfeitGrind(navProvider),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  foregroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('FORFEIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection(BuildContext context, NavigationProvider navProvider, Color primaryColor, Color neonCyan) {
    if (_loadingChallenges) {
      return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
    }

    if (_receivedChallenges.isEmpty) {
      return Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No friend challenges yet.', style: TextStyle(color: Colors.white24, fontSize: 12)),
            TextButton(
              onPressed: _fetchReceivedChallenges,
              child: const Text('REFRESH', style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _receivedChallenges.map((challenge) {
        final isAccepted = challenge.challengeStatus == 'accepted';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF191022),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3), width: 1),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'CHALLENGE • ${challenge.xpReward} pts',
                        style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                    ),
                    Text(
                      'From: ${challenge.senderName ?? "Unknown"}',
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  challenge.title,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  challenge.instructions,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : () => _recordProof(challenge),
                        icon: const Icon(Icons.videocam, size: 18),
                        label: const Text('PROVE IT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _isProcessing ? null : () => _forfeitChallenge(challenge),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        side: const BorderSide(color: Colors.redAccent, width: 1),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('FORFEIT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _forfeitChallenge(DareModel dare) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: const Text('Forfeit Challenge?'),
        content: const Text('Giving up will cost you 100 pts. Choose how to proceed:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'), 
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'tax'), 
            child: const Text('CHICKEN TAX (5 💎)', style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'ad'), 
            child: const Text('WATCH AD (FREE)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'counter'), 
            child: const Text('COUNTER-DARE', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'forfeit'), 
            child: const Text('FORFEIT (-100)', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (result == 'cancel' || result == null) return;

    bool skipDeduction = false;
    if (result == 'tax') {
      try {
        await _supabaseService.updateGems(userId, -5);
        await _supabaseService.updateChallengeStatus(dare.id, 'rejected');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tax paid! No XP penalty.')));
          _fetchReceivedChallenges();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return;
    }

    if (result == 'ad') {
      skipDeduction = await _showAdPlaceholder();
      if (!skipDeduction) return; // User closed ad early or failed
    }

    setState(() => _isProcessing = true);
    try {
      if (!skipDeduction) {
        await _supabaseService.updateCoins(userId, -100);
      }
      await _supabaseService.updateChallengeStatus(dare.id, 'rejected'); 
      await _fetchReceivedChallenges();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(skipDeduction ? 'Challenge cleared via Ad!' : 'Challenge forfeited. -100 pts applied.')
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }

    if (result == 'counter') {
      try {
        await _supabaseService.updateCoins(userId, -100);
        await _supabaseService.updateChallengeStatus(dare.id, 'rejected');
        await _fetchReceivedChallenges();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Forfeited! -100 pts. Now go find them and dare them back!')));
          _fetchUserProfile();
          Provider.of<NavigationProvider>(context, listen: false).setTab(1); // Go to Search
        }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _skipDaily(BuildContext context) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: const Text('Skip Daily?'),
        content: const Text('Skipping will cost you 50 pts and reset your daily progress. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('SKIP (-50)', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      await _supabaseService.updateCoins(userId, -50);
      setState(() => _dailyCompleted = true); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Daily Dare skipped. -50 pts applied.')));
        _fetchUserProfile();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateChallengeStatus(String id, String status) async {
    setState(() => _isProcessing = true);
    try {
      await _supabaseService.updateChallengeStatus(id, status);
      await _fetchReceivedChallenges();
      if (mounted) {
        String msg = status == 'accepted' ? 'Challenge accepted! Time to prove it. 📽️' : 'Challenge rejected.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _recordProof(DareModel dare) async {
    try {
      final choice = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: const Color(0xFF191022),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam, color: Color(0xFF22D3EE)),
                title: const Text('Record Video', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, {'source': ImageSource.camera}),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.video_library, color: Color(0xFFA855F7)),
                title: const Text('Upload Video', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, {'source': ImageSource.gallery}),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );

      if (choice == null) return;

      final source = choice['source'] as ImageSource;
      final file = await _picker.pickVideo(source: source);

      if (file != null && mounted) {
        final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => ProofPreviewScreen(
          videoPath: file!.path,
          difficulty: dare.difficulty,
          dareId: dare.id,
          challengeId: dare.isChallenge ? dare.id : null, 
          xpReward: dare.xpReward,
          isChallenge: dare.isChallenge,
          isImage: false,
          dareTitle: dare.title,
          dareInstructions: dare.instructions,
        )));

        if (result == true && mounted) {
          _fetchDailyDare();
          _fetchReceivedChallenges();
          
          // Clear grind dare if it was the one completed
          final navProvider = Provider.of<NavigationProvider>(context, listen: false);
          if (navProvider.activeGrindDare?.id == dare.id) {
            navProvider.clearGrindDare();
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _forfeitGrind(NavigationProvider navProvider) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A1B3D),
        title: const Text('Forfeit Dare?'),
        content: const Text('Giving up will cost you 5 pts. Choose how to proceed:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'), 
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'ad'), 
            child: const Text('WATCH AD (FREE)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'forfeit'), 
            child: const Text('FORFEIT (-5)', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (result == 'cancel' || result == null) return;

    bool skipDeduction = false;
    if (result == 'ad') {
      skipDeduction = await _showAdPlaceholder();
      if (!skipDeduction) return; 
    }

    setState(() => _isProcessing = true);
    try {
      if (!skipDeduction) {
        await _supabaseService.updateCoins(userId, -5);
      }
      navProvider.clearGrindDare();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(skipDeduction ? 'Dare cleared via Ad!' : 'Dare forfeited. -5 pts applied.')
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showDailyDifficultySelector() async {
    if (_dailyCompleted) return;
    
    final difficulties = ['Easy', 'Medium', 'Hard'];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191022),
        title: const Text('Daily Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: difficulties.map((d) => ListTile(
            title: Text(d, style: const TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, d),
            trailing: _dailyDifficulty == d ? const Icon(Icons.check, color: Color(0xFF22D3EE)) : null,
          )).toList(),
        ),
      ),
    );
    if (result != null) {
      setState(() => _dailyDifficulty = result);
      _fetchDailyDare();
    }
  }

  Future<bool> _showAdPlaceholder() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AdMiniWindow(),
    ) ?? false;
  }

  Widget _buildStreakProgress() {
    if (_userProfile == null) return const SizedBox(height: 60);

    final progress = _userProfile!.weeklyProgress;
    final streak = _userProfile!.streak;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (index) {
                return _buildStreakFire(index < progress);
              }),
            ),
            const SizedBox(height: 8),
            Text(
              'WEEKLY PROGRESS: $progress/7',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        );
  }

  Widget _buildStreakFire(bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Icon(
            isActive ? Icons.local_fire_department : Icons.local_fire_department_outlined,
            color: isActive ? Colors.orangeAccent : Colors.white10,
            size: 28,
          ),
          if (isActive)
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.orangeAccent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.orange, blurRadius: 4)],
              ),
            ),
        ],
      ),
    );
  }
}

class _AdMiniWindow extends StatefulWidget {
  @override
  State<_AdMiniWindow> createState() => _AdMiniWindowState();
}

class _AdMiniWindowState extends State<_AdMiniWindow> {
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    while (_secondsRemaining > 0) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _secondsRemaining--);
      } else {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF191022),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.amber, size: 64),
            const SizedBox(height: 24),
            const Text(
              'WATCHING AD...',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 12),
            Text(
              'Reward unlock in $_secondsRemaining s',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),
            if (_secondsRemaining == 0)
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('COLLECT REWARD', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CLOSE AD (NO REWARD)', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ),
          ],
        ),
      ),
    );
  }
}
