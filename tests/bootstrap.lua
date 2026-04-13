local M = {}

local function currentDir()
    local source = debug.getinfo(1, "S").source
    source = source:sub(2)
    return source:match("^(.*)/[^/]+$") or "."
end

local function serializeValue(value)
    local valueType = type(value)
    if valueType == "string" then
        return string.format("%q", value)
    end
    if valueType == "number" or valueType == "boolean" then
        return tostring(value)
    end
    if valueType == "table" then
        local keys = {}
        for key in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(lhs, rhs)
            return tostring(lhs) < tostring(rhs)
        end)

        local parts = { "{" }
        for _, key in ipairs(keys) do
            parts[#parts + 1] = "[" .. serializeValue(key) .. "]=" .. serializeValue(value[key]) .. ","
        end
        parts[#parts + 1] = "}"
        return table.concat(parts)
    end
    error("Unsupported fake serialization type: " .. valueType)
end

local function deserializeValue(payload)
    local loader = loadstring or load
    local chunk, err = loader("return " .. payload)
    assert(chunk, err)
    return chunk()
end

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
    local testsDir = currentDir()
    local addonRoot = testsDir:match("^(.*)/tests$") or "."
    local ns = {
        eqol = {},
        castbar = {},
        profiles = {},
        options = {},
    }

    _G.EQOLAyijeAnchorDB = nil

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

    local settingsState = {
        nextCategoryID = 1,
        categories = {},
        openedCategoryID = nil,
        addOnCategories = {},
    }

    local function makeCategory(name)
        local category = {
            _id = settingsState.nextCategoryID,
            name = name,
            initializers = {},
            controls = {},
        }
        settingsState.nextCategoryID = settingsState.nextCategoryID + 1

        function category:GetID()
            return self._id
        end

        return category
    end

    local function pushControl(category, control)
        if category and category.controls then
            category.controls[#category.controls + 1] = control
        end
        return control
    end

    _G.Settings = _G.Settings or {}
    _G.Settings.VarType = _G.Settings.VarType or {
        Boolean = "boolean",
        Number = "number",
        String = "string",
    }
    _G.Settings.RegisterCanvasLayoutCategory = _G.Settings.RegisterCanvasLayoutCategory or function() end
    _G.Settings.RegisterAddOnCategory = function(category)
        settingsState.addOnCategories[#settingsState.addOnCategories + 1] = category
    end
    _G.Settings.RegisterVerticalLayoutCategory = function(name)
        local category = makeCategory(name)
        local layout = {
            category = category,
            initializers = category.initializers,
        }

        function layout:AddInitializer(initializer)
            self.initializers[#self.initializers + 1] = initializer
            return initializer
        end

        settingsState.categories[#settingsState.categories + 1] = category
        return category, layout
    end
    _G.Settings.CreateElementInitializer = function(template, data)
        return {
            template = template,
            data = data or {},
        }
    end
    _G.Settings.RegisterProxySetting = function(category, key, varType, displayName, defaultValue, getter, setter)
        local setting = {
            category = category,
            key = key,
            varType = varType,
            displayName = displayName,
            defaultValue = defaultValue,
            getter = getter,
            setter = setter,
            value = defaultValue,
        }

        function setting:GetValue()
            if type(self.getter) == "function" then
                return self.getter()
            end
            return self.value
        end

        function setting:SetValue(value, initializing)
            self.value = value
            if type(self.setter) == "function" then
                return self.setter(value, initializing)
            end
        end

        function setting:GetVariable()
            return self.key
        end

        return setting
    end
    _G.Settings.CreateCheckbox = function(category, setting, desc)
        return pushControl(category, {
            kind = "checkbox",
            category = category,
            setting = setting,
            desc = desc,
        })
    end
    _G.Settings.CreateDropdown = function(category, setting, optionsFn, desc)
        local control = {
            kind = "dropdown",
            category = category,
            setting = setting,
            optionsFn = optionsFn,
            desc = desc,
        }

        function control:GetOptions()
            if type(self.optionsFn) == "function" then
                return self.optionsFn()
            end
            return self.optionsFn
        end

        control.options = control:GetOptions()
        return pushControl(category, control)
    end
    _G.Settings.CreateSliderOptions = function(minValue, maxValue, step)
        local sliderOptions = {
            minValue = minValue,
            maxValue = maxValue,
            step = step,
        }

        function sliderOptions:SetLabelFormatter(formatter)
            self.labelFormatter = formatter
        end

        return sliderOptions
    end
    _G.Settings.CreateSlider = function(category, setting, sliderOptions, desc)
        return pushControl(category, {
            kind = "slider",
            category = category,
            setting = setting,
            sliderOptions = sliderOptions,
            desc = desc,
        })
    end
    _G.Settings.CreateControlTextContainer = function()
        local container = {
            data = {},
        }

        function container:Add(value, label, tooltip)
            self.data[value] = {
                label = label,
                tooltip = tooltip,
            }
            return self.data[value]
        end

        function container:GetData()
            return self.data
        end

        return container
    end
    _G.Settings.OpenToCategory = function(categoryID)
        settingsState.openedCategoryID = categoryID
    end
    _G.Settings._state = settingsState

    _G.CreateSettingsButtonInitializer = _G.CreateSettingsButtonInitializer or function(label, text, click, desc, searchtags)
        return {
            template = "SettingsButtonControlTemplate",
            label = label,
            text = text,
            click = click,
            desc = desc,
            searchtags = searchtags,
        }
    end

    _G.StaticPopupDialogs = _G.StaticPopupDialogs or {}
    _G.StaticPopup_Show = _G.StaticPopup_Show or function(key)
        local dialog = _G.StaticPopupDialogs[key]
        if not dialog then
            return nil
        end

        local popup = {
            key = key,
            dialog = dialog,
            hidden = false,
        }

        local editBox = {
            text = "",
        }

        function editBox:GetText()
            return self.text
        end

        function editBox:SetText(text)
            self.text = text
        end

        function editBox:HighlightText() end
        function editBox:SetFocus() end
        function editBox:GetParent()
            return popup
        end

        popup.EditBox = editBox
        popup.editBox = editBox

        function popup:GetEditBox()
            return editBox
        end

        function popup:Hide()
            self.hidden = true
        end

        function popup:Accept()
            if type(dialog.OnAccept) == "function" then
                return dialog.OnAccept(self)
            end
        end

        function popup:SubmitText()
            if type(dialog.EditBoxOnEnterPressed) == "function" then
                return dialog.EditBoxOnEnterPressed(editBox)
            end
        end

        if type(dialog.OnShow) == "function" then
            dialog.OnShow(popup)
        end

        _G.__lastStaticPopup = popup
        return popup
    end
    _G.SlashCmdList = _G.SlashCmdList or {}

    _G.C_Timer = _G.C_Timer or {}
    _G.C_Timer.After = function(_, callback)
        if type(callback) == "function" then
            callback()
        end
    end

    _G.C_EncodingUtil = {
        SerializeCBOR = serializeValue,
        DeserializeCBOR = deserializeValue,
        CompressString = function(s)
            return s
        end,
        DecompressString = function(s)
            return s
        end,
        EncodeBase64 = function(s)
            return s
        end,
        DecodeBase64 = function(s)
            return s
        end,
    }

    _G.hooksecurefunc = _G.hooksecurefunc or function() end
    _G.InCombatLockdown = _G.InCombatLockdown or function()
        return false
    end

    _G.OKAY = _G.OKAY or "OK"
    _G.CANCEL = _G.CANCEL or "Cancel"
    _G.DELETE = _G.DELETE or "Delete"
    _G.MinimalSliderWithSteppersMixin = _G.MinimalSliderWithSteppersMixin or {
        Label = {
            Right = "Right",
        },
    }

    local context = { ns = ns }

    function context.load(relpath)
        local chunk, err = loadfile(addonRoot .. "/" .. relpath)
        assert(chunk, err)
        return chunk("EQOLAyijeAnchor", ns)
    end

    return context
end

return M
