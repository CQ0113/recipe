import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_widgets.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import 'cooking_mode_page.dart';
import 'recipe_form_page.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({
    super.key,
    required this.user,
    required this.repository,
    required this.initialRecipe,
  });

  final User user;
  final RecipeRepository repository;
  final Recipe initialRecipe;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late int _servings;

  @override
  void initState() {
    super.initState();
    _servings = widget.initialRecipe.servings;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Recipe?>(
      stream: widget.repository.watchRecipe(widget.initialRecipe.id),
      initialData: widget.initialRecipe,
      builder: (context, snapshot) {
        final recipe = snapshot.data;
        if (recipe == null) {
          return const Scaffold(
            body: AsyncMessage(
              icon: Icons.no_meals_outlined,
              title: 'Recipe unavailable',
              message: 'It may have been removed by its author.',
            ),
          );
        }
        return StreamBuilder<Set<String>>(
          stream: widget.repository.watchFavoriteIds(widget.user.uid),
          builder: (context, favoriteSnapshot) {
            final favorite =
                favoriteSnapshot.data?.contains(recipe.id) ?? false;
            return _RecipeDetail(
              user: widget.user,
              repository: widget.repository,
              recipe: recipe,
              favorite: favorite,
              servings: _servings,
              onServings: (value) => setState(() => _servings = value),
            );
          },
        );
      },
    );
  }
}

class _RecipeDetail extends StatelessWidget {
  const _RecipeDetail({
    required this.user,
    required this.repository,
    required this.recipe,
    required this.favorite,
    required this.servings,
    required this.onServings,
  });

  final User user;
  final RecipeRepository repository;
  final Recipe recipe;
  final bool favorite;
  final int servings;
  final ValueChanged<int> onServings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final canEdit = recipe.isOwnedBy(user.uid);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe'),
        actions: [
          IconButton(
            tooltip: favorite ? 'Remove from saved' : 'Save recipe',
            onPressed: () => repository.toggleFavorite(
              uid: user.uid,
              recipeId: recipe.id,
              isFavorite: favorite,
            ),
            icon: Icon(favorite ? Icons.favorite : Icons.favorite_border),
          ),
          if (canEdit)
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeFormPage(
                        user: user,
                        repository: repository,
                        recipe: recipe,
                      ),
                    ),
                  );
                } else if (value == 'delete') {
                  await _confirmDelete(context);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit recipe')),
                PopupMenuItem(value: 'delete', child: Text('Delete recipe')),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppContent(
        maxWidth: 1120,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            width < 600 ? 16 : 28,
            8,
            width < 600 ? 16 : 28,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: AspectRatio(
                  aspectRatio: width < 600 ? 4 / 3 : 16 / 7,
                  child: Hero(
                    tag: 'recipe-image-${recipe.id}',
                    child: NetworkFoodImage(
                      url: recipe.imageUrl,
                      semanticLabel: recipe.title,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '${recipe.cuisine.toUpperCase()} · ${recipe.category.label.toUpperCase()}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                recipe.title,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 14),
              Text(
                recipe.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetaPill(
                    icon: Icons.schedule,
                    label: '${recipe.totalMinutes} minutes',
                  ),
                  _MetaPill(
                    icon: Icons.signal_cellular_alt,
                    label: recipe.difficulty.label,
                  ),
                  _MetaPill(
                    icon: Icons.restaurant,
                    label: '$servings servings',
                  ),
                  if (recipe.isVegetarian)
                    const _MetaPill(
                      icon: Icons.eco_outlined,
                      label: 'Vegetarian',
                    ),
                  if (recipe.ratingCount > 0)
                    _MetaPill(
                      icon: Icons.star_rounded,
                      label:
                          '${recipe.ratingAverage.toStringAsFixed(1)} (${recipe.ratingCount})',
                    ),
                ],
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final stack = constraints.maxWidth < 580;
                  final buttons = [
                    FilledButton.icon(
                      key: const Key('startCookingButton'),
                      onPressed: recipe.steps.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CookingModePage(recipe: recipe),
                              ),
                            ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start cooking'),
                    ),
                    OutlinedButton.icon(
                      key: const Key('addToShoppingButton'),
                      onPressed: () async {
                        await repository.addRecipeToShoppingList(
                          uid: user.uid,
                          recipe: recipe,
                          servings: servings,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Ingredients added to your shopping list.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.shopping_basket_outlined),
                      label: const Text('Add to shopping list'),
                    ),
                  ];
                  return stack
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buttons[0],
                            const SizedBox(height: 10),
                            buttons[1],
                          ],
                        )
                      : Row(
                          children: [
                            buttons[0],
                            const SizedBox(width: 12),
                            buttons[1],
                          ],
                        );
                },
              ),
              const SizedBox(height: 44),
              LayoutBuilder(
                builder: (context, constraints) {
                  final ingredients = _IngredientsSection(
                    recipe: recipe,
                    servings: servings,
                    onServings: onServings,
                  );
                  final method = _MethodSection(recipe: recipe);
                  if (constraints.maxWidth < 820) {
                    return Column(
                      children: [
                        ingredients,
                        const SizedBox(height: 42),
                        method,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth * .38,
                        child: ingredients,
                      ),
                      const SizedBox(width: 52),
                      Expanded(child: method),
                    ],
                  );
                },
              ),
              if (recipe.imageAttribution.isNotEmpty) ...[
                const SizedBox(height: 36),
                Text(
                  'Photo: ${recipe.imageAttribution}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this recipe?'),
        content: Text(
          '“${recipe.title}” and its uploaded image will be removed permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await repository.deleteRecipe(recipe);
      if (context.mounted) Navigator.of(context).pop();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete recipe: $error')),
        );
      }
    }
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: colors.primary),
            const SizedBox(width: 7),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _IngredientsSection extends StatelessWidget {
  const _IngredientsSection({
    required this.recipe,
    required this.servings,
    required this.onServings,
  });

  final Recipe recipe;
  final int servings;
  final ValueChanged<int> onServings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Ingredients',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            IconButton(
              tooltip: 'Decrease servings',
              onPressed: servings > 1 ? () => onServings(servings - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$servings',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            IconButton(
              tooltip: 'Increase servings',
              onPressed: servings < 24 ? () => onServings(servings + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final ingredient in recipe.ingredients)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ingredient.displayQuantity(recipe.servings, servings),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        if (recipe.allergens.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Contains: ${recipe.allergens.join(', ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _MethodSection extends StatelessWidget {
  const _MethodSection({required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Method', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        for (var index = 0; index < recipe.steps.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.steps[index].instruction,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (recipe.steps[index].durationMinutes > 0) ...[
                        const SizedBox(height: 7),
                        Text(
                          '${recipe.steps[index].durationMinutes} minute timer',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                      if (recipe.steps[index].tip.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Tip: ${recipe.steps[index].tip}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
