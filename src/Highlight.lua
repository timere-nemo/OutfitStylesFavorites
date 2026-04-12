OSF = OSF or {}

-- Highlight.lua
-- Adds a gold-star badge to the status multi-icon of favorited style cells when the
-- "Show Favorites" filter is OFF (i.e. all styles are visible and favorites need
-- visual distinction).  When the filter is ON every visible entry is already a
-- favorite, so the badge is redundant and skipped.
--
-- Hook: ZO_PostHook on RefreshGridEntryMultiIcon.
-- The base method calls ClearIcons() first, so our icon is always appended to a
-- clean state and never duplicated.  Controls are pooled and reused, so resetting
-- before applying is already guaranteed by the base call that precedes us.
--
-- Icon: the gold-star target-marker texture, rendered at the 24×24 size of the
-- status multi-icon control.

local FAVORITE_ICON = "EsoUI/Art/TargetMarkers/Target_Gold_Star_64.dds"

function OSF:InitializeHighlight()
    ZO_PostHook(ZO_OUTFIT_STYLES_PANEL_KEYBOARD, "RefreshGridEntryMultiIcon",
        function(_, control, data)
            -- Guard: skip pooled padding cells and the clear-slot entry.
            if not control.statusMultiIcon then return end
            if data.isEmptyCell or data.clearAction then return end
            -- When the favorites filter is active every visible entry is a favorite,
            -- so there is nothing extra to highlight.
            if OSF.showFavorites then return end

            if OSF:IsFavorite(data:GetId()) then
                control.statusMultiIcon:AddIcon(FAVORITE_ICON)
                control.statusMultiIcon:Show()
            end
        end
    )
end
