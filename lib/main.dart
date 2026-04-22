import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_theme.dart';
import 'core/app_router.dart';
import 'models/player_progress.dart';
import 'models/car_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to landscape for best driving experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Full immersive mode
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Init Hive for local persistence
  await Hive.initFlutter();
  Hive.registerAdapter(PlayerProgressAdapter());
  Hive.registerAdapter(CarConfigAdapter());
  await Hive.openBox<PlayerProgress>('progress');
  await Hive.openBox<CarConfig>('garage');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: ParkMasterApp()));
}

class ParkMasterApp extends ConsumerWidget {
  const ParkMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'NexyParking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
