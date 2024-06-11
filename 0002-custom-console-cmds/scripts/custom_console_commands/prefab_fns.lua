-- Previously, it seemed that the CustomCmd table wasn't loaded into memory.
-- But now it works just fine?
-- print("CUSTOMCMD: Loaded \"customcmd\"? ", package.loaded["customcmd"])

-- For caller, pack `prefab` and varargs into a table then pass that.
---@param prefabs string[]
---@param remove boolean
local function prefabs_helper(prefabs, remove) 
    -- Record invalid inputs in order so user knows what went wrong
    ---@type string[]
    local invalid_inputs = {}
    for _, prefab in ipairs(prefabs) do
        -- DST's prefab strings are always lowercase.
        -- If you input a non-string for some reason, that's handled too.
        prefab = type(prefab) == "string" and string.lower(prefab) or tostring(prefab)

        -- Don't complain in the middle of counting but take note of it.
        if _G.Prefabs[prefab] == nil then
            table.insert(invalid_inputs, string.format("'%s'", prefab))
        else
            _G.TheNet:Announce(CountPrefabs.make_tally(prefab, _G.Ents, remove))
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

-- Because `c_countall` and `c_removeall` have similar implementations, 
-- we can use a function to create/return a new function definition.
---@param fn_name string The function's name as a string, e.g. `"c_countall"`.
---@param remove boolean `true` if you want to remove prefabs, false otherwise.
local function make_prefabsfn(fn_name, remove)
    -- Need 1 argument before the varargs ala C-style varargs.
    -- This also ensures we don't run the prefab count body with 0 arguments.
    ---@param prefab string
    ---@param ... string
    return function(prefab, ...)
        if prefab == nil or type(prefab) ~= "string" then
            Helper.print_usage(UsageStrings[fn_name])
            return
        end
        prefabs_helper({prefab, ...}, remove)
    end
end

return make_prefabsfn
