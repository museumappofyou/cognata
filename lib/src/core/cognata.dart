import 'models.dart';

/// Days since the fixed epoch (2026-01-01), in UTC — stable per calendar day.
int dayNumber([DateTime? date]) {
  final d = (date ?? DateTime.now()).toUtc();
  final now = DateTime.utc(d.year, d.month, d.day);
  final epoch = DateTime.utc(2026, 1, 1);
  return (now.difference(epoch).inHours / 24).round();
}

/// ISO date key (YYYY-MM-DD) in UTC.
String todayKey([DateTime? date]) {
  final d = (date ?? DateTime.now()).toUtc();
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

({Puzzle puzzle, int number}) puzzleFor(List<Puzzle> puzzles, [DateTime? date]) {
  final n = dayNumber(date);
  final idx = ((n % puzzles.length) + puzzles.length) % puzzles.length;
  return (puzzle: puzzles[idx], number: n + 1);
}

const _diacritics = <String, String>{
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'ă': 'a', 'ą': 'a', 'ç': 'c', 'ć': 'c', 'č': 'c', 'ĉ': 'c', 'è': 'e',
  'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ĕ': 'e', 'ė': 'e', 'ę': 'e',
  'ě': 'e', 'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'ĭ': 'i',
  'į': 'i', 'ı': 'i', 'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ņ': 'n', 'ò': 'o',
  'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o', 'ŏ': 'o',
  'ő': 'o', 'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ŭ': 'u',
  'ů': 'u', 'ų': 'u', 'ű': 'u', 'ý': 'y', 'ÿ': 'y', 'ŷ': 'y', 'ß': 'ss',
  'æ': 'ae', 'œ': 'oe', 'ḱ': 'k', 'ǵ': 'g', 'ʰ': 'h', 'ʷ': 'w', 'ə': 'e',
  'ṃ': 'm', 'ṇ': 'n', 'ṛ': 'r', 'ḷ': 'l',
};

/// Lowercase, strip diacritics and anything that isn't a letter.
String normalize(String s) {
  final buffer = StringBuffer();
  for (final rune in s.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    final folded = _diacritics[ch] ?? ch;
    for (final part in folded.split('')) {
      if (part.codeUnitAt(0) >= 0x61 && part.codeUnitAt(0) <= 0x7A) {
        buffer.write(part);
      }
    }
  }
  return buffer.toString();
}

bool checkGuess(Puzzle puzzle, String guess) {
  final g = normalize(guess);
  return puzzle.answers.any((a) => normalize(a) == g);
}

String shareText(int number, int guessesUsed) {
  final squares = guessesUsed == 0
      ? '⬛⬛⬛'
      : '🟩' * guessesUsed + '⬛' * (3 - guessesUsed);
  final tail = guessesUsed == 0
      ? 'defeated by a sound law'
      : 'solved in $guessesUsed ${guessesUsed == 1 ? 'guess' : 'guesses'}';
  return 'Cognata #$number $squares\n$tail. Play the Daily Cognate — cognata.app/daily';
}

/// Build an Anki-importable TSV (front: foreign word, back: English + rule).
String buildAnkiExport(List<SoundLaw> laws, String pairId) {
  final rows = <String>[];
  for (final law in laws.where((l) => l.pair == pairId)) {
    for (final ex in law.examples) {
      rows.add('${ex.other}\t${ex.en} — rule: ${law.rule}');
    }
  }
  return rows.join('\n');
}
