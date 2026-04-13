local bootstrap = dofile("AddOns/EQOLAyijeAnchor/tests/bootstrap.lua")
local ctx = bootstrap.newContext()

ctx.load("Core.lua")
ctx.load("EQOLConfig.lua")

local eqol = ctx.ns.eqol

local partySources = eqol.BuildDefaultSources()
local cleaned, err = eqol.ValidateSources(partySources)
assert(cleaned, err)
assert(cleaned.party.target == "cdm_racials", "party target should remain cdm_racials")

local playerSources = eqol.BuildDefaultSources()
playerSources.player.target = "cdm_racials"
local invalid, invalidErr = eqol.ValidateSources(playerSources)
assert(not invalid, "player target should be rejected")
assert(tostring(invalidErr):find("Invalid target", 1, true), "expected Invalid target error")
