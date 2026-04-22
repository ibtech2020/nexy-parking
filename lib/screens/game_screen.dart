import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flame/game.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';

import '../game/park_master_game.dart';
import '../game/car_physics.dart';
import '../core/app_theme.dart';
import '../widgets/steering_wheel_widget.dart';
import '../widgets/pedal_widget.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/gear_selector_widget.dart';
import '../widgets/result_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  final int levelId;
  const GameScreen({super.key, required this.levelId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with TickerProviderStateMixin {
  late ParkMasterGame _game;
  CarPhysics? _carState;
  GameStatus _status = GameStatus.playing;
  double _elapsedTime = 0;
  int _hitCount = 0;
  bool _paused = false;
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _keysHeld = {};

  late AnimationController _damageFlashCtrl;
  late Animation<double> _damageFlash;
  late AnimationController _parkFlashCtrl;
  late Animation<double> _parkFlash;

  @override
  void initState() {
    super.initState();
    _damageFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _damageFlash =
        CurvedAnimation(parent: _damageFlashCtrl, curve: Curves.easeOut);
    _parkFlashCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _parkFlash =
        CurvedAnimation(parent: _parkFlashCtrl, curve: Curves.easeOut);
    _game = _buildGame();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  ParkMasterGame _buildGame() {
    final game = ParkMasterGame(levelId: widget.levelId);
    game.onStatusChange = (status) {
      if (!mounted) return;
      scheduleMicrotask(() {
        if (!mounted) return;
        setState(() => _status = status);
        if (status == GameStatus.parked) {
          _parkFlashCtrl.forward(from: 0);
          Vibration.vibrate(pattern: [0, 100, 50, 200], amplitude: 255);
        } else if (status == GameStatus.playing) {
          _damageFlashCtrl.forward(from: 0);
          Vibration.vibrate(duration: 80, amplitude: 128);
        }
      });
    };
    game.onCarStateUpdate = (state) {
      if (!mounted) return;
      scheduleMicrotask(() {
        if (!mounted) return;
        setState(() => _carState = state);
      });
    };
    game.onScoreUpdate = (time, hits) {
      if (!mounted) return;
      scheduleMicrotask(() {
        if (!mounted) return;
        setState(() {
          _elapsedTime = time;
          _hitCount = hits;
        });
      });
    };
    return game;
  }

  void _restart() {
    _keysHeld.clear();
    setState(() {
      _status = GameStatus.playing;
      _paused = false;
      _elapsedTime = 0;
      _hitCount = 0;
      _game = _buildGame();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) _keysHeld.add(event.logicalKey);
    if (event is KeyUpEvent) _keysHeld.remove(event.logicalKey);

    _game.setThrottle(
      (_keysHeld.contains(LogicalKeyboardKey.arrowUp) ||
              _keysHeld.contains(LogicalKeyboardKey.keyW))
          ? 1.0
          : 0.0,
    );
    _game.setBrake(
      (_keysHeld.contains(LogicalKeyboardKey.arrowDown) ||
              _keysHeld.contains(LogicalKeyboardKey.keyS))
          ? 1.0
          : 0.0,
    );
    if (_keysHeld.contains(LogicalKeyboardKey.arrowLeft) ||
        _keysHeld.contains(LogicalKeyboardKey.keyA)) {
      _game.setSteer(-1.0);
    } else if (_keysHeld.contains(LogicalKeyboardKey.arrowRight) ||
        _keysHeld.contains(LogicalKeyboardKey.keyD)) {
      _game.setSteer(1.0);
    } else {
      _game.setSteer(0.0);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _damageFlashCtrl.dispose();
    _parkFlashCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameReady = _game.isLoaded;
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        _handleKey(event);
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GameWidget(game: _game),

            AnimatedBuilder(
              animation: _damageFlash,
              builder: (_, __) => IgnorePointer(
                child: Container(
                  color: Colors.red.withOpacity(0.18 * (1 - _damageFlash.value)),
                ),
              ),
            ),

            AnimatedBuilder(
              animation: _parkFlash,
              builder: (_, __) => IgnorePointer(
                child: Container(
                  color: AppTheme.neonCyan.withOpacity(0.08 * (1 - _parkFlash.value)),
                ),
              ),
            ),

            if (gameReady &&
                (_status == GameStatus.playing || _status == GameStatus.paused))
              HudOverlay(
                levelId: widget.levelId,
                carState: _carState,
                elapsedTime: _elapsedTime,
                hitCount: _hitCount,
                timeLimit: _game.level.timeLimit,
                cameraMode: _game.cameraMode,
                onCameraToggle: () => setState(() => _game.cycleCameraMode()),
                onPause: _handlePause,
              ),

            if (_status == GameStatus.playing) _buildControls(),

            if (_status == GameStatus.playing)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: GearSelectorWidget(
                    current: _game.selectedGear,
                    onChanged: (g) {
                      setState(() => _game.setGear(g));
                      Vibration.vibrate(duration: 30, amplitude: 60);
                    },
                  ),
                ),
              ),

            if (_paused) _buildPauseMenu(),

            if (_status == GameStatus.parked || _status == GameStatus.timeOut)
              ResultOverlay(
                success: _status == GameStatus.parked,
                stars: _game.calculateStars(),
                score: _game.calculateScore(),
                time: _elapsedTime,
                hits: _hitCount,
                onRetry: _restart,
                onNext: () => context.go('/levels'),
                onMenu: () => context.go('/menu'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Stack(
      children: [
        Positioned(
          bottom: 30,
          left: 20,
          child: SteeringWheelWidget(onSteer: (v) => _game.setSteer(v)),
        ),
        Positioned(
          bottom: 30,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PedalWidget(
                label: 'GAS',
                icon: Icons.arrow_upward_rounded,
                color: AppTheme.neonCyan,
                onChanged: (v) => _game.setThrottle(v),
              ),
              const SizedBox(height: 10),
              PedalWidget(
                label: 'BRAKE',
                icon: Icons.arrow_downward_rounded,
                color: AppTheme.neonRed,
                onChanged: (v) => _game.setBrake(v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handlePause() {
    setState(() {
      _paused = !_paused;
      _paused ? _game.pause() : _game.resume();
    });
  }

  Widget _buildPauseMenu() {
    return Container(
      color: Colors.black.withOpacity(0.75),
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            border: Border.all(color: AppTheme.neonCyan.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('PAUSED',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 24, letterSpacing: 6)),
              const SizedBox(height: 24),
              _pauseBtn('RESUME', AppTheme.neonCyan, _handlePause),
              const SizedBox(height: 10),
              _pauseBtn('RESTART', AppTheme.neonOrange, _restart),
              const SizedBox(height: 10),
              _pauseBtn('QUIT', AppTheme.neonRed, () => context.go('/menu')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13, letterSpacing: 2, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
