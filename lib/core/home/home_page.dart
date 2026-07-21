import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final svc = AuthService();
      await svc.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Clean off-white background
      body: Stack(
        children: [
          // Dynamic Transit Background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: TransitBackgroundPainter(
                    animationValue: _controller.value,
                  ),
                );
              },
            ),
          ),
          
          // Logo & Branding at top
          Positioned(
            top: size.height * 0.08,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    size: 32,
                    color: Color(0xFF0D9488), // Teal primary
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pickkaru',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Coordinated commute helper',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          // Action Card at Bottom (Highly rounded radius 32)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Daily Commute Made Easy',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Coordinate paths, check rides, and track transit dynamically in real time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Unified "Continue with Google" Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488), // Teal Accent Primary
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30), // Highly rounded
                      ),
                    ),
                    onPressed: _loading ? null : _handleGoogleSignIn,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else ...[
                          // Clean White Backdrop Google Icon
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Image.network(
                              'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                              height: 18,
                              width: 18,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.g_mobiledata,
                                  size: 18,
                                  color: Colors.red,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransitBackgroundPainter extends CustomPainter {
  final double animationValue;

  TransitBackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw stylized background grids/roads
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double gridSpace = size.width / 5;
    for (double i = 0; i < size.width; i += gridSpace) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += gridSpace) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // 2. Define a winding road path
    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.35);
    path.cubicTo(
      size.width * 0.5, size.height * 0.2,
      size.width * 0.2, size.height * 0.55,
      size.width * 0.85, size.height * 0.45,
    );

    // Draw the main road line
    final roadPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 12.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadOverlayPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, roadPaint);
    canvas.drawPath(path, roadOverlayPaint);

    // Draw dashes on the road
    final dashesPaint = Paint()
      ..color = const Color(0xFF0D9488).withValues(alpha: 0.15) // Subtle Teal accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, dashesPaint);

    // 3. Extract path metrics for animated vehicle placement
    final PathMetrics metrics = path.computeMetrics();
    final iterator = metrics.iterator;
    if (iterator.moveNext()) {
      final PathMetric metric = iterator.current;
      final double totalLength = metric.length;
      final double currentPos = totalLength * animationValue;
      final Tangent? tangent = metric.getTangentForOffset(currentPos);

      if (tangent != null) {
        final position = tangent.position;
        final angle = tangent.angle;

        // Draw animated vehicle (bus/car representation)
        canvas.save();
        canvas.translate(position.dx, position.dy);
        canvas.rotate(-angle); // Align with tangent direction

        // Vehicle body shadow
        final shadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-18, -10, 36, 20), const Radius.circular(6)), shadowPaint);

        // Vehicle main body (Teal Primary Accent)
        final vehiclePaint = Paint()..color = const Color(0xFF0D9488);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -9, 32, 18), const Radius.circular(5)), vehiclePaint);

        // Windshield
        final windowPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
        canvas.drawRect(const Rect.fromLTWH(6, -6, 6, 12), windowPaint);

        // Headlights
        final lightsPaint = Paint()..color = Colors.yellow;
        canvas.drawCircle(const Offset(15, -5), 2, lightsPaint);
        canvas.drawCircle(const Offset(15, 5), 2, lightsPaint);

        canvas.restore();
      }
    }

    // 4. Draw Start & End Location Pins with animation bobbing
    final double bobValue = math.sin(animationValue * math.pi * 2) * 6;
    
    // Start Pin (Teal, bobbing)
    final Offset startOffset = Offset(size.width * 0.15, size.height * 0.35 + bobValue);
    _drawPin(canvas, startOffset, const Color(0xFF0D9488));

    // End Pin (Orange, reverse bobbing)
    final Offset endOffset = Offset(size.width * 0.85, size.height * 0.45 - bobValue);
    _drawPin(canvas, endOffset, const Color(0xFFF97316));
  }

  void _drawPin(Canvas canvas, Offset offset, Color color) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    // Draw shadow underneath pin
    canvas.drawOval(Rect.fromCenter(center: Offset(offset.dx, offset.dy + 12), width: 12, height: 6), shadowPaint);

    final pinPaint = Paint()..color = color;
    final centerPinPaint = Paint()..color = Colors.white;

    final pinPath = Path();
    pinPath.moveTo(offset.dx, offset.dy);
    pinPath.cubicTo(
      offset.dx - 12, offset.dy - 12,
      offset.dx - 12, offset.dy - 24,
      offset.dx, offset.dy - 24,
    );
    pinPath.cubicTo(
      offset.dx + 12, offset.dy - 24,
      offset.dx + 12, offset.dy - 12,
      offset.dx, offset.dy,
    );

    canvas.drawPath(pinPath, pinPaint);
    canvas.drawCircle(Offset(offset.dx, offset.dy - 16), 4, centerPinPaint);
  }

  @override
  bool shouldRepaint(covariant TransitBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
