_G = GLOBAL

local CountPrefabs = require("countprefabs")

-- Need 1 argument ala C-style varargs
function _G.c_countall(prefab, ...)
    for _, what in ipairs({prefab, ...}) do
        _G.TheNet:Announce(CountPrefabs.get_servercount(what))
    end

    -- _G.TheNet:Announce(CountPrefabs.get_servercount(prefab))
end
