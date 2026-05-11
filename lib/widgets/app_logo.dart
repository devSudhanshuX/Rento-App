import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 96, this.fit = BoxFit.contain});

  static const assetPath = 'assets/images/rento_logo.png';

  final double height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
    );
  }
}
