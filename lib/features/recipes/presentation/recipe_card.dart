import 'package:flutter/material.dart';

import '../../../core/widgets/app_widgets.dart';
import '../domain/recipe.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isFavorite,
    required this.onOpen,
    required this.onFavorite,
    this.compact = false,
  });

  final Recipe recipe;
  final bool isFavorite;
  final VoidCallback onOpen;
  final VoidCallback onFavorite;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'recipe-image-${recipe.id}',
                    child: NetworkFoodImage(
                      url: recipe.imageUrl,
                      semanticLabel: recipe.title,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: colors.surface.withValues(alpha: .92),
                      shape: const CircleBorder(),
                      child: IconButton(
                        key: Key('favorite-${recipe.id}'),
                        tooltip: isFavorite
                            ? 'Remove from saved'
                            : 'Save recipe',
                        onPressed: onFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? colors.secondary
                              : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                  if (recipe.featured)
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            'EDITOR’S PICK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                compact ? 12 : 16,
                16,
                compact ? 14 : 18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${recipe.cuisine.toUpperCase()} · ${recipe.category.label.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    recipe.title,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16),
                      const SizedBox(width: 5),
                      Text('${recipe.totalMinutes} min'),
                      const SizedBox(width: 16),
                      const Icon(Icons.signal_cellular_alt, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          recipe.difficulty.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (recipe.ratingCount > 0) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: 3),
                        Text(recipe.ratingAverage.toStringAsFixed(1)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
