import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_scope.dart';
import '../core/cognata.dart';
import '../core/models.dart';
import '../core/record_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cognata_card.dart';
import '../widgets/page_body.dart';

enum _Phase { playing, won, lost, already }

class DailyPage extends StatefulWidget {
  const DailyPage({super.key});

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> {
  final TextEditingController _input = TextEditingController();

  RecordStore? _store;
  Puzzle? _puzzle;
  int _number = 0;
  _Phase _phase = _Phase.playing;
  List<String> _guesses = [];
  DailyRecord? _record;
  bool _shared = false;
  String? _error;
  bool _loading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _store = AppScope.of(context).store;
    _init(AppScope.of(context).data.puzzles);
  }

  Future<void> _init(List<Puzzle> puzzles) async {
    final result = puzzleFor(puzzles);
    final record = await _store!.load();
    if (!mounted) return;

    var phase = _Phase.playing;
    var guesses = <String>[];
    if (record != null) {
      final g = record.results[todayKey()];
      if (g != null) {
        phase = g == 0 ? _Phase.already : _Phase.won;
        guesses = List.filled(g == 0 ? 3 : g, '•');
      }
    }

    setState(() {
      _puzzle = result.puzzle;
      _number = result.number;
      _record = record;
      _phase = phase;
      _guesses = guesses;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final puzzle = _puzzle;
    if (puzzle == null) return;

    final guess = _input.text.trim();
    if (guess.isEmpty) return;
    if (!RegExp(r"^[A-Za-zÀ-ÿ' -]+$").hasMatch(guess)) {
      setState(() => _error = 'Letters only.');
      return;
    }

    setState(() {
      _error = null;
      _guesses = [..._guesses, guess];
      _input.clear();
    });

    if (checkGuess(puzzle, guess)) {
      setState(() => _phase = _Phase.won);
      final record = await _store!.recordResult(_guesses.length);
      if (!mounted) return;
      setState(() => _record = record);
    } else if (_guesses.length >= 3) {
      setState(() => _phase = _Phase.lost);
      final record = await _store!.recordResult(0);
      if (!mounted) return;
      setState(() => _record = record);
    }
  }

  Future<void> _share() async {
    final stored = _record?.results[todayKey()];
    final used = stored ??
        (_guesses.isNotEmpty ? _guesses.length : 3);
    final text = shareText(_number, _phase == _Phase.lost ? 0 : used);
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      setState(() => _shared = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Result copied to clipboard.')),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _shared = false);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _error = 'Couldn\'t reach the clipboard — select and copy manually.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _puzzle == null) {
      return const PageBody(
        maxWidth: 640,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Text(
              'Opening today\'s cipher…',
              style: TextStyle(color: CognataColors.faded),
            ),
          ),
        ),
      );
    }

    final puzzle = _puzzle!;
    final hintsShown = _phase == _Phase.playing ? _guesses.length : 3;

    return PageBody(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Text(
                'COGNATA #$_number',
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  color: CognataColors.faded,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The Daily Cognate',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: CognataFonts.display,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: CognataColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          CognataCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Text(
                  'Today\'s mystery word, in',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: CognataColors.faded,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  puzzle.source.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: CognataColors.gold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  puzzle.word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: CognataFonts.display,
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: CognataColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Guess the modern English cousin — 3 tries.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: CognataColors.faded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _guesses.length; i++) ...[
            _GuessRow(
              guess: _guesses[i],
              correct: _phase == _Phase.won &&
                  i == _guesses.length - 1 &&
                  _guesses[i] != '•',
            ),
            const SizedBox(height: 8),
          ],
          if (hintsShown > 0 && _phase != _Phase.won) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < puzzle.hints.take(hintsShown).length; i++) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: CognataColors.paper,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hint ${i + 1}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: CognataColors.gold,
                        ),
                      ),
                      TextSpan(text: puzzle.hints[i]),
                    ],
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: CognataColors.faded,
                  ),
                ),
              ),
            ],
          ],
          if (_phase == _Phase.playing) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    onSubmitted: (_) => _submit(),
                    autofocus: true,
                    maxLength: 24,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 16,
                      letterSpacing: 1,
                      fontFamily: CognataFonts.body,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Your English guess…',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: CognataColors.accent,
                    foregroundColor: CognataColors.cream,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: CognataFonts.body,
                    ),
                  ),
                  child: const Text('Decrypt'),
                ),
              ],
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: CognataColors.accent,
                ),
              ),
            ),
          if (_phase != _Phase.playing) ...[
            const SizedBox(height: 20),
            CognataCard(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  if (_phase == _Phase.won)
                    const Text(
                      '🎉 Decrypted!',
                      style: TextStyle(
                        fontFamily: CognataFonts.display,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: CognataColors.greenInk,
                      ),
                    ),
                  if (_phase == _Phase.lost)
                    const Text(
                      'The cipher wins today.',
                      style: TextStyle(
                        fontFamily: CognataFonts.display,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: CognataColors.accent,
                      ),
                    ),
                  if (_phase == _Phase.already)
                    const Text(
                      'You already played today.',
                      style: TextStyle(
                        fontFamily: CognataFonts.display,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: CognataColors.faded,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'The answer: '),
                        TextSpan(
                          text: puzzle.answers.first.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: CognataFonts.display,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 14.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    puzzle.fact,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.65,
                      color: CognataColors.faded,
                    ),
                  ),
                  if (_record != null) ...[
                    const SizedBox(height: 14),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: '🔥 Current streak: '),
                          TextSpan(
                            text: '${_record!.streak}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _share,
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
                    child: Text(_shared ? 'Copied!' : 'Share your result'),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Want the full rulebook? '),
                TextSpan(
                  text: 'Open the Decryption Matrix',
                  style: const TextStyle(
                    color: CognataColors.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: CognataColors.accent,
                  ),
                ),
                const TextSpan(text: '.'),
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
    );
  }
}

class _GuessRow extends StatelessWidget {
  const _GuessRow({required this.guess, required this.correct});

  final String guess;
  final bool correct;

  @override
  Widget build(BuildContext context) {
    final placeholder = guess == '•';
    final Color border;
    final Color background;
    final Color text;

    if (correct) {
      border = CognataColors.green;
      background = CognataColors.greenSurface;
      text = CognataColors.ink;
    } else if (placeholder) {
      border = CognataColors.leafBorder;
      background = CognataColors.paper;
      text = CognataColors.faded;
    } else {
      border = CognataColors.accent.withValues(alpha: 0.3);
      background = CognataColors.accent.withValues(alpha: 0.05);
      text = CognataColors.ink;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Text(
              guess.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: CognataFonts.display,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: text,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            correct ? '✓ cognate!' : '✗',
            style: TextStyle(
              fontSize: 13,
              color: correct
                  ? CognataColors.greenInk
                  : CognataColors.faded,
            ),
          ),
        ],
      ),
    );
  }
}
