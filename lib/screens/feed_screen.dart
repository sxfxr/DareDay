import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/social_bar.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../models/dare_model.dart';
import '../providers/navigation_provider.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with WidgetsBindingObserver {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<UserAttemptModel>> _attemptsFuture;
  final PageController _pageController = PageController();
  int _lastRefreshKey = -1;
  bool _showFollowingOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAttempts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final navProvider = Provider.of<NavigationProvider>(context);
    if (navProvider.feedRefreshKey != _lastRefreshKey) {
      _lastRefreshKey = navProvider.feedRefreshKey;
      _loadAttempts();
    }
  }

  void _loadAttempts() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    _attemptsFuture = (_showFollowingOnly && userId != null)
        ? _supabaseService.fetchFollowingAttempts(userId)
        : _supabaseService.fetchAttempts();
    
    _attemptsFuture.then((attempts) {
      debugPrint('Feed loaded ${attempts.length} attempts (FollowingOnly: $_showFollowingOnly)');
      return attempts;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _loadAttempts());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _loadAttempts();
              });
            },
            color: const Color(0xFFA855F7),
            child: FutureBuilder<List<UserAttemptModel>>(
        future: _attemptsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          final attempts = snapshot.data ?? [];
          if (attempts.isEmpty) {
            return const Center(child: Text('No proof videos found. Go record one!', style: TextStyle(color: Colors.white)));
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: attempts.length,
            itemBuilder: (context, index) {
              return DarePlayer(attempt: attempts[index]);
            },
                );
              },
            ),
          ),
          // Top Toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToggleItem('For You', !_showFollowingOnly),
                const SizedBox(width: 20),
                _buildToggleItem('Following', _showFollowingOnly),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          setState(() {
            _showFollowingOnly = title == 'Following';
            _loadAttempts();
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              width: 20,
              height: 2,
              color: const Color(0xFFA855F7),
            ),
        ],
      ),
    );
  }
}

class DarePlayer extends StatefulWidget {
  final UserAttemptModel attempt;
  const DarePlayer({super.key, required this.attempt});

  @override
  State<DarePlayer> createState() => _DarePlayerState();
}

class _DarePlayerState extends State<DarePlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _showHeart = false;
  Offset _heartPosition = Offset.zero;
  CommentModel? _latestComment;
  bool _hasError = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchLatestComment();
    _initializePlayer();
  }

  Future<void> _fetchLatestComment() async {
    try {
      final comments = await SupabaseService().fetchComments(widget.attempt.id);
      if (mounted) {
        setState(() {
          _latestComment = comments.isNotEmpty ? comments.first : null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching latest comment: $e');
    }
  }

  Future<void> _initializePlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.attempt.videoUrl));
      await _videoController!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: true,
        showControls: false,
        aspectRatio: _videoController!.value.aspectRatio,
      );
      
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Video Player error for ${widget.attempt.id}: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, child) {
        // Pause video if not on feed tab
        if (navProvider.selectedIndex != 0) {
          _videoController?.pause();
        } else {
          // Only play if it was already playing or supposed to
          if (_videoController != null && !_videoController!.value.isPlaying && _chewieController != null) {
             _videoController?.play();
          }
        }

        return GestureDetector(
          onDoubleTapDown: (details) => _handleDoubleTap(details.localPosition),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Video Player
            Positioned.fill(
                child: _hasError 
                    ? _buildErrorPlaceholder()
                    : _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                        ? Chewie(controller: _chewieController!)
                        : const Center(child: CircularProgressIndicator(color: Color(0xFFA855F7))),
              ),
        
        // Overlays
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF191022).withValues(alpha: 0.9),
                  Colors.transparent,
                  Colors.transparent,
                  const Color(0xFF191022).withValues(alpha: 0.4),
                ],
                stops: const [0.0, 0.4, 0.6, 1.0],
              ),
            ),
          ),
        ),

        // Sidebar
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            children: [
              _buildFollowButton(),
              const SizedBox(height: 20),
              SocialBar(
                attemptId: widget.attempt.id,
                videoUrl: widget.attempt.videoUrl,
              ),
            ],
          ),
        ),

        // Dare Title Chip
        if (widget.attempt.dareTitle != null)
          Positioned(
            left: 16,
            bottom: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA855F7).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Color(0xFFA855F7), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    widget.attempt.dareTitle!,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

        // Details
        Positioned(
          bottom: 40,
          left: 16,
          right: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Submitted by: ${widget.attempt.username}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dare Attempt',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (widget.attempt.caption != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MESSAGE:',
                        style: TextStyle(
                          color: Color(0xFFA855F7), 
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.attempt.caption!,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 13, 
                          height: 1.4,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
              ),
            ),
            _buildHeartOverlay(),
          ],
            ),
        );
      },
    );
  }

  Future<void> _handleDoubleTap(Offset position) async {
    setState(() {
      _showHeart = true;
      _heartPosition = position;
    });

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      await SupabaseService().submitReaction(userId, widget.attempt.id, 'heart');
    }

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _showHeart = false);
    }
  }

  Widget _buildHeartOverlay() {
    if (!_showHeart) return const SizedBox.shrink();

    return Positioned(
      left: _heartPosition.dx - 50,
      top: _heartPosition.dy - 50,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        builder: (context, value, child) {
          return Opacity(
            opacity: value > 0.8 ? (1.0 - value) * 5 : 1.0,
            child: Transform.scale(
              scale: value * 1.5,
              child: const Icon(Icons.favorite, color: Colors.redAccent, size: 100),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFollowButton() {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null || currentUserId == widget.attempt.userId) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () async {
        await SupabaseService().followUser(currentUserId, widget.attempt.userId);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Followed!')));
      },
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(color: Color(0xFFA855F7), shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black87,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load video',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          TextButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _errorMsg = null;
                _initializePlayer();
              });
            },
            child: const Text('RETRY', style: TextStyle(color: Color(0xFFA855F7))),
          ),
        ],
      ),
    );
  }
}
