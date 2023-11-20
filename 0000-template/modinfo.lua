local IS_LOCAL = true
local APPEND = (IS_LOCAL and "Local") or "Client"

------------------------------- BASIC INFORMATION ------------------------------

-- Formatted string, e.g. `"Mod Template (Local)"`
name = ("Mod Template (%s)"):format(APPEND)
author = "crimeraaa"
description = "This is a template mod!"

-- Commenting out so the game won't constantly complain in logs.
-- However, making your own modicon is rather easy! Just create an `images`
-- folder under your mod's main folder and place the desired image there.
-- icon_atlas = "modicon.xml"
-- icon = "modicon.tex"

---------------------------------- VERSIONING ----------------------------------

version = "1.0.0"
api_version = 10

-------------------------------- COMPATIBILITY ---------------------------------

dst_compatible = true
dont_starve_compatible = false

----------------------------------- MOD SCOPE ----------------------------------

client_only_mod = true
server_only_mod = false
all_clients_require_mod = false

------------------------- CONFIGURATIONS OPTIONS PROPER ------------------------

configuration_options = {}
