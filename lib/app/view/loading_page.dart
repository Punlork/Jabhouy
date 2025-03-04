import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_app/app/app.dart';
import 'package:my_app/auth/auth.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          context.goNamed(AppRoutes.home);
        } else if (state is Unauthenticated) {
          context.goNamed(AppRoutes.signin);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: .9),
                colorScheme.primaryContainer.withValues(alpha: .7),
              ],
              stops: const [0.1, 0.9],
            ),
          ),
          child: Stack(
            children: [
              // Subtle animated background effect (optional)
              _buildBackgroundEffect(colorScheme),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo or Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surface.withValues(alpha: .2),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.shadow.withValues(alpha: .3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lock_open_rounded, // Replace with your app logo/icon
                        size: 80,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Animated Loading Indicator
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                        strokeWidth: 6,
                        backgroundColor: colorScheme.onPrimary.withValues(alpha: .3),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Enhanced Typography
                    Text(
                      'Getting Ready...',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                        shadows: [
                          Shadow(
                            color: colorScheme.shadow.withValues(alpha: .5),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please wait a moment',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimary.withValues(alpha: .8),
                            fontSize: 18,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundEffect(ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(seconds: 3),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            colorScheme.primary.withValues(alpha: .2),
            colorScheme.primaryContainer.withValues(alpha: .1),
          ],
        ),
      ),
    );
  }
}
