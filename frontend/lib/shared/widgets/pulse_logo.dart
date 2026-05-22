import 'package:flutter/material.dart';

const String kAppName = 'Pulse of Life';
const String kAppSlogan = 'Track what matters. Live with purpose.';
const String kAppVersion = '1.0.0';

/// Official Pulse of Life logo — heartbeat ECG line merging into a heart.
class PulseOfLifeLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSlogan;
  final bool showVersion;
  final Color? textColor;

  const PulseOfLifeLogo({
    super.key,
    this.size = 72,
    this.showText = false,
    this.showSlogan = false,
    this.showVersion = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final tc = textColor ?? Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00D4AA), Color(0xFF6B4EFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.26),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B4EFF).withValues(alpha: 0.4),
                blurRadius: size * 0.3,
                offset: Offset(0, size * 0.08),
              ),
              BoxShadow(
                color: const Color(0xFF00D4AA).withValues(alpha: 0.2),
                blurRadius: size * 0.15,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: CustomPaint(painter: _PulseLogoPainter()),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.16),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'PULSE ',
                  style: TextStyle(
                    color: tc,
                    fontSize: size * 0.28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: size * 0.03,
                  ),
                ),
                TextSpan(
                  text: 'of Life',
                  style: TextStyle(
                    color: tc.withValues(alpha: 0.85),
                    fontSize: size * 0.24,
                    fontWeight: FontWeight.w300,
                    letterSpacing: size * 0.01,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (showSlogan) ...[
          SizedBox(height: size * 0.08),
          Text(
            kAppSlogan,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: tc.withValues(alpha: 0.55),
              fontSize: size * 0.14,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ],
        if (showVersion) ...[
          SizedBox(height: size * 0.06),
          Text(
            'v$kAppVersion',
            style: TextStyle(
              color: tc.withValues(alpha: 0.35),
              fontSize: size * 0.12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _PulseLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pad = w * 0.12;

    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.065
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── ECG pulse line (left side) ────────────────────────────────────────
    final ecg = Path();
    ecg.moveTo(pad, h * 0.50);
    ecg.lineTo(w * 0.23, h * 0.50);
    ecg.lineTo(w * 0.29, h * 0.37);
    ecg.lineTo(w * 0.33, h * 0.50);
    ecg.lineTo(w * 0.38, h * 0.18);  // main spike up
    ecg.lineTo(w * 0.43, h * 0.76);  // main spike down
    ecg.lineTo(w * 0.48, h * 0.50);
    ecg.lineTo(w * 0.535, h * 0.50); // connect to heart entry
    canvas.drawPath(ecg, paint);

    // ── Heart shape (right side) ──────────────────────────────────────────
    final cx = w * 0.735;
    final cy = h * 0.50;
    final s = w * 0.225;

    final heart = Path();
    // Start at top-center indentation (where two lobes meet)
    heart.moveTo(cx, cy - s * 0.05);
    // Left lobe: arc up-left then curve down
    heart.cubicTo(cx - s * 0.05, cy - s * 0.48, cx - s * 0.52, cy - s * 0.44, cx - s * 0.50, cy - s * 0.04);
    // Left bottom → tip
    heart.cubicTo(cx - s * 0.50, cy + s * 0.22, cx - s * 0.18, cy + s * 0.42, cx, cy + s * 0.56);
    // Tip → right bottom
    heart.cubicTo(cx + s * 0.18, cy + s * 0.42, cx + s * 0.50, cy + s * 0.22, cx + s * 0.50, cy - s * 0.04);
    // Right lobe: arc up-right then back to center
    heart.cubicTo(cx + s * 0.52, cy - s * 0.44, cx + s * 0.05, cy - s * 0.48, cx, cy - s * 0.05);
    heart.close();

    // Draw heart fill (semi-transparent white glow)
    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawPath(heart, fillPaint);

    // Draw heart outline
    canvas.drawPath(heart, paint);

    // ── Connecting line ECG → heart ───────────────────────────────────────
    final connector = Path();
    connector.moveTo(w * 0.535, h * 0.50);
    connector.lineTo(cx - s * 0.50, h * 0.50);
    canvas.drawPath(connector, paint);

    // ── Small pulse dot at center of heart ────────────────────────────────
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + s * 0.12), w * 0.04, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated version of the logo for splash screens.
class AnimatedPulseLogo extends StatefulWidget {
  final double size;
  final VoidCallback? onComplete;
  const AnimatedPulseLogo({super.key, this.size = 100, this.onComplete});

  @override
  State<AnimatedPulseLogo> createState() => _AnimatedPulseLogoState();
}

class _AnimatedPulseLogoState extends State<AnimatedPulseLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4)),
    );
    _ctrl.forward().then((_) => widget.onComplete?.call());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: PulseOfLifeLogo(
            size: widget.size,
            showText: true,
            showSlogan: true,
          ),
        ),
      ),
    );
  }
}
