---@class Map<K, V>: {[K]: V}
---@class Dictionary<T>: {[string]: T}

---@class ParamInfo
---@field type string
---@field desc string
---@field sample? string[]
---@field optional? boolean
---@field default? string|number|boolean
---@field isvararg? boolean

---@class DocString
---@field sample  string[] A series of format strings showing sample usages.
---@field params  string[] A series of keys into `Params`.
---@field retval? ParamInfo

_G = GLOBAL

---@class CustomCmd
_G.CustomCmd = {} -- expose to global env as mod env is sandboxed

CustomCmd = _G.CustomCmd
CustomCmd.Util  = require("custom_console_commands/util")
CustomCmd.Check = require("custom_console_commands/check")
CustomCmd.Count = require("custom_console_commands/count")

---@type Dictionary<ParamInfo>
local Params = {
    command = {
        type = "string|function",
        desc = "A key into CustomCmd, sample string usage, or a function thereof.",
        sample = {"\"give_to\"", "\"CustomCmd.count_all\"", "CustomCmd.get_tags"},
        optional = true,
        default = "calling CustomCmd:list()",
    },
    inst = {
        type = "table",
        desc = "An entity instance.",
        sample = {"ThePlayer", "c_findnext(\"beefalo\")", "c_spawn(\"pigman\")"},
    },
    item_count = {
        type = "integer",
        desc = "How many of the given prefab to give. Must be 1 or greater.",
        optional = true,
        default = 1,
    },
    player_number = {
        type = "integer",
        desc = "Index into the AllPlayers table to retrieve a player entity.",
    },
    prefab = {
        type = "string",
        desc = "Prefab name in Lua code.",
        sample = {"\"log\"", "\"pigman\"", "\"meat\""},
    },
    ["prefabs..."] = {
        type = "string",
        desc = "0 or more other prefabs.",
        optional = true,
        isvararg = true,
    },
    saddle = {
        type = "string",
        desc = "A saddle prefab name. You can omit the \"saddle_\" part.",
        sample = {"\"saddle_basic\"", "\"saddle_race\"", "\"saddle_war\"",
            "\"basic\"", "\"race\"", "\"war\""},
        optional = true,
        default = "\"saddle_race\"",
    },
    tag = {
        type = "string",
        desc = "An entity tag.",
        sample = {"\"beefalo\"", "\"merm\"", "\"player\""},
    },
    ["tags..."] = {
        type = "string",
        desc = "0 or more other tags.",
        optional = true,
        isvararg = true,
    },
    tendency = {
        type = "string",
        desc = "A Beefalo tendency.",
        sample = {"\"RIDER\"", "\"ORNERY\"", "\"DEFAULT\"", "\"PUDGY\""},
        optional = true,
        default = "\"RIDER\"",
    },
    toggle = {
        type = "boolean",
        desc = "If true, turn the mode on. If false, turn the mode off.",
        sample = {"true", "false"},
    },
    verbose = {
        type = "boolean",
        desc = "If true, print all commands' help information. Otherwise just print the name.",
        optional = true,
        default = false,
    },
}

---@class Caller
---@field doc DocString
---@field fn function

local Callers = {}

-- Populated at the very end of this file, when all the functions are known.
---@type Map<Caller, string>
Callers.aliases = {}

---@type metatable
Callers.mt = {
    ---@param t Caller
    ---@param ... any
    __call = function(t, ...) return t.fn(...) end,
    
    ---@param t Caller
    __tostring = function(t) return "CustomCmd:" .. Callers.aliases[t] end,
}

---@param caller Caller
function Callers:new(caller)
    ---@type Caller
    return _G.setmetatable(caller, self.mt)
end

function Callers:is_instance(t)
    return _G.getmetatable(t) == self.mt
end

CustomCmd.count_all = Callers:new({
    doc = {
        params = {"prefab", "prefabs..."},
        sample = {
            "%s(\"pigman\")",
            "%s(\"pigman\", \"spider\", \"beefalo\")",
        },
    },
    fn = CustomCmd.Count:make_fn("count_all", false),
})

CustomCmd.remove_all = Callers:new({
    doc = CustomCmd.count_all.doc,
    fn = CustomCmd.Count:make_fn("remove_all", true)
})

--- HELP UTILITIES -------------------------------------------------------- {{{1

---@param name string
---@param param ParamInfo
function CustomCmd:print_param(name, param)
    if param.optional then
        self.Util:printf("[%s]: %s", name, param.type)
    else
        self.Util:printf("<%s>: %s", name, param.type)
    end
    self.Util:printf("\t%s", param.desc)
    if param.sample then
        self.Util:printf("\tE.g. %s", table.concat(param.sample, ", "))
    end
    if param.default then
        self.Util:printf("\tDefaults to %s if not specified.", param.default)
    end
end

---@param cmd string|Caller Docs key or caller instance.
function CustomCmd:get_usage(cmd)
    local key, caller = cmd, nil
    if type(cmd) == "string" then
        if key:find("^CustomCmd%.") then
            key = key:gsub("^CustomCmd%.", "")
        end
        ---@type Caller
        caller = self[key]
    else
        ---@type string, Caller
        key, caller = Callers.aliases[key], cmd
    end
    if not Callers:is_instance(caller) then
        return nil
    end
    return caller
end

---@param cmd string|Caller Docs key or caller instance.
function CustomCmd:print_usage(cmd)
    local caller = self:get_usage(cmd)
    if not caller then
        self.Util:printf("Unknown custom command '%s'.", tostring(cmd))
        self.Util:printf("See %s().", tostring(self.list))
        return
    end

    self.Util:printf("---SYNTAX---")
    local _params = {} -- silly but need to print `prefabs...` as `...`
    for _, v in ipairs(caller.doc.params) do
        _params[#_params + 1] = Params[v].isvararg and "..." or v
    end
    self.Util:printf("%s(%s)", tostring(caller), table.concat(_params, ", "))

    self.Util:printf("---PARAMS---")
    if #caller.doc.params > 0 then
        for _, key in ipairs(caller.doc.params) do
            self:print_param(key, Params[key])
        end
    else
        print("No parameters.")
    end

    self.Util:printf("---SAMPLE---")
    for _, v in ipairs(caller.doc.sample) do
        self.Util:printf("%s", v:format(tostring(caller)))
    end

    self.Util:printf("---RETURN---")
    if caller.doc.retval then
        self:print_param("retval", caller.doc.retval)
    else
        print("No return value/s.")
    end
end

CustomCmd.list = Callers:new({
    doc = {
        params = {"verbose"},
        sample = {"%s()", "%s(true)", "%s(false)"},
    },
    
    ---@param self CustomCmd
    ---@param verbose boolean?
    fn = function(self, verbose)
        print("---COMMANDS LIST---")
        for k, v in pairs(self) do
            if Callers:is_instance(v) then
                if verbose then
                    self:print_usage(k)
                    print()
                else
                    print(k)
                end
            end
        end
    end,
})

CustomCmd.help = Callers:new({
    doc = {
        params = {"command"},
        sample = {
            "%s(\"give_to\")",
            "%s(\"CustomCmd.get_tags\")",
            "%s(CustomCmd.remove_all\")",
        },
    },
    ---@param self CustomCmd
    ---@param what? string|Caller
    fn = function(self, what)
        if not what then
            print("---CUSTOMCMD HELP---")
            self:help(self.help)
            self:list()
            return
        end
        self:print_usage(what)
    end,
})

-- 1}}} ------------------------------------------------------------------------

--- TAG FUNCTIONS --------------------------------------------------------- {{{1

---@alias Tags table<string, boolean>
---@alias GUID integer

local _tags = {
    memoized = {}, ---@type table<GUID, Tags>
    mt = {}, ---@type metatable
}

---@param inst table
function _tags:new(inst)
    -- Contains the individual tags as seen from the debug string.
    -- You only really need the keys, as the keys themselves are the tags.
    ---@type Tags
    local ret = self.memoized[inst.GUID] or _G.setmetatable({}, self.mt)
    if not self.memoized[inst.GUID] then
        self.memoized[inst.GUID] = ret
    end

    -- Erase previous contents, if any, to avoid bad data later on.
    for k in pairs(ret) do
        ret[k] = nil
    end

    -- The string between `"Tags: "` and `"\n"` in the debug string
    -- `"%w+"` matches only "word" characters, that is:
    -- alphabeticals `[a-zA-Z]`, numericals `[0-9]` and underscores `[_]`.
    for word in CustomCmd.Util:get_debugstring_tags(inst):gmatch("%w+") do
        ret[word] = true
    end
    return ret
end

---@param t Tags
function _tags.mt.__tostring(t)
    local s = {}
    for k in pairs(t) do
        s[#s + 1] = k
    end
    return table.concat(s, ", ")
end

CustomCmd.get_tags = Callers:new({
    doc = {   
        params = {"inst"},
        sample = {
            "%s(ThePlayer)",
            "%s(c_find(\"beefalo\"))",
            "%s(c_select())",
        },
        retval = {
            type = "table<string, boolean>",
            desc = "A key-value table. Each key is the tag, each value is `true`.",
        }
    },
    -- Pass an entity to get the tags of.
    ---@param self CustomCmd
    ---@param inst table
    fn = function(self, inst) 
        if not (inst and type(inst) == "table") then
            self:print_usage("get_tags")
            return nil
        end
        return _tags:new(inst)
    end,
})


CustomCmd.add_tags = Callers:new({
    doc = {
        params = {"inst", "tag", "tags..."},
        sample = {
            "%s(ThePlayer, \"merm\", \"beefalo\")",
            "%s(c_findnext(\"merm\"), \"pigman\")",
            "%s(AllPlayers[2], \"player\")",
        },
    },
    ---@param self CustomCmd
    ---@param inst table
    ---@param tag string
    ---@param ... string
    fn = function(self, inst, tag, ...)
        if not (inst and tag) then
            self:print_usage("add_tags")
            return
        end
        for _, v in ipairs{tag, ...} do
            if inst:HasTag(v) then
                self.Util:printf("%s already has tag '%s'!", tostring(inst), v)
            else
                inst:AddTag(v)
            end
        end
    end,
})

CustomCmd.remove_tags = Callers:new({
    doc = CustomCmd.add_tags.doc,
    
    ---@param self CustomCmd
    ---@param inst table
    ---@param tag string
    ---@param ... string
    fn = function(self, inst, tag, ...)
        if not (inst and tag) then
            self:print_usage("remove_tags")
            return
        end
        for _, v in ipairs{tag, ...} do
            if not inst:HasTag(v) then
                self.Util:printf("%s does not have tag '%s'!", tostring(inst), v)
            else
                inst:RemoveTag(v)
            end
        end
    end,
})

--- 1}}} -----------------------------------------------------------------------

--- ITEM FUNCTIONS -------------------------------------------------------- {{{1

CustomCmd.give_to = Callers:new({
    doc = {
        params = {"player_number", "prefab", "item_count"},
        sample = {"%s(1, \"log\")", "%s(3, \"meat\", 20)"},
    },

    ---@param self CustomCmd
    ---@param player_number integer
    ---@param prefab string
    ---@param item_count? integer
    fn = function(self, player_number, prefab, item_count)
        if player_number == nil then
            self:print_usage("give_to")
            return
        end
        local player = self.Check:player(player_number)
        prefab = self.Check:prefab(prefab)
        item_count = self.Check:count(item_count)
        -- All 3 validation functions return the appropriate handles/fallbacks,
        -- and return `nil` if a non-`nil` input was invalid for that use case.
        if not (player and prefab and item_count) then
            return
        end
        self.Util:give_item(player, prefab, item_count)
    end,
})

CustomCmd.give_all = Callers:new({
    doc = {
        params = {"prefab", "item_count"},
        sample = {"%s(\"log\")", "%s(\"meat\", 20)"},
    },
    
    ---@param self CustomCmd
    ---@param prefab string
    ---@param item_count? integer
    fn = function(self, prefab, item_count)
        if prefab == nil then
            self:print_usage("give_all")
            return
        end
        prefab = self.Check:prefab(prefab)
        item_count = self.Check:count(item_count)
        if not (prefab and item_count) then
            return
        elseif #_G.AllPlayers == 0 then
            print("There are no players in the server to give items to!")
            return
        end
        for _, player in ipairs(_G.AllPlayers) do
            self.Util:give_item(player, prefab, item_count)
        end
    end,
})

--- 1}}} -----------------------------------------------------------------------

--- GODMODE/CREATIVE FUNCTIONS -------------------------------------------- {{{1

---@param what string
---@param status boolean?
function CustomCmd:print_toggle(what, status)
    local shard = self.Util:get_shard()
    self.Util:printf("%s - Set everyone's %s to '%s'.", shard, what, tostring(status))
end

CustomCmd.set_creative = Callers:new({
    doc = {
        params = {},
        sample = {"%s()"},
    },
    -- See: https://github.com/penguin0616/dst_gamescripts/blob/master/consolecommands.lua#L354
    ---@param self CustomCmd
    ---@param toggle boolean
    fn = function(self, toggle)
        if type(toggle) ~= "boolean" then
            print("CustomCmd:set_creative(): `toggle` must be a boolean.")
            return
        end

        for _, player in ipairs(_G.AllPlayers) do
            player.components.builder.freebuildmode = toggle
            player:PushEvent("techlevelchange")
        end
        
        self:print_toggle("creative mode", toggle)
    end

})

CustomCmd.set_godmode = Callers:new({
    doc = CustomCmd.set_creative.doc,
    -- Please refer to the following:
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/health.lua#L116
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/health.lua#L355
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/sanity.lua#L232
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/hunger.lua#L113
    ---@param self CustomCmd
    ---@param toggle boolean
    fn = function(self, toggle)
        if type(toggle) ~= "boolean" then
            print("CustomCmd:set_godmode(): `toggle` must be a boolean.")
            return
        end

        for _, player in ipairs(_G.AllPlayers) do
            player.components.health:SetInvincible(toggle)
            if toggle then
                player.components.health:SetPercent(1)
                player.components.sanity:SetPercent(1)
                player.components.hunger:SetPercent(1)
                player.components.moisture:SetPercent(0)
            end
        end
        self:print_toggle("godmode", toggle)
    end,
})

CustomCmd.creative_on = Callers:new({
    doc = {
        params = {"toggle"},
        sample = {"%s(true)", "%s(false)"},
    },
    fn = function(self) self:set_creative(true) end,
})

CustomCmd.creative_off = Callers:new({
    doc = CustomCmd.creative_on.doc,
    fn = function(self) self:set_creative(false) end,
})

CustomCmd.godmode_on = Callers:new({
    doc = CustomCmd.creative_on.doc,
    fn = function(self) self:set_godmode(true) end
})

CustomCmd.godmode_off = Callers:new({
    doc = CustomCmd.creative_on.doc,
    fn = function(self) self:set_godmode(false) end
})

--- 1}}} -----------------------------------------------------------------------

--- BEEFALO FUNCTIONS ----------------------------------------------------- {{{1

CustomCmd.spawn_beef = Callers:new({
    doc = {
        params = {"player_number", "tendency", "saddle"},
        sample = {
            "%s(1, \"RIDER\", \"saddle_race\")",
            "%s(3, \"ORNERY\")",
            "%s(2, nil, \"saddle_war\")",
        },
    },

    ---@param self CustomCmd
    ---@param player_number integer
    ---@param tendency "RIDER"|"ORNERY"|"DEFAULT"|"PUDGY"
    ---@param saddle "saddle_basic"|"saddle_race"|"saddle_war"|"basic"|"race"|"war"
    fn = function(self, player_number, tendency, saddle)
        if player_number == nil then
            self:print_usage("spawn_beef")
            return
        end
        -- No fallback: get `nil` if `player_number` is invalid index to `AllPlayers`
        local player = self.Check:player(player_number)
        tendency = self.Check:tendency(tendency)
        saddle = self.Check:saddle(saddle)
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
        beef.components.hunger:SetPercent(0.5)
        beef.components.rideable:SetSaddle(nil, _G.SpawnPrefab(saddle))
        self.Util:give_item(player, "beef_bell")
    end
})
--- 1}}} -----------------------------------------------------------------------

for k, v in pairs(CustomCmd) do
    if Callers:is_instance(v) then
        Callers.aliases[v] = k
    end
end
