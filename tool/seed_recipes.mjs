/**
 * Idempotently seeds curated Savora recipes through the Firestore REST API.
 *
 * Authentication order:
 *   1. GOOGLE_APPLICATION_CREDENTIALS
 *   2. Firebase CLI application-default credentials on Windows
 *
 * Usage: node tool/seed_recipes.mjs [--project recipe-f6d5b] [--dry-run]
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const projectFlag = process.argv.indexOf('--project');
const projectId = projectFlag >= 0 ? process.argv[projectFlag + 1] : 'recipe-f6d5b';
const dryRun = process.argv.includes('--dry-run');
const verifyOnly = process.argv.includes('--verify-only');

const recipes = [
  {
    id: 'savora_lemon_herb_chicken',
    title: 'One-pan lemon herb chicken',
    description: 'Golden chicken thighs, tender potatoes, and green beans roasted together with lemon, garlic, and plenty of herbs.',
    category: 'mains', cuisine: 'Mediterranean', difficulty: 'easy',
    prepMinutes: 15, cookMinutes: 40, servings: 4,
    imageUrl: 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: false, featured: true,
    tags: ['one-pan', 'weeknight', 'high-protein'], allergens: [],
    ratingAverage: 4.9, ratingCount: 184,
    ingredients: [
      ingredient('chicken thighs', 8, '', 'Meat'),
      ingredient('baby potatoes', 600, 'g', 'Produce'),
      ingredient('green beans', 250, 'g', 'Produce'),
      ingredient('lemon', 1, '', 'Produce'),
      ingredient('garlic cloves', 4, '', 'Produce'),
      ingredient('olive oil', 3, 'tbsp', 'Pantry'),
      ingredient('dried oregano', 1, 'tsp', 'Pantry'),
      ingredient('sea salt', 1, 'tsp', 'Pantry'),
    ],
    steps: [
      step('Heat the oven to 220°C. Halve the potatoes and toss them with half the oil, oregano, and salt in a large roasting tray.', 0, 'Put the cut sides down for deeper browning.'),
      step('Roast the potatoes until their edges begin to colour.', 15),
      step('Pat the chicken dry. Rub with the remaining oil, grated garlic, lemon zest, and a pinch of black pepper.', 0, 'Dry skin is the secret to a crisp finish.'),
      step('Nestle the chicken among the potatoes and roast until almost cooked through.', 20),
      step('Add the green beans and lemon wedges. Roast until the beans are tender and the chicken reaches 74°C at its thickest point.', 8),
      step('Rest for five minutes, spoon the tray juices over everything, and serve.', 5),
    ],
  },
  {
    id: 'savora_roasted_tomato_pasta',
    title: 'Roasted tomato & basil pasta',
    description: 'Jammy roasted tomatoes folded through silky pasta with basil, parmesan, and a bright splash of balsamic vinegar.',
    category: 'mains', cuisine: 'Italian', difficulty: 'easy',
    prepMinutes: 10, cookMinutes: 30, servings: 4,
    imageUrl: 'https://images.unsplash.com/photo-1473093295043-cdd812d0e601?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: true, featured: true,
    tags: ['pasta', 'weeknight', 'vegetarian'], allergens: ['gluten', 'dairy'],
    ratingAverage: 4.8, ratingCount: 132,
    ingredients: [
      ingredient('cherry tomatoes', 700, 'g', 'Produce'),
      ingredient('rigatoni', 400, 'g', 'Pantry'),
      ingredient('garlic cloves', 4, '', 'Produce'),
      ingredient('olive oil', 3, 'tbsp', 'Pantry'),
      ingredient('balsamic vinegar', 1, 'tbsp', 'Pantry'),
      ingredient('parmesan', 60, 'g', 'Dairy'),
      ingredient('fresh basil', 1, 'handful', 'Produce'),
    ],
    steps: [
      step('Heat the oven to 210°C. Add the tomatoes and lightly crushed garlic to a baking dish, then toss with olive oil, salt, and pepper.', 0),
      step('Roast until the tomatoes collapse and their juices turn glossy.', 25, 'A few dark edges add welcome sweetness.'),
      step('Meanwhile, boil the pasta in well-salted water until just shy of al dente.', 10),
      step('Reserve a mug of pasta water, then drain. Crush the roasted tomatoes with a fork and stir in the balsamic vinegar.', 0),
      step('Toss the pasta through the sauce with parmesan and enough pasta water to make it silky.', 2),
      step('Fold through torn basil, taste for seasoning, and finish with more parmesan.', 0),
    ],
  },
  {
    id: 'savora_coconut_laksa',
    title: 'Weeknight coconut laksa',
    description: 'A fragrant Malaysian-inspired coconut noodle soup with tofu, mushrooms, greens, and a lively lime finish.',
    category: 'mains', cuisine: 'Malaysian-inspired', difficulty: 'medium',
    prepMinutes: 20, cookMinutes: 25, servings: 4,
    imageUrl: 'https://images.unsplash.com/photo-1559314809-0d155014e29e?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: true, featured: true,
    tags: ['noodles', 'soup', 'spicy'], allergens: ['soy'],
    ratingAverage: 4.9, ratingCount: 96,
    ingredients: [
      ingredient('laksa paste', 4, 'tbsp', 'Pantry'),
      ingredient('coconut milk', 400, 'ml', 'Pantry'),
      ingredient('vegetable stock', 600, 'ml', 'Pantry'),
      ingredient('rice noodles', 300, 'g', 'Pantry'),
      ingredient('firm tofu', 300, 'g', 'Chilled'),
      ingredient('mushrooms', 200, 'g', 'Produce'),
      ingredient('pak choi', 2, '', 'Produce'),
      ingredient('lime', 1, '', 'Produce'),
      ingredient('bean sprouts', 120, 'g', 'Produce'),
    ],
    steps: [
      step('Prepare the noodles according to the packet, rinse under cool water, and divide between bowls.', 5),
      step('Fry the laksa paste in a splash of neutral oil until deeply fragrant.', 2, 'This wakes up the spices and removes any raw edge.'),
      step('Pour in the coconut milk and stock. Stir well and bring to a gentle simmer.', 5),
      step('Add the tofu and mushrooms and simmer until the mushrooms soften.', 8),
      step('Add the pak choi for the final two minutes, then season the broth with lime juice and salt.', 2),
      step('Ladle over the noodles and finish with bean sprouts and extra lime.', 0),
    ],
  },
  {
    id: 'savora_miso_salmon_bowl',
    title: 'Miso salmon rice bowl',
    description: 'Caramelised miso-glazed salmon with cucumber, edamame, and sesame rice for a balanced bowl with real weeknight speed.',
    category: 'mains', cuisine: 'Japanese-inspired', difficulty: 'easy',
    prepMinutes: 15, cookMinutes: 18, servings: 4,
    imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: false, featured: false,
    tags: ['rice-bowl', 'high-protein', 'quick'], allergens: ['fish', 'soy', 'sesame'],
    ratingAverage: 4.7, ratingCount: 88,
    ingredients: [
      ingredient('salmon fillets', 4, '', 'Seafood'),
      ingredient('white miso', 2, 'tbsp', 'Chilled'),
      ingredient('soy sauce', 1, 'tbsp', 'Pantry'),
      ingredient('honey', 1, 'tbsp', 'Pantry'),
      ingredient('cooked rice', 600, 'g', 'Pantry'),
      ingredient('cucumber', 1, '', 'Produce'),
      ingredient('shelled edamame', 200, 'g', 'Frozen'),
      ingredient('sesame seeds', 2, 'tsp', 'Pantry'),
    ],
    steps: [
      step('Heat the oven grill to high and line a tray. Mix the miso, soy sauce, and honey.', 0),
      step('Pat the salmon dry, coat the top with glaze, and place it skin-side down on the tray.', 0),
      step('Grill until caramelised and just cooked in the centre.', 9, 'The centre should flake but remain moist.'),
      step('Warm the rice and edamame. Thinly slice the cucumber.', 5),
      step('Divide rice between bowls, add cucumber and edamame, then top with salmon and sesame seeds.', 0),
    ],
  },
  {
    id: 'savora_apple_oats',
    title: 'Cinnamon apple overnight oats',
    description: 'Creamy overnight oats layered with cinnamon apples and toasted seeds—made ahead for an easier morning.',
    category: 'breakfast', cuisine: 'Modern', difficulty: 'easy',
    prepMinutes: 12, cookMinutes: 6, servings: 2,
    imageUrl: 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: true, featured: false,
    tags: ['make-ahead', 'breakfast', 'fibre-rich'], allergens: ['dairy'],
    ratingAverage: 4.6, ratingCount: 61,
    ingredients: [
      ingredient('rolled oats', 100, 'g', 'Pantry'),
      ingredient('milk', 240, 'ml', 'Dairy'),
      ingredient('Greek yogurt', 100, 'g', 'Dairy'),
      ingredient('apple', 1, '', 'Produce'),
      ingredient('maple syrup', 1, 'tbsp', 'Pantry'),
      ingredient('ground cinnamon', 1, 'tsp', 'Pantry'),
      ingredient('pumpkin seeds', 2, 'tbsp', 'Pantry'),
    ],
    steps: [
      step('Stir the oats, milk, yogurt, half the maple syrup, and half the cinnamon in a container.', 0),
      step('Cover and refrigerate until thick and creamy.', 480),
      step('Dice the apple and cook it with a splash of water, the remaining cinnamon, and maple syrup until just tender.', 6),
      step('Cool the apples, then layer them over the oats with pumpkin seeds.', 0),
    ],
  },
  {
    id: 'savora_strawberry_pavlova',
    title: 'Strawberry cloud pavlova',
    description: 'A crisp, marshmallow-centred pavlova finished with softly whipped cream, strawberries, and lemon zest.',
    category: 'desserts', cuisine: 'Australian', difficulty: 'advanced',
    prepMinutes: 25, cookMinutes: 75, servings: 8,
    imageUrl: 'https://images.unsplash.com/photo-1519915028121-7d3463d20b13?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: true, featured: false,
    tags: ['celebration', 'make-ahead', 'gluten-free'], allergens: ['egg', 'dairy'],
    ratingAverage: 4.9, ratingCount: 170,
    ingredients: [
      ingredient('egg whites', 4, '', 'Dairy'),
      ingredient('caster sugar', 220, 'g', 'Baking'),
      ingredient('cornstarch', 2, 'tsp', 'Baking'),
      ingredient('white vinegar', 1, 'tsp', 'Pantry'),
      ingredient('whipping cream', 300, 'ml', 'Dairy'),
      ingredient('strawberries', 350, 'g', 'Produce'),
      ingredient('lemon', 1, '', 'Produce'),
    ],
    steps: [
      step('Heat the oven to 150°C. Draw a 20 cm circle on baking paper and turn the paper pencil-side down.', 0),
      step('Whisk the egg whites to soft peaks, then add the sugar one spoonful at a time until thick and glossy.', 10, 'Rub a little mixture between your fingers; it should feel smooth, not grainy.'),
      step('Fold in the cornstarch and vinegar, then shape the meringue inside the circle with a shallow well in the centre.', 0),
      step('Lower the oven to 120°C and bake without opening the door.', 75),
      step('Turn off the oven and let the pavlova cool completely inside.', 120),
      step('Top with softly whipped cream, strawberries, and finely grated lemon zest just before serving.', 0),
    ],
  },
  {
    id: 'savora_mango_smoothie',
    title: 'Mango, lime & yogurt smoothie',
    description: 'A cold, creamy mango smoothie sharpened with lime and ginger for a bright breakfast or afternoon lift.',
    category: 'drinks', cuisine: 'Tropical', difficulty: 'easy',
    prepMinutes: 6, cookMinutes: 0, servings: 2,
    imageUrl: 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: true, featured: false,
    tags: ['quick', 'breakfast', 'no-cook'], allergens: ['dairy'],
    ratingAverage: 4.7, ratingCount: 74,
    ingredients: [
      ingredient('frozen mango', 300, 'g', 'Frozen'),
      ingredient('plain yogurt', 180, 'g', 'Dairy'),
      ingredient('milk', 180, 'ml', 'Dairy'),
      ingredient('lime', 1, '', 'Produce'),
      ingredient('fresh ginger', 1, 'tsp', 'Produce'),
      ingredient('honey', 1, 'tsp', 'Pantry'),
    ],
    steps: [
      step('Add the mango, yogurt, milk, lime juice, ginger, and honey to a blender.', 0),
      step('Blend until completely smooth, adding a splash more milk if needed.', 1),
      step('Taste for lime and sweetness, then pour into chilled glasses.', 0),
    ],
  },
  {
    id: 'savora_corn_avocado_salad',
    title: 'Charred corn & avocado salad',
    description: 'Sweet charred corn, creamy avocado, crisp lettuce, and a smoky lime dressing for a generous warm-weather salad.',
    category: 'salads', cuisine: 'Mexican-inspired', difficulty: 'easy',
    prepMinutes: 18, cookMinutes: 10, servings: 4,
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=1600&q=86',
    imageAttribution: 'Unsplash', isVegetarian: true, featured: false,
    tags: ['salad', 'summer', 'gluten-free'], allergens: [],
    ratingAverage: 4.8, ratingCount: 57,
    ingredients: [
      ingredient('corn cobs', 3, '', 'Produce'),
      ingredient('avocados', 2, '', 'Produce'),
      ingredient('romaine lettuce', 1, '', 'Produce'),
      ingredient('cherry tomatoes', 250, 'g', 'Produce'),
      ingredient('lime', 2, '', 'Produce'),
      ingredient('olive oil', 2, 'tbsp', 'Pantry'),
      ingredient('smoked paprika', 1, 'tsp', 'Pantry'),
      ingredient('fresh coriander', 1, 'handful', 'Produce'),
    ],
    steps: [
      step('Heat a dry frying pan or grill until very hot. Cook the corn, turning, until deeply charred in places.', 10),
      step('Whisk the lime juice, olive oil, smoked paprika, and a pinch of salt.', 0),
      step('Slice the kernels from the cobs. Chop the lettuce, halve the tomatoes, and dice the avocado.', 0),
      step('Toss everything gently with the dressing and coriander, then serve immediately.', 0, 'Add the avocado last so it keeps its shape.'),
    ],
  },
];

function ingredient(name, quantity, unit, aisle) {
  return { name, quantity, unit, aisle };
}

function step(instruction, durationMinutes = 0, tip = '') {
  return { instruction, durationMinutes, tip };
}

async function accessToken() {
  const cliConfig = path.join(os.homedir(), '.config', 'configstore', 'firebase-tools.json');
  if (fs.existsSync(cliConfig)) {
    const cli = JSON.parse(fs.readFileSync(cliConfig, 'utf8'));
    if (cli.tokens?.access_token && cli.tokens?.expires_at > Date.now() + 30_000) {
      return cli.tokens.access_token;
    }
  }

  const explicit = process.env.GOOGLE_APPLICATION_CREDENTIALS;
  let credentialPath = explicit;
  if (!credentialPath && process.platform === 'win32') {
    const firebaseDir = path.join(process.env.APPDATA ?? '', 'firebase');
    const candidates = fs.existsSync(firebaseDir)
      ? fs.readdirSync(firebaseDir).filter((name) => name.endsWith('_application_default_credentials.json'))
      : [];
    credentialPath = candidates.length ? path.join(firebaseDir, candidates[0]) : undefined;
  }
  if (!credentialPath && process.platform !== 'win32') {
    const candidate = path.join(os.homedir(), '.config', 'gcloud', 'application_default_credentials.json');
    if (fs.existsSync(candidate)) credentialPath = candidate;
  }
  if (!credentialPath || !fs.existsSync(credentialPath)) {
    throw new Error(
      'No active Firebase credential found. Run `firebase projects:list`, then rerun this seed.',
    );
  }
  const credential = JSON.parse(fs.readFileSync(credentialPath, 'utf8'));
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: credential.client_id,
      client_secret: credential.client_secret,
      refresh_token: credential.refresh_token,
      grant_type: 'refresh_token',
    }),
  });
  if (!response.ok) throw new Error(`OAuth refresh failed (${response.status}): ${await response.text()}`);
  return (await response.json()).access_token;
}

function firestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === 'boolean') return { booleanValue: value };
  if (typeof value === 'number') {
    return Number.isInteger(value) ? { integerValue: String(value) } : { doubleValue: value };
  }
  if (typeof value === 'string') return { stringValue: value };
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) return { arrayValue: { values: value.map(firestoreValue) } };
  return {
    mapValue: {
      fields: Object.fromEntries(Object.entries(value).map(([key, item]) => [key, firestoreValue(item)])),
    },
  };
}

async function seed() {
  console.log(
    `${dryRun ? 'Would seed' : verifyOnly ? 'Verifying' : 'Seeding'} ${recipes.length} curated recipes in ${projectId}.`,
  );
  if (dryRun) return;
  const token = await accessToken();
  const now = new Date();
  if (!verifyOnly) {
    for (const recipe of recipes) {
      const { id, ...data } = recipe;
      const fields = Object.fromEntries(
        Object.entries({
          ...data,
          authorId: 'system',
          authorName: 'Savora kitchen',
          visibility: 'public',
          seedVersion: 1,
          createdAt: now,
          updatedAt: now,
        }).map(([key, value]) => [key, firestoreValue(value)]),
      );
      const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/recipes/${id}`;
      const response = await fetch(url, {
        method: 'PATCH',
        headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' },
        body: JSON.stringify({ fields }),
      });
      if (!response.ok) throw new Error(`Failed to seed ${id} (${response.status}): ${await response.text()}`);
      console.log(`  ✓ wrote ${id}`);
    }
  }

  for (const recipe of recipes) {
    const url = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/recipes/${recipe.id}`;
    const response = await fetch(url, {
      headers: { authorization: `Bearer ${token}` },
    });
    if (!response.ok) throw new Error(`Missing seeded document ${recipe.id}`);
    const document = await response.json();
    const stepCount = document.fields?.steps?.arrayValue?.values?.length ?? 0;
    if (document.fields?.authorId?.stringValue !== 'system' || stepCount < 1) {
      throw new Error(`Seeded document ${recipe.id} failed schema verification.`);
    }
    const image = await fetch(recipe.imageUrl, { method: 'HEAD', redirect: 'follow' });
    if (!image.ok) throw new Error(`Image for ${recipe.id} returned HTTP ${image.status}`);
    console.log(`  ✓ verified ${recipe.id} (${stepCount} steps, image ${image.status})`);
  }
  console.log(verifyOnly ? 'Verification complete.' : 'Seed and verification complete.');
}

await seed();
