import 'package:flutter/material.dart';

import 'src/app/app_shell.dart';
import 'src/core/record_store.dart';
import 'src/data/cognata_data.dart';
import 'src/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = await CognataData.load();
  runApp(CognataApp(data: data, store: RecordStore()));
}

class CognataApp extends StatelessWidget {
  const CognataApp({super.key, required this.data, required this.store});

  final CognataData data;
  final RecordStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognata — The Language Decryption Engine',
      debugShowCheckedModeBanner: false,
      theme: buildCognataTheme(),
      home: AppShell(data: data, store: store),
    );
  }
}
