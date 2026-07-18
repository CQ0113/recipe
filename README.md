# Savora

Savora is a responsive Flutter recipe application built around the complete home-cooking journey: discover, save, shop, and cook. Firebase Authentication, Cloud Firestore, and Firebase Storage provide the production backend.

## Product capabilities

- Google authentication with a protected profile bootstrap
- Curated community recipes and private-by-default user recipes
- Responsive discovery, search, category, and vegetarian filtering
- Personal favorites stored under each user's document
- Structured ingredients with live serving conversion
- Generated, aisle-grouped shopping lists
- Guided cooking mode with per-step timers
- Recipe authoring, secure image uploads, editing, and deletion
- Light and dark themes, semantic labels, adaptive navigation, and resilient loading/error states
- Firebase Analytics, Performance Monitoring, Crashlytics, and App Check integration

## Architecture

```text
lib/
  core/                         Theme and shared widgets
  features/auth/               Authentication data and presentation
  features/recipes/domain/     Recipe, ingredient, step, and shopping models
  features/recipes/data/       Firestore and Storage repository
  features/recipes/presentation/
tool/                           Idempotent admin seed tooling
test/                           Unit and widget tests
```

Firebase access is isolated behind `RecipeRepository`; UI state stays local to the screen that owns it. Shared recipe content is separate from personal favorites, serving selection, and shopping state.

## Firebase setup

The configured project is `recipe-f6d5b`.

1. Enable Google in **Firebase Authentication → Sign-in method**.
2. Register the required Android SHA-1/SHA-256 fingerprints for `com.savora.app`.
3. Deploy the checked-in security policy:

```powershell
firebase deploy --only firestore:rules,firestore:indexes,storage --project recipe-f6d5b
```

4. Seed or refresh the curated catalogue:

```powershell
node tool/seed_recipes.mjs --project recipe-f6d5b
```

The seed is idempotent: it updates eight stable `savora_*` document IDs and does not delete user content.
Use `--verify-only` to validate the live documents, step arrays, and image endpoints without writing.

## Development

Copy `.env.example` to `.env`, then fill in the Firebase client configuration for the target environment. The local `.env` is ignored by Git and is supplied to Flutter at compile time; it is never bundled as a Flutter asset.

```powershell
Copy-Item .env.example .env
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=.env
```

To validate a release web build:

```powershell
flutter build web --release --dart-define-from-file=.env
```

For GitHub Actions, configure matching repository secrets for every Firebase variable in `.env.example`. `RECAPTCHA_SITE_KEY` may remain empty until App Check is enabled. Firebase client configuration is visible in compiled mobile/web clients by design; service-account JSON, signing passwords, and other administrator credentials must never be placed in Dart code or committed.

## Netlify deployment

Connect the GitHub repository to Netlify with `main` as the production branch. The checked-in `netlify.toml` installs Flutter, runs `tool/netlify_build.sh`, publishes `build/web`, and configures the SPA route fallback.

Add these variables under **Netlify → Project configuration → Environment variables** with the Builds scope:

- `FIREBASE_API_KEY`
- `FIREBASE_WEB_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_STORAGE_BUCKET`
- `RECAPTCHA_SITE_KEY` (optional until App Check is enforced)

Trigger a production deploy after saving the values. Do not upload the local `.env` file or place its values in `netlify.toml`.

## Security model

- Users can read public recipes and their own private recipes.
- Users can only create, edit, or delete recipes whose `authorId` matches their Firebase UID.
- Curated `system` recipes are read-only to clients.
- Favorites and shopping items are readable and writable only by their owner.
- Recipe uploads are user-scoped, authenticated, limited to JPEG/PNG/WebP, and capped below 8 MB.
- All unmatched Firestore and Storage paths are denied.

Rules are defined in [firestore.rules](firestore.rules) and [storage.rules](storage.rules).

## Release checklist

- Configure a private Android upload key in `android/key.properties`; never commit the key or passwords.
- Create separate Firebase projects for development, staging, and production before public distribution.
- Add store URLs for the privacy policy and terms before submission.
- Enable Firebase App Check enforcement after registering production builds.
- Supply `--dart-define=RECAPTCHA_SITE_KEY=...` for App Check on production web builds.
- Add Crashlytics/Performance Monitoring when mobile release credentials are available.
- Test Google authentication using release fingerprints on a physical Android or iOS device.

## Data note

The bundled catalogue is mocked editorial content intended for development and demonstration. Remote photography is attributed as Unsplash in recipe documents. Replace it with licensed production photography and detailed attribution before commercial publication.
