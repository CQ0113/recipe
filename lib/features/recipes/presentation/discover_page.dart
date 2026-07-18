import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import 'recipe_card.dart';
import 'recipe_detail_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({
    super.key,
    required this.user,
    required this.repository,
    this.savedOnly = false,
  });

  final User user;
  final RecipeRepository repository;
  final bool savedOnly;

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String _query = '';
  RecipeCategory? _category;
  bool _vegetarianOnly = false;
  late final Stream<List<Recipe>> _recipesStream;
  late final Stream<Set<String>> _favoritesStream;

  @override
  void initState() {
    super.initState();
    _recipesStream = widget.repository.watchRecipesFor(widget.user.uid);
    _favoritesStream = widget.repository.watchFavoriteIds(widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Recipe>>(
      stream: _recipesStream,
      builder: (context, recipesSnapshot) {
        if (recipesSnapshot.hasError) {
          return AsyncMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Recipes are unavailable',
            message: recipesSnapshot.error.toString(),
          );
        }
        if (!recipesSnapshot.hasData) return const LoadingView();

        return StreamBuilder<Set<String>>(
          stream: _favoritesStream,
          builder: (context, favoriteSnapshot) {
            final favorites = favoriteSnapshot.data ?? const <String>{};
            final filtered = recipesSnapshot.data!
                .where((recipe) {
                  final query = _query.trim().toLowerCase();
                  final matchesQuery =
                      query.isEmpty ||
                      recipe.title.toLowerCase().contains(query) ||
                      recipe.description.toLowerCase().contains(query) ||
                      recipe.tags.any(
                        (tag) => tag.toLowerCase().contains(query),
                      );
                  final matchesCategory =
                      _category == null || recipe.category == _category;
                  final matchesVegetarian =
                      !_vegetarianOnly || recipe.isVegetarian;
                  final matchesSaved =
                      !widget.savedOnly || favorites.contains(recipe.id);
                  return matchesQuery &&
                      matchesCategory &&
                      matchesVegetarian &&
                      matchesSaved;
                })
                .toList(growable: false);

            return _RecipeCollection(
              user: widget.user,
              repository: widget.repository,
              recipes: filtered,
              favorites: favorites,
              savedOnly: widget.savedOnly,
              query: _query,
              category: _category,
              vegetarianOnly: _vegetarianOnly,
              onQuery: (value) => setState(() => _query = value),
              onCategory: (value) => setState(() => _category = value),
              onVegetarian: (value) => setState(() => _vegetarianOnly = value),
            );
          },
        );
      },
    );
  }
}

class _RecipeCollection extends StatelessWidget {
  const _RecipeCollection({
    required this.user,
    required this.repository,
    required this.recipes,
    required this.favorites,
    required this.savedOnly,
    required this.query,
    required this.category,
    required this.vegetarianOnly,
    required this.onQuery,
    required this.onCategory,
    required this.onVegetarian,
  });

  final User user;
  final RecipeRepository repository;
  final List<Recipe> recipes;
  final Set<String> favorites;
  final bool savedOnly;
  final String query;
  final RecipeCategory? category;
  final bool vegetarianOnly;
  final ValueChanged<String> onQuery;
  final ValueChanged<RecipeCategory?> onCategory;
  final ValueChanged<bool> onVegetarian;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1320
        ? 4
        : width >= 900
        ? 3
        : width >= 600
        ? 2
        : 1;
    final ratio = columns == 1 ? 1.35 : .76;

    return CustomScrollView(
      key: PageStorageKey(savedOnly ? 'savedRecipes' : 'discoverRecipes'),
      slivers: [
        SliverToBoxAdapter(
          child: AppContent(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                width < 600 ? 18 : 32,
                28,
                width < 600 ? 18 : 32,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!savedOnly) ...[
                    _DiscoverHero(user: user),
                    const SizedBox(height: 30),
                  ] else ...[
                    Text(
                      'Saved recipes',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The dishes you want to come back to.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 26),
                  ],
                  TextField(
                    key: Key(
                      savedOnly ? 'savedSearchField' : 'recipeSearchField',
                    ),
                    onChanged: onQuery,
                    decoration: InputDecoration(
                      hintText: 'Search recipes, ingredients, or cuisines',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty ? null : const Icon(Icons.tune),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: category == null,
                          onSelected: (_) => onCategory(null),
                        ),
                        const SizedBox(width: 8),
                        for (final item in RecipeCategory.values) ...[
                          ChoiceChip(
                            label: Text(item.label),
                            selected: category == item,
                            onSelected: (_) => onCategory(item),
                          ),
                          const SizedBox(width: 8),
                        ],
                        FilterChip(
                          avatar: const Icon(Icons.eco_outlined, size: 17),
                          label: const Text('Vegetarian'),
                          selected: vegetarianOnly,
                          onSelected: onVegetarian,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          savedOnly
                              ? 'Your collection'
                              : 'Cook something memorable',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      Text('${recipes.length} recipes'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        if (recipes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: AsyncMessage(
              icon: savedOnly ? Icons.bookmark_border : Icons.search_off,
              title: savedOnly ? 'Your cookbook is ready' : 'No recipes found',
              message: savedOnly
                  ? 'Tap the heart on a recipe to keep it here.'
                  : 'Try a different search or clear a filter.',
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              width < 600 ? 18 : 32,
              4,
              width < 600 ? 18 : 32,
              110,
            ),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final recipe = recipes[index];
                final favorite = favorites.contains(recipe.id);
                return RecipeCard(
                  recipe: recipe,
                  isFavorite: favorite,
                  onOpen: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailPage(
                        user: user,
                        repository: repository,
                        initialRecipe: recipe,
                      ),
                    ),
                  ),
                  onFavorite: () => repository.toggleFavorite(
                    uid: user.uid,
                    recipeId: recipe.id,
                    isFavorite: favorite,
                  ),
                );
              }, childCount: recipes.length),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: ratio,
              ),
            ),
          ),
      ],
    );
  }
}

class _DiscoverHero extends StatelessWidget {
  const _DiscoverHero({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final firstName = (user.displayName ?? 'Cook').trim().split(' ').first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 28),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WELCOME BACK, ${firstName.toUpperCase()}',
                      style: const TextStyle(
                        color: Color(0xFFBED8C9),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'What are we\ncooking today?',
                      style: Theme.of(
                        context,
                      ).textTheme.displayMedium?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reliable recipes for real kitchens.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (constraints.maxWidth > 640)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: 142,
                    child: Icon(
                      Icons.restaurant_menu,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
