# Addon: Outfit Styles Favorites

Extends the ESO Outfit Styles panel with a favorites system: checkbox filter, context menu, star badge, account-wide persistence.

## File structure

```
OutfitStylesFavorites.lua   entry point — defines OutfitStylesFavorites global, registers EVENT_ADD_ON_LOADED
strings.lua                 SI_OSF_* IDs via ZO_CreateStringId (auto-allocated, English defaults)
lang/ru.lua                 Russian overrides via SafeAddString version 1; early-return for non-ru clients
src/Favorites.lua           IsFavorite / AddFavorite / RemoveFavorite, SavedVars init
src/Filter.lua              ZO_PreHook on gridListPanelList.AddEntry — blocks non-favourites when filter is active
src/Checkbox.lua            "Show Favorites" checkbox, layout measured on first SCENE_FRAGMENT_SHOWING
src/ContextMenu.lua         right-click menu injection via ZO_PostHook on OnOutfitStyleEntryRightClick
src/Highlight.lua           CT_TEXTURE badge anchored TOPRIGHT; shown/hidden via ZO_PostHook on RefreshGridEntryMultiIcon
```

**Load order (manifest):** main file → strings.lua → lang/ru.lua → src/*.lua.

## Invariants — do not change

- **styleKey is `collectibleData:GetId()`** — integer collectible ID, account-wide stable. Never use display names or `GetName()` as keys.
- **`showFavorites` is session state, never persisted.** Defaults `false` on login so the grid is never silently filtered on open.
- **Filter uses `ZO_PreHook` on `gridListPanelList.AddEntry`**, not `SetGridEntryVisibilityFunction` (causes row-padding artifacts — `FillRowWithEmptyCells` runs on the unfiltered count) and not `FilterCollectible` (local closure rebuilt each `RefreshVisible` call, unhookable by name).
- **SavedVars are account-wide with `GetWorldName()` as profile** — separates NA/EU/PTS data. Key: `favorites = { [collectibleId (integer)] = true }`.
- **Context menu hook calls `ShowMenu(panel.control)` again** after `AddMenuItem` — the base handler calls `ShowMenu` first; our `ZO_PostHook` fires after and re-displays with our item appended. Do not wrap or replace the global `ShowMenu`.
- **Star badge (`control.osfFavoriteBadge`) is fully independent of `statusMultiIcon`** — anchored `TOPRIGHT` at `DL_OVERLAY`, `SetMouseEnabled(false)`. Never call `ClearIcons()` or touch `statusMultiIcon`.

## Change policy

- Prefer the smallest diff that achieves the goal — do not refactor working logic without a concrete reason.
- Keep the three approved hook points; do not switch hook strategy without re-verifying `FillRowWithEmptyCells` row-padding behavior.
- New feature: one file per concern, `local OSF = OutfitStylesFavorites` alias, init called from the main `EVENT_ADD_ON_LOADED` handler.

## Key behaviors

**Filter gate (`src/Filter.lua`):**
- Hook installed once at init; checks `OSF.showFavorites` at call time — no setup/teardown around each refresh. Toggle checkbox + call `RefreshVisible` is sufficient.
- `clearAction` entries always pass (no collectible ID). Empty padding cells come from `FillRowWithEmptyCells` via `ZO_ScrollList_AddOperation`, not `AddEntry` — unaffected by the gate.
- The context menu hook also guards `isEmptyCell` and `clearAction` before acting — matching the base function's own guards.

**Checkbox layout (`src/Checkbox.lua`):**
- Conservative placeholder offset set at creation; measured and replaced on first `SCENE_FRAGMENT_SHOWING` (guarded by `adjusted` flag).
- Use `GetStringWidthScaled(ZoFontGameBold, ..., 1, SPACE_INTERFACE)` for the "Show Locked" label width — returns virtual pixels directly. Do not use `GetTextWidth()`: it measures the already-ellipsized rendered text, producing a too-narrow offset for long locales (e.g. Russian).

**Highlight badge (`src/Highlight.lua`):**
- Badge hidden by default on creation; every refresh path sets `SetHidden` explicitly so pooled controls carry no stale visibility.
- Badge skipped entirely when `OSF.showFavorites` is true — all visible entries are already favorites, badge is redundant.
- Anchor offsets are intentionally chosen to align the badge with `statusMultiIcon`'s visual center — treat as deliberate, not arbitrary.

## Hook points

| Hook | Target | Method |
|---|---|---|
| Filter | `gridListPanelList.AddEntry` | `ZO_PreHook` |
| Context menu | `ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnOutfitStyleEntryRightClick` | `ZO_PostHook` |
| Highlight | `ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RefreshGridEntryMultiIcon` | `ZO_PostHook` |

## SavedVars

```lua
ZO_SavedVars:NewAccountWide("OutfitStylesFavorites_SavedVars", 1, nil, { favorites = {} }, GetWorldName())
```

Account-wide is correct — outfit style unlocks are account-wide in ESO. `GetWorldName()` as profile arg isolates NA/EU/PTS.

## ESO reference files

- `esoui/esoui/ingame/outfits/keyboard/outfitstylespanel_keyboard.lua` — panel logic, filter, context menu, entry setup
- `esoui/esoui/ingame/outfits/keyboard/outfitstylespanel_keyboard.xml` — control template, mouse handlers
- `esoui/esoui/ingame/outfits/outfit_manager.lua` — ShowLocked state, collectible lookups
- `esoui/esoui/libraries/zo_parametricgridlist/zo_abstractgridscrolllist.lua` — AddEntry, FillRowWithEmptyCells
- `esoui/esoui/libraries/zo_templates/scrolltemplates.lua` — SetVisibilityFunction, IsDataVisible
