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

local profiles = ctx.ns.profiles

assert(ctx.ns.profiles.CreateProfile("Arena") == true, "expected Arena profile to be created")
assert(ctx.ns.profiles.CreateProfile("Imported") == true, "expected Imported profile to be created")

local arenaProfile = assert(profiles.GetProfile("Arena"))
arenaProfile.eqol.sources.player.enabled = true
arenaProfile.castbar.target = "utility"
arenaProfile.castbar.x = 42

local importedProfile = assert(profiles.GetProfile("Imported"))
importedProfile.eqol.sources.player.enabled = false
importedProfile.castbar.target = "screen"
importedProfile.castbar.x = -7

assert(profiles.SwitchProfile("Arena") == true, "expected Arena to become the active profile")
assert(profiles.GetActiveProfileName() == "Arena", "expected Arena to be active before import")

local exported = assert(ctx.ns.serialization.ExportProfile("Arena"))
assert(exported:match("^EQAYA"), "expected export prefix")

local parsed = assert(ctx.ns.serialization.DeserializeProfileString(exported))
assert(parsed.meta.profile == "Arena", "expected exported profile name to survive")
assert(parsed.meta.version == 2, "expected payload version to be explicit")

local encodedPayload = exported:sub(#ctx.ns.EXPORT_PREFIX + 1)
local decodedPayload = assert(C_EncodingUtil.DeserializeCBOR(encodedPayload))
decodedPayload.meta.version = 999
local badVersionExport = ctx.ns.EXPORT_PREFIX .. assert(C_EncodingUtil.SerializeCBOR(decodedPayload))
local badVersionOk, badVersionErr = ctx.ns.serialization.DeserializeProfileString(badVersionExport)
assert(badVersionOk == nil, "expected unsupported export version to be rejected")
assert(type(badVersionErr) == "string" and badVersionErr:find("version", 1, true), "expected unsupported version error")

assert(ctx.ns.serialization.ImportIntoProfile(exported, "Imported") == true, "expected import into Imported to succeed")
assert(profiles.GetActiveProfileName() == "Arena", "expected import into non-active profile to keep active profile unchanged")

local replacedProfile = assert(profiles.GetProfile("Imported"))
assert(replacedProfile.castbar.target == "utility", "expected target profile castbar target to be replaced")
assert(replacedProfile.castbar.x == 42, "expected target profile castbar x to be replaced")
assert(replacedProfile.eqol.sources.player.enabled == true, "expected target profile EQOL sources to be replaced")
