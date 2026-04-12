OSF = OSF or {}

-- Filter.lua
-- Wraps ZO_OutfitStylesPanel_Keyboard:RefreshVisible on the singleton instance.
-- When OSF.showFavorites is true, temporarily gates gridListPanelList:AddEntry so
-- that only favorited entries (and the clear-slot entry) are passed to the grid.
-- Because the gate runs before FillRowWithEmptyCells, row padding is always correct.

function OSF:InitializeFilter()
    local panel    = ZO_OUTFIT_STYLES_PANEL_KEYBOARD
    -- gridList is captured once here. ZO_OutfitStylesPanel_Keyboard sets
    -- gridListPanelList in InitializeGridListPanel and never reassigns it, so
    -- this reference stays valid for the lifetime of the session.
    local gridList = panel.gridListPanelList

    local originalRefreshVisible = panel.RefreshVisible

    panel.RefreshVisible = function(panelSelf, retainScrollPosition)
        -- When the favorites filter is inactive, delegate unchanged.
        if not OSF.showFavorites then
            return originalRefreshVisible(panelSelf, retainScrollPosition)
        end

        -- Install a gating closure on AddEntry for the duration of this call.
        -- Empty-cell entries added by FillRowWithEmptyCells bypass AddEntry entirely
        -- (they go through ZO_ScrollList_AddOperation directly), so they are unaffected.
        local originalAddEntry = gridList.AddEntry
        gridList.AddEntry = function(listSelf, data, ...)
            -- Always pass the clear-slot entry; it has no collectible ID.
            if data.clearAction then
                return originalAddEntry(listSelf, data, ...)
            end
            -- Drop entries that are not in the favorites set.
            if not OSF:IsFavorite(data:GetId()) then
                return
            end
            return originalAddEntry(listSelf, data, ...)
        end

        -- Use pcall so AddEntry is always restored even if the base function errors.
        -- error(err, 0) re-raises with level 0 so no new location is prepended;
        -- the original file:line info is already embedded in err by the time
        -- pcall captures it. The full stack trace is lost, but the message is not.
        local ok, err = pcall(originalRefreshVisible, panelSelf, retainScrollPosition)
        gridList.AddEntry = originalAddEntry

        if not ok then
            error(err, 0)
        end
    end
end
