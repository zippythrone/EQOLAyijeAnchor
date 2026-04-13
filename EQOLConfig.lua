local ADDON_NAME, ns = ...
local eqol = ns.eqol

if type(eqol) ~= "table" then
    eqol = {}
    ns.eqol = eqol
end

local OFFSET_MIN = -3000
local OFFSET_MAX = 3000

local function CopyValue(value)
    if type(ns.DeepCopy) == "function" then
        return ns.DeepCopy(value)
    end
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = CopyValue(v)
    end
    return copy
end

local function RoundNumber(value)
    value = tonumber(value) or 0
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

eqol.SOURCE_ORDER = {
    "player",
    "target",
    "targettarget",
    "focus",
    "pet",
    "boss",
    "party",
}

eqol.SOURCE_DEFAULTS = {
    enabled = false,
    target = "cdm_essential",
    point = "CENTER",
    relativePoint = "CENTER",
    x = 0,
    y = 0,
}

eqol.SOURCE_DEFAULT_OVERRIDES = {
    player = {
        target = "cdm_essential",
        point = "RIGHT",
        relativePoint = "TOPLEFT",
        x = -12,
        y = 0,
    },
    target = {
        target = "cdm_essential",
        point = "LEFT",
        relativePoint = "TOPRIGHT",
        x = 12,
        y = 0,
    },
    focus = {
        target = "eqol_target",
        point = "TOPLEFT",
        relativePoint = "TOPRIGHT",
        x = 8,
        y = 0,
    },
    party = {
        target = "cdm_racials",
        point = "TOPLEFT",
        relativePoint = "BOTTOMLEFT",
        x = 0,
        y = -4,
    },
}

eqol.SOURCE_LABELS = {
    player = "EQOL Player Frame",
    target = "EQOL Target Frame",
    targettarget = "EQOL Target of Target Frame",
    focus = "EQOL Focus Frame",
    pet = "EQOL Pet Frame",
    boss = "EQOL Boss Container",
    party = "EQOL Party Frame",
}

eqol.SOURCE_INFO = {
    player = {
        ensureUnit = "player",
        frameName = "EQOLUFPlayerFrame",
        label = eqol.SOURCE_LABELS.player,
    },
    target = {
        ensureUnit = "target",
        frameName = "EQOLUFTargetFrame",
        label = eqol.SOURCE_LABELS.target,
    },
    targettarget = {
        ensureUnit = "targettarget",
        frameName = "EQOLUFToTFrame",
        label = eqol.SOURCE_LABELS.targettarget,
    },
    focus = {
        ensureUnit = "focus",
        frameName = "EQOLUFFocusFrame",
        label = eqol.SOURCE_LABELS.focus,
    },
    pet = {
        ensureUnit = "pet",
        frameName = "EQOLUFPetFrame",
        label = eqol.SOURCE_LABELS.pet,
    },
    boss = {
        ensureUnit = "boss1",
        frameName = "EQOLUFBossContainer",
        label = eqol.SOURCE_LABELS.boss,
    },
    party = {
        kind = "group",
        groupKind = "party",
        frameName = "EQOLUFPartyAnchor",
        label = eqol.SOURCE_LABELS.party,
    },
}

eqol.TARGET_ORDER = {
    "cdm_essential",
    "cdm_utility",
    "cdm_buffbar",
    "cdm_bufficon",
    "eqol_player",
    "eqol_target",
    "eqol_targettarget",
    "eqol_focus",
    "eqol_pet",
    "eqol_boss",
    "eqol_party",
    "blizz_player",
    "blizz_target",
    "blizz_targettarget",
    "blizz_focus",
    "blizz_pet",
    "blizz_boss",
    "ui_parent",
}

eqol.PARTY_TARGET_ORDER = {
    "cdm_essential",
    "cdm_utility",
    "cdm_buffbar",
    "cdm_bufficon",
    "cdm_racials",
    "eqol_player",
    "eqol_target",
    "eqol_targettarget",
    "eqol_focus",
    "eqol_pet",
    "eqol_boss",
    "eqol_party",
    "blizz_player",
    "blizz_target",
    "blizz_targettarget",
    "blizz_focus",
    "blizz_pet",
    "blizz_boss",
    "ui_parent",
}

eqol.TARGETS = {
    ui_parent = {
        kind = "ui_parent",
        label = "UIParent (Screen)",
    },
    eqol_player = {
        kind = "eqol_source",
        source = "player",
        label = "EQOL Player Frame",
    },
    eqol_target = {
        kind = "eqol_source",
        source = "target",
        label = "EQOL Target Frame",
    },
    eqol_targettarget = {
        kind = "eqol_source",
        source = "targettarget",
        label = "EQOL Target of Target Frame",
    },
    eqol_focus = {
        kind = "eqol_source",
        source = "focus",
        label = "EQOL Focus Frame",
    },
    eqol_pet = {
        kind = "eqol_source",
        source = "pet",
        label = "EQOL Pet Frame",
    },
    eqol_boss = {
        kind = "eqol_source",
        source = "boss",
        label = "EQOL Boss Container",
    },
    eqol_party = {
        kind = "eqol_source",
        source = "party",
        label = "EQOL Party Frame",
    },
    blizz_player = {
        kind = "blizzard",
        frame = "PlayerFrame",
        label = "Blizzard PlayerFrame",
    },
    blizz_target = {
        kind = "blizzard",
        frame = "TargetFrame",
        label = "Blizzard TargetFrame",
    },
    blizz_targettarget = {
        kind = "blizzard",
        frame = "TargetFrameToT",
        label = "Blizzard TargetFrameToT",
    },
    blizz_focus = {
        kind = "blizzard",
        frame = "FocusFrame",
        label = "Blizzard FocusFrame",
    },
    blizz_pet = {
        kind = "blizzard",
        frame = "PetFrame",
        label = "Blizzard PetFrame",
    },
    blizz_boss = {
        kind = "blizzard",
        frame = "BossTargetFrameContainer",
        label = "Blizzard BossTargetFrameContainer",
    },
    cdm_essential = {
        kind = "cdm",
        frames = { "EssentialCooldownViewer_CDM_Container", "EssentialCooldownViewer" },
        label = "CDM Essential Viewer",
    },
    cdm_utility = {
        kind = "cdm",
        frames = { "UtilityCooldownViewer_AnchorContainer", "UtilityCooldownViewer" },
        label = "CDM Utility Viewer",
    },
    cdm_buffbar = {
        kind = "cdm",
        frames = { "BuffBarCooldownViewer_CDM_Container", "BuffBarCooldownViewer" },
        label = "CDM Buff Bar Viewer",
    },
    cdm_bufficon = {
        kind = "cdm",
        frames = { "BuffIconCooldownViewer_CDM_Container", "BuffIconCooldownViewer" },
        label = "CDM Buff Icon Viewer",
    },
    cdm_racials = {
        kind = "cdm",
        frames = { "CDM_RacialsContainer" },
        allowedSources = { party = true },
        label = "CDM Racials",
    },
}

eqol.TARGET_LABELS = {}
eqol.VALID_TARGETS = {}
eqol.TARGET_SOURCE_MAP = {}
for key, info in pairs(eqol.TARGETS) do
    eqol.TARGET_LABELS[key] = info.label or key
    eqol.VALID_TARGETS[key] = true
    if info.kind == "eqol_source" then
        eqol.TARGET_SOURCE_MAP[key] = info.source
    end
end

function eqol.GetTargetOrderForSource(source)
    if source == "party" then
        return eqol.PARTY_TARGET_ORDER
    end
    return eqol.TARGET_ORDER
end

function eqol.IsTargetAllowedForSource(source, target)
    if not eqol.VALID_TARGETS[target] then
        return false
    end

    local info = eqol.TARGETS[target]
    local allowedSources = info and info.allowedSources
    if not allowedSources then
        return true
    end

    return allowedSources[source] == true
end

function eqol.GetSourceDefaultField(source, field)
    local overrides = eqol.SOURCE_DEFAULT_OVERRIDES[source]
    if overrides and overrides[field] ~= nil then
        return overrides[field]
    end
    return eqol.SOURCE_DEFAULTS[field]
end

local function BuildDefaultSourceConfig(source)
    return {
        enabled = eqol.GetSourceDefaultField(source, "enabled"),
        target = eqol.GetSourceDefaultField(source, "target"),
        point = eqol.GetSourceDefaultField(source, "point"),
        relativePoint = eqol.GetSourceDefaultField(source, "relativePoint"),
        x = eqol.GetSourceDefaultField(source, "x"),
        y = eqol.GetSourceDefaultField(source, "y"),
    }
end

function eqol.BuildDefaultSources()
    local sources = {}
    for _, source in ipairs(eqol.SOURCE_ORDER) do
        sources[source] = BuildDefaultSourceConfig(source)
    end
    return sources
end

function eqol.GetDB()
    local profiles = ns.profiles
    local profile = profiles and type(profiles.GetActiveProfile) == "function" and profiles.GetActiveProfile() or nil
    if type(profile) ~= "table" then
        return { sources = eqol.BuildDefaultSources() }
    end

    profile.eqol = type(profile.eqol) == "table" and profile.eqol or {}
    profile.eqol.sources = type(profile.eqol.sources) == "table" and profile.eqol.sources or eqol.BuildDefaultSources()
    return profile.eqol
end

function eqol.NormalizeDB(db)
    db.sources = type(db.sources) == "table" and db.sources or {}
    local cleaned, err = eqol.ValidateSources(db.sources)
    if not cleaned then
        db.sources = eqol.BuildDefaultSources()
        return
    end
    db.sources = cleaned
end

function eqol.GetSourceConfig(source)
    return eqol.GetDB().sources[source]
end

function eqol.GetSourceLabel(source)
    return (eqol.SOURCE_INFO[source] and eqol.SOURCE_INFO[source].label) or source
end

function eqol.GetTargetLabel(target)
    return eqol.TARGET_LABELS[target] or target
end

function eqol.GetEQOL()
    return _G.EnhanceQoL
end

function eqol.GetUF()
    local engine = eqol.GetEQOL()
    return engine and engine.Aura and engine.Aura.UF or nil
end

function eqol.GetGF()
    local uf = eqol.GetUF()
    return uf and uf.GroupFrames or nil
end

local function CopySources(sources)
    local copy = {}
    for _, source in ipairs(eqol.SOURCE_ORDER) do
        copy[source] = BuildDefaultSourceConfig(source)
        local sourceInput = type(sources) == "table" and sources[source] or nil
        if type(sourceInput) == "table" then
            for key in pairs(eqol.SOURCE_DEFAULTS) do
                if sourceInput[key] ~= nil then
                    copy[source][key] = sourceInput[key]
                end
            end
        end
    end
    return copy
end

local function ValidateSingleSource(source, cfg)
    if type(cfg) ~= "table" then
        return nil, string.format("%s config is not a table", tostring(source))
    end

    local defaultTarget = eqol.GetSourceDefaultField(source, "target")
    local defaultPoint = eqol.GetSourceDefaultField(source, "point")

    local target = type(cfg.target) == "string" and string.lower(cfg.target) or defaultTarget
    if not eqol.IsTargetAllowedForSource(source, target) then
        return nil, string.format("Invalid target for %s: %s", tostring(source), tostring(cfg.target))
    end

    local point
    if cfg.point == nil then
        point = defaultPoint
    elseif type(cfg.point) == "string" then
        point = string.upper(cfg.point)
    end
    if not point or not (ns.VALID_POINTS and ns.VALID_POINTS[point]) then
        return nil, string.format("Invalid point for %s: %s", tostring(source), tostring(cfg.point))
    end

    local relativePoint
    if cfg.relativePoint == nil then
        relativePoint = point
    elseif type(cfg.relativePoint) == "string" then
        relativePoint = string.upper(cfg.relativePoint)
    end
    if not relativePoint or not (ns.VALID_POINTS and ns.VALID_POINTS[relativePoint]) then
        return nil, string.format("Invalid relative point for %s: %s", tostring(source), tostring(cfg.relativePoint))
    end

    local x = tonumber(cfg.x)
    local y = tonumber(cfg.y)
    if x == nil or y == nil then
        return nil, string.format("Offsets must be numeric for %s", tostring(source))
    end

    x = RoundNumber(x)
    y = RoundNumber(y)
    if x < OFFSET_MIN or x > OFFSET_MAX or y < OFFSET_MIN or y > OFFSET_MAX then
        return nil, string.format("Offsets for %s must be in [%d, %d]", tostring(source), OFFSET_MIN, OFFSET_MAX)
    end

    return {
        enabled = cfg.enabled == true,
        target = target,
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

local function DetectCycle(sources)
    local visiting = {}
    local visited = {}

    local function Walk(source, path)
        if visited[source] then
            return nil
        end
        if visiting[source] then
            local cyclePath = CopyValue(path)
            cyclePath[#cyclePath + 1] = source
            return string.format("Anchor cycle detected: %s", table.concat(cyclePath, " -> "))
        end

        visiting[source] = true
        path[#path + 1] = source

        local cfg = sources[source]
        if cfg and cfg.enabled then
            local targetSource = eqol.TARGET_SOURCE_MAP[cfg.target]
            if targetSource and sources[targetSource] and sources[targetSource].enabled then
                local err = Walk(targetSource, path)
                if err then
                    return err
                end
            end
        end

        path[#path] = nil
        visiting[source] = nil
        visited[source] = true
        return nil
    end

    for _, source in ipairs(eqol.SOURCE_ORDER) do
        local err = Walk(source, {})
        if err then
            return err
        end
    end

    return nil
end

function eqol.ValidateSources(sources)
    if type(sources) ~= "table" then
        return nil, "Sources payload is not a table"
    end

    local cleaned = {}
    for _, source in ipairs(eqol.SOURCE_ORDER) do
        local sourceCfg = sources[source]
        if sourceCfg == nil then
            sourceCfg = BuildDefaultSourceConfig(source)
        end
        local validated, err = ValidateSingleSource(source, sourceCfg)
        if not validated then
            return nil, err
        end
        cleaned[source] = validated
    end

    local cycleErr = DetectCycle(cleaned)
    if cycleErr then
        return nil, cycleErr
    end

    return cleaned
end

local function CommitSources(candidateSources)
    local cleaned, err = eqol.ValidateSources(candidateSources)
    if not cleaned then
        return nil, err
    end

    local db = eqol.GetDB()
    ns.WipeTable(db.sources)
    for _, source in ipairs(eqol.SOURCE_ORDER) do
        db.sources[source] = cleaned[source]
    end

    return true
end

function eqol.TrySetSourceField(source, field, value)
    if not eqol.SOURCE_INFO[source] then
        return nil, "Unknown source: " .. tostring(source)
    end
    if eqol.SOURCE_DEFAULTS[field] == nil then
        return nil, "Unknown field: " .. tostring(field)
    end

    local candidate = CopySources(eqol.GetDB().sources)
    candidate[source][field] = value
    return CommitSources(candidate)
end

function eqol.TryReplaceSource(source, value)
    if not eqol.SOURCE_INFO[source] then
        return nil, "Unknown source: " .. tostring(source)
    end

    local candidate = CopySources(eqol.GetDB().sources)
    candidate[source] = value
    return CommitSources(candidate)
end

function eqol.TryReplaceAllSources(value)
    local candidate = CopySources(value)
    return CommitSources(candidate)
end

function eqol.ResetAllSources()
    local reset = {}
    for _, source in ipairs(eqol.SOURCE_ORDER) do
        reset[source] = BuildDefaultSourceConfig(source)
    end
    return eqol.TryReplaceAllSources(reset)
end

function eqol.ResetSource(source)
    return eqol.TryReplaceSource(source, BuildDefaultSourceConfig(source))
end

return eqol
