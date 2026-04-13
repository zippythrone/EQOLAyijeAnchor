local ADDON_NAME, ns = ...
local options = ns.options or {}
ns.options = options

local SETTING_VAR_PREFIX = "EQOLAyijeAnchor_"
local selectedProfileName = nil

local PROFILE_CREATE_DIALOG = "EQOLAYIJEANCHOR_PROFILE_CREATE"
local PROFILE_RENAME_DIALOG = "EQOLAYIJEANCHOR_PROFILE_RENAME"
local PROFILE_DUPLICATE_DIALOG = "EQOLAYIJEANCHOR_PROFILE_DUPLICATE"
local PROFILE_DELETE_DIALOG = "EQOLAYIJEANCHOR_PROFILE_DELETE"
local PROFILE_EXPORT_DIALOG = "EQOLAYIJEANCHOR_PROFILE_EXPORT"
local PROFILE_IMPORT_DIALOG = "EQOLAYIJEANCHOR_PROFILE_IMPORT"

local function GetSelectedProfileName()
    local current = selectedProfileName
    if current and ns.profiles.GetProfile(current) then
        return current
    end

    selectedProfileName = ns.profiles.GetActiveProfileName()
    return selectedProfileName
end

local function SetSelectedProfileName(name, suppressRefresh)
    local profileName, err = ns.profiles.ValidateProfileName(name)
    if not profileName then
        return nil, err
    end
    if not ns.profiles.GetProfile(profileName) then
        return nil, "Unknown profile: " .. profileName
    end

    selectedProfileName = profileName
    if not suppressRefresh and options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

local function SyncSelectedProfileName(fallbackName)
    if fallbackName and ns.profiles.GetProfile(fallbackName) then
        selectedProfileName = fallbackName
        return selectedProfileName
    end

    selectedProfileName = ns.profiles.GetActiveProfileName()
    return selectedProfileName
end

local function BuildProfileDropdownOptions()
    local container = Settings.CreateControlTextContainer()
    for _, name in ipairs(ns.profiles.ListProfileNames()) do
        container:Add(name, name)
    end
    return container:GetData()
end

local function GetPopupText(popup)
    local eb = options.GetPopupEditBox and options.GetPopupEditBox(popup) or nil
    return eb
end

local function PrintActionError(prefix, err)
    options.PrintError(prefix .. ": " .. tostring(err))
end

local profileUI = {}

function profileUI.GetSelectedProfileName()
    return GetSelectedProfileName()
end

function profileUI.SetSelectedProfileName(name)
    return SetSelectedProfileName(name)
end

function profileUI.CreateProfile(name)
    local profileName, nameErr = ns.profiles.ValidateProfileName(name)
    if not profileName then
        return nil, nameErr
    end

    local ok, err = ns.profiles.CreateProfile(profileName)
    if not ok then
        return nil, err
    end

    selectedProfileName = profileName
    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.RenameSelectedProfile(newName)
    local profileName, nameErr = ns.profiles.ValidateProfileName(newName)
    if not profileName then
        return nil, nameErr
    end

    local sourceName = GetSelectedProfileName()
    local ok, err = ns.profiles.RenameProfile(sourceName, profileName)
    if not ok then
        return nil, err
    end

    selectedProfileName = profileName
    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.DuplicateSelectedProfile(newName)
    local profileName, nameErr = ns.profiles.ValidateProfileName(newName)
    if not profileName then
        return nil, nameErr
    end

    local sourceName = GetSelectedProfileName()
    local ok, err = ns.profiles.DuplicateProfile(sourceName, profileName)
    if not ok then
        return nil, err
    end

    selectedProfileName = profileName
    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.DeleteSelectedProfile()
    local sourceName = GetSelectedProfileName()
    local ok, err = ns.profiles.DeleteProfile(sourceName)
    if not ok then
        return nil, err
    end

    SyncSelectedProfileName()
    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.SwitchToSelectedProfile()
    local sourceName = GetSelectedProfileName()
    local ok, err = ns.profiles.SwitchProfile(sourceName)
    if not ok then
        return nil, err
    end

    selectedProfileName = ns.profiles.GetActiveProfileName()
    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.ExportSelectedProfile()
    local sourceName = GetSelectedProfileName()
    return ns.SerializeProfile(sourceName)
end

function profileUI.ImportIntoSelectedProfile(rawString)
    local targetName = GetSelectedProfileName()
    local ok, err = ns.ImportIntoProfile(targetName, rawString)
    if not ok then
        return nil, err
    end

    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

options.profileUI = profileUI
options.GetSelectedProfileName = GetSelectedProfileName
options.SetSelectedProfileName = SetSelectedProfileName

local function DefineTextPopup(key, title, buttonLabel, onAccept, onShow)
    StaticPopupDialogs[key] = {
        text = title,
        button1 = buttonLabel or OKAY,
        button2 = CANCEL,
        hasEditBox = true,
        editBoxWidth = 350,
        OnShow = function(self)
            local eb = GetPopupText(self)
            if not eb then
                return
            end
            if type(onShow) == "function" then
                onShow(self, eb)
            end
        end,
        EditBoxOnEscapePressed = function(self)
            self:GetParent():Hide()
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            if not parent then
                return
            end
            if onAccept(parent) then
                parent:Hide()
            end
        end,
        OnAccept = function(self)
            return not onAccept(self)
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end

local function DefineConfirmPopup(key, title, buttonLabel, onAccept)
    StaticPopupDialogs[key] = {
        text = title,
        button1 = buttonLabel or OKAY,
        button2 = CANCEL,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
        OnAccept = function(self)
            return not onAccept(self)
        end,
    }
end

DefineTextPopup(PROFILE_CREATE_DIALOG, "EQOL Ayije Anchor - Create profile", OKAY, function(popup)
    local eb = GetPopupText(popup)
    local input = (eb and eb:GetText()) or ""
    local ok, err = profileUI.CreateProfile(input)
    if not ok then
        PrintActionError("Create profile failed", err)
        return false
    end
    options.PrintSuccess("Created profile: " .. tostring(input))
    return true
end, function(_, eb)
    eb:SetText("")
    eb:SetFocus()
end)

DefineTextPopup(PROFILE_RENAME_DIALOG, "EQOL Ayije Anchor - Rename profile", OKAY, function(popup)
    local eb = GetPopupText(popup)
    local input = (eb and eb:GetText()) or ""
    local ok, err = profileUI.RenameSelectedProfile(input)
    if not ok then
        PrintActionError("Rename profile failed", err)
        return false
    end
    options.PrintSuccess("Renamed profile.")
    return true
end, function(_, eb)
    eb:SetText(GetSelectedProfileName())
    eb:HighlightText()
    eb:SetFocus()
end)

DefineTextPopup(PROFILE_DUPLICATE_DIALOG, "EQOL Ayije Anchor - Duplicate profile", OKAY, function(popup)
    local eb = GetPopupText(popup)
    local input = (eb and eb:GetText()) or ""
    local ok, err = profileUI.DuplicateSelectedProfile(input)
    if not ok then
        PrintActionError("Duplicate profile failed", err)
        return false
    end
    options.PrintSuccess("Duplicated profile to: " .. tostring(input))
    return true
end, function(_, eb)
    eb:SetText(GetSelectedProfileName() .. " Copy")
    eb:HighlightText()
    eb:SetFocus()
end)

DefineConfirmPopup(PROFILE_DELETE_DIALOG, "Delete the selected profile?", DELETE, function()
    local ok, err = profileUI.DeleteSelectedProfile()
    if not ok then
        PrintActionError("Delete profile failed", err)
        return false
    end
    options.PrintSuccess("Deleted profile.")
    return true
end)

DefineTextPopup(PROFILE_EXPORT_DIALOG, "EQOL Ayije Anchor - Export selected profile\n(Ctrl+C to copy, Esc to close)", OKAY, function()
    return true
end, function(popup, eb)
    local exported, err = profileUI.ExportSelectedProfile()
    if not exported then
        eb:SetText("")
        PrintActionError("Export failed", err)
        return
    end

    eb:SetText(exported)
    eb:HighlightText()
    eb:SetFocus()
end)

DefineTextPopup(PROFILE_IMPORT_DIALOG, "EQOL Ayije Anchor - Paste import string", "Import", function(popup)
    local eb = GetPopupText(popup)
    local input = (eb and eb:GetText()) or ""
    local ok, err = profileUI.ImportIntoSelectedProfile(input)
    if not ok then
        PrintActionError("Import failed", err)
        return false
    end
    options.PrintSuccess("Imported into selected profile.")
    return true
end, function(_, eb)
    eb:SetText("")
    eb:SetFocus()
end)

local function BuildProfileActions(category, layout)
    layout:AddInitializer(Settings.CreateElementInitializer(
        "SettingsListSectionHeaderTemplate",
        { name = "Profiles" }
    ))

    local selectedSetting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "selectedProfile",
        Settings.VarType.String,
        "Selected profile",
        GetSelectedProfileName(),
        function()
            return GetSelectedProfileName()
        end,
        function(value, initializing)
            local ok, err = SetSelectedProfileName(value, initializing)
            if not ok then
                PrintActionError("Select profile failed", err)
            end
        end
    )

    options.RegisterProxySetting("profile.selected", selectedSetting, function()
        return GetSelectedProfileName()
    end)

    Settings.CreateDropdown(
        category,
        selectedSetting,
        BuildProfileDropdownOptions,
        "Choose which saved profile the buttons below will operate on."
    )

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Switch active profile",
        function()
            local ok, err = profileUI.SwitchToSelectedProfile()
            if not ok then
                PrintActionError("Switch profile failed", err)
            end
        end,
        "Make the selected profile active immediately.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Create profile",
        function()
            StaticPopup_Show(PROFILE_CREATE_DIALOG)
        end,
        "Create a new profile by cloning the active profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Rename profile",
        function()
            StaticPopup_Show(PROFILE_RENAME_DIALOG)
        end,
        "Rename the selected profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Duplicate profile",
        function()
            StaticPopup_Show(PROFILE_DUPLICATE_DIALOG)
        end,
        "Duplicate the selected profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Delete profile",
        function()
            StaticPopup_Show(PROFILE_DELETE_DIALOG)
        end,
        "Delete the selected profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Export profile",
        function()
            StaticPopup_Show(PROFILE_EXPORT_DIALOG)
        end,
        "Export the selected profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Import into profile",
        function()
            StaticPopup_Show(PROFILE_IMPORT_DIALOG)
        end,
        "Replace the selected profile from an import string.",
        false
    ))
end

function options.BuildProfilesCategory()
    if ns.profileCategoryID or not Settings or not Settings.RegisterVerticalLayoutCategory then
        return ns.profileCategoryID
    end

    selectedProfileName = GetSelectedProfileName()

    local category, layout = Settings.RegisterVerticalLayoutCategory("EQOL Ayije Anchor - Profiles")
    BuildProfileActions(category, layout)

    options.RegisterCategory(category, "EQOL Ayije Anchor - Profiles", "profiles")
    return category
end
