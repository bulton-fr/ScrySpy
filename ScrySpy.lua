local LMP = LibMapPins
local GPS = LibGPS3
local Lib3D = Lib3D
local CCP = COMPASS_PINS
local LAM = LibAddonMenu2


---------------------------------------
----- Lib3D Vars                  -----
---------------------------------------



---------------------------------------
----- ScrySpy Vars                -----
---------------------------------------

ScrySpy_SavedVars = ScrySpy_SavedVars or { }
ScrySpy_SavedVars.version = ScrySpy_SavedVars.version or 1 -- This is not the addon version number
ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
ScrySpy_SavedVars.pin_level = ScrySpy_SavedVars.pin_level or ScrySpy.scryspy_defaults.pin_level
ScrySpy_SavedVars.pin_size = ScrySpy_SavedVars.pin_size or ScrySpy.scryspy_defaults.pin_size
ScrySpy_SavedVars.digsite_pin_size = ScrySpy_SavedVars.digsite_pin_size or ScrySpy.scryspy_defaults.digsite_pin_size
ScrySpy_SavedVars.pin_type = ScrySpy_SavedVars.pin_type or ScrySpy.scryspy_defaults.pin_type
ScrySpy_SavedVars.digsite_pin_type = ScrySpy_SavedVars.digsite_pin_type or ScrySpy.scryspy_defaults.digsite_pin_type
ScrySpy_SavedVars.compass_max_distance = ScrySpy_SavedVars.compass_max_distance or ScrySpy.scryspy_defaults.compass_max_distance
ScrySpy_SavedVars.custom_compass_pin = ScrySpy_SavedVars.custom_compass_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.custom_compass_pin]
ScrySpy_SavedVars.scryspy_map_pin = ScrySpy_SavedVars.scryspy_map_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.scryspy_map_pin]
ScrySpy_SavedVars.dig_site_pin = ScrySpy_SavedVars.dig_site_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.dig_site_pin]
ScrySpy_SavedVars.digsite_spike_color = ScrySpy_SavedVars.digsite_spike_color or ScrySpy.scryspy_defaults.digsite_spike_color

-- Existing Local
local PIN_TYPE = "pinType_Digsite" -- This is changed by LAM now, use ScrySpy.scryspy_map_pin
local PIN_FILTER_NAME = "ScrySpy"
local PIN_NAME = "Dig Location"
local PIN_PRIORITY_OFFSET = 1

-- ScrySpy
dig_site_names = {
    ["en"] = "Dig Site",
    ["fr"] = "site de fouilles",
    ["de"] = "Ausgrabungsstätte",
    ["ru"] = "Место раскопок",
}

loc_index = {
    x_pos  = 1,
    y_pos  = 2,
    x_gps  = 3,
    y_gps  = 4,
    worldX = 5,
    worldY = 6,
    worldZ = 7,
}

local function is_in(search_value, search_table)
    for k, v in pairs(search_table) do
        if search_value == v then return true end
        if type(search_value) == "string" then
            if string.find(string.lower(v), string.lower(search_value)) then return true end
        end
    end
    return false
end

-- Function to check for empty table
local function is_empty_or_nil(t)
    if not t then return true end
    if type(t) == "table" then
        if next(t) == nil then
            return true
        else
            return false
        end
    elseif type(t) == "string" then
        if t == nil then
            return true
        elseif t == "" then
            return true
        else
            return false
        end
    elseif type(t) == "nil" then
        return true
    end
end

local function get_digsite_locations(zone)
    --d(zone)
    if is_empty_or_nil(ScrySpy.dig_sites[zone]) then
        return {}
    else
        return ScrySpy.dig_sites[zone]
    end
end

---------------------------------------
----- ScrySpy                     -----
---------------------------------------
ScrySpy.worldControlPool = ZO_ControlPool:New("ScrySpy_WorldPin", ScrySpy_WorldPins)
ScrySpy.antiquity_dig_sites = {}
ScrySpy.scrying_antiquities = false

local function get_digsite_loc_sv(zone)
    --d(zone)
    if is_empty_or_nil(ScrySpy_SavedVars.location_info[zone]) then
        return {}
    else
        return ScrySpy_SavedVars.location_info[zone]
    end
end

local function save_to_sv(locations_table, location)
    --[[
    This should be the table not the Zone like Skyrim or
    the ZoneID

    example ScrySpy.dig_sites[zone_id][zone] where zone might be
    ["skyrim/westernskryim_base_0"] and zone_id is 1160
    ]]--
    local save_location = true
    for num_entry, digsite_loc in ipairs(locations_table) do
        local distance = zo_round(GPS:GetLocalDistanceInMeters(digsite_loc[loc_index.x_pos], digsite_loc[loc_index.y_pos], location[loc_index.x_pos], location[loc_index.y_pos]))
        --d(distance)
        if distance <= 10 then
            --d("less then 10 to close to me")
            return false
        else
            --d("more then 10, far away, save it")
        end
    end
    return save_location
end

local function save_dig_site_location()
    --d("save_dig_site_location")
    local x_pos, y_pos = GetMapPlayerPosition("player")
    local x_gps, y_gps = GPS:LocalToGlobal(x_pos, y_pos)
    local zone_id, worldX, worldY, worldZ = GetUnitWorldPosition("player")

    local zone = LMP:GetZoneAndSubzone(true, false, true)
    -- if ScrySpy_SavedVars.location_info == nil then ScrySpy_SavedVars.location_info = {} end
    -- not needed, because it's already created above
    ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
    ScrySpy_SavedVars.location_info[zone] = ScrySpy_SavedVars.location_info[zone] or { }

    if ScrySpy.dig_sites == nil then ScrySpy.dig_sites = {} end
    if ScrySpy.dig_sites[zone] == nil then ScrySpy.dig_sites[zone] = {} end

    local dig_sites_table = get_digsite_locations(zone)
    if is_empty_or_nil(dig_sites_table) then dig_sites_table = {} end

    local dig_sites_sv_table = get_digsite_loc_sv(zone)
    if is_empty_or_nil(dig_sites_sv_table) then dig_sites_sv_table = {} end

    local location = {
        [loc_index.x_pos] = x_pos,
        [loc_index.y_pos] = y_pos,
        [loc_index.x_gps] = x_gps,
        [loc_index.y_gps] = y_gps,
        [loc_index.worldX] = worldX,
        [loc_index.worldY] = worldY,
        [loc_index.worldZ] = worldZ,
    }
    if save_to_sv(dig_sites_table, location) and save_to_sv(dig_sites_sv_table, location) then
        --d("saving location")
        table.insert(ScrySpy_SavedVars.location_info[zone], location)
        LMP:RefreshPins(ScrySpy.scryspy_map_pin)
        CCP:RefreshPins(ScrySpy.custom_compass_pin)
        ScrySpy.Draw3DPins()
    end
end

function ScrySpy.RefreshPinFilters()
    LMP:SetEnabled(ScrySpy.scryspy_map_pin, ScrySpy_SavedVars.scryspy_map_pin)
end

function ScrySpy.RefreshPinLayout()
    LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "size", ScrySpy_SavedVars.pin_size)
    LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "level", ScrySpy_SavedVars.pin_level+PIN_PRIORITY_OFFSET)
    LMP:SetLayoutKey(ScrySpy.scryspy_map_pin, "texture", ScrySpy.pin_textures[ScrySpy_SavedVars.pin_type])
    LMP:RefreshPins(ScrySpy.scryspy_map_pin)
end


---------------------------------------
----- Lib3D                       -----
---------------------------------------

function ScrySpy.Hide3DPins()
    -- remove the on update handler and hide the ScrySpy.dig_site_pin
    EVENT_MANAGER:UnregisterForUpdate("DigSite")
    ScrySpy_WorldPins:SetHidden(true)
    ScrySpy.worldControlPool:ReleaseAllObjects()
end

function ScrySpy.Draw3DPins()
    EVENT_MANAGER:UnregisterForUpdate("DigSite")

    local zone = LMP:GetZoneAndSubzone(true, false, true)

    local mapData = ScrySpy.get_pin_data(zone) or { }
    -- pseudo_pin_location
    if mapData then
        local worldX, worldZ, worldY = WorldPositionToGuiRender3DPosition(0,0,0)
        if not worldX then return end
        ScrySpy_WorldPins:Set3DRenderSpaceOrigin(worldX, worldZ, worldY)
        ScrySpy_WorldPins:SetHidden(false)

        for pin, pinData in ipairs(mapData) do
            local pinControl = ScrySpy.worldControlPool:AcquireObject(pin)
            if not pinControl:Has3DRenderSpace() then
                pinControl:Create3DRenderSpace()
            end

            local size = 1
            local iconControl = pinControl:GetNamedChild("Icon")
            if not iconControl:Has3DRenderSpace() then
                iconControl:Create3DRenderSpace()
                iconControl:Set3DRenderSpaceUsesDepthBuffer(true)
            end
            iconControl:SetTexture(ScrySpy.pin_textures[ScrySpy_SavedVars.digsite_pin_type])
            iconControl:Set3DRenderSpaceOrigin(pinData[loc_index.worldX]/100, (pinData[loc_index.worldY]/100) + 2.5, pinData[loc_index.worldZ]/100)
            iconControl:Set3DLocalDimensions(0.30 * size + 0.6, 0.30 * size + 0.6)

            local spikeControl = pinControl:GetNamedChild("Spike")
            if not spikeControl:Has3DRenderSpace() then
                spikeControl:Create3DRenderSpace()
                spikeControl:Set3DRenderSpaceUsesDepthBuffer(true)
            end
            spikeControl:SetColor(ScrySpy.unpack_color_table(ScrySpy_SavedVars.digsite_spike_color))
            spikeControl:Set3DRenderSpaceOrigin(pinData[loc_index.worldX]/100, (pinData[loc_index.worldY]/100) + 1.0, pinData[loc_index.worldZ]/100)
            spikeControl:Set3DLocalDimensions(0.25 * size + 0.75, 0.75 * size + 1.25)
        end

        local activeObjects = ScrySpy.worldControlPool:GetActiveObjects()

        -- don't do that every single frame. it's not necessary
        EVENT_MANAGER:RegisterForUpdate("DigSite", 100, function()
            local x, y, z, forwardX, forwardY, forwardZ, rightX, rightY, rightZ, upX, upY, upZ = Lib3D:GetCameraRenderSpace()
            for key, pinControl in pairs(activeObjects) do
                for i = 1, pinControl:GetNumChildren() do
                    local textureControl = pinControl:GetChild(i)
                    textureControl:Set3DRenderSpaceForward(forwardX, forwardY, forwardZ)
                    textureControl:Set3DRenderSpaceRight(rightX, rightY, rightZ)
                    textureControl:Set3DRenderSpaceUp(upX, upY, upZ)
                end
            end
        end)
    end
end

local function OnInteract(event_code, client_interact_result, interact_target_name)
    --d(event_code)
    --d(client_interact_result)
    local text = zo_strformat(SI_CHAT_MESSAGE_FORMATTER, interact_target_name)
    --d(text)
    --d("OnInteract")
    if text == dig_site_names[ScrySpy.client_lang] then
        save_dig_site_location()
    end
end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name,EVENT_CLIENT_INTERACT_RESULT, OnInteract)

function ScrySpy.combine_data(zone)
    ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
    ScrySpy_SavedVars.location_info[zone] = ScrySpy_SavedVars.location_info[zone] or { }

    ScrySpy.dig_sites[zone] = ScrySpy.dig_sites[zone] or { }

    local mapData = ScrySpy.dig_sites[zone] or { }
    local dig_sites_sv_table = get_digsite_loc_sv(zone) or { }
    for num_entry, digsite_loc in ipairs(dig_sites_sv_table) do
        if save_to_sv(mapData, digsite_loc) then
            table.insert(mapData, digsite_loc)
        end
    end
    return mapData
end

function ScrySpy.get_pin_data(zone)
    local function digsite_in_range(location)
        for key, compas_pin_loc in pairs(ScrySpy.antiquity_dig_sites) do
            local distance = zo_round(GPS:GetLocalDistanceInMeters(compas_pin_loc.x, compas_pin_loc.y, location[loc_index.x_pos], location[loc_index.y_pos]))
            if distance <= ScrySpy.antiquity_dig_sites[key].size then
                return true
            end
        end
        return false
    end

    local function in_mod_digsite_pool(main_table, location)
        for _, compas_pin_loc in pairs(main_table) do
            local distance = zo_round(GPS:GetLocalDistanceInMeters(compas_pin_loc[loc_index.x_pos], compas_pin_loc[loc_index.y_pos], location[loc_index.x_pos], location[loc_index.y_pos]))
            if distance <= 10 then
                return true
            end
        end
        return false
    end

    ScrySpy_SavedVars.location_info = ScrySpy_SavedVars.location_info or { }
    ScrySpy_SavedVars.location_info[zone] = ScrySpy_SavedVars.location_info[zone] or { }

    ScrySpy.dig_sites[zone] = ScrySpy.dig_sites[zone] or { }

    -- this is the end result if within range
    local mod_digsite_pool = { }

    for num_entry, digsite_loc in ipairs(ScrySpy.dig_sites[zone]) do
        if digsite_in_range(digsite_loc) then
            table.insert(mod_digsite_pool, digsite_loc)
        end
    end

    local dig_sites_sv_table = get_digsite_loc_sv(zone) or { }
    for num_entry, digsite_loc in ipairs(dig_sites_sv_table) do
        if digsite_in_range(digsite_loc) and not in_mod_digsite_pool(mod_digsite_pool, digsite_loc) then
            table.insert(mod_digsite_pool, digsite_loc)
        end
    end

    --mod_digsite_pool = ScrySpy.combine_data(zone)
    return mod_digsite_pool
end

local function InitializePins()
    local function MapPinAddCallback(pinType)
        local zone = LMP:GetZoneAndSubzone(true, false, true)
        --[[
        Problem encountered. When standing in the ["skyrim/solitudeoutlawsrefuge_0"]

        The Zone ID for that map is 1178 and the mapname is ["skyrim/solitudeoutlawsrefuge_0"]

        If you have the map open and change maps, then the map might be ["craglorn/craglorn_base_0"]
        but the player, where they are currently standing is still 1178.

        meaning the game will look for 1178 and ["craglorn/craglorn_base_0"] which is invalid
        ]]--
        --d(zone)
        local mapData = ScrySpy.get_pin_data(zone) or { }
        if mapData then
            for index, pinData in pairs(mapData) do
                LMP:CreatePin(ScrySpy.scryspy_map_pin, pinData, pinData[loc_index.x_pos], pinData[loc_index.y_pos])
            end
        end
    end

    local function PinTypeAddCallback(pinType)
        if GetMapType() <= MAPTYPE_ZONE and LMP:IsEnabled(pinType) then
            MapPinAddCallback(pinType)
        end
    end

    local lmp_pin_layout =
    {
        level = ScrySpy_SavedVars.pin_level,
        texture = ScrySpy.pin_textures[ScrySpy_SavedVars.pin_type],
        size = ScrySpy_SavedVars.pin_size,
    }

    local pinlayout_compass = {
        maxDistance = 0.05,
        texture = ScrySpy.pin_textures[ScrySpy_SavedVars.custom_compass_pin],
        sizeCallback = function(pin, angle, normalizedAngle, normalizedDistance)
            if zo_abs(normalizedAngle) > 0.25 then
                pin:SetDimensions(54 - 24 * zo_abs(normalizedAngle), 54 - 24 * zo_abs(normalizedAngle))
            else
                pin:SetDimensions(48, 48)
            end
        end,
    }

    local function compass_callback()
        if GetMapType() <= MAPTYPE_ZONE and ScrySpy_SavedVars.custom_compass_pin then
            local zone = LMP:GetZoneAndSubzone(true, false, true)
            local mapData = ScrySpy.get_pin_data(zone) or { }
            if mapData then
                for _, pinData in ipairs(mapData) do
                    CCP.pinManager:CreatePin(ScrySpy.custom_compass_pin, pinData, pinData[loc_index.x_pos], pinData[loc_index.y_pos])
                end
            end
        end
    end

    local pinTooltipCreator = {
        creator = function(pin)
            if IsInGamepadPreferredMode() then
                local InformationTooltip = ZO_MapLocationTooltip_Gamepad
                local baseSection = InformationTooltip.tooltip
                InformationTooltip:LayoutIconStringLine(baseSection, nil, ScrySpy.addon_name, baseSection:GetStyle("mapLocationTooltipContentHeader"))
                InformationTooltip:LayoutIconStringLine(baseSection, nil, PIN_NAME, baseSection:GetStyle("mapLocationTooltipContentName"))
            else
                SetTooltipText(InformationTooltip, PIN_NAME)
            end
        end
    }

    LMP:AddPinType(ScrySpy.scryspy_map_pin, function() PinTypeAddCallback(ScrySpy.scryspy_map_pin) end, nil, lmp_pin_layout, pinTooltipCreator)
    ScrySpy.RefreshPinFilters()
    CCP:AddCustomPin(ScrySpy.custom_compass_pin, compass_callback, pinlayout_compass)
    CCP:RefreshPins(ScrySpy.custom_compass_pin)
end

local function build_zone_data()
    local zone = LMP:GetZoneAndSubzone(true, false, true)
    if ScrySpy_SavedVars.data_store == nil then ScrySpy_SavedVars.data_store = {} end
    ScrySpy_SavedVars.data_store[zone] = ScrySpy.combine_data(zone)
end

local function reset_zone_data()
    ScrySpy_SavedVars.data_store = {}
end

local function OnPlayerActivated(eventCode)
    InitializePins()
    ScrySpy.RefreshPinLayout()
    CCP.pinLayouts[ScrySpy.custom_compass_pin].texture = ScrySpy.pin_textures[ScrySpy_SavedVars.pin_type]
    CCP:RefreshPins(ScrySpy.custom_compass_pin)
    ScrySpy.update_antiquity_dig_sites()
    ScrySpy.Draw3DPins()
    EVENT_MANAGER:UnregisterForEvent(ScrySpy.addon_name.."_InitPins", EVENT_PLAYER_ACTIVATED)
end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name.."_InitPins", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)

function ScrySpy.update_active_dig_sites()
    if #ScrySpy.antiquity_dig_sites >=1 then
        ScrySpy.scrying_antiquities = true
        -- also enable compas pins
        ScrySpy_SavedVars.custom_compass_pin = true
        -- also enable map pins
        ScrySpy_SavedVars.scryspy_map_pin = true
    else
        ScrySpy.scrying_antiquities = false
        -- also disable compas pins
        ScrySpy_SavedVars.custom_compass_pin = false
        -- also disable map pins
        ScrySpy_SavedVars.scryspy_map_pin = false
        -- release all the world objects
        ScrySpy.worldControlPool:ReleaseAllObjects()
    end

    InitializePins()

    if ScrySpy.scrying_antiquities then
        ScrySpy.Draw3DPins()
    else
        ScrySpy.Hide3DPins()
    end
end

-- MAP_PIN_TYPE_TRACKED_ANTIQUITY_DIG_SITE = 42
function ScrySpy.update_antiquity_dig_sites()
    local map_pin_keys = LMP.pinManager.m_keyToPinMapping["antiquityDigSite"]
    local polygon_information = LMP.pinManager["m_Active"]

    ScrySpy.antiquity_dig_sites = {}

    for _, polygon_location in pairs(map_pin_keys) do
        for _, pin_information in pairs(polygon_location) do
            local temp_compas_pin_location = {}
            temp_compas_pin_location.x = polygon_information[pin_information]["normalizedX"]
            temp_compas_pin_location.y = polygon_information[pin_information]["normalizedY"]
            blob_key = polygon_information[pin_information]["polygonBlobKey"]
            local my_control = WINDOW_MANAGER:GetControlByName("ZO_PinPolygonBlob", blob_key)
            temp_compas_pin_location.size = zo_round(math.max(my_control:GetDimensions())) + 50
            ScrySpy.antiquity_dig_sites[blob_key] = temp_compas_pin_location
        end
    end
    ScrySpy.update_active_dig_sites()
end

local function OnTrackingUpdate(eventCode)
    --d("OnTrackingUpdate")
    ScrySpy.update_antiquity_dig_sites()
    --d(ScrySpy.antiquity_dig_sites)
    --d(ScrySpy.scrying_antiquities)
    --d("OnTrackingUpdate end")
end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name.."_DigSiteLocations", EVENT_ANTIQUITY_TRACKING_UPDATE, OnTrackingUpdate)

local function OnRevealAntiquity(eventCode)
    --d("OnRevealAntiquity")
    ScrySpy.update_antiquity_dig_sites()
    --d(ScrySpy.antiquity_dig_sites)
    --d(ScrySpy.scrying_antiquities)
    --d("OnRevealAntiquity end")
end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name.."_DigSiteLocations", EVENT_REVEAL_ANTIQUITY_DIG_SITES_ON_MAP, OnRevealAntiquity)

local function OnLoad(eventCode, addOnName)
    -- turn the top level control into a 3d control
    ScrySpy_WorldPins:Create3DRenderSpace()

    -- make sure the control is only shown, when the player can see the world
    -- i.e. the control is only shown during non-menu scenes
    local fragment = ZO_SimpleSceneFragment:New(ScrySpy_WorldPins)
    HUD_UI_SCENE:AddFragment(fragment)
    HUD_SCENE:AddFragment(fragment)
    LOOT_SCENE:AddFragment(fragment)

    -- register a callback, so we know when to start/stop displaying the ScrySpy.dig_site_pin
    Lib3D:RegisterWorldChangeCallback("DigSite", function(identifier, zoneIndex, isValidZone, newZone)
        if not newZone then return end

        if ScrySpy.scrying_antiquities then
            ScrySpy.Draw3DPins()
        else
            ScrySpy.Hide3DPins()
        end
    end)

    if ScrySpy_SavedVars.version ~= 4 then
        local temp_locations
        if ScrySpy_SavedVars.version == nil then ScrySpy_SavedVars.version = 1 end
        if ScrySpy_SavedVars.version >= 2 then
            if ScrySpy_SavedVars.location_info then
                temp_locations = ScrySpy_SavedVars.location_info
            end
        end
        ScrySpy_SavedVars = { }
        ScrySpy_SavedVars.version = 4
        ScrySpy_SavedVars.location_info = temp_locations or { }
        ScrySpy_SavedVars.pin_level = ScrySpy_SavedVars.pin_level or ScrySpy.scryspy_defaults.pin_level
        ScrySpy_SavedVars.pin_size = ScrySpy_SavedVars.pin_size or ScrySpy.scryspy_defaults.pin_size
        ScrySpy_SavedVars.digsite_pin_size = ScrySpy_SavedVars.digsite_pin_size or ScrySpy.scryspy_defaults.digsite_pin_size
        ScrySpy_SavedVars.pin_type = ScrySpy_SavedVars.pin_type or ScrySpy.scryspy_defaults.pin_type
        ScrySpy_SavedVars.digsite_pin_type = ScrySpy_SavedVars.digsite_pin_type or ScrySpy.scryspy_defaults.digsite_pin_type
        ScrySpy_SavedVars.compass_max_distance = ScrySpy_SavedVars.compass_max_distance or ScrySpy.scryspy_defaults.compass_max_distance
        ScrySpy_SavedVars.custom_compass_pin = ScrySpy_SavedVars.custom_compass_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.custom_compass_pin]
        ScrySpy_SavedVars.scryspy_map_pin = ScrySpy_SavedVars.scryspy_map_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.scryspy_map_pin]
        ScrySpy_SavedVars.dig_site_pin = ScrySpy_SavedVars.dig_site_pin or ScrySpy.scryspy_defaults.filters[ScrySpy.dig_site_pin]
        if ScrySpy_SavedVars.version >= 4 then
            ScrySpy_SavedVars.digsite_spike_color = ScrySpy_SavedVars.digsite_spike_color or ScrySpy.scryspy_defaults.digsite_spike_color
        else
            ScrySpy_SavedVars.digsite_spike_color = ScrySpy.scryspy_defaults.digsite_spike_color
        end
        ScrySpy.RefreshPinFilters()
        ScrySpy.RefreshPinLayout()
        LMP:RefreshPins(ScrySpy.scryspy_map_pin)
    end
    ScrySpy.update_antiquity_dig_sites()

    --SLASH_COMMANDS["/ssreset"] = function() reset_zone_data() end

    --SLASH_COMMANDS["/ssbuild"] = function() build_zone_data() end

    SLASH_COMMANDS["/ssrefresh"] = function() ScrySpy.update_antiquity_dig_sites() end


end
EVENT_MANAGER:RegisterForEvent(ScrySpy.addon_name, EVENT_ADD_ON_LOADED, OnLoad)
