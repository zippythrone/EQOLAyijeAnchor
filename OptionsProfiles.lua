local ADDON_NAME, ns = ...
local options = ns.options or {}
ns.options = options

local SETTING_VAR_PREFIX = "EQOLAyijeAnchor_"

local PROFILE_CREATE_DIALOG = "EQOLAYIJEANCHOR_PROFILE_CREATE"
local PROFILE_RENAME_DIALOG = "EQOLAYIJEANCHOR_PROFILE_RENAME"
local PROFILE_DUPLICATE_DIALOG = "EQOLAYIJEANCHOR_PROFILE_DUPLICATE"
local PROFILE_DELETE_DIALOG = "EQOLAYIJEANCHOR_PROFILE_DELETE"
local PROFILE_EXPORT_DIALOG = "EQOLAYIJEANCHOR_PROFILE_EXPORT"
local PROFILE_IMPORT_DIALOG = "EQOLAYIJEANCHOR_PROFILE_IMPORT"

local function GetActiveProfileName()
    return ns.profiles.GetActiveProfileName()
end

local function SwitchActiveProfile(name)
    local profileName, err = ns.profiles.ValidateProfileName(name)
    if not profileName then
        return nil, err
    end

    local ok, switchErr = ns.profiles.SwitchProfile(profileName)
    if not ok then
        return nil, switchErr
    end

    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
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

function profileUI.CreateProfile(name)
    local profileName, nameErr = ns.profiles.ValidateProfileName(name)
    if not profileName then
        return nil, nameErr
    end

    local ok, err = ns.profiles.CreateProfile(profileName, GetActiveProfileName())
    if not ok then
        return nil, err
    end

    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.RenameActiveProfile(newName)
    local profileName, nameErr = ns.profiles.ValidateProfileName(newName)
    if not profileName then
        return nil, nameErr
    end

    local ok, err = ns.profiles.RenameProfile(GetActiveProfileName(), profileName)
    if not ok then
        return nil, err
    end

    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.DuplicateActiveProfile(newName)
    local profileName, nameErr = ns.profiles.ValidateProfileName(newName)
    if not profileName then
        return nil, nameErr
    end

    local ok, err = ns.profiles.DuplicateProfile(GetActiveProfileName(), profileName)
    if not ok then
        return nil, err
    end

    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.DeleteActiveProfile()
    local ok, err = ns.profiles.DeleteProfile(GetActiveProfileName())
    if not ok then
        return nil, err
    end

    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

function profileUI.ExportActiveProfile()
    return ns.SerializeProfile(GetActiveProfileName())
end

function profileUI.ImportIntoActiveProfile(rawString)
    local ok, err = ns.ImportIntoProfile(GetActiveProfileName(), rawString)
    if not ok then
        return nil, err
    end

    if options.RefreshOptionsUI then
        options.RefreshOptionsUI(false)
    end
    return true
end

options.profileUI = profileUI

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
    local ok, err = profileUI.RenameActiveProfile(input)
    if not ok then
        PrintActionError("Rename profile failed", err)
        return false
    end
    options.PrintSuccess("Renamed profile.")
    return true
end, function(_, eb)
    eb:SetText(GetActiveProfileName())
    eb:HighlightText()
    eb:SetFocus()
end)

DefineTextPopup(PROFILE_DUPLICATE_DIALOG, "EQOL Ayije Anchor - Duplicate profile", OKAY, function(popup)
    local eb = GetPopupText(popup)
    local input = (eb and eb:GetText()) or ""
    local ok, err = profileUI.DuplicateActiveProfile(input)
    if not ok then
        PrintActionError("Duplicate profile failed", err)
        return false
    end
    options.PrintSuccess("Duplicated profile to: " .. tostring(input))
    return true
end, function(_, eb)
    eb:SetText(GetActiveProfileName() .. " Copy")
    eb:HighlightText()
    eb:SetFocus()
end)

DefineConfirmPopup(PROFILE_DELETE_DIALOG, "Delete the active profile?", DELETE, function()
    local ok, err = profileUI.DeleteActiveProfile()
    if not ok then
        PrintActionError("Delete profile failed", err)
        return false
    end
    options.PrintSuccess("Deleted profile.")
    return true
end)

DefineTextPopup(PROFILE_EXPORT_DIALOG, "EQOL Ayije Anchor - Export active profile\n(Ctrl+C to copy, Esc to close)", OKAY, function()
    return true
end, function(popup, eb)
    local exported, err = profileUI.ExportActiveProfile()
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
    local ok, err = profileUI.ImportIntoActiveProfile(input)
    if not ok then
        PrintActionError("Import failed", err)
        return false
    end
    options.PrintSuccess("Imported into active profile.")
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

    local activeSetting = Settings.RegisterProxySetting(
        category,
        SETTING_VAR_PREFIX .. "profileActiveProfile",
        Settings.VarType.String,
        "Active profile",
        GetActiveProfileName(),
        function()
            return GetActiveProfileName()
        end,
        function(value, initializing)
            if initializing then
                return
            end
            local ok, err = SwitchActiveProfile(value)
            if not ok then
                PrintActionError("Switch profile failed", err)
            end
        end
    )

    options.RegisterProxySetting("profile.active", activeSetting, function()
        return GetActiveProfileName()
    end)

    Settings.CreateDropdown(
        category,
        activeSetting,
        BuildProfileDropdownOptions,
        "Choose the profile the addon should use right now."
    )

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
        "Rename active profile",
        function()
            StaticPopup_Show(PROFILE_RENAME_DIALOG)
        end,
        "Rename the active profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Duplicate active profile",
        function()
            StaticPopup_Show(PROFILE_DUPLICATE_DIALOG)
        end,
        "Duplicate the active profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Delete active profile",
        function()
            StaticPopup_Show(PROFILE_DELETE_DIALOG)
        end,
        "Delete the active profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Export active profile",
        function()
            StaticPopup_Show(PROFILE_EXPORT_DIALOG)
        end,
        "Export the active profile.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Import into active profile",
        function()
            StaticPopup_Show(PROFILE_IMPORT_DIALOG)
        end,
        "Replace the active profile from an import string.",
        false
    ))
end

function options.BuildProfilesCategory()
    if ns.profileCategoryID or not Settings or not Settings.RegisterVerticalLayoutSubcategory then
        return ns.profileCategoryID
    end

    local root = options.BuildRootCategory()
    if not root then
        return ns.profileCategoryID
    end

    local category, layout = Settings.RegisterVerticalLayoutSubcategory(root, "Profiles")
    BuildProfileActions(category, layout)

    options.RegisterSubcategory(category, "Profiles", "profiles")
    return category
end
