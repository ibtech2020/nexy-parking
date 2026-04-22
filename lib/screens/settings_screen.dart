import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _hapticEnabled = true;
  bool _tiltControls = false;
  double _sfxVolume = 0.8;
  double _musicVolume = 0.5;
  int _graphicsQuality = 1; // 0=low, 1=mid, 2=high
  bool _showFps = false;

  @override
  Widget build(BuildContext context) {
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
                  Text('SETTINGS',
                      style: Theme.of(context)
                          .textTheme
                          .headlineLarge
                          ?.copyWith(letterSpacing: 6)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _section('AUDIO'),
                  _toggle('Sound Effects', _soundEnabled,
                      (v) => setState(() => _soundEnabled = v),
                      AppTheme.neonCyan),
                  _slider('SFX Volume', _sfxVolume,
                      (v) => setState(() => _sfxVolume = v),
                      AppTheme.neonCyan),
                  _toggle('Music', _musicEnabled,
                      (v) => setState(() => _musicEnabled = v),
                      AppTheme.neonOrange),
                  _slider('Music Volume', _musicVolume,
                      (v) => setState(() => _musicVolume = v),
                      AppTheme.neonOrange),
                  _toggle('Haptic Feedback', _hapticEnabled,
                      (v) => setState(() => _hapticEnabled = v),
                      AppTheme.neonCyan),

                  const SizedBox(height: 16),
                  _section('CONTROLS'),
                  _toggle('Tilt Steering (Gyroscope)', _tiltControls,
                      (v) => setState(() => _tiltControls = v),
                      AppTheme.neonOrange),

                  const SizedBox(height: 16),
                  _section('GRAPHICS'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text('Quality',
                              style: TextStyle(
                                  color: AppTheme.textPrimary, fontSize: 14)),
                        ),
                        _qualityBtn('LOW', 0),
                        const SizedBox(width: 8),
                        _qualityBtn('MED', 1),
                        const SizedBox(width: 8),
                        _qualityBtn('HIGH', 2),
                      ],
                    ),
                  ),
                  _toggle('Show FPS', _showFps,
                      (v) => setState(() => _showFps = v),
                      AppTheme.textSecondary),

                  const SizedBox(height: 24),
                  _section('ACCOUNT'),
                  _actionRow('Reset Progress', Icons.refresh_rounded,
                      AppTheme.neonRed, () {}),
                  _actionRow('Privacy Policy', Icons.privacy_tip_outlined,
                      AppTheme.textSecondary, () {}),
                  _actionRow('Version 1.0.0', Icons.info_outline_rounded,
                      AppTheme.textMuted, null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                color: AppTheme.neonCyan,
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w700)),
      );

  Widget _toggle(String label, bool val, Function(bool) onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
          Switch(
            value: val,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.darkBorder,
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double val, Function(double) onChanged, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: AppTheme.darkBorder,
                thumbColor: color,
                overlayColor: color.withOpacity(0.2),
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(value: val, onChanged: onChanged),
            ),
          ),
          Text('${(val * 100).toInt()}%',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _qualityBtn(String label, int level) {
    final active = _graphicsQuality == level;
    return GestureDetector(
      onTap: () => setState(() => _graphicsQuality = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.neonCyan.withOpacity(0.15)
              : Colors.transparent,
          border: Border.all(
            color: active
                ? AppTheme.neonCyan
                : Colors.white.withOpacity(0.15),
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? AppTheme.neonCyan : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
      ),
    );
  }

  Widget _actionRow(
      String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(color: color, fontSize: 14)),
            const Spacer(),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
