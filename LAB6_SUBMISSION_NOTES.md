# Lab 6 Firebase Recipe App Notes

## Firestore Database Design

Collection: `recipes`

Each recipe is stored as one document with these fields:

- `title` (`string`): recipe name shown in lists and details.
- `category` (`string`): one of `desserts`, `mainCuisines`, `drinks`, or `breakfast`, used for filtering.
- `description` (`string`): complete recipe summary for the detail page.
- `reviews` (`string`): display text such as `170 Reviews`.
- `prepTime` (`string`): preparation duration.
- `cookTime` (`string`): cooking duration.
- `imageUrl` (`string`): remote image displayed in the app.
- `isVegetarian` (`boolean`): supports vegetarian filtering.
- `ingredients` (`array` of maps): each item has `quantity`, `unit`, and `name`.
- `isFavorite` (`boolean`): stores the favorite state.
- `servingSize` (`number`): stores the current serving multiplier.
- `createdAt` (`timestamp`): supports sorting by newest recipe.
- `updatedAt` (`timestamp`): records the latest edit.

This structure keeps all information required to display a recipe in one document, which makes listing, detail viewing, adding, editing, and deleting simple. Ingredients are embedded because they belong directly to one recipe and are usually loaded together with the recipe details.

## Completed Functionality

- Firebase is initialized in the app using `lib/firebase_options.dart`.
- Firebase Authentication is used for Google sign-in before opening the recipe manager.
- Recipes are stored in Cloud Firestore in the `recipes` collection.
- The app seeds starter recipes into Firestore if the collection is empty.
- Users can add, view, edit, and delete recipes.
- The recipe details page shows full recipe information and ingredients.
- Form validation checks required fields, meaningful text length, valid image URL, and at least one valid ingredient.
- The interface includes search, category filtering, vegetarian filtering, favorite toggling, and serving-size controls.
- Users can upload recipe images from their PC to Firebase Storage; the app stores the generated download URL in Firestore.

## Firebase Storage

Uploaded recipe images are stored in Firebase Storage under the `recipe_images/` folder. Firebase Storage must be enabled in the Firebase Console, and the Storage rules must allow authenticated users to upload and read recipe images.

For Flutter web, the Storage bucket also needs CORS configured so images can load from `localhost` during development. This project includes `storage.cors.json`; apply it with:

```sh
gsutil cors set storage.cors.json gs://recipe-f6d5b.firebasestorage.app
```

## Reflection

Integrating the recipe application with Firebase made the app more useful because recipe data is no longer limited to local memory. Cloud Firestore allows recipes to be saved permanently, loaded again after restarting the app, and synchronized across devices. Firebase Authentication also improves the app by allowing only signed-in users to access the recipe manager, which is closer to a real production application. Another advantage is that Firestore snapshots update the interface automatically when data changes, so the app feels responsive without needing manual refresh buttons.

The main challenge was changing the app from local sample data to a cloud database structure. Data must be converted between Dart models and Firestore documents, and every add, edit, or delete action must handle possible network or permission errors. Validation also becomes more important because incorrect data stored in Firestore can affect every future screen that reads it. Firebase setup requires careful configuration too, especially enabling Authentication providers, Cloud Firestore, and platform-specific app settings. Overall, Firebase adds powerful backend features, but it also requires good planning for database fields, rules, error handling, and testing.
