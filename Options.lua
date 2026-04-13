local ADDON_NAME, ns = ...
local options = ns.options or {}
ns.options = options

local SETTING_VAR_PREFIX = "EQOLAyijeAnchor_"

local CASTBAR_TARGET_LABELS = {
    essential = "Essential CDM Frame",
    utility = "Utility CDM Frame",
    resources = "Resources frame (passthrough)",
    screen = "Screen (passthrough - Ayije controls)",
}

local proxySettings = {}
local previewSettings = {}
local refreshing = false
local refreshingPreview = false
local previewSelection = nil
local previewBorder = nil

local function PrintError(message)
    print("|cFFff5555[EQAYA]|r " .. tostring(message))
end

local function PrintSuccess(message)
    print("|cFF3bb273[EQAYA]|r " .. tostring(message))
end

local function GetPopupEditBox(popup)
    if not popup then return nil end
    if popup.EditBox then return popup.EditBox end
    if popup.editBox then return popup.editBox end
    if popup.GetEditBox then return popup:GetEditBox() end
    return nil
end

local function GetPreviewBorder()
    if previewBorder then
        return previewBorder
    end

    previewBorder = CreateFrame("Frame", "EQOLAyijeAnchorPreviewBorder", UIParent, "BackdropTemplate")
    previewBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    previewBorder:SetBackdropBorderColor(0.24, 0.65, 0.95, 1)
    previewBorder:SetFrameStrata("HIGH")
    previewBorder:Hide()
    return previewBorder
end

local function HidePreviewBorder()
    if previewBorder then
        previewBorder:Hide()
    end
end

local function ResolvePreviewTarget()
    if not previewSelection then
        return nil
    end

    if previewSelection.kind == "eqol" then
        return ns.eqol.GetPreviewTarget(previewSelection.source)
    end

    if previewSelection.kind == "castbar" then
        return ns.castbar.GetPreviewTarget()
    end

    return nil
end

local function RefreshPreviewBorder()
    local target = ResolvePreviewTarget()
    if not target then
        HidePreviewBorder()
        return
    end

    local border = GetPreviewBorder()
    border:ClearAllPoints()
    border:SetPoint("TOPLEFT", target, "TOPLEFT", -4, 4)
    border:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 4, -4)
    border:Show()
end

local function SelectionsEqual(left, right)
    if left == right then
        return true
    end
    if not left or not right then
        return false
    end
    if left.kind ~= right.kind then
        return false
    end
    if left.kind == "eqol" then
        return left.source == right.source
    end
    return left.kind == "castbar"
end

local function CopySelection(selection)
    if not selection then
        return nil
    end
    if selection.kind == "eqol" then
        return { kind = "eqol", source = selection.source }
    end
    if selection.kind == "castbar" then
        return { kind = "castbar" }
    end
    return nil
end

local function SyncPreviewSettings()
    if not next(previewSettings) then
        return
    end

    refreshingPreview = true
    for _, info in pairs(previewSettings) do
        local setting = info and info.setting
        if setting and setting.SetValue then
            pcall(setting.SetValue, setting, SelectionsEqual(previewSelection, info.selection), true)
        end
    end
    refreshingPreview = false
end

local function RepaintOptionsUI(notifyChanged)
    if next(proxySettings) then
        refreshing = true
        for _, info in pairs(proxySettings) do
            local setting = info and info.setting
            local readValue = info and info.readValue
            if setting and setting.SetValue and type(readValue) == "function" then
                local ok, value = pcall(readValue)
                if ok then
                    pcall(setting.SetValue, setting, value, true)
                end
            end
        end
        refreshing = false
    end

    SyncPreviewSettings()

    if notifyChanged == false then
        RefreshPreviewBorder()
        return
    end

    ns.NotifyChanged()
end

function ns.SetPreviewSelection(selection)
    previewSelection = selection
    RefreshPreviewBorder()
    SyncPreviewSettings()
end

function ns.GetPreviewSelection()
    return previewSelection
end

local function BuildDropdownOptionsFn(orderedKeys, labelMap)
    return function()
        local container = Settings.CreateControlTextContainer()
        for _, key in ipairs(orderedKeys) do
            container:Add(key, labelMap[key] or key)
        end
        return container:GetData()
    end
end

local function RegisterProxySetting(key, setting, readValue)
    proxySettings[key] = {
        setting = setting,
        readValue = readValue,
    }
    return setting
end

local function GetEQOLSourceDefaultField(source, field)
    if ns.eqol.GetSourceDefaultField then
        return ns.eqol.GetSourceDefaultField(source, field)
    end
    return ns.eqol.SOURCE_DEFAULTS[field]
end

local function MakeEQOLBooleanProxySetting(category, source, field, displayName)
    local setting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "eqol_" .. source .. "_" .. field,
        Settings.VarType.Boolean,
        displayName,
        GetEQOLSourceDefaultField(source, field),
        function()
            local cfg = ns.eqol.GetSourceConfig(source)
            return cfg and cfg[field] or GetEQOLSourceDefaultField(source, field)
        end,
        function(value)
            if refreshing then
                return
            end

            local ok, err = ns.eqol.TrySetSourceField(source, field, value and true or false)
            if not ok then
                local cfg = ns.eqol.GetSourceConfig(source) or {}
                ns.eqol.EmitWarning(source, cfg.target, "Rejected settings change", err)
                RepaintOptionsUI(false)
                return
            end

            ns.NotifyChanged()
        end
    )

    return RegisterProxySetting("eqol." .. source .. "." .. field, setting, function()
        local cfg = ns.eqol.GetSourceConfig(source)
        return cfg and cfg[field] or GetEQOLSourceDefaultField(source, field)
    end)
end

local function MakeEQOLStringProxySetting(category, source, field, displayName)
    local setting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "eqol_" .. source .. "_" .. field,
        Settings.VarType.String,
        displayName,
        GetEQOLSourceDefaultField(source, field),
        function()
            local cfg = ns.eqol.GetSourceConfig(source)
            return cfg and cfg[field] or GetEQOLSourceDefaultField(source, field)
        end,
        function(value)
            if refreshing then
                return
            end

            local ok, err = ns.eqol.TrySetSourceField(source, field, value)
            if not ok then
                local cfg = ns.eqol.GetSourceConfig(source) or {}
                ns.eqol.EmitWarning(source, cfg.target, "Rejected settings change", err)
                RepaintOptionsUI(false)
                return
            end

            ns.NotifyChanged()
        end
    )

    return RegisterProxySetting("eqol." .. source .. "." .. field, setting, function()
        local cfg = ns.eqol.GetSourceConfig(source)
        return cfg and cfg[field] or GetEQOLSourceDefaultField(source, field)
    end)
end

local function MakeEQOLNumberProxySetting(category, source, field, displayName)
    local setting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "eqol_" .. source .. "_" .. field,
        Settings.VarType.Number,
        displayName,
        GetEQOLSourceDefaultField(source, field),
        function()
            local cfg = ns.eqol.GetSourceConfig(source)
            return cfg and cfg[field] or GetEQOLSourceDefaultField(source, field)
        end,
        function(value)
            if refreshing then
                return
            end

            local ok, err = ns.eqol.TrySetSourceField(source, field, value)
            if not ok then
                local cfg = ns.eqol.GetSourceConfig(source) or {}
                ns.eqol.EmitWarning(source, cfg.target, "Rejected settings change", err)
                RepaintOptionsUI(false)
                return
            end

            ns.NotifyChanged()
        end
    )

    return RegisterProxySetting("eqol." .. source .. "." .. field, setting, function()
        local cfg = ns.eqol.GetSourceConfig(source)
        return cfg and cfg[field] or GetEQOLSourceDefaultField(source, field)
    end)
end

local function MakeCastBarStringProxySetting(category, field, displayName)
    local setting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "castbar_" .. field,
        Settings.VarType.String,
        displayName,
        ns.castbar.DEFAULTS[field],
        function()
            return ns.castbar.GetDB()[field]
        end,
        function(value)
            if refreshing then
                return
            end

            ns.castbar.GetDB()[field] = value
            ns.NotifyChanged()
        end
    )

    return RegisterProxySetting("castbar." .. field, setting, function()
        return ns.castbar.GetDB()[field]
    end)
end

local function MakeCastBarNumberProxySetting(category, field, displayName)
    local setting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "castbar_" .. field,
        Settings.VarType.Number,
        displayName,
        ns.castbar.DEFAULTS[field],
        function()
            return ns.castbar.GetDB()[field]
        end,
        function(value)
            if refreshing then
                return
            end

            ns.castbar.GetDB()[field] = value
            ns.NotifyChanged()
        end
    )

    return RegisterProxySetting("castbar." .. field, setting, function()
        return ns.castbar.GetDB()[field]
    end)
end

local function MakePreviewSetting(category, key, selection)
    local setting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "preview_" .. key,
        Settings.VarType.Boolean,
        "Preview target",
        false,
        function()
            return SelectionsEqual(previewSelection, selection)
        end,
        function(value)
            if refreshingPreview then
                return
            end

            if value then
                ns.SetPreviewSelection(CopySelection(selection))
            elseif SelectionsEqual(previewSelection, selection) then
                ns.SetPreviewSelection(nil)
            end
        end
    )

    previewSettings[key] = {
        setting = setting,
        selection = CopySelection(selection),
    }
    return setting
end

options.MakeEQOLBooleanProxySetting = MakeEQOLBooleanProxySetting
options.MakeEQOLStringProxySetting = MakeEQOLStringProxySetting
options.MakeEQOLNumberProxySetting = MakeEQOLNumberProxySetting
options.MakeCastBarStringProxySetting = MakeCastBarStringProxySetting
options.MakeCastBarNumberProxySetting = MakeCastBarNumberProxySetting

options.PrintError = PrintError
options.PrintSuccess = PrintSuccess
options.GetPopupEditBox = GetPopupEditBox
options.BuildDropdownOptionsFn = BuildDropdownOptionsFn
options.RegisterProxySetting = RegisterProxySetting
options.GetEQOLSourceDefaultField = GetEQOLSourceDefaultField
options.SelectionsEqual = SelectionsEqual
options.CopySelection = CopySelection
options.MakePreviewSetting = MakePreviewSetting

ns.categoryID = nil
ns.category = nil
ns.profileCategoryID = nil

function options.RegisterCategory(category, name, role)
    if not category or not Settings or not Settings.RegisterAddOnCategory then
        return
    end

    Settings.RegisterAddOnCategory(category)
    if role == "main" then
        ns.category = category
        ns.categoryID = category:GetID()
        options.mainCategoryID = ns.categoryID
        options.mainCategoryName = name
    elseif role == "profiles" then
        ns.profileCategoryID = category:GetID()
        options.profileCategoryID = ns.profileCategoryID
        options.profileCategoryName = name
    end
end

function ns.OpenSettings()
    if not Settings or not Settings.OpenToCategory then
        PrintError("Settings API not available in this client.")
        return
    end
    if not ns.categoryID then
        PrintError("Options panel not registered yet.")
        return
    end
    pcall(Settings.OpenToCategory, ns.categoryID)
end

function ns.RefreshUI()
    RepaintOptionsUI(true)
end

options.RefreshOptionsUI = RepaintOptionsUI

local coreNotify = ns.NotifyChanged
function ns.NotifyChanged()
    coreNotify()
    RefreshPreviewBorder()
end

function options.EnsureSettingsPanelHook()
    if SettingsPanel and not ns._settingsPanelHookInstalled then
        SettingsPanel:HookScript("OnHide", function(self)
            if self:IsShown() then
                return
            end
            if previewSelection then
                ns.SetPreviewSelection(nil)
            end
        end)
        ns._settingsPanelHookInstalled = true
    end
end

function options.CreateSettingsButtonInitializer(label, text, click, desc, searchable)
    if type(_G.CreateSettingsButtonInitializer) == "function" then
        return _G.CreateSettingsButtonInitializer(label, text, click, desc, searchable)
    end

    return Settings.CreateElementInitializer("SettingsButtonControlTemplate", {
        label = label,
        name = text,
        text = text,
        click = click,
        desc = desc,
        searchtags = searchable,
    })
end

function options.BuildOptionsPanels()
    if type(options.BuildAnchorsCategory) == "function" and not ns.categoryID then
        options.BuildAnchorsCategory()
    end
    if type(options.BuildProfilesCategory) == "function" and not ns.profileCategoryID then
        options.BuildProfilesCategory()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        ns.GetDB()
        options.BuildOptionsPanels()
    end
end)
