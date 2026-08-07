import 'package:flutter/material.dart';

class ShowlineLogo extends StatelessWidget {
  const ShowlineLogo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? const Color(0xFFF8F5ED) : const Color(0xFF17221C);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.ssid_chart_rounded,
            color: light ? const Color(0xFF17221C) : const Color(0xFFF8F5ED),
            size: 21,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'SHOWLINE',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
