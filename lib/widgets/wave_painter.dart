import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';

/// Küre içindeki tek bir renkli içecek bandı.
class WaveBand {
  const WaveBand({
    required this.color,
    required this.fraction,
    required this.label,
    required this.percent,
  });

  final Color color;

  /// Günlük hedefe göre bu bandın kapladığı oran (0 - 1).
  final double fraction;

  final String label;
  final int percent;
}

/// CustomPainter + sinüs dalgası matematiği ile çizilen segmentli su küresi.
///
/// Her içecek türü (Su, Maden Suyu, Çay, Kahve) kendi rengiyle alttan
/// üste doğru istiflenir; sadece en üst bandın yüzeyi dalgalanır, bantlar
/// birbirine karışmaz.
class WavePainter extends CustomPainter {
  WavePainter({
    required this.bands,
    required this.animation,
    this.baseColor = const Color(0xFFF0F6FD),
  }) : super(repaint: animation);

  /// Alttan üste sıralı renkli bantlar.
  final List<WaveBand> bands;
  final Animation<double> animation;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.shortestSide / 2;

    final Path circle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(circle);

    // Daire içi boş (henüz doldurulmamış) zemin.
    canvas.drawCircle(center, radius, Paint()..color = baseColor);

    if (bands.isNotEmpty) {
      final double height = size.height;
      final double phase = animation.value * math.pi * 2;

      // Bant sınırlarını alttan üste hesapla.
      double cursorY = height;
      final List<_BandLayout> layouts = <_BandLayout>[];
      for (final WaveBand band in bands) {
        final double bandHeight = band.fraction * height;
        final double topY = cursorY - bandHeight;
        layouts.add(_BandLayout(band: band, topY: topY, bottomY: cursorY));
        cursorY = topY;
      }

      // Düz bantlar (en üstteki hariç) - alttan üste çizilir.
      for (int i = 0; i < layouts.length - 1; i++) {
        final _BandLayout layout = layouts[i];
        final Rect rect = Rect.fromLTRB(
          0,
          layout.topY,
          size.width,
          layout.bottomY,
        );
        canvas.drawRect(rect, Paint()..color = layout.band.color);
        // Bantları ayıran ince beyaz çizgi.
        canvas.drawLine(
          Offset(0, layout.topY),
          Offset(size.width, layout.topY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..strokeWidth = 1.5,
        );
      }

      // En üst bant: dalgalı yüzey.
      final _BandLayout top = layouts.last;
      final double amplitude = size.height * 0.028;
      final Path wave = Path();
      wave.moveTo(-2, top.bottomY + 2);
      wave.lineTo(-2, top.topY);
      for (double x = 0; x <= size.width + 2; x += 3) {
        final double normalized = x / size.width;
        final double y =
            top.topY +
            amplitude * math.sin((normalized * math.pi * 2 * 2.0) + phase);
        wave.lineTo(x, y);
      }
      wave.lineTo(size.width + 2, top.bottomY + 2);
      wave.close();
      canvas.drawPath(wave, Paint()..color = top.band.color);

      // Yüzey parlaklığı.
      final Paint surfacePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.40)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      final Path surface = Path();
      for (double x = 0; x <= size.width + 2; x += 3) {
        final double normalized = x / size.width;
        final double y =
            top.topY +
            amplitude * math.sin((normalized * math.pi * 2 * 2.0) + phase);
        if (x == 0) {
          surface.moveTo(x, y);
        } else {
          surface.lineTo(x, y);
        }
      }
      canvas.drawPath(surface, surfacePaint);

      // Su içinde yükselen kabarcıklar.
      for (int i = 0; i < 3; i++) {
        final double t = (animation.value + i * 0.33) % 1.0;
        final double x = size.width * (0.24 + i * 0.26);
        final double y = size.height - t * (size.height - top.topY);
        if (y > top.topY + 10 && y < size.height - 8) {
          canvas.drawCircle(
            Offset(x, y),
            3.5 + i * 1.2,
            Paint()..color = Colors.white.withValues(alpha: 0.35),
          );
        }
      }
    }

    canvas.restore();

    // Dış çerçeve.
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) =>
      oldDelegate.bands != bands ||
      oldDelegate.animation != animation ||
      oldDelegate.baseColor != baseColor;
}

class _BandLayout {
  const _BandLayout({
    required this.band,
    required this.topY,
    required this.bottomY,
  });

  final WaveBand band;
  final double topY;
  final double bottomY;
}

/// Kürenin etrafındaki şık halka ilerleme göstergesi.
class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide / 2) - 4;

    // Arka plan izi.
    final Paint trackPaint = Paint()
      ..color = const Color(0xFFE2EDF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final Rect rect = Rect.fromCircle(center: center, radius: radius);
      final Paint progressPaint = Paint()
        ..shader = AppColors.primaryGradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5;

      const double startAngle = -math.pi / 2;
      final double sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Ana ekrandaki segmentli dalgalı su küresi.
class WaveSphere extends StatefulWidget {
  const WaveSphere({
    super.key,
    required this.typeTotals,
    required this.consumedMl,
    required this.goalMl,
    this.size = 224,
  });

  /// İçecek etiketi -> net ml.
  final Map<String, int> typeTotals;
  final int consumedMl;
  final int goalMl;
  final double size;

  @override
  State<WaveSphere> createState() => _WaveSphereState();
}

class _WaveSphereState extends State<WaveSphere>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<WaveBand> _buildBands(double scale) {
    final int goal = widget.goalMl <= 0 ? 2500 : widget.goalMl;
    final List<WaveBand> bands = <WaveBand>[];
    double cumulative = 0;

    for (final DrinkType type in kDrinkTypes) {
      final int ml = widget.typeTotals[type.label] ?? 0;
      if (ml <= 0) {
        continue;
      }
      double fraction = (ml / goal) * scale;
      // Toplam %100'ü aşmasın.
      if (cumulative + fraction > 1.0) {
        fraction = (1.0 - cumulative).clamp(0.0, 1.0);
      }
      if (fraction <= 0.001) {
        continue;
      }
      cumulative += fraction;
      bands.add(
        WaveBand(
          color: type.color,
          fraction: fraction,
          label: type.shortLabel,
          percent: ((ml / goal) * 100).round(),
        ),
      );
    }
    return bands;
  }

  @override
  Widget build(BuildContext context) {
    final int goal = widget.goalMl <= 0 ? 2500 : widget.goalMl;
    final double target = (widget.consumedMl / goal).clamp(0.0, 1.0);
    final int percent = (target * 100).round();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double scale, _) {
        final List<WaveBand> bands = _buildBands(scale);
        final double innerSize = widget.size - 20;

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.14),
                blurRadius: 24,
                spreadRadius: -4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Dış çemberdeki şık gradyan ilerleme çizgisi.
              Positioned.fill(
                child: CustomPaint(
                  painter: _ProgressRingPainter(progress: target * scale),
                ),
              ),
              // İç dalga küresi.
              RepaintBoundary(
                child: CustomPaint(
                  size: Size.square(innerSize),
                  painter: WavePainter(bands: bands, animation: _controller),
                ),
              ),
              // Merkez metin: Arka plandaki dalgaları kapatmayan, şık yarı saydam buzlu cam kapsül.
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.84),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: <Widget>[
                            Text(
                              formatMl(widget.consumedMl),
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: AppColors.heading,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              'ml',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '%$percent tamamlandı',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
