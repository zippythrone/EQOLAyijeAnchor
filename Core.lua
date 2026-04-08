local ADDON_NAME, ns = ...

local SHORT_TAG = "EQAYA"
local EXPORT_PREFIX = "EQAYA1:"

ns.eqol = ns.eqol or {}
ns.castbar = ns.castbar or {}

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

local function ReplaceTableContents(dst, src)
    WipeTable(dst)
    for k, v in pairs(src) do
        dst[k] = DeepCopy(v)
    end
end

local function DeepEqual(lhs, rhs)
    if lhs == rhs then
        return true
    end
    if type(lhs) ~= type(rhs) then
        return false
    end
    if type(lhs) ~= "table" then
        return false
    end

    for k, v in pairs(lhs) do
        if not DeepEqual(v, rhs[k]) then
            return false
        end
    end
    for k in pairs(rhs) do
        if lhs[k] == nil then
            return false
        end
    end

    return true
end

local function BuildDefaultDB()
    local eqolSources = {}
    local castbarConfig = {}

    if ns.eqol.BuildDefaultSources then
        eqolSources = ns.eqol.BuildDefaultSources()
    end
    if ns.castbar.BuildDefaultConfig then
        castbarConfig = ns.castbar.BuildDefaultConfig()
    end

    return {
        eqol = {
            sources = eqolSources,
        },
        castbar = castbarConfig,
    }
end

function ns.GetDB()
    EQOLAyijeAnchorDB = type(EQOLAyijeAnchorDB) == "table" and EQOLAyijeAnchorDB or BuildDefaultDB()
    local db = EQOLAyijeAnchorDB

    db.eqol = type(db.eqol) == "table" and db.eqol or {}
    db.eqol.sources = type(db.eqol.sources) == "table" and db.eqol.sources or {}
    db.castbar = type(db.castbar) == "table" and db.castbar or {}

    if ns.eqol.NormalizeDB then
        ns.eqol.NormalizeDB(db.eqol)
    end
    if ns.castbar.NormalizeDB then
        ns.castbar.NormalizeDB(db.castbar)
    end

    return db
end

local function HasEncodingUtil()
    return C_EncodingUtil
        and C_EncodingUtil.SerializeCBOR
        and C_EncodingUtil.DeserializeCBOR
        and C_EncodingUtil.CompressString
        and C_EncodingUtil.DecompressString
        and C_EncodingUtil.EncodeBase64
        and C_EncodingUtil.DecodeBase64
end

local function EnsureValidationContracts()
    if type(ns.eqol.ValidateSources) ~= "function" then
        return nil, "EQOL subsystem not ready: missing ValidateSources"
    end
    if type(ns.castbar.ValidateConfig) ~= "function" then
        return nil, "CastBar subsystem not ready: missing ValidateConfig"
    end
    return true
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

local function ValidatePayload(payload)
    local ready, readyErr = EnsureValidationContracts()
    if not ready then
        return nil, readyErr
    end

    if type(payload) ~= "table" then
        return nil, "Payload is not a table"
    end

    local eqolPayload = payload.eqol
    local eqolSources = eqolPayload and eqolPayload.sources
    local castbarPayload = payload.castbar

    local cleanedEqol, eqolErr = ns.eqol.ValidateSources(eqolSources)
    if not cleanedEqol then
        return nil, eqolErr or "Invalid EQOL payload"
    end

    local cleanedCastbar, castbarErr = ns.castbar.ValidateConfig(castbarPayload)
    if not cleanedCastbar then
        return nil, castbarErr or "Invalid castbar payload"
    end

    return {
        eqol = {
            sources = cleanedEqol,
        },
        castbar = cleanedCastbar,
    }
end

function ns.SerializeSettings()
    if not HasEncodingUtil() then
        return nil, "C_EncodingUtil not available in this client"
    end

    local payload, err = ValidatePayload(ns.GetDB())
    if not payload then
        return nil, err
    end

    local okS, cbor = pcall(C_EncodingUtil.SerializeCBOR, payload)
    if not okS or not cbor then return nil, "CBOR serialize failed" end

    local okC, compressed = pcall(C_EncodingUtil.CompressString, cbor)
    if not okC or not compressed then return nil, "Compress failed" end

    local okB, base64 = pcall(C_EncodingUtil.EncodeBase64, compressed)
    if not okB or not base64 then return nil, "Base64 encode failed" end

    return EXPORT_PREFIX .. base64
end

function ns.DeserializeSettings(str)
    if type(str) ~= "string" then
        return nil, "Empty input"
    end

    str = str:gsub("^%s+", ""):gsub("%s+$", "")
    if str == "" then
        return nil, "Empty input"
    end

    if str:sub(1, #EXPORT_PREFIX) ~= EXPORT_PREFIX then
        return nil, 'Unknown format - expected "EQAYA1:BASE64"'
    end

    if not HasEncodingUtil() then
        return nil, "C_EncodingUtil not available in this client"
    end

    local payload64 = str:sub(#EXPORT_PREFIX + 1)
    if payload64 == "" then
        return nil, "Empty payload"
    end

    local okD, compressed = pcall(C_EncodingUtil.DecodeBase64, payload64)
    if not okD or not compressed then return nil, "Base64 decode failed" end

    local okU, cbor = pcall(C_EncodingUtil.DecompressString, compressed)
    if not okU or not cbor then return nil, "Decompress failed" end

    local okC, payload = pcall(C_EncodingUtil.DeserializeCBOR, cbor)
    if not okC or type(payload) ~= "table" then
        return nil, "CBOR deserialize failed"
    end

    return ValidatePayload(payload)
end

function ns.ApplyParsedSettings(parsed)
    local cleaned, err = ValidatePayload(parsed)
    if not cleaned then
        return nil, err
    end

    local db = ns.GetDB()
    db.eqol = type(db.eqol) == "table" and db.eqol or {}
    db.eqol.sources = type(db.eqol.sources) == "table" and db.eqol.sources or {}
    db.castbar = type(db.castbar) == "table" and db.castbar or {}

    local eqolSourcesChanged = not DeepEqual(db.eqol.sources, cleaned.eqol.sources)

    ReplaceTableContents(db.eqol.sources, cleaned.eqol.sources)
    ReplaceTableContents(db.castbar, cleaned.castbar)

    if eqolSourcesChanged and ns.eqol.ClearRuntimeState then
        ns.eqol.ClearRuntimeState()
    end

    return true
end

function ns.ResetEQOL()
    local okContracts, contractsErr = EnsureResetContracts(true, false)
    if not okContracts then
        return nil, contractsErr
    end

    local db = ns.GetDB()
    return ns.ApplyParsedSettings({
        eqol = { sources = ns.eqol.BuildDefaultSources() },
        castbar = db.castbar,
    })
end

function ns.ResetCastBar()
    local okContracts, contractsErr = EnsureResetContracts(false, true)
    if not okContracts then
        return nil, contractsErr
    end

    local db = ns.GetDB()
    return ns.ApplyParsedSettings({
        eqol = { sources = db.eqol and db.eqol.sources },
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
