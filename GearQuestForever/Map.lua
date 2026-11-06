local _, GQ = ...

GQ.Map = GQ.Map or {}

local PREFIX = "|cff66ccffGearQuest|r: "
local zoneCache = {}

local ZONE_MAP = Enum and Enum.UIMapType and Enum.UIMapType.Zone or 3

-- English zone name -> uiMapID from the hunt coordinates (spot.map with
-- spot.mapId), built once on first use.
local dataMapIds

-- Continents the data names (entry.zone, a few spots) that neither table
-- covers. UiMap.db2 of WoW Forever 1.60.1.70790 (wago.tools): 1414 Kalimdor,
-- 1415 Eastern Kingdoms, Type 2 = Continent. The only other rows with these
-- names are their Taxi-system twins 1464/1463, which the name scan reaches
-- later and picks only if they score higher.
local CONTINENT_MAP_IDS = {
    ["Kalimdor"] = 1414,
    ["Eastern Kingdoms"] = 1415,
}

local function MapAcceptsWorld(mapId)
    if not (mapId and C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then
        return true
    end
    local ok, continent, world = pcall(C_Map.GetWorldPosFromMapPos, mapId, CreateVector2D(0.5, 0.5))
    return ok and continent and world and true or false
end

-- One pass over every spot (about 65,000), so it reads plain fields only.
-- The id most spots of a zone carry wins; a tie takes the lower id.
local function BuildDataMapIds(rows)
    local counts = {}
    for _, row in pairs(rows) do
        local spots = row.spots
        if spots then
            for i = 1, #spots do
                local spot = spots[i]
                local id = spot.mapId
                local name = id and spot.map
                if name then
                    local byId = counts[name]
                    if not byId then
                        byId = {}
                        counts[name] = byId
                    end
                    byId[id] = (byId[id] or 0) + 1
                end
            end
        end
    end
    local ids = {}
    for name, byId in pairs(counts) do
        local best, bestCount
        for id, n in pairs(byId) do
            if not bestCount or n > bestCount or (n == bestCount and id < best) then
                best, bestCount = id, n
            end
        end
        ids[name] = best
    end
    return ids
end

local function DataMapId(zoneName)
    if not dataMapIds then
        local rows = GQ.Data and GQ.Data.coordinates
        if type(rows) ~= "table" then
            return nil
        end
        -- Malformed data leaves the table empty; the name scan still runs.
        local ok, ids = pcall(BuildDataMapIds, rows)
        dataMapIds = ok and ids or {}
    end
    return dataMapIds[zoneName]
end

-- The first id with this name is often a duplicate that cannot take a world
-- position. Prefer the outdoor zone, and one the guide can measure yards on.
-- The client names maps in its own language, so this only finds an English
-- name on an English client (or a map the client leaves untranslated).
local function ScanMapNames(zoneName)
    local found = false
    local bestScore = -1
    if C_Map and C_Map.GetMapInfo then
        for id = 1, 3000 do
            local info = C_Map.GetMapInfo(id)
            if info and info.name == zoneName then
                local score = info.mapType == ZONE_MAP and 100 or 10
                if MapAcceptsWorld(id) then
                    score = score + 50
                end
                if score > bestScore then
                    bestScore = score
                    found = id
                end
            end
        end
    end
    return found
end

-- English data name (spot.map, entry.zone, place.zone) -> the client's
-- uiMapID, by id tables first: GQ.L10N's zone ids, the continents, then the
-- pairs in the coordinate data. The name scan is the last resort.
local function FindMapId(zoneName)
    if type(zoneName) ~= "string" or zoneName == "" then
        return nil
    end
    if zoneCache[zoneName] ~= nil then
        return zoneCache[zoneName] or nil
    end
    local L10N = GQ.L10N
    local found = (L10N and L10N.ZoneMapId and L10N.ZoneMapId(zoneName))
        or CONTINENT_MAP_IDS[zoneName]
        or DataMapId(zoneName)
        or ScanMapNames(zoneName)
        or false
    zoneCache[zoneName] = found
    return found or nil
end

-- Display only: the client's name for an English zone name from the data
-- (GQ.L10N), or the name unchanged. Never feed the result back to ZoneMap.
local function ZoneText(name)
    local L10N = GQ.L10N
    if type(name) == "string" and name ~= "" and L10N and L10N.ZoneName then
        return L10N.ZoneName(name)
    end
    return name
end

-- TomTom title and chat text for an entry. entry.questName/npc/zone stay
-- English; quest and zone names are shown as the client names them. NPC
-- names have no ids and stay as stored.
local function DisplayLabel(entry)
    local quest = entry.questName
    if quest then
        local L10N = GQ.L10N
        if type(quest) == "string" and quest ~= "" and L10N and L10N.QuestName then
            return L10N.QuestName(quest)
        end
        return quest
    end
    if entry.npc then
        return entry.npc
    end
    if entry.zone then
        return ZoneText(entry.zone)
    end
    return "GearQuest"
end

function GQ.Map:ZoneMap(zoneName)
    return FindMapId(zoneName)
end

function GQ.Map:KindFor(entry)
    local src = entry and entry.sourceType or ""
    if GQ.NormalizeSourceType then
        src = GQ:NormalizeSourceType(src) or src
    end
    return src
end

-- Faction-matching coordinate, before the zone name is turned into a map id.
function GQ.Map:DisplaySpot(entry)
    if not entry or not entry.itemId or not GQ.Data or not GQ.Data.coordinates then
        return nil
    end
    if GQ.Data.NearestCoordinateSpot then
        return GQ.Data:NearestCoordinateSpot(entry.itemId)
    end
    local row = GQ.Data.coordinates[entry.itemId]
    if not row or not row.spots or #row.spots == 0 then
        return nil
    end
    local faction = GQ.GetEffectiveFaction and GQ:GetEffectiveFaction() or nil
    local openWorld = GQ.Data.PinIgnoresFactionZone and GQ.Data:PinIgnoresFactionZone(row)
    for i = 1, #row.spots do
        local spot = row.spots[i]
        if spot.x and spot.y and GQ.Data:SpotVisible(spot, faction, openWorld) then
            return spot
        end
    end
    return nil
end

function GQ.Map:HasSpot(entry)
    return self:DisplaySpot(entry) ~= nil
end

-- The same spot the coordinate line shows for this faction. One pin.
function GQ.Map:SpotForEntry(entry)
    local spot = self:DisplaySpot(entry)
    if not spot then
        return nil
    end
    -- The client's map id for this zone name. A stored id can be a Wowhead
    -- id the world map does not use, and then the pin never lands.
    local mapId = self:ZoneMap(spot.map) or spot.mapId
    if not mapId then
        return nil
    end
    return {
        mapId = mapId,
        x = spot.x,
        y = spot.y,
        map = spot.map,
        kind = self:KindFor(entry),
        entry = entry,
    }
end

-- Shift-click on a user waypoint inserts the pin in chat, then copies a
-- /mappin command with CopyToClipboard. That copy is reserved for Blizzard
-- UI. A pin placed from this addon runs the click tainted, so the copy pops
-- "blocked from an action only available to the Blizzard UI" after the chat
-- link is already in. Skip the clipboard step; chat share stays.
local function SkipWaypointClipboard()
end

local function GuardWaypointClipboard()
    -- The gamepad UI closes the map through a protected focus clear. Do not
    -- touch WorldMapFrame.pinPools or a live pin: writing an addon function
    -- onto one taints that hide. Mouse mode only skips the clipboard copy.
    if GQ.UsesGamepad and GQ:UsesGamepad() then
        return
    end
    if type(WaypointLocationPinMixin) == "table"
        and type(WaypointLocationPinMixin.CopySlashCommandToClipboard) == "function"
        and WaypointLocationPinMixin.CopySlashCommandToClipboard ~= SkipWaypointClipboard
    then
        WaypointLocationPinMixin.CopySlashCommandToClipboard = SkipWaypointClipboard
    end
end

local clipboardGuard = CreateFrame("Frame")
clipboardGuard:RegisterEvent("ADDON_LOADED")
clipboardGuard:RegisterEvent("PLAYER_LOGIN")
clipboardGuard:SetScript("OnEvent", function()
    GuardWaypointClipboard()
end)

local function OpenToMap(mapId)
    GuardWaypointClipboard()
    if mapId and C_Map and C_Map.OpenWorldMap then
        C_Map.OpenWorldMap(mapId)
        return
    end
    if mapId and OpenWorldMap then
        OpenWorldMap(mapId)
        return
    end
    if WorldMapFrame and not WorldMapFrame:IsShown() and ToggleWorldMap then
        ToggleWorldMap()
    end
end

local function SetPin(mapId, x, y, label)
    x, y = x / 100, y / 100
    if TomTom and TomTom.AddWaypoint then
        TomTom:AddWaypoint(mapId, x, y, { title = "GearQuest: " .. label })
        return true
    end
    if C_Map.SetUserWaypoint and UiMapPoint and C_Map.CanSetUserWaypointOnMap and C_Map.CanSetUserWaypointOnMap(mapId) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapId, x, y))
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        return true
    end
    return false
end

function GQ.Map:Show(entry)
    if not entry then
        return
    end
    if GQ.Guide and GQ.Guide.ShowEntry then
        GQ.Guide:ShowEntry(entry)
    end
    local spot = self:SpotForEntry(entry)
    -- ZoneMap gets the English entry.zone; label is display text only.
    local mapId = spot and spot.mapId or self:ZoneMap(entry.zone)
    local label = DisplayLabel(entry)

    OpenToMap(mapId)

    if not spot then
        GQ:Chat(PREFIX .. "Для этого предмета нет точного места.")
        return
    end

    local pinned = SetPin(spot.mapId, spot.x, spot.y, label)
    GuardWaypointClipboard()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, GuardWaypointClipboard)
    end
    local where = string.format("%s %.1f, %.1f", ZoneText(spot.map) or label, spot.x, spot.y)
    GQ:Chat(PREFIX .. where .. (pinned and " — метка установлена" or ""))
end
