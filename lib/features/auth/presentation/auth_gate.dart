import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/presentation/app_shell.dart';
import '../data/auth_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.initializationError});

  final Object? initializationError;

  @override
  Widget build(BuildContext context) {
    if (initializationError != null) {
      return Scaffold(
        body: AsyncMessage(
          icon: Icons.cloud_off_outlined,
          title: 'The kitchen could not connect',
          message:
              'Firebase initialization failed. Check the environment configuration and restart the app.\n\n$initializationError',
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        final user = snapshot.data;
        if (user == null) return const SignInPage();
        return _ProfileBootstrap(user: user);
      },
    );
  }
}

class _ProfileBootstrap extends StatefulWidget {
  const _ProfileBootstrap({required this.user});

  final User user;

  @override
  State<_ProfileBootstrap> createState() => _ProfileBootstrapState();
}

class _ProfileBootstrapState extends State<_ProfileBootstrap> {
  late final RecipeRepository _repository;
  late final Future<void> _profileFuture;

  @override
  void initState() {
    super.initState();
    _repository = RecipeRepository();
    _profileFuture = _repository.ensureUserProfile(
      uid: widget.user.uid,
      displayName: widget.user.displayName ?? 'Home cook',
      email: widget.user.email ?? '',
      photoUrl: widget.user.photoURL ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingView(label: 'Setting your table…'),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: AsyncMessage(
              icon: Icons.sync_problem_outlined,
              title: 'We could not prepare your profile',
              message: snapshot.error.toString(),
              action: FilledButton(
                onPressed: AuthService.signOut,
                child: const Text('Return to sign in'),
              ),
            ),
          );
        }
        return AppShell(user: widget.user, repository: _repository);
      },
    );
  }
}

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _working = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await AuthService.signInWithGoogle();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (MediaQuery.sizeOf(context).width >= 860)
              Expanded(
                flex: 6,
                child: Semantics(
                  image: true,
                  label: 'A table of colorful home-cooked dishes',
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const NetworkFoodImage(
                        url:
                            'https://images.unsplash.com/photo-1543353071-873f17a7a088?auto=format&fit=crop&w=1800&q=88',
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              AppColors.ink.withValues(alpha: .84),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Text(
                            'Good food starts\nwith a good plan.',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: Colors.white, height: 1.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              flex: 5,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(10),
                                child: Icon(
                                  Icons.soup_kitchen_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'SAVORA',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    letterSpacing: 2.2,
                                    color: colors.primary,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 46),
                        Text(
                          'Your everyday\ncooking companion.',
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Discover dependable recipes, turn ingredients into a shopping list, and cook one calm step at a time.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 34),
                        FilledButton.icon(
                          key: const Key('googleSignInButton'),
                          onPressed: _working ? null : _signIn,
                          icon: _working
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: const Text('Continue with Google'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Text(
                          'By continuing, you agree to keep your account and recipe data securely associated with your Google identity.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyAuthError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'popup-closed-by-user' ||
      'cancelled-popup-request' => 'Sign-in was cancelled.',
      'network-request-failed' => 'Check your connection and try again.',
      'account-exists-with-different-credential' =>
        'This email already uses a different sign-in method.',
      _ => error.message ?? 'Sign-in failed. Please try again.',
    };
  }
  return error.toString().replaceFirst('Exception: ', '');
}
