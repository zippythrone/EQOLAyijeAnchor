local ADDON_NAME, ns = ...
local eqol = ns.eqol

if type(eqol) ~= "table" then
    eqol = {}
    ns.eqol = eqol
end

local SHORT_TAG = ns.SHORT_TAG or "EQAYA"
local After = C_Timer and C_Timer.After

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
            EmitWarning(source, cfg.target, "Target frame could not be measured", "Keeping the last successfully applied position.")
        end
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

eqol.MarkDirty = MarkDirty

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

return eqol
