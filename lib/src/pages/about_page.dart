import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/cognata_card.dart';
import '../widgets/page_body.dart';
import '../widgets/page_header.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return PageBody(
      maxWidth: 672,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: 'About Cognata',
            tagline: 'Language learning is cryptography — you just need the key.',
          ),
          const SizedBox(height: 32),
          CognataCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('The big idea'),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'English, German, Latin, Greek, Sanskrit and '
                            'Russian are all daughters of one language spoken '
                            'roughly 5,000 years ago: Proto-Indo-European. As '
                            'the tribes split, each branch mutated the '
                            'ancestral consonants in its own systematic, '
                            'exceptionless way — not randomly, but by law.',
                      ),
                      const TextSpan(text: '\n\n'),
                      const TextSpan(
                        text: 'In 1822, Jacob Grimm (yes, the fairy-tale '
                            'Grimm) described the most famous of these laws. '
                            'The Germanic branch shifted ',
                      ),
                      const TextSpan(
                        text: 'p → f, t → th, k → h, d → t, bʰ → b',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const TextSpan(
                        text: ' — every single time. That\'s why Latin ',
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
                      const TextSpan(text: ' and Latin '),
                      const TextSpan(
                        text: 'cornu',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const TextSpan(text: ' is English '),
                      const TextSpan(
                        text: 'horn',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const TextSpan(text: '.'),
                      const TextSpan(text: '\n\n'),
                      const TextSpan(
                        text: 'Cognata turns those laws into a game, a cheat '
                            'sheet, and a family album for words. No '
                            'brute-force memorization — just the cipher.',
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.75,
                    color: CognataColors.ink,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CognataCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('What\'s inside'),
                _NavLine(
                  label: 'The Daily Cognate',
                  tail: ' — one mystery word a day, three guesses, escalating hints.',
                  onTap: () => scope.go(AppTab.daily),
                ),
                _NavLine(
                  label: 'The Decryption Matrix',
                  tail:
                      ' — the ten most productive sound laws for English ↔ German '
                      'and English ↔ Spanish/Latin, with Anki export.',
                  onTap: () => scope.go(AppTab.matrix),
                ),
                _NavLine(
                  label: 'The Kinship Tree',
                  tail:
                      ' — a word\'s cousins across the whole family, sound law by sound law.',
                  onTap: () => scope.go(AppTab.tree),
                ),
                _NavLine(
                  label: 'The Origins',
                  tail:
                      ' — precomputed 3D terrain renders of the steppe where the family began.',
                  onTap: () => scope.go(AppTab.origins),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          CognataCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _CardTitle('Credits & caveats'),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'The etymologies here are curated from standard '
                            'historical-linguistics references and the '
                            'wonderful open Wiktionary etymology community. '
                            'Sound laws are regular, but real words wander — '
                            'every family tree has a borrowing or two hiding '
                            'in it, and the notes say so where we know.',
                      ),
                      const TextSpan(text: '\n\n'),
                      const TextSpan(text: 'Deeper data: the '),
                      TextSpan(
                        text: 'etymology-db project',
                        style: const TextStyle(
                          color: CognataColors.accent,
                          decoration: TextDecoration.underline,
                          decorationColor: CognataColors.accent,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                                Uri.parse(
                                    'https://github.com/droher/etymology-db'),
                              ),
                      ),
                      const TextSpan(
                        text:
                            ' parses Wiktionary\'s million-plus derivation relations '
                            'if you want the full graph.',
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.75,
                    color: CognataColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: CognataFonts.display,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: CognataColors.ink,
        ),
      ),
    );
  }
}

class _NavLine extends StatelessWidget {
  const _NavLine({required this.label, required this.tail, required this.onTap});

  final String label;
  final String tail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Text('•',
                style: TextStyle(fontSize: 14, color: CognataColors.faded)),
          ),
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: const TextStyle(
                        color: CognataColors.accent,
                        decoration: TextDecoration.underline,
                        decorationColor: CognataColors.accent,
                      ),
                    ),
                    TextSpan(text: tail),
                  ],
                ),
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.7,
                  color: CognataColors.ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
