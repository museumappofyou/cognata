import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.child, this.maxWidth = 1024});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                const SizedBox(height: 64),
                const _Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const Divider(color: CognataColors.border, height: 1),
          const SizedBox(height: 24),
          Text(
            'Built on historical linguistics — Grimm\'s Law, the High German '
            'shift, and the Wiktionary etymology community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: CognataColors.faded,
              fontFamily: CognataFonts.body,
            ),
          ),
        ],
      ),
    );
  }
}
