import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_fonts.dart';
import '../core/app_theme.dart';
import '../core/strings.dart';
import '../services/ads_service.dart';
import '../services/premium_service.dart';
import 'calculator_screen.dart';
import 'settings_screen.dart' show openCompanyWebsite;

/// 3-second animated splash: spinning rings, popping keys, title,
/// loading bar and "Powered by Cyber Tech System".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _main = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat();

  Animation<double> _iv(double a, double b, [Curve c = Curves.easeOutCubic]) =>
      CurvedAnimation(
        parent: _main,
        curve: Interval(a, b, curve: c),
      );

  late final _draw = _iv(0, .35, Curves.easeInOutCubic);
  late final _keys = List.generate(
    4,
    (i) => _iv(.08 + i * .05, .30 + i * .05, Curves.elasticOut),
  );
  late final _title = _iv(.28, .48);
  late final _tag = _iv(.40, .55);
  late final _brand = _iv(.45, .62);
  late final _bar = _iv(0, 1, Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    _main.forward().whenComplete(_open);
  }

  void _open() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => const CalculatorScreen(),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
    // Start ads (and the consent popup) after the splash, free users only.
    if (!context.read<PremiumService>().isPremium) {
      context.read<AdsService>().start();
    }
  }

  @override
  void dispose() {
    _main.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(p.accent.withValues(alpha: .06)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 236,
                        height: 236,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_draw, _spin]),
                          builder: (_, child) => CustomPaint(
                            painter: _RingsPainter(
                              progress: _draw.value,
                              turn: _spin.value,
                              accent: p.accent,
                              dark: Color.lerp(p.accent, p.bg, .35)!,
                              light: Color.lerp(p.accent, Colors.white, .4)!,
                            ),
                            child: child,
                          ),
                          child: Center(child: _keyGrid(p)),
                        ),
                      ),
                      const SizedBox(height: 36),
                      _fadeUp(
                        _title,
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'SMART\n',
                                style: TextStyle(color: p.text),
                              ),
                              TextSpan(
                                text: 'CALCULATOR',
                                style: TextStyle(color: p.accent),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: kBrandFont,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FadeTransition(
                        opacity: _tag,
                        child: Text(
                          context.tr('tagline'),
                          style: TextStyle(
                            fontSize: 14,
                            color: p.muted,
                            letterSpacing: .5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 56),
                  child: AnimatedBuilder(
                    animation: _bar,
                    builder: (_, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _bar.value,
                        minHeight: 4,
                        backgroundColor: p.surface,
                        color: p.accent,
                        semanticsLabel: context.tr('loading'),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                _fadeUp(
                  _brand,
                  Column(
                    children: [
                      Text(
                        context.tr('poweredBy').toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.5,
                          color: p.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => openCompanyWebsite(context),
                        child: Image.asset(
                          'assets/images/cyber_logo.png',
                          height: 62,
                          semanticLabel: 'Cyber Tech System',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fadeUp(Animation<double> a, Widget child) => AnimatedBuilder(
    animation: a,
    builder: (_, c) => Opacity(
      opacity: a.value.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(0, 18 * (1 - a.value)),
        child: c,
      ),
    ),
    child: child,
  );

  Widget _keyGrid(AppPalette p) {
    const symbols = ['+', '−', '×', '='];
    return SizedBox(
      width: 126,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 58 / 58,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(4, (i) {
          final isEq = i == 3;
          return ScaleTransition(
            scale: _keys[i],
            child: Container(
              decoration: BoxDecoration(
                color: isEq ? p.accent : p.surface,
                borderRadius: BorderRadius.circular(16),
                border: isEq ? null : Border.all(color: p.border),
                boxShadow: isEq
                    ? [
                        BoxShadow(
                          color: p.accent.withValues(alpha: .45),
                          blurRadius: 24,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                symbols[i],
                style: TextStyle(
                  fontFamily: kBrandFont,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isEq
                      ? p.onAccent
                      : Color.lerp(p.accent, Colors.white, .4),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({
    required this.progress,
    required this.turn,
    required this.accent,
    required this.dark,
    required this.light,
  });

  final double progress;
  final double turn;
  final Color accent;
  final Color dark;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    void arcs(
      double r,
      double width,
      Color color,
      double rotation,
      List<double> segments,
    ) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..color = color;
      final rect = Rect.fromCircle(center: c, radius: r);
      var start = rotation;
      for (var i = 0; i < segments.length; i += 2) {
        final sweep = segments[i] * progress;
        canvas.drawArc(rect, start, sweep, false, paint);
        start += segments[i] + (i + 1 < segments.length ? segments[i + 1] : 0);
      }
    }

    const tau = math.pi * 2;
    arcs(112, 6, accent, turn * tau, [2.3, .4, 1.1, 2.4]);
    arcs(96, 10, dark, -turn * tau * .7, [2.0, .3, 0.9, 3.0]);
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = light.withValues(alpha: .55 * progress);
    for (var i = 0; i < 12; i++) {
      final a = turn * tau * 1.5 + i * tau / 12;
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 80),
        a,
        .3,
        false,
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.progress != progress || old.turn != turn;
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
