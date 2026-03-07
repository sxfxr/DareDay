import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_service.dart';
import '../services/ai_service.dart';
import '../models/dare_model.dart';
import '../providers/navigation_provider.dart';
import '../models/dare_verification_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'success_screen.dart';
import 'verification_failure_screen.dart';

class ProofPreviewScreen extends StatefulWidget {
  final String videoPath; 
  final String? dareId;
  final String? challengeId;
  final String difficulty;
  final int xpReward;
  final bool isChallenge;
  final bool isImage;
  final String? dareTitle;
  final String? dareInstructions;

  const ProofPreviewScreen({
    super.key, 
    required this.videoPath,
    required this.difficulty,
    this.dareId,
    this.challengeId,
    this.xpReward = 0,
    this.isChallenge = false,
    this.isImage = false,
    this.dareTitle,
    this.dareInstructions,
  });

  @override
  State<ProofPreviewScreen> createState() => _ProofPreviewScreenState();
}

class _ProofPreviewScreenState extends State<ProofPreviewScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isUploading = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final TextEditingController _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isImage) {
      _initializePreview();
    }
  }

  Future<void> _initializePreview() async {
    _videoController = VideoPlayerController.file(File(widget.videoPath));
    await _videoController!.initialize();
    _videoController!.setVolume(0); // Mute audio outside feed
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: true,
      aspectRatio: _videoController!.value.aspectRatio,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF22D3EE);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Review Proof', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: widget.isImage
                  ? Image.file(File(widget.videoPath), fit: BoxFit.contain)
                  : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                      ? Chewie(controller: _chewieController!)
                      : const Center(child: CircularProgressIndicator(color: Color(0xFF22D3EE))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: TextField(
              controller: _captionController,
              maxLength: 100,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                counterStyle: const TextStyle(color: Colors.white24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ElevatedButton(
              onPressed: _isUploading ? null : _submitProof,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: neonCyan,
                foregroundColor: Colors.black,
              ),
              child: Text(_isUploading ? 'Uploading...' : 'Submit Proof'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitProof() async {
    setState(() => _isUploading = true);
    String currentStep = 'initializing';
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // AI VERIFICATION STEP
      if (!widget.isImage && widget.dareTitle != null) {
        currentStep = 'AI Verification';
        
        // 1. Extract frames
        final frames = await _extractFrames();
        if (frames.isEmpty) throw Exception('Could not process video frames for verification.');

        // 2. Extract Audio
        currentStep = 'Extracting Audio';
        final audioData = await _extractAudio();

        // 3. Call AI Service
        final result = await AiService().verifyDareProof(
          title: widget.dareTitle!,
          instructions: widget.dareInstructions ?? '',
          frames: frames,
          audioData: audioData,
        );

        // 3. Check Threshold
        if (!result.passed) {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationFailureScreen(
                  score: result.score,
                  reasoning: result.reasoning,
                  dareTitle: widget.dareTitle!,
                ),
              ),
            );
          }
          setState(() => _isUploading = false);
          return;
        }
      }

      // 1. Fetch profile for metadata
      final profile = await _supabaseService.fetchProfile(userId);

      // 1. Upload media (can be image or video)
      currentStep = 'uploading media';
      final mediaFile = File(widget.videoPath);
      // We'll reuse uploadVideo since it's just a binary upload to a bucket
      // In a real app we might want to rename it or check extension
      final videoUrl = await _supabaseService.uploadVideo(mediaFile);

      // 1.5 Ensure Dare Metadata exists in dares_master (for AI/Challenges)
      if (widget.dareId != null) {
        currentStep = 'ensuring dare metadata';
        final dareToEnsure = DareModel(
          id: widget.dareId!,
          title: widget.dareTitle ?? 'Custom Dare',
          instructions: widget.dareInstructions ?? 'Follow the video proof.',
          difficulty: widget.difficulty,
          xpReward: widget.xpReward,
          isChallenge: widget.isChallenge,
          createdAt: DateTime.now(),
        );
        await _supabaseService.ensureDareExists(dareToEnsure);
      }

      // 2. Create attempt record in 'user_attempts'
      currentStep = 'saving attempt record';
      final attempt = UserAttemptModel(
        id: const Uuid().v4(),
        userId: userId,
        username: profile.username,
        dareId: widget.dareId,
        videoUrl: videoUrl,
        status: 'verified',
        caption: _captionController.text.trim().isEmpty ? null : _captionController.text.trim(),
        completedAt: DateTime.now(),
      );
      
      await _supabaseService.submitAttempt(attempt);

      // 3. Award points/gems and mark completed
      currentStep = 'awarding rewards';
      
      // Multiplier Logic
      int multiplier = profile.multiplierActive ? 2 : 1;
      
      // Weekend Warrior (2x)
      final now = DateTime.now();
      if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
        multiplier *= 2;
      }
      
      final totalXP = widget.xpReward * multiplier;
      await _supabaseService.updateCoins(userId, totalXP);
      
      // Hard Dare = Gems
      if (widget.difficulty == 'Hard' || widget.difficulty == 'Insane') {
        int gemReward = 10 * (profile.multiplierActive ? 2 : 1);
        await _supabaseService.updateGems(userId, gemReward);
      }
      
      if (widget.isChallenge) {
        await _supabaseService.updateGems(userId, 5);
        if (widget.challengeId != null) {
          await _supabaseService.completeChallenge(widget.challengeId!);
        }
      }

      // 4. Update Streak Progress
      await _supabaseService.updateStreakProgress(userId, widget.difficulty);

      if (mounted) {
        // Trigger feed refresh so new dare shows immediately
        final navProvider = Provider.of<NavigationProvider>(context, listen: false);
        navProvider.triggerFeedRefresh();
        
        final gemsEarned = widget.isChallenge ? 5 : 0;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(
              xpEarned: widget.xpReward,
              gemsEarned: gemsEarned,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('CRITICAL FAILURE during $currentStep: $e');
      if (mounted) {
        final errorMsg = 'Failed at $currentStep: $e';
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF191022),
            title: Text('Failed at: $currentStep', style: const TextStyle(color: Colors.redAccent)),
            content: Text(errorMsg, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Color(0xFF22D3EE))),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<List<Uint8List>> _extractFrames() async {
    final List<Uint8List> frames = [];
    try {
      // Get video duration to space frames
      final duration = _videoController?.value.duration.inMilliseconds ?? 0;
      if (duration == 0) return [];

      // Extract 3-5 frames
      int frameCount = 4;
      int interval = duration ~/ (frameCount + 1);

      for (int i = 1; i <= frameCount; i++) {
        final uint8list = await VideoThumbnail.thumbnailData(
          video: widget.videoPath,
          imageFormat: ImageFormat.JPEG,
          maxWidth: 512, // Reduced size for faster API calls
          quality: 50,
          timeMs: i * interval,
        );
        if (uint8list != null) {
          frames.add(uint8list);
        }
      }
    } catch (e) {
      debugPrint('Error extracting frames: $e');
    }
    return frames;
  }

  Future<Uint8List?> _extractAudio() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final audioPath = '${tempDir.path}/temp_audio_${const Uuid().v4()}.aac';
      
      // Extract audio using FFmpeg
      // -i: input, -vn: no video, -acodec aac: standard aac, -b:a 128k: bitrate
      final session = await FFmpegKit.execute('-i ${widget.videoPath} -vn -acodec aac -b:a 128k $audioPath');
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final audioFile = File(audioPath);
        final bytes = await audioFile.readAsBytes();
        
        // Clean up temp file
        try { await audioFile.delete(); } catch (_) {}
        
        return bytes;
      } else {
        debugPrint('FFmpeg failed to extract audio: ${await session.getOutput()}');
        return null; // Fallback to vision-only if audio fails
      }
    } catch (e) {
      debugPrint('Error in _extractAudio: $e');
      return null;
    }
  }
}
