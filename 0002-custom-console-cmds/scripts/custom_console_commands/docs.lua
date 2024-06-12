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

---@type Dictionary<DocString>
local Templates = {
    void = {
        params = {},
        sample = {"%s()"},
    },
    bool = {
        params = {"toggle"},
        sample = {"%s(true)", "%s(false)"},
    },
    prefabs = {
        params = {"prefab", "prefabs..."},
        sample = {
            "%s(\"pigman\")",
            "%s(\"pigman\", \"spider\", \"beefalo\")",
        },
    },
    tags = {
        params = {"inst", "tag", "tags..."},
        sample = {
            "%s(ThePlayer, \"merm\", \"beefalo\")",
            "%s(c_findnext(\"merm\"), \"pigman\")",
            "%s(AllPlayers[2], \"player\")",
        },
    }
}

-- Hardcoded strings which are (usually) displayed when you invoke the commands
-- without any arguments. 
-- 
-- They're meant to teach you about the basics of the command.
-- Also to help you know about any quirks to take note of.
---@type Dictionary<DocString>
local Commands = {
    help = {
        params = {"command"},
        sample = {
            "%s(\"give_to\")",
            "%s(\"CustomCmd.get_tags\")",
            "%s(CustomCmd.remove_all\")",
        },
    },
    count_all = Templates.prefabs,
    remove_all = Templates.prefabs,
    get_tags = {
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
    add_tags = Templates.tags,
    remove_tags = Templates.tags,
    give_to = {
        params = {"player_number", "prefab", "item_count"},
        sample = {"%s(1, \"log\")", "%s(3, \"meat\", 20)"},
    },
    give_all = {
        params = {"prefab", "item_count"},
        sample = {"%s(\"log\")", "%s(\"meat\", 20)"},
    },
    set_creative = Templates.bool,
    creative_on  = Templates.void,
    creative_off = Templates.void,
    set_godmode  = Templates.bool,
    godmode_on   = Templates.void,
    godmode_off  = Templates.void,
    spawn_beef = {
        params = {"player_number", "tendency", "saddle"},
        sample = {
            "%s(1, \"RIDER\", \"saddle_race\")",
            "%s(3, \"ORNERY\")",
            "%s(2, nil, \"saddle_war\")",
        },
    },
}

---@type Dictionary<ParamInfo>
local Params = {
    command = {
        type = "string|function",
        desc = "A key into CustomCmd, sample string usage, or a function thereof.",
        sample = {"\"give_to\"", "\"CustomCmd.count_all\"", "CustomCmd.get_tags"},
        optional = true,
        default = "calling CustomCmd.list()",
    },
    prefab = {
        type = "string",
        desc = "Prefab name in Lua code.",
        sample = {"\"log\"", "\"pigman\"", "\"meat\""},
    },
    inst = {
        type = "table",
        desc = "An entity instance.",
        sample = {"ThePlayer", "c_findnext(\"beefalo\")", "c_spawn(\"pigman\")"},
    },
    tag = {
        type = "string",
        desc = "An entity tag.",
        sample = {"\"beefalo\"", "\"merm\"", "\"player\""},
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
    tendency = {
        type = "string",
        desc = "A Beefalo tendency.",
        sample = {"\"RIDER\"", "\"ORNERY\"", "\"DEFAULT\"", "\"PUDGY\""},
        optional = true,
        default = "\"RIDER\"",
    },
    saddle = {
        type = "string",
        desc = "A saddle prefab name. You can omit the \"saddle_\" part.",
        sample = {"\"saddle_basic\"", "\"saddle_race\"", "\"saddle_war\"",
            "\"basic\"", "\"race\"", "\"war\""},
        optional = true,
        default = "\"saddle_race\"",
    },
    toggle = {
        type = "boolean",
        desc = "If true, turn the mode on. If false, turn the mode off.",
        sample = {"true", "false"},
    },
    ["prefabs..."] = {
        type = "string",
        desc = "0 or more other prefabs.",
        optional = true,
        isvararg = true,
    },
    ["tags..."] = {
        type = "string",
        desc = "0 or more other tags.",
        optional = true,
        isvararg = true,
    }
}

return {Commands = Commands, Params = Params, Templates = Templates}
