import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:savora/core/theme/app_theme.dart';
import 'package:savora/features/recipes/domain/recipe.dart';
import 'package:savora/features/recipes/presentation/recipe_card.dart';

void main() {
  testWidgets('recipe card exposes core decision information', (tester) async {
    const recipe = Recipe(
      id: 'pasta',
      title: 'Roasted Tomato Pasta',
      description: 'A bright tomato pasta.',
      category: RecipeCategory.mains,
      cuisine: 'Italian',
      difficulty: RecipeDifficulty.easy,
      prepMinutes: 10,
      cookMinutes: 20,
      servings: 4,
      imageUrl: '',
      ingredients: [],
      steps: [],
      authorId: 'system',
      authorName: 'Savora kitchen',
      visibility: RecipeVisibility.public,
      ratingAverage: 4.8,
      ratingCount: 12,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 440,
            child: RecipeCard(
              recipe: recipe,
              isFavorite: false,
              onOpen: () {},
              onFavorite: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Roasted Tomato Pasta'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('Easy'), findsOneWidget);
    expect(find.byKey(const Key('favorite-pasta')), findsOneWidget);
  });
}
