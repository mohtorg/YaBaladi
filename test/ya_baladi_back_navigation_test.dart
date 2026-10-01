import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/navigation/ya_baladi_back_navigation.dart';

void main() {
  testWidgets('G2-007 pops a child route with normal back', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: YaBaladiBackNavigation(
          child: const Text('Parent'),
        ),
      ),
    );

    navigatorKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => const YaBaladiBackNavigation(
          child: Text('Child'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Child'), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(find.text('Parent'), findsOneWidget);
  });

  testWidgets('G2-007 keeps root route on back', (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const YaBaladiBackNavigation(
          isRoot: true,
          child: Text('Root'),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('G2-007 does not discard unsaved changes without approval',
      (tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    var confirmCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: YaBaladiBackNavigation(
          hasUnsavedChanges: true,
          onConfirmDiscard: () async {
            confirmCalls++;
            return false;
          },
          child: const Text('Edited'),
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(confirmCalls, 1);
    expect(find.text('Edited'), findsOneWidget);
  });
}
