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

    local cleanedCastbar = ns.castbar.BuildDefaultConfig()
    local validatedCastbar = ns.castbar.ValidateConfig(profile.castbar)
    if validatedCastbar then
        cleanedCastbar = validatedCastbar
    end
    profile.castbar = cleanedCastbar

    return profile
end

function profiles.BuildDefaultProfile()
    return BuildDefaultProfile()
end

function profiles.NormalizeProfile(profile)
    return NormalizeProfile(profile)
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
