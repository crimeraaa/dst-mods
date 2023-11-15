---@diagnostic disable: duplicate-set-field
-- Contains some helper functions/methods that are somewhat common when it comes
-- to determining if mod creator's input or user's input is valid.
-- 
-- Stuff like determining if the player number is in range, if beefalo tendency
-- is valid, etc. etc.
CustomCmd = {}

-- Almost a C-style printf, but it does append newlines always since we can't
-- access `io.stdout.write` from DST.
---@param fmt string String literal or C-style format string.
---@param ... string|number Arguments to C-style format string, if any.
function CustomCmd:printf(fmt, ...)
    print(fmt:format(...))
end

---@param usage UsageString
function CustomCmd:print_usage(usage)
    -- Messy here, but nicer printing
    CustomCmd:printf([[syntax: %s
    Note that parameters enclosed in angled brackets, e.g. <prefab> are required.
    Parameters enclosed in square brackets, e.g. [tendency] are optional.]], 
        usage.syntax
    )
    -- The multi-string literals have newlines appended already
    CustomCmd:printf("params:\n%s", usage.params)
    CustomCmd:printf("sample:\n%s", usage.sample)
    CustomCmd:printf("return:\n%s", usage.retval or "   (none)")
end

-- Checks if `player_number` is a valid player number in the current player list.
-- 
-- In other words, it needs to be non-zero and non-negative.
---@param player_number integer
function CustomCmd:valid_player(player_number)
    local player_count = #_G.AllPlayers
    local valid = (player_number > 0) and (player_number <= player_count)
    if not valid then
        CustomCmd:printf("'%i' is outside the current player range!", player_number)
        if player_count == 0 then
            print("There are no players in the server to give items to.")
        elseif player_count == 1 then
            print("There is exactly 1 player in the server to give items to.")
        else
            CustomCmd:printf("Valid player numbers are %i to %i.", 1, player_count)
        end
        return false
    end
    return true
end

-- Checks if the lowercase version `prefab` exists in the global `Prefabs` table.
-- 
-- If it does we get the lowercase string back, otherwise we get `nil`.
function CustomCmd:valid_prefab(prefab)
    prefab = string.lower(prefab)
    if not _G.Prefabs[prefab] then
        CustomCmd:printf("'%s' is not a valid prefab name!", prefab)
        return nil
    end
    return prefab
end

-- Checks if `count` is a non-zero and non-negative integer. Falls back to `1` if it's `nil`. 
-- 
-- Returns the value itself if valid, otherwise `nil`.
---@param count integer
function CustomCmd:valid_count(count)
    count = count or 1
    if count < 1 then
        CustomCmd:printf("Cannot give %i items to players!", count)
        return nil
    end
    return count
end

-- Converts `tendency` to uppercase (or falls back to `"RIDER"`),
-- then checks if it's a valid key in the `TENDENCY` table.
-- If it is, returns the uppercase or our fallback, otherwise `nil`.
---@param tendency string
function CustomCmd:valid_tendency(tendency)
    tendency = tendency and tendency:upper() or "RIDER"
    local valid = _G.TENDENCY[tendency]
    if not valid then
        CustomCmd:printf("Tendency '%s' is not valid! It must be one of:", tendency)
        for _, v in pairs(_G.TENDENCY) do
            CustomCmd:printf("\"%s\"", v)
        end
        return nil
    end
    return valid
end

-- Converts `saddle` to lowercase (or falls back to `"saddle_race"`),
-- then checks if that's a valid prefab.
-- 
-- If `"saddle_"` isn't at the start of the string, it gets added.
-- This allows you just type `"basic"`, `"race"` and `"war"`.
---@param saddle string
function CustomCmd:valid_saddle(saddle)
    saddle = saddle and saddle:lower() or "saddle_race"
    -- Allow users to simply use "basic", "race" and "war".
    if not saddle:find("^saddle_") then
        saddle = "saddle_"..saddle
    end
    -- If even after all our work, it's not a valid prefab, then too bad
    if not _G.Prefabs[saddle] then
        return nil
    end
    return saddle
end

-- For pretty printing/announcing so players know which shard the command is 
-- coming from. Many commands only affect the shard they were run in.
function CustomCmd:get_shard()
    if _G.TheWorld:HasTag("forest") then 
        return "SURFACE"
    elseif _G.TheWorld:HasTag("cave") then 
        return "CAVES" 
    elseif _G.TheWorld:HasTag("island") then 
        return "SHIPWRECKED" 
    elseif _G.TheWorld:HasTag("volcano") then 
        return "VOLCANO" 
    end
    -- Default in case none of the above were matched
    return "THIS SHARD"
end

-- Instances can have different display names from their prefab's display name. 
-- e.g. bonded Beefalo, players, pigmen, merms, etc.
-- This gets the generic prefab display name.
---@param prefab string
function CustomCmd:get_display(prefab)
    -- I'm assuming that the valid prefab check was already run beforehand
    -- Need upper because all the keys in `STRINGS.NAMES` are uppercase.
    local display = _G.STRINGS.NAMES[string.upper(prefab)]
    -- Some valid prefabs don't have display names
    if not display then 
        local warning = string.format("Prefab '%s' has no Display Name!", prefab)
        print(warning)
    end
    -- If no display name (i.e. it's `nil`), we'll just use `"Missing Name"`.
    return display or "Missing Name"
end

-- Given an entity `inst`, get the string in between `"Tags:"` and `"\n"`.
---@return string
function CustomCmd:get_debugstring_tags(inst)
    -- Throaway values so we can skip to the 3rd return value of `string.find`.
    local i, j

    ---@type string
    local debugstring = inst.entity and inst.entity:GetDebugString() or inst:GetDebugString()

    -- return value #3 and above are the captures, if any are specified
    i, j, debugstring = debugstring:find("Tags:%s?(.-)%s?\n")
    return debugstring
end

-- Handles indexing into `player.components.inventory:GiveItem` and spawning prefabs.
---@param player table
---@param prefab string
---@param count? integer Falls back to 1. I'm assuming the non-negative check was run.
function CustomCmd:give_item(player, prefab, count)
    for i = 1, count or 1, 1 do
        player.components.inventory:GiveItem(_G.SpawnPrefab(prefab))
    end
end

return CustomCmd
