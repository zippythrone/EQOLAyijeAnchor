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

local profiles = ctx.ns.profiles

assert(profiles.CreateProfile("Arena") == true, "expected CreateProfile to succeed")
assert(profiles.GetProfile("Arena") ~= nil, "expected Arena profile to exist")

assert(profiles.SwitchProfile("Arena") == true, "expected SwitchProfile to succeed")
assert(ctx.ns.profiles.GetActiveProfileName() == "Arena", "expected active profile to change to Arena")

assert(profiles.RenameProfile("Arena", "Shuffle") == true, "expected RenameProfile to succeed")
assert(profiles.GetProfile("Arena") == nil, "expected old Arena profile to be removed")
assert(profiles.GetProfile("Shuffle") ~= nil, "expected Shuffle profile to exist")
assert(ctx.ns.profiles.GetActiveProfileName() == "Shuffle", "expected active profile to update to Shuffle")

assert(profiles.DuplicateProfile("Shuffle", "Raid") == true, "expected DuplicateProfile to succeed")
assert(profiles.GetProfile("Raid") ~= nil, "expected Raid profile to exist")

assert(profiles.DeleteProfile("Raid") == true, "expected DeleteProfile on Raid to succeed")
assert(profiles.GetProfile("Raid") == nil, "expected Raid profile to be removed")

assert(profiles.DeleteProfile("Shuffle") == true, "expected DeleteProfile on Shuffle to succeed")
assert(ctx.ns.profiles.GetActiveProfileName() == "Default", "expected active profile to fall back to Default")

local ok, err = profiles.DeleteProfile("Default")
assert(ok == nil, "expected deleting the last remaining profile to fail")
assert(type(err) == "string" and err:lower():find("last", 1, true), "expected last-profile error message")

local function contains(values, needle)
    for _, value in ipairs(values) do
        if value == needle then
            return true
        end
    end
    return false
end

local sideEffects = {
    clear = 0,
    notify = 0,
    refresh = 0,
}

ctx.ns.eqol.ClearRuntimeState = function()
    sideEffects.clear = sideEffects.clear + 1
end
ctx.ns.NotifyChanged = function()
    sideEffects.notify = sideEffects.notify + 1
end
ctx.ns.RefreshUI = function()
    sideEffects.refresh = sideEffects.refresh + 1
end

assert(profiles.CreateProfile("Active") == true, "expected Active profile to be created")
assert(profiles.CreateProfile("Spare") == true, "expected Spare profile to be created")

db.profiles.Broken = true

local names = profiles.ListProfileNames()
assert(not contains(names, "Broken"), "expected malformed profile entry to be ignored by ListProfileNames")

assert(profiles.SwitchProfile("Active") == true, "expected SwitchProfile to activate Active")
sideEffects.clear = 0
sideEffects.notify = 0
sideEffects.refresh = 0

assert(profiles.DeleteProfile("Spare") == true, "expected inactive profile delete to succeed")
assert(sideEffects.clear == 0, "expected inactive profile delete to skip ClearRuntimeState")
assert(sideEffects.notify == 0, "expected inactive profile delete to skip NotifyChanged")
assert(sideEffects.refresh == 1, "expected inactive profile delete to refresh UI")
assert(ctx.ns.profiles.GetActiveProfileName() == "Active", "expected inactive profile delete to keep the active profile")

sideEffects.clear = 0
sideEffects.notify = 0
sideEffects.refresh = 0

assert(profiles.DeleteProfile("Active") == true, "expected active profile delete to succeed")
assert(sideEffects.clear == 1, "expected active profile delete to clear runtime state")
assert(sideEffects.notify == 1, "expected active profile delete to notify changes")
assert(sideEffects.refresh == 1, "expected active profile delete to refresh UI")
assert(ctx.ns.profiles.GetActiveProfileName() == "Default", "expected active profile delete to fall back to Default")

local finalOk, finalErr = profiles.DeleteProfile("Default")
assert(finalOk == nil, "expected malformed entry not to bypass last-profile protection")
assert(type(finalErr) == "string" and finalErr:lower():find("last", 1, true), "expected last-profile protection to remain in force")

local function loadProfilesWithDB(dbState)
    local freshCtx = bootstrap.newContext()
    _G.EQOLAyijeAnchorDB = dbState
    freshCtx.load("Core.lua")
    freshCtx.load("EQOLConfig.lua")
    freshCtx.load("CastBar.lua")
    freshCtx.load("Profiles.lua")
    return freshCtx
end

local recoveryCtx = loadProfilesWithDB({
    profiles = {
        Alpha = {
            eqol = { sources = {} },
            castbar = {},
        },
        Beta = {
            eqol = { sources = {} },
            castbar = {},
        },
    },
    activeProfile = "Broken",
})

local recoveredDB = recoveryCtx.ns.GetDB()
assert(recoveredDB.activeProfile == "Alpha", "expected invalid activeProfile to fall back to a valid existing profile")
assert(recoveredDB.profiles.Broken == nil, "expected invalid activeProfile to not synthesize a junk profile")

local numericKeyCtx = loadProfilesWithDB({
    profiles = {
        Alpha = {
            eqol = { sources = {} },
            castbar = {},
        },
        [1] = {
            eqol = { sources = {} },
            castbar = {},
        },
    },
    activeProfile = 1,
})

local numericNames = numericKeyCtx.ns.profiles.ListProfileNames()
assert(#numericNames == 1 and numericNames[1] == "Alpha", "expected numeric profile key to be ignored by profile listing")
assert(numericKeyCtx.ns.profiles.GetActiveProfileName() == "Alpha", "expected numeric profile key to be ignored by active profile fallback")
