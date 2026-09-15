import 'package:cognata/main.dart';
import 'package:cognata/src/core/models.dart';
import 'package:cognata/src/core/record_store.dart';
import 'package:cognata/src/data/cognata_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders the home page and navigates between tabs',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});

    final data = CognataData(
      laws: const [
        SoundLaw(
          id: 'x',
          pair: 'en-de',
          rule: 't→ss',
          ipa: 'ipa',
          title: 'Water law',
          explanation: 'explanation',
          unlocks: 42,
          examples: [],
        ),
      ],
      trees: const [
        FamilyTree(
          word: 'heart',
          proto: '*ḱērd (Proto-Indo-European)',
          gloss: 'the organ that beats',
          branches: [
            TreeBranch(lang: 'English', form: 'heart', note: 'root'),
          ],
        ),
      ],
      puzzles: const [
        Puzzle(
          id: 1,
          source: 'Latin',
          word: 'PISCIS',
          answers: ['fish'],
          hints: ['h1', 'h2', 'h3'],
          fact: 'fact',
        ),
      ],
    );

    await tester.pumpWidget(
      CognataApp(data: data, store: RecordStore()),
    );
    await tester.pump();

    expect(find.text('Cognata'), findsOneWidget);
    expect(find.textContaining('3,000 words'), findsOneWidget);
    expect(find.text('How the cipher works'), findsOneWidget);

    await tester.tap(find.text('Decryption Matrix').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Water law'), findsOneWidget);

    await tester.tap(find.text('Kinship Tree').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('heart'), findsWidgets);

    // Dispose the tree so periodic timers (cipher demo) are cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('daily page accepts a correct guess', (tester) async {
    tester.view.physicalSize = const Size(500, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});

    final data = CognataData(
      laws: const [],
      trees: const [],
      puzzles: const [
        Puzzle(
          id: 1,
          source: 'Latin',
          word: 'PISCIS',
          answers: ['fish'],
          hints: ['h1', 'h2', 'h3'],
          fact: 'A fact about fish.',
        ),
      ],
    );

    await tester.pumpWidget(
      CognataApp(data: data, store: RecordStore()),
    );
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pump(const Duration(milliseconds: 50));

    await tester.enterText(find.byType(TextField).first, 'fish');
    await tester.tap(find.text('Decrypt'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('🎉 Decrypted!'), findsOneWidget);
    expect(find.textContaining('The answer:'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
