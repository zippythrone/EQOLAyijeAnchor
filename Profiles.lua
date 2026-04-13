local ADDON_NAME, ns = ...
local profiles = ns.profiles

if type(profiles) ~= "table" then
    profiles = {}
    ns.profiles = profiles
end

local DB_VERSION = 2

profiles.DB_VERSION = DB_VERSION

local function BuildDefaultProfile()
    return {
        eqol = {
            sources = ns.eqol.BuildDefaultSources(),
        },
        castbar = ns.castbar.BuildDefaultConfig(),
    }
end

local function NormalizeProfile(profile)
    if type(profile) ~= "table" then
        return BuildDefaultProfile()
    end

    profile.eqol = type(profile.eqol) == "table" and profile.eqol or {}
    profile.castbar = type(profile.castbar) == "table" and profile.castbar or {}

    local cleanedSources = ns.eqol.BuildDefaultSources()
    if type(profile.eqol.sources) == "table" then
        local validatedSources = ns.eqol.ValidateSources(profile.eqol.sources)
        if validatedSources then
            cleanedSources = validatedSources
        end
    end
    profile.eqol.sources = cleanedSources

    profile.castbar = type(profile.castbar) == "table" and profile.castbar or {}
    ns.castbar.NormalizeDB(profile.castbar)

    return profile
end

local function CanonicalizeProfileName(name)
    if type(name) ~= "string" then
        return nil
    end

    name = name:gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        return nil
    end

    return name
end

local function ValidateProfileName(name)
    name = CanonicalizeProfileName(name)
    if not name then
        return nil, "Profile name cannot be empty"
    end
    return name
end

local function IsValidProfile(profile)
    return type(profile) == "table"
end

local function ShouldKeepProfileCandidate(candidate, existing)
    if candidate.exact ~= existing.exact then
        return candidate.exact
    end
    if candidate.rawName ~= existing.rawName then
        return candidate.rawName < existing.rawName
    end
    return false
end

local function CanonicalizeProfiles(rawProfiles)
    local canonicalCandidates = {}
    local canonicalProfiles = {}

    for rawName, profile in pairs(rawProfiles) do
        local canonicalName = CanonicalizeProfileName(rawName)
        if canonicalName and IsValidProfile(profile) then
            local candidate = {
                canonicalName = canonicalName,
                exact = rawName == canonicalName,
                profile = profile,
                rawName = rawName,
            }
            local existing = canonicalCandidates[canonicalName]
            if not existing or ShouldKeepProfileCandidate(candidate, existing) then
                canonicalCandidates[canonicalName] = candidate
            end
        end
    end

    for name, candidate in pairs(canonicalCandidates) do
        canonicalProfiles[name] = NormalizeProfile(candidate.profile)
    end

    return canonicalProfiles
end

local function GetValidProfileNames(db)
    local names = {}
    local seen = {}
    for name, profile in pairs(db.profiles) do
        local canonicalName = CanonicalizeProfileName(name)
        if canonicalName and IsValidProfile(profile) and not seen[canonicalName] then
            seen[canonicalName] = true
            names[#names + 1] = canonicalName
        end
    end
    table.sort(names, function(lhs, rhs)
        local lhsLower = lhs:lower()
        local rhsLower = rhs:lower()
        if lhsLower == rhsLower then
            return lhs < rhs
        end
        return lhsLower < rhsLower
    end)
    return names
end

function profiles.BuildDefaultProfile()
    return BuildDefaultProfile()
end

function profiles.NormalizeProfile(profile)
    return NormalizeProfile(profile)
end

function profiles.ValidateProfileName(name)
    return ValidateProfileName(name)
end

function profiles.GetProfile(name)
    local profileName, err = ValidateProfileName(name)
    if not profileName then
        return nil, err
    end

    local db = profiles.GetDB()
    return db.profiles[profileName]
end

function profiles.ListProfileNames()
    local db = profiles.GetDB()
    return GetValidProfileNames(db)
end

function profiles.SwitchProfile(name)
    local profileName, err = ValidateProfileName(name)
    if not profileName then
        return nil, err
    end

    local db = profiles.GetDB()
    if type(db.profiles[profileName]) ~= "table" then
        return nil, "Unknown profile: " .. profileName
    end

    db.activeProfile = profileName

    if type(ns.eqol.ClearRuntimeState) == "function" then
        ns.eqol.ClearRuntimeState()
    end
    if type(ns.NotifyChanged) == "function" then
        ns.NotifyChanged()
    end
    if type(ns.RefreshUI) == "function" then
        ns.RefreshUI()
    end

    return true
end

function profiles.CreateProfile(name, sourceName)
    local profileName, err = ValidateProfileName(name)
    if not profileName then
        return nil, err
    end

    local db = profiles.GetDB()
    if type(db.profiles[profileName]) == "table" then
        return nil, "Profile already exists: " .. profileName
    end

    local sourceProfile = profiles.GetProfile(sourceName)
    if type(sourceProfile) ~= "table" then
        sourceProfile = profiles.GetActiveProfile()
    end

    db.profiles[profileName] = ns.DeepCopy(sourceProfile)
    return true
end

function profiles.RenameProfile(oldName, newName)
    local oldProfileName, oldErr = ValidateProfileName(oldName)
    if not oldProfileName then
        return nil, oldErr
    end

    local newProfileName, newErr = ValidateProfileName(newName)
    if not newProfileName then
        return nil, newErr
    end

    local db = profiles.GetDB()
    local existing = db.profiles[oldProfileName]
    if type(existing) ~= "table" then
        return nil, "Unknown profile: " .. oldProfileName
    end
    if type(db.profiles[newProfileName]) == "table" then
        return nil, "Profile already exists: " .. newProfileName
    end

    db.profiles[newProfileName] = existing
    db.profiles[oldProfileName] = nil
    if db.activeProfile == oldProfileName then
        db.activeProfile = newProfileName
    end

    if type(ns.RefreshUI) == "function" then
        ns.RefreshUI()
    end

    return true
end

function profiles.DuplicateProfile(sourceName, newName)
    local sourceProfileName, sourceErr = ValidateProfileName(sourceName)
    if not sourceProfileName then
        return nil, sourceErr
    end

    local newProfileName, newErr = ValidateProfileName(newName)
    if not newProfileName then
        return nil, newErr
    end

    local sourceProfile = profiles.GetProfile(sourceProfileName)
    if type(sourceProfile) ~= "table" then
        return nil, "Unknown profile: " .. sourceProfileName
    end

    local db = profiles.GetDB()
    if type(db.profiles[newProfileName]) == "table" then
        return nil, "Profile already exists: " .. newProfileName
    end

    db.profiles[newProfileName] = ns.DeepCopy(sourceProfile)
    return true
end

function profiles.DeleteProfile(name)
    local profileName, err = ValidateProfileName(name)
    if not profileName then
        return nil, err
    end

    local db = profiles.GetDB()
    if not IsValidProfile(db.profiles[profileName]) then
        return nil, "Unknown profile: " .. profileName
    end

    local names = GetValidProfileNames(db)
    if #names <= 1 then
        return nil, "Cannot delete the last remaining profile"
    end

    local activeProfileChanged = db.activeProfile == profileName
    if db.activeProfile == profileName then
        for _, candidate in ipairs(names) do
            if candidate ~= profileName then
                db.activeProfile = candidate
                break
            end
        end
    end

    db.profiles[profileName] = nil

    if activeProfileChanged and type(ns.eqol.ClearRuntimeState) == "function" then
        ns.eqol.ClearRuntimeState()
    end
    if activeProfileChanged and type(ns.NotifyChanged) == "function" then
        ns.NotifyChanged()
    end
    if type(ns.RefreshUI) == "function" then
        ns.RefreshUI()
    end

    return true
end

local function ValidateReplacementPayload(payload)
    if type(payload) ~= "table" then
        return nil, "Profile payload must be a table"
    end

    if type(ns.eqol.ValidateSources) ~= "function" then
        return nil, "EQOL subsystem not ready: missing ValidateSources"
    end
    if type(ns.castbar.ValidateConfig) ~= "function" then
        return nil, "CastBar subsystem not ready: missing ValidateConfig"
    end

    local cleanedSources, sourcesErr = ns.eqol.ValidateSources(payload.eqol and payload.eqol.sources)
    if not cleanedSources then
        return nil, sourcesErr or "Invalid EQOL payload"
    end

    local cleanedCastbar, castbarErr = ns.castbar.ValidateConfig(payload.castbar)
    if not cleanedCastbar then
        return nil, castbarErr or "Invalid castbar payload"
    end

    return NormalizeProfile({
        eqol = {
            sources = cleanedSources,
        },
        castbar = cleanedCastbar,
    })
end

function profiles.ReplaceProfile(name, payload)
    local profileName, err = ValidateProfileName(name)
    if not profileName then
        return nil, err
    end

    local db = profiles.GetDB()
    if type(db.profiles[profileName]) ~= "table" then
        return nil, "Unknown profile: " .. profileName
    end

    local replacement, payloadErr = ValidateReplacementPayload(payload)
    if not replacement then
        return nil, payloadErr
    end

    db.profiles[profileName] = replacement

    if db.activeProfile == profileName and type(ns.eqol.ClearRuntimeState) == "function" then
        ns.eqol.ClearRuntimeState()
    end
    if db.activeProfile == profileName and type(ns.NotifyChanged) == "function" then
        ns.NotifyChanged()
    end
    if type(ns.RefreshUI) == "function" then
        ns.RefreshUI()
    end

    return true
end

function profiles.GetDB()
    local db = type(_G.EQOLAyijeAnchorDB) == "table" and _G.EQOLAyijeAnchorDB or {}

    if type(db.profiles) ~= "table" then
        local legacyProfile = {
            eqol = {
                sources = type(db.eqol) == "table" and db.eqol.sources or nil,
            },
            castbar = type(db.castbar) == "table" and db.castbar or nil,
        }
        db.profiles = {
            Default = NormalizeProfile(legacyProfile),
        }
        db.activeProfile = "Default"
    else
        db.profiles = CanonicalizeProfiles(db.profiles or {})
        local activeProfileName = CanonicalizeProfileName(db.activeProfile)
        if not activeProfileName or not IsValidProfile(db.profiles[activeProfileName]) then
            local fallbackNames = GetValidProfileNames(db)
            activeProfileName = fallbackNames[1]
            if not activeProfileName then
                activeProfileName = "Default"
                db.profiles.Default = BuildDefaultProfile()
            end
        end
        db.activeProfile = activeProfileName
        db.profiles[db.activeProfile] = NormalizeProfile(db.profiles[db.activeProfile])
    end

    db.version = DB_VERSION
    db.eqol = nil
    db.castbar = nil

    _G.EQOLAyijeAnchorDB = db
    return db
end

function profiles.GetActiveProfileName()
    return profiles.GetDB().activeProfile
end

function profiles.GetActiveProfile()
    local db = profiles.GetDB()
    return db.profiles[db.activeProfile]
end

function ns.GetDB()
    return profiles.GetDB()
end

return profiles
