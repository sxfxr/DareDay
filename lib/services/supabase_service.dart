import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dare_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // --- Profile Operations ---

  Future<void> createInitialProfile(String userId, String username) async {
    await _supabase.from('profiles').upsert({
      'id': userId,
      'username': username,
      'coins': 1000,
      'streak': 0,
    });
  }

  Future<UserModel> fetchProfile(String userId) async {
    final response = await _supabase.from('profiles').select().eq('id', userId).maybeSingle();
    if (response == null) {
      final email = _supabase.auth.currentUser?.email ?? '';
      final username = email.split('@').first;
      await createInitialProfile(userId, username);
      return await fetchProfile(userId);
    }
    return UserModel.fromJson(response);
  }

  Future<void> updateProfile(String userId, {String? username, String? bio, List<String>? interests}) async {
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (interests != null) updates['interests'] = interests;
    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    }
  }

  Future<void> updateCoins(String userId, int delta) async {
    // Fetch fresh profile to avoid stale data
    final profile = await fetchProfile(userId);
    final newCoins = profile.coins + delta;
    await _supabase.from('profiles').update({'coins': newCoins}).eq('id', userId);
  }

  Future<void> updateGems(String userId, int delta) async {
    final profile = await fetchProfile(userId);
    await _supabase.from('profiles').update({'gems': profile.gems + delta}).eq('id', userId);
  }

  Future<void> updateLastActive(String userId) async {
    await _supabase.from('profiles').update({'last_active': DateTime.now().toUtc().toIso8601String()}).eq('id', userId);
  }

  Future<void> updateInterests(String userId, List<String> interests) async {
    await _supabase.from('profiles').update({'interests': interests}).eq('id', userId);
  }

  Future<void> deleteProfile(String userId) async {
    await _supabase.from('profiles').update({'deleted_at': DateTime.now().toUtc().toIso8601String()}).eq('id', userId);
  }

  // --- Economy/Items ---

  Future<void> buyStreakFreeze(String userId) async {
    final profile = await fetchProfile(userId);
    if (profile.gems < 15) throw Exception('Not enough gems! 💎');
    await _supabase.from('profiles').update({
      'gems': profile.gems - 15,
      'streak_freezes': profile.streakFreezes + 1,
    }).eq('id', userId);
  }

  Future<void> buySkipToken(String userId) async {
    final profile = await fetchProfile(userId);
    if (profile.gems < 5) throw Exception('Not enough gems!');
    await _supabase.from('profiles').update({
      'gems': profile.gems - 5,
      'skip_tokens': profile.skipTokens + 1,
    }).eq('id', userId);
  }

  // --- Dare & Attempt Operations ---

  Future<List<DareModel>> fetchDares() async {
    final response = await _supabase.from('dares_master').select().order('created_at', ascending: false);
    return (response as List).map((json) => DareModel.fromJson(json)).toList();
  }

  Future<List<UserAttemptModel>> fetchAttempts() async {
    final response = await _supabase
        .from('user_attempts')
        .select('*, profiles(username), dares_master(title)')
        .order('completed_at', ascending: false);
    return (response as List).map((json) => UserAttemptModel.fromJson(json)).toList();
  }

  Future<List<UserAttemptModel>> fetchFollowingAttempts(String userId) async {
    final followingIds = await fetchFollowingIds(userId);
    if (followingIds.isEmpty) return [];

    final response = await _supabase
        .from('user_attempts')
        .select('*, profiles(username), dares_master(title)')
        .inFilter('user_id', followingIds)
        .order('completed_at', ascending: false);
    return (response as List).map((json) => UserAttemptModel.fromJson(json)).toList();
  }

  Future<void> submitAttempt(UserAttemptModel attempt) async {
    await _supabase.from('user_attempts').insert(attempt.toJson());
  }

  Future<bool> isDareCompleted(String userId, String dareId) async {
    final response = await _supabase
        .from('user_attempts')
        .select('id')
        .eq('user_id', userId)
        .eq('dare_id', dareId)
        .maybeSingle();
    return response != null;
  }

  Future<void> deleteAttempt(String attemptId) async {
    await _supabase.from('user_attempts').delete().eq('id', attemptId);
  }

  Future<String> uploadVideo(File videoFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final path = 'attempts/$fileName';
    final bytes = await videoFile.readAsBytes();
    await _supabase.storage.from('proof_videos').uploadBinary(path, bytes);
    return _supabase.storage.from('proof_videos').getPublicUrl(path);
  }

  Future<List<UserAttemptModel>> fetchUserAttempts(String userId) async {
    final response = await _supabase.from('user_attempts').select().eq('user_id', userId).order('completed_at', ascending: false);
    return (response as List).map((json) => UserAttemptModel.fromJson(json)).toList();
  }

  /// Ensures a dare exists in dares_master before an attempt is linked to it.
  /// Useful for AI-generated dares and friend challenges that aren't yet in the master list.
  Future<void> ensureDareExists(DareModel dare) async {
    try {
      await _supabase.from('dares_master').upsert(dare.toJson());
    } catch (e) {
      debugPrint('Note: Error ensuring dare exists (might already exist or schema mismatch): $e');
      // We don't want to block the whole flow if this fails (e.g. RLS issues on master table)
      // but it helps if it works.
    }
  }

  // --- Social & Graph ---

  Future<void> followUser(String followerId, String targetId) async {
    await _supabase.from('social_graph').upsert({'follower_id': followerId, 'following_id': targetId});
  }

  Future<void> unfollowUser(String followerId, String targetId) async {
    await _supabase.from('social_graph').delete().match({'follower_id': followerId, 'following_id': targetId});
  }

  Future<Map<String, int>> fetchSocialCounts(String userId) async {
    final followers = await _supabase.from('social_graph').select('follower_id').eq('following_id', userId);
    final following = await _supabase.from('social_graph').select('following_id').eq('follower_id', userId);
    return {'followers': (followers as List).length, 'following': (following as List).length};
  }

  Future<bool> checkFollowStatus(String followerId, String targetId) async {
    final res = await _supabase.from('social_graph').select().match({'follower_id': followerId, 'following_id': targetId}).maybeSingle();
    return res != null;
  }

  Future<bool> isMutualFollow(String userA, String userB) async {
    return await checkFollowStatus(userA, userB) && await checkFollowStatus(userB, userA);
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final res = await _supabase.from('profiles').select().ilike('username', '%$query%').limit(10);
    return (res as List).map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<String>> fetchFollowingIds(String userId) async {
    final response = await _supabase.from('social_graph').select('following_id').eq('follower_id', userId);
    return (response as List).map((json) => json['following_id'] as String).toList();
  }

  Future<DareModel?> fetchDailyChallenge({String difficulty = 'Medium'}) async {
    final now = DateTime.now().toUtc();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    try {
      final scheduled = await _supabase.from('daily_challenges').select('*, dares_master(*)').eq('date', todayStr).maybeSingle();
      if (scheduled != null && scheduled['dares_master'] != null) {
        final dareJson = scheduled['dares_master'] as Map<String, dynamic>;
        // If the scheduled dare matches the requested difficulty, return it.
        // Otherwise, fall back to rotation.
        if (dareJson['difficulty'] == difficulty) {
          return DareModel.fromJson(dareJson);
        }
      }
      
      // Fallback: Fetch dares of specific difficulty
      final response = await _supabase.from('dares_master').select().eq('difficulty', difficulty).order('id', ascending: true);
      final allDares = (response as List).map((json) => DareModel.fromJson(json)).toList();
      
      if (allDares.isEmpty) {
        // Absolute fallback to any dare if no match for difficulty
        final anyResponse = await _supabase.from('dares_master').select().limit(5);
        final anyDares = (anyResponse as List).map((json) => DareModel.fromJson(json)).toList();
        if (anyDares.isEmpty) return null;
        return anyDares[now.day % anyDares.length];
      }

      final dayOfYear = now.difference(DateTime.utc(now.year, 1, 1)).inDays;
      final index = dayOfYear % allDares.length;
      return allDares[index];
    } catch (e) {
      debugPrint('Error in fetchDailyChallenge: $e');
      return null;
    }
  }

  // --- Challenges ---

  Future<void> sendChallenge({required String senderId, required String recipientId, required String title, required String instructions, int xpReward = 15}) async {
    await _supabase.from('friend_challenges').insert({'sender_id': senderId, 'recipient_id': recipientId, 'title': title, 'instructions': instructions, 'xp_reward': xpReward, 'status': 'pending'});
  }

  Future<List<DareModel>> fetchReceivedChallenges(String userId) async {
    final res = await _supabase.from('friend_challenges').select('*, sender:profiles!sender_id(username)').eq('recipient_id', userId).inFilter('status', ['pending', 'accepted']).order('created_at', ascending: false);
    return (res as List).map((json) {
      final sender = json['sender'] as Map<String, dynamic>?;
      return DareModel(
        id: json['id'], title: json['title'], instructions: json['instructions'], difficulty: 'Custom', xpReward: json['xp_reward'] ?? 15, isChallenge: true, senderName: sender?['username'] ?? 'Unknown', challengeStatus: json['status'], createdAt: DateTime.parse(json['created_at']),
      );
    }).toList();
  }

  Future<void> updateChallengeStatus(String id, String status) async {
    await _supabase.from('friend_challenges').update({'status': status}).eq('id', id);
  }

  Future<void> completeChallenge(String id) async {
    await _supabase.from('friend_challenges').update({'status': 'completed'}).eq('id', id);
  }

  // --- Streaks ---

  Future<void> updateStreakProgress(String userId, String difficulty) async {
    // Allow all standard difficulties to count for daily streak
    final validDiffs = ['Easy', 'Medium', 'Hard', 'Insane'];
    if (!validDiffs.contains(difficulty)) return;
    final profile = await fetchProfile(userId);
    final now = DateTime.now().toUtc();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    if (profile.lastDareDate == todayStr) return;
    int progress = profile.weeklyProgress + 1;
    int streaks = profile.totalStreaks;
    bool multiplier = profile.multiplierActive;
    if (progress >= 7) { progress = 0; streaks++; multiplier = true; }
    await _supabase.from('profiles').update({'weekly_progress': progress, 'total_streaks': streaks, 'multiplier_active': multiplier, 'last_dare_date': todayStr}).eq('id', userId);
  }

  Future<void> checkAndResetStreak(String userId) async {
    final profile = await fetchProfile(userId);
    if (profile.lastDareDate == null) return;
    final now = DateTime.now().toUtc();
    final last = DateTime.parse(profile.lastDareDate!);
    if (now.difference(last).inDays > 1) {
      if (profile.streakFreezes > 0) {
        await _supabase.from('profiles').update({'streak_freezes': profile.streakFreezes - 1, 'last_dare_date': "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}"}).eq('id', userId);
      } else {
        await _supabase.from('profiles').update({'weekly_progress': 0}).eq('id', userId);
      }
    }
  }

  // --- Reactions & Comments ---

  Future<void> submitReaction(String userId, String attemptId, String type) async {
    try {
      await _supabase.from('reactions').upsert({'user_id': userId, 'attempt_id': attemptId, 'type': type});
    } catch (e) {
      debugPrint('Error submitting reaction: $e');
      if (e.toString().contains('42501')) {
        debugPrint('RLS permission denied for reactions. Check DB policies.');
      }
    }
  }

  Future<Map<String, int>> fetchReactionCounts(String attemptId) async {
    final response = await _supabase
        .from('reactions')
        .select('type')
        .eq('attempt_id', attemptId);
    
    final Map<String, int> counts = {};
    for (var item in response as List) {
      final type = item['type'] as String;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    return counts;
  }

  Future<bool> checkMutualFollow(String userId, String otherId) async {
    final following = await _supabase
        .from('social_graph')
        .select('following_id')
        .eq('follower_id', userId)
        .eq('following_id', otherId)
        .maybeSingle();
    
    final follower = await _supabase
        .from('social_graph')
        .select('follower_id')
        .eq('follower_id', otherId)
        .eq('following_id', userId)
        .maybeSingle();
    
    return following != null && follower != null;
  }

  Future<int> fetchCommentCount(String attemptId) async {
    final response = await _supabase
        .from('comments')
        .select('id')
        .eq('attempt_id', attemptId);
    return (response as List).length;
  }

  Future<List<CommentModel>> fetchComments(String attemptId) async {
    try {
      // Try profiles join first.
      final res = await _supabase
          .from('comments')
          .select('*, profiles!comments_user_id_fkey(username)')
          .eq('attempt_id', attemptId)
          .order('created_at', ascending: false);
      
      var list = (res as List).map((json) => CommentModel.fromJson(json)).toList();
      
      // If any usernames are still Anonymous, try to fetch them from profiles table
      final anonymousIds = list
          .where((c) => c.username == 'Anonymous')
          .map((c) => c.userId)
          .toSet()
          .toList();

      if (anonymousIds.isNotEmpty) {
        final profileRes = await _supabase
            .from('profiles')
            .select('id, username')
            .inFilter('id', anonymousIds);
        
        final profileMap = {
          for (var p in (profileRes as List)) 
            p['id'] as String: p['username'] as String
        };

        // Re-construct the list with found usernames
        list = list.map((c) {
          if (c.username == 'Anonymous' && profileMap.containsKey(c.userId)) {
            return CommentModel(
              id: c.id,
              attemptId: c.attemptId,
              userId: c.userId,
              username: profileMap[c.userId]!,
              text: c.text,
              createdAt: c.createdAt,
            );
          }
          return c;
        }).toList();
      }

      debugPrint('Fetched ${list.length} comments for $attemptId');
      return list;
    } catch (e) {
      debugPrint('Error fetching comments with join: $e');
      try {
        final res = await _supabase
            .from('comments')
            .select('*')
            .eq('attempt_id', attemptId)
            .order('created_at', ascending: false);
        
        final rawList = (res as List);
        final userIds = rawList.map((j) => j['user_id'] as String).toSet().toList();
        
        Map<String, String> profileMap = {};
        if (userIds.isNotEmpty) {
          final profileRes = await _supabase.from('profiles').select('id, username').inFilter('id', userIds);
          profileMap = { for (var p in (profileRes as List)) p['id'] as String: p['username'] as String };
        }

        final list = rawList.map((json) {
          final uid = json['user_id'] as String;
          final uname = profileMap[uid] ?? 'Anonymous';
          return CommentModel(
            id: json['id'] as String,
            attemptId: json['attempt_id'] as String,
            userId: uid,
            username: uname,
            text: json['text'] as String,
            createdAt: DateTime.parse(json['created_at'] as String),
          );
        }).toList();

        debugPrint('Fallback fetched ${list.length} comments for $attemptId');
        return list;
      } catch (e2) {
        debugPrint('Fallback fetch failed: $e2');
        return [];
      }
    }
  }

  Future<void> addComment(String userId, String attemptId, String text) async {
    try {
      await _supabase.from('comments').insert({
        'user_id': userId, 
        'attempt_id': attemptId, 
        'text': text
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }
}
