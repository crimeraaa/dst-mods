---@diagnostic disable: duplicate-doc-field
---@class UsageString
---@field syntax string
---@field sample string
---@field params string
---@field retval string

UsageStrings = {}

UsageStrings.c_countall = {
    -- To be supplied by the call to `make_prefabsfn`
    syntax = "c_countall(<prefab>, [...])",
    params = [[
    <prefab>: 
        Lowercase string of the prefab name, e.g. "pigman".
    [...]: 
        Variadic arguments. 0 or more prefab strings you also want to count/remove.]],
    sample = [[
    c_countall("pigman"),
    c_countall("spider", "pigman")]],
}

UsageStrings.c_removeall = {}
for k, v in pairs(UsageStrings.c_countall) do
    UsageStrings.c_removeall[k] = v:gsub("c_countall", "c_removeall")
end

UsageStrings.c_gettags = {
    syntax = "c_gettags(<inst>)",
    params = [[
    <inst>: 
        An entity instance, (which is a Lua table), e.g. ThePlayer.]],
    sample = [[
    c_gettags(ThePlayer)
    c_gettags(c_find("beefalo"))]],
    retval = [[
    table<string, boolean>: 
        A key-value table where each key is the tag, and each value is the boolean true.
        This makes it so you can do something like this:
            for k, v in pairs(c_gettags(ThePlayer)) do print(k); end;]],
}

UsageStrings.c_giveto = {
    syntax = "c_giveto(<player_number>, <prefab>, [count])",
    params = [[
    <player_number>:
        Index into the AllPlayers table to retrieve the player entity.
    <prefab>:
        Lowercase string of the prefab name to give, e.g. "log".
    [count]:
        How many of this prefab to give. Defaults to 1 if nil.
        If specified, must be 1 or greater.
    ]],
    sample = [[
    c_giveto(1, "log")
    c_giveto(3, "meat", 20)
    ]],
}

UsageStrings.c_giveall = {
    syntax = "c_giveall(<prefab>, [count])",
    params = [[
    <prefab>:
        Lowercase string of the prefab name to give, e.g. "log".
    [count]:
        How many of this prefab to give. Defaults to 1 if nil.
        If specified, must be 1 or greater.
    ]],
    sample = [[
    c_giveall("log")
    c_giveall("meat", 20)
    ]],
}

UsageStrings.c_spawnbeef = {
    syntax = "c_spawnbeef(player_number, [tendency], [saddle])",
    params = [[
    <player_number>:
        An integer used to index into the AllPlayers table.
    [tendency]:
        Uppercase string that is one of the following:
            "RIDER"
            "ORNERY"
            "DEFAULT"
            "PUDGY"
        If nil, we will fall back to "RIDER".
    [saddle]:
        Lowercase string that is one of the following:
            "saddle_basic"
            "saddle_race"
            "saddle_war"
            "basic"
            "race"
            "war"
        If nil, we will fall back to "saddle_race" (Glossamer Saddle).
        You can omit the "saddle_" part of the string and it should still work.]],
    sample = [[
    c_spawnbeef(1, "RIDER", "saddle_race")
    c_spawnbeef(3, "ORNERY", nil)
    c_spawnbeef(2, nil, "saddle_war")]],
}

return UsageStrings
