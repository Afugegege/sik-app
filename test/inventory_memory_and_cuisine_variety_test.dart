import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/models/fridge_item.dart';
import 'package:sik_app/models/mock_data.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/screens/fridge_screen.dart';
import 'package:sik_app/screens/profile_screen.dart';
import 'package:sik_app/services/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Inventory Persistence & Memory Tests', () {
    test('FridgeItem serializes and deserializes correctly', () {
      final item = FridgeItem(
        id: 'test_123',
        name: 'Irish Courgettes',
        location: StorageLocation.fridge,
        quantityMode: QuantityMode.exact,
        quantityDisplay: '2 pieces',
        status: 'Have',
      );

      final json = item.toJson();
      expect(json['id'], 'test_123');
      expect(json['name'], 'Irish Courgettes');
      expect(json['location'], 'fridge');
      expect(json['quantityMode'], 'exact');
      expect(json['quantityDisplay'], '2 pieces');

      final reconstructed = FridgeItem.fromJson(json);
      expect(reconstructed.id, item.id);
      expect(reconstructed.name, item.name);
      expect(reconstructed.location, item.location);
      expect(reconstructed.quantityDisplay, item.quantityDisplay);
      expect(reconstructed.status, item.status);
    });

    test('StorageService saves and restores fridge items across restarts', () async {
      final items = [
        FridgeItem(
          id: 'item_1',
          name: 'Butter',
          location: StorageLocation.fridge,
          quantityMode: QuantityMode.approximate,
          quantityDisplay: 'Plenty',
          status: 'Have',
        ),
        FridgeItem(
          id: 'item_2',
          name: 'Breaded Chicken Steak',
          location: StorageLocation.freezer,
          quantityMode: QuantityMode.approximate,
          quantityDisplay: '1 piece',
          status: 'Have',
        ),
      ];

      await StorageService.saveFridgeItems(items);
      final loaded = await StorageService.loadFridgeItems();
      expect(loaded, isNotNull);
      expect(loaded!.length, 2);
      expect(loaded[0].name, 'Butter');
      expect(loaded[1].name, 'Breaded Chicken Steak');
      expect(loaded[1].location, StorageLocation.freezer);
    });

    test('AppState restores saved inventory and syncs recipes', () async {
      final customItems = [
        FridgeItem(
          id: 'pork_1',
          name: 'Pork Loin Chop',
          location: StorageLocation.freezer,
          quantityMode: QuantityMode.exact,
          quantityDisplay: '2 pieces',
          status: 'Have',
        ),
        FridgeItem(
          id: 'butter_1',
          name: 'Butter',
          location: StorageLocation.fridge,
          quantityMode: QuantityMode.approximate,
          quantityDisplay: 'Plenty',
          status: 'Have',
        ),
      ];
      await StorageService.saveFridgeItems(customItems);

      final appState = AppState();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(appState.fridgeItems.length, 2);
      expect(appState.fridgeItems.any((i) => i.name == 'Pork Loin Chop'), isTrue);
      expect(appState.fridgeItems.any((i) => i.name == 'Butter'), isTrue);
    });

    test('AppState.clearInventory empties items and persists empty inventory', () async {
      final appState = AppState();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(appState.fridgeItems.isNotEmpty, isTrue);

      appState.clearInventory();
      expect(appState.fridgeItems.isEmpty, isTrue);
      expect(appState.recipes.isEmpty, isTrue);
      expect(appState.filteredRecipes.isEmpty, isTrue);

      // Verify persistent storage reflects empty list
      final persisted = await StorageService.loadFridgeItems();
      expect(persisted, isNotNull);
      expect(persisted!.isEmpty, isTrue);
    });

    test('AppState.resetInventoryToDefault restores sample items and persists', () async {
      final appState = AppState();
      await Future.delayed(const Duration(milliseconds: 50));
      appState.clearInventory();
      expect(appState.fridgeItems.isEmpty, isTrue);

      appState.resetInventoryToDefault();
      expect(appState.fridgeItems.length, MockData.seedFridgeItems.length);

      final persisted = await StorageService.loadFridgeItems();
      expect(persisted, isNotNull);
      expect(persisted!.length, MockData.seedFridgeItems.length);
    });
  });

  group('Cuisine Variety & Preferences Tests', () {
    test('MockData contains diverse global recipes (Western, Italian, Japanese, Asian Fusion)', () {
      expect(MockData.defaultCuisines.contains('Western & Italian'), isTrue);
      expect(MockData.defaultCuisines.contains('Chinese & Asian Fusion'), isTrue);
      expect(MockData.defaultCuisines.contains('Japanese'), isTrue);

      final titles = MockData.seedRecipes.map((r) => r.title).toList();
      expect(titles.any((t) => t.contains('Pork Chop')), isTrue);
      expect(titles.any((t) => t.contains('Chicken')), isTrue);
      expect(titles.any((t) => t.contains('Courgettes & Ham Noodles')), isTrue);
      expect(titles.any((t) => t.contains('Lao Gan Ma')), isTrue);
      expect(titles.any((t) => t.contains('Miso')), isTrue);
    });

    test('AppState.togglePreferredCuisine updates preferences and re-syncs recipes', () async {
      final appState = AppState();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(appState.preferredCuisines.contains('Mexican & Latin'), isFalse);
      appState.togglePreferredCuisine('Mexican & Latin');
      expect(appState.preferredCuisines.contains('Mexican & Latin'), isTrue);

      final saved = await StorageService.loadUserCuisines();
      expect(saved, isNotNull);
      expect(saved!.contains('Mexican & Latin'), isTrue);
    });
  });

  group('UI Clear and Delete Everything Tests', () {
    testWidgets('FridgeScreen header displays Delete Everything button and modal dialog', (tester) async {
      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: FridgeScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Delete Everything tooltip button
      final deleteBtnFinder = find.byTooltip('Delete Everything');
      expect(deleteBtnFinder, findsOneWidget);

      await tester.tap(deleteBtnFinder);
      await tester.pumpAndSettle();

      // Verify confirmation dialog shows
      expect(find.text('Delete Everything?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Confirm deletion
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Delete Everything');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Inventory should now be cleared
      expect(appState.fridgeItems.isEmpty, isTrue);
      expect(find.text('Your kitchen is completely empty'), findsOneWidget);
      expect(find.text('Load Sample Pantry'), findsOneWidget);
    });

    testWidgets('ProfileScreen shows Kitchen Data & Memory card with Clear All Data action', (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Kitchen Data & Memory'), findsOneWidget);
      expect(find.text('Clear All Data'), findsOneWidget);
      expect(find.text('Restore Defaults'), findsOneWidget);

      // Preferred cuisines chips should display global options
      expect(find.text('Western & Italian'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);
      expect(find.text('Chinese & Asian Fusion'), findsOneWidget);
    });
  });
}
