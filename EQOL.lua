local ADDON_NAME, ns = ...
local eqol = ns.eqol

if type(eqol) ~= "table" then
    eqol = {}
    ns.eqol = eqol
end

local OFFSET_MIN = -3000
local OFFSET_MAX = 3000
local SHORT_TAG = ns.SHORT_TAG or "EQAYA"
local After = C_Timer and C_Timer.After

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

local dirtySources = {}
local lastAbsoluteAnchors = {}
local warningState = {}
local deferredApplyPending = false

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

local function NormalizePoint(value, fallback)
    local point = type(value) == "string" and string.upper(value) or fallback
    if ns.VALID_POINTS and ns.VALID_POINTS[point] then
        return point
    end
    return fallback
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
    local db = ns.GetDB().eqol
    db.sources = type(db.sources) == "table" and db.sources or eqol.BuildDefaultSources()
    return db
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

function eqol.ResolveSourceFrame(source)
    local info = eqol.SOURCE_INFO[source]
    if not info then
        return nil
    end

    if info.kind == "group" then
        local gf = eqol.GetGF()
        if gf and type(gf.EnsureHeaders) == "function" and not (InCombatLockdown and InCombatLockdown()) then
            pcall(gf.EnsureHeaders, gf)
        end
    else
        local uf = eqol.GetUF()
        if uf and type(uf.EnsureFrames) == "function" and not (InCombatLockdown and InCombatLockdown()) then
            pcall(uf.EnsureFrames, info.ensureUnit)
        end
    end

    return _G[info.frameName]
end

function eqol.ResolveTargetFrame(target)
    local info = eqol.TARGETS[target]
    if not info then
        return nil
    end

    if info.kind == "ui_parent" then
        return UIParent
    elseif info.kind == "eqol_source" then
        return eqol.ResolveSourceFrame(info.source)
    elseif info.kind == "blizzard" then
        return _G[info.frame]
    elseif info.kind == "cdm" then
        for _, frameName in ipairs(info.frames or {}) do
            local frame = _G[frameName]
            if frame then
                return frame
            end
        end
    end

    return nil
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

local function ClearWarnings(source)
    warningState[source] = nil
end

local function EmitWarning(source, target, reason, detail)
    local targetKey = target or "unknown"
    local throttleKey = table.concat({ tostring(source), tostring(targetKey), tostring(reason) }, "::")

    warningState[source] = warningState[source] or {}
    if warningState[source][throttleKey] then
        return
    end
    warningState[source][throttleKey] = true

    local lines = {
        string.format("[%s] %s -> %s", SHORT_TAG, eqol.GetSourceLabel(source), eqol.GetTargetLabel(targetKey)),
        "Reason: " .. tostring(reason),
    }
    if detail and detail ~= "" then
        lines[#lines + 1] = "Detail: " .. tostring(detail)
    end

    if debugstack then
        local ok, stack = pcall(debugstack, 3, 8, 8)
        if ok and type(stack) == "string" and stack ~= "" then
            lines[#lines + 1] = "Stack:\n" .. stack
        end
    end

    local handler = geterrorhandler and geterrorhandler()
    if type(handler) == "function" then
        handler(table.concat(lines, "\n"))
    else
        print(table.concat(lines, "\n"))
    end
end

eqol.EmitWarning = EmitWarning

local function GetPointOffset(point, width, height)
    local x = 0
    local y = 0
    point = NormalizePoint(point, "CENTER")

    if point:find("LEFT", 1, true) then
        x = x - (width / 2)
    elseif point:find("RIGHT", 1, true) then
        x = x + (width / 2)
    end

    if point:find("TOP", 1, true) then
        y = y + (height / 2)
    elseif point:find("BOTTOM", 1, true) then
        y = y - (height / 2)
    end

    return x, y
end

local function CaptureAbsoluteAnchor(frame, point)
    if not frame or not frame.GetCenter or not UIParent or not UIParent.GetCenter then
        return nil
    end

    local centerX, centerY = frame:GetCenter()
    local uiCenterX, uiCenterY = UIParent:GetCenter()
    if not centerX or not centerY or not uiCenterX or not uiCenterY then
        return nil
    end

    local uiScale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local frameScale = (frame.GetEffectiveScale and frame:GetEffectiveScale()) or uiScale
    local scaleFactor = frameScale / uiScale

    centerX = centerX * scaleFactor
    centerY = centerY * scaleFactor

    local width = ((frame.GetWidth and frame:GetWidth()) or 0) * scaleFactor
    local height = ((frame.GetHeight and frame:GetHeight()) or 0) * scaleFactor
    local x = centerX - uiCenterX
    local y = centerY - uiCenterY

    local pointOffsetX, pointOffsetY = GetPointOffset(point, width, height)
    x = x + pointOffsetX
    y = y + pointOffsetY

    return {
        point = NormalizePoint(point, "CENTER"),
        relativePoint = "CENTER",
        x = RoundNumber(x),
        y = RoundNumber(y),
    }
end

local function BuildAbsoluteAnchorFromTargetFramePoint(targetFrame, sourcePoint, targetPoint, offsetX, offsetY)
    if not targetFrame or not targetFrame.GetCenter or not UIParent or not UIParent.GetCenter then
        return nil
    end

    local centerX, centerY = targetFrame:GetCenter()
    local uiCenterX, uiCenterY = UIParent:GetCenter()
    if not centerX or not centerY or not uiCenterX or not uiCenterY then
        return nil
    end

    local uiScale = (UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    local frameScale = (targetFrame.GetEffectiveScale and targetFrame:GetEffectiveScale()) or uiScale
    local scaleFactor = frameScale / uiScale

    centerX = centerX * scaleFactor
    centerY = centerY * scaleFactor

    local width = ((targetFrame.GetWidth and targetFrame:GetWidth()) or 0) * scaleFactor
    local height = ((targetFrame.GetHeight and targetFrame:GetHeight()) or 0) * scaleFactor
    if width <= 0 or height <= 0 then
        return nil
    end
    local pointOffsetX, pointOffsetY = GetPointOffset(targetPoint, width, height)

    return {
        point = NormalizePoint(sourcePoint, "CENTER"),
        relativePoint = "CENTER",
        x = RoundNumber((centerX - uiCenterX) + pointOffsetX + (tonumber(offsetX) or 0)),
        y = RoundNumber((centerY - uiCenterY) + pointOffsetY + (tonumber(offsetY) or 0)),
    }
end

local function ApplyAbsoluteAnchor(frame, anchor)
    if not frame or not anchor then
        return false
    end
    frame:ClearAllPoints()
    frame:SetPoint(anchor.point or "CENTER", UIParent, anchor.relativePoint or "CENTER", anchor.x or 0, anchor.y or 0)
    return true
end

local MarkDirty

local function ApplyMirroredPartyRacialsAnchor(source, sourceFrame, cfg, targetFrame)
    local anchor = BuildAbsoluteAnchorFromTargetFramePoint(
        targetFrame,
        cfg.point,
        cfg.relativePoint,
        cfg.x,
        cfg.y
    )

    if not anchor then
        MarkDirty(source)
        if lastAbsoluteAnchors[source] then
            ApplyAbsoluteAnchor(sourceFrame, lastAbsoluteAnchors[source])
        end
        EmitWarning(source, cfg.target, "Target frame could not be measured", "Keeping the last successfully applied position.")
        return false
    end

    ApplyAbsoluteAnchor(sourceFrame, anchor)
    lastAbsoluteAnchors[source] = anchor
    dirtySources[source] = nil
    ClearWarnings(source)
    return true
end

MarkDirty = function(source)
    if source then
        dirtySources[source] = true
        return
    end

    for _, sourceKey in ipairs(eqol.SOURCE_ORDER) do
        local cfg = eqol.GetSourceConfig(sourceKey)
        if cfg and cfg.enabled then
            dirtySources[sourceKey] = true
        end
    end
end

function eqol.ApplySourceAnchor(source)
    local cfg = eqol.GetSourceConfig(source)
    if not cfg or not cfg.enabled then
        dirtySources[source] = nil
        ClearWarnings(source)
        return true
    end

    if InCombatLockdown and InCombatLockdown() then
        MarkDirty(source)
        return false
    end

    local sourceFrame = eqol.ResolveSourceFrame(source)
    if not sourceFrame then
        MarkDirty(source)
        EmitWarning(source, cfg.target, "Source frame could not be resolved", "Enable the corresponding EQOL frame (Esc -> Options -> EnhanceQoL), then reapply.")
        return false
    end

    local targetFrame = eqol.ResolveTargetFrame(cfg.target)
    if not targetFrame then
        MarkDirty(source)
        if lastAbsoluteAnchors[source] then
            ApplyAbsoluteAnchor(sourceFrame, lastAbsoluteAnchors[source])
        end
        EmitWarning(source, cfg.target, "Target frame could not be resolved", "Keeping the last successfully applied position.")
        return false
    end

    if source == "party" and cfg.target == "cdm_racials" then
        return ApplyMirroredPartyRacialsAnchor(source, sourceFrame, cfg, targetFrame)
    end

    sourceFrame:ClearAllPoints()
    sourceFrame:SetPoint(cfg.point, targetFrame, cfg.relativePoint, cfg.x, cfg.y)
    lastAbsoluteAnchors[source] = CaptureAbsoluteAnchor(sourceFrame, cfg.point) or lastAbsoluteAnchors[source]
    dirtySources[source] = nil
    ClearWarnings(source)
    return true
end

function eqol.ApplyAllAnchors()
    if InCombatLockdown and InCombatLockdown() then
        MarkDirty()
        return
    end

    for _, source in ipairs(eqol.SOURCE_ORDER) do
        eqol.ApplySourceAnchor(source)
    end
end

function eqol.ApplyDirtyAnchors()
    if InCombatLockdown and InCombatLockdown() then
        return
    end

    local hadDirty = false
    for _, source in ipairs(eqol.SOURCE_ORDER) do
        if dirtySources[source] then
            hadDirty = true
            eqol.ApplySourceAnchor(source)
        end
    end
    if not hadDirty then
        eqol.ApplyAllAnchors()
    end
end

function eqol.RequestDeferredApply()
    if deferredApplyPending then
        return
    end
    deferredApplyPending = true

    local function Run()
        deferredApplyPending = false
        eqol.ApplyAllAnchors()
    end

    if After then
        After(0, Run)
    else
        Run()
    end
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

function eqol.ClearRuntimeState()
    ns.WipeTable(dirtySources)
    ns.WipeTable(lastAbsoluteAnchors)
    ns.WipeTable(warningState)
end

function eqol.NotifyChanged()
    local uf = eqol.GetUF()
    if uf and type(uf.Refresh) == "function" then
        uf.Refresh()
    else
        eqol.ApplyAllAnchors()
    end
end

function eqol.GetPreviewTarget(source)
    local cfg = eqol.GetSourceConfig(source)
    return cfg and eqol.ResolveTargetFrame(cfg.target) or nil
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

    MarkDirty("party")
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
