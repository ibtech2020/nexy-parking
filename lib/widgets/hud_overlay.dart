import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../game/car_physics.dart';
import '../game/park_master_game.dart';

class HudOverlay extends StatelessWidget {
  final int levelId;
  final CarPhysics? carState;
  final double elapsedTime;
  final int hitCount;
  final double timeLimit;
  final CameraMode cameraMode;
  final VoidCallback onCameraToggle;
  final VoidCallback onPause;

  const HudOverlay({
    super.key,
    required this.levelId,
    required this.carState,
    required this.elapsedTime,
    required this.hitCount,
    required this.timeLimit,
    required this.cameraMode,
    required this.onCameraToggle,
    required this.onPause,
  });

  @override
  Widget build(BuildContext context) {
    final timeLeft = (timeLimit - elapsedTime).clamp(0.0, timeLimit);
    final timeRatio = timeLeft / timeLimit;
    final speed = carState?.speed.abs().toInt() ?? 0;
    final rpm = carState?.rpm.toInt() ?? 800;

    return Stack(
      children: [
        // ---- TIME BAR ----
        Positioned(
          top: 0, left: 0, right: 0,
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: timeRatio,
              backgroundColor: AppTheme.darkBorder,
              valueColor: AlwaysStoppedAnimation(
                timeRatio > 0.5
                    ? AppTheme.neonCyan
                    : timeRatio > 0.25
                        ? AppTheme.neonOrange
                        : AppTheme.neonRed,
              ),
            ),
          ),
        ),

        // ---- TOP LEFT: level + hits ----
        Positioned(
          top: 12, left: 14,
          child: Row(
            children: [
              _pill('LEVEL ${levelId + 1}', AppTheme.neonCyan),
              const SizedBox(width: 8),
              _pill('✕ $hitCount HITS', AppTheme.neonOrange),
            ],
          ),
        ),

        // ---- TOP RIGHT: camera + pause ----
        Positioned(
          top: 12, right: 14,
          child: Row(
            children: [
              _iconBtn(
                Icons.camera_alt_outlined,
                _camLabel(cameraMode),
                AppTheme.neonCyan,
                onCameraToggle,
              ),
              const SizedBox(width: 8),
              _iconBtn(Icons.pause_rounded, 'PAUSE', Colors.white70, onPause),
            ],
          ),
        ),

        // ---- TIMER ----
        Positioned(
          top: 14, left: 0, right: 0,
          child: Center(
            child: _pill(
              _formatTime(timeLeft),
              timeRatio > 0.25 ? Colors.white70 : AppTheme.neonRed,
            ),
          ),
        ),

        // ---- SPEEDOMETER + RPM ----
        Positioned(
          bottom: 140, left: 0, right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _gauge(speed.toString(), 'KM/H', AppTheme.neonCyan),
                const SizedBox(width: 20),
                _gearBadge(carState?.gear),
                const SizedBox(width: 20),
                _gauge('${(rpm / 100).round()}', 'RPM×100', AppTheme.neonOrange),
              ],
            ),
          ),
        ),

        // ---- RPM BAR ----
        Positioned(
          bottom: 132, left: 60, right: 60,
          child: _rpmBar(rpm, carState?.spec.maxRpm ?? 6500),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border.all(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
    );
  }

  Widget _iconBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _gauge(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: color.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w700, height: 1)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textMuted, fontSize: 9, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _gearBadge(GearState? gear) {
    final label = {
      GearState.park: 'P',
      GearState.reverse: 'R',
      GearState.neutral: 'N',
      GearState.drive: 'D',
    }[gear] ?? 'D';
    return Text(label,
        style: const TextStyle(
          color: AppTheme.neonOrange,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: AppTheme.neonOrange, blurRadius: 12)],
        ));
  }

  Widget _rpmBar(int rpm, double maxRpm) {
    final ratio = (rpm / maxRpm).clamp(0.0, 1.0);
    Color barColor = AppTheme.neonCyan;
    if (ratio > 0.75) barColor = AppTheme.neonOrange;
    if (ratio > 0.9) barColor = AppTheme.neonRed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 3,
        backgroundColor: Colors.white.withOpacity(0.06),
        valueColor: AlwaysStoppedAnimation(barColor),
      ),
    );
  }

  String _formatTime(double t) {
    final m = (t / 60).floor();
    final s = (t % 60).floor();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _camLabel(CameraMode mode) {
    switch (mode) {
      case CameraMode.follow: return 'FOLLOW';
      case CameraMode.topDown: return 'TOP';
      case CameraMode.driver: return 'DRIVER';
    }
  }
}
