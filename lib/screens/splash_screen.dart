// ===================== splash_screen.dart =====================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) context.go('/menu');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                  color: AppTheme.neonCyan.withOpacity(0.08),
                ),
                child: const Icon(Icons.directions_car_rounded, color: AppTheme.neonCyan, size: 40),
              ),
              const SizedBox(height: 20),
              const Text('NEXY PARKING',
                style: TextStyle(
                  color: AppTheme.neonCyan, fontSize: 22,
                  fontWeight: FontWeight.w700, letterSpacing: 8)),
              const SizedBox(height: 8),
              const Text('LOADING...',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 10, letterSpacing: 3)),
            ],
          ),
        ),
      ),
    );
  }
}
