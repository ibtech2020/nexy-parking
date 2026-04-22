import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../game/level_data.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  int _selectedLevel = 0;

  // Mock data — replace with Firebase Firestore
  final List<_ScoreEntry> _global = [
    _ScoreEntry('APEX_DRIVER', 1, 9850, 3, 18),
    _ScoreEntry('PARKMASTER_X', 2, 9400, 3, 21),
    _ScoreEntry('NEON_KING', 3, 8900, 2, 19),
    _ScoreEntry('DRIFT_GOD', 4, 8400, 3, 24),
    _ScoreEntry('YOU', 5, 7200, 2, 27),
    _ScoreEntry('SPEED_DEMON', 6, 6800, 2, 30),
    _ScoreEntry('CAR_WIZARD', 7, 6200, 1, 35),
    _ScoreEntry('TURBO_BOY', 8, 5500, 1, 38),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
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
                  Text('LEADERBOARD',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(letterSpacing: 4)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TabBar(
                controller: _tabs,
                indicator: BoxDecoration(
                  color: AppTheme.neonCyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.neonCyan.withOpacity(0.4)),
                ),
                labelColor: AppTheme.neonCyan,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2),
                tabs: const [Tab(text: 'GLOBAL'), Tab(text: 'MY SCORES')],
              ),
            ),
            const SizedBox(height: 12),

            // Level filter
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: LevelRegistry.all.length,
                itemBuilder: (_, i) {
                  final sel = i == _selectedLevel;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLevel = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppTheme.neonOrange.withOpacity(0.15)
                            : Colors.transparent,
                        border: Border.all(
                          color: sel
                              ? AppTheme.neonOrange
                              : Colors.white.withOpacity(0.12),
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text('LV ${i + 1}',
                          style: TextStyle(
                              color: sel
                                  ? AppTheme.neonOrange
                                  : AppTheme.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Podium top 3
            _buildPodium(),
            const SizedBox(height: 8),

            // Full list
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildList(_global),
                  _buildList(_global.where((e) => e.name == 'YOU').toList()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium() {
    if (_global.length < 3) return const SizedBox();
    final top = _global.take(3).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _podiumCard(top[1], 2, 80),
          const SizedBox(width: 8),
          _podiumCard(top[0], 1, 100),
          const SizedBox(width: 8),
          _podiumCard(top[2], 3, 64),
        ],
      ),
    );
  }

  Widget _podiumCard(_ScoreEntry e, int rank, double height) {
    final colors = [
        AppTheme.neonOrange, // gold
        Colors.grey, // silver
        const Color(0xFFCD7F32), // bronze
    ];
    final c = colors[rank - 1];
    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          border: Border.all(color: c.withOpacity(0.4)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$rank', style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w700)),
            Text(e.name,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 9, letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis),
            Text('${e.score}',
                style: TextStyle(
                    color: c, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<_ScoreEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Text('No scores yet',
            style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final isMe = e.name == 'YOU';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.neonCyan.withOpacity(0.08)
                : AppTheme.darkCard,
            border: Border.all(
              color: isMe
                  ? AppTheme.neonCyan.withOpacity(0.4)
                  : Colors.white.withOpacity(0.06),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text('${e.rank}',
                    style: TextStyle(
                        color: e.rank <= 3
                            ? AppTheme.neonOrange
                            : AppTheme.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
              Expanded(
                child: Text(e.name,
                    style: TextStyle(
                        color: isMe
                            ? AppTheme.neonCyan
                            : AppTheme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              Row(
                children: List.generate(3, (si) => Icon(
                  si < e.stars
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: si < e.stars
                      ? AppTheme.neonOrange
                      : Colors.white12,
                  size: 13,
                )),
              ),
              const SizedBox(width: 12),
              Text('${e.time}s',
                  style: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12)),
              const SizedBox(width: 12),
              Text('${e.score}',
                  style: const TextStyle(
                      color: AppTheme.neonCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreEntry {
  final String name;
  final int rank, score, stars, time;
  _ScoreEntry(this.name, this.rank, this.score, this.stars, this.time);
}
