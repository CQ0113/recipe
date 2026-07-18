import 'package:cloud_firestore/cloud_firestore.dart';

enum RecipeCategory {
  mains('Mains'),
  breakfast('Breakfast'),
  desserts('Desserts'),
  drinks('Drinks'),
  salads('Salads'),
  baking('Baking');

  const RecipeCategory(this.label);
  final String label;

  static RecipeCategory fromValue(String? value) {
    return RecipeCategory.values.firstWhere(
      (item) => item.name == value,
      orElse: () => RecipeCategory.mains,
    );
  }
}

enum RecipeDifficulty {
  easy('Easy'),
  medium('Medium'),
  advanced('Advanced');

  const RecipeDifficulty(this.label);
  final String label;

  static RecipeDifficulty fromValue(String? value) {
    return RecipeDifficulty.values.firstWhere(
      (item) => item.name == value,
      orElse: () => RecipeDifficulty.easy,
    );
  }
}

enum RecipeVisibility { public, private }

class Ingredient {
  const Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    this.aisle = 'Other',
  });

  final String name;
  final double quantity;
  final String unit;
  final String aisle;

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? '',
      aisle: map['aisle'] as String? ?? 'Other',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'quantity': quantity,
    'unit': unit.trim(),
    'aisle': aisle.trim().isEmpty ? 'Other' : aisle.trim(),
  };

  double quantityFor(int baseServings, int targetServings) {
    if (baseServings <= 0) return quantity;
    return quantity * targetServings / baseServings;
  }

  String displayQuantity(int baseServings, int targetServings) {
    final value = quantityFor(baseServings, targetServings);
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
    return unit.isEmpty ? '$formatted $name' : '$formatted $unit $name';
  }
}

class RecipeStep {
  const RecipeStep({
    required this.instruction,
    this.durationMinutes = 0,
    this.tip = '',
  });

  final String instruction;
  final int durationMinutes;
  final String tip;

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      instruction: map['instruction'] as String? ?? '',
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      tip: map['tip'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'instruction': instruction.trim(),
    'durationMinutes': durationMinutes,
    'tip': tip.trim(),
  };
}

class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.cuisine,
    required this.difficulty,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.servings,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.authorId,
    required this.authorName,
    required this.visibility,
    this.imageAttribution = '',
    this.isVegetarian = false,
    this.featured = false,
    this.tags = const [],
    this.allergens = const [],
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final RecipeCategory category;
  final String cuisine;
  final RecipeDifficulty difficulty;
  final int prepMinutes;
  final int cookMinutes;
  final int servings;
  final String imageUrl;
  final String imageAttribution;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final String authorId;
  final String authorName;
  final RecipeVisibility visibility;
  final bool isVegetarian;
  final bool featured;
  final List<String> tags;
  final List<String> allergens;
  final double ratingAverage;
  final int ratingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get totalMinutes => prepMinutes + cookMinutes;
  bool isOwnedBy(String uid) => authorId == uid;

  factory Recipe.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    return Recipe.fromMap(document.id, document.data() ?? const {});
  }

  factory Recipe.fromMap(String id, Map<String, dynamic> map) {
    return Recipe(
      id: id,
      title: map['title'] as String? ?? 'Untitled recipe',
      description: map['description'] as String? ?? '',
      category: RecipeCategory.fromValue(map['category'] as String?),
      cuisine: map['cuisine'] as String? ?? 'International',
      difficulty: RecipeDifficulty.fromValue(map['difficulty'] as String?),
      prepMinutes: (map['prepMinutes'] as num?)?.toInt() ?? 0,
      cookMinutes: (map['cookMinutes'] as num?)?.toInt() ?? 0,
      servings: (map['servings'] as num?)?.toInt().clamp(1, 99) ?? 1,
      imageUrl: map['imageUrl'] as String? ?? '',
      imageAttribution: map['imageAttribution'] as String? ?? '',
      ingredients: _maps(map['ingredients'])
          .map(Ingredient.fromMap)
          .where((item) => item.name.trim().isNotEmpty)
          .toList(growable: false),
      steps: _maps(map['steps'])
          .map(RecipeStep.fromMap)
          .where((step) => step.instruction.trim().isNotEmpty)
          .toList(growable: false),
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? 'Savora kitchen',
      visibility: map['visibility'] == 'private'
          ? RecipeVisibility.private
          : RecipeVisibility.public,
      isVegetarian: map['isVegetarian'] as bool? ?? false,
      featured: map['featured'] as bool? ?? false,
      tags: _strings(map['tags']),
      allergens: _strings(map['allergens']),
      ratingAverage: (map['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore({bool create = false}) => {
    'title': title.trim(),
    'description': description.trim(),
    'category': category.name,
    'cuisine': cuisine.trim(),
    'difficulty': difficulty.name,
    'prepMinutes': prepMinutes,
    'cookMinutes': cookMinutes,
    'servings': servings,
    'imageUrl': imageUrl.trim(),
    'imageAttribution': imageAttribution.trim(),
    'ingredients': ingredients.map((item) => item.toMap()).toList(),
    'steps': steps.map((step) => step.toMap()).toList(),
    'authorId': authorId,
    'authorName': authorName.trim(),
    'visibility': visibility.name,
    'isVegetarian': isVegetarian,
    'featured': featured,
    'tags': tags
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(),
    'allergens': allergens,
    'ratingAverage': ratingAverage,
    'ratingCount': ratingCount,
    if (create) 'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    RecipeCategory? category,
    String? cuisine,
    RecipeDifficulty? difficulty,
    int? prepMinutes,
    int? cookMinutes,
    int? servings,
    String? imageUrl,
    String? imageAttribution,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    String? authorId,
    String? authorName,
    RecipeVisibility? visibility,
    bool? isVegetarian,
    bool? featured,
    List<String>? tags,
    List<String>? allergens,
    double? ratingAverage,
    int? ratingCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      cuisine: cuisine ?? this.cuisine,
      difficulty: difficulty ?? this.difficulty,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      servings: servings ?? this.servings,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAttribution: imageAttribution ?? this.imageAttribution,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      visibility: visibility ?? this.visibility,
      isVegetarian: isVegetarian ?? this.isVegetarian,
      featured: featured ?? this.featured,
      tags: tags ?? this.tags,
      allergens: allergens ?? this.allergens,
      ratingAverage: ratingAverage ?? this.ratingAverage,
      ratingCount: ratingCount ?? this.ratingCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.aisle,
    required this.recipeTitle,
    required this.checked,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String aisle;
  final String recipeTitle;
  final bool checked;

  factory ShoppingItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final map = document.data() ?? const <String, dynamic>{};
    return ShoppingItem(
      id: document.id,
      name: map['name'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? '',
      aisle: map['aisle'] as String? ?? 'Other',
      recipeTitle: map['recipeTitle'] as String? ?? '',
      checked: map['checked'] as bool? ?? false,
    );
  }

  String get quantityLabel {
    final value = quantity == quantity.roundToDouble()
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    return unit.isEmpty ? value : '$value $unit';
  }
}

List<Map<String, dynamic>> _maps(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

List<String> _strings(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

DateTime? _date(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
