-- I don't like typing out `GLOBAL` all the time :)
-- Note that any modules loaded by `require` can "inherit" this global variable.
-- Which is useful so I don't have to constantly rewrite this line.
_G = GLOBAL

-- For some reason, `require` didn't import non-local functions?
-- Whatever, I'll just return a table acting as a namespace then...
local CountPrefabs = require("counthelpers")

---- MOD CONFIGURATIONS --------------------------------------------------------

local defaults = {
    slash = GetModConfigData("default_slash"),
    key1 = GetModConfigData("default_key1"),
    key2 = GetModConfigData("default_key2"),
    key3 = GetModConfigData("default_key3"),
}

local keybinds = {
    key1 = GetModConfigData("keybind_key1"),
    key2 = GetModConfigData("keybind_key2"),
    key3 = GetModConfigData("keybind_key3"),
}

---- SLASH COMMAND PROPER ------------------------------------------------------

---@param mode integer
---@param msg string
local function make_announcement(mode, msg)
    -- `announce_fns` table has index 0 so users can input 0 for global
    local announcer = CountPrefabs.announce_fns[mode]
    if announcer then
        announcer(string.format("%s %s", _G.STRINGS.LMB, msg))
    else
        -- Invalid mode, warn user instead
        _G.ChatHistory:SendCommandResponse(
            string.format("Invalid mode '%i'; see /help count.", mode)
        )
    end
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
        -- I'm unsure how this can happen, but this is a holdover from the
        -- original modmain Crestwave wrote out for me long long ago.
        if caller == nil or caller.HUD == nil then 
            return 
        end 

        -- Params are strings by default, so convert them.
        -- Note that `tonumber` isn't part of DST's mod env, need `_G`.
        local mode = _G.tonumber(params.mode)

        -- Correct string case here in case user didn't use all lowercase.
        local prefab = string.lower(params.prefab)

        --warn the user for clarity!
        if _G.Prefabs[prefab] == nil then
            _G.ChatHistory:SendCommandResponse(
                string.format("Invalid prefab '%s'!", prefab)
            ) 
            return
        end
        -- If `mode` is `nil`, we'll use slash cmd's configured default.
        make_announcement(
            mode or defaults.slash, 
            CountPrefabs:get_clientcount(prefab)
        )
    end, 
}) 

---- KEYBIND ACTION SETUP ------------------------------------------------------

local prefix = "MOD_COUNTPREFABS"
local mod_id = {
    prefix.."_PRIMARYHOOK",
    prefix.."_SECONDARYHOOK",
    prefix.."_TERTIARYHOOK",
}

-- Creates the prompt to be shown for the action, e.g. `"Local Count"`.
---@param key integer 
---```lua
----- Sample usage:
---get_hint(defaults.key1)
--```
local function get_hint(key)
    return CountPrefabs.hint_strings[key]
end

-- All 3 versions of the action have similar implementations, so we can just
-- create them by calling this with the respective key.
---@param mode integer
---```lua
----- Sample usage:
---make_announce_act(defaults.key3)
--```
local function make_announce_act(mode)
    return function(act)
        if act and act.doer then
            -- Target is the entity that's the receiver of the action
            local target = act.target
            if target == nil or target.prefab == nil then
                return
            end
            make_announcement(
                mode, 
                CountPrefabs:get_clientcount(target.prefab)
            )
        end
    end
end

---- KEYBIND ACTION PROPER -----------------------------------------------------

-- Your primary keybind should only show the word `"Count"`.
AddAction(mod_id[1], "Count", make_announce_act(defaults.key1))
AddAction(mod_id[2], get_hint(defaults.key2), make_announce_act(defaults.key2))
AddAction(mod_id[3], get_hint(defaults.key3), make_announce_act(defaults.key3))

-- i just lifted these straight from Environment Pinger's modmain, by sauktux.

local function PlayerActionPickerPostInit(playeractionpicker, player)
    if player ~= _G.ThePlayer then
        return 
    end
    
    local old_DoGetMouseActions = playeractionpicker.DoGetMouseActions
    playeractionpicker.DoGetMouseActions = function(self, position, target)
        local lmb, rmb = old_DoGetMouseActions(self, position, target)
        if _G.TheInput:IsKeyDown(keybinds.key1) then
            local entity_target = _G.TheInput:GetWorldEntityUnderMouse()
            local hud_entity = _G.TheInput:GetHUDEntityUnderMouse()
           
            if hud_entity or not entity_target then
               return lmb, rmb
            end
           
            lmb = _G.BufferedAction(
                player, 
                entity_target, 
                _G.ACTIONS[mod_id[1]]
            )

            if _G.TheInput:IsKeyDown(keybinds.key2) then
                lmb = _G.BufferedAction(
                    player, 
                    entity_target, 
                    _G.ACTIONS[mod_id[2]]
                )

                if _G.TheInput:IsKeyDown(keybinds.key3) then
                    lmb = _G.BufferedAction(
                        player, 
                        entity_target, 
                        _G.ACTIONS[mod_id[3]]
                    )
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
