import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/recipe.dart';

class RecipeRepository {
  RecipeRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _recipes =>
      _firestore.collection('recipes');

  Stream<List<Recipe>> watchRecipesFor(String uid) {
    late StreamController<List<Recipe>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? publicSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? privateSub;
    var publicRecipes = <Recipe>[];
    var privateRecipes = <Recipe>[];

    void emit() {
      final byId = <String, Recipe>{
        for (final recipe in publicRecipes) recipe.id: recipe,
        for (final recipe in privateRecipes) recipe.id: recipe,
      };
      final recipes = byId.values.toList()
        ..sort((a, b) {
          final featured = (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0);
          if (featured != 0) return featured;
          return (b.createdAt ?? DateTime(2000)).compareTo(
            a.createdAt ?? DateTime(2000),
          );
        });
      if (!controller.isClosed) controller.add(recipes);
    }

    controller = StreamController<List<Recipe>>(
      onListen: () {
        publicSub = _recipes
            .where('visibility', isEqualTo: RecipeVisibility.public.name)
            .snapshots()
            .listen((snapshot) {
              publicRecipes = snapshot.docs.map(Recipe.fromDocument).toList();
              emit();
            }, onError: controller.addError);
        privateSub = _recipes
            .where('authorId', isEqualTo: uid)
            .snapshots()
            .listen((snapshot) {
              privateRecipes = snapshot.docs.map(Recipe.fromDocument).toList();
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await publicSub?.cancel();
        await privateSub?.cancel();
      },
    );
    return controller.stream;
  }

  Stream<Recipe?> watchRecipe(String recipeId) {
    return _recipes
        .doc(recipeId)
        .snapshots()
        .map(
          (document) => document.exists ? Recipe.fromDocument(document) : null,
        );
  }

  Stream<Set<String>> watchFavoriteIds(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  Future<void> toggleFavorite({
    required String uid,
    required String recipeId,
    required bool isFavorite,
  }) async {
    final reference = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(recipeId);
    if (isFavorite) {
      await reference.delete();
    } else {
      await reference.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  Future<String> createRecipe(Recipe recipe) async {
    final document = await _recipes.add(recipe.toFirestore(create: true));
    return document.id;
  }

  Future<void> updateRecipe(Recipe recipe) {
    return _recipes.doc(recipe.id).update(recipe.toFirestore());
  }

  Future<void> deleteRecipe(Recipe recipe) async {
    await _recipes.doc(recipe.id).delete();
    if (recipe.imageUrl.contains('firebasestorage.googleapis.com') ||
        recipe.imageUrl.contains('firebasestorage.app')) {
      try {
        await _storage.refFromURL(recipe.imageUrl).delete();
      } catch (_) {
        // The database deletion is authoritative. A missing image is harmless.
      }
    }
  }

  Future<String> uploadRecipeImage({
    required String uid,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    if (bytes.lengthInBytes > 8 * 1024 * 1024) {
      throw const FormatException('Images must be smaller than 8 MB.');
    }
    const allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};
    if (!allowedTypes.contains(contentType)) {
      throw const FormatException('Use a JPEG, PNG, or WebP image.');
    }
    final safeName = fileName
        .replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    final object = _storage.ref(
      'users/$uid/recipe_images/${DateTime.now().millisecondsSinceEpoch}_$safeName',
    );
    final upload = await object.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        cacheControl: 'public,max-age=31536000,immutable',
      ),
    );
    return upload.ref.getDownloadURL();
  }

  Stream<List<ShoppingItem>> watchShoppingItems(String uid) {
    return _shopping(uid).snapshots().map((snapshot) {
      final items = snapshot.docs.map(ShoppingItem.fromDocument).toList();
      items.sort((a, b) {
        final checked = (a.checked ? 1 : 0).compareTo(b.checked ? 1 : 0);
        if (checked != 0) return checked;
        final aisle = a.aisle.compareTo(b.aisle);
        return aisle != 0 ? aisle : a.name.compareTo(b.name);
      });
      return items;
    });
  }

  Future<void> addRecipeToShoppingList({
    required String uid,
    required Recipe recipe,
    required int servings,
  }) async {
    final batch = _firestore.batch();
    for (var index = 0; index < recipe.ingredients.length; index++) {
      final ingredient = recipe.ingredients[index];
      final document = _shopping(uid).doc('${recipe.id}_$index');
      batch.set(document, {
        'name': ingredient.name,
        'quantity': ingredient.quantityFor(recipe.servings, servings),
        'unit': ingredient.unit,
        'aisle': ingredient.aisle,
        'recipeId': recipe.id,
        'recipeTitle': recipe.title,
        'checked': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Future<void> setShoppingItemChecked(String uid, String itemId, bool checked) {
    return _shopping(uid).doc(itemId).update({'checked': checked});
  }

  Future<void> deleteShoppingItem(String uid, String itemId) {
    return _shopping(uid).doc(itemId).delete();
  }

  Future<void> clearCheckedShoppingItems(String uid) async {
    final checked = await _shopping(
      uid,
    ).where('checked', isEqualTo: true).get();
    final batch = _firestore.batch();
    for (final item in checked.docs) {
      batch.delete(item.reference);
    }
    await batch.commit();
  }

  Future<void> ensureUserProfile({
    required String uid,
    required String displayName,
    required String email,
    required String photoUrl,
  }) {
    return _firestore.collection('users').doc(uid).set({
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'lastSeenAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserData(String uid) async {
    final owned = await _recipes.where('authorId', isEqualTo: uid).get();
    for (final document in owned.docs) {
      await deleteRecipe(Recipe.fromDocument(document));
    }

    for (final collectionName in ['favorites', 'shoppingItems']) {
      final collection = _firestore
          .collection('users')
          .doc(uid)
          .collection(collectionName);
      while (true) {
        final page = await collection.limit(400).get();
        if (page.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final document in page.docs) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }
    }
    await _firestore.collection('users').doc(uid).delete();
  }

  CollectionReference<Map<String, dynamic>> _shopping(String uid) {
    return _firestore.collection('users').doc(uid).collection('shoppingItems');
  }
}
