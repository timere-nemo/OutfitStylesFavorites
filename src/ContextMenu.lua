OSF = OSF or {}

-- ContextMenu.lua
-- Injects "Add to Favorites" / "Remove from Favorites" into the right-click menu
-- for outfit style cells.
--
-- Hook strategy: ShowMenu trampoline
-- ------------------------------------
-- The base-game right-click handler (OnOutfitStyleEntryRightClick) calls:
--   1. ClearMenu()
--   2. AddMenuItem(...)  × N
--   3. ShowMenu(self.control)
--
-- A ZO_PreHook would have our items wiped by step 1.
-- A ZO_PostHook fires after step 3 — the menu is already displayed.
--
-- Instead, we wrap the global XML dispatcher
-- (ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp) and, on right-click,
-- install a one-shot replacement for ShowMenu that appends our item just before
-- the menu is actually shown.  The replacement restores ShowMenu before calling
-- through, so there is no risk of infinite recursion or dangling state.
--
-- Safety: the trampoline is only installed when we have verified that the entry
-- is a real, non-empty, non-clear collectible — the same condition under which
-- OnOutfitStyleEntryRightClick will call ShowMenu.  If the base function exits
-- early, ShowMenu is never called and our replacement is never reached; but that
-- branch cannot happen when the condition above holds.
--
-- Risk: if ESO adds an early-return path in OnOutfitStyleEntryRightClick that
-- bypasses ShowMenu for a non-empty, non-clear entry, the global ShowMenu would
-- remain replaced for the rest of the session.  This has not happened as of the
-- current API version but should be verified when the base function changes.

function OSF:InitializeContextMenu()
    local originalMouseUp = ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp

    ZO_OutfitStyle_GridEntry_Template_Keyboard_OnMouseUp = function(control, button, upInside)
        if upInside and button == MOUSE_BUTTON_INDEX_RIGHT then
            local entryData = control.dataEntry
            if entryData
                and entryData.data
                and not entryData.data.isEmptyCell
                and not entryData.data.clearAction
            then
                -- Capture the style key now; the closure in AddMenuItem will use it later.
                local styleKey    = entryData.data:GetId()
                local savedShowMenu = ShowMenu

                ShowMenu = function(owner, ...)
                    -- Restore before calling through to avoid any risk of recursion.
                    ShowMenu = savedShowMenu

                    if OSF:IsFavorite(styleKey) then
                        AddMenuItem(GetString(SI_OSF_REMOVE_FAVORITE), function()
                            OSF:RemoveFavorite(styleKey)
                        end)
                    else
                        AddMenuItem(GetString(SI_OSF_ADD_FAVORITE), function()
                            OSF:AddFavorite(styleKey)
                        end)
                    end

                    return savedShowMenu(owner, ...)
                end
            end
        end

        return originalMouseUp(control, button, upInside)
    end
end
