# Changelog

## [1.1.1] - 2026-04-14

### Changed

- Added `## AddOnVersion` field to the manifest to enable update detection in Minion and compatible addon managers

## [1.1.0] - 2026-04-13

### Fixed

- **Global namespace** — addon table renamed from `OSF` to `OutfitStylesFavorites` to meet ESOUI uniqueness requirements
- **String IDs** — replaced hardcoded numeric constants with `ZO_CreateStringId`, which auto-allocates IDs from ESO's custom-string pool and eliminates collision risk
- **SavedVariables** — renamed from `OSF_SavedVars` to `OutfitStylesFavorites_SavedVars`; added `GetWorldName()` so favorites are stored separately per server (NA, EU, PTS)
- **Context menu** — replaced the `ShowMenu` global trampoline with `ZO_PostHook` on `OnOutfitStyleEntryRightClick`; the global `ShowMenu` function is no longer modified, fixing compatibility with all other addons that use context menus anywhere in the UI
- **Control name** — checkbox control renamed from `OSF_ShowFavorites` to `OutfitStylesFavorites_ShowFavorites` to avoid global name collisions

### Note

Existing favorites are not migrated from v1.0.x due to the SavedVariables rename and the addition of server separation. Favorites will need to be re-added after updating.

## [1.0.1] - 2026-04-13

### Fixed

- Favorite star no longer disappears when a style is applied — the badge is now a separate texture anchored to the top-right corner of the cell, independent of the ESO status icon area; both indicators are visible simultaneously when a style is both applied and favorited

## [1.0.0] - 2026-04-12

Initial release.

### Added

- "Show Favorites" checkbox in the Outfit Styles panel header, placed on the same row as "Show Locked"
- Right-click context menu items to add or remove a style from favorites
- Gold-star badge on favorited style cells when the favorites filter is off
- Account-wide persistent storage via `ZO_SavedVars`
- English and Russian localizations
