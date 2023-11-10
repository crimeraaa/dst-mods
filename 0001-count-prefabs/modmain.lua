-- I don't like typing out `GLOBAL` all the time :)
-- Note that any modules loaded by `require` can "inherit" this global variable.
-- Which is useful so I don't have to constantly rewrite this line.
_G = GLOBAL

-- For some reason, `require` didn't import non-local functions?
-- Whatever, I'll just return a table acting as a namespace then...
local CountPrefabs = require("countprefabs")

---- MOD CONFIGURATIONS --------------------------------------------------------

-- ? 0-based as the option for global chat uses mode number 0.
---@type integer[]
local default_key = {
    ---@type integer
    [0] = GetModConfigData("default_key1"),
    [1] = GetModConfigData("default_key2"),
    [2] = GetModConfigData("default_key3"),
}

---@type integer
local default_slash = GetModConfigData("default_slash")

---@type integer[]
local keybind_key = {
    GetModConfigData("keybind_key1"),
    GetModConfigData("keybind_key2"),
    GetModConfigData("keybind_key3"),
}

---- SLASH COMMAND PROPER ------------------------------------------------------

-- ? 0-based as global chat uses mode number 0.
-- Upvalue to avoid constantly constructing this table. It's constant anyway.
local announce_fns = {
    -- Global Chat
    [0] = function(msg) _G.TheNet:Say(msg) end,

    -- Whisper Chat
    [1] = function(msg) _G.TheNet:Say(msg, true) end,

    -- Local Chat
    [2] = function(msg) _G.ChatHistory:SendCommandResponse(msg) end,
}

-- All validation checks should have been run beforehand.
---@param mode integer
---@param msg string
local function make_announcement(mode, msg)
    -- `announce_fns` table has index 0 so users can input 0 for global
    local announcer = announce_fns[mode]
    announcer(string.format("%s %s", _G.STRINGS.LMB, msg))
end

-- Pass in `params.mode`.
---@param mode string
local function validate_mode(mode)
    -- Got an argument for `params.mode`, so validate it first.
    if mode ~= nil then
        -- Params are always strings. Note that `tonumber` isn't part of mod env.
        local converted = _G.tonumber(mode)
        -- Wasn't a number or a valid announcement mode.
        if converted == nil or announce_fns[converted] == nil then
            _G.ChatHistory:SendCommandResponse(
                string.format("Invalid mode '%s'; see /help count.", mode)
            )
            return nil
        end
        return converted
    end
    -- Got no argument, so fall back to the mod configuration for slash command.
    return default_slash
end

-- Pass in `params.prefab`. 
-- Converts `param` to lowercase + checks if exists in the `_G.Prefabs` table.
local function validate_prefab(prefab)
    -- Convert to lowercase as all DST prefabs are lowercase.
    prefab = string.lower(prefab)

    -- `_G.Prefabs` table contains all currently existing prefabs. 
    -- ? It may include modded prefabs too!
    if _G.Prefabs[prefab] == nil then
        _G.ChatHistory:SendCommandResponse(
            string.format("Invalid prefab '%s'!", prefab)
        ) 
        return nil
    end
    -- Prefab exists so we're good to go!
    return prefab
end

AddUserCommand("count", {
    aliases = {"countprefabs", "prefabcount"},
    prettyname = "Count Prefabs (Client)", 
    desc = [[
Counts prefabs (and stacks, ignoring inventory/containers) loaded by you.
Modes: 0 for global chat (default), 1 for whisper chat, 2 for local chat.]], 
    permission = _G.COMMAND_PERMISSION.USER, 
    slash = true, 
    usermenu = false, 
    servermenu = false, 
    params = {"prefab", "mode"}, 
    paramsoptional = {false, true}, 
    vote = false, 
    localfn = function(params, caller) 
        -- Can run slash commands in various situations so avoid these ones
        if caller == nil or caller.HUD == nil then 
            return
        end 

        -- DST prefab strings are always lowercase.
        local prefab = validate_prefab(params.prefab)
        local mode = validate_mode(params.mode)

        -- If both validation functions returned nil, something went wrong.
        -- They already send error messages so we don't need to do anything.
        if prefab == nil and mode == nil then
            return
        end

        -- coords are ever-changing, so we need to constantly retrieve its values.
        local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()

        -- Radius 80 is approximately how long your loaded range is.
        local ents = _G.TheSim:FindEntities(x, y, z, 80)

        local tally = CountPrefabs:make_tally(prefab, ents)
        make_announcement(mode, tally)
    end, 
}) 

---- KEYBIND ACTION SETUP ------------------------------------------------------

local prefix = "MOD_COUNTPREFABS"

-- 1-based as Lua normally is, because "key0" doesn't seem right to me.
local keybind_id = {
    prefix.."_KEYBIND1",
    prefix.."_KEYBIND2",
    prefix.."_KEYBIND3",
}

-- ? 0-based as global uses mode number 0.
-- upvalue so we don't constantly construct this table over and over again
local hint_strings = { 
    [0] = "Global Count",  
    [1] = "Whisper Count", 
    [2] = "Local Count" 
}

-- All 3 versions of the action have similar implementations, so we can just
-- create them one by one by passing the numbers 0, 1 and 2.
-- This returns the prompt string and the actual action function.
---@param index integer Value we'll use to index into `default_key`.
local function make_announce_act(index)
    -- Action is based on the default configured mode for this keybind.
    local mode = default_key[index]
    local function announce_act_fn(act)
        if act and act.doer then
            -- Target is the entity that's the receiver of the action
            local target = act.target
            if target == nil or target.prefab == nil then
                return
            end
            local x, y, z = act.Transform:GetWorldPosition()
            local ents = _G.TheSim:FindEntities(x, y, z, 80)
            local tally = CountPrefabs:make_tally(target.prefab, ents, false)
            make_announcement(mode, tally)
        end
    end
    return hint_strings[mode], announce_act_fn
end

---- KEYBIND ACTION PROPER -----------------------------------------------------

-- TODO Your primary keybind should only show the word `"Count"`.
AddAction(keybind_id[1], make_announce_act(0))
AddAction(keybind_id[2], make_announce_act(1))
AddAction(keybind_id[3], make_announce_act(2))

-- i just lifted these straight from Environment Pinger's modmain, by sauktux.

local function PlayerActionPickerPostInit(playeractionpicker, player)
    if player ~= _G.ThePlayer then
        return 
    end

    -- Directly overriding `DoGetMouseActions` but hook to retain original behavior
    local old_DoGetMouseActions = playeractionpicker.DoGetMouseActions
    playeractionpicker.DoGetMouseActions = function(self, position, target)
        -- Our new action comes after the original function is run normally
        local lmb, rmb = old_DoGetMouseActions(self, position, target)
        if _G.TheInput:IsKeyDown(keybind_key[1]) then
            local entity_target = _G.TheInput:GetWorldEntityUnderMouse()
            local hud_entity = _G.TheInput:GetHUDEntityUnderMouse()

            -- Don't count hud entities, or when user is pressing the correct 
            -- keybinds but there's no entity *to* count
            if hud_entity or not entity_target then
               return lmb, rmb
            end

            -- This is ugly as hell but it works...
            lmb = _G.BufferedAction(player, entity_target, _G.ACTIONS[keybind_id[1]])
            if _G.TheInput:IsKeyDown(keybind_key[2]) then
                lmb = _G.BufferedAction(player, entity_target, _G.ACTIONS[keybind_id[2]])
                if _G.TheInput:IsKeyDown(keybind_key[3]) then
                    lmb = _G.BufferedAction(player, entity_target, _G.ACTIONS[keybind_id[3]])
                end
            end
        end
        return lmb, rmb
    end
end

-- state variable that's constantly toggled by `OnLeftClick` below
local cooldown = false 

local function PlayerControllerPostInit(playercontroller, player)
    -- Might try to init other players even if we're clientsided
    if player ~= _G.ThePlayer then
        return
    end

    -- We're directly overriding `OnLeftClick` so we'll do some hooking
    local old_OnLeftClick = playercontroller.OnLeftClick
    playercontroller.OnLeftClick = function(self, down, ...)
        local lmb = self:GetLeftMouseAction()
        if down and lmb and lmb.action.id and string.match(lmb.action.id, prefix) then
            if not cooldown then
                cooldown = _G.ThePlayer:DoTaskInTime(1, function() 
                    cooldown = false 
                end)
                lmb.action.fn(lmb)
            end
            -- if attempting to count while on cooldown, just do nothing
            return
        end
        -- if none of the above, do the original leftclick
        old_OnLeftClick(self, down, ...) 
    end
end

AddComponentPostInit("playeractionpicker", PlayerActionPickerPostInit)
AddComponentPostInit("playercontroller", PlayerControllerPostInit)
