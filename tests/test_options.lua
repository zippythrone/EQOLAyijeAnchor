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
ctx.load("Serialization.lua")
ctx.load("Options.lua")
ctx.load("OptionsAnchors.lua")
ctx.load("OptionsProfiles.lua")

ctx.ns.options.BuildOptionsPanels()

local settingsState = assert(_G.Settings._state, "expected settings state to be available")

local function findCategory(name)
    for _, category in ipairs(settingsState.categories) do
        if category.name == name then
            return category
        end
    end
    return nil
end

assert(#settingsState.rootCategories == 1, "expected exactly one root settings category")
local root = assert(findCategory("EQOL Ayije Anchor"), "expected root category to exist")
local anchors = assert(findCategory("Anchors"), "expected Anchors subcategory to exist")
local profiles = assert(findCategory("Profiles"), "expected Profiles subcategory to exist")

assert(root.parent == nil, "expected root category to have no parent")
assert(root.kind == "canvas", "expected root category to use canvas registration")
assert(root.name == "EQOL Ayije Anchor", "expected root category name to match")
assert(#root.subcategories == 2, "expected root category to have two child subcategories")
assert(anchors.parent == root, "expected Anchors to be a child of the root category")
assert(profiles.parent == root, "expected Profiles to be a child of the root category")
assert(#settingsState.addOnCategories == 1, "expected exactly one addon category registration")
assert(settingsState.addOnCategories[1] == root, "expected the root category to be the registered addon category")

local function findControl(category, kind, key)
    for _, control in ipairs(category.controls or {}) do
        local setting = control.setting
        if control.kind == kind and setting and setting.GetVariable and setting:GetVariable() == key then
            return control
        end
    end
    return nil
end

local function findButton(category, text)
    for _, initializer in ipairs(category.initializers or {}) do
        if initializer.template == "SettingsButtonControlTemplate" and initializer.text == text then
            return initializer
        end
    end
    return nil
end

local function submitPopup(dialogKey, text)
    local popup = assert(StaticPopup_Show(dialogKey), "expected popup to be shown: " .. dialogKey)
    if text ~= nil then
        popup.EditBox:SetText(text)
    end
    popup:SubmitText()
    return popup
end

local function acceptPopup(dialogKey)
    local popup = assert(StaticPopup_Show(dialogKey), "expected popup to be shown: " .. dialogKey)
    popup:Accept()
    return popup
end

ctx.ns.OpenSettings()
assert(settingsState.openedCategoryID == ctx.ns.categoryID, "expected /eaya to open Anchors")
assert(settingsState.openedCategoryID ~= ctx.ns.profileCategoryID, "expected /eaya not to open the profiles page")

local activeProfileControl = assert(
    findControl(anchors, "dropdown", "EQOLAyijeAnchor_activeProfileDisplay"),
    "expected active profile display control to exist"
)
assert(activeProfileControl.setting:GetValue() == "Default", "expected Default to be the initial active profile")

local profileDropdown = assert(
    findControl(profiles, "dropdown", "EQOLAyijeAnchor_profileActiveProfile"),
    "expected active profile dropdown to exist"
)
assert(findButton(profiles, "Switch active profile") == nil, "expected switch active profile button to be absent")
assert(findButton(profiles, "Import into active profile") ~= nil, "expected import into active profile button to exist")
assert(StaticPopupDialogs["EQOLAYIJEANCHOR_PROFILE_EXPORT"].text:match("Export active profile"), "expected export popup copy to mention the active profile")

submitPopup("EQOLAYIJEANCHOR_PROFILE_CREATE", "Arena")
submitPopup("EQOLAYIJEANCHOR_PROFILE_CREATE", "Imported")

local profileOptions = profileDropdown:GetOptions()
assert(profileOptions["Arena"], "expected Arena to appear in the active-profile dropdown")
assert(profileOptions["Imported"], "expected Imported to appear in the active-profile dropdown")

profileDropdown.setting:SetValue("Arena")
assert(ctx.ns.profiles.GetActiveProfileName() == "Arena", "expected dropdown changes to switch the active profile immediately")
assert(activeProfileControl.setting:GetValue() == "Arena", "expected active profile display to track the active profile")

local importedProfile = assert(ctx.ns.profiles.GetProfile("Imported"))
importedProfile.eqol.sources.player.enabled = false
importedProfile.castbar.target = "screen"
importedProfile.castbar.x = -7

local arenaProfile = assert(ctx.ns.profiles.GetProfile("Arena"))
arenaProfile.eqol.sources.player.enabled = true
arenaProfile.castbar.target = "utility"
arenaProfile.castbar.x = 42

local exportPopup = assert(StaticPopup_Show("EQOLAYIJEANCHOR_PROFILE_EXPORT"), "expected export popup to be shown")
local exported = exportPopup.EditBox:GetText()
assert(exported:match("^EQAYA"), "expected active-profile export to use the addon export prefix")

arenaProfile.eqol.sources.player.enabled = false
arenaProfile.castbar.target = "essential"
arenaProfile.castbar.x = 99

submitPopup("EQOLAYIJEANCHOR_PROFILE_IMPORT", exported)
assert(ctx.ns.profiles.GetActiveProfileName() == "Arena", "expected import into active profile to keep Arena active")
arenaProfile = assert(ctx.ns.profiles.GetProfile("Arena"))
assert(arenaProfile.eqol.sources.player.enabled == true, "expected active profile EQOL data to be restored")
assert(arenaProfile.castbar.target == "utility", "expected active profile castbar target to be restored")
assert(arenaProfile.castbar.x == 42, "expected active profile castbar offset to be restored")
importedProfile = assert(ctx.ns.profiles.GetProfile("Imported"))
assert(importedProfile.castbar.x == -7, "expected inactive profile data to remain untouched")
assert(importedProfile.eqol.sources.player.enabled == false, "expected inactive profile EQOL data to remain untouched")

submitPopup("EQOLAYIJEANCHOR_PROFILE_CREATE", "ArenaClone")
assert(ctx.ns.profiles.GetActiveProfileName() == "Arena", "expected create profile not to switch the active profile")
assert(profileDropdown.setting:GetValue() == "Arena", "expected dropdown to stay on the current active profile after create")
local arenaClone = assert(ctx.ns.profiles.GetProfile("ArenaClone"))
assert(arenaClone.castbar.x == 42, "expected create profile to clone the active profile")

submitPopup("EQOLAYIJEANCHOR_PROFILE_DUPLICATE", "ArenaCopy")
assert(ctx.ns.profiles.GetActiveProfileName() == "Arena", "expected duplicate profile not to switch the active profile")
assert(ctx.ns.profiles.GetProfile("ArenaCopy") ~= nil, "expected duplicate profile to exist")

submitPopup("EQOLAYIJEANCHOR_PROFILE_RENAME", "ArenaRenamed")
assert(ctx.ns.profiles.GetActiveProfileName() == "ArenaRenamed", "expected rename to update the active profile name")
assert(profileDropdown.setting:GetValue() == "ArenaRenamed", "expected dropdown to refresh after rename")
assert(ctx.ns.profiles.GetProfile("Arena") == nil, "expected old active profile name to be removed after rename")
assert(ctx.ns.profiles.GetProfile("ArenaCopy") ~= nil, "expected duplicate profile to remain after renaming the active profile")
assert(ctx.ns.profiles.GetProfile("ArenaRenamed") ~= nil, "expected renamed profile to exist")

acceptPopup("EQOLAYIJEANCHOR_PROFILE_DELETE")
assert(ctx.ns.profiles.GetProfile("ArenaRenamed") == nil, "expected deleted active profile to be removed")
assert(profileDropdown.setting:GetValue() == ctx.ns.profiles.GetActiveProfileName(), "expected dropdown to follow the fallback active profile after delete")
