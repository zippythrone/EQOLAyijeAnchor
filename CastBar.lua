local ADDON_NAME, ns = ...
local castbar = ns.castbar

if type(castbar) ~= "table" then
    castbar = {}
    ns.castbar = castbar
end

castbar.DEFAULTS = {
    target = "essential", -- screen | resources | essential | utility
    point = "TOP",        -- point on the cast bar
    relativePoint = "BOTTOM", -- point on the target frame
    x = 0,
    y = -1,
}

castbar.VALID_TARGETS = {
    screen = true,
    resources = true,
    essential = true,
    utility = true,
}

-- Stable ordered list of targets for options UIs and validation.
castbar.TARGET_ORDER = { "essential", "utility", "resources", "screen" }

local OFFSET_MIN = -300
local OFFSET_MAX = 300

castbar.OFFSET_MIN = OFFSET_MIN
castbar.OFFSET_MAX = OFFSET_MAX

local function NormalizeStoredOffset(value, fallback)
    value = tonumber(value)
    if not value then
        return fallback
    end

    if value ~= math.floor(value) then
        value = value >= 0 and math.floor(value + 0.5) or math.ceil(value - 0.5)
    end
    if value < OFFSET_MIN then
        return OFFSET_MIN
    end
    if value > OFFSET_MAX then
        return OFFSET_MAX
    end
    return value
end

local function GetActiveProfile()
    local profiles = ns.profiles
    if not profiles or type(profiles.GetActiveProfile) ~= "function" then
        return nil
    end

    local profile = profiles.GetActiveProfile()
    if type(profile) ~= "table" then
        return nil
    end

    profile.castbar = type(profile.castbar) == "table" and profile.castbar or castbar.BuildDefaultConfig()
    return profile
end

local function GetActiveConfig()
    local profile = GetActiveProfile()
    if not profile then
        return nil
    end
    return profile.castbar
end

local function ValidateOffset(value, fieldName)
    local n = tonumber(value)
    if not n or n ~= math.floor(n) then
        return nil, string.format("%s must be a whole number", fieldName)
    end
    if n < OFFSET_MIN or n > OFFSET_MAX then
        return nil, string.format("%s must be in [%d, %d]", fieldName, OFFSET_MIN, OFFSET_MAX)
    end
    return n
end

function castbar.BuildDefaultConfig()
    return {
        target = castbar.DEFAULTS.target,
        point = castbar.DEFAULTS.point,
        relativePoint = castbar.DEFAULTS.relativePoint,
        x = castbar.DEFAULTS.x,
        y = castbar.DEFAULTS.y,
    }
end

function castbar.GetDB()
    if not castbar._dbProxy then
        castbar._dbProxy = setmetatable({}, {
            __index = function(_, key)
                local db = GetActiveConfig()
                if db then
                    return db[key]
                end
                return castbar.DEFAULTS[key]
            end,
            __newindex = function(_, key, value)
                local ok, err = castbar.TrySetField(key, value)
                if not ok then
                    error(err, 2)
                end
            end,
            __pairs = function()
                local db = GetActiveConfig() or castbar.BuildDefaultConfig()
                return next, db, nil
            end,
            __metatable = false,
        })
    end

    return castbar._dbProxy
end

function castbar.ValidateConfig(t)
    if type(t) ~= "table" then
        return nil, "Not a table"
    end

    local validPoints = ns.VALID_POINTS or {}

    local target = type(t.target) == "string" and t.target:lower() or nil
    if not target or not castbar.VALID_TARGETS[target] then
        return nil, "Invalid target: " .. tostring(t.target)
    end

    local point = type(t.point) == "string" and t.point:upper() or nil
    if not point or not validPoints[point] then
        return nil, "Invalid point: " .. tostring(t.point)
    end

    local relativePoint = type(t.relativePoint) == "string" and t.relativePoint:upper() or nil
    if not relativePoint or not validPoints[relativePoint] then
        return nil, "Invalid relativePoint: " .. tostring(t.relativePoint)
    end

    local x, xErr = ValidateOffset(t.x, "x")
    if not x then
        return nil, xErr
    end

    local y, yErr = ValidateOffset(t.y, "y")
    if not y then
        return nil, yErr
    end

    return {
        target = target,
        point = point,
        relativePoint = relativePoint,
        x = x,
        y = y,
    }
end

function castbar.NormalizeDB(db)
    if type(db) ~= "table" then
        return
    end

    for k, v in pairs(castbar.BuildDefaultConfig()) do
        if db[k] == nil then
            db[k] = v
        end
    end

    local validPoints = ns.VALID_POINTS or {}

    local target = type(db.target) == "string" and db.target:lower() or nil
    db.target = castbar.VALID_TARGETS[target] and target or castbar.DEFAULTS.target

    local point = type(db.point) == "string" and db.point:upper() or nil
    db.point = validPoints[point] and point or castbar.DEFAULTS.point

    local relativePoint = type(db.relativePoint) == "string" and db.relativePoint:upper() or nil
    db.relativePoint = validPoints[relativePoint] and relativePoint or castbar.DEFAULTS.relativePoint

    db.x = NormalizeStoredOffset(db.x, castbar.DEFAULTS.x)
    db.y = NormalizeStoredOffset(db.y, castbar.DEFAULTS.y)
end

function castbar.TrySetField(field, value)
    if type(field) ~= "string" or castbar.DEFAULTS[field] == nil then
        return nil, "Unknown field: " .. tostring(field)
    end

    local profile = GetActiveProfile()
    if not profile then
        return nil, "Active profile is not available"
    end

    local candidate = castbar.BuildDefaultConfig()
    for k, v in pairs(profile.castbar) do
        candidate[k] = v
    end
    candidate[field] = value

    local cleaned, err = castbar.ValidateConfig(candidate)
    if not cleaned then
        return nil, err
    end

    profile.castbar = cleaned
    return true
end

function castbar.ResolveTargetFrame(target)
    local CDM = _G.Ayije_CDM
    if not CDM then
        return nil
    end

    if target == "essential" then
        local viewers = CDM.CONST and CDM.CONST.VIEWERS
        return CDM.anchorContainers and viewers and CDM.anchorContainers[viewers.ESSENTIAL] or nil
    elseif target == "utility" then
        local viewers = CDM.CONST and CDM.CONST.VIEWERS
        return CDM.anchorContainers and viewers and CDM.anchorContainers[viewers.UTILITY] or nil
    end

    -- "screen" and "resources": passthrough to Ayije positioning.
    return nil
end

function castbar.GetPreviewTarget()
    return castbar.ResolveTargetFrame(castbar.GetDB().target)
end

function castbar.ApplyAnchor()
    local CDM = _G.Ayije_CDM
    if not CDM or not CDM.castBarContainer then
        return
    end

    local db = castbar.GetDB()
    local target = castbar.ResolveTargetFrame(db.target)
    if not target then
        return
    end

    local container = CDM.castBarContainer
    container:ClearAllPoints()
    container:SetPoint(db.point, target, db.relativePoint, db.x, db.y)
end

local function ForceLockContainer()
    local CDM = _G.Ayije_CDM
    if not CDM then return end
    local container = CDM.castBarContainer
    if not container then return end
    container:SetMovable(false)
    container:EnableMouse(false)
    if container.helperText then container.helperText:Hide() end
    if container.dragOverlay then container.dragOverlay:Hide() end
end

castbar.ForceLockContainer = ForceLockContainer

function castbar.NotifyChanged()
    local CDM = _G.Ayije_CDM
    if CDM and CDM.UpdatePlayerCastBar then
        CDM:UpdatePlayerCastBar()
    else
        castbar.ApplyAnchor()
        castbar.ForceLockContainer()
    end
end

do
    local CDM = _G.Ayije_CDM
    if CDM and type(CDM.UpdatePlayerCastBar) == "function" then
        hooksecurefunc(CDM, "UpdatePlayerCastBar", function()
            castbar.ApplyAnchor()
            castbar.ForceLockContainer()
        end)
    end
end

local lifecycle = CreateFrame("Frame")
lifecycle:RegisterEvent("ADDON_LOADED")
lifecycle:RegisterEvent("PLAYER_LOGIN")
lifecycle:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then
            ns.GetDB()
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        castbar.NotifyChanged()
    end
end)
