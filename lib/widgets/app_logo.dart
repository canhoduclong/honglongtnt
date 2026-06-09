import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * .22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D7A70).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.all(size * .08),
        child: Image.asset(
          'assets/icons/icons-hl-new.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
