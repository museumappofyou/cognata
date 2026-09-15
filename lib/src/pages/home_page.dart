import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/cognata_card.dart';
import '../widgets/page_body.dart';

const _demo = [
  (en: 'brother', other: 'Bruder', law: 'th → d', lang: 'German'),
  (en: 'water', other: 'Wasser', law: 't → ss', lang: 'German'),
  (en: 'three', other: 'tres', law: 'th → t', lang: 'Latin'),
  (en: 'fish', other: 'piscis', law: 'f → p', lang: 'Latin'),
  (en: 'night', other: 'nacht', law: 'gh → ch', lang: 'German'),
];

const _pillars = [
  (
    tab: AppTab.daily,
    title: 'The Daily Cognate',
    tag: 'Play',
    desc:
        'A mystery word from an ancient tongue, three guesses, one sound law. New puzzle every midnight.',
  ),
  (
    tab: AppTab.matrix,
    title: 'The Decryption Matrix',
    tag: 'Learn',
    desc:
        'The ten sound shifts that secretly map English onto German and Spanish — each one unlocks hundreds of words.',
  ),
  (
    tab: AppTab.tree,
    title: 'The Kinship Tree',
    tag: 'Explore',
    desc:
        'Type a word — heart, night, milk — and watch its cousins bloom across fifteen languages.',
  ),
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Hero(),
          const SizedBox(height: 64),
          const _Pillars(),
          const SizedBox(height: 64),
          const _HowItWorks(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        return Column(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Text(
                'You already know 3,000 words in German, Spanish, Italian and French.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: CognataFonts.display,
                  fontSize: wide ? 40 : 30,
                  fontWeight: FontWeight.w700,
                  height: 1.18,
                  color: CognataColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You just don\'t know the cipher yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: CognataFonts.display,
                fontSize: wide ? 23 : 19,
                fontStyle: FontStyle.italic,
                color: CognataColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: const Text(
                'Every “foreign” word is an English word passed through a '
                'mathematical sound shift. Learn ten rules and watch half a '
                'vocabulary decrypt itself.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.7,
                  color: CognataColors.faded,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const _CipherDemo(),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => AppScope.of(context).go(AppTab.daily),
              style: FilledButton.styleFrom(
                backgroundColor: CognataColors.accent,
                foregroundColor: CognataColors.cream,
                padding:
                    const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: CognataFonts.body,
                ),
              ),
              child: const Text('Play today\'s puzzle →'),
            ),
          ],
        );
      },
    );
  }
}

class _CipherDemo extends StatefulWidget {
  const _CipherDemo();

  @override
  State<_CipherDemo> createState() => _CipherDemoState();
}

class _CipherDemoState extends State<_CipherDemo> {
  int _i = 0;
  bool _revealed = false;
  Timer? _revealTimer;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _revealTimer?.cancel();
    _advanceTimer?.cancel();
    _revealTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _revealed = true);
    });
    _advanceTimer = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      setState(() {
        _revealed = false;
        _i = (_i + 1) % _demo.length;
      });
      _schedule();
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  Widget _flip({
    required Key key,
    required Widget child,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        builder: (context, _) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX((1 - animation.value) * -math.pi / 2),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
      ),
      child: KeyedSubtree(key: key, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = _demo[_i];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: CognataCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          children: [
            const Text(
              'THE CIPHER',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 3,
                color: CognataColors.faded,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                _flip(
                  key: ValueKey('en-${d.en}'),
                  child: Text(
                    d.en,
                    style: const TextStyle(
                      fontFamily: CognataFonts.display,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      color: CognataColors.ink,
                    ),
                  ),
                ),
                const Text(
                  '→',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: CognataColors.gold,
                  ),
                ),
                _flip(
                  key: ValueKey('other-${d.other}-$_revealed'),
                  child: _revealed
                      ? Text(
                          d.other,
                          style: const TextStyle(
                            fontFamily: CognataFonts.display,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: CognataColors.accent,
                          ),
                        )
                      : ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: 3,
                            sigmaY: 3,
                          ),
                          child: const Text(
                            '??????',
                            style: TextStyle(
                              fontFamily: CognataFonts.display,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Color(0x66a99f8d),
                            ),
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: d.law,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: CognataColors.ink,
                    ),
                  ),
                  TextSpan(text: '  unlocks this pair in ${d.lang}'),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: CognataColors.faded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pillars extends StatelessWidget {
  const _Pillars();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        final cards = [
          for (final p in _pillars)
            CognataCard(
              padding: const EdgeInsets.all(24),
              onTap: () => AppScope.of(context).go(p.tab),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: CognataColors.paper,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      p.tag.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: CognataColors.faded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontFamily: CognataFonts.display,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: CognataColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.desc,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.65,
                      color: CognataColors.faded,
                    ),
                  ),
                ],
              ),
            ),
        ];

        if (!wide) {
          return Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                cards[i],
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 18),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    return CognataCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How the cipher works',
            style: TextStyle(
              fontFamily: CognataFonts.display,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: CognataColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Around 500 BC, one tribe of Indo-European speakers '
                      'underwent a systematic consonant cascade — ',
                ),
                const TextSpan(
                  text: 'Grimm\'s Law',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '. Their '),
                const TextSpan(
                  text: 'p',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: '\'s became '),
                const TextSpan(
                  text: 'f',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: '\'s, their '),
                const TextSpan(
                  text: 't',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: '\'s became '),
                const TextSpan(
                  text: 'th',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: '\'s, their '),
                const TextSpan(
                  text: 'k',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: '\'s became '),
                const TextSpan(
                  text: 'h',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(
                  text: '\'s. That tribe became the Germanic peoples, and '
                      'their language became English.',
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.75,
              color: CognataColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'The Romans kept the original sounds. So Latin ',
                ),
                const TextSpan(
                  text: 'pater',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: ' is English '),
                const TextSpan(
                  text: 'father',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: ', '),
                const TextSpan(
                  text: 'tres',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: ' is '),
                const TextSpan(
                  text: 'three',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: ', '),
                const TextSpan(
                  text: 'cornu',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(text: ' is '),
                const TextSpan(
                  text: 'horn',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                const TextSpan(
                  text: ' — every single time. That\'s not memorization. '
                      'That\'s cryptography.',
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 14,
              height: 1.75,
              color: CognataColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
