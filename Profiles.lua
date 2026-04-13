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

local function ValidateProfileName(name)
    name = type(name) == "string" and name:gsub("^%s+", ""):gsub("%s+$", "") or ""
    if name == "" then
        return nil, "Profile name cannot be empty"
    end
    return name
end

local function IsValidProfile(profile)
    return type(profile) == "table"
end

local function GetValidProfileNames(db)
    local names = {}
    for name, profile in pairs(db.profiles) do
        if IsValidProfile(profile) then
            names[#names + 1] = name
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
        db.profiles = db.profiles or {}
        if type(db.activeProfile) ~= "string" or db.activeProfile == "" then
            db.activeProfile = "Default"
        end
        if type(db.profiles[db.activeProfile]) ~= "table" then
            db.profiles[db.activeProfile] = BuildDefaultProfile()
        end
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
