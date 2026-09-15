import 'package:flutter/widgets.dart';

import '../core/record_store.dart';
import '../data/cognata_data.dart';

enum AppTab { home, daily, matrix, tree, origins, about }

class AppScope extends InheritedNotifier<ValueNotifier<AppTab>> {
  const AppScope({
    super.key,
    required this.data,
    required this.store,
    required ValueNotifier<AppTab> tab,
    required super.child,
  }) : super(notifier: tab);

  final CognataData data;
  final RecordStore store;

  AppTab get currentTab => notifier!.value;

  void go(AppTab tab) => notifier!.value = tab;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope.of() called outside an AppScope');
    return scope!;
  }

  @override
  bool updateShouldNotify(covariant AppScope oldWidget) =>
      data != oldWidget.data ||
      store != oldWidget.store ||
      notifier != oldWidget.notifier;
}
