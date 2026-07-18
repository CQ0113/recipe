import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_widgets.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key, required this.user, required this.repository});

  final User user;
  final RecipeRepository repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShoppingItem>>(
      stream: repository.watchShoppingItems(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AsyncMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Shopping list unavailable',
            message: snapshot.error.toString(),
          );
        }
        if (!snapshot.hasData) return const LoadingView();
        final items = snapshot.data!;
        final grouped = <String, List<ShoppingItem>>{};
        for (final item in items) {
          grouped.putIfAbsent(item.aisle, () => []).add(item);
        }
        return AppContent(
          maxWidth: 820,
          child: CustomScrollView(
            key: const PageStorageKey('shoppingList'),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shopping list',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        items.isEmpty
                            ? 'Build your list straight from a recipe.'
                            : '${items.where((item) => item.checked).length} of ${items.length} items collected',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (items.any((item) => item.checked)) ...[
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () =>
                              repository.clearCheckedShoppingItems(user.uid),
                          icon: const Icon(Icons.cleaning_services_outlined),
                          label: const Text('Clear collected items'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AsyncMessage(
                    icon: Icons.shopping_basket_outlined,
                    title: 'Nothing to buy yet',
                    message: 'Open a recipe and choose “Add to shopping list”.',
                  ),
                )
              else
                for (final entry in grouped.entries) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Text(
                        entry.key.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final item = entry.value[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) =>
                            repository.deleteShoppingItem(user.uid, item.id),
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 28),
                          child: const Icon(Icons.delete_outline),
                        ),
                        child: CheckboxListTile(
                          key: Key('shopping-${item.id}'),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 3,
                          ),
                          value: item.checked,
                          onChanged: (value) =>
                              repository.setShoppingItemChecked(
                                user.uid,
                                item.id,
                                value ?? false,
                              ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: item.checked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            '${item.quantityLabel} · ${item.recipeTitle}',
                          ),
                          secondary: IconButton(
                            tooltip: 'Remove item',
                            onPressed: () => repository.deleteShoppingItem(
                              user.uid,
                              item.id,
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        );
      },
    );
  }
}
