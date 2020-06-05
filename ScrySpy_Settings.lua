local CCP = COMPASS_PINS
local LMP = LibMapPins
local LAM = LibAddonMenu2

local pin_textures_list = {
    [1] = "Pickaxe-Shovel Red-X (Default)",
    [2] = "Pickaxe-Shovel",
}

local panelData = {
    type = "panel",
    name = GetString(mod_title),
    displayName = "|cFFFFB0" .. GetString(mod_title) .. "|r",
    author = "Sharlikran",
    version = ScrySpy.addon_version,
    slashCommand = "/scryspy",
    registerForRefresh = true,
    registerForDefaults = true,
    website = ScrySpy.addon_website,
}

local create_icons, shovel_icon, digsite_icon
local function create_icons(panel)
    if panel == WINDOW_MANAGER:GetControlByName(ScrySpy.addon_name, "_Options") then
        shovel_icon = WINDOW_MANAGER:CreateControl(nil, panel.controlsToRefresh[1], CT_TEXTURE)
        shovel_icon:SetAnchor(RIGHT, panel.controlsToRefresh[1].combobox, LEFT, -10, 0)
        shovel_icon:SetTexture(ScrySpy.pin_textures[ScrySpy_SavedVars.pin_type])
        shovel_icon:SetDimensions(ScrySpy_SavedVars.digsite_pin_size, ScrySpy_SavedVars.digsite_pin_size)
        digsite_icon = WINDOW_MANAGER:CreateControl(nil, panel.controlsToRefresh[2], CT_TEXTURE)
        digsite_icon:SetAnchor(RIGHT, panel.controlsToRefresh[2].combobox, LEFT, -10, 0)
        digsite_icon:SetTexture(ScrySpy.pin_textures[ScrySpy_SavedVars.digsite_pin_type])
        digsite_icon:SetDimensions(ScrySpy_SavedVars.digsite_pin_size, ScrySpy_SavedVars.digsite_pin_size)
        CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated", create_icons)
    end
end
CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", create_icons)

local optionsTable = {
    -- Set Map Pin and Compas Pin texture
    {
        type = "dropdown",
        name = GetString(map_pin_texture_text),
        tooltip = GetString(map_pin_texture_desc),
        choices = pin_textures_list,
        getFunc = function() return pin_textures_list[ScrySpy_SavedVars.pin_type] end,
        setFunc = function(selected)
                for index, name in ipairs(pin_textures_list) do
                    if name == selected then
                        ScrySpy.scryspy_defaults.pin_type = index
                        ScrySpy_SavedVars.pin_type = ScrySpy.scryspy_defaults.pin_type
                        LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "texture", ScrySpy.pin_textures[index])
                        shovel_icon:SetTexture(ScrySpy.pin_textures[index])
                        ScrySpy.RefreshPinLayout()
                        CCP.pinLayouts[ScrySpy.custom_compass_pin].texture = ScrySpy.pin_textures[index]
                        CCP:RefreshPins(ScrySpy.custom_compass_pin)
                        break
                    end
                end
            end,
        disabled = function() return not ScrySpy_SavedVars.scryspy_map_pin end,
        default = pin_textures_list[ScrySpy.scryspy_defaults.pin_type],
    },
    -- 3D Digsite Icon Texture
    {
        type = "dropdown",
        name = GetString(digsite_texture_text),
        tooltip = GetString(digsite_texture_desc),
        choices = pin_textures_list,
        getFunc = function() return pin_textures_list[ScrySpy_SavedVars.digsite_pin_type] end,
        setFunc = function(selected)
                for index, name in ipairs(pin_textures_list) do
                    if name == selected then
                        ScrySpy.scryspy_defaults.digsite_pin_type = index
                        ScrySpy_SavedVars.digsite_pin_type = ScrySpy.scryspy_defaults.digsite_pin_type
                        digsite_icon:SetTexture(ScrySpy.pin_textures[index])
                        ScrySpy.Draw3DPins() -- this makes the pins appear when the are normally hidden
                        break
                    end
                end
            end,
        disabled = function() return not ScrySpy.scryspy_defaults.filters[ScrySpy.dig_site_pin] end,
        default = pin_textures_list[ScrySpy.scryspy_defaults.digsite_pin_type],
    },
    -- Set Map Pin pin size
    {
        type = "slider",
        name = GetString(pin_size),
        tooltip = GetString(pin_size_desc),
        min = 20,
        max = 70,
        getFunc = function() return ScrySpy_SavedVars.pin_size end,
        setFunc = function(size)
                ScrySpy.scryspy_defaults.pin_size = size
                ScrySpy_SavedVars.pin_size = ScrySpy.scryspy_defaults.pin_size
                shovel_icon:SetDimensions(size, size)
                LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "size", size)
                ScrySpy.RefreshPinLayout()
            end,
        disabled = function() return not ScrySpy_SavedVars.scryspy_map_pin end,
        default = ScrySpy.scryspy_defaults.pin_size,
    },
    -- Set Map Pin pin level meaning what takes precedence over other pins
    {
        type = "slider",
        name = GetString(pin_layer),
        tooltip = GetString(pin_layer_desc),
        min = 10,
        max = 200,
        step = 5,
        getFunc = function() return ScrySpy_SavedVars.pin_level end,
        setFunc = function(level)
                ScrySpy.scryspy_defaults.pin_level = level
                ScrySpy_SavedVars.pin_level = ScrySpy.scryspy_defaults.pin_level
                LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "level", level)
                ScrySpy.RefreshPinLayout()
            end,
        disabled = function() return not ScrySpy_SavedVars.scryspy_map_pin end,
        default = ScrySpy.scryspy_defaults.pin_level,
    },
    -- Toggle showing digsites on compass
    {
        type = "checkbox",
        name = GetString(show_digsites_on_compas),
        tooltip = GetString(show_digsites_on_compas_desc),
        getFunc = function() return ScrySpy_SavedVars.custom_compass_pin end,
        setFunc = function(state)
                ScrySpy.scryspy_defaults.filters[ScrySpy.custom_compass_pin] = state
                ScrySpy_SavedVars.custom_compass_pin = ScrySpy.scryspy_defaults.filters[ScrySpy.custom_compass_pin]
                CCP:RefreshPins(ScrySpy.custom_compass_pin)
            end,
        default = ScrySpy.scryspy_defaults.filters[ScrySpy.custom_compass_pin],
    },
    -- Set the max distance for compas pins to show up
    {
        type = "slider",
        name = GetString(compass_max_dist),
        tooltip = GetString(compass_max_dist_desc),
        min = 1,
        max = 100,
        getFunc = function() return ScrySpy_SavedVars.compass_max_distance * 1000 end,
        setFunc = function(maxDistance)
                ScrySpy.scryspy_defaults.compass_max_distance = maxDistance / 1000
                ScrySpy_SavedVars.compass_max_distance = ScrySpy.scryspy_defaults.compass_max_distance
                CCP.pinLayouts[ScrySpy.custom_compass_pin].maxDistance = maxDistance / 1000
                CCP:RefreshPins(ScrySpy.custom_compass_pin)
            end,
        width = "full",
        disabled = function() return not ScrySpy_SavedVars.custom_compass_pin end,
        default = ScrySpy.scryspy_defaults.compass_max_distance * 1000,
    },
    -- Set color for the 3D Map Pin Spike
    {
        type = "colorpicker",
        name = GetString(spike_pincolor),
        tooltip = GetString(spike_pincolor_desc),
        getFunc = function() return unpack(ScrySpy_SavedVars.digsite_spike_color) end,
        setFunc = function(...)
            ScrySpy.digsite_spike_color:SetRGBA(...)
            ScrySpy.scryspy_defaults.digsite_spike_color = { ScrySpy.digsite_spike_color:UnpackRGBA() }
            ScrySpy_SavedVars.digsite_spike_color = ScrySpy.scryspy_defaults.digsite_spike_color
            ScrySpy.Draw3DPins()
        end,
        default = ScrySpy.scryspy_defaults.digsite_spike_color,
    },
}

local function OnPlayerActivated(event)
    LAM:RegisterAddonPanel(ScrySpy.addon_name.."_Options", panelData)
    LAM:RegisterOptionControls(ScrySpy.addon_name.."_Options", optionsTable)
    EVENT_MANAGER:UnregisterForEvent(ScrySpy.addon_name.."_Options", EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name.."_Options", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)