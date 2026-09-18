import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sik_app/models/fridge_item.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/widgets/quantity_scrubber_badge.dart';

void main() {
  testWidgets('QuantityScrubberBadge renders and opens quick stepper sheet on tap', (tester) async {
    final item = const FridgeItem(
      id: 'test_1',
      name: 'Milk',
      location: StorageLocation.fridge,
      quantityDisplay: '500 ml',
      status: 'Have',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuantityScrubberBadge(item: item),
            ),
          ),
        ),
      ),
    );

    // Verify quantity badge is rendered
    expect(find.text('500 ml'), findsOneWidget);

    // Tap badge to open quick stepper sheet
    await tester.tap(find.text('500 ml'));
    await tester.pumpAndSettle();

    // Verify sheet is displayed with stepper and tip
    expect(find.text('Quantity: Milk'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(find.textContaining('Pro-tip: Long press and drag'), findsOneWidget);

    // Tap '+' in quick stepper
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // 500 ml should step to 550 ml
    expect(find.text('550 ml'), findsOneWidget);
  });

  testWidgets('QuantityScrubberBadge long press activates HUD and horizontal drag changes value', (tester) async {
    final item = const FridgeItem(
      id: 'test_2',
      name: 'Eggs',
      location: StorageLocation.fridge,
      quantityDisplay: '6 pieces',
      status: 'Have',
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: QuantityScrubberBadge(item: item),
            ),
          ),
        ),
      ),
    );

    final badgeFinder = find.text('6 pieces');
    expect(badgeFinder, findsOneWidget);

    // Start a gesture at the badge
    final gesture = await tester.startGesture(tester.getCenter(badgeFinder));
    // Wait for long-press timeout (default kLongPressTimeout is 500ms)
    await tester.pump(const Duration(milliseconds: 600));

    // Magnifier HUD should appear
    expect(find.text('SLIDE ◄  ► TO ADJUST'), findsOneWidget);

    // Drag right by 60 pixels (should step up by at least 2 steps: 6 -> 7 -> 8 pieces)
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();

    expect(find.text('8 pieces'), findsWidgets);

    // Drag left by 80 pixels (should step down)
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();

    // Release gesture
    await gesture.up();
    await tester.pumpAndSettle();

    // HUD dismissed
    expect(find.text('SLIDE ◄  ► TO ADJUST'), findsNothing);
  });
}
