# Addon: Outfit Styles Favorites

Extends the ESO Outfit Styles panel with a favorites system.

## Features

1. **"Show Favorites" checkbox** — placed on the same header row as "Show Locked"; filters the grid to favorited styles only
2. **Context menu** — right-click a style cell to add or remove it from favorites
3. **Visual highlight** — gold-star badge on favorited entries when the filter is off
4. **Persistent storage** — favorites stored account-wide via `ZO_SavedVars`

## File structure

```
OutfitStylesFavorites.lua   entry point — defines OSF, registers EVENT_ADD_ON_LOADED
strings.lua                 SI_OSF_* string ID constants (200001–200003)
lang/en.lua                 English string values — baseline for all locales (version 0)
lang/ru.lua                 Russian string overrides (version 1, skipped for non-Russian clients)
src/Favorites.lua           IsFavorite / AddFavorite / RemoveFavorite, SavedVars init
src/Filter.lua              RefreshVisible wrapper with AddEntry gating
src/Checkbox.lua            "Show Favorites" checkbox creation and layout
src/ContextMenu.lua         right-click menu injection via ShowMenu trampoline
src/Highlight.lua           gold-star badge via PostHook on RefreshGridEntryMultiIcon
```

**Load order matters.** `OutfitStylesFavorites.lua` must be listed first in the manifest so `OSF = {}` exists before sub-modules define methods on it. Each sub-module also declares `OSF = OSF or {}` for safety. `strings.lua` and `lang/*` must be loaded before any module that calls `GetString(...)` (e.g. `Checkbox.lua`, `ContextMenu.lua`), so all `SI_OSF_*` string IDs are registered before use.


## Localization

`strings.lua` defines the `SI_OSF_*` integer constants (`SI_OSF_SHOW_FAVORITES`, `SI_OSF_ADD_FAVORITE`, `SI_OSF_REMOVE_FAVORITE`). Numeric IDs are chosen well above ESO's generated range to avoid collision.

`lang/en.lua` registers English values at version 0 via `SafeAddString` — this is the baseline for all locales.

`lang/ru.lua` registers Russian values at version 1. It returns early if `GetCVar("language.2") ~= "ru"`, so it is a no-op for non-Russian clients and the English baseline remains in effect.

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

## Context menu hook — ShowMenu trampoline

`OnOutfitStyleEntryRightClick` calls `ClearMenu()` at the start and `ShowMenu()` at the end. A pre-hook would have items wiped; a post-hook fires too late.

Instead, `ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp` (the global XML dispatcher) is wrapped. On a qualifying right-click it installs a one-shot replacement for the global `ShowMenu` that appends the favorites item and immediately restores `ShowMenu` before calling through.

The trampoline is only installed when the entry is a real, non-empty, non-clear collectible — which is the same condition under which the base function will actually call `ShowMenu`.

## Visual highlight

`ZO_PostHook` on `ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RefreshGridEntryMultiIcon`. The base method calls `ClearIcons()` first, so the star icon is always appended to a clean state. The hook skips entries when `OSF.showFavorites` is true (all visible entries are already favorites — highlighting is redundant).

## Checkbox layout

Created via `CreateControlFromVirtual("OSF_ShowFavorites", panel.control, "ZO_CheckButton")`, anchored `LEFT` to `showLockedCheckBox RIGHT + dynamic_offset` on the same vertical baseline.

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
| Context menu | `ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp` | Global function replacement (wraps original) |
| ShowMenu injection | Global `ShowMenu` | One-shot trampoline installed per right-click |
| Highlight | `ZO_OUTFIT_STYLES_PANEL_KEYBOARD:RefreshGridEntryMultiIcon` | `ZO_PostHook` |

## SavedVariables

```lua
ZO_SavedVars:NewAccountWide("OSF_SavedVars", 1, nil, { favorites = {} })
-- favorites = { [collectibleId (integer)] = true }
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
