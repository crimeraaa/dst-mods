local IS_LOCAL = true
local APPEND = (IS_LOCAL and "Local") or "Client"

---- BASIC INFORMATION ---------------------------------------------------------

name = ("Count Prefabs (%s)"):format(APPEND)
author = "crimeraaa"
description = 
[[
This mod counts prefabs on the ground in your loaded area and announces it.

Hold Keybind 1 (Default: C) and Left-click to use.
Hold Keybind 2 (Default: LCtrl) at the same time to Whisper.

Slash Command:
/count prefab mode 
Mode: 0 (Global Chat), 1 (Whisper), 2 (Local Chat) 
Default Mode is 0.
]]

---- VERSIONING ----------------------------------------------------------------

version = "1.2.1"
api_version = 10

---- COMPATIBILITY -------------------------------------------------------------

dst_compatible = true
dont_starve_compatible = false

---- MOD SCOPE -----------------------------------------------------------------

client_only_mod = true
server_only_mod = false
all_clients_require_mod = false

-- icon_atlas = "countprefabs.xml"
-- icon = "countprefabs.tex"

---- HELPER FUNCTIONS ----------------------------------------------------------

-- Creates an individual option with `description`, `data` and `hover` fields.
-- You'll probably find you'll need this a lot when creating complex options.
-- Table fields can be empty, such as for `add_title`.
---@param description? string
---@param data?        any
---@param hover?       string
local function format_option(description, data, hover)
    return {
        description = description or "",
        data        = data or 0,
        hover       = hover or "",
    }
end

-- Creates a row in your mod options menu that's just the `label` field.
-- Useful for visually separating things out.
---@param title string 
local function add_title(title)
    return {
        name = "",
        label = title,
        hover = "",
        -- Empty option.
        options = { format_option() },
        default = 0,
    }
end

---@param name string
---@param label string
---@param hover string
---@param options table
---@param default any
local function add_option(name, label, hover, options, default)
    return {
        name = name,
        label = label,
        hover = hover,
        options = options,
        default = default,
    }
end

---- CONFIGURATIONS OPTIONS PROPER ---------------------------------------------

local keys = {
    { display = "None--",       keynum = 0 },
    { display = "A",            keynum = 97 },
    { display = "B",            keynum = 98 },
    { display = "C",            keynum = 99 },
    { display = "D",            keynum = 100 },
    { display = "E",            keynum = 101 },
    { display = "F",            keynum = 102 },
    { display = "G",            keynum = 103 },
    { display = "H",            keynum = 104 },
    { display = "I",            keynum = 105 },
    { display = "J",            keynum = 106 },
    { display = "K",            keynum = 107 },
    { display = "L",            keynum = 108 },
    { display = "M",            keynum = 109 },
    { display = "N",            keynum = 110 },
    { display = "O",            keynum = 111 },
    { display = "P",            keynum = 112 },
    { display = "Q",            keynum = 113 },
    { display = "R",            keynum = 114 },
    { display = "S",            keynum = 115 },
    { display = "T",            keynum = 116 },
    { display = "U",            keynum = 117 },
    { display = "V",            keynum = 118 },
    { display = "W",            keynum = 119 },
    { display = "X",            keynum = 120 },
    { display = "Y",            keynum = 121 },
    { display = "Z",            keynum = 122 },
    { display = "--None--",     keynum = 0 },
    { display = "Period",       keynum = 46 },
    { display = "Slash",        keynum = 47 },
    { display = "Semicolon",    keynum = 59 },
    { display = "LeftBracket",  keynum = 91 },
    { display = "RightBracket", keynum = 93 },
    { display = "F1",           keynum = 282 },
    { display = "F2",           keynum = 283 },
    { display = "F3",           keynum = 284 },
    { display = "F4",           keynum = 285 },
    { display = "F5",           keynum = 286 },
    { display = "F6",           keynum = 287 },
    { display = "F7",           keynum = 288 },
    { display = "F8",           keynum = 289 },
    { display = "F9",           keynum = 290 },
    { display = "F10",          keynum = 291 },
    { display = "F11",          keynum = 292 },
    { display = "F12",          keynum = 293 },
    { display = "Up",           keynum = 273 },
    { display = "Down",         keynum = 274 },
    { display = "Right",        keynum = 275 },
    { display = "Left",         keynum = 276 },
    { display = "PageUp",       keynum = 280 },
    { display = "PageDown",     keynum = 281 },
    { display = "Home",         keynum = 278 },
    { display = "Insert",       keynum = 277 },
    { display = "Delete",       keynum = 127 },
    { display = "End",          keynum = 279 },
    { display = "--None--",     keynum = 0 },
    { display = "RShift",       keynum = 303 },
    { display = "LShift",       keynum = 304 },
    { display = "LCtrl",        keynum = 306 },
    { display = "RCtrl",        keynum = 305 },
    { display = "RAlt",         keynum = 307 },
    { display = "LAlt",         keynum = 308 },
    { display = "--None",       keynum = 0 },
}

local fmts = {
    mode    = "Sends the count message %s.",
    keybind = "Hold this key %s.\nDefault: %s.",
    header  = "Use this mode by default for the %s.\nDefault: %s Chat."
}

local hovers = {
    mode0 = fmts.mode:format("to everybody in the server"),
    mode1 = fmts.mode:format("only to players in your vicinity"),
    mode2 = fmts.mode:format("to your local chat, which only you can see"),
    
    keybind1 = fmts.keybind:format("and Left-click the prefab", "C"),
    keybind2 = fmts.keybind:format("with Keybind 1 held down", "LCtrl"),
    keybind3 = fmts.keybind:format("with Keybinds 1 & 2 held down", "None")
}

local menu = {
    slash = fmts.header:format("slash command", "Global"),
    keybind1 = fmts.header:format("Keybind 1", "Global"),
    keybind2 = fmts.header:format("Keybind 2", "Whisper"),
    keybind3 = fmts.header:format("Keybind 3", "Local"),
}

local function make_keybinds()
    local t = {}
    for i = 1, #keys do
        t[i] = format_option(keys[i].display, keys[i].keynum)
    end
    return t
end

local opts = {}
opts.keybinds = make_keybinds()
opts.modes = {
    format_option("Global Chat", 0, hovers.mode0),
    format_option("Whisper",     1, hovers.mode1),
    format_option("Local Chat",  2, hovers.mode2),
}

configuration_options = {
    ---- DEFAULT MODES ---------------------------------------------------------
    add_title("Default Modes"),

    -- Default is Global Chat.
    add_option("default_slash", "Slash Command", menu.slash, opts.modes, 0),

    -- Default is Global Chat.
    add_option("default_key1", "Keybind 1", menu.keybind1, opts.modes, 0),

    -- Default is Whisper Chat.
    add_option("default_key2", "Keybind 2", menu.keybind2, opts.modes, 1),

    -- Default is Local Chat.
    add_option("default_key3", "Keybind 3", menu.keybind3, opts.modes, 2),

    ---- USER KEYBINDS ---------------------------------------------------------
    add_title("Hook Keybinds"),

    -- default is C.
    add_option("keybind_key1", "Keybind 1", hovers.keybind1, opts.keybinds, 99), 

    -- default is LCtrl.
    add_option("keybind_key2", "Keybind 2", hovers.keybind2, opts.keybinds, 306), 

    -- default is None.
    add_option("keybind_key3", "Keybind 3", hovers.keybind3, opts.keybinds, 0), 
}
