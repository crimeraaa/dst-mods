local IS_LOCAL = true
local APPEND = (IS_LOCAL and "Local") or "Client"

---- BASIC INFORMATION ---------------------------------------------------------

-- Formatted string, e.g. `"Mod Template (Local)"`
name = ("Mod Template (%s)"):format(APPEND)
author = "crimeraaa"
description = "This is a template mod!"

-- Commenting out so the game won't constantly complain in logs.
-- However, making your own modicon is rather easy! Just create an `images`
-- folder under your mod's main folder and place the desired image there.
-- icon_atlas = "modicon.xml"
-- icon = "modicon.tex"

---- VERSIONING ----------------------------------------------------------------

version = "1.0.0"
api_version = 10

---- COMPATIBILITY -------------------------------------------------------------

dst_compatible = true
dont_starve_compatible = false

---- MOD SCOPE -----------------------------------------------------------------

client_only_mod = true
server_only_mod = false
all_clients_require_mod = false

---- HELPER FUNCTIONS ----------------------------------------------------------

-- Creates an individual option with `description`, `data` and `hover` fields.
-- You'll probably find you'll need this a lot when creating complex options.
-- Table fields can be empty, such as for `AddTitle`.
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

-- Creates a modinfo option that the user cannot see.
-- Useful for tranferring internal values between modinfo and modmain.
local function add_hidden(name, value)
    return {
        name = name,
        label = nil,
        hover = nil,
        -- It appears that if this is `nil`, there is no resulting newline.
        options = nil,
        default = value,
    }
end

-- Need this as in modinfo, much of Lua's libaries are unavailable to us.
-- So we can't call something like `table.insert`.
-- 
-- Note that the `#` table operator only applies to the array portion.
-- Meaning that non-numeric keys aren't part of its count.
local function table_append(tbl, element)
    -- Need add 1 since Lua is 1-based.
    tbl[#tbl + 1] = element
end

---- CONFIGURATIONS OPTIONS PROPER ---------------------------------------------

configuration_options = {}