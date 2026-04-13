local ADDON_NAME, ns = ...
local eqol = ns.eqol

if type(eqol) ~= "table" then
    eqol = {}
    ns.eqol = eqol
end

local function InstallUFHooks()
    local uf = eqol.GetUF()
    if not uf then
        return
    end

    if not eqol._refreshHookInstalled and type(uf.Refresh) == "function" then
        hooksecurefunc(uf, "Refresh", function()
            eqol.ApplyAllAnchors()
        end)
        eqol._refreshHookInstalled = true
    end

    if not eqol._refreshUnitHookInstalled and type(uf.RefreshUnit) == "function" then
        hooksecurefunc(uf, "RefreshUnit", function()
            eqol.ApplyAllAnchors()
        end)
        eqol._refreshUnitHookInstalled = true
    end

    local gf = uf.GroupFrames
    if gf then
        if not eqol._gfApplyHookInstalled and type(gf.ApplyHeaderAttributes) == "function" then
            hooksecurefunc(gf, "ApplyHeaderAttributes", function()
                eqol.ApplyAllAnchors()
            end)
            eqol._gfApplyHookInstalled = true
        end

        if not eqol._gfFullRefreshHookInstalled and type(gf.FullRefresh) == "function" then
            hooksecurefunc(gf, "FullRefresh", function()
                eqol.ApplyAllAnchors()
            end)
            eqol._gfFullRefreshHookInstalled = true
        end

        if not eqol._gfRefreshHookInstalled and type(gf.Refresh) == "function" then
            hooksecurefunc(gf, "Refresh", function()
                eqol.ApplyAllAnchors()
            end)
            eqol._gfRefreshHookInstalled = true
        end
    end
end

local AYIJE_RACIALS_POSITION_CALLBACK_KEY = "EQAYA_RacialsMirror"

local function RequestPartyRacialsMirrorRefresh()
    local cfg = eqol.GetSourceConfig("party")
    if not (cfg and cfg.enabled and cfg.target == "cdm_racials") then
        return
    end

    eqol.MarkDirty("party")
    eqol.RequestDeferredApply()
end

local function InstallAyijeHook()
    local cdm = _G.Ayije_CDM
    if not cdm then
        return
    end

    if not eqol._ayijeCastBarHookInstalled and type(cdm.UpdatePlayerCastBar) == "function" then
        hooksecurefunc(cdm, "UpdatePlayerCastBar", function()
            eqol.ApplyAllAnchors()
        end)
        eqol._ayijeCastBarHookInstalled = true
    end

    if not eqol._ayijeRacialsHookInstalled and type(cdm.UpdateRacials) == "function" then
        hooksecurefunc(cdm, "UpdateRacials", function()
            RequestPartyRacialsMirrorRefresh()
        end)
        eqol._ayijeRacialsHookInstalled = true
    end

    if not eqol._ayijeTrackerPositionHookInstalled and type(cdm.RegisterTrackerPositionCallback) == "function" then
        cdm.RegisterTrackerPositionCallback(AYIJE_RACIALS_POSITION_CALLBACK_KEY, RequestPartyRacialsMirrorRefresh)
        eqol._ayijeTrackerPositionHookInstalled = true
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("PLAYER_TARGET_CHANGED")
f:RegisterEvent("PLAYER_FOCUS_CHANGED")
f:RegisterEvent("UNIT_PET")
f:RegisterEvent("UNIT_TARGET")
f:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
f:RegisterEvent("UNIT_TARGETABLE_CHANGED")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            ns.GetDB()
            InstallUFHooks()
            InstallAyijeHook()
        elseif arg1 == "EnhanceQoL" then
            InstallUFHooks()
        elseif arg1 == "Ayije_CDM" then
            InstallAyijeHook()
            eqol.ApplyAllAnchors()
        end
    elseif event == "PLAYER_LOGIN" then
        InstallUFHooks()
        InstallAyijeHook()
        eqol.NotifyChanged()
    elseif event == "PLAYER_REGEN_ENABLED" then
        eqol.ApplyDirtyAnchors()
    elseif event == "GROUP_ROSTER_UPDATE" then
        eqol.RequestDeferredApply()
    elseif event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_FOCUS_CHANGED" or event == "INSTANCE_ENCOUNTER_ENGAGE_UNIT" or event == "ENCOUNTER_START" or event == "ENCOUNTER_END" then
        eqol.RequestDeferredApply()
    elseif event == "UNIT_PET" and arg1 == "player" then
        eqol.RequestDeferredApply()
    elseif event == "UNIT_TARGET" and arg1 == "target" then
        eqol.RequestDeferredApply()
    elseif event == "UNIT_TARGETABLE_CHANGED" and type(arg1) == "string" and arg1:match("^boss%d+$") then
        eqol.RequestDeferredApply()
    end
end)

return eqol
