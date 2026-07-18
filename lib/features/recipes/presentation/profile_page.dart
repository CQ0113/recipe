import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_widgets.dart';
import '../../auth/data/auth_service.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import 'recipe_form_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.user, required this.repository});

  final User user;
  final RecipeRepository repository;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppContent(
      maxWidth: 820,
      child: ListView(
        key: const PageStorageKey('profile'),
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 110),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundImage: user.photoURL == null
                    ? null
                    : NetworkImage(user.photoURL!),
                child: user.photoURL == null
                    ? Text(
                        (user.displayName ?? 'C').characters.first
                            .toUpperCase(),
                      )
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'Home cook',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email ?? '',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          FilledButton.icon(
            key: const Key('createRecipeButton'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    RecipeFormPage(user: user, repository: repository),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Create a recipe'),
          ),
          const SizedBox(height: 34),
          Text(
            'Your recipes',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Recipe>>(
            stream: repository.watchRecipesFor(user.uid),
            builder: (context, snapshot) {
              final owned =
                  snapshot.data
                      ?.where((recipe) => recipe.isOwnedBy(user.uid))
                      .toList() ??
                  const <Recipe>[];
              if (!snapshot.hasData) return const LinearProgressIndicator();
              if (owned.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Your private and community recipes will appear here.',
                    ),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (var index = 0; index < owned.length; index++) ...[
                      ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            owned[index].visibility == RecipeVisibility.private
                                ? Icons.lock_outline
                                : Icons.public,
                          ),
                        ),
                        title: Text(
                          owned[index].title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          owned[index].visibility == RecipeVisibility.private
                              ? 'Only you can see this'
                              : 'Visible to the community',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RecipeFormPage(
                              user: user,
                              repository: repository,
                              recipe: owned[index],
                            ),
                          ),
                        ),
                      ),
                      if (index != owned.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 34),
          Text(
            'Account & privacy',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Private by default'),
                  subtitle: Text(
                    'New recipes are visible only to you until you publish them.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  key: const Key('signOutButton'),
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: AuthService.signOut,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: colors.error,
                  ),
                  title: Text(
                    'Delete account',
                    style: TextStyle(color: colors.error),
                  ),
                  subtitle: const Text('Requires a recent Google sign-in.'),
                  onTap: () => _confirmAccountDeletion(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Savora 1.0.0 · Your personal lists and private recipes are protected by per-user Firebase rules.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAccountDeletion(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently removes your recipes, favorites, shopping list, uploaded images, and authentication account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthService.reauthenticateWithGoogle();
      await repository.deleteUserData(user.uid);
      await AuthService.deleteAccount();
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please sign out, sign back in, and try again. $error',
            ),
          ),
        );
      }
    }
  }
}
