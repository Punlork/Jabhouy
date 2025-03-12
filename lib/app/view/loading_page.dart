// ignore_for_file: use_build_context_synchronously

import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';
import 'package:my_app/l10n/l10n.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;

  final List<ParticleModel> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutCubic,
      ),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      _rotationController,
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _initializeParticles();

    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        if (!context.mounted) return;
        context.read<AuthBloc>().add(AuthCheckRequested());
      },
    );
  }

  void _initializeParticles() {
    for (var i = 0; i < 20; i++) {
      _particles.add(
        ParticleModel(
          position: Offset(
            _random.nextDouble() * double.infinity,
            _random.nextDouble() * double.infinity,
          ),
          size: _random.nextDouble() * 8 + 2,
          speed: _random.nextDouble() * 1.5 + 0.5,
          angle: _random.nextDouble() * pi * 2,
          opacity: _random.nextDouble() * 0.6 + 0.2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context); // Access translations

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.goNamed(AppRoutes.home);
        } else if (state is Unauthenticated) {
          context.goNamed(AppRoutes.signin);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primaryContainer,
                    colorScheme.secondary.withValues(alpha: .8),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _rotationAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  origin: Offset(size.width, size.height),
                  child: CustomPaint(
                    size: Size(size.width, size.height),
                    painter: BackgroundPatternPainter(
                      color: colorScheme.onPrimary.withValues(alpha: .1),
                    ),
                  ),
                );
              },
            ),
            CustomPaint(
              size: Size(size.width, size.height),
              painter: ParticlesPainter(
                particles: _particles,
                color: colorScheme.onPrimary,
              ),
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(seconds: 1),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: child,
                        );
                      },
                      child: const AppLogo(size: 120),
                    ),
                    const SizedBox(height: 50),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ScaleTransition(
                          scale: _pulseAnimation,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.onPrimary.withValues(alpha: .15),
                            ),
                          ),
                        ),
                        RotationTransition(
                          turns: _rotationController,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.onPrimary.withValues(alpha: .7),
                                width: 4,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              ),
                              gradient: SweepGradient(
                                colors: [
                                  colorScheme.onPrimary.withValues(alpha: .1),
                                  colorScheme.onPrimary.withValues(alpha: .8),
                                ],
                                stops: const [0.0, 0.7],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.onPrimary.withValues(alpha: .5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _fadeController,
                          curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
                        ),
                      ),
                      child: Text(
                        l10n.gettingReady, // Translated
                        style: AppTextTheme.headline.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold, // Already w700
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: .4),
                              blurRadius: 10,
                              offset: const Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 24,
                      child: AnimatedTextKit(
                        repeatForever: true,
                        animatedTexts: [
                          TypewriterAnimatedText(
                            l10n.preparingExperience, // Translated
                            textStyle: AppTextTheme.body.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: .9),
                              fontSize: 18, // Override to match original
                              letterSpacing: 0.5,
                            ),
                            speed: const Duration(milliseconds: 80),
                          ),
                          TypewriterAnimatedText(
                            l10n.loadingContent, // Translated
                            textStyle: AppTextTheme.body.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: .9),
                              fontSize: 18, // Override to match original
                              letterSpacing: 0.5,
                            ),
                            speed: const Duration(milliseconds: 80),
                          ),
                          TypewriterAnimatedText(
                            l10n.almostThere, // Translated
                            textStyle: AppTextTheme.body.copyWith(
                              color: colorScheme.onPrimary.withValues(alpha: .9),
                              fontSize: 18, // Override to match original
                              letterSpacing: 0.5,
                            ),
                            speed: const Duration(milliseconds: 80),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController,
                  curve: const Interval(0.7, 1),
                ),
                child: Center(
                  child: Text(
                    l10n.appVersion('1.0.0'), // Translated with parameter
                    style: AppTextTheme.caption.copyWith(
                      color: colorScheme.onPrimary.withValues(alpha: .6),
                      fontSize: 14, // Override to match original
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for background pattern
class BackgroundPatternPainter extends CustomPainter {
  BackgroundPatternPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw concentric circles
    for (var i = 0; i < 10; i++) {
      final radius = (size.width / 2) * (i / 10 + 0.2);
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        radius,
        paint,
      );
    }

    // Draw crossing lines
    for (var i = 0; i < 12; i++) {
      final angle = pi * 2 * (i / 12);
      final dx = cos(angle);
      final dy = sin(angle);

      canvas.drawLine(
        Offset(size.width / 2, size.height / 2),
        Offset(size.width / 2 + dx * size.width, size.height / 2 + dy * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Particle model for floating effect
class ParticleModel {
  ParticleModel({
    required this.position,
    required this.size,
    required this.speed,
    required this.angle,
    required this.opacity,
  });
  Offset position;
  double size;
  double speed;
  double angle;
  double opacity;

  void update(Size canvasSize) {
    // Move particle based on angle and speed
    position = Offset(
      position.dx + cos(angle) * speed,
      position.dy + sin(angle) * speed,
    );

    // Wrap around screen edges
    if (position.dx < 0) position = Offset(canvasSize.width, position.dy);
    if (position.dx > canvasSize.width) position = Offset(0, position.dy);
    if (position.dy < 0) position = Offset(position.dx, canvasSize.height);
    if (position.dy > canvasSize.height) position = Offset(position.dx, 0);
  }
}

// Custom painter for floating particles
class ParticlesPainter extends CustomPainter {
  ParticlesPainter({required this.particles, required this.color});
  final List<ParticleModel> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Update and draw each particle
    for (final particle in particles) {
      particle.update(size);

      final paint = Paint()
        ..color = color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        particle.position,
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
