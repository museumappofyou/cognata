import 'package:cognata/src/core/cognata.dart';
import 'package:cognata/src/core/models.dart';
import 'package:cognata/src/core/record_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Puzzle _puzzle(int id) => Puzzle(
      id: id,
      source: 'Latin',
      word: 'PISCIS',
      answers: const ['fish'],
      hints: const ['a', 'b', 'c'],
      fact: 'fact',
    );

void main() {
  group('normalize', () {
    test('lowercases, folds diacritics and drops punctuation', () {
      expect(normalize('Bruder'), 'bruder');
      expect(normalize('Æsir!'), 'aesir');
      expect(normalize('Wasser-'), 'wasser');
      expect(normalize('tres,'), 'tres');
      expect(normalize('ḱērd'), 'kerd');
      expect(normalize('  '), '');
    });
  });

  group('checkGuess', () {
    final puzzle = _puzzle(1);
    test('accepts case and diacritic variants', () {
      expect(checkGuess(puzzle, 'Fish'), isTrue);
      expect(checkGuess(puzzle, 'FISH!'), isTrue);
      expect(checkGuess(puzzle, 'fich'), isFalse);
    });
  });

  group('dayNumber / todayKey', () {
    test('epoch is day 0', () {
      expect(dayNumber(DateTime.utc(2026, 1, 1)), 0);
    });
    test('stable per UTC calendar day', () {
      expect(dayNumber(DateTime.utc(2026, 1, 2, 23, 59)), 1);
      expect(dayNumber(DateTime.utc(2026, 1, 2, 0, 1)), 1);
      expect(dayNumber(DateTime.utc(2025, 12, 31, 23, 59)), -1);
    });
    test('todayKey is the UTC ISO date', () {
      expect(todayKey(DateTime.utc(2026, 3, 5, 10)), '2026-03-05');
      expect(todayKey(DateTime.utc(2026, 12, 31, 23)), '2026-12-31');
    });
  });

  group('puzzleFor', () {
    final puzzles = [for (var i = 0; i < 5; i++) _puzzle(i)];
    test('cycles by day and reports 1-based number', () {
      final first = puzzleFor(puzzles, DateTime.utc(2026, 1, 1));
      expect(first.puzzle.id, 0);
      expect(first.number, 1);
      expect(puzzleFor(puzzles, DateTime.utc(2026, 1, 7)).puzzle.id, 1);
      expect(puzzleFor(puzzles, DateTime.utc(2026, 1, 7)).number, 7);
    });
    test('handles dates before the epoch', () {
      final before = puzzleFor(puzzles, DateTime.utc(2025, 12, 31));
      expect(before.puzzle.id, 4);
      expect(before.number, 0);
    });
  });

  group('shareText', () {
    test('formats a solved game', () {
      expect(shareText(3, 2), contains('Cognata #3 🟩🟩⬛'));
      expect(shareText(3, 2), contains('solved in 2 guesses'));
    });
    test('formats a loss and a one-guess win', () {
      expect(shareText(4, 0), contains('⬛⬛⬛'));
      expect(shareText(4, 0), contains('defeated by a sound law'));
      expect(shareText(5, 1), contains('solved in 1 guess'));
    });
  });

  group('RecordStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('records a result and builds a streak across consecutive days',
        () async {
      final store = RecordStore();
      var rec = await store.recordResult(2, DateTime.utc(2026, 1, 10, 12));
      expect(rec.streak, 1);
      expect(rec.results['2026-01-10'], 2);

      rec = await store.recordResult(1, DateTime.utc(2026, 1, 11, 12));
      expect(rec.streak, 2);
    });

    test('replaying the same day keeps the first result', () async {
      final store = RecordStore();
      await store.recordResult(1, DateTime.utc(2026, 1, 10, 12));
      final rec = await store.recordResult(3, DateTime.utc(2026, 1, 10, 18));
      expect(rec.results['2026-01-10'], 1);
      expect(rec.streak, 1);
    });

    test('a missed day resets the streak', () async {
      final store = RecordStore();
      await store.recordResult(1, DateTime.utc(2026, 1, 10, 12));
      final rec = await store.recordResult(1, DateTime.utc(2026, 1, 13, 12));
      expect(rec.streak, 1);
    });
  });

  test('buildAnkiExport emits TSV rows grouped by pair', () {
    const laws = [
      SoundLaw(
        id: 'x',
        pair: 'en-de',
        rule: 't→ss',
        ipa: 'ipa',
        title: 'T',
        explanation: 'e',
        unlocks: 10,
        examples: [
          LawExample(en: 'water', other: 'Wasser'),
          LawExample(en: 'foot', other: 'Fuß'),
        ],
      ),
    ];
    expect(
      buildAnkiExport(laws, 'en-de'),
      'Wasser\twater — rule: t→ss\nFuß\tfoot — rule: t→ss',
    );
    expect(buildAnkiExport(laws, 'en-es'), '');
  });
}
