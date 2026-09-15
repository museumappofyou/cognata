class LawExample {
  const LawExample({required this.en, required this.other});

  final String en;
  final String other;

  factory LawExample.fromJson(Map<String, dynamic> json) => LawExample(
        en: json['en'] as String,
        other: json['other'] as String,
      );
}

class SoundLaw {
  const SoundLaw({
    required this.id,
    required this.pair,
    required this.rule,
    required this.ipa,
    required this.title,
    required this.explanation,
    required this.unlocks,
    required this.examples,
  });

  final String id;
  final String pair;
  final String rule;
  final String ipa;
  final String title;
  final String explanation;
  final int unlocks;
  final List<LawExample> examples;

  factory SoundLaw.fromJson(Map<String, dynamic> json) => SoundLaw(
        id: json['id'] as String,
        pair: json['pair'] as String,
        rule: json['rule'] as String,
        ipa: json['ipa'] as String,
        title: json['title'] as String,
        explanation: json['explanation'] as String,
        unlocks: json['unlocks'] as int,
        examples: (json['examples'] as List<dynamic>)
            .map((e) => LawExample.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class TreeBranch {
  const TreeBranch({required this.lang, required this.form, required this.note});

  final String lang;
  final String form;
  final String note;

  factory TreeBranch.fromJson(Map<String, dynamic> json) => TreeBranch(
        lang: json['lang'] as String,
        form: json['form'] as String,
        note: json['note'] as String,
      );
}

class FamilyTree {
  const FamilyTree({
    required this.word,
    required this.proto,
    required this.gloss,
    required this.branches,
  });

  final String word;
  final String proto;
  final String gloss;
  final List<TreeBranch> branches;

  factory FamilyTree.fromJson(Map<String, dynamic> json) => FamilyTree(
        word: json['word'] as String,
        proto: json['proto'] as String,
        gloss: json['gloss'] as String,
        branches: (json['branches'] as List<dynamic>)
            .map((e) => TreeBranch.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Puzzle {
  const Puzzle({
    required this.id,
    required this.source,
    required this.word,
    required this.answers,
    required this.hints,
    required this.fact,
  });

  final int id;
  final String source;
  final String word;
  final List<String> answers;
  final List<String> hints;
  final String fact;

  factory Puzzle.fromJson(Map<String, dynamic> json) => Puzzle(
        id: json['id'] as int,
        source: json['source'] as String,
        word: json['word'] as String,
        answers: (json['answers'] as List<dynamic>).cast<String>(),
        hints: (json['hints'] as List<dynamic>).cast<String>(),
        fact: json['fact'] as String,
      );
}

class DailyRecord {
  const DailyRecord({
    required this.lastPlayed,
    required this.streak,
    required this.results,
  });

  final String lastPlayed;
  final int streak;
  final Map<String, int> results;

  static const empty = DailyRecord(lastPlayed: '', streak: 0, results: {});

  factory DailyRecord.fromJson(Map<String, dynamic> json) => DailyRecord(
        lastPlayed: json['lastPlayed'] as String? ?? '',
        streak: json['streak'] as int? ?? 0,
        results: (json['results'] as Map<String, dynamic>? ?? {})
            .map((key, value) => MapEntry(key, value as int)),
      );

  Map<String, dynamic> toJson() => {
        'lastPlayed': lastPlayed,
        'streak': streak,
        'results': results,
      };
}
