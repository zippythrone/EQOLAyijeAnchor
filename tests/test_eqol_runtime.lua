local function currentDir()
    local source = debug.getinfo(1, "S").source
    source = source:sub(2)
    return source:match("^(.*)/[^/]+$") or "."
end

local testsDir = currentDir()
local bootstrap = dofile(testsDir .. "/bootstrap.lua")
local ctx = bootstrap.newContext()

ctx.load("Core.lua")
ctx.load("EQOLConfig.lua")
ctx.load("CastBar.lua")
ctx.load("Profiles.lua")
ctx.load("EQOLRuntime.lua")

local eqol = ctx.ns.eqol

local warningMessage = nil
_G.geterrorhandler = function()
    return function(message)
        warningMessage = message
    end
end

local function makeMeasuredFrame(width, height, centerX, centerY)
    local frame = {
        _points = {},
    }

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
        return centerX or 0, centerY or 0
    end

    function frame:GetEffectiveScale()
        return 1
    end

    function frame:GetWidth()
        return width
    end

    function frame:GetHeight()
        return height
    end

    return frame
end

assert(eqol.TrySetSourceField("party", "enabled", true) == true, "expected party source to be enabled")

local sourceFrame = makeMeasuredFrame(200, 80, 100, 100)
local targetFrame = makeMeasuredFrame(0, 0, 300, 300)

_G.EQOLUFPartyAnchor = sourceFrame
_G.CDM_RacialsContainer = targetFrame

local applied = eqol.ApplySourceAnchor("party")
assert(applied == false, "expected unresolved racials measurement to defer")
assert(warningMessage == nil, "expected transient zero-size racials frame to defer without warning")

targetFrame.GetWidth = function()
    return 120
end
targetFrame.GetHeight = function()
    return 40
end

applied = eqol.ApplySourceAnchor("party")
assert(applied == true, "expected racials mirror to apply once the target becomes measurable")
assert(#sourceFrame._points == 1, "expected anchor point to be applied to the party frame")
