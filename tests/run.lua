local root = "AddOns/EQOLAyijeAnchor/tests/"

local knownTests = {
    eqol_config = root .. "test_eqol_config.lua",
}

local function resolveTest(arg)
    if arg:match("%.lua$") then
        if arg:match("^AddOns/") then
            return arg
        end
        return root .. arg
    end
    return knownTests[arg] or (root .. "test_" .. arg .. ".lua")
end

local args = {...}
local files = {}

if #args == 0 then
    for _, path in pairs(knownTests) do
        files[#files + 1] = path
    end
else
    for _, arg in ipairs(args) do
        files[#files + 1] = resolveTest(arg)
    end
end

for _, file in ipairs(files) do
    local ok, err = pcall(dofile, file)
    if not ok then
        io.stderr:write("FAIL " .. file .. ": " .. tostring(err) .. "\n")
        os.exit(1)
    end
    print("PASS " .. file)
end
