import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/widgets/app_widgets.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';

class RecipeFormPage extends StatefulWidget {
  const RecipeFormPage({
    super.key,
    required this.user,
    required this.repository,
    this.recipe,
  });

  final User user;
  final RecipeRepository repository;
  final Recipe? recipe;

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _cuisine = TextEditingController(text: 'International');
  final _prep = TextEditingController(text: '15');
  final _cook = TextEditingController(text: '30');
  final _servings = TextEditingController(text: '4');
  final _imageUrl = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps = TextEditingController();
  final _tags = TextEditingController();
  RecipeCategory _category = RecipeCategory.mains;
  RecipeDifficulty _difficulty = RecipeDifficulty.easy;
  RecipeVisibility _visibility = RecipeVisibility.private;
  bool _vegetarian = false;
  bool _saving = false;
  bool _uploading = false;
  Uint8List? _previewBytes;

  bool get _editing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final recipe = widget.recipe;
    if (recipe != null) {
      _title.text = recipe.title;
      _description.text = recipe.description;
      _cuisine.text = recipe.cuisine;
      _prep.text = recipe.prepMinutes.toString();
      _cook.text = recipe.cookMinutes.toString();
      _servings.text = recipe.servings.toString();
      _imageUrl.text = recipe.imageUrl;
      _ingredients.text = recipe.ingredients
          .map(
            (item) =>
                '${item.quantity}|${item.unit}|${item.name}|${item.aisle}',
          )
          .join('\n');
      _steps.text = recipe.steps
          .map(
            (step) => '${step.durationMinutes}|${step.instruction}|${step.tip}',
          )
          .join('\n');
      _tags.text = recipe.tags.join(', ');
      _category = recipe.category;
      _difficulty = recipe.difficulty;
      _visibility = recipe.visibility;
      _vegetarian = recipe.isVegetarian;
    }
    _imageUrl.addListener(_refresh);
  }

  @override
  void dispose() {
    _imageUrl.removeListener(_refresh);
    for (final controller in [
      _title,
      _description,
      _cuisine,
      _prep,
      _cook,
      _servings,
      _imageUrl,
      _ingredients,
      _steps,
      _tags,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      _show('The selected image could not be read.');
      return;
    }
    final contentType = _contentType(file.extension);
    setState(() {
      _uploading = true;
      _previewBytes = bytes;
    });
    try {
      _imageUrl.text = await widget.repository.uploadRecipeImage(
        uid: widget.user.uid,
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
      );
      _show('Image uploaded securely.');
    } catch (error) {
      _show(error.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ingredients = _parseIngredients();
    final steps = _parseSteps();
    if (ingredients.isEmpty) {
      _show('Add at least one ingredient in the requested format.');
      return;
    }
    if (steps.isEmpty) {
      _show('Add at least one cooking step in the requested format.');
      return;
    }
    setState(() => _saving = true);
    final existing = widget.recipe;
    final recipe = Recipe(
      id: existing?.id ?? '',
      title: _title.text,
      description: _description.text,
      category: _category,
      cuisine: _cuisine.text,
      difficulty: _difficulty,
      prepMinutes: int.parse(_prep.text),
      cookMinutes: int.parse(_cook.text),
      servings: int.parse(_servings.text),
      imageUrl: _imageUrl.text,
      imageAttribution: existing?.imageAttribution ?? '',
      ingredients: ingredients,
      steps: steps,
      authorId: widget.user.uid,
      authorName: widget.user.displayName ?? 'Home cook',
      visibility: _visibility,
      isVegetarian: _vegetarian,
      featured: existing?.featured ?? false,
      tags: _tags.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .take(8)
          .toList(),
      allergens: existing?.allergens ?? const [],
      ratingAverage: existing?.ratingAverage ?? 0,
      ratingCount: existing?.ratingCount ?? 0,
      createdAt: existing?.createdAt,
      updatedAt: existing?.updatedAt,
    );
    try {
      if (_editing) {
        await widget.repository.updateRecipe(recipe);
      } else {
        await widget.repository.createRecipe(recipe);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      _show('Could not save recipe: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<Ingredient> _parseIngredients() {
    return _ingredients.text
        .split('\n')
        .map((line) {
          final parts = line.split('|').map((part) => part.trim()).toList();
          if (parts.length < 3) return null;
          final quantity = double.tryParse(parts[0]);
          if (quantity == null || quantity <= 0 || parts[2].length < 2) {
            return null;
          }
          return Ingredient(
            quantity: quantity,
            unit: parts[1],
            name: parts[2],
            aisle: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : 'Other',
          );
        })
        .whereType<Ingredient>()
        .toList(growable: false);
  }

  List<RecipeStep> _parseSteps() {
    return _steps.text
        .split('\n')
        .map((line) {
          final parts = line.split('|').map((part) => part.trim()).toList();
          if (parts.length < 2 || parts[1].length < 8) return null;
          return RecipeStep(
            durationMinutes: int.tryParse(parts[0]) ?? 0,
            instruction: parts[1],
            tip: parts.length > 2 ? parts.sublist(2).join(' | ') : '',
          );
        })
        .whereType<RecipeStep>()
        .toList(growable: false);
  }

  String _contentType(String? extension) => switch (extension?.toLowerCase()) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  String? _required(String? value, String label, {int minimum = 2}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required.';
    if (text.length < minimum) return 'Add a more useful $label.';
    return null;
  }

  String? _number(
    String? value,
    String label, {
    int minimum = 0,
    int maximum = 1440,
  }) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < minimum || number > maximum) {
      return '$label must be between $minimum and $maximum.';
    }
    return null;
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit recipe' : 'Create a recipe')),
      body: Form(
        key: _formKey,
        child: AppContent(
          maxWidth: 820,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
            children: [
              Text(
                _editing
                    ? 'Refine your recipe'
                    : 'Share something worth cooking',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Clear measurements and calm instructions make a dependable recipe.',
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'The dish',
                children: [
                  TextFormField(
                    controller: _title,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Recipe title',
                    ),
                    validator: (value) => _required(value, 'title', minimum: 3),
                  ),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Short description',
                    ),
                    validator: (value) =>
                        _required(value, 'description', minimum: 20),
                  ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final items = [
                        DropdownButtonFormField<RecipeCategory>(
                          initialValue: _category,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                          items: [
                            for (final value in RecipeCategory.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.label),
                              ),
                          ],
                          onChanged: (value) =>
                              setState(() => _category = value ?? _category),
                        ),
                        TextFormField(
                          controller: _cuisine,
                          decoration: const InputDecoration(
                            labelText: 'Cuisine',
                          ),
                          validator: (value) => _required(value, 'cuisine'),
                        ),
                      ];
                      return constraints.maxWidth < 560
                          ? Column(
                              children: [
                                items[0],
                                const SizedBox(height: 12),
                                items[1],
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: items[0]),
                                const SizedBox(width: 12),
                                Expanded(child: items[1]),
                              ],
                            );
                    },
                  ),
                  DropdownButtonFormField<RecipeDifficulty>(
                    initialValue: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: [
                      for (final value in RecipeDifficulty.values)
                        DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _difficulty = value ?? _difficulty),
                  ),
                  TextFormField(
                    controller: _tags,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      helperText:
                          'Comma separated — for example: quick, weeknight, spicy',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Vegetarian'),
                    value: _vegetarian,
                    onChanged: (value) => setState(() => _vegetarian = value),
                  ),
                ],
              ),
              _Section(
                title: 'Time & portions',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prep,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Prep minutes',
                          ),
                          validator: (value) => _number(value, 'Prep time'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cook,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cook minutes',
                          ),
                          validator: (value) => _number(value, 'Cook time'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _servings,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Servings',
                          ),
                          validator: (value) => _number(
                            value,
                            'Servings',
                            minimum: 1,
                            maximum: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _Section(
                title: 'Recipe photo',
                children: [
                  if (_previewBytes != null || _imageUrl.text.trim().isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 8,
                        child: _previewBytes != null
                            ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                            : NetworkFoodImage(url: _imageUrl.text.trim()),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _uploading ? null : _pickImage,
                    icon: _uploading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined),
                    label: Text(_uploading ? 'Uploading…' : 'Upload photo'),
                  ),
                  TextFormField(
                    controller: _imageUrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      helperText:
                          'Filled automatically after upload, or paste an HTTPS URL.',
                    ),
                    validator: (value) {
                      final required = _required(
                        value,
                        'image URL',
                        minimum: 8,
                      );
                      if (required != null) return required;
                      final uri = Uri.tryParse(value!.trim());
                      return uri?.scheme == 'https'
                          ? null
                          : 'Use a valid HTTPS image URL.';
                    },
                  ),
                ],
              ),
              _Section(
                title: 'Ingredients',
                subtitle: 'One per line: quantity | unit | ingredient | aisle',
                children: [
                  TextFormField(
                    controller: _ingredients,
                    minLines: 7,
                    maxLines: 14,
                    decoration: const InputDecoration(
                      hintText:
                          '2|tbsp|olive oil|Pantry\n400|g|tomatoes|Produce',
                    ),
                    validator: (value) =>
                        _required(value, 'ingredients', minimum: 8),
                  ),
                ],
              ),
              _Section(
                title: 'Method',
                subtitle:
                    'One per line: timer minutes | instruction | optional tip',
                children: [
                  TextFormField(
                    controller: _steps,
                    minLines: 8,
                    maxLines: 18,
                    decoration: const InputDecoration(
                      hintText:
                          '5|Warm the oil over medium heat.|The oil should shimmer, not smoke.\n0|Season and serve immediately.|',
                    ),
                    validator: (value) =>
                        _required(value, 'method', minimum: 12),
                  ),
                ],
              ),
              _Section(
                title: 'Visibility',
                children: [
                  SegmentedButton<RecipeVisibility>(
                    segments: const [
                      ButtonSegment(
                        value: RecipeVisibility.private,
                        icon: Icon(Icons.lock_outline),
                        label: Text('Only me'),
                      ),
                      ButtonSegment(
                        value: RecipeVisibility.public,
                        icon: Icon(Icons.public),
                        label: Text('Community'),
                      ),
                    ],
                    selected: {_visibility},
                    onSelectionChanged: (values) =>
                        setState(() => _visibility = values.first),
                  ),
                ],
              ),
              FilledButton.icon(
                key: const Key('saveRecipeButton'),
                onPressed: _saving || _uploading ? null : _save,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_editing ? 'Save changes' : 'Publish recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 14),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
