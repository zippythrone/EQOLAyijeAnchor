local M = {}

local function makeFrame(name)
    local frame = {
        _name = name,
        _points = {},
    }

    function frame:RegisterEvent() end
    function frame:UnregisterEvent() end
    function frame:SetScript() end
    function frame:ClearAllPoints()
        self._points = {}
    end
    function frame:SetPoint(point, relativeTo, relativePoint, x, y)
        self._points[#self._points + 1] = {
            point = point,
            relativeTo = relativeTo,
            relativePoint = relativePoint,
            x = x,
            y = y,
        }
    end
    function frame:GetCenter()
        return 0, 0
    end
    function frame:GetEffectiveScale()
        return 1
    end
    function frame:GetWidth()
        return 100
    end
    function frame:GetHeight()
        return 100
    end
    function frame:SetMovable() end
    function frame:EnableMouse() end
    function frame:Hide() self.hidden = true end
    function frame:Show() self.hidden = false end
    function frame:SetBackdrop() end
    function frame:SetBackdropBorderColor() end

    return frame
end

function M.newContext()
    local ns = {
        eqol = {},
        castbar = {},
        profiles = {},
        options = {},
    }

    _G.UIParent = _G.UIParent or makeFrame("UIParent")
    _G.UIParent.GetCenter = _G.UIParent.GetCenter or function()
        return 0, 0
    end
    _G.UIParent.GetEffectiveScale = _G.UIParent.GetEffectiveScale or function()
        return 1
    end
    _G.UIParent.GetWidth = _G.UIParent.GetWidth or function()
        return 1920
    end
    _G.UIParent.GetHeight = _G.UIParent.GetHeight or function()
        return 1080
    end

    _G.CreateFrame = function(_, name)
        return makeFrame(name or "Frame")
    end

    _G.Settings = _G.Settings or {
        RegisterCanvasLayoutCategory = function() end,
        RegisterAddOnCategory = function() end,
    }

    _G.StaticPopupDialogs = _G.StaticPopupDialogs or {}
    _G.SlashCmdList = _G.SlashCmdList or {}

    _G.C_Timer = _G.C_Timer or {}
    _G.C_Timer.After = function(_, callback)
        if type(callback) == "function" then
            callback()
        end
    end

    _G.hooksecurefunc = _G.hooksecurefunc or function() end
    _G.InCombatLockdown = _G.InCombatLockdown or function()
        return false
    end

    local context = { ns = ns }

    function context.load(relpath)
        local chunk, err = loadfile("AddOns/EQOLAyijeAnchor/" .. relpath)
        assert(chunk, err)
        return chunk("EQOLAyijeAnchor", ns)
    end

    return context
end

return M
