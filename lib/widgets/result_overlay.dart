import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_theme.dart';

class ResultOverlay extends StatelessWidget {
  final bool success;
  final int stars;
  final int score;
  final double time;
  final int hits;
  final VoidCallback onRetry;
  final VoidCallback onNext;
  final VoidCallback onMenu;

  const ResultOverlay({
    super.key,
    required this.success,
    required this.stars,
    required this.score,
    required this.time,
    required this.hits,
    required this.onRetry,
    required this.onNext,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Center(
        child: Container(
          width: 340,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            border: Border.all(
              color: success
                  ? AppTheme.neonCyan.withOpacity(0.4)
                  : AppTheme.neonRed.withOpacity(0.4),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                success ? 'PARKED!' : 'TIME OUT',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: success ? AppTheme.neonCyan : AppTheme.neonRed,
                  letterSpacing: 6,
                  shadows: [
                    Shadow(
                      color: (success ? AppTheme.neonCyan : AppTheme.neonRed).withOpacity(0.5),
                      blurRadius: 20,
                    )
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3),

              const SizedBox(height: 16),

              // Stars
              if (success)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    final filled = i < stars;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: filled ? AppTheme.neonOrange : Colors.white12,
                        size: 36,
                      )
                          .animate(delay: Duration(milliseconds: 200 + i * 150))
                          .scale(begin: const Offset(0, 0), curve: Curves.elasticOut),
                    );
                  }),
                ),

              const SizedBox(height: 20),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _statBox('${time.toInt()}s', 'TIME'),
                  _statBox('$hits', 'HITS'),
                  _statBox('$score', 'POINTS'),
                ],
              ).animate(delay: 300.ms).fadeIn(),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: _btn('RETRY', AppTheme.neonOrange, onRetry),
                  ),
                  const SizedBox(width: 10),
                  if (success)
                    Expanded(
                      child: _btn('NEXT', AppTheme.neonCyan, onNext),
                    ),
                  if (!success)
                    Expanded(
                      child: _btn('MENU', Colors.white54, onMenu),
                    ),
                ],
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, color: AppTheme.neonOrange, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 9, color: AppTheme.textMuted, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
        ),
      ),
    );
  }
}
