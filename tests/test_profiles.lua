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
        x = 999,
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
assert(db.eqol == nil, "expected legacy top-level eqol key to be removed")
assert(db.castbar == nil, "expected legacy top-level castbar key to be removed")
assert(ctx.ns.profiles.GetActiveProfileName() == "Default", "expected active profile name to be Default")

local profile = ctx.ns.profiles.GetActiveProfile()
assert(type(profile.eqol.sources) == "table", "expected active profile eqol sources table")
assert(profile.eqol.sources.player.enabled == true, "expected migrated eqol player enabled to survive")
assert(profile.eqol.sources.player.target == "cdm_essential", "expected migrated eqol player target to survive")
assert(profile.eqol.sources.player.point == "RIGHT", "expected migrated eqol player point to survive")
assert(profile.eqol.sources.player.relativePoint == "TOPLEFT", "expected migrated eqol player relativePoint to survive")
assert(profile.eqol.sources.player.x == -12, "expected migrated eqol player x to survive")
assert(profile.eqol.sources.player.y == 0, "expected migrated eqol player y to survive")

assert(type(profile.castbar) == "table", "expected active profile castbar table")
assert(profile.castbar.target == "essential", "expected migrated castbar target to survive")
assert(profile.castbar.point == "TOP", "expected migrated castbar point to survive")
assert(profile.castbar.relativePoint == "BOTTOM", "expected migrated castbar relativePoint to survive")
assert(profile.castbar.x == 300, "expected invalid castbar x to be clamped")
assert(profile.castbar.y == -1, "expected migrated castbar y to survive")
