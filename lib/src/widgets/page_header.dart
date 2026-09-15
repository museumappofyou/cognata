import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.tagline,
    this.taglineColor = CognataColors.accent,
  });

  final String title;
  final String? subtitle;
  final String? tagline;
  final Color taglineColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: CognataFonts.display,
            fontSize: 34,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: CognataColors.ink,
          ),
        ),
        if (tagline != null) ...[
          const SizedBox(height: 8),
          Text(
            tagline!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: CognataFonts.display,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: taglineColor,
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.6,
              color: CognataColors.faded,
            ),
          ),
        ],
      ],
    );
  }
}
