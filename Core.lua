local ADDON_NAME, ns = ...

local SHORT_TAG = "EQAYA"
local EXPORT_PREFIX = "EQAYA1:"

ns.eqol = ns.eqol or {}
ns.castbar = ns.castbar or {}
ns.profiles = ns.profiles or {}

ns.SHORT_TAG = SHORT_TAG
ns.EXPORT_PREFIX = EXPORT_PREFIX

ns.POINT_ORDER = {
    "TOPLEFT", "TOP", "TOPRIGHT",
    "LEFT", "CENTER", "RIGHT",
    "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT",
}

ns.VALID_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

ns.POINT_LABELS = {
    TOPLEFT = "Top Left",
    TOP = "Top",
    TOPRIGHT = "Top Right",
    LEFT = "Left",
    CENTER = "Center",
    RIGHT = "Right",
    BOTTOMLEFT = "Bottom Left",
    BOTTOM = "Bottom",
    BOTTOMRIGHT = "Bottom Right",
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function WipeTable(t)
    if not t then
        return
    end
    for k in pairs(t) do
        t[k] = nil
    end
end

ns.DeepCopy = DeepCopy
ns.WipeTable = WipeTable

function ns.GetDB()
    if ns.profiles and type(ns.profiles.GetDB) == "function" then
        return ns.profiles.GetDB()
    end

    EQOLAyijeAnchorDB = type(EQOLAyijeAnchorDB) == "table" and EQOLAyijeAnchorDB or {}
    return EQOLAyijeAnchorDB
end

local function EnsureResetContracts(resetEqol, resetCastbar)
    if resetEqol and type(ns.eqol.BuildDefaultSources) ~= "function" then
        return nil, "EQOL subsystem not ready: missing BuildDefaultSources"
    end
    if resetCastbar and type(ns.castbar.BuildDefaultConfig) ~= "function" then
        return nil, "CastBar subsystem not ready: missing BuildDefaultConfig"
    end
    return true
end

local function GetSerializationApi()
    local serialization = ns.serialization
    if type(serialization) ~= "table" then
        return nil, "Serialization subsystem not loaded"
    end
    return serialization
end

function ns.SerializeProfile(profileName)
    local serialization, err = GetSerializationApi()
    if not serialization then
        return nil, err
    end
    return serialization.ExportProfile(profileName)
end

function ns.ImportIntoProfile(profileName, rawString)
    local serialization, err = GetSerializationApi()
    if not serialization then
        return nil, err
    end
    return serialization.ImportIntoProfile(rawString, profileName)
end

function ns.SerializeSettings()
    if not (ns.profiles and type(ns.profiles.GetActiveProfileName) == "function") then
        return nil, "Profiles subsystem not ready"
    end
    return ns.SerializeProfile(ns.profiles.GetActiveProfileName())
end

function ns.DeserializeSettings(str)
    local serialization, err = GetSerializationApi()
    if not serialization then
        return nil, err
    end
    return serialization.DeserializeProfileString(str)
end

function ns.ApplyParsedSettings(parsed)
    if not (ns.profiles and type(ns.profiles.ReplaceProfile) == "function" and type(ns.profiles.GetActiveProfileName) == "function") then
        return nil, "Profiles subsystem not ready"
    end

    local payload = parsed
    if type(parsed) == "table" and type(parsed.data) == "table" then
        payload = parsed.data
    end

    return ns.profiles.ReplaceProfile(ns.profiles.GetActiveProfileName(), payload)
end

function ns.ResetEQOL()
    local okContracts, contractsErr = EnsureResetContracts(true, false)
    if not okContracts then
        return nil, contractsErr
    end

    local profile = ns.profiles and type(ns.profiles.GetActiveProfile) == "function" and ns.profiles.GetActiveProfile() or nil
    if type(profile) ~= "table" then
        return nil, "Active profile is not available"
    end

    return ns.ApplyParsedSettings({
        eqol = { sources = ns.eqol.BuildDefaultSources() },
        castbar = profile.castbar,
    })
end

function ns.ResetCastBar()
    local okContracts, contractsErr = EnsureResetContracts(false, true)
    if not okContracts then
        return nil, contractsErr
    end

    local profile = ns.profiles and type(ns.profiles.GetActiveProfile) == "function" and ns.profiles.GetActiveProfile() or nil
    if type(profile) ~= "table" then
        return nil, "Active profile is not available"
    end

    return ns.ApplyParsedSettings({
        eqol = { sources = profile.eqol and profile.eqol.sources },
        castbar = ns.castbar.BuildDefaultConfig(),
    })
end

function ns.ResetAll()
    local okContracts, contractsErr = EnsureResetContracts(true, true)
    if not okContracts then
        return nil, contractsErr
    end

    return ns.ApplyParsedSettings({
        eqol = { sources = ns.eqol.BuildDefaultSources() },
        castbar = ns.castbar.BuildDefaultConfig(),
    })
end

function ns.NotifyChanged()
    if ns.eqol.NotifyChanged then
        ns.eqol.NotifyChanged()
    end
    if ns.castbar.NotifyChanged then
        ns.castbar.NotifyChanged()
    end
end

SLASH_EQOLAYIJEANCHOR1 = "/eaya"
SlashCmdList["EQOLAYIJEANCHOR"] = function(message)
    local trimmed = type(message) == "string" and message:match("^%s*(.-)%s*$") or ""
    if trimmed ~= "" then
        print(string.format("|cFFff5555[%s]|r Unsupported arguments. Use /eaya to open settings.", SHORT_TAG))
        return
    end

    if ns.OpenSettings then
        ns.OpenSettings()
    else
        print(string.format("|cFFff5555[%s]|r Options panel not registered yet.", SHORT_TAG))
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        ns.GetDB()
    end
end)
