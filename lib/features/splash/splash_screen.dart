import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/brand_assets.dart';
import '../auth/state/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;
  // Minimum dwell so the brand reveal lands even if auth resolves instantly.
  static const _minDwell = Duration(milliseconds: 1800);
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset(BrandAssets.logoVideo);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0); // muted — required for web autoplay
      await controller.play();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _videoReady = true;
      });
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  Future<void> _navigateAfter(AuthState state) async {
    final elapsed = DateTime.now().difference(_startedAt);
    if (elapsed < _minDwell) {
      await Future<void>.delayed(_minDwell - elapsed);
    }
    if (!mounted) return;
    switch (state) {
      case AuthSignedIn():
        context.go('/home');
      case AuthSignedOut():
        context.go('/onboarding');
      case AuthLoading():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (_, next) => _navigateAfter(next));

    return Scaffold(
      body: Stack(
        children: [
          // Base gradient (visible during video load and behind any letterboxing)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.emerald, AppColors.emeraldDark],
              ),
            ),
          ),
          // Brand content — video if ready, else static logo
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _videoReady && _video != null
                  ? _VideoBrand(controller: _video!)
                  : _StaticBrand(showFallback: _videoFailed),
            ),
          ),
          // Bottom spinner + tagline
          Positioned(
            left: 0,
            right: 0,
            bottom: 56,
            child: Column(
              children: [
                Text(
                  'Empowering Women. Enabling Better Living.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoBrand extends StatelessWidget {
  const _VideoBrand({required this.controller});
  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = (size.width * 0.7).clamp(200.0, 360.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio == 0
              ? 1.0
              : controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

class _StaticBrand extends StatelessWidget {
  const _StaticBrand({required this.showFallback});
  final bool showFallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            BrandAssets.logoMark,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Text(
                'i',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
            ),
          ),
        ),
        if (showFallback) ...[
          const SizedBox(height: 16),
          const Text(
            'iGobi',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}
