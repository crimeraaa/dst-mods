_G = GLOBAL

local CountPrefabs = require("countprefabs")

---@param usage string The main syntax for how to use the command.
---@param ... string Optional help/descriptions/information/etc.
local function print_usage(usage, ...)
    print("Usage: "..usage)

    -- Pack variadic arguments into a table and print on individual lines
    for _, v in ipairs{...} do
        print(v)
    end
end

-- For caller, pack `prefab` and varargs into a table then pass that.
---@param prefabs string[]
---@param remove boolean
local function prefabs_helper(prefabs, remove) 
    ---@type string[]
    local invalid_inputs = {}

    for _, prefab in ipairs(prefabs) do
        -- DST's prefab strings are always lowercase.
        -- ? Do we want to modify this loop variable directly?
        prefab = (type(prefab) == "string" and string.lower(prefab)) or tostring(prefab)

        -- Don't complain in the middle of counting but take note of it.
        if _G.Prefabs[prefab] == nil then
            table.insert(invalid_inputs, string.format("'%s'", prefab))
        else
            _G.TheNet:Announce(CountPrefabs:make_tally(prefab, _G.Ents, remove))
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

---@param fn_name string The function's name as a string, e.g. `"c_countall"`.
---@param remove boolean `true` if you want to remove prefabs, false otherwise.
local function make_prefabsfn(fn_name, remove)
    -- Need 1 argument before the varargs ala C-style varargs.
    ---@param prefab string
    ---@param ... string
    return function(prefab, ...)
        if prefab == nil or type(prefab) ~= "string" then
            print_usage(
                string.format("%s(prefab, ...)", fn_name), 
                "Please input 1 or more prefab strings."
            )
            return
        end
        prefabs_helper({prefab, ...}, remove)
    end
end

_G.c_countall = make_prefabsfn("c_countall", false)

-- overwrite the original `c_removeall` from `consolecommands.lua`,
-- Need `AddSimPostInit` as console commands are loaded by then.
AddSimPostInit(function()
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.c_removeall = make_prefabsfn("c_removeall", true)
end)

-- Pass an entity.
---@param inst table
---@diagnostic disable-next-line: duplicate-set-field
function _G.c_gettags(inst)
    -- Ensure correct usage or remind user of it.
    if inst == nil or type(inst) ~= "table" then
        print_usage(
            "c_gettags(entity)",
            "Please pass exactly 1 entity to get the tags of."
        )
        return nil
    end

    -- Prefer to use `.entity` version because its debug string is much shorter.
    -- But otherwise we can still work with `what:GetDebugString()`.
    ---@type string
    local str = inst.entity and inst.entity:GetDebugString() or inst:GetDebugString()
    
    -- Contains the individual tags as seen from the debug string.
    -- It's a key-value hashtable, but you only really need the keys.
    local tags = {}
    
    -- Get only the "Tags:" line of the debug string. 
    -- Remove "Tags: " and the newline. We only want the tags themselves.
    str = str:match("Tags:.-\n"):gsub("Tags:%s?", "", 1):gsub("\n", "", 1)

    -- Need to use the "miserly" version of the all characters pattern.
    -- ".*%s" is the "greedy" version---it will match the entire string!
    for word in str:gmatch(".-%s") do
        -- We just want these keys to be valid.
        tags[word] = true
    end

    return tags
end
