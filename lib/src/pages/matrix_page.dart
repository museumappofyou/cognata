import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app/app_scope.dart';
import '../core/cognata.dart';
import '../core/models.dart';
import '../data/cognata_data.dart';
import '../theme/app_theme.dart';
import '../widgets/cognata_card.dart';
import '../widgets/page_body.dart';
import '../widgets/page_header.dart';
import '../widgets/pill_button.dart';

class MatrixPage extends StatefulWidget {
  const MatrixPage({super.key});

  @override
  State<MatrixPage> createState() => _MatrixPageState();
}

class _MatrixPageState extends State<MatrixPage> {
  String _pair = CognataData.pairs.first.id;
  String? _open;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final laws = AppScope.of(context).data.laws;
    if (laws.isNotEmpty) _open = laws.first.id;
  }

  Future<void> _export(String pairId, int count) async {
    final laws = AppScope.of(context).data.laws;
    final tsv = buildAnkiExport(laws, pairId);
    final fileName = 'cognata-$pairId-deck.tsv';
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              utf8.encode(tsv),
              name: fileName,
              mimeType: 'text/tab-separated-values',
            ),
          ],
          fileNameOverrides: [fileName],
          text: 'Cognata — $count sound-law flashcards (Anki TSV)',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the share sheet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final laws = AppScope.of(context).data.laws
        .where((l) => l.pair == _pair)
        .toList();
    final totalUnlocked = laws.fold<int>(0, (sum, l) => sum + l.unlocks);
    final pairExamples = laws.expand((l) => l.examples).length;

    return PageBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'The Decryption Matrix',
            subtitle:
                'Learn ${laws.length} rules, unlock ~${_formatThousands(totalUnlocked)} words overnight.',
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final p in CognataData.pairs) ...[
                PillButton(
                  label: p.label,
                  selected: _pair == p.id,
                  onPressed: () => setState(() => _pair = p.id),
                ),
                if (p != CognataData.pairs.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 28),
          for (var idx = 0; idx < laws.length; idx++) ...[
            _LawCard(
              index: idx + 1,
              law: laws[idx],
              expanded: _open == laws[idx].id,
              onToggle: () => setState(
                () => _open = _open == laws[idx].id ? null : laws[idx].id,
              ),
            ),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 10),
          CognataCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(
                  'Export all $pairExamples pairs as an Anki-ready deck — '
                  'cards grouped by sound law, not by topic, because your brain '
                  'remembers the rule, not the list.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.65,
                    color: CognataColors.faded,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => _export(_pair, pairExamples),
                  style: FilledButton.styleFrom(
                    backgroundColor: CognataColors.ink,
                    foregroundColor: CognataColors.cream,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: CognataFonts.body,
                    ),
                  ),
                  child: Text('⬇ Export $pairExamples cards to Anki (TSV)'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'In Anki: File → Import → choose the file, tab-separated. Done.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: CognataColors.faded,
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

String _formatThousands(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

class _LawCard extends StatelessWidget {
  const _LawCard({
    required this.index,
    required this.law,
    required this.expanded,
    required this.onToggle,
  });

  final int index;
  final SoundLaw law;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CognataCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    index.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontFamily: CognataFonts.display,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: CognataColors.gold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          law.title,
                          style: const TextStyle(
                            fontFamily: CognataFonts.display,
                            fontSize: 17.5,
                            fontWeight: FontWeight.w700,
                            color: CognataColors.ink,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${law.rule} · ${law.ipa}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: CognataColors.faded,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: CognataColors.paper,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '🔓 ~${_formatThousands(law.unlocks)} words',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: CognataColors.faded,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Text(
                      '▸',
                      style: TextStyle(
                        fontSize: 18,
                        color: CognataColors.faded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFEEE5D2)),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    law.explanation,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      color: CognataColors.faded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final twoUp = constraints.maxWidth >= 560;
                      final examples = law.examples;
                      final rows = <Widget>[
                        for (final ex in examples)
                          _ExampleTile(other: ex.other, en: ex.en),
                      ];
                      if (!twoUp) {
                        return Column(
                          children: [
                            for (var i = 0; i < rows.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              rows[i],
                            ],
                          ],
                        );
                      }
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final row in rows)
                            SizedBox(
                              width: (constraints.maxWidth - 8) / 2,
                              child: row,
                            ),
                        ],
                      );
                    },
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

class _ExampleTile extends StatelessWidget {
  const _ExampleTile({required this.other, required this.en});

  final String other;
  final String en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: CognataColors.paper,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              other,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: CognataColors.ink,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '↔',
              style: TextStyle(color: CognataColors.gold),
            ),
          ),
          Flexible(
            child: Text(
              en,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: CognataColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
