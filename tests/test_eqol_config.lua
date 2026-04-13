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

local eqol = ctx.ns.eqol

local function explicitSource(target, point, relativePoint, x, y, enabled)
    return {
        enabled = enabled == true,
        target = target,
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

local partySources = {
    player = explicitSource("cdm_essential", "RIGHT", "TOPLEFT", -12, 0),
    target = explicitSource("cdm_essential", "LEFT", "TOPRIGHT", 12, 0),
    targettarget = explicitSource("cdm_essential", "CENTER", "CENTER", 0, 0),
    focus = explicitSource("eqol_target", "TOPLEFT", "TOPRIGHT", 8, 0),
    pet = explicitSource("cdm_utility", "CENTER", "CENTER", 0, 0),
    boss = explicitSource("cdm_buffbar", "CENTER", "CENTER", 0, 0),
    party = explicitSource("cdm_racials", "TOPLEFT", "BOTTOMLEFT", 0, -4),
}

local cleaned, err = eqol.ValidateSources(partySources)
assert(cleaned, err)
assert(cleaned.party.target == "cdm_racials", "party target should remain cdm_racials")

local playerSources = {
    player = explicitSource("cdm_racials", "RIGHT", "TOPLEFT", -12, 0),
    target = explicitSource("cdm_essential", "LEFT", "TOPRIGHT", 12, 0),
    targettarget = explicitSource("cdm_essential", "CENTER", "CENTER", 0, 0),
    focus = explicitSource("eqol_target", "TOPLEFT", "TOPRIGHT", 8, 0),
    pet = explicitSource("cdm_utility", "CENTER", "CENTER", 0, 0),
    boss = explicitSource("cdm_buffbar", "CENTER", "CENTER", 0, 0),
    party = explicitSource("cdm_racials", "TOPLEFT", "BOTTOMLEFT", 0, -4),
}
local invalid, invalidErr = eqol.ValidateSources(playerSources)
assert(not invalid, "player target should be rejected")
assert(tostring(invalidErr):find("Invalid target", 1, true), "expected Invalid target error")
