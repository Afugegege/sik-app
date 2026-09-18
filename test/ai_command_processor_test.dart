import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/services/ai_command_processor.dart';
import 'package:sik_app/models/fridge_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Command Processor Natural Language Tests', () {
    testWidgets('Natural language list addition adds to inventory without filtering recipes', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                home: Scaffold(
                  body: Builder(
                    builder: (innerContext) {
                      return ElevatedButton(
                        onPressed: () async {
                          await AiCommandProcessor.processUserPrompt(
                            innerContext,
                            'i wanted to add a list of stuff: tofu, eggs, milk, kimchi',
                          );
                        },
                        child: const Text('Run'),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Verify initial recipe query is empty
      expect(appState.currentAiQuery, '');

      // Trigger the command
      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      // Crucial: currentAiQuery must NOT be set to the user prompt!
      expect(appState.currentAiQuery, '');

      // Switched to Fridge tab
      expect(appState.activeTabIndex, AppState.tabFridge);

      // Inventory items should now contain Tofu, Eggs, Milk, Kimchi
      final itemNames = appState.fridgeItems.map((e) => e.name).toList();
      expect(itemNames.contains('Tofu'), isTrue);
      expect(itemNames.contains('Eggs'), isTrue);
      expect(itemNames.contains('Milk'), isTrue);
      expect(itemNames.contains('Kimchi'), isTrue);
    });

    testWidgets('Quantity and location parsing for natural language addition', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AiCommandProcessor.processUserPrompt(
                        context,
                        'add 2 packs of tofu, 1 dozen eggs to fridge, and ice cream to freezer',
                      );
                    },
                    child: const Text('Run'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      final tofu = appState.fridgeItems.firstWhere((e) => e.name == 'Tofu');
      expect(tofu.quantityDisplay, '2 packs');
      expect(tofu.location, StorageLocation.fridge);

      final iceCream = appState.fridgeItems.firstWhere((e) => e.name.toLowerCase().contains('ice cream'));
      expect(iceCream.location, StorageLocation.freezer);
    });

    testWidgets('Natural language shopping list command', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AiCommandProcessor.processUserPrompt(
                        context,
                        'need to buy sesame oil and seaweed',
                      );
                    },
                    child: const Text('Run'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(appState.wantList.contains('Sesame Oil'), isTrue);
      expect(appState.wantList.contains('Seaweed'), isTrue);
    });

    testWidgets('View mode switching via natural language', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AiCommandProcessor.processUserPrompt(
                        context,
                        'switch to grid view',
                      );
                    },
                    child: const Text('Run'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(appState.isRecipeGridView, isTrue);
    });

    testWidgets('Genuine recipe search triggers recipe filter', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      await AiCommandProcessor.processUserPrompt(
                        context,
                        'kimchi soup',
                      );
                    },
                    child: const Text('Run'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(appState.currentAiQuery, 'kimchi soup');
      expect(appState.activeTabIndex, 0);
    });
  });
}
