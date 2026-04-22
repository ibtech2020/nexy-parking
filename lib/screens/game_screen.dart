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
import '../audio/audio_service.dart';
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
  final AudioService _audio = AudioService();

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
    _audio.init().then((_) {
      _audio.startGameMusic();
      _audio.startEngine();
    });
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
          _audio.playParkSuccess();
          Vibration.vibrate(pattern: [0, 100, 50, 200], amplitude: 255);
        } else if (status == GameStatus.playing) {
          _damageFlashCtrl.forward(from: 0);
          _audio.playCollision(10);
          Vibration.vibrate(duration: 80, amplitude: 128);
        }
      });
    };
    game.onCarStateUpdate = (state) {
      if (!mounted) return;
      scheduleMicrotask(() {
        if (!mounted) return;
        setState(() => _carState = state);
        _audio.updateEngineRpm(state.rpm, state.spec.maxRpm);
        if (state.isSkidding) _audio.playSkid();
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
    _audio.stopEngine();
    _audio.stopMusic();
    _audio.dispose();
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
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final isMobile = screenW < 600;
    final wheelSize = isMobile ? 100.0 : 130.0;
    final pedalW = isMobile ? 72.0 : 100.0;
    final pedalH = isMobile ? 52.0 : 72.0;
    final bottomPad = isMobile ? 12.0 : 24.0;

    return Stack(
      children: [
        // ---- LEFT: Steering wheel ----
        Positioned(
          bottom: bottomPad,
          left: 10,
          child: SizedBox(
            width: wheelSize,
            height: wheelSize,
            child: SteeringWheelWidget(onSteer: (v) => _game.setSteer(v)),
          ),
        ),

        // ---- CENTER-LEFT: Gear selector (above steering on mobile) ----
        Positioned(
          bottom: bottomPad + wheelSize + 6,
          left: 10,
          child: GearSelectorWidget(
            compact: isMobile,
            current: _game.selectedGear,
            onChanged: (g) {
              setState(() => _game.setGear(g));
              _audio.playGearShift();
              Vibration.vibrate(duration: 30, amplitude: 60);
            },
          ),
        ),

        // ---- RIGHT: Gas + Brake ----
        Positioned(
          bottom: bottomPad,
          right: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pedalBtn('GAS', '🚀', AppTheme.neonCyan, pedalW, pedalH,
                  (v) => _game.setThrottle(v)),
              const SizedBox(height: 8),
              _pedalBtn('BRAKE', '🛑', AppTheme.neonRed, pedalW, pedalH,
                  (v) => _game.setBrake(v)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pedalBtn(String label, String emoji, Color color, double w, double h,
      Function(double) onChanged) {
    return _PedalButton(
      label: label,
      emoji: emoji,
      color: color,
      width: w,
      height: h,
      onChanged: onChanged,
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

// ---- Inline pedal button ----
class _PedalButton extends StatefulWidget {
  final String label;
  final String emoji;
  final Color color;
  final double width;
  final double height;
  final Function(double) onChanged;

  const _PedalButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  @override
  State<_PedalButton> createState() => _PedalButtonState();
}

class _PedalButtonState extends State<_PedalButton> {
  bool _pressed = false;

  void _start() { setState(() => _pressed = true); widget.onChanged(1.0); }
  void _end()   { setState(() => _pressed = false); widget.onChanged(0.0); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _end(),
      onTapCancel: _end,
      onPanStart: (_) => _start(),
      onPanEnd: (_) => _end(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed
                ? [widget.color, widget.color.withOpacity(0.7)]
                : [widget.color.withOpacity(0.85), widget.color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _pressed ? Colors.white : widget.color,
            width: _pressed ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_pressed ? 0.7 : 0.3),
              blurRadius: _pressed ? 18 : 6,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.emoji, style: TextStyle(fontSize: _pressed ? 20 : 17)),
            Text(widget.label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}
