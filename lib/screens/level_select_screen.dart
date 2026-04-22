import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../game/level_data.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  // Simulated unlock state — replace with Hive persistence
  final Set<int> _unlocked = {0, 1, 2};
  final Map<int, int> _stars = {0: 3, 1: 2, 2: 1};

  @override
  Widget build(BuildContext context) {
    final levels = LevelRegistry.all;
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/menu'),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: AppTheme.neonCyan, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SELECT LEVEL',
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(letterSpacing: 4)),
                      Text('${_unlocked.length} / ${levels.length} UNLOCKED',
                          style: Theme.of(context).textTheme.labelSmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Difficulty legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _diffDot(AppTheme.neonCyan, 'EASY'),
                  const SizedBox(width: 16),
                  _diffDot(AppTheme.neonOrange, 'MEDIUM'),
                  const SizedBox(width: 16),
                  _diffDot(AppTheme.neonRed, 'HARD'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Level grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: levels.length,
                itemBuilder: (context, i) {
                  final lv = levels[i];
                  final unlocked = _unlocked.contains(i);
                  final stars = _stars[i] ?? 0;
                  return _LevelCard(
                    level: lv,
                    unlocked: unlocked,
                    stars: stars,
                    onTap: unlocked ? () => context.go('/game/$i') : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _diffDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color.withOpacity(0.7), fontSize: 9, letterSpacing: 1.5)),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final LevelData level;
  final bool unlocked;
  final int stars;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    this.onTap,
  });

  Color get _diffColor {
    if (level.difficulty <= 2) return AppTheme.neonCyan;
    if (level.difficulty <= 3) return AppTheme.neonOrange;
    return AppTheme.neonRed;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: unlocked ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            border: Border.all(
              color: unlocked
                  ? _diffColor.withOpacity(0.3)
                  : Colors.white.withOpacity(0.08),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Level number
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _diffColor.withOpacity(0.1),
                  border: Border.all(color: _diffColor.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    '${level.id + 1}',
                    style: TextStyle(
                        color: _diffColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Name
              Text(
                level.name,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Difficulty dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < level.difficulty
                        ? _diffColor
                        : Colors.white.withOpacity(0.1),
                  ),
                )),
              ),
              const SizedBox(height: 6),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < stars
                      ? AppTheme.neonOrange
                      : Colors.white.withOpacity(0.15),
                  size: 14,
                )),
              ),

              if (!unlocked) ...[
                const SizedBox(height: 6),
                Icon(Icons.lock_outline_rounded,
                    color: Colors.white.withOpacity(0.3), size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
