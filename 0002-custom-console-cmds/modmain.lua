---@class Map<K, V>: {[K]: V}
---@class Dictionary<T>: {[string]: T}

---@class ParamInfo
---@field type string
---@field desc string
---@field sample? string[]
---@field optional? boolean
---@field default? string|number
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
        desc = "A prefab name string as seen in the DST Lua source code.",
        sample = {"\"log\"", "\"pigman\"", "\"meat\""},
    },
    prefabs = {
        type = "string",
        desc = "0 or more other prefab names.",
        sample = {"\"log\"", "\"pigman\"", "\"meat\""},
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
    tags = {
        type = "string",
        desc = "0 or more other tags.",
        sample = {"\"beefalo\"", "\"merm\"", "\"player\""},
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
    },
    verbose = {
        type = "boolean",
        desc = "If true, print all commands' help information. Otherwise just print the name.",
        optional = true,
        default = "false",
    },
}

---@class Caller
---@field doc DocString
---@field fn function

local Caller = {}

-- Populated at the very end of this file, when all the functions are known.
---@type Map<Caller, string>
Caller.aliases = {}

---@type metatable
Caller.mt = {
    -- `CustomCmd:count_all(...)` is equivalent to:
    -- `CustomCmd.count_all(CustomCmd, ...)`, which in turn calls:
    -- `getmetatable(CustomCmd.count_all).__call(CustomCmd, ...)`
    ---@param caller Caller
    ---@param ... any
    __call = function(caller, ...)
        return caller.fn(...)
    end,
    
    ---@param caller Caller
    __tostring = function(caller)
        return "CustomCmd:" .. Caller.aliases[caller]
    end,
}

---@param caller Caller
function Caller:new(caller)
    ---@type Caller
    return _G.setmetatable(caller, self.mt)
end

function Caller:is_instance(t)
    return _G.getmetatable(t) == self.mt
end

CustomCmd.count_all = Caller:new({
    doc = {
        params = {"prefabs"},
        sample = {
            "%s(\"pigman\")",
            "%s(\"pigman\", \"spider\", \"beefalo\")",
        },
    },
    fn = CustomCmd.Count:make_fn("count_all", false),
})

CustomCmd.remove_all = Caller:new({
    doc = CustomCmd.count_all.doc,
    fn = CustomCmd.Count:make_fn("remove_all", true)
})

--- HELP UTILITIES -------------------------------------------------------- {{{1

---@param display string For varargs, ensure this is `"..."`.
---@param param ParamInfo
function CustomCmd:print_param(display, param)
    -- `string.byte` will attempt to return `j - i` values (here, `2 - 1`).
    local left, right = string.byte(param.optional and "[]" or "<>", 1, 2)
    self.Util:printf("%c%s%c: %s", left, display, right, param.type)
    self.Util:printf("\t%s", param.desc)
    if param.sample then
        self.Util:printf("\tE.g. %s", table.concat(param.sample, ", "))
    end
    if param.default then
        self.Util:printf("\tDefaults to %s if not specified.", param.default)
    end
end

---@param cmd string|Caller Docs key or caller instance.
function CustomCmd:get_caller(cmd)
    ---@type Caller
    local caller = type(cmd) == "string" and self[cmd:gsub("^CustomCmd[.:]", "")] or cmd
    if not Caller:is_instance(caller) then
        return nil
    end
    return caller
end

---@param cmd string|Caller Docs key or caller instance.
function CustomCmd:print_usage(cmd)
    local caller = self:get_caller(cmd)
    if not caller then
        self.Util:printf("Unknown custom command '%s'.", tostring(cmd))
        self.Util:printf("See %s().", tostring(self.list))
        return
    end

    self.Util:printf("---SYNTAX---")
    local _params = {} -- silly but need to print `prefabs` as `...`
    for _, key in ipairs(caller.doc.params) do
        _params[#_params + 1] = Params[key].isvararg and "..." or key
    end
    self.Util:printf("%s(%s)", tostring(caller), table.concat(_params, ", "))

    self.Util:printf("---PARAMS---")
    if #caller.doc.params > 0 then
        for i, key in ipairs(caller.doc.params) do
            self:print_param(_params[i], Params[key])
        end
    else
        print("No parameters.")
    end

    self.Util:printf("---SAMPLE---")
    -- Assume `fmt` only has `"%s"` and no other format specifiers.
    for _, fmt in ipairs(caller.doc.sample) do
        self.Util:printf(fmt, tostring(caller))
    end

    self.Util:printf("---RETURN---")
    if caller.doc.retval then
        self:print_param("retval", caller.doc.retval)
    else
        print("No return value/s.")
    end
end

CustomCmd.list = Caller:new({
    doc = {
        params = {"verbose"},
        sample = {"%s()", "%s(true)", "%s(false)"},
    },
    
    ---@param self CustomCmd
    ---@param verbose boolean?
    fn = function(self, verbose)
        print("---COMMANDS LIST---")
        for field, caller in pairs(self) do
            if Caller:is_instance(caller) then
                if verbose then
                    self:print_usage(caller)
                    print()
                else
                    print(field)
                end
            end
        end
    end,
})

CustomCmd.help = Caller:new({
    doc = {
        params = {"command"},
        sample = {
            "%s(\"give_to\")",
            "%s(\"CustomCmd.get_tags\")",
            "%s(CustomCmd.remove_all)",
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
     ---@type table<GUID, Tags>
    memoized = {},

     ---@type metatable
    mt = {
        ---@param t Tags
        __tostring = function(t)
            local s = {}
            for k in pairs(t) do
                s[#s + 1] = k
            end
            return table.concat(s, ", ")
        end
    },
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

CustomCmd.get_tags = Caller:new({
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
        if type(inst) ~= "table" then
            self:print_usage("get_tags")
            return nil
        end
        return _tags:new(inst)
    end,
})


CustomCmd.add_tags = Caller:new({
    doc = {
        params = {"inst", "tags"},
        sample = {
            "%s(ThePlayer, \"merm\", \"beefalo\")",
            "%s(c_findnext(\"merm\"), \"pigman\")",
            "%s(AllPlayers[2], \"player\")",
        },
    },
    ---@param self CustomCmd
    ---@param inst table
    ---@param ... string
    fn = function(self, inst, ...)
        local argc, argv = _G.select('#', ...), {...}
        -- Hard to determine if `inst` was not supplied to begin with
        if not inst and argc == 0 then
            self:print_usage("add_tags")
            return
        end
        for _, v in ipairs(argv) do
            if inst:HasTag(v) then
                self.Util:printf("%s already has tag '%s'!", tostring(inst), v)
            else
                inst:AddTag(v)
            end
        end
    end,
})

CustomCmd.remove_tags = Caller:new({
    doc = CustomCmd.add_tags.doc,
    
    ---@param self CustomCmd
    ---@param inst table
    ---@param ...  string
    fn = function(self, inst, ...)
        local argc, argv = _G.select('#', ...), {...}
        -- Hard to deteremine if `inst` was not supplied to begin with
        if not inst and argc == 0 then
            self:print_usage("remove_tags")
            return
        end
        for _, v in ipairs(argv) do
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

CustomCmd.give_to = Caller:new({
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
        prefab       = self.Check:prefab(prefab)
        item_count   = self.Check:count(item_count)
        if not (player and prefab and item_count) then
            return
        end
        self.Util:give_item(player, prefab, item_count)
    end,
})

CustomCmd.give_all = Caller:new({
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
        prefab, item_count = self.Check:prefab(prefab), self.Check:count(item_count)
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

---@param mode string
---@param status boolean?
function CustomCmd:print_toggle(mode, status)
    local shard = self.Util:get_shard()
    self.Util:printf("%s - Set everyone's %s to '%s'.", shard, mode, tostring(status))
end

-- Do this as `nil` or any non-boolean truthy argument may be a mistake.
---@param caller Caller
---@param toggle boolean
function CustomCmd:valid_toggle(caller, toggle)
    if type(toggle) ~= "boolean" then
        self.Util:printf("%s(): `toggle` must be a boolean.", tostring(caller))
        return false
    end
    return true
end

CustomCmd.set_creative = Caller:new({
    doc = {
        params = {},
        sample = {"%s()"},
    },
    -- See: https://github.com/penguin0616/dst_gamescripts/blob/master/consolecommands.lua#L354
    ---@param self CustomCmd
    ---@param toggle boolean
    fn = function(self, toggle)
        if not self:valid_toggle(self.set_creative, toggle) then
            return
        end
        for _, player in ipairs(_G.AllPlayers) do
            player.components.builder.freebuildmode = toggle
            player:PushEvent("techlevelchange")
        end
        self:print_toggle("creative mode", toggle)
    end

})

CustomCmd.set_godmode = Caller:new({
    doc = CustomCmd.set_creative.doc,
    -- Please refer to the following:
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/health.lua#L116
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/health.lua#L355
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/sanity.lua#L232
    -- https://github.com/penguin0616/dst_gamescripts/blob/master/components/hunger.lua#L113
    ---@param self CustomCmd
    ---@param toggle boolean
    fn = function(self, toggle)
        if not self:valid_toggle(self.set_godmode, toggle) then
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

CustomCmd.creative_on = Caller:new({
    doc = {
        params = {"toggle"},
        sample = {"%s(true)", "%s(false)"},
    },
    fn = function(self) self:set_creative(true) end,
})

CustomCmd.creative_off = Caller:new({
    doc = CustomCmd.creative_on.doc,
    fn = function(self) self:set_creative(false) end,
})

CustomCmd.godmode_on = Caller:new({
    doc = CustomCmd.creative_on.doc,
    fn = function(self) self:set_godmode(true) end
})

CustomCmd.godmode_off = Caller:new({
    doc = CustomCmd.creative_on.doc,
    fn = function(self) self:set_godmode(false) end
})

--- 1}}} -----------------------------------------------------------------------

--- BEEFALO FUNCTIONS ----------------------------------------------------- {{{1

---@param beef table A beefalo instance.
---@param player table A player instance.
---@param tendency string
---@param saddle string
function CustomCmd:tame_beef(beef, player, tendency, saddle)
    beef.Transform:SetPosition(player.Transform:GetWorldPosition())
    beef.components.domesticatable:DeltaDomestication(1)
    beef.components.domesticatable:DeltaObedience(1)
    beef.components.domesticatable:DeltaTendency(tendency, 1)
    beef:SetTendency()
    beef.components.domesticatable:BecomeDomesticated()
    beef.components.hunger:SetPercent(0.5)
    beef.components.rideable:SetSaddle(nil, _G.SpawnPrefab(saddle))
end

CustomCmd.spawn_beef = Caller:new({
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
        local player = self.Check:player(player_number)
        tendency = self.Check:tendency(tendency)
        saddle = self.Check:saddle(saddle)
        if not (player and tendency and saddle) then
            return
        end
        self:tame_beef(_G.c_spawn("beefalo"), player, tendency, saddle)
        self.Util:give_item(player, "beef_bell")
    end
})
--- 1}}} -----------------------------------------------------------------------

for k, v in pairs(CustomCmd) do
    if Caller:is_instance(v) then
        Caller.aliases[v] = k
    end
end
