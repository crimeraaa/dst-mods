---- COUNT PREFABS HELPER FUNCTIONS --------------------------------------------

local CountPrefabs = {}

-- TODO Find a way to dump all tags `TheWorld` so we can just index into those.
function CountPrefabs:get_shard()
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
function CountPrefabs:get_displayname(prefab) 
    -- I'm assuming that the valid prefab check was already run beforehand
    -- Need upper because all the keys in `STRINGS.NAMES` are uppercase.
    local display = _G.STRINGS.NAMES[string.upper(prefab)]
    -- Some valid prefabs don't have display names
    if not display then 
        local warning = string.format("Prefab '%s' has no Display Name!", prefab)
        _G.ChatHistory:SendCommandResponse(warning)
        -- dedicated servers can't use `SendCommandResponse`, so do this instead
        print(warning)
    end
    -- If no display name (i.e. it's `nil`), we'll just use `"Missing Name"`.
    return display or "Missing Name"
end

-- This check is so verbose, so I'd rather function it out.
-- Checks if `what` is indeed an instance of `prefab` and that it's not
-- currently being held by someone or in a container.
function CountPrefabs:is_countable(what, prefab)
    return what.prefab == prefab and not (
        what.replica.inventoryitem and what.replica.inventoryitem:IsHeld()
    )
end

-- Just functioning this out because goodness this check is verbose.
-- If no `replica.stackable` field exists, assume a stack is 1.
function CountPrefabs:get_stacksize(whom)
    return whom.replica.stackable and whom.replica.stackable:StackSize() or 1
end

-- Actually creates the prefab count of the prefab in your loaded area.
---@param prefab string
---@param entities table
---@param remove boolean
function CountPrefabs:get_counts(prefab, entities, remove)
    local total = 0
    local stacks = 0
    for _, entity in pairs(entities) do
        -- if it's in a container/being held, we'll ignore it
        if self:is_countable(entity, prefab) then
            total  = total + self:get_stacksize(entity)
            stacks = stacks + 1 
            if remove == true then
                entity:Remove()
            end
        end
    end
    return total, stacks
end

----------------------------- COUNT PREFABS PROPER -----------------------------

-- Generic count function to allow us to work with either client or server.
---@param prefab string
---@param entities table
---@param remove? boolean Pass `true` to also remove all instances of this prefab.
function CountPrefabs:make_tally(prefab, entities, remove)
    local world = self:get_shard()
    local total, stacks = self:get_counts(prefab, entities, remove or false)
    local basic = "%s: There are %s."

    -- Reformat to display name then prefab, e.g. `"Beefalo ('beefalo')"`
    prefab = string.format("%s ('%s')", self:get_displayname(prefab), prefab)

    -- Adjust our message's grammar so it looks right.
    if total == 0 then
        -- Grammar for none found.
        basic = basic:gsub("are", "is no")
    elseif total == 1 then
        -- Grammar for singular found.
        basic = basic:gsub("are", "is a")
    elseif total == stacks then
        -- Entity is probably unstackable but there's multiple of it,
        -- or entity is stackable but we only found stacks of 1.
        prefab = string.format("%d %s", total, prefab)
    else
        -- There's multiple of this entity and has different stacks.
        prefab = string.format("%d %s, in %d stacks", total, prefab, stacks)
    end

    -- Replace "There is " and "There are " with "Removed " (whitespace included)
    -- Use non-greedy algorithm so we don't match the entire string.
    if remove == true and total >= 1 then
        basic = basic:gsub("There %w-%s", "Removed ")
    end

    return basic:format(world, prefab)
end

-- I do this a lot so I've functioned it out. Gets entities loaded by `ThePlayer`
-- within 80 radius units, which is about how far our loading range goes.
function CountPrefabs:get_client_ents()
    -- Player's coordinates are ever-changing, so need to determine them here
    local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()
    return _G.TheSim:FindEntities(x, y, z, 80)
end

return CountPrefabs
