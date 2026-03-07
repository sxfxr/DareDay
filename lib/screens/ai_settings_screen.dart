import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/navigation_provider.dart';

class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final AiService _aiService = AiService();
  bool _isLoading = false;

  final Map<String, bool> _interests = {
    'Fitness': false,
    'Social': false,
    'Tech': false,
    'Comedy': false,
    'Travel': false,
    'Gaming': false,
    'Art': false,
  };

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }

  Future<void> _loadUserInterests() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final profile = await _supabaseService.fetchProfile(userId);
      if (profile.interests != null) {
        setState(() {
          for (var interest in profile.interests!) {
            if (_interests.containsKey(interest)) {
              _interests[interest] = true;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading interests: $e');
    }
  }

  final Map<String, IconData> _icons = {
    'Fitness': Icons.fitness_center,
    'Social': Icons.group,
    'Tech': Icons.memory,
    'Comedy': Icons.theater_comedy,
    'Travel': Icons.explore,
    'Gaming': Icons.sports_esports,
    'Art': Icons.palette,
  };

  final Map<String, String> _subtitles = {
    'Fitness': 'Workouts & physical goals',
    'Social': 'Meeting people & conversation',
    'Tech': 'Coding & digital gadgets',
    'Comedy': 'Pranks & funny situations',
    'Travel': 'Adventure & exploration',
    'Gaming': 'Challenges & achievements',
    'Art': 'Creativity & expression',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191022),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191022).withValues(alpha: 0.8),
        elevation: 0,
        title: const Text('Personalize Your Dares', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Gemini 2.5 Flash-Lite uses these to craft your challenges. Select at least 3 categories to get started.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _interests.keys.map((interest) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _interests[interest]!
                            ? const Color(0xFFA855F7).withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: SwitchListTile(
                      value: _interests[interest]!,
                      onChanged: (val) {
                        setState(() {
                          _interests[interest] = val;
                        });
                      },
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_icons[interest], color: const Color(0xFFA855F7)),
                      ),
                      title: Text(
                        interest,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        _subtitles[interest]!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                      ),
                      activeThumbColor: const Color(0xFFA855F7),
                      activeTrackColor: const Color(0xFFA855F7).withValues(alpha: 0.3),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Consumer<NavigationProvider>(
                  builder: (context, navProvider, child) {
                    final selectedCount = _interests.values.where((v) => v).length;
                    final hasGrindDare = navProvider.activeGrindDare != null;
                    final canGenerate = selectedCount >= 3 && !_isLoading && !hasGrindDare;

                    return Column(
                      children: [
                        Text(
                          hasGrindDare 
                            ? "✓ Finish your active grind first"
                            : '$selectedCount / 3 selected${selectedCount < 3 ? " — pick ${3 - selectedCount} more" : " ✓"}',
                          style: TextStyle(
                            color: (selectedCount >= 3 || hasGrindDare) ? const Color(0xFF22D3EE) : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: canGenerate ? () => _generateDare(navProvider) : null,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: const Color(0xFFA855F7),
                            disabledBackgroundColor: Colors.white10,
                            disabledForegroundColor: Colors.white24,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: canGenerate ? 10 : 0,
                            shadowColor: const Color(0xFFA855F7).withValues(alpha: 0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  hasGrindDare ? 'GRIND IN PROGRESS' : 'Generate My Dares',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFA855F7), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'POWERED BY GEMINI 2.5 FLASH-LITE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateDare(NavigationProvider navProvider) async {
    final difficulty = await _showDifficultySelector();
    if (difficulty == null) return;

    setState(() => _isLoading = true);
    try {
      final selectedInterests = _interests.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _supabaseService.updateInterests(userId, selectedInterests);
      }

      final newDare = await _aiService.generatePersonalizedDare(selectedInterests, difficulty);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A1B3D),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Column(
              children: [
                Text(newDare.title.toUpperCase(), 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22D3EE).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$difficulty • ${newDare.xpReward} pts${newDare.gemReward > 0 ? " • ${newDare.gemReward} Gem" : ""}', 
                    style: const TextStyle(color: Color(0xFF22D3EE), fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            content: Text(
              newDare.instructions, 
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)
            ),
            actions: [
              TextButton(
                onPressed: () {
                  navProvider.setGrindDare(newDare);
                  navProvider.setTab(2); // Go to Dares tab
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('LET\'S DO IT!', style: TextStyle(color: Color(0xFFA855F7), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2A1B3D),
            title: const Text('AI Challenge Notice', style: TextStyle(color: Color(0xFF22D3EE))),
            content: SingleChildScrollView(
              child: Text(
                _sanitizeAiError(e.toString()),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('GOT IT', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _showDifficultySelector() async {
    const difficulties = {
      'Easy': 'Starts small (3 pts)',
      'Medium': 'Steady progress (5 pts)',
      'Hard': 'True challenge (10 pts)',
    };

    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF191022),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Color(0xFFA855F7), width: 0.5)),
        title: Column(
          children: [
            const Text('Choose Difficulty', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            if (isWeekend) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text('🔥 2X WEEKEND REWARDS', style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: difficulties.entries.map((e) {
            return ListTile(
              onTap: () => Navigator.pop(context, e.key),
              title: Text(e.key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(e.value, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFFA855F7)),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _sanitizeAiError(String error) {
    String clean = error.replaceAll('Exception: ', '').replaceAll('FormatException: ', '');
    // Remove specific model leaks from Gemini error messages
    clean = clean.replaceAll(RegExp(r'model: gemini-[\w\.\-]+', caseSensitive: false), 'AI service');
    if (clean.contains('Quota exceeded')) {
      return 'The AI is currently resting due to high demand. Please try again in a few minutes! ⚡';
    }
    return clean;
  }
}
