local ADDON_NAME, GQ = ...

if not strtrim then
    function strtrim(s)
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end
end

GQ = GQ or {}
_G.GearQuest = GQ

GQ.VERSION = "1.0.7"
GQ.ADDON_NAME = ADDON_NAME

-- General -> Hide chat messages. Off until the player checks it.
function GQ:Chat(...)
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    if settings and settings.hideChat then
        return
    end
    _G.print(...)
end

-- Russian plural form: GQ.Plural(5, "цель", "цели", "целей") -> "целей".
function GQ.Plural(n, one, few, many)
    n = math.abs(math.floor(tonumber(n) or 0))
    local n100 = n % 100
    local n10 = n % 10
    if n100 >= 11 and n100 <= 14 then
        return many
    end
    if n10 == 1 then
        return one
    end
    if n10 >= 2 and n10 <= 4 then
        return few
    end
    return many
end

-- Russian UI text needs Cyrillic glyphs. Blizzard's font families already use
-- the _CYR files on the Russian client (Blizzard_Fonts_Shared/Shared/Fonts.xml:
-- QuestFont_Huge -> Fonts\MORPHEUS_CYR.TTF, system fonts -> Fonts\FRIZQT___CYR.TTF).
-- A font string only loses them when SetFont gets a plain Latin file, so such a
-- file is swapped for its Cyrillic twin of the same face; a _CYR file stays.
local CYR_FONT_FILE = "Fonts\\FRIZQT___CYR.TTF"
local CYR_TWIN = {
    ["fonts\\frizqt__.ttf"] = CYR_FONT_FILE,
    ["fonts\\morpheus.ttf"] = "Fonts\\MORPHEUS_CYR.TTF",
}

-- Returns the Cyrillic twin and a plain fallback, or nil if the font is fine.
local function CyrFontFor(font)
    if type(font) ~= "string" or font == "" then
        return nil
    end
    local key = font:lower():gsub("/", "\\")
    if key:find("_cyr", 1, true) then
        return nil
    end
    local twin = CYR_TWIN[key]
    if twin then
        return twin, twin ~= CYR_FONT_FILE and CYR_FONT_FILE or nil
    end
    if key:find("morpheus", 1, true) or key:find("skurri", 1, true) then
        return CYR_FONT_FILE
    end
    return nil
end

local function NormFontPath(path)
    return (path:lower():gsub("/", "\\"))
end

-- Never throws. New clients reject a nil flags argument, and some return
-- nothing from SetFont, so success is read back with GetFont.
local function TrySetFont(fontString, font, size, flags)
    if type(font) ~= "string" or not size then
        return false
    end
    local ok, set = pcall(fontString.SetFont, fontString, font, size, flags or "")
    if not ok then
        return false
    end
    if set then
        return true
    end
    local okGet, now = pcall(fontString.GetFont, fontString)
    return okGet and type(now) == "string" and NormFontPath(now) == NormFontPath(font)
end

function GQ.SetFontCyr(fontString, font, size, flags)
    if not fontString or not fontString.SetFont or not font then
        return false
    end
    local cyr, alt = CyrFontFor(font)
    if cyr and TrySetFont(fontString, cyr, size, flags) then
        return true
    end
    if alt and TrySetFont(fontString, alt, size, flags) then
        return true
    end
    return TrySetFont(fontString, font, size, flags)
end

-- Swap a font string's current face for the Cyrillic one, keeping size and flags.
-- If the client refuses, the template font object is put back as it was.
function GQ.ApplyCyrFont(fontString)
    if not fontString or not fontString.GetFont or not fontString.SetFont then
        return false
    end
    local ok, font, size, flags = pcall(fontString.GetFont, fontString)
    if not ok or not size then
        return false
    end
    local cyr, alt = CyrFontFor(font)
    if not cyr then
        return false
    end
    local okObj, fontObject = pcall(fontString.GetFontObject, fontString)
    if TrySetFont(fontString, cyr, size, flags) then
        return true
    end
    if alt and TrySetFont(fontString, alt, size, flags) then
        return true
    end
    if okObj and fontObject and fontString.SetFontObject then
        pcall(fontString.SetFontObject, fontString, fontObject)
    else
        TrySetFont(fontString, font, size, flags)
    end
    return false
end

-- Upper case for ASCII and Russian letters in UTF-8. Lua's string.upper works
-- on single bytes and corrupts Cyrillic, so map the two-byte letters directly:
-- а-п (D0 B0-BF) -> А-П (D0 90-9F), р-я (D1 80-8F) -> Р-Я (D0 A0-AF), ё -> Ё.
function GQ.UpperUTF8(s)
    if type(s) ~= "string" then
        return s
    end
    s = s:gsub("[a-z]", function(c)
        return string.char(c:byte() - 32)
    end)
    s = s:gsub("\208([\176-\191])", function(c)
        return "\208" .. string.char(c:byte() - 32)
    end)
    s = s:gsub("\209([\128-\143])", function(c)
        return "\208" .. string.char(c:byte() + 32)
    end)
    s = s:gsub("\209\145", "\208\129")
    return s
end

-- Lower case for ASCII and Russian letters in UTF-8, the mirror of UpperUTF8:
-- А-П (D0 90-9F) -> а-п (D0 B0-BF), Р-Я (D0 A0-AF) -> р-я (D1 80-8F), Ё -> ё.
-- Use it on both sides of a case-insensitive comparison of client text.
function GQ.LowerUTF8(s)
    if type(s) ~= "string" then
        return s
    end
    s = s:gsub("[A-Z]", function(c)
        return string.char(c:byte() + 32)
    end)
    s = s:gsub("\208([\144-\159])", function(c)
        return "\208" .. string.char(c:byte() + 32)
    end)
    s = s:gsub("\208([\160-\175])", function(c)
        return "\209" .. string.char(c:byte() - 32)
    end)
    s = s:gsub("\208\129", "\209\145")
    return s
end

-- Old scraped text can carry Windows-1252 quotes and dashes as single bytes:
-- 0x91-0x94 (' ' " ") and 0x96-0x97 (- -). In UTF-8 the same byte values are
-- the second byte of Б В Г Д Ж З and ё, so replacing them everywhere cut those
-- letters in half and the game drew a box plus an apostrophe. Only stray bytes,
-- ones that are not part of a valid UTF-8 character, are replaced here.
local CP1252_PUNCT = {
    ["\145"] = "'", ["\146"] = "'", ["\147"] = "'", ["\148"] = "'",
    ["\150"] = "-", ["\151"] = "-",
}

-- Number of continuation bytes a UTF-8 lead byte needs, 0 for an invalid lead.
local function Utf8TailLength(byte)
    if byte >= 194 and byte <= 223 then
        return 1
    elseif byte >= 224 and byte <= 239 then
        return 2
    elseif byte >= 240 and byte <= 244 then
        return 3
    end
    return 0
end

function GQ.FixStrayCp1252(text)
    if type(text) ~= "string" or not text:find("[\145-\151]") then
        return text
    end
    return (text:gsub("([\192-\255]?)([\128-\191]+)", function(lead, run)
        local tail = lead ~= "" and Utf8TailLength(lead:byte()) or 0
        if tail > 0 and #run >= tail then
            if #run == tail then
                return nil
            end
            return lead .. run:sub(1, tail) .. (run:sub(tail + 1):gsub("[\145-\151]", CP1252_PUNCT))
        end
        return lead .. (run:gsub("[\145-\151]", CP1252_PUNCT))
    end))
end

-- Russian display names for English keys. Keys stay English everywhere in the
-- logic; only text shown to the player goes through GQ.RuLabel.
GQ.RU = {
    class = {
        WARRIOR = "Воин", PALADIN = "Паладин", HUNTER = "Охотник", ROGUE = "Разбойник",
        PRIEST = "Жрец", SHAMAN = "Шаман", MAGE = "Маг", WARLOCK = "Чернокнижник", DRUID = "Друид",
    },
    faction = {
        Alliance = "Альянс", Horde = "Орда",
    },
    profession = {
        Tailoring = "Портняжное дело", Leatherworking = "Кожевничество",
        Blacksmithing = "Кузнечное дело", Engineering = "Инженерное дело",
        Alchemy = "Алхимия", Enchanting = "Наложение чар", Mining = "Горное дело",
        Herbalism = "Травничество", Skinning = "Снятие шкур", Cooking = "Кулинария",
        ["First Aid"] = "Первая помощь", Fishing = "Рыбная ловля", Jewelcrafting = "Ювелирное дело",
    },
    armor = {
        Cloth = "Ткань", Leather = "Кожа", Mail = "Кольчуга", Plate = "Латы", Shield = "Щит",
        Idol = "Идол", Libram = "Манускрипт", Totem = "Тотем", Relic = "Реликвия",
    },
    -- Log.lua sits at Lua 5.1's limit of 200 file-level locals, so its display
    -- tables live here instead of as locals there.
    repStanding = {
        Hated = "Ненависть", Hostile = "Враждебность", Unfriendly = "Неприязнь", Neutral = "Равнодушие",
        Friendly = "Дружелюбие", Honored = "Уважение", Revered = "Почтение", Exalted = "Превознесение",
    },
    weaponType = {
        Dagger = "Кинжал", Sword = "Меч", Mace = "Дробящее оружие", Axe = "Топор",
        Fist = "Кистевое оружие", Polearm = "Древковое оружие", Staff = "Посох",
        Bow = "Лук", Gun = "Огнестрельное оружие", Crossbow = "Арбалет",
    },
}

-- Track button caption. Log.lua's WireControls compares the button text against it.
GQ.TRACK_BUTTON_TEXT = "Отслеживать"

-- GQ.RuLabel("class", "WARRIOR") -> "Воин". Unknown keys come back unchanged.
function GQ.RuLabel(kind, key)
    if key == nil then
        return nil
    end
    local map = GQ.RU[kind]
    if not map then
        return key
    end
    local found = map[key]
    if not found and type(key) == "string" then
        found = map[key:upper()] or map[key:sub(1, 1):upper() .. key:sub(2):lower()]
    end
    return found or key
end
-- WoW Forever: 1–60 Classic+ (no TBC level cap).
GQ.MAX_PLAYER_LEVEL = 60

-- Forever's Interface 16001 client namespaced item APIs (10.2.6+). The old
-- globals can be nil and would crash PLAYER_LOGIN at Equip.lua:PrimeItem.
do
    local item = C_Item
    if item then
        if type(GetItemInfo) ~= "function" and item.GetItemInfo then
            GetItemInfo = item.GetItemInfo
        end
        if type(GetItemInfoInstant) ~= "function" and item.GetItemInfoInstant then
            GetItemInfoInstant = item.GetItemInfoInstant
        end
        if type(GetItemStats) ~= "function" and item.GetItemStats then
            GetItemStats = item.GetItemStats
        end
        if type(GetItemIcon) ~= "function" and (item.GetItemIconByID or item.GetItemIcon) then
            GetItemIcon = item.GetItemIconByID or item.GetItemIcon
        end
        if type(GetItemQualityColor) ~= "function" and item.GetItemQualityColor then
            GetItemQualityColor = item.GetItemQualityColor
        end
        if type(IsEquippableItem) ~= "function" and item.IsEquippableItem then
            IsEquippableItem = item.IsEquippableItem
        end
        if type(GetItemCount) ~= "function" and item.GetItemCount then
            GetItemCount = item.GetItemCount
        end
        if type(GetItemFamily) ~= "function" and item.GetItemFamily then
            GetItemFamily = item.GetItemFamily
        end
    end
    if type(GetItemQualityColor) ~= "function" then
        GetItemQualityColor = function(quality)
            local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality or 1]
            if c then
                return c.r, c.g, c.b
            end
            return 1, 1, 1
        end
    end
end

-- Forever dropped some Classic events (TRADE_SKILL_UPDATE, CRAFT_*). Registering
-- an unknown event throws and would abort the rest of PLAYER_LOGIN (no minimap).
function GQ.RegisterEvent(frame, event)
    if not frame or not event or type(frame.RegisterEvent) ~= "function" then
        return false
    end
    return pcall(frame.RegisterEvent, frame, event)
end

-- Forever/Midnight can mark tooltip FontString text as a secret string.
-- Comparing or pattern-matching that value while tainted throws.
function GQ.PublicText(value)
    if value == nil then
        return nil
    end
    if issecretvalue then
        local ok, secret = pcall(issecretvalue, value)
        if ok and secret then
            return nil
        end
    end
    if canaccessvalue then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok and not accessible then
            return nil
        end
    end
    local ok, public = pcall(function()
        return type(value) == "string" and value ~= "" and value or nil
    end)
    if not ok then
        return nil
    end
    return public
end

function GQ:ClampPlayerLevel(level)
    level = tonumber(level) or 1
    level = math.floor(level)
    if level < 1 then
        return 1
    end
    if level > self.MAX_PLAYER_LEVEL then
        return self.MAX_PLAYER_LEVEL
    end
    return level
end

-- Forever can inject SavedVariables into _G while addon code holds a separate
-- empty table if we assign defaults too early. Always read/write _G explicitly.
function GQ:BindSavedVariableGlobals()
    -- Never fabricate empty SavedVariables tables here — that runs before the
    -- client merges WTF data and can shadow saved hunt/obtained keys on reload.
    if type(_G.GearQuestForeverDB) == "table" then
        GearQuestForeverDB = _G.GearQuestForeverDB
    elseif type(GearQuestForeverDB) == "table" then
        _G.GearQuestForeverDB = GearQuestForeverDB
    end
    if type(_G.GearQuestForeverCharDB) == "table" then
        GearQuestForeverCharDB = _G.GearQuestForeverCharDB
    elseif type(GearQuestForeverCharDB) == "table" then
        _G.GearQuestForeverCharDB = GearQuestForeverCharDB
    end
end

-- forceCreate: never pass true before SavedVariables have had a chance to load.
function GQ:EnsureSavedVariableDefaults(forceCreate)
    self:BindSavedVariableGlobals()
    if type(GearQuestForeverDB) ~= "table" then
        if not forceCreate then
            return false
        end
        _G.GearQuestForeverDB = {}
        GearQuestForeverDB = _G.GearQuestForeverDB
    end
    if type(GearQuestForeverCharDB) ~= "table" then
        if forceCreate then
            _G.GearQuestForeverCharDB = {}
            GearQuestForeverCharDB = _G.GearQuestForeverCharDB
        end
    end
    GearQuestForeverDB.hunts = GearQuestForeverDB.hunts or {}
    GearQuestForeverDB.obtained = GearQuestForeverDB.obtained or {}
    GearQuestForeverDB.obtainedItems = GearQuestForeverDB.obtainedItems or {}
    GearQuestForeverDB.crafted = GearQuestForeverDB.crafted or {}
    GearQuestForeverDB.dismissedCompleted = GearQuestForeverDB.dismissedCompleted or {}
    return true
end

local svBindFrame = CreateFrame("Frame")
svBindFrame:RegisterEvent("ADDON_LOADED")
pcall(function()
    svBindFrame:RegisterEvent("VARIABLES_LOADED")
end)
svBindFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName ~= GQ.ADDON_NAME then
        return
    end
    GQ:BindSavedVariableGlobals()
end)

local SOURCE_LABELS = {
    world_drop = "Добыча в мире",
    unsourced = "Без источника",
    rare_npc = "Редкий NPC",
    boss_drop = "Добыча с босса",
    raid_trash = "Трэш в подземельях и рейдах",
    quest_reward = "Награда за задание",
    vendor = "Торговец",
    profession = "Профессия",
    auction_house = "Аукцион",
    object_drop = "Контейнер",
}

local SOURCE_COLORS = {
    world_drop = "|cff66ccff",
    unsourced = "|cff9a9a9a",
    rare_npc = "|cff8899dd",
    boss_drop = "|cffff4444",
    raid_trash = "|cffcc9966",
    quest_reward = "|cff00ff00",
    vendor = "|cffffcc00",
    profession = "|cffcc66ff",
    auction_house = "|cffffa500",
}

local SOURCE_ALIAS = {
    -- Fishing and skinning are professions. The filter checkbox is Profession.
    fishing = "profession",
    skinning = "profession",
    -- Looted from a container. The checkbox id is object_drop.
    container = "object_drop",
}

function GQ:NormalizeSourceType(sourceType)
    return SOURCE_ALIAS[sourceType] or sourceType
end

function GQ:GetSourceLabel(sourceType)
    sourceType = self:NormalizeSourceType(sourceType)
    return SOURCE_LABELS[sourceType] or sourceType
end

function GQ:GetSourceTag(sourceType)
    sourceType = self:NormalizeSourceType(sourceType)
    local color = SOURCE_COLORS[sourceType] or "|cffcccccc"
    return color .. (SOURCE_LABELS[sourceType] or sourceType) .. "|r"
end

-- InputDeviceInterfaceStyle is 0 for mouse. The gamepad UI is 1, or a value
-- whose name contains "gamepad". Anything else still draws the map pins.
function GQ:UsesGamepad()
    local get = C_CVar and C_CVar.GetCVar or GetCVar
    if not get then
        return false
    end
    local ok, style = pcall(get, "InputDeviceInterfaceStyle")
    if not ok or style == nil then
        return false
    end
    style = tostring(style):lower()
    if style == "1" or style == "gamepad" then
        return true
    end
    return style:find("gamepad", 1, true) ~= nil
end

-- Gamepad UI: Blizzard shows the "following UI restrictions" dialog when any
-- addon is still on the stack, then the dialog itself changes gamepad focus
-- and the same protected call fires again until the client stops responding.
-- The warning is the hang. Mouse mode still shows it.
function GQ:SilenceGamepadActionPopup()
    if not self:UsesGamepad() or not UIParent or not UIParent.UnregisterEvent then
        return
    end
    pcall(UIParent.UnregisterEvent, UIParent, "ADDON_ACTION_FORBIDDEN")
    pcall(UIParent.UnregisterEvent, UIParent, "ADDON_ACTION_BLOCKED")
end

function GQ:PLAYER_LOGIN()
    self:SilenceGamepadActionPopup()

    local function run(label, fn)
        local ok, err = pcall(fn)
        if not ok then
            GQ:Chat("|cffff0000GearQuest|r: Ошибка (" .. label .. "): " .. tostring(err))
        end
        return ok
    end

    run("startup", function()
        self:BindSavedVariableGlobals()
        self:EnsureSavedVariableDefaults(true)
        GearQuestForeverDB.suffixLinks = nil
        GearQuestForeverDB.suffixLinksVersion = nil
        self.Preview:MigrateSettings()
        self.Preview:OnPlayerLogin()
        if self.Spec and self.Spec.OnPlayerLogin then
            self.Spec:OnPlayerLogin()
        end
        if self.Data.EnsureActiveHuntClasses then
            self.Data:EnsureActiveHuntClasses()
        end
        self.Data:BuildIndex()
        if self.Custom and self.Custom.EnsureBuilt and self.GetEffectiveClass and self.GetEffectiveSpec then
            local classFile = self:GetEffectiveClass()
            local specId = self:GetEffectiveSpec()
            if classFile and specId and self.Custom:Get(classFile, specId) then
                self.Custom:EnsureBuilt(classFile, specId)
            end
        end
        self.Data:CacheContainerItemLinks()
    end)

    run("Indicator", function() self.Indicator:Init() end)
    run("Log", function() self.Log:Init() end)
    run("spec-ui", function()
        if self.Log and self.Log.UpdateSpecButton then
            self.Log:UpdateSpecButton()
        end
        if C_Timer and C_Timer.After and self.Log and self.Log.UpdateSpecButton then
            C_Timer.After(0.5, function()
                if GQ.Log and GQ.Log.UpdateSpecButton then
                    GQ.Log:UpdateSpecButton()
                end
            end)
        end
    end)
    run("Toast", function() self.Toast:Init() end)
    run("Tracker", function() self.Tracker:Init() end)
    run("Guide", function() self.Guide:Init() end)
    run("Popup", function() self.Popup:Init() end)
    run("PaperDoll", function() self.PaperDoll:Init() end)
    run("Minimap", function() self.Minimap:Init() end)
    run("Commands", function() self.Commands:Init() end)

    local previewNote = self.Preview:IsEnabled() and (" (" .. self:GetPreviewLabel() .. ")") or ""
    GQ:Chat("|cff66ccffGearQuest|r v" .. self.VERSION .. " от Weber8210 загружен" .. previewNote .. ". Щёлкните правой кнопкой мыши по слоту экипировки в окне персонажа или введите |cff00ff00/gq|r.")
    GQ:Chat("|cff66ccffGearQuest|r: Щёлкните по значку на миникарте, чтобы открыть GearQuest.")
    -- Login and /reload only print the welcome lines above. Milestone chat
    -- belongs to a real level-up, and a character already past that level
    -- is marked seen so a later check cannot repeat it.
    run("milestones", function()
        self:RememberMilestonesAlreadyPassed(self:GetEffectiveLevel())
    end)
    if self.Log and self.Log.ScheduleAutoCompletionCheck then
        run("auto-complete", function()
            self.Log:ScheduleAutoCompletionCheck()
        end)
    end
end

function GQ:SyncLevelOverride()
    if not self._playerLevelOverride then
        return
    end
    if self:IsPreviewEnabled() then
        self._playerLevelOverride = nil
        return
    end
    local actual = UnitLevel("player")
    if actual and actual >= self._playerLevelOverride then
        self._playerLevelOverride = nil
    end
end

-- List builds ask for class, level, faction and spec several times per
-- catalog entry, and every answer re-reads saved settings. Nothing changes
-- them mid-build, so answer from one snapshot. Only list building runs inside.
local function CloseContextSnapshot(self, ok, ...)
    self._ctx = nil
    if not ok then
        error((...), 0)
    end
    return ...
end

function GQ:WithContextSnapshot(fn, ...)
    if self._ctx then
        return fn(...)
    end
    self._ctx = {}
    return CloseContextSnapshot(self, pcall(fn, ...))
end

function GQ:GetEffectiveLevel()
    if self._listProbeLevel then
        return self:ClampPlayerLevel(self._listProbeLevel)
    end
    local ctx = self._ctx
    local level = ctx and ctx.level
    if level == nil then
        level = self:ComputeEffectiveLevel()
        if ctx then
            ctx.level = level
        end
    end
    return level
end

function GQ:ComputeEffectiveLevel()
    self:SyncLevelOverride()
    if self._playerLevelOverride and not self:IsPreviewEnabled() then
        return self:ClampPlayerLevel(self._playerLevelOverride)
    end
    return self:ClampPlayerLevel(self.Preview:GetEffectiveLevel())
end

function GQ:RefreshUI(opts)
    opts = opts or {}
    if self._refreshScheduled then
        self._refreshPending = true
        return
    end

    self._refreshScheduled = true
    self._refreshPending = false

    local function finishRefresh()
        self._refreshScheduled = false
        if self._refreshPending then
            self._refreshPending = false
            self:RefreshUI(opts)
        end
    end

    local function runHeavy()
        local function afterIndicatorCache()
            if self.Log and self.Log.frame then
                pcall(function()
                    if self.Log.UpdateContextStatus then
                        self.Log:UpdateContextStatus()
                    end
                end)
                if self.Log.frame:IsShown() then
                    pcall(function()
                        if self.Log.ScheduleListRefresh then
                            self.Log:ScheduleListRefresh(opts.reason == "level")
                        else
                            self.Log:Refresh()
                        end
                    end)
                elseif opts.reason == "level" then
                    GQ._levelUpGap = nil
                end
            end

            if self.Popup and self.Popup.container and self.Popup.container:IsShown() then
                pcall(function()
                    if self.Popup.activeSlotName and self.Popup.activeSlotButton then
                        self.Popup:ShowForSlot(self.Popup.activeSlotName, self.Popup.activeSlotButton)
                    else
                        self.Popup:Hide()
                    end
                end)
            end

            if self.Tracker then
                pcall(function()
                    self.Tracker:Refresh()
                end)
            end

            finishRefresh()
        end

        if self.Indicator then
            pcall(function()
                if self.Indicator.RebuildCacheAsync then
                    local perFrame = (opts.reason == "level") and 1 or nil
                    self.Indicator:RebuildCacheAsync(afterIndicatorCache, perFrame)
                else
                    self.Indicator:RebuildCache()
                    self.Indicator:RefreshAll()
                    afterIndicatorCache()
                end
            end)
        else
            afterIndicatorCache()
        end
    end

    if self.Log then
        pcall(function()
            if self.Log.UpdateSpecButton then
                self.Log:UpdateSpecButton()
            end
            if self.Log.frame and self.Log.frame:IsShown() and self.Log.UpdateFooterButtons then
                self.Log:UpdateFooterButtons()
            end
        end)
    end

    if C_Timer and C_Timer.After then
        -- A cold cache builds every slot inside the first indicator pass.
        -- Warm one slot per frame, then draw.
        C_Timer.After(0, function()
            if self.Data and self.Data.WarmQueryCacheAsync then
                self.Data:WarmQueryCacheAsync(runHeavy)
            else
                runHeavy()
            end
        end)
    else
        runHeavy()
    end
end

function GQ:MilestoneTables()
    self:BindSavedVariableGlobals()
    GearQuestForeverCharDB.milestones = GearQuestForeverCharDB.milestones or {}
    GearQuestForeverDB.settings = GearQuestForeverDB.settings or {}
    GearQuestForeverDB.settings.milestones = GearQuestForeverDB.settings.milestones or {}
    return GearQuestForeverCharDB.milestones, GearQuestForeverDB.settings.milestones
end

function GQ:MilestoneSeen(key)
    local char, account = self:MilestoneTables()
    if key == "ringSlot1" and (char.ringSlots or account.ringSlots) then
        char.ringSlot1 = true
        account.ringSlot1 = true
    end
    return char[key] or account[key]
end

function GQ:MarkMilestone(key)
    local char, account = self:MilestoneTables()
    char[key] = true
    account[key] = true
end

function GQ:NotifyMilestoneOnce(key, message)
    if self:MilestoneSeen(key) then
        self:MarkMilestone(key)
        return
    end

    self:MarkMilestone(key)
    GQ:Chat(message)
end

-- A character who logs in already past a milestone has had their chance.
-- Record it without printing. Welcome chat is the only login message.
function GQ:RememberMilestonesAlreadyPassed(level)
    level = tonumber(level)
    if not level then
        return
    end

    if level >= 10 then
        self:MarkMilestone("specSwitch")
    end

    local fingerUnlock = 9
    if GQ.Data and GQ.Data.GetSlotUnlockLevel then
        fingerUnlock = GQ.Data:GetSlotUnlockLevel("Finger") or fingerUnlock
    end
    if level >= fingerUnlock then
        self:MarkMilestone("ringSlot1")
    end

    local ringSlot2Level = GQ.Data and GQ.Data.RING_SLOT_2_MILESTONE_LEVEL
    if ringSlot2Level and level >= ringSlot2Level then
        self:MarkMilestone("ringSlot2")
    end
end

function GQ:CheckLevelMilestones(previousLevel, newLevel)
    -- Slot unlock messages — see docs/DATA_RULES.md § Slot unlock & level-up messages.
    -- Only when the player crosses the level. Login must not call this.
    if not newLevel or not previousLevel or newLevel <= previousLevel then
        return
    end

    -- Finger milestones follow this character's hunts, not the Alliance paladin
    -- level-9 band. Horde shaman has no Finger rows until later; do not toast an empty slot.
    local fingerUnlock = 9
    if GQ.Data and GQ.Data.GetSlotUnlockLevel then
        fingerUnlock = GQ.Data:GetSlotUnlockLevel("Finger") or fingerUnlock
    end
    local ringSlot2Level = GQ.Data and GQ.Data.RING_SLOT_2_MILESTONE_LEVEL
    local crossesRing1 = previousLevel < fingerUnlock and newLevel >= fingerUnlock
    local crossesRing2 = ringSlot2Level and previousLevel < ringSlot2Level and newLevel >= ringSlot2Level
    -- The finger list is a catalog walk. Only a ring milestone needs it.
    local fingerCount = 0
    if (crossesRing1 or crossesRing2) and GQ.Data and GQ.Data.GetTopUpgradesForSlot then
        local fingerHunts = GQ.Data:GetTopUpgradesForSlot("Finger", 3)
        fingerCount = fingerHunts and #fingerHunts or 0
    end
    if fingerCount > 0 and crossesRing1 then
        self:NotifyMilestoneOnce(
            "ringSlot1",
            "|cff66ccffGearQuest|r: Вы достигли уровня " .. newLevel .. " — один из слотов для колец теперь можно улучшить! Откройте |cff00ff00/gq log|r, чтобы посмотреть улучшения для колец."
        )
    end
    if fingerCount >= 2 and crossesRing2 then
        self:NotifyMilestoneOnce(
            "ringSlot2",
            "|cff66ccffGearQuest|r: Вы достигли уровня " .. newLevel .. " — второй слот для кольца теперь тоже можно улучшить! Откройте |cff00ff00/gq log|r, чтобы посмотреть улучшения для колец."
        )
    end

    -- Level 10: talent specs — log button and /gq spec filter gear lists.
    if newLevel >= 10 and previousLevel < 10 then
        local classFile = GQ:GetEffectiveClass()
        if GQ.Spec and GQ.Spec.HasSpecs and GQ.Spec:HasSpecs(classFile) then
            local defaultLabel = GQ.Spec:GetSpecLabel(GQ.Spec:GetDefaultSpec(classFile), classFile) or "специализация по умолчанию"
            self:NotifyMilestoneOnce(
                "specSwitch",
                "|cff66ccffGearQuest|r: Поздравляем — вы достигли 10-го уровня! Теперь в GearQuest доступны специализации. Откройте |cff00ff00/gq log|r, чтобы посмотреть улучшения для каждой специализации; по умолчанию выбрано: |cff00ff00"
                    .. defaultLabel
                    .. "|r."
            )
        end
    end
end

function GQ:PLAYER_LEVEL_UP(_, newLevel)
    local previousLevel = newLevel and (newLevel - 1) or nil
    if newLevel and not self:IsPreviewEnabled() then
        self._playerLevelOverride = newLevel
    end
    if self.Data and self.Data.InvalidateQueryCache then
        self.Data:InvalidateQueryCache()
    end
    -- Quest turn-in dings inside the gamepad focus change. Each slot waits
    -- a frame, then milestones, the obtain check, and the redraw each wait
    -- a frame of their own.
    GQ._levelUpGap = 1
    local function later(fn)
        if C_Timer and C_Timer.After then
            C_Timer.After(0, fn)
        else
            fn()
        end
    end
    local function apply()
        later(function()
            self:CheckLevelMilestones(previousLevel, newLevel)
            later(function()
                if self.Log and self.Log.CheckAutoCompletion then
                    self.Log:CheckAutoCompletion()
                end
                later(function()
                    self:RefreshUI({ reason = "level" })
                end)
            end)
        end)
    end
    if not (C_Timer and C_Timer.After) then
        apply()
        return
    end
    if not (self.Data and self.Data.WarmQueryCacheAsync) then
        C_Timer.After(0, apply)
        return
    end
    self.Data:WarmQueryCacheAsync(apply, 1)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        GQ:PLAYER_LOGIN()
    elseif event == "PLAYER_LEVEL_UP" then
        GQ:PLAYER_LEVEL_UP(event, ...)
    end
end)
