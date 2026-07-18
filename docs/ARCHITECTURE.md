# Architecture decisions

## Data ownership

Public recipe content lives at `recipes/{recipeId}`. A recipe's `authorId`, not the client route, determines write ownership. Personal state is isolated below `users/{uid}`:

```text
users/{uid}/favorites/{recipeId}
users/{uid}/shoppingItems/{itemId}
```

Serving selection is transient UI state. It is intentionally never written to a shared recipe.

## Query strategy

The repository subscribes to two rule-compatible queries: public recipes by `visibility`, and owned recipes by `authorId`. It merges and deduplicates the streams by document ID. This prevents private content from leaking while avoiding a broad collection query that Firestore rules would reject.

## UI composition

`AppShell` owns the four persistent product destinations. Each feature screen owns its short-lived filter or workflow state. Domain parsing is defensive so a malformed optional field does not crash the entire catalogue.

## Deliberate boundaries

- Firebase SDK types are contained in domain factories and the repository.
- Authentication provider behavior is contained in `AuthService`.
- Admin catalogue seeding is never reachable from the client application.
- Curated recipe scoring and featured status cannot be modified by ordinary clients.

## Next scale threshold

The current repository-stream approach is appropriate for a small curated catalogue. At thousands of recipes, add server-side search, pagination, image derivatives, Cloud Functions for rating aggregates and account cleanup, and a dedicated state-management package for cache coordination.
