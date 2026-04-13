local ADDON_NAME, ns = ...
local options = ns.options or {}
ns.options = options

local function BuildActiveProfileSection(category, layout)
    layout:AddInitializer(Settings.CreateElementInitializer(
        "SettingsListSectionHeaderTemplate",
        { name = "Profile" }
    ))

    local setting = Settings.RegisterProxySetting(
        category,
        "EQOLAyijeAnchor_activeProfileDisplay",
        Settings.VarType.String,
        "Active profile",
        ns.profiles.GetActiveProfileName(),
        function()
            return ns.profiles.GetActiveProfileName()
        end,
        function() end
    )

    options.RegisterProxySetting("profile.activeDisplay", setting, function()
        return ns.profiles.GetActiveProfileName()
    end)

    Settings.CreateDropdown(
        category,
        setting,
        function()
            local container = Settings.CreateControlTextContainer()
            local profileName = ns.profiles.GetActiveProfileName()
            container:Add(profileName, profileName)
            return container:GetData()
        end,
        "The active profile currently being edited. Use the Profiles page to switch profiles."
    )
end

local function BuildEQOLSection(category, layout)
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

        local enabledSetting = options.MakeEQOLBooleanProxySetting(category, source, "enabled", "Enable override")
        Settings.CreateCheckbox(category, enabledSetting, "Enable companion anchoring for this EQOL frame.")

        local targetSetting = options.MakeEQOLStringProxySetting(category, source, "target", "Target frame")
        local eqolTargetOrder = ns.eqol.GetTargetOrderForSource and ns.eqol.GetTargetOrderForSource(source) or ns.eqol.TARGET_ORDER
        Settings.CreateDropdown(
            category,
            targetSetting,
            options.BuildDropdownOptionsFn(eqolTargetOrder, ns.eqol.TARGET_LABELS),
            "Frame to anchor this EQOL unit frame to."
        )

        local pointSetting = options.MakeEQOLStringProxySetting(category, source, "point", "Source point")
        Settings.CreateDropdown(
            category,
            pointSetting,
            options.BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
            "Anchor point on the EQOL source frame."
        )

        local relativePointSetting = options.MakeEQOLStringProxySetting(category, source, "relativePoint", "Target point")
        Settings.CreateDropdown(
            category,
            relativePointSetting,
            options.BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
            "Anchor point on the selected target frame."
        )

        local xSetting = options.MakeEQOLNumberProxySetting(category, source, "x", "X offset")
        do
            local sliderOptions = Settings.CreateSliderOptions(-3000, 3000, 1)
            sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
            Settings.CreateSlider(category, xSetting, sliderOptions, "Horizontal offset in pixels.")
        end

        local ySetting = options.MakeEQOLNumberProxySetting(category, source, "y", "Y offset")
        do
            local sliderOptions = Settings.CreateSliderOptions(-3000, 3000, 1)
            sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
            Settings.CreateSlider(category, ySetting, sliderOptions, "Vertical offset in pixels.")
        end

        local previewSetting = options.MakePreviewSetting(category, "eqol_" .. source, { kind = "eqol", source = source })
        Settings.CreateCheckbox(
            category,
            previewSetting,
            "Highlight the currently selected target frame for this source. Only one preview can be active at a time."
        )
    end
end

local function BuildCastBarSection(category, layout)
    layout:AddInitializer(Settings.CreateElementInitializer(
        "SettingsListSectionHeaderTemplate",
        { name = "Ayije Cast Bar" }
    ))

    local castbarTargetSetting = options.MakeCastBarStringProxySetting(category, "target", "Target frame")
    Settings.CreateDropdown(
        category,
        castbarTargetSetting,
        options.BuildDropdownOptionsFn(ns.castbar.TARGET_ORDER, {
            essential = "Essential CDM Frame",
            utility = "Utility CDM Frame",
            resources = "Resources frame (passthrough)",
            screen = "Screen (passthrough - Ayije controls)",
        }),
        "Frame to anchor the cast bar to. 'screen' and 'resources' fall through to Ayije's own positioning."
    )

    local castbarPointSetting = options.MakeCastBarStringProxySetting(category, "point", "Cast bar point")
    Settings.CreateDropdown(
        category,
        castbarPointSetting,
        options.BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
        "Anchor point on the cast bar itself."
    )

    local castbarRelativePointSetting = options.MakeCastBarStringProxySetting(category, "relativePoint", "Target point")
    Settings.CreateDropdown(
        category,
        castbarRelativePointSetting,
        options.BuildDropdownOptionsFn(ns.POINT_ORDER, ns.POINT_LABELS),
        "Anchor point on the selected target frame."
    )

    local castbarXSetting = options.MakeCastBarNumberProxySetting(category, "x", "X offset")
    do
        local sliderOptions = Settings.CreateSliderOptions(ns.castbar.OFFSET_MIN, ns.castbar.OFFSET_MAX, 1)
        sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, castbarXSetting, sliderOptions, "Horizontal offset in pixels.")
    end

    local castbarYSetting = options.MakeCastBarNumberProxySetting(category, "y", "Y offset")
    do
        local sliderOptions = Settings.CreateSliderOptions(ns.castbar.OFFSET_MIN, ns.castbar.OFFSET_MAX, 1)
        sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, castbarYSetting, sliderOptions, "Vertical offset in pixels.")
    end

    local castbarPreviewSetting = options.MakePreviewSetting(category, "castbar", { kind = "castbar" })
    Settings.CreateCheckbox(
        category,
        castbarPreviewSetting,
        "Highlight the currently selected target frame. Only one preview can be active at a time."
    )
end

local function BuildResetSection(category, layout)
    layout:AddInitializer(Settings.CreateElementInitializer(
        "SettingsListSectionHeaderTemplate",
        { name = "Profile Actions" }
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Reset EQOL anchors",
        function()
            local ok, err = ns.ResetEQOL()
            if not ok then
                options.PrintError("Reset EQOL anchors failed: " .. tostring(err))
            end
        end,
        "Restore EQOL source anchor overrides to defaults.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Reset cast bar anchor",
        function()
            local ok, err = ns.ResetCastBar()
            if not ok then
                options.PrintError("Reset cast bar anchor failed: " .. tostring(err))
            end
        end,
        "Restore cast bar anchoring to defaults.",
        false
    ))

    layout:AddInitializer(options.CreateSettingsButtonInitializer(
        "",
        "Reset all",
        function()
            local ok, err = ns.ResetAll()
            if not ok then
                options.PrintError("Reset all failed: " .. tostring(err))
            end
        end,
        "Restore EQOL and cast bar anchors to defaults.",
        false
    ))
end

function options.BuildAnchorsCategory()
    if ns.categoryID or not Settings or not Settings.RegisterVerticalLayoutCategory then
        return ns.category
    end

    local category, layout = Settings.RegisterVerticalLayoutCategory("EQOL Ayije Anchor")
    BuildActiveProfileSection(category, layout)
    BuildEQOLSection(category, layout)
    BuildCastBarSection(category, layout)
    BuildResetSection(category, layout)

    options.RegisterCategory(category, "EQOL Ayije Anchor", "main")
    options.EnsureSettingsPanelHook()
    return category
end
