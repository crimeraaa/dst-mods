-- Only set to `true` when developing.
local mod_is_local = true
local mod_suffix = (mod_is_local and "Local") or "Server"

---- BASIC INFORMATION ---------------------------------------------------------

-- Formatted string, e.g. `"Mod Template (Local)"`
name = ("Custom Console Commands (%s)"):format(mod_suffix)
author = "crimeraaa"
description = [[
Useful helper commands meant to be used purely from the console.
Run either `CustomCmd:help()` or `CustomCmd:list()` for more information.]]
icon_atlas = "customcmd.xml"
icon = "customcmd.tex"

---- VERSIONING ----------------------------------------------------------------

version = "1.0.0"
api_version = 10

---- COMPATIBILITY -------------------------------------------------------------

dst_compatible = true
dont_starve_compatible = false

---- MOD SCOPE -----------------------------------------------------------------

client_only_mod = false
server_only_mod = false
all_clients_require_mod = true

-- TODO Comment out when these are needed.
-- ---- HELPER FUNCTIONS ----------------------------------------------------------

-- -- Creates an individual option with `description`, `data` and `hover` fields.
-- -- You'll probably find you'll need this a lot when creating complex options.
-- -- Table fields can be empty, such as for `AddTitle`.
-- ---@param description? string
-- ---@param data?        any
-- ---@param hover?       string
-- local function format_option(description, data, hover)
--     return {
--         description = description or "",
--         data        = data or 0,
--         hover       = hover or "",
--     }
-- end

-- -- Creates a row in your mod options menu that's just the `label` field.
-- -- Useful for visually separating things out.
-- ---@param title string 
-- local function add_title(title)
--     return {
--         name = "",
--         label = title,
--         hover = "",
--         -- Empty option.
--         options = { format_option() },
--         default = 0,
--     }
-- end

-- ---@param name string
-- ---@param label string
-- ---@param hover string
-- ---@param options table
-- ---@param default any
-- local function add_option(name, label, hover, options, default)
--     return {
--         name = name,
--         label = label,
--         hover = hover,
--         options = options,
--         default = default,
--     }
-- end

-- -- Creates a modinfo option that the user cannot see.
-- -- Useful for tranferring internal values between modinfo and modmain.
-- local function add_hidden(name, value)
--     return {
--         name = name,
--         label = nil,
--         hover = nil,
--         -- It appears that if this is `nil`, there is no resulting newline.
--         options = nil,
--         default = value,
--     }
-- end

-- -- Need this as in modinfo, much of Lua's libaries are unavailable to us.
-- -- So we can't call something like `table.insert`.
-- -- 
-- -- Note that the `#` table operator only applies to the array portion.
-- -- Meaning that non-numeric keys aren't part of its count.
-- local function table_append(tbl, element)
--     -- Need add 1 since Lua is 1-based.
--     tbl[#tbl + 1] = element
-- end

-- ---- CONFIGURATIONS OPTIONS PROPER ---------------------------------------------

-- configuration_options = {}
