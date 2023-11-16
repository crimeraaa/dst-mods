-- Uncategorized helper functions that I find useful.
Helper = {}

-- Almost a C-style printf, but it does append newlines always since we can't
-- access `io.stdout.write` from DST.
---@param fmt string String literal or C-style format string.
---@param ... string|number Arguments to C-style format string, if any.
function Helper:printf(fmt, ...)
    print(fmt:format(...))
end

---@param usage UsageString
function Helper:print_usage(usage)
    -- Messy here, but nicer printing
    self:printf([[syntax: %s
    Note that parameters enclosed in angled brackets, e.g. <prefab> are required.
    Parameters enclosed in square brackets, e.g. [tendency] are optional.]], 
        usage.syntax
    )
    self:printf("params:\n%s", usage.params)
    self:printf("sample:\n%s", usage.sample)
    self:printf("return:\n%s", usage.retval or "   (none)")
end

-- For pretty printing/announcing so players know which shard the command is 
-- coming from. Many commands only affect the shard they were run in.
function Helper:get_shard()
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
function Helper:get_display(prefab)
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
function Helper:get_debugstring_tags(inst)
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
function Helper:give_item(player, prefab, count)
    for i = 1, count or 1, 1 do
        player.components.inventory:GiveItem(_G.SpawnPrefab(prefab))
    end
end

return Helper
