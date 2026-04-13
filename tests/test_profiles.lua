local function currentDir()
    local source = debug.getinfo(1, "S").source
    source = source:sub(2)
    return source:match("^(.*)/[^/]+$") or "."
end

local testsDir = currentDir()
local bootstrap = dofile(testsDir .. "/bootstrap.lua")
local ctx = bootstrap.newContext()

_G.EQOLAyijeAnchorDB = {
    eqol = {
        sources = {
            player = {
                enabled = true,
                target = "cdm_essential",
                point = "RIGHT",
                relativePoint = "TOPLEFT",
                x = -12,
                y = 0,
            },
        },
    },
    castbar = {
        target = "essential",
        point = "TOP",
        relativePoint = "BOTTOM",
        x = 0,
        y = -1,
    },
}

ctx.load("Core.lua")
ctx.load("EQOLConfig.lua")
ctx.load("CastBar.lua")
ctx.load("Profiles.lua")

local db = ctx.ns.GetDB()
assert(db.version == 2, "expected db.version == 2")
assert(db.activeProfile == "Default", "expected activeProfile to be Default")
assert(type(db.profiles) == "table", "expected profiles table")
assert(type(db.profiles.Default) == "table", "expected Default profile")
assert(ctx.ns.profiles.GetActiveProfileName() == "Default", "expected active profile name to be Default")
assert(type(ctx.ns.profiles.GetActiveProfile().eqol.sources) == "table", "expected active profile eqol sources table")
