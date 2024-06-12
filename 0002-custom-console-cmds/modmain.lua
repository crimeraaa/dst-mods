-- These are declared as globals within the mod environment, so they should
-- be accessible from within any of this mod's scripts.

_G = GLOBAL
_G.CustomCmd = {} -- expose to global env as mod env is sandboxed

CustomCmd = _G.CustomCmd
CustomCmd.Docs  = require("custom_console_commands/docs")
CustomCmd.Util  = require("custom_console_commands/util")
CustomCmd.Check = require("custom_console_commands/check")
CustomCmd.Count = require("custom_console_commands/count")

CustomCmd.count_all = CustomCmd.Count.make_fn("count_all", false)
CustomCmd.remove_all = CustomCmd.Count.make_fn("remove_all", true)

---@param field string A key into `CustomCmd.Docs.Commands`.
function CustomCmd.print_usage(field)
    local usage = CustomCmd.Docs.Commands[field]
    if not usage then
        CustomCmd.Util.printf("Unknown custom command '%s'.", field)
        print("Try CustomCmd.list_commands().")
        return
    end

    CustomCmd.Util.printf("---SYNTAX---")
    local _params = {} -- silly but need to print `prefabs` as `...`
    for _, v in ipairs(usage.params) do
        _params[#_params + 1] = CustomCmd.Docs.Params[v].name == "..." and "..." or v
    end
    CustomCmd.Util.printf("CustomCmd.%s(%s)", field, table.concat(_params, ", "))

    CustomCmd.Util.printf("---PARAMS---")
    for _, key in ipairs(usage.params) do
        CustomCmd.Util.print_param(CustomCmd.Docs.Params[key])
    end

    CustomCmd.Util.printf("---SAMPLE---")
    for _, v in ipairs(usage.sample) do
        CustomCmd.Util.printf("CustomCmd.%s", v:format(field))
    end

    if usage.retval then
        CustomCmd.Util.printf("---RETURN---")
        CustomCmd.Util.print_param(usage.retval)
    end
    -- Helper.printf("return:\n%s", usage.retval or "   (none)")
end

---@param verbose boolean?
function CustomCmd.list_commands(verbose)
    print("---COMMANDS LIST---")
    for k in pairs(CustomCmd.Docs.Commands) do
        if verbose then
            CustomCmd.print_usage(k)
        else
            print(k)
        end
    end
end

---@param what string
function CustomCmd.help(what)
    if not what then
        CustomCmd.list_commands()
        return
    end
    CustomCmd.print_usage(what)
end

---@alias Tags table<string, boolean>
---@alias GUID integer

---@type table<GUID, Tags>
local memoized_tags = {}

-- Pass an entity to get the tags of.
---@param inst table
function CustomCmd.get_tags(inst)
    if not (inst and type(inst) == "table") then
        CustomCmd.print_usage("get_tags")
        return nil
    end
    
    -- Contains the individual tags as seen from the debug string.
    -- You only really need the keys, as the keys themselves are the tags.
    ---@type Tags
    local tags = memoized_tags[inst.GUID] or {}

    -- The string between `"Tags: "` and `"\n"` in the debug string
    -- `"%w+"` matches only "word" characters, that is:
    -- alphabeticals `[a-zA-Z]`, numericals `[0-9]` and underscores `[_]`.
    for word in CustomCmd.Util.get_debugstring_tags(inst):gmatch("%w+") do
        tags[word] = true
    end
    memoized_tags[inst.GUID] = tags
    return tags
end

function CustomCmd.add_tags(inst, tag, ...)
    if not (inst and tag) then
        CustomCmd.print_usage("add_tags")
        return
    end
    for _, v in ipairs{tag, ...} do
        if inst:HasTag(v) then
            CustomCmd.Util.printf("%s already has tag '%s'!", tostring(inst), v)
        else
            inst:AddTag(v)
        end
    end
end

function CustomCmd.remove_tags(inst, tag, ...)
    if not (inst and tag) then
        CustomCmd.print_usage("remove_tags")
        return
    end
    for _, v in ipairs{tag, ...} do
        if not inst:HasTag(v) then
            CustomCmd.Util.printf("%s does not have tag '%s'!", tostring(inst), v)
        else
            inst:RemoveTag(v)
        end
    end
end

---@param player_number integer
---@param prefab string
---@param count? integer
function CustomCmd.give_to(player_number, prefab, count)
    if player_number == nil then
        CustomCmd.print_usage("give_to")
        return
    end
    local player = CustomCmd.Check.player(player_number)
    prefab = CustomCmd.Check.prefab(prefab)
    count = CustomCmd.Check.count(count)
    -- All 3 validation functions return the appropriate handles/fallbacks,
    -- and return `nil` if a non-`nil` input was invalid for that use case.
    if not (player and prefab and count) then
        return
    end
    CustomCmd.Util.give_item(player, prefab, count)    
end

---@param prefab string
---@param count? integer
function CustomCmd.give_all(prefab, count)
    if prefab == nil then
        CustomCmd.print_usage("give_all")
        return
    end
    -- All validation functions print error messages
    prefab = CustomCmd.Check.prefab(prefab)
    count = CustomCmd.Check.count(count)
    -- Validation functions return fallback values if the params were `nil`.
    if not (prefab and count) then
        return
    elseif #_G.AllPlayers == 0 then
        print("There are no players in the server to give items to!")
        return
    end
    for _, player in ipairs(_G.AllPlayers) do
        CustomCmd.Util.give_item(player, prefab, count)
    end
end

---@param player_number integer
---@param tendency "RIDER"|"ORNERY"|"DEFAULT"|"PUDGY"
---@param saddle "saddle_basic"|"saddle_race"|"saddle_war"|"basic"|"race"|"war"
function CustomCmd.spawn_beef(player_number, tendency, saddle)
    if player_number == nil then
        CustomCmd.print_usage("spawn_beef")
        return
    end
    -- No fallback: get `nil` if `player_number` is invalid index to `AllPlayers`
    local player = CustomCmd.Check.player(player_number)
    tendency = CustomCmd.Check.tendency(tendency)
    saddle = CustomCmd.Check.saddle(saddle)
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
    CustomCmd.Util.give_item(player, "beef_bell")
end
