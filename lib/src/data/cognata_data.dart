import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/models.dart';

class LawPair {
  const LawPair(this.id, this.label);

  final String id;
  final String label;
}

class CognataData {
  const CognataData({
    required this.laws,
    required this.trees,
    required this.puzzles,
  });

  final List<SoundLaw> laws;
  final List<FamilyTree> trees;
  final List<Puzzle> puzzles;

  static const pairs = [
    LawPair('en-de', 'English ↔ German'),
    LawPair('en-es', 'English ↔ Spanish/Latin'),
  ];

  static Future<CognataData> load() async {
    final raw = await Future.wait([
      rootBundle.loadString('assets/data/soundLaws.json'),
      rootBundle.loadString('assets/data/familyTrees.json'),
      rootBundle.loadString('assets/data/puzzles.json'),
    ]);

    final lawsJson = jsonDecode(raw[0]) as List<dynamic>;
    final treesJson = jsonDecode(raw[1]) as List<dynamic>;
    final puzzlesJson = jsonDecode(raw[2]) as List<dynamic>;

    return CognataData(
      laws: lawsJson
          .map((e) => SoundLaw.fromJson(e as Map<String, dynamic>))
          .toList(),
      trees: treesJson
          .map((e) => FamilyTree.fromJson(e as Map<String, dynamic>))
          .toList(),
      puzzles: puzzlesJson
          .map((e) => Puzzle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
