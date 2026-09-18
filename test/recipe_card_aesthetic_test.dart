import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sik_app/models/recipe.dart';
import 'package:sik_app/providers/app_state.dart';
import 'package:sik_app/widgets/recipe_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(fileInput: 'OPENAI_API_KEY=mock_key');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testRecipe = Recipe(
    id: 'r_test',
    title: 'Kimchi Fried Rice with Soft Egg',
    koreanTitle: '김치볶음밥',
    imageUrl: '',
    cookingTimeMinutes: 15,
    cookingMethod: 'Stovetop',
    difficulty: 'Easy',
    kitchenMatchPercent: 95,
    category: 'Cook with what you have',
    ingredients: [
      RecipeIngredient(name: 'Aged Kimchi', amount: '1 cup', status: 'have'),
      RecipeIngredient(name: 'Cooked Jasmine Rice', amount: '2 cups', status: 'have'),
      RecipeIngredient(name: 'Egg', amount: '1 large', status: 'have'),
    ],
    cookingSteps: ['Cook step 1', 'Cook step 2'],
    isSaved: true,
  );

  Widget createWidgetUnderTest({required bool isGrid, double width = 390, double height = 800}) {
    final appState = AppState();
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: isGrid
                  ? GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      children: const [
                        RecipeCard(recipe: testRecipe, isGrid: true),
                      ],
                    )
                  : const RecipeCard(recipe: testRecipe, isGrid: false),
            ),
          ),
        ),
      ),
    );
  }

  group('RecipeCard Aesthetic Tests', () {
    testWidgets('Renders List View aesthetic card with centered title, Korean subtitle, and chips',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isGrid: false));
      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.text('Kimchi Fried Rice with Soft Egg'), findsOneWidget);

      // Verify Korean title and category are rendered
      expect(find.textContaining('김치볶음밥'), findsOneWidget);

      // Verify match percentage badge
      expect(find.text('95% Match'), findsOneWidget);

      // Verify specs chips
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('Stovetop'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('3 items'), findsOneWidget);

      // Verify no Flutter render overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders Grid View aesthetic card with middle-center aligned medallion, title, and specs',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(isGrid: true));
      await tester.pumpAndSettle();

      // Verify title is rendered
      expect(find.text('Kimchi Fried Rice with Soft Egg'), findsOneWidget);

      // Verify Korean title and category are rendered
      expect(find.textContaining('김치볶음밥'), findsOneWidget);

      // Verify match percentage badge
      expect(find.text('95%'), findsOneWidget);

      // Verify specs chip contains time & method
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('Stovetop'), findsOneWidget);

      // Verify no Flutter render overflow errors
      expect(tester.takeException(), isNull);
    });
  });
}
