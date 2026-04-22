import 'package:flutter/material.dart';

class PedalWidget extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Function(double value) onChanged;

  const PedalWidget({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  State<PedalWidget> createState() => _PedalWidgetState();
}

class _PedalWidgetState extends State<PedalWidget> {
  bool _pressed = false;

  void _start() {
    setState(() => _pressed = true);
    widget.onChanged(1.0);
  }

  void _end() {
    setState(() => _pressed = false);
    widget.onChanged(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final isGas = widget.label == 'GAS';
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _end(),
      onTapCancel: _end,
      onPanStart: (_) => _start(),
      onPanEnd: (_) => _end(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        width: 110,
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _pressed
                ? [widget.color, widget.color.withOpacity(0.7)]
                : [widget.color.withOpacity(0.85), widget.color.withOpacity(0.5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _pressed ? Colors.white : widget.color,
            width: _pressed ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_pressed ? 0.8 : 0.4),
              blurRadius: _pressed ? 24 : 10,
              spreadRadius: _pressed ? 4 : 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isGas ? '🚀' : '🛑',
              style: TextStyle(fontSize: _pressed ? 28 : 24),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
