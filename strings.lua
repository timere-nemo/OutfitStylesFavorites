-- strings.lua
-- Defines SI_OSF_* string ID constants for use with GetString() and SafeAddString().
-- Numeric IDs are chosen well above ESO's generated range (~9718 as of current API)
-- to avoid collision with base-game strings.
-- Actual string values are registered in lang/en.lua (baseline) and
-- locale-specific overrides in lang/<locale>.lua.

SI_OSF_SHOW_FAVORITES  = 200001
SI_OSF_ADD_FAVORITE    = 200002
SI_OSF_REMOVE_FAVORITE = 200003
