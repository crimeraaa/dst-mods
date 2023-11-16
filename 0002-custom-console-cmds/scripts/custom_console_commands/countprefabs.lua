---@diagnostic disable: duplicate-set-field
CountPrefabs = {}

-- Checks if `what` is indeed an instance of `prefab` and that it's not
-- currently being held by someone or in a container.
function CountPrefabs:is_countable(what, prefab)
    return what.prefab == prefab and not (
        what.replica.inventoryitem and what.replica.inventoryitem:IsHeld()
    )
end

-- If no `replica.stackable` field exists, assume a stack is 1.
function CountPrefabs:get_stacksize(whom)
    return whom.replica.stackable and whom.replica.stackable:StackSize() or 1
end

-- Actually creates the prefab count of the prefab in the loaded area.
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
    local world = Helper:get_shard()
    local total, stacks = self:get_counts(prefab, entities, remove or false)
    local basic = "%s: There are %s."

    -- Reformat to display name then prefab, e.g. `"Beefalo ('beefalo')"`
    prefab = string.format("%s ('%s')", Helper:get_displayname(prefab), prefab)

    -- Adjust our message's grammar so it looks right.
    if total == 0 then
        -- Grammar for none found.get_display
        basic = basic:gsub("are", "is no")
    elseif total == 1 then
        -- Grammar for singular found.
        basic = basic:gsub("are", "is a")
    elseif total == stacks then
        -- Entity is probably unstackable but there's multiple of it,
        -- or entity is stackable but we only found stacks of 1.
        prefab = string.format("%d %s", total, prefab)
    else
        -- There's multiple of this entity and it has different stacks.
        prefab = string.format("%d %s, in %d stacks", total, prefab, stacks)
    end

    -- Replace "There is " and "There are " with "Removed " (whitespace included)
    -- Use non-greedy algorithm so we don't match the entire string.
    if remove == true and total >= 1 then
        basic = basic:gsub("There %w-%s", "Removed ")
    end

    return basic:format(world, prefab)
end

return CountPrefabs
