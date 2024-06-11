-- These are declared as globals within the mod environment, so they should
-- be accessible from within any of this mod's scripts.

_G = GLOBAL
UsageStrings  = require("custom_console_commands/usagestrings")
Helper        = require("custom_console_commands/helper")
ValidateInput = require("custom_console_commands/validateinput")
CountPrefabs  = require("custom_console_commands/countprefabs")

local make_prefabsfn = require("custom_console_commands/prefab_fns")

_G.c_countall = make_prefabsfn("c_countall", false)

-- overwrite the original `c_removeall` from `consolecommands.lua`,
-- Need `AddSimPostInit` as console commands are loaded by then.
AddSimPostInit(function()
    _G.c_removeall = make_prefabsfn("c_removeall", true)
end)

function _G.c_listcmds()
    print("---BEGIN LISTING---")
    for k in pairs(UsageStrings) do
        print(k)
    end
    print("---DONE LISTING---")
end

---@param what string
function _G.c_helpcmd(what)
    if not what:find("^c_") then
        what = "c_" .. what
    end
    Helper.print_usage(UsageStrings[what])
end

-- Pass an entity to get the tags of.
---@param inst table
function _G.c_gettags(inst)
    if not (inst and type(inst) == "table") then
        Helper.print_usage(UsageStrings.c_gettags)
        return nil
    end
    -- The string between `"Tags: "` and `"\n"` in the debug string
    local str = Helper.get_debugstring_tags(inst)
    -- Contains the individual tags as seen from the debug string.
    -- You only really need the keys as the keys are the tags.
    ---@type table<string,boolean>
    local tags = {}
    -- `"%w+"` matches only "word" characters, that is:
    -- alphabeticals `[a-zA-Z]`, numericals `[0-9]` and underscores `[_]`.
    for word in str:gmatch("%w+") do
        tags[word] = true
    end
    return tags
end

function _G.c_addtags(inst, tag, ...)
    if not (inst and tag) then
        -- Helper.print_usage(UsageStrings.c_addtags)
        print("TODO: Usage string c_addtags")
        return
    end
    for _, v in ipairs{tag, ...} do
        if inst:HasTag(v) then
            Helper.printf("%s already has tag '%s'!", tostring(inst), v)
        else
            inst:AddTag(v)
        end
    end
end

function _G.c_removetags(inst, tag, ...)
    if not (inst and tag) then
        -- Helper.print_usage(UsageStrings.c_removetags)
        print("TODO: Usage string c_removetags")
        return
    end
    for _, v in ipairs{tag, ...} do
        if not inst:HasTag(v) then
            Helper.printf("%s does not have tag '%s'!", tostring(inst), v)
        else
            inst:RemoveTag(v)
        end
    end
end

---@param player_number integer
---@param prefab string
---@param count? integer
function _G.c_giveto(player_number, prefab, count)
    if player_number == nil then
        Helper.print_usage(UsageStrings.c_giveto)
        return
    end
    local player = ValidateInput.player(player_number)
    prefab = ValidateInput.prefab(prefab)
    count = ValidateInput.count(count)
    -- All 3 validation functions return the appropriate handles/fallbacks,
    -- and return `nil` if a non-`nil` input was invalid for that use case.
    if not (player and prefab and count) then
        return
    end
    Helper.give_item(player, prefab, count)    
end

---@param prefab string
---@param count? integer
function _G.c_giveall(prefab, count)
    if prefab == nil then
        Helper.print_usage(UsageStrings.c_giveall)
        return
    end
    -- All validation functions print error messages
    prefab = ValidateInput.prefab(prefab)
    count = ValidateInput.count(count)
    -- Validation functions return fallback values if the params were `nil`.
    if not (prefab and count) then
        return
    elseif #_G.AllPlayers == 0 then
        print("There are no players in the server to give items to!")
        return
    end
    -- Marginally inefficient to call `_G.c_giveto` because of error checking,
    -- but I'm sure it doesn't matter unless you infinite loop this command
    for _, player in ipairs(_G.AllPlayers) do
        Helper.give_item(player, prefab, count)
    end
end

---@param player_number integer
---@param tendency "RIDER"|"ORNERY"|"DEFAULT"|"PUDGY"
---@param saddle "saddle_basic"|"saddle_race"|"saddle_war"|"basic"|"race"|"war"
function _G.c_spawnbeef(player_number, tendency, saddle)
    if player_number == nil then
        Helper.print_usage(UsageStrings.c_spawnbeef)
        return
    end
    -- No fallback: get `nil` if `player_number` is invalid index to `AllPlayers`
    local player = ValidateInput.player(player_number)
    tendency = ValidateInput.tendency(tendency)
    saddle = ValidateInput.saddle(saddle)
    -- If any of the 3 are `nil`, this check will pass and we'll early return
    if not (player and tendency and saddle) then
        return 
    end
    -- Need handle to this specific beefalo instance, we'll modify it a ton
    local beef = _G.c_spawn("beefalo")

    -- dedi server defaults to 0,0,0 so move beefalo to player in question
    beef.Transform:SetPosition(player.Transform:GetWorldPosition())

    -- Domestication proper, unsure if need this exact order though
    beef.components.domesticatable:DeltaDomestication(1)
    beef.components.domesticatable:DeltaObedience(1)
    beef.components.domesticatable:DeltaTendency(tendency, 1)
    beef:SetTendency()
    beef.components.domesticatable:BecomeDomesticated()
    -- beef.components.hunger:SetHunger(0.5) -- Seems like this one doesn't exist anymore.
    beef.components.rideable:SetSaddle(nil, _G.SpawnPrefab(saddle))
    Helper.give_item(player, "beef_bell")
end
