import 'package:flutter/material.dart';

import '../app.dart';

class P41Logo extends StatelessWidget {
  const P41Logo({
    super.key,
    this.size = 34,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'P',
            style: TextStyle(
              fontFamily: 'GlacialIndifference',
              fontSize: size,
              fontWeight: FontWeight.w400,
              color: palette.textStrong,
              height: 1,
            ),
          ),
          TextSpan(
            text: '41',
            style: TextStyle(
              fontFamily: 'GlacialIndifference',
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: palette.warning,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
