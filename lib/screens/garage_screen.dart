import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/app_theme.dart';
import '../game/car_physics.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({super.key});
  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> with SingleTickerProviderStateMixin {
  int _selectedCar = 0;
  int _selectedColor = 0;
  int _playerCoins = 4200;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounce;

  final List<Color> _colors = [
    const Color(0xFFFF3333), // red
    const Color(0xFF3399FF), // blue
    const Color(0xFF33CC33), // green
    const Color(0xFFFFCC00), // yellow
    const Color(0xFFFF66CC), // pink
    const Color(0xFFCC44FF), // purple
    const Color(0xFFFF6600), // orange
    Colors.white,
  ];

  final List<CarSpec> _cars = CarSpecs.all;

  // Unlocked cars (0 = always unlocked)
  final Set<int> _unlocked = {0, 1};

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _bounce = Tween(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  bool _isUnlocked(int i) => _unlocked.contains(i) || _cars[i].unlockLevel == 0;

  void _tryUnlock(int i) {
    final car = _cars[i];
    if (_playerCoins >= car.price) {
      setState(() {
        _playerCoins -= car.price;
        _unlocked.add(i);
        _selectedCar = i;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Need ${car.price} coins to unlock ${car.name}!'),
          backgroundColor: AppTheme.neonRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final car = _cars[_selectedCar];
    final unlocked = _isUnlocked(_selectedCar);
    final carColor = _colors[_selectedColor];

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ---- HEADER ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/menu'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.secondary.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.secondary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('🚗 GARAGE',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            color: AppTheme.accent1,
                            letterSpacing: 4,
                            shadows: [Shadow(color: AppTheme.accent1.withOpacity(0.5), blurRadius: 12)],
                          )),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.neonOrange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.neonOrange.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text('$_playerCoins',
                            style: const TextStyle(
                                color: AppTheme.neonOrange, fontSize: 14, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ---- CAR PREVIEW ----
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      carColor.withOpacity(0.08),
                      AppTheme.darkCard,
                      carColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: carColor.withOpacity(0.4), width: 2),
                  boxShadow: [BoxShadow(color: carColor.withOpacity(0.15), blurRadius: 20)],
                ),
                child: Stack(
                  children: [
                    // Car name badge
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: carColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: carColor.withOpacity(0.6)),
                        ),
                        child: Text(
                          _carEmoji(car.id),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    // Lock overlay
                    if (!unlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🔒', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text('UNLOCK FOR ${car.price} 🪙',
                                  style: const TextStyle(
                                      color: AppTheme.accent1,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1)),
                            ],
                          ),
                        ),
                      ),
                    // Animated car
                    Center(
                      child: AnimatedBuilder(
                        animation: _bounce,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(0, _bounce.value),
                          child: CustomPaint(
                            size: const Size(140, 220),
                            painter: _CarIllustrationPainter(
                              color: carColor,
                              carId: car.id,
                              locked: !unlocked,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Stats overlay bottom
                    Positioned(
                      bottom: 12, left: 12, right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _miniStat('⚡', 'SPEED', car.maxSpeed / 220),
                          _miniStat('🎯', 'HANDLE', 1.0 - car.driftTendency),
                          _miniStat('🛑', 'BRAKE', car.maxBrakeForce / 12000),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ---- CAR GRID ----
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _cars.length,
                itemBuilder: (_, i) {
                  final c = _cars[i];
                  final sel = i == _selectedCar;
                  final locked = !_isUnlocked(i);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCar = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 88,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: sel
                            ? LinearGradient(colors: [
                                _colors[_selectedColor].withOpacity(0.3),
                                _colors[_selectedColor].withOpacity(0.1),
                              ])
                            : null,
                        color: sel ? null : AppTheme.darkCard,
                        border: Border.all(
                          color: sel ? _colors[_selectedColor] : Colors.white.withOpacity(0.12),
                          width: sel ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: sel
                            ? [BoxShadow(color: _colors[_selectedColor].withOpacity(0.3), blurRadius: 10)]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_carEmoji(c.id), style: TextStyle(fontSize: locked ? 18 : 22)),
                          if (locked) const Text('🔒', style: TextStyle(fontSize: 10)),
                          const SizedBox(height: 4),
                          Text(
                            c.name,
                            style: TextStyle(
                              color: sel ? Colors.white : AppTheme.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                          Text(
                            locked ? '${c.price}🪙' : 'LV${c.unlockLevel}',
                            style: TextStyle(
                              color: locked ? AppTheme.accent1 : AppTheme.textMuted,
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // ---- COLOR PICKER ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('🎨 COLOR  ',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, letterSpacing: 1)),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_colors.length, (i) {
                          final sel = i == _selectedColor;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: sel ? 34 : 28,
                              height: sel ? 34 : 28,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _colors[i],
                                border: Border.all(
                                  color: sel ? Colors.white : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: sel
                                    ? [BoxShadow(color: _colors[i].withOpacity(0.6), blurRadius: 10)]
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ---- ACTION BUTTON ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!unlocked) {
                      _tryUnlock(_selectedCar);
                    } else {
                      context.go('/levels');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unlocked ? AppTheme.accent2 : AppTheme.accent1,
                    foregroundColor: AppTheme.darkBg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 6,
                    shadowColor: (unlocked ? AppTheme.accent2 : AppTheme.accent1).withOpacity(0.5),
                  ),
                  child: Text(
                    unlocked ? '🏁  RACE WITH ${car.name}' : '🔓  UNLOCK FOR ${car.price} 🪙',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String label, double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 2),
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(
                value > 0.7 ? AppTheme.accent2 : value > 0.4 ? AppTheme.accent1 : AppTheme.neonRed,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 7, letterSpacing: 1)),
      ],
    );
  }

  String _carEmoji(String id) {
    switch (id) {
      case 'sedan':  return '🚗';
      case 'suv':    return '🚙';
      case 'sports': return '🏎️';
      case 'truck':  return '🛻';
      case 'muscle': return '💪🚗';
      case 'mini':   return '🐣🚗';
      case 'bus':    return '🚌';
      case 'police': return '🚓';
      default:       return '🚗';
    }
  }
}

// ---- Car Illustration Painter ----
class _CarIllustrationPainter extends CustomPainter {
  final Color color;
  final String carId;
  final bool locked;

  _CarIllustrationPainter({required this.color, required this.carId, required this.locked});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Dimensions vary by car type
    double w, h, roofH, roofW;
    switch (carId) {
      case 'bus':
        w = size.width * 0.75; h = size.height * 0.92; roofH = 0.55; roofW = 0.9;
        break;
      case 'truck':
        w = size.width * 0.70; h = size.height * 0.88; roofH = 0.35; roofW = 0.7;
        break;
      case 'suv':
        w = size.width * 0.65; h = size.height * 0.85; roofH = 0.45; roofW = 0.8;
        break;
      case 'mini':
        w = size.width * 0.50; h = size.height * 0.70; roofH = 0.50; roofW = 0.85;
        break;
      case 'sports':
        w = size.width * 0.60; h = size.height * 0.72; roofH = 0.30; roofW = 0.65;
        break;
      default:
        w = size.width * 0.58; h = size.height * 0.80; roofH = 0.40; roofW = 0.75;
    }

    final bodyColor = locked ? Colors.grey.shade700 : color;

    // Glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + h * 0.3), width: w * 1.4, height: h * 0.2),
      Paint()
        ..color = bodyColor.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 3, cy + 3), width: w, height: h),
        const Radius.circular(10),
      ),
      Paint()..color = Colors.black.withOpacity(0.35),
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        const Radius.circular(10),
      ),
      Paint()..color = bodyColor,
    );

    // Roof / cabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - h * 0.12),
          width: w * roofW,
          height: h * roofH,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = bodyColor.withOpacity(0.7),
    );

    // Windshield
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - h * 0.18),
          width: w * roofW * 0.75,
          height: h * roofH * 0.55,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF87CEEB).withOpacity(0.75),
    );

    // Stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy + h * 0.05), width: w - 8, height: 6),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withOpacity(0.25),
    );

    // Headlights
    canvas.drawCircle(Offset(cx - w / 2 + 8, cy - h / 2 + 6), 5,
        Paint()..color = const Color(0xFFFFFF88));
    canvas.drawCircle(Offset(cx + w / 2 - 8, cy - h / 2 + 6), 5,
        Paint()..color = const Color(0xFFFFFF88));

    // Taillights
    canvas.drawCircle(Offset(cx - w / 2 + 8, cy + h / 2 - 6), 5,
        Paint()..color = const Color(0xFFFF2222));
    canvas.drawCircle(Offset(cx + w / 2 - 8, cy + h / 2 - 6), 5,
        Paint()..color = const Color(0xFFFF2222));

    // Wheels
    _drawWheel(canvas, Offset(cx - w / 2 - 2, cy - h / 3), bodyColor);
    _drawWheel(canvas, Offset(cx + w / 2 - 10, cy - h / 3), bodyColor);
    _drawWheel(canvas, Offset(cx - w / 2 - 2, cy + h / 4), bodyColor);
    _drawWheel(canvas, Offset(cx + w / 2 - 10, cy + h / 4), bodyColor);

    // Outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
        const Radius.circular(10),
      ),
      Paint()
        ..color = locked ? Colors.grey.shade500 : Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Police lights
    if (carId == 'police') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - h / 2 - 5), width: w * 0.5, height: 8),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFF0044FF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + w * 0.12, cy - h / 2 - 5), width: w * 0.22, height: 8),
          const Radius.circular(4),
        ),
        Paint()..color = const Color(0xFFFF2222),
      );
    }

    // Bus windows
    if (carId == 'bus') {
      for (int i = 0; i < 3; i++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - w / 2 + 10 + i * (w / 3 - 2), cy - h * 0.15, w / 3 - 8, h * 0.18),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFF87CEEB).withOpacity(0.6),
        );
      }
    }

    // Front arrow
    final arrowPath = Path()
      ..moveTo(cx, cy - h / 2 - 10)
      ..lineTo(cx - 7, cy - h / 2 + 2)
      ..lineTo(cx + 7, cy - h / 2 + 2)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = const Color(0xFFFFE600));
  }

  void _drawWheel(Canvas canvas, Offset pos, Color carColor) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(pos.dx, pos.dy, 12, 18), const Radius.circular(3)),
      Paint()..color = const Color(0xFF1A1A1A),
    );
    canvas.drawCircle(Offset(pos.dx + 6, pos.dy + 9), 4,
        Paint()..color = carColor.withOpacity(0.6));
  }

  @override
  bool shouldRepaint(_CarIllustrationPainter old) =>
      old.color != color || old.carId != carId || old.locked != locked;
}
