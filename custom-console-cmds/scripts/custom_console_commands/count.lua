local Count = {}

-- Checks if `what` is indeed an instance of `prefab` and that it's not
-- currently being held by someone or in a container.
function Count:is_countable(what, prefab)
    return what.prefab == prefab and not (
        what.replica.inventoryitem and what.replica.inventoryitem:IsHeld()
    )
end

-- If no `replica.stackable` field exists, assume a stack is 1.
function Count:get_stacksize(whom)
    return whom.replica.stackable and whom.replica.stackable:StackSize() or 1
end

-- Actually creates the prefab count of the prefab in the loaded area.
---@param prefab string
---@param entities table
---@param remove boolean
function Count:get_counts(prefab, entities, remove)
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

-- Instances can have different display names from their prefab's display name. 
-- e.g. bonded Beefalo, players, pigmen, merms, etc.
-- This gets the generic prefab display name.
---@param prefab string
function Count:get_displayname(prefab) 
    -- I'm assuming that the valid prefab check was already run beforehand
    -- Need upper because all the keys in `STRINGS.NAMES` are uppercase.
    local display = _G.STRINGS.NAMES[prefab:upper()]

    -- Some valid prefabs don't have display names
    if not display then 
        CustomCmd.Util:printf("Prefab '%s' has no Display Name!", prefab)
    end

    -- If no display name (i.e. it's `nil`), we'll just use `"Missing Name"`.
    return display or "Missing Name"
end

----------------------------- COUNT PREFABS PROPER -----------------------------

-- Generic count function to allow us to work with either client or server.
---@param prefab string
---@param entities table
---@param remove? boolean Pass `true` to also remove all instances of this prefab.
function Count:make_tally(prefab, entities, remove)
    local world = CustomCmd.Util:get_shard()
    local total, stacks = self:get_counts(prefab, entities, remove or false)
    local basic = "%s: There are %s."

    -- Reformat to display name then prefab, e.g. `"Beefalo ('beefalo')"`
    prefab = string.format("%s ('%s')", self:get_displayname(prefab), prefab)

    -- Adjust our message's grammar so it looks right.
    if total == 0 then
        basic = basic:gsub("are", "is no")
    elseif total == 1 then
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

-- For caller, pack `prefab` and varargs into a table then pass that.
---@param prefabs string[]
---@param remove boolean
local function helperfn(prefabs, remove) 
    -- Record invalid inputs in order so user knows what went wrong
    ---@type string[]
    local invalid_inputs = {}
    for _, prefab in ipairs(prefabs) do
        -- DST's prefab strings are always lowercase.
        -- If you input a non-string for some reason, that's handled too.
        prefab = type(prefab) == "string" and prefab:lower() or tostring(prefab)

        -- Don't complain in the middle of counting but take note of it.
        if _G.Prefabs[prefab] == nil then
            table.insert(invalid_inputs, string.format("'%s'", prefab))
        else
            _G.TheNet:Announce(Count:make_tally(prefab, _G.Ents, remove))
        end
    end
    -- Only print out error messages if we have at least 1 invalid input
    if #invalid_inputs > 0 then
        print("The following inputs were invalid:")
        for i, v in ipairs(invalid_inputs) do
            print(i, v)
        end
        print("Please make sure you have the correct names and/or spelling.")
    end
end

-- Because `count_all` and `remove_all` have similar implementations, 
-- we can use a function to create/return a new function definition.
---@param fn_name string The function's name as a string, e.g. `"count_all"`.
---@param remove boolean `true` if you want to remove prefabs, false otherwise.
function Count:make_fn(fn_name, remove)
    ---@param self CustomCmd Argument 1.
    ---@param ... string
    ---@diagnostic disable-next-line: redefined-local
    return function(self, ...)
        local argc, argv = select('#', ...),  {...}
        if argc == 0 then
            self:print_usage(fn_name)
            return
        end
        helperfn(argv, remove)
    end
end

return Count
