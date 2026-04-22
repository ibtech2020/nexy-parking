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
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600;

    return Stack(
      children: [
        // ---- TIME BAR (top) ----
        Positioned(
          top: 0, left: 0, right: 0,
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: timeRatio,
              backgroundColor: AppTheme.darkBorder,
              valueColor: AlwaysStoppedAnimation(
                timeRatio > 0.5 ? AppTheme.neonCyan
                    : timeRatio > 0.25 ? AppTheme.neonOrange
                    : AppTheme.neonRed,
              ),
            ),
          ),
        ),

        // ---- TOP LEFT: level + hits ----
        Positioned(
          top: 10, left: 10,
          child: Row(
            children: [
              _pill('LV ${levelId + 1}', AppTheme.neonCyan, isMobile),
              const SizedBox(width: 6),
              _pill('✕$hitCount', AppTheme.neonOrange, isMobile),
            ],
          ),
        ),

        // ---- TOP CENTER: timer ----
        Positioned(
          top: 10, left: 0, right: 0,
          child: Center(
            child: _pill(
              _formatTime(timeLeft),
              timeRatio > 0.25 ? Colors.white70 : AppTheme.neonRed,
              isMobile,
            ),
          ),
        ),

        // ---- TOP RIGHT: camera + pause ----
        Positioned(
          top: 10, right: 10,
          child: Row(
            children: [
              if (!isMobile) ...[
                _iconBtn(Icons.camera_alt_outlined, _camLabel(cameraMode),
                    AppTheme.neonCyan, onCameraToggle),
                const SizedBox(width: 6),
              ],
              _iconBtn(Icons.pause_rounded, 'PAUSE', Colors.white70, onPause),
            ],
          ),
        ),

        // ---- BOTTOM LEFT: compact gauges (KM/H | GEAR | RPM) ----
        Positioned(
          bottom: isMobile ? 170 : 150,
          left: isMobile ? 10 : 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _compactGauge(speed.toString(), 'KM/H', AppTheme.neonCyan, isMobile),
                _divider(),
                _compactGear(carState?.gear),
                _divider(),
                _compactGauge('${(rpm / 100).round()}', 'RPM', AppTheme.neonOrange, isMobile),
              ],
            ),
          ),
        ),

        // ---- RPM bar under gauges ----
        Positioned(
          bottom: isMobile ? 164 : 144,
          left: isMobile ? 10 : 16,
          width: 120,
          child: _rpmBar(rpm, carState?.spec.maxRpm ?? 6500),
        ),
      ],
    );
  }

  Widget _pill(String text, Color color, bool small) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 4 : 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }

  Widget _iconBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _compactGauge(String value, String label, Color color, bool small) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: small ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  height: 1.1)),
          Text(label,
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: small ? 7 : 8,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _compactGear(GearState? gear) {
    final label = {
      GearState.park: 'P',
      GearState.reverse: 'R',
      GearState.neutral: 'N',
      GearState.drive: 'D',
    }[gear] ?? 'D';
    final color = {
      GearState.park: Colors.white60,
      GearState.reverse: AppTheme.neonRed,
      GearState.neutral: Colors.white38,
      GearState.drive: AppTheme.neonCyan,
    }[gear] ?? AppTheme.neonCyan;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: color, blurRadius: 8)])),
    );
  }

  Widget _divider() => Container(
        width: 1, height: 28,
        color: Colors.white.withOpacity(0.1),
      );

  Widget _rpmBar(int rpm, double maxRpm) {
    final ratio = (rpm / maxRpm).clamp(0.0, 1.0);
    Color c = AppTheme.neonCyan;
    if (ratio > 0.75) c = AppTheme.neonOrange;
    if (ratio > 0.9) c = AppTheme.neonRed;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 3,
        backgroundColor: Colors.white.withOpacity(0.06),
        valueColor: AlwaysStoppedAnimation(c),
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
      case CameraMode.follow: return 'CAM';
      case CameraMode.topDown: return 'TOP';
      case CameraMode.driver: return 'DRV';
    }
  }
}
