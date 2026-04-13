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

local profiles = ctx.ns.profiles
local castbar = ctx.ns.castbar

local activeProfile = assert(profiles.GetActiveProfile())
assert(activeProfile.castbar.target == "essential", "expected default castbar target")
assert(activeProfile.castbar.point == "TOP", "expected default castbar point")

assert(castbar.TrySetField("target", "utility") == true, "expected target update to succeed")
assert(activeProfile.castbar.target == "utility", "expected TrySetField to write into the active profile")

local db = castbar.GetDB()
db.point = "LEFT"
assert(activeProfile.castbar.point == "LEFT", "expected proxy assignment to commit through validation")

local ok, err = castbar.TrySetField("x", 301.5)
assert(ok == nil, "expected invalid x to be rejected")
assert(type(err) == "string" and err:find("whole number", 1, true), "expected invalid x error")
assert(activeProfile.castbar.x == 0, "expected invalid x to leave stored state unchanged")

local invalidWriteOk, invalidWriteErr = pcall(function()
    db.relativePoint = "NOT_A_POINT"
end)
assert(invalidWriteOk == false, "expected invalid proxy writes to fail")
assert(type(invalidWriteErr) == "string" and invalidWriteErr:find("Invalid relativePoint", 1, true), "expected invalid proxy write error")
assert(activeProfile.castbar.relativePoint == "BOTTOM", "expected failed proxy write to leave state unchanged")

assert(castbar.TrySetField("target", "screen") == true, "expected screen target update to succeed")
assert(activeProfile.castbar.target == "screen", "expected final target update to commit")

assert(profiles.CreateProfile("Arena") == true, "expected Arena profile to be created")
assert(profiles.SwitchProfile("Arena") == true, "expected Arena to become active")
assert(db.target == "screen", "expected proxy reads to follow the cloned active profile after switching")

db.x = 12
local arenaProfile = assert(profiles.GetActiveProfile())
assert(arenaProfile.castbar.x == 12, "expected proxy writes to target the new active profile")

assert(profiles.SwitchProfile("Default") == true, "expected Default to become active again")
assert(db.x == 0, "expected proxy reads to track the current active profile after switching back")
assert(activeProfile.castbar.x == 0, "expected old profile state to remain unchanged after switching")
