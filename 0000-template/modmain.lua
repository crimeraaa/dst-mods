print("[MOD TEMPLATE] Before require:", ModinfoWriter)
ModinfoWriter = require("internal/writer")
print("[MOD TEMPLATE] After require:", ModinfoWriter)

print("[MOD TEMPLATE]:")
---@diagnostic disable-next-line: undefined-global
for k, v in pairs(env) do
    print(k, v)
end

