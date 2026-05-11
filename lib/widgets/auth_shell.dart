import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'app_logo.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 650),
                              child: const _BrandHeader(),
                            ),
                            const SizedBox(height: 22),
                            FadeInUp(
                              delay: const Duration(milliseconds: 120),
                              duration: const Duration(milliseconds: 650),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x260B1220),
                                      blurRadius: 32,
                                      offset: Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF101827),
                                          fontSize: 30,
                                          fontWeight: FontWeight.w900,
                                          height: 1.08,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Color(0xFF667085),
                                          fontSize: 15.5,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 26),
                                      ...children,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: onPressed == null
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x332563EB),
                    blurRadius: 18,
                    offset: Offset(0, 9),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: const Color(0xFFE5E7EB),
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthStatusMessage extends StatelessWidget {
  const AuthStatusMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return FadeIn(
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFC2410C), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF9A3412), height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        AppLogo(height: 156),
        SizedBox(height: 12),
        Text(
          'List your room. Book with ease.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            shadows: [
              Shadow(
                color: Color(0x660B1220),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF082F49), Color(0xFF0F766E), Color(0xFF1D4ED8)],
          stops: [0, 0.52, 1],
        ),
      ),
      child: CustomPaint(painter: _AuthBackdropPainter()),
    );
  }
}

class _AuthBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cyanPaint = Paint()..color = const Color(0x3306B6D4);
    final amberPaint = Paint()..color = const Color(0x22F59E0B);
    final whitePaint = Paint()..color = const Color(0x14FFFFFF);

    final topBand = Path()
      ..moveTo(0, size.height * 0.08)
      ..lineTo(size.width, size.height * 0.0)
      ..lineTo(size.width, size.height * 0.18)
      ..lineTo(0, size.height * 0.32)
      ..close();

    final middleBand = Path()
      ..moveTo(0, size.height * 0.66)
      ..lineTo(size.width, size.height * 0.48)
      ..lineTo(size.width, size.height * 0.62)
      ..lineTo(0, size.height * 0.82)
      ..close();

    final bottomBand = Path()
      ..moveTo(0, size.height * 0.88)
      ..lineTo(size.width, size.height * 0.74)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(topBand, whitePaint);
    canvas.drawPath(middleBand, cyanPaint);
    canvas.drawPath(bottomBand, amberPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
