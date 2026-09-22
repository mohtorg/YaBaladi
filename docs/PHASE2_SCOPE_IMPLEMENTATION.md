# Ya Baladi — Phase 2 Scope Implementation

## Scope model
`admin_profiles/{uid}.scope` now contains:
- `all`: unrestricted scope; intended for explicitly authorized moderators only.
- `governorateIds`: optional governorate constraints.
- `cityIds`: optional city constraints.
- `categoryIds`: optional category constraints.
- `groupIds`: optional place-group constraints.

Rules:
1. A moderator must have the requested permission.
2. `scope.all == true` permits the requested permission across the supported resource.
3. If `scope.all` is false, at least one scope dimension must be populated.
4. Every populated scope dimension is a constraint; the resource must match all populated dimensions.
5. An existing legacy moderator with no scope is therefore denied scoped writes rather than silently receiving nationwide access.
6. Super Admin (`request.auth.token.admin == true`) remains unrestricted.

## Protected operations in this phase
`places.write` is enforced against both the existing and new place document for update operations, and against the relevant document for create/delete.

`Place` now has an optional `groupId` so group-based scope has a canonical field for place records.

## UI
The Super Admin moderator editor now stores the scope values as comma-separated IDs for:
- governorates
- cities
- categories
- place groups
- or an explicit "All scopes" switch

## Verification
A Flutter test was added for scope serialization and legacy-profile default behavior.

The current execution environment does not contain the Flutter/Dart SDK, so `flutter analyze` and the Flutter test runner could not be executed here. No package upgrades were made.

The project itself was not changed on the user's Windows machine; this archive is the modified test-project package.
