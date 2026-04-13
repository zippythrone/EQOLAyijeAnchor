local function currentDir()
    local source = debug.getinfo(1, "S").source
    source = source:sub(2)
    return source:match("^(.*)/[^/]+$") or "."
end

local testsDir = currentDir()
local bootstrap = dofile(testsDir .. "/bootstrap.lua")
local ctx = bootstrap.newContext()

ctx.load("Core.lua")
ctx.load("EQOLConfig.lua")
ctx.load("CastBar.lua")
ctx.load("Profiles.lua")
ctx.load("Serialization.lua")

assert(ctx.ns.profiles.CreateProfile("Arena") == true, "expected Arena profile to be created")

local exported = assert(ctx.ns.serialization.ExportProfile("Arena"))
assert(exported:match("^EQAYA"), "expected export prefix")

local parsed = assert(ctx.ns.serialization.DeserializeProfileString(exported))
assert(parsed.meta.profile == "Arena", "expected exported profile name to survive")
assert(parsed.meta.version == 2, "expected payload version to be explicit")

assert(ctx.ns.serialization.ImportIntoProfile(exported, "Default") == true, "expected import into Default to succeed")
assert(ctx.ns.profiles.GetActiveProfileName() == "Default", "expected import into non-active profile to keep Default active")
