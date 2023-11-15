---@diagnostic disable: duplicate-set-field
-- These are declared as globals within the mod environment, so they should
-- be accessible from within any of this mod's scripts.

_G = GLOBAL
UsageStrings = require("usagestrings")
CustomCmd    = require("customcmd")
CountPrefabs = require("countprefabs")

local make_prefabsfn = require("prefab_fns")

_G.c_countall = make_prefabsfn("c_countall", false)

-- overwrite the original `c_removeall` from `consolecommands.lua`,
-- Need `AddSimPostInit` as console commands are loaded by then.
AddSimPostInit(function()
    _G.c_removeall = make_prefabsfn("c_removeall", true)
end)

-- Pass an entity to get the tags of.
---@param inst table
function _G.c_gettags(inst)
    if not (inst and type(inst) == "table") then
        CustomCmd:print_usage(UsageStrings.c_gettags)
        return nil
    end

    local str = CustomCmd:get_debugstring_tags(inst)
    
    -- Contains the individual tags as seen from the debug string.
    -- It's a key-value hashtable, but you only really need the keys.
    local tags = {}

    -- `"%w+"` matches only "word" characters, that is:
    -- alphabeticals `[a-zA-Z]`, numericals `[0-9]` and underscores `[_]`.
    for word in str:gmatch("%w+") do
        tags[word] = true
    end

    return tags
end

---@param player_number integer
---@param prefab string
---@param count? integer
function _G.c_giveto(player_number, prefab, count)
    if player_number == nil then
        CustomCmd:print_usage(UsageStrings.c_giveto)
        return
    end

    prefab = CustomCmd:valid_prefab(prefab)
    count = CustomCmd:valid_count(count)

    if not (CustomCmd:valid_player(player_number) and prefab and count) then
        return
    end

    local player = _G.AllPlayers[player_number]
    CustomCmd:give_item(player, prefab, count)    
end

---@param prefab string
---@param count? integer
function _G.c_giveall(prefab, count)
    if prefab == nil then
        CustomCmd:print_usage(UsageStrings.c_giveall)
        return
    end

    -- All validation functions print error messages
    prefab = CustomCmd:valid_prefab(prefab)
    count = CustomCmd:valid_count(count)

    if not (prefab and count) then
        return
    elseif #_G.AllPlayers == 0 then
        print("There are no players in the server to give items to!")
        return
    end

    for _, player in ipairs(_G.AllPlayers) do
        CustomCmd:give_item(player, prefab, count)
    end
end

---@param player_number integer
---@param tendency "RIDER"|"ORNERY"|"DEFAULT"|"PUDGY"
---@param saddle "saddle_basic"|"saddle_race"|"saddle_war"|"basic"|"race"|"war"
function _G.c_spawnbeef(player_number, tendency, saddle)
    if player_number == nil then
        CustomCmd:print_usage(UsageStrings.c_spawnbeef)
        return
    end
    tendency = CustomCmd:valid_tendency(tendency)
    saddle = CustomCmd:valid_saddle(saddle)
    if not (CustomCmd:valid_player(player_number) and tendency and saddle) then 
        return 
    end

    local player = _G.AllPlayers[player_number]
    local x, y, z = player.Transform:GetWorldPosition()

    -- Need a reference to this specific beefalo instance
    local beef = _G.c_spawn("beefalo")
    -- dedi server defaults to 0,0,0 so move beefalo to the player in question
    beef.Transform:SetPosition(x,y,z)

    -- Domestication proper
    beef.components.domesticatable:DeltaDomestication(1)
    beef.components.domesticatable:DeltaObedience(1)
    beef.components.domesticatable:DeltaTendency(tendency, 1)
    beef:SetTendency()
    beef.components.domesticatable:BecomeDomesticated()
    beef.components.hunger:SetHunger(0.5)
    beef.components.rideable:SetSaddle(nil, _G.SpawnPrefab(saddle))
    CustomCmd:give_item(player, "beef_bell")
end
