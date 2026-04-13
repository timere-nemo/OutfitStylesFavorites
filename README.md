# Outfit Styles Favorites

An Elder Scrolls Online addon that extends the Outfit Styles panel with a favorites system, letting you mark and filter styles you care about most.

## Features

- **Show Favorites checkbox** — placed on the same header row as "Show Locked"; filters the grid to favorited styles only
- **Context menu** — right-click any style cell to add or remove it from favorites
- **Gold-star badge** — favorited entries are marked with a star in the top-right corner of the cell; the ESO applied-style indicator (eye icon) remains unaffected and both can be visible at the same time
- **Account-wide persistence** — favorites are stored per account (not per character), matching how outfit style unlocks work in ESO

## Installation

1. Download the addon folder (`OutfitStylesFavorites`)
2. Place it in your ESO AddOns directory:
   - **Windows:** `Documents\Elder Scrolls Online\live\AddOns\`
3. Launch ESO and enable the addon in the AddOns menu (character select or in-game)

## Usage

1. Open the **Outfit** panel (default: `U` → Outfit tab or the Outfit Styles panel)
2. A **Show Favorites** checkbox appears on the header row next to "Show Locked"
3. Right-click any style cell and choose **Add to Favorites** or **Remove from Favorites**
4. Check **Show Favorites** to filter the grid to your favorited styles only
5. Uncheck it to return to the full list — favorited styles will have a gold star badge

## Localization

The addon ships with:

- **English** (default, all locales)
- **Russian** (auto-applied when the ESO client language is set to Russian)

All UI strings use `SafeAddString` so other locale files can override them without conflict.

## Notes

- Favorites are stored **account-wide** — shared across all characters on the account, which matches how outfit style unlocks work in ESO
- The "Show Favorites" filter is **session-only** — it always resets to off on login so you never open the panel to a silently filtered grid

## Development

See [CLAUDE.md](CLAUDE.md) for implementation details, hook strategies, and development guidelines.

## License

MIT — see [LICENSE](LICENSE)
