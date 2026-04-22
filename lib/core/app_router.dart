import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/level_select_screen.dart';
import '../screens/garage_screen.dart';
import '../screens/game_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/leaderboard_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/menu', builder: (_, __) => const MainMenuScreen()),
      GoRoute(path: '/levels', builder: (_, __) => const LevelSelectScreen()),
      GoRoute(path: '/garage', builder: (_, __) => const GarageScreen()),
      GoRoute(
        path: '/game/:levelId',
        builder: (_, state) => GameScreen(
          levelId: int.parse(state.pathParameters['levelId']!),
        ),
      ),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
    ],
  );
}
