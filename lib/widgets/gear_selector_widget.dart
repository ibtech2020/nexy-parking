// gear_selector_widget.dart
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../game/car_physics.dart';

class GearSelectorWidget extends StatelessWidget {
  final GearState current;
  final Function(GearState) onChanged;
  final bool compact;

  const GearSelectorWidget({
    super.key,
    required this.current,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnW = compact ? 34.0 : 44.0;
    final btnH = compact ? 28.0 : 36.0;
    final fontSize = compact ? 11.0 : 13.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6, vertical: compact ? 4 : 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _gearBtn('P', GearState.park, Colors.white60, btnW, btnH, fontSize),
          SizedBox(width: compact ? 4 : 6),
          _gearBtn('R', GearState.reverse, AppTheme.neonRed, btnW, btnH, fontSize),
          SizedBox(width: compact ? 4 : 6),
          _gearBtn('N', GearState.neutral, Colors.white38, btnW, btnH, fontSize),
          SizedBox(width: compact ? 4 : 6),
          _gearBtn('D', GearState.drive, AppTheme.neonCyan, btnW, btnH, fontSize),
        ],
      ),
    );
  }

  Widget _gearBtn(String label, GearState gear, Color color, double w, double h, double fs) {
    final active = current == gear;
    return GestureDetector(
      onTap: () => onChanged(gear),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: w,
        height: h,
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
              fontSize: fs,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
