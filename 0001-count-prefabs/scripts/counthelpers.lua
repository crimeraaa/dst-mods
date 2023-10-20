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
-- If no `replica.stackable` field exists, assume "stacksize" = 1.
function CountPrefabs.get_stacksize(whom)
    return whom.replica.stackable and whom.replica.stackable:StackSize() or 1
end

-- Actually creates the prefab count of the prefab in your loaded area.
-- Need to pass `self` so we have immediate access to member methods.
function CountPrefabs:make_tally(prefab)
    local total = 0
    local stacks = 0
    local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()
    -- Radius 80 is approximately how long your loaded range is.
    local loaded_entities = _G.TheSim:FindEntities(x, y, z, 80)

    for _, entity in pairs(loaded_entities) do
        -- if it's in a container/being held, we'll ignore it
        if self.is_countable(entity, prefab) then
            total  = total + self.get_stacksize(entity)
            stacks = stacks + 1 
        end
    end

    return total, stacks
end

---- MODENV COUNT FUNCTIONS ----------------------------------------------------

-- Pass `self` via colon notation so we have immediate access to member methods.
---@param prefab string
function CountPrefabs:get_clientcount(prefab)
    local world = self.get_shard()
    local total, stacks = self:make_tally(prefab)
    local basic = "%s - There are %s here."

    -- Reformat to display name then prefab, e.g. `"Beefalo ('beefalo')"`
    prefab = string.format("%s ('%s')", self.get_displayname(prefab), prefab)

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

-- Upvalue to avoid constantly constructing this table. It's constant anyway.
CountPrefabs.announce_fns = {
    -- Global Chat
    ---@param msg string
    [0] = function(msg) _G.TheNet:Say(msg) end,

    -- Whisper Chat
    ---@param msg string
    [1] = function(msg) _G.TheNet:Say(msg, true) end,

    -- Local Chat
    ---@param msg string
    [2] = function(msg) _G.ChatHistory:SendCommandResponse(msg) end,
}

-- upvalue so we don't constantly construct this table over and over again
CountPrefabs.hint_strings = { 
    [0] = "Global Count",  
    [1] = "Whisper Count", 
    [2] = "Local Count" 
}

return CountPrefabs
