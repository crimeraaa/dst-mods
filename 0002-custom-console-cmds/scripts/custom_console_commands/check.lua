-- Namespace for ensuring correct usage of commands, be it from mod creator or user.
-- 
-- Some functions return the parameters themselves, fallback values, or use
-- their parameters to get return some other value (e.g. param was index into a table).
-- 
-- All functions have some error checking, but no rigid typechecking. 
-- The assumption is that if you pass in a wrong type, the function sometimes 
-- throws an error anyway.
local Check = {}

-- Checks if `player_number` is a valid player number in the current player list.
-- In other words, it needs to be non-zero and non-negative.
-- 
-- Note that this function has no fallback values of any kind.
---@param player_number integer
---@return table|nil player Player table itself if exists in `AllPlayers` table.
function Check:player(player_number)
    local player_count = #_G.AllPlayers
    local valid = (player_number > 0) and (player_number <= player_count)
    if not valid then
        CustomCmd.Util:printf("'%i' is outside the current player range!", player_number)
        if player_count == 0 then
            print("There are no players in the server to give items to.")
        elseif player_count == 1 then
            print("There is exactly 1 player in the server to give items to.")
        else
            CustomCmd.Util:printf("Valid player numbers are %i to %i.", 1, player_count)
        end
        return nil
    end
    return _G.AllPlayers[player_number]
end

-- Checks if the lowercase version `prefab` exists in `Prefabs` table.
-- 
---@param prefab string
---@return string|nil lower lowercase of `prefab` if exists in `Prefabs` table.
function Check:prefab(prefab)
    local lower = prefab:lower()
    if not _G.Prefabs[lower] then
        CustomCmd.Util:printf("'%s' is not a valid prefab name!", prefab)
        return nil
    end
    return lower
end

-- Checks `if count < 1`, because you can't give 0 or negative items to players. 
-- Falls back to `1` if `nil`. 
---@param item_count? integer If `nil`, defaults to `1`.
---@return integer|nil item_count Return `item_count` itself/fallback, or `nil`.
function Check:count(item_count)
    item_count = item_count or 1
    if item_count < 1 then
        CustomCmd.Util:printf("Cannot give %i items to players!", item_count)
        return nil
    end
    return item_count
end

-- Converts `tendency` to uppercase (or falls back to `"RIDER"`).
---@param tendency string
---@return string|nil upper Uppercase of `tendency` if exists in `TENDENCY` table.
function Check:tendency(tendency)
    tendency = tendency and tendency:upper() or "RIDER"
    local valid = _G.TENDENCY[tendency]
    if not valid then
        CustomCmd.Util:printf("Tendency '%s' is not valid! It must be one of:", tendency)
        for _, v in pairs(_G.TENDENCY) do
            CustomCmd.Util:printf("\"%s\"", v)
        end
        return nil
    end
    return valid
end

-- Converts `saddle` to lowercase (or falls back to `"saddle_race"`),
-- then checks if that's a valid prefab.
-- 
-- If `"saddle_"` isn't at the start of the string, it gets added.
-- 
-- This allows you just type `"basic"`, `"race"` and `"war"`.
---@param prefab string? If `nil`, defaults to `"saddle_race"`.
function Check:saddle(prefab)
    local lower = prefab and prefab:lower() or "saddle_race"
    -- Allow users to simply use "basic", "race" and "war".
    if not lower:find("^saddle_") then
        lower = "saddle_" .. lower
    end
    return self:prefab(lower)
end

return Check
