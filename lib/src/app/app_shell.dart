import 'package:flutter/material.dart';

import '../core/record_store.dart';
import '../data/cognata_data.dart';
import '../pages/about_page.dart';
import '../pages/daily_page.dart';
import '../pages/home_page.dart';
import '../pages/matrix_page.dart';
import '../pages/origins_page.dart';
import '../pages/tree_page.dart';
import '../theme/app_theme.dart';
import 'app_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.data, required this.store});

  final CognataData data;
  final RecordStore store;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ValueNotifier<AppTab> _tab = ValueNotifier(AppTab.home);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      data: widget.data,
      store: widget.store,
      tab: _tab,
      child: ValueListenableBuilder<AppTab>(
        valueListenable: _tab,
        builder: (context, tab, _) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            return Scaffold(
              body: Column(
                children: [
                  _Header(
                    current: tab,
                    wide: wide,
                    onSelect: (t) => _tab.value = t,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: tab.index,
                      children: const [
                        HomePage(),
                        DailyPage(),
                        MatrixPage(),
                        TreePage(),
                        OriginsPage(),
                        AboutPage(),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: wide
                  ? null
                  : NavigationBar(
                      selectedIndex: tab.index,
                      onDestinationSelected: (i) =>
                          _tab.value = AppTab.values[i],
                      backgroundColor: CognataColors.card,
                      indicatorColor: CognataColors.paper,
                      labelBehavior:
                          NavigationDestinationLabelBehavior.onlyShowSelected,
                      height: 64,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          selectedIcon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.today_outlined),
                          selectedIcon: Icon(Icons.today),
                          label: 'Daily',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_outlined),
                          selectedIcon: Icon(Icons.grid_view),
                          label: 'Matrix',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.account_tree_outlined),
                          selectedIcon: Icon(Icons.account_tree),
                          label: 'Tree',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.terrain_outlined),
                          selectedIcon: Icon(Icons.terrain),
                          label: 'Origins',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.info_outline),
                          selectedIcon: Icon(Icons.info),
                          label: 'About',
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.current,
    required this.wide,
    required this.onSelect,
  });

  final AppTab current;
  final bool wide;
  final ValueChanged<AppTab> onSelect;

  static const _items = [
    (AppTab.daily, 'Daily Cognate'),
    (AppTab.matrix, 'Decryption Matrix'),
    (AppTab.tree, 'Kinship Tree'),
    (AppTab.origins, 'Origins'),
    (AppTab.about, 'About'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CognataColors.cream,
        border: Border(bottom: BorderSide(color: CognataColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: Row(
            children: [
              InkWell(
                onTap: () => onSelect(AppTab.home),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        'Cognata',
                        style: TextStyle(
                          fontFamily: CognataFonts.display,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: CognataColors.ink,
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: 10),
                        const Text(
                          'THE LANGUAGE CIPHER',
                          style: TextStyle(
                            fontSize: 9.5,
                            letterSpacing: 2.4,
                            color: CognataColors.faded,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (wide)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      child: Wrap(
                        spacing: 2,
                        children: [
                          for (final item in _items)
                            TextButton(
                              onPressed: () => onSelect(item.$1),
                              style: TextButton.styleFrom(
                                foregroundColor: current == item.$1
                                    ? CognataColors.accent
                                    : CognataColors.faded,
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: CognataFonts.body,
                                ),
                              ),
                              child: Text(item.$2),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
