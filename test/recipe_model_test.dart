import 'package:flutter_test/flutter_test.dart';
import 'package:savora/features/recipes/domain/recipe.dart';

void main() {
  group('Ingredient scaling', () {
    const ingredient = Ingredient(
      name: 'flour',
      quantity: 300,
      unit: 'g',
      aisle: 'Baking',
    );

    test('scales from base servings to target servings', () {
      expect(ingredient.quantityFor(4, 6), 450);
      expect(ingredient.displayQuantity(4, 6), '450 g flour');
    });

    test('formats fractional values cleanly', () {
      const egg = Ingredient(name: 'egg', quantity: 1, unit: '');
      expect(egg.displayQuantity(2, 3), '1.5 egg');
    });
  });

  group('Recipe model', () {
    test('parses a production recipe document', () {
      final recipe = Recipe.fromMap('test', {
        'title': 'Tomato pasta',
        'description':
            'A dependable weeknight pasta with a bright tomato sauce.',
        'category': 'mains',
        'cuisine': 'Italian',
        'difficulty': 'easy',
        'prepMinutes': 10,
        'cookMinutes': 20,
        'servings': 4,
        'imageUrl': 'https://example.com/pasta.jpg',
        'ingredients': [
          {'name': 'pasta', 'quantity': 400, 'unit': 'g', 'aisle': 'Pantry'},
        ],
        'steps': [
          {
            'instruction': 'Cook the pasta until al dente.',
            'durationMinutes': 10,
            'tip': '',
          },
        ],
        'authorId': 'system',
        'authorName': 'Savora kitchen',
        'visibility': 'public',
        'isVegetarian': true,
        'featured': true,
        'tags': ['quick'],
        'allergens': ['gluten'],
        'ratingAverage': 4.8,
        'ratingCount': 42,
      });

      expect(recipe.totalMinutes, 30);
      expect(recipe.category, RecipeCategory.mains);
      expect(recipe.steps.single.durationMinutes, 10);
      expect(recipe.isVegetarian, isTrue);
    });

    test('falls back safely for malformed optional values', () {
      final recipe = Recipe.fromMap('test', {
        'title': 'Fallback',
        'servings': 0,
        'ingredients': 'not-a-list',
        'steps': null,
      });

      expect(recipe.servings, 1);
      expect(recipe.ingredients, isEmpty);
      expect(recipe.steps, isEmpty);
    });
  });
}
