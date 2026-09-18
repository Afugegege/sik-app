import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/screens/explore_screen.dart';
import 'package:sik_app/widgets/explore_filters.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'OPENAI_API_KEY=mock_key');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createExploreScreen(AppState appState) {
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: const MaterialApp(
        home: Scaffold(
          body: ExploreScreen(),
        ),
      ),
    );
  }

  group('ExploreScreen Filter Collapse Tests', () {
    testWidgets('Filters are collapsed by default on main screen', (tester) async {
      final appState = AppState();
      await tester.pumpWidget(createExploreScreen(appState));
      await tester.pumpAndSettle();

      // Filter toggle button is visible
      expect(find.text('Filter & Sort'), findsOneWidget);
      expect(appState.isFilterExpanded, isFalse);

      // In collapsed default state, ExploreFilters does not render full categories
      final exploreFiltersFinder = find.byType(ExploreFilters);
      expect(
        find.descendant(of: exploreFiltersFinder, matching: find.text('Cook with what you have')),
        findsNothing,
      );
      expect(
        find.descendant(of: exploreFiltersFinder, matching: find.text('Almost there')),
        findsNothing,
      );
    });

    testWidgets('Tapping Filter button expands and collapses filters', (tester) async {
      final appState = AppState();
      await tester.pumpWidget(createExploreScreen(appState));
      await tester.pumpAndSettle();

      final exploreFiltersFinder = find.byType(ExploreFilters);

      // Tap Filter button to expand
      await tester.tap(find.text('Filter & Sort'));
      await tester.pumpAndSettle();

      expect(appState.isFilterExpanded, isTrue);
      // Category pills are now visible inside ExploreFilters
      expect(
        find.descendant(of: exploreFiltersFinder, matching: find.text('Cook with what you have')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: exploreFiltersFinder, matching: find.text('Almost there')),
        findsOneWidget,
      );

      // Tap Filter button again to collapse
      await tester.tap(find.text('Filter & Sort'));
      await tester.pumpAndSettle();

      expect(appState.isFilterExpanded, isFalse);
      expect(
        find.descendant(of: exploreFiltersFinder, matching: find.text('Cook with what you have')),
        findsNothing,
      );
    });

    testWidgets('Active filter shows clearable chip when collapsed', (tester) async {
      final appState = AppState();
      appState.setFilter('Cook with what you have');

      await tester.pumpWidget(createExploreScreen(appState));
      await tester.pumpAndSettle();

      // When collapsed with active filter, the active filter label is rendered in the pill
      expect(
        find.text('Cook with what you have'),
        findsOneWidget,
      );

      // Tap Clear to reset
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(appState.selectedFilter, 'All');
    });
  });
}
