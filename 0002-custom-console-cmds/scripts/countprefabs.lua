---- COUNT PREFABS HELPER FUNCTIONS --------------------------------------------

local CountPrefabs = {}

-- TODO Find a way to dump all tags `TheWorld` so we can just index into those.
function CountPrefabs.get_shard()
    local shard = "THIS SHARD"
    if _G.TheWorld:HasTag("forest") then 
        shard = "SURFACE"
    elseif _G.TheWorld:HasTag("cave") then 
        shard = "CAVES" 
    elseif _G.TheWorld:HasTag("island") then 
        shard = "SHIPWRECKED" 
    elseif _G.TheWorld:HasTag("volcano") then 
        shard = "VOLCANO" 
    end
    return shard
end

-- Instances can have different display names from their prefab's display name. 
-- e.g. bonded Beefalo, players, pigmen, merms, etc.
-- This gets the generic prefab display name.
---@param prefab string
function CountPrefabs.get_displayname(prefab) 
    -- I'm assuming that the valid prefab check was already run beforehand
    -- Need upper because all the keys in `STRINGS.NAMES` are uppercase.
    local display = _G.STRINGS.NAMES[string.upper(prefab)]

    -- Some valid prefabs don't have display names
    if not display then 
        _G.ChatHistory:SendCommandResponse(
            string.format("Prefab '%s' has no Display Name!", prefab)
        )
    end

    -- If no display name (i.e. it's `nil`), we'll just use `"Missing Name"`.
    return display or "Missing Name"
end

-- This check is so verbose, so I'd rather function it out.
-- Checks if `what` is indeed an instance of `prefab` and that it's not
-- currently being held by someone or in a container.
function CountPrefabs.is_countable(what, prefab)
    return what.prefab == prefab and not (
        what.replica.inventoryitem and what.replica.inventoryitem:IsHeld()
    )
end

-- Just functioning this out because goodness this check is verbose.
-- If no `replica.stackable` field exists, assume a stack is 1.
function CountPrefabs.get_stacksize(whom)
    return whom.replica.stackable and whom.replica.stackable:StackSize() or 1
end

-- Actually creates the prefab count of the prefab in your loaded area.
---@param prefab string
---@param entities table
function CountPrefabs.get_counts(prefab, entities)
    local total = 0
    local stacks = 0

    for _, entity in pairs(entities) do
        -- if it's in a container/being held, we'll ignore it
        if CountPrefabs.is_countable(entity, prefab) then
            total  = total + CountPrefabs.get_stacksize(entity)
            stacks = stacks + 1 
        end
    end

    return total, stacks
end

---- COUNT PREFABS PROPER ------------------------------------------------------

-- Generic count function to allow us to work with either client or server.
---@param prefab string
---@param entities table
function CountPrefabs.make_tally(prefab, entities)
    local world = CountPrefabs.get_shard()
    local total, stacks = CountPrefabs.get_counts(prefab, entities)
    local basic = "%s: There are %s here."

    -- Reformat to display name then prefab, e.g. `"Beefalo ('beefalo')"`
    prefab = string.format("%s ('%s')", CountPrefabs.get_displayname(prefab), prefab)

    if total == 0 then
        -- Grammar for none found.
        basic = basic:gsub("are", "is no")
    elseif total == 1 then
        -- Grammar for singular found.
        basic = basic:gsub("are", "is a")
    elseif total == stacks then
        -- Entity is probably unstackable but there's multiple of it.
        prefab = string.format("%d %s", total, prefab)
    else
        -- There's multiple of this entity and each has its own stack.
        prefab = string.format("%d %s, in %d stacks", total, prefab, stacks)
    end
    return basic:format(world, prefab)
end

---@param prefab string
function CountPrefabs.get_servercount(prefab)
    -- Need a local var so we can toss away the numbers returned from `gsub`.
    local s = CountPrefabs.make_tally(prefab, _G.Ents):gsub("here", "in the shard")
    return s
end

---@param prefab string
function CountPrefabs.get_clientcount(prefab)
    -- coords are ever-changing, so we need to constantly retrieve its values.
    local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()

    -- Radius 80 is approximately how long your loaded range is.
    local ents = _G.TheSim:FindEntities(x, y, z, 80)

    return CountPrefabs.make_tally(prefab, ents)
end

return CountPrefabs
