local function currentDir()
    local source = debug.getinfo(1, "S").source
    source = source:sub(2)
    return source:match("^(.*)/[^/]+$") or "."
end

local testsDir = currentDir()
local knownTests = {
    { name = "eqol_config", path = testsDir .. "/test_eqol_config.lua" },
}

local function resolveTest(arg)
    if arg:match("%.lua$") then
        if arg:match("^/") then
            return arg
        end
        return testsDir .. "/" .. arg
    end
    for _, test in ipairs(knownTests) do
        if test.name == arg then
            return test.path
        end
    end
    return testsDir .. "/test_" .. arg .. ".lua"
end

local args = {...}
local files = {}

if #args == 0 then
    for _, test in ipairs(knownTests) do
        files[#files + 1] = test.path
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
