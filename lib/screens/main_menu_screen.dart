import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../audio/audio_service.dart';
import '../core/app_theme.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _titleCtrl;
  final AudioService _audio = AudioService();

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _titleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _audio.init().then((_) => _audio.startMenuMusic());
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _titleCtrl.dispose();
    _audio.stopMusic();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background grid
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              painter: _GridPainter(t: _bgCtrl.value),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Title
                AnimatedBuilder(
                  animation: _titleCtrl,
                  builder: (_, __) => Opacity(
                    opacity: _titleCtrl.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _titleCtrl.value)),
                      child: Column(
                        children: [
                          Text(
                            'NEXY',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 64,
                              letterSpacing: 16,
                              shadows: [
                                const Shadow(
                                  color: AppTheme.neonCyan,
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'PARKING',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 40,
                              color: AppTheme.neonOrange,
                              letterSpacing: 22,
                              shadows: [
                                const Shadow(
                                  color: AppTheme.neonOrange,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'NEXY PARKING SIMULATOR',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 3, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // Menu buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: Column(
                    children: [
                      _menuBtn(context, 'PLAY', Icons.play_arrow_rounded, AppTheme.neonCyan,
                          () => context.go('/levels')),
                      const SizedBox(height: 14),
                      _menuBtn(context, 'GARAGE', Icons.directions_car_rounded,
                          AppTheme.neonOrange, () => context.go('/garage')),
                      const SizedBox(height: 14),
                      _menuBtn(context, 'LEADERBOARD', Icons.leaderboard_rounded,
                          Colors.white54, () => context.go('/leaderboard')),
                      const SizedBox(height: 14),
                      _menuBtn(context, 'SETTINGS', Icons.settings_rounded, Colors.white38,
                          () => context.go('/settings')),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'v1.0.0  •  NEXY PARKING',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuBtn(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final double t;
  _GridPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent1.withOpacity(0.05)
      ..strokeWidth = 0.5;

    final offset = t * 40;
    for (double x = -40 + offset % 40; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = -40 + offset % 40; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Colorful glowing dots
    final colors = [
      AppTheme.accent1, AppTheme.accent2, AppTheme.accent3,
      AppTheme.secondary, AppTheme.primary,
    ];
    int ci = 0;
    for (double x = -40 + offset % 40; x < size.width; x += 40) {
      for (double y = -40 + offset % 40; y < size.height; y += 40) {
        final dotPaint = Paint()..color = colors[ci % colors.length].withOpacity(0.15);
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
        ci++;
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.t != t;
}
