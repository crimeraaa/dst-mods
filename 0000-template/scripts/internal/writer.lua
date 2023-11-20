-- Namespace to help writer DST modinfo files.
ModinfoWriter = {}

------------------------------- HELPER FUNCTIONS -------------------------------

-- Creates an individual option with `description`, `data` and `hover` fields.
-- You'll probably find you'll need this a lot when creating complex options.
-- Table fields can be empty, such as for `ModinfoWriter:add_title`.
---@param description? string
---@param data?        any
---@param hover?       string
function ModinfoWriter:format_option(description, data, hover)
    return {
        description = description or "",
        data        = data or 0,
        hover       = hover or "",
    }
end

-- Creates a row in your mod options menu that's just the `label` field.
-- Useful for visually separating things out.
---@param title string 
function ModinfoWriter:add_title(title)
    return {
        name = "",
        label = title,
        hover = "",
        -- Empty option.
        options = { self:format_option() },
        default = 0,
    }
end

-- Creates an option in the mod settings menu that the user can work with.
---@param name string
---@param label string
---@param hover string
---@param options table
---@param default any
function ModinfoWriter:add_option(name, label, hover, options, default)
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
---@param name string
---@param value any
function ModinfoWriter:add_hidden(name, value)
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
function ModinfoWriter:table_append(tbl, element)
    -- Need add 1 since Lua is 1-based.
    tbl[#tbl + 1] = element
end

return ModinfoWriter
