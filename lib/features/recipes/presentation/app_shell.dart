import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/recipe_repository.dart';
import 'discover_page.dart';
import 'profile_page.dart';
import 'recipe_form_page.dart';
import 'shopping_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.user, required this.repository});

  final User user;
  final RecipeRepository repository;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    DiscoverPage(user: widget.user, repository: widget.repository),
    DiscoverPage(
      user: widget.user,
      repository: widget.repository,
      savedOnly: true,
    ),
    ShoppingPage(user: widget.user, repository: widget.repository),
    ProfilePage(user: widget.user, repository: widget.repository),
  ];

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Discover',
    ),
    NavigationDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: 'Saved',
    ),
    NavigationDestination(
      icon: Icon(Icons.shopping_basket_outlined),
      selectedIcon: Icon(Icons.shopping_basket),
      label: 'Shop',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 980;
    final body = IndexedStack(index: _index, children: _pages);

    return Scaffold(
      body: SafeArea(
        child: desktop
            ? Row(
                children: [
                  NavigationRail(
                    extended: MediaQuery.sizeOf(context).width >= 1180,
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
                      child: MediaQuery.sizeOf(context).width >= 1180
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _BrandMark(),
                                const SizedBox(width: 12),
                                Text(
                                  'SAVORA',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: AppColors.herb,
                                        letterSpacing: 2,
                                      ),
                                ),
                              ],
                            )
                          : const _BrandMark(),
                    ),
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.explore_outlined),
                        selectedIcon: Icon(Icons.explore),
                        label: Text('Discover'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite_border),
                        selectedIcon: Icon(Icons.favorite),
                        label: Text('Saved'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.shopping_basket_outlined),
                        selectedIcon: Icon(Icons.shopping_basket),
                        label: Text('Shop'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        selectedIcon: Icon(Icons.person),
                        label: Text('Profile'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: _destinations,
            ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              key: const Key('newRecipeFab'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeFormPage(
                    user: widget.user,
                    repository: widget.repository,
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New recipe'),
            )
          : null,
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(13),
      ),
      child: const SizedBox.square(
        dimension: 42,
        child: Icon(Icons.soup_kitchen_outlined, color: Colors.white),
      ),
    );
  }
}
