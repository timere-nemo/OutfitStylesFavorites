# Addon: Outfit Styles Favorites

Extends the ESO Outfit Styles panel with a favorites system.

## Features

1. **"Show Favorites" checkbox** — placed on the same header row as "Show Locked"; filters the grid to favorited styles only
2. **Context menu** — right-click a style cell to add or remove it from favorites
3. **Visual highlight** — gold-star badge on favorited entries when the filter is off
4. **Persistent storage** — favorites stored account-wide per server via `ZO_SavedVars`

## File structure

```
OutfitStylesFavorites.lua   entry point — defines OutfitStylesFavorites global, registers EVENT_ADD_ON_LOADED
strings.lua                 SI_OSF_* IDs registered via ZO_CreateStringId (auto-allocated, English defaults)
lang/ru.lua                 Russian overrides via SafeAddString version 1
src/Favorites.lua           IsFavorite / AddFavorite / RemoveFavorite, SavedVars init
src/Filter.lua              RefreshVisible wrapper with AddEntry gating
src/Checkbox.lua            "Show Favorites" checkbox creation and layout
src/ContextMenu.lua         right-click menu injection via ZO_PostHook
src/Highlight.lua           separate CT_TEXTURE badge anchored TOPRIGHT; shown/hidden via ZO_PostHook
```

**Global and load order.** The global table is `OutfitStylesFavorites`. Every file uses `local OSF = OutfitStylesFavorites` as a local alias. `OutfitStylesFavorites.lua` must be listed first in the manifest so the global exists before sub-modules reference it. `strings.lua` and `lang/*` must load before any module that calls `GetString(...)`.


## Localization

`strings.lua` calls `ZO_CreateStringId("SI_OSF_SHOW_FAVORITES", "Show Favorites")` etc. This auto-allocates a numeric ID from ESO's custom-string pool and sets the English default — no hardcoded numbers.

`lang/ru.lua` overrides with `SafeAddString(SI_OSF_..., "...", 1)`. Version 1 > 0 (the implicit version from `ZO_CreateStringId`), so the override is applied correctly for Russian clients. The file returns early for non-Russian clients.

All UI code retrieves strings with `GetString(SI_OSF_*)`.

## styleKey

`collectibleData:GetId()` — integer collectible ID, account-wide stable.
Always guard against `clearAction` entries before calling `:GetId()`.

## Filtering approach — AddEntry gating

`ZO_OUTFIT_STYLES_PANEL_KEYBOARD.RefreshVisible` is replaced on the singleton instance. When `OSF.showFavorites` is true, the wrapper temporarily replaces `gridListPanelList.AddEntry` with a closure that drops non-favorites before they reach the grid. `AddEntry` is restored inside a `pcall` so it is always restored even if the base function errors.

**Why not `SetGridEntryVisibilityFunction`:** that API runs after `FillRowWithEmptyCells`, so the row-padding calculation is based on the unfiltered count and produces visual artifacts (extra empty squares at section boundaries).

**Why not hooking `FilterCollectible` directly:** it is a local closure rebuilt on every `RefreshVisible` call — not hookable by name.

Key behaviors of the gate:
- `clearAction` entries always pass (they have no collectible ID)
- Empty cells are added by `FillRowWithEmptyCells` via `ZO_ScrollList_AddOperation`, not via `AddEntry` — unaffected by the gate
- Type-0 (`NO_WEAPON_OR_ARMOR_TYPE`) entries skip the base game `FilterCollectible` but still pass through `AddEntry` and are gated correctly

`OSF.showFavorites` is session state (not persisted). It defaults to `false` on every login so the player never opens the panel to a silently filtered grid.

## Context menu hook — ZO_PostHook

`ZO_PostHook(ZO_OUTFIT_STYLES_PANEL_KEYBOARD, "OnOutfitStyleEntryRightClick", hookFunc)`.

The base handler calls `ClearMenu()`, `AddMenuItem()` × N, then `ShowMenu(self.control)`. Our hook fires after all of that. It appends the favorites item via `AddMenuItem` and calls `ShowMenu(panel.control)` again to redisplay the updated menu. `panel.control` is the same control the base passed to `ShowMenu`.

The hook guards `isEmptyCell` and `clearAction` before acting — matching the exact conditions the base function uses for its own items. It never touches `ShowMenu` globally.

## Visual highlight

A dedicated `CT_TEXTURE` badge (`control.osfFavoriteBadge`) is created once per pooled control and anchored to `TOPRIGHT` at `DL_OVERLAY`. It is entirely independent of `statusMultiIcon` — ESO's own status icons (eye, lock) occupy the `TOPLEFT` area and are unaffected. An applied favorite shows both the ESO eye indicator and the star simultaneously.

`ZO_PostHook` on `ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RefreshGridEntryMultiIcon` is used only as a refresh trigger. The hook does not touch `statusMultiIcon` or its icon set — it only calls `SetHidden` on `osfFavoriteBadge`. This avoids conflicts with `RefreshGridEntryMultiIcon`, which calls `ClearIcons()` and rebuilds the multi-icon on every refresh.

The badge is hidden by default on creation. Every refresh path explicitly sets its hidden state, so pooled controls carry no stale visibility. `SetMouseEnabled(false)` prevents the badge from intercepting mouse events on the cell.

Anchor offsets are chosen to visually align the badge with the eye icon: `statusMultiIcon` is 24×24 anchored `TOPLEFT` at `(3, 3)`, giving an eye center at `y=15`. A 20×20 badge needs `BADGE_INSET_Y=5` to match that center (`5+10=15`). `BADGE_INSET_X=3` mirrors the multi-icon's corner inset.

The hook skips entries when `OSF.showFavorites` is true (all visible entries are already favorites — the badge is redundant).

## Checkbox layout

Created via `CreateControlFromVirtual("OutfitStylesFavorites_ShowFavorites", panel.control, "ZO_CheckButton")`, anchored `LEFT` to `showLockedCheckBox RIGHT + dynamic_offset` on the same vertical baseline.

**Init (placeholder):** A conservative `ANCHOR_OFFSET` (130 px) is set immediately as a placeholder. `showLockedCheckBox` also receives a matching conservative label wrap (`ANCHOR_OFFSET - LABEL_GAP - VISUAL_GAP`) so it does not visually overflow before real coordinates are known.

**First show (`SCENE_FRAGMENT_SHOWING`):** The placeholder is replaced by a measured offset. This happens once, guarded by an `adjusted` flag:

1. `lockedTextWidth = GetStringWidthScaled(ZoFontGameBold, GetString(SI_RESTYLE_SHOW_LOCKED), 1, SPACE_INTERFACE)` — natural (untruncated) virtual-pixel width of the localized string.
2. `offset = LABEL_GAP(5) + lockedTextWidth + VISUAL_GAP(10)`
3. `ShowFavorites` is re-anchored with the measured offset.
4. Both label wraps are then set from the corrected on-screen positions: `showLockedCheckBox` wraps to the space between its button right and ShowFavorites left; ShowFavorites wraps to the space between its button right and `typeFilterControl` left.

**Why `GetStringWidthScaled` with `SPACE_INTERFACE`:** it returns virtual pixels directly, matching `SetWidth`/`GetLeft`/`GetRight`. `GetTextWidth()` is not used because it returns the width of the already-ellipsized text set by the conservative step-4 wrap, which would produce a too-narrow offset for long localized strings (e.g. Russian "Показывать заблокированное"). The physical-pixel variant would require manual `/ GetUIGlobalScale()` correction.

## Hook points

| Hook | Target | Method |
|---|---|---|
| Filter | `ZO_OUTFIT_STYLES_PANEL_KEYBOARD.RefreshVisible` | Direct replacement on the singleton |
| Context menu | `ZO_OUTFIT_STYLES_PANEL_KEYBOARD:OnOutfitStyleEntryRightClick` | `ZO_PostHook` |
| Highlight | `ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RefreshGridEntryMultiIcon` | `ZO_PostHook` |

## SavedVariables

```lua
ZO_SavedVars:NewAccountWide("OutfitStylesFavorites_SavedVars", 1, nil, { favorites = {} }, GetWorldName())
-- favorites = { [collectibleId (integer)] = true }
-- Keyed by display name (default) and world name (server) — NA/EU/PTS data is separate.
```

Account-wide is correct because outfit style unlocks are account-wide in ESO.

## ESO reference files

- `esoui/esoui/ingame/outfits/keyboard/outfitstylespanel_keyboard.lua` — panel logic, filter, context menu, entry setup
- `esoui/esoui/ingame/outfits/keyboard/outfitstylespanel_keyboard.xml` — control template, mouse handlers
- `esoui/esoui/ingame/outfits/outfit_manager.lua` — ShowLocked state, collectible lookups
- `esoui/esoui/libraries/zo_parametricgridlist/zo_abstractgridscrolllist.lua` — AddEntry, FillRowWithEmptyCells, CommitGridList
- `esoui/esoui/libraries/zo_templates/scrolltemplates.lua` — SetVisibilityFunction, IsDataVisible

## What to avoid

- Do not use `SetGridEntryVisibilityFunction` for favorites filtering — causes row-padding artifacts
- Do not replace or replicate `FilterCollectible` — it is a local closure in `RefreshVisible`; the gate operates after it
- Do not persist `showFavorites` — session-only by design
- Do not use `collectibleData:GetName()` or display names as keys — unstable
- Do not overwrite or wrap the global `ShowMenu` function — breaks all other addons using context menus
