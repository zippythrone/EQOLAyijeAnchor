local ADDON_NAME, ns = ...

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

local function ImportSettingsFromPopup(popup)
    local eb = GetPopupEditBox(popup)
    local input = (eb and eb:GetText()) or ""
    local parsed, err = ns.DeserializeSettings(input)
    if not parsed then
        PrintError("Import failed: " .. tostring(err))
        return false
    end

    local ok, applyErr = ns.ApplyParsedSettings(parsed)
    if not ok then
        PrintError("Import failed: " .. tostring(applyErr))
        return false
    end

    if ns.RefreshUI then
        ns.RefreshUI()
    end
    PrintSuccess("Imported settings.")
    return true
end

StaticPopupDialogs["EQOLAYIJEANCHOR_EXPORT"] = {
    text = "EQOL Ayije Anchor - Export string\n(Ctrl+C to copy, Esc to close)",
    button1 = OKAY,
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self)
        local eb = GetPopupEditBox(self)
        if not eb then
            return
        end

        local exported, err = ns.SerializeSettings()
        if not exported then
            eb:SetText("")
            PrintError("Export failed: " .. tostring(err))
            return
        end

        eb:SetText(exported)
        eb:HighlightText()
        eb:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnEnterPressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["EQOLAYIJEANCHOR_IMPORT"] = {
    text = "EQOL Ayije Anchor - Paste import string",
    button1 = "Import",
    button2 = CANCEL,
    hasEditBox = true,
    editBoxWidth = 350,
    OnShow = function(self)
        local eb = GetPopupEditBox(self)
        if not eb then
            return
        end
        eb:SetText("")
        eb:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        if not parent then
            return
        end
        if ImportSettingsFromPopup(parent) then
            parent:Hide()
        end
    end,
    OnAccept = function(self)
        return not ImportSettingsFromPopup(self)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

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

ns.categoryID = nil
ns.category = nil

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

local coreNotify = ns.NotifyChanged
function ns.NotifyChanged()
    coreNotify()
    RefreshPreviewBorder()
end

local function BuildPanel()
    if not Settings or not Settings.RegisterVerticalLayoutCategory then
        return
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("EQOL Ayije Anchor")
    ns.category = category

    layout:AddInitializer(Settings.CreateElementInitializer(
        "SettingsListSectionHeaderTemplate",
        { name = "EQOL Frames" }
    ))

    for _, source in ipairs(ns.eqol.SOURCE_ORDER) do
        local sourceLabel = ns.eqol.SOURCE_LABELS[source] or source

        layout:AddInitializer(Settings.CreateElementInitializer(
            "SettingsListSectionHeaderTemplate",
            { name = sourceLabel }
        ))

        local enabledSetting = MakeEQOLBooleanProxySetting(category, source, "enabled", "Enable override")
        Settings.CreateCheckbox(
            category,
            enabledSetting,
            "Enable companion anchoring for this EQOL frame."
        )

        local targetSetting = MakeEQOLStringProxySetting(category, source, "target", "Target frame")
        local eqolTargetOrder = ns.eqol.GetTargetOrderForSource and ns.eqol.GetTargetOrderForSource(source) or ns.eqol.TARGET_ORDER
        Settings.CreateDropdown(
            category,
            targetSetting,
            BuildDropdownOptionsFn(eqolTargetOrder, ns.eqol.TARGET_LABELS),
            "Frame to anchor this EQOL unit frame to."
        )

        local pointSetting = MakeEQOLStringProxySetting(category, source, "point", "Source point")
        Settings.CreateDropdown(
            category,
            pointSetting,
            BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
            "Anchor point on the EQOL source frame."
        )

        local relativePointSetting = MakeEQOLStringProxySetting(category, source, "relativePoint", "Target point")
        Settings.CreateDropdown(
            category,
            relativePointSetting,
            BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
            "Anchor point on the selected target frame."
        )

        local xSetting = MakeEQOLNumberProxySetting(category, source, "x", "X offset")
        do
            local options = Settings.CreateSliderOptions(-3000, 3000, 1)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
            Settings.CreateSlider(category, xSetting, options, "Horizontal offset in pixels.")
        end

        local ySetting = MakeEQOLNumberProxySetting(category, source, "y", "Y offset")
        do
            local options = Settings.CreateSliderOptions(-3000, 3000, 1)
            options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
            Settings.CreateSlider(category, ySetting, options, "Vertical offset in pixels.")
        end

        local previewSetting = MakePreviewSetting(category, "eqol_" .. source, { kind = "eqol", source = source })
        Settings.CreateCheckbox(
            category,
            previewSetting,
            "Highlight the currently selected target frame for this source. Only one preview can be active at a time."
        )
    end

    layout:AddInitializer(Settings.CreateElementInitializer(
        "SettingsListSectionHeaderTemplate",
        { name = "Ayije Cast Bar" }
    ))

    local castbarTargetSetting = MakeCastBarStringProxySetting(category, "target", "Target frame")
    Settings.CreateDropdown(
        category,
        castbarTargetSetting,
        BuildDropdownOptionsFn(ns.castbar.TARGET_ORDER, CASTBAR_TARGET_LABELS),
        "Frame to anchor the cast bar to. 'screen' and 'resources' fall through to Ayije's own positioning."
    )

    local castbarPointSetting = MakeCastBarStringProxySetting(category, "point", "Cast bar point")
    Settings.CreateDropdown(
        category,
        castbarPointSetting,
        BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
        "Anchor point on the cast bar itself."
    )

    local castbarRelativePointSetting = MakeCastBarStringProxySetting(category, "relativePoint", "Target point")
    Settings.CreateDropdown(
        category,
        castbarRelativePointSetting,
        BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
        "Anchor point on the selected target frame."
    )

    local castbarXSetting = MakeCastBarNumberProxySetting(category, "x", "X offset")
    do
        local options = Settings.CreateSliderOptions(ns.castbar.OFFSET_MIN, ns.castbar.OFFSET_MAX, 1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, castbarXSetting, options, "Horizontal offset in pixels.")
    end

    local castbarYSetting = MakeCastBarNumberProxySetting(category, "y", "Y offset")
    do
        local options = Settings.CreateSliderOptions(ns.castbar.OFFSET_MIN, ns.castbar.OFFSET_MAX, 1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, castbarYSetting, options, "Vertical offset in pixels.")
    end

    local castbarPreviewSetting = MakePreviewSetting(category, "castbar", { kind = "castbar" })
    Settings.CreateCheckbox(
        category,
        castbarPreviewSetting,
        "Highlight the currently selected target frame. Only one preview can be active at a time."
    )

    layout:AddInitializer(Settings.CreateElementInitializer(
        "SettingsListSectionHeaderTemplate",
        { name = "Profile" }
    ))

    do
        local function OnResetEQOL()
            local ok, err = ns.ResetEQOL()
            if not ok then
                PrintError("Reset EQOL anchors failed: " .. tostring(err))
                return
            end
            ns.RefreshUI()
        end
        layout:AddInitializer(CreateSettingsButtonInitializer(
            "",
            "Reset EQOL anchors",
            OnResetEQOL,
            "Restore EQOL source anchor overrides to defaults.",
            false
        ))
    end

    do
        local function OnResetCastBar()
            local ok, err = ns.ResetCastBar()
            if not ok then
                PrintError("Reset cast bar anchor failed: " .. tostring(err))
                return
            end
            ns.RefreshUI()
        end
        layout:AddInitializer(CreateSettingsButtonInitializer(
            "",
            "Reset cast bar anchor",
            OnResetCastBar,
            "Restore cast bar anchoring to defaults.",
            false
        ))
    end

    do
        local function OnResetAll()
            local ok, err = ns.ResetAll()
            if not ok then
                PrintError("Reset all failed: " .. tostring(err))
                return
            end
            ns.RefreshUI()
        end
        layout:AddInitializer(CreateSettingsButtonInitializer(
            "",
            "Reset all",
            OnResetAll,
            "Restore EQOL and cast bar anchors to defaults.",
            false
        ))
    end

    do
        local function OnExport()
            StaticPopup_Show("EQOLAYIJEANCHOR_EXPORT")
        end
        layout:AddInitializer(CreateSettingsButtonInitializer(
            "",
            "Export",
            OnExport,
            "Open a popup with the current EQOL Ayije Anchor profile.",
            false
        ))
    end

    do
        local function OnImport()
            StaticPopup_Show("EQOLAYIJEANCHOR_IMPORT")
        end
        layout:AddInitializer(CreateSettingsButtonInitializer(
            "",
            "Import",
            OnImport,
            "Open a popup to paste an exported EQOL Ayije Anchor profile.",
            false
        ))
    end

    Settings.RegisterAddOnCategory(category)
    ns.categoryID = category:GetID()

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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        ns.GetDB()
        BuildPanel()
    end
end)
