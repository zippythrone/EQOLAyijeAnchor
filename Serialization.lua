local ADDON_NAME, ns = ...

local serialization = ns.serialization or {}
ns.serialization = serialization

local EXPORT_PREFIX = ns.EXPORT_PREFIX or "EQAYA1:"
local EXPORT_ADDON = "EQOLAyijeAnchor"
local EXPORT_VERSION = 2

local function HasEncodingUtil()
    return C_EncodingUtil
        and C_EncodingUtil.SerializeCBOR
        and C_EncodingUtil.DeserializeCBOR
        and C_EncodingUtil.CompressString
        and C_EncodingUtil.DecompressString
        and C_EncodingUtil.EncodeBase64
        and C_EncodingUtil.DecodeBase64
end

local function ValidatePayload(payload)
    if type(ns.eqol.ValidateSources) ~= "function" then
        return nil, "EQOL subsystem not ready: missing ValidateSources"
    end
    if type(ns.castbar.ValidateConfig) ~= "function" then
        return nil, "CastBar subsystem not ready: missing ValidateConfig"
    end
    if type(payload) ~= "table" or type(payload.meta) ~= "table" or type(payload.data) ~= "table" then
        return nil, "Payload is not a valid export table"
    end
    if payload.meta.addon ~= EXPORT_ADDON then
        return nil, "Export belongs to another addon"
    end
    if payload.meta.version ~= EXPORT_VERSION then
        return nil, "Unsupported export version: " .. tostring(payload.meta.version)
    end

    local cleanedSources, eqolErr = ns.eqol.ValidateSources(payload.data.eqol and payload.data.eqol.sources)
    if not cleanedSources then
        return nil, eqolErr or "Invalid EQOL payload"
    end

    local cleanedCastbar, castbarErr = ns.castbar.ValidateConfig(payload.data.castbar)
    if not cleanedCastbar then
        return nil, castbarErr or "Invalid castbar payload"
    end

    return {
        meta = {
            addon = EXPORT_ADDON,
            version = EXPORT_VERSION,
            profile = payload.meta.profile,
        },
        data = {
            eqol = {
                sources = cleanedSources,
            },
            castbar = cleanedCastbar,
        },
    }
end

function serialization.ExportProfile(profileName)
    if not HasEncodingUtil() then
        return nil, "C_EncodingUtil not available in this client"
    end

    local profile, profileErr = ns.profiles.GetProfile(profileName)
    if type(profile) ~= "table" then
        return nil, profileErr or "Unknown profile"
    end

    local payload, payloadErr = ValidatePayload({
        meta = {
            addon = EXPORT_ADDON,
            version = EXPORT_VERSION,
            profile = profileName,
        },
        data = ns.DeepCopy(profile),
    })
    if not payload then
        return nil, payloadErr
    end

    local okSerialize, cbor = pcall(C_EncodingUtil.SerializeCBOR, payload)
    if not okSerialize or not cbor then
        return nil, "CBOR serialize failed"
    end

    local okCompress, compressed = pcall(C_EncodingUtil.CompressString, cbor)
    if not okCompress or not compressed then
        return nil, "Compress failed"
    end

    local okEncode, encoded = pcall(C_EncodingUtil.EncodeBase64, compressed)
    if not okEncode or not encoded then
        return nil, "Base64 encode failed"
    end

    return EXPORT_PREFIX .. encoded
end

function serialization.DeserializeProfileString(str)
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

    local encoded = str:sub(#EXPORT_PREFIX + 1)
    if encoded == "" then
        return nil, "Empty payload"
    end

    local okDecode, compressed = pcall(C_EncodingUtil.DecodeBase64, encoded)
    if not okDecode or not compressed then
        return nil, "Base64 decode failed"
    end

    local okDecompress, cbor = pcall(C_EncodingUtil.DecompressString, compressed)
    if not okDecompress or not cbor then
        return nil, "Decompress failed"
    end

    local okDeserialize, payload = pcall(C_EncodingUtil.DeserializeCBOR, cbor)
    if not okDeserialize or type(payload) ~= "table" then
        return nil, "CBOR deserialize failed"
    end

    return ValidatePayload(payload)
end

function serialization.ImportIntoProfile(str, profileName)
    local cleaned, err = serialization.DeserializeProfileString(str)
    if not cleaned then
        return nil, err
    end

    return ns.profiles.ReplaceProfile(profileName, cleaned.data)
end

return serialization
