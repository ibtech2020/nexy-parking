// gear_selector_widget.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../game/car_physics.dart';

class GearSelectorWidget extends StatelessWidget {
  final GearState current;
  final Function(GearState) onChanged;

  const GearSelectorWidget({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gearBtn('P', GearState.park, Colors.white60),
          const SizedBox(width: 6),
          _gearBtn('R', GearState.reverse, AppTheme.neonRed),
          const SizedBox(width: 6),
          _gearBtn('N', GearState.neutral, Colors.white38),
          const SizedBox(width: 6),
          _gearBtn('D', GearState.drive, AppTheme.neonCyan),
        ],
      ),
    );
  }

  Widget _gearBtn(String label, GearState gear, Color color) {
    final active = current == gear;
    return GestureDetector(
      onTap: () => onChanged(gear),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 44,
        height: 36,
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : Colors.transparent,
          border: Border.all(
            color: active ? color : Colors.white.withOpacity(0.12),
            width: active ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(7),
          boxShadow: active
              ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: active ? color : Colors.white30,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
