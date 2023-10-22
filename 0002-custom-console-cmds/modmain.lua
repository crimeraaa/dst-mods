_G = GLOBAL

local CountPrefabs = require("countprefabs")

-- Need 1 argument ala C-style variadic arguments
---@param prefab string
---@param ... string
function _G.c_countall(prefab, ...)
    if prefab == nil then
        print("Usage: c_countall(prefab, ...)")
        print("Please input 1 or more prefab strings.")
        return
    end

    ---@type string[]
    local invalid_inputs = {}

    for _, what in ipairs{prefab, ...} do
        -- Convert to lowercase in case of user error; DST's prefab strings are
        -- always lowercase and indexing into tables is case-sensitive.
        what = string.lower(what)

        -- Don't complain in the middle of counting just yet
        if _G.Prefabs[what] == nil then
            table.insert(invalid_inputs, string.format("'%s'", what))
        else
            _G.TheNet:Announce(CountPrefabs.get_servercount(what))
        end
    end

    -- Only print out error messages in this case
    if #invalid_inputs > 0 then
        print("The following inputs were invalid:")
        for i, v in ipairs(invalid_inputs) do
            print(i, v)
        end
        print("Please make sure you have the correct names and/or spelling.")
    end
end
