local _, GQ = ...

-- Display-time Russian for the addon's English data (class hunt data, stored
-- Wowhead tooltips). The data itself stays English, because the logic parses
-- it; only the string that is about to be shown goes through GQ.L10N.
--
-- Translations live in _generated/L10N.*.ru.generated.lua:
--   L.text[english] = russian   instructions, quest objectives, lore, item effects
--   L.tip[shape]    = russian   one tooltip line shape, numbers as {1}, {2}, ...
--   L.ids.*                     english name -> client id, to show official names
-- Inside a translation, {z:Name} {q:Name} {f:Name} {i:Name} stand for a zone,
-- quest, faction or item. They become the client's own (Russian) name when the
-- client knows the id, and stay the English name otherwise.

GQ.L10N = GQ.L10N or {}
local L = GQ.L10N
L.text = L.text or {}
L.tip = L.tip or {}
L.ids = L.ids or {}
L.ids.zoneMap = L.ids.zoneMap or {}
L.ids.zoneArea = L.ids.zoneArea or {}
L.ids.quest = L.ids.quest or {}
L.ids.faction = L.ids.faction or {}
L.ids.item = L.ids.item or {}
-- English quest title -> Russian title (Questie's WoW Forever database), shown
-- until the client has the quest cached and can name it itself.
L.questRu = L.questRu or {}
-- English NPC name -> Russian name (same source). Nominative case only: use it
-- where the name stands alone ("Выпадает из: <name>"), not inside a sentence.
L.npcRu = L.npcRu or {}
-- English set name -> official Russian set name (ItemSet.db2 of the Forever client).
L.setName = L.setName or {}
-- Set names shared by an original set and its Forever re-release (different
-- Russian names): set id -> { English, Russian }, and item id -> set id.
L.setById = L.setById or {}
L.itemSet = L.itemSet or {}
-- English set name -> { { set id, lowest piece id, highest piece id }, ... } for those
-- shared names, to place an item that is not a listed piece (a Forever variant id).
L.setCand = L.setCand or {}

-- Client strings are used only on a Russian client; anywhere else the Russian
-- fallbacks below are shown, so the addon reads Russian either way.
local IS_RU = type(GetLocale) == "function" and GetLocale() == "ruRU"

local function G(name, fallback)
    if IS_RU then
        local v = _G[name]
        if type(v) == "string" and v ~= "" then
            return v
        end
    end
    return fallback
end

-- string.format that never throws: a client format with other specifiers
-- falls back to ours.
local function F(fmt, fallback, ...)
    local ok, out = pcall(string.format, fmt, ...)
    if ok and type(out) == "string" then
        return out
    end
    ok, out = pcall(string.format, fallback, ...)
    if ok then
        return out
    end
    return nil
end

local function Str(value)
    if type(value) ~= "string" or value == "" then
        return nil
    end
    if GQ.PublicText then
        return GQ.PublicText(value)
    end
    return value
end

------------------------------------------------------------------------
-- Names from the client
------------------------------------------------------------------------

local nameCache = {}
local questRequested = {}

local function ZoneName(en)
    if type(en) ~= "string" or en == "" then
        return en
    end
    local key = "z" .. en
    if nameCache[key] then
        return nameCache[key]
    end
    local name
    local id = L.ids.zoneMap[en]
    if id and C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, id)
        if ok and type(info) == "table" then
            name = Str(info.name)
        end
    end
    if not name then
        id = L.ids.zoneArea[en]
        if id and C_Map and C_Map.GetAreaInfo then
            local ok, n = pcall(C_Map.GetAreaInfo, id)
            if ok then
                name = Str(n)
            end
        end
    end
    if name then
        nameCache[key] = name
    end
    return name or en
end

local function QuestName(en)
    if type(en) ~= "string" or en == "" then
        return en
    end
    local key = "q" .. en
    if nameCache[key] then
        return nameCache[key]
    end
    local id = L.ids.quest[en]
    local name
    if id and C_QuestLog then
        if C_QuestLog.GetTitleForQuestID then
            local ok, t = pcall(C_QuestLog.GetTitleForQuestID, id)
            if ok then
                name = Str(t)
            end
        end
        if not name and C_QuestLog.GetQuestInfo then
            local ok, t = pcall(C_QuestLog.GetQuestInfo, id)
            if ok then
                name = Str(t)
            end
        end
        -- ask the client to load the quest once per session
        if not name and C_QuestLog.RequestLoadQuestByID and not questRequested[id] then
            questRequested[id] = true
            pcall(C_QuestLog.RequestLoadQuestByID, id)
        end
    end
    if name then
        nameCache[key] = name
        return name
    end
    -- Not loaded by the client yet: the stored Russian title. It is not put in
    -- nameCache, so the client's own title wins once the quest has loaded.
    return L.questRu[en] or en
end

local function FactionName(en)
    if type(en) ~= "string" or en == "" then
        return en
    end
    local key = "f" .. en
    if nameCache[key] then
        return nameCache[key]
    end
    local id = L.ids.faction[en]
    local name
    if id then
        if C_Reputation and C_Reputation.GetFactionDataByID then
            local ok, data = pcall(C_Reputation.GetFactionDataByID, id)
            if ok and type(data) == "table" then
                name = Str(data.name)
            end
        end
        if not name and GetFactionInfoByID then
            local ok, n = pcall(GetFactionInfoByID, id)
            if ok then
                name = Str(n)
            end
        end
    end
    if name then
        nameCache[key] = name
    end
    return name or en
end

-- The client's name of an item id, or nil (then the item is requested, so a
-- later look finds it).
local function ItemNameById(id)
    id = tonumber(id)
    if not id then
        return nil
    end
    local name
    if GetItemInfo then
        local ok, n = pcall(GetItemInfo, id)
        if ok then
            name = Str(n)
        end
    end
    if name and GQ.Data and GQ.Data.IsPlaceholderItemName and GQ.Data:IsPlaceholderItemName(name, id) then
        name = nil
    end
    if not name and GQ.Data and GQ.Data.RequestItemInfo then
        pcall(GQ.Data.RequestItemInfo, GQ.Data, id)
    end
    return name
end

local function ItemName(en)
    if type(en) ~= "string" or en == "" then
        return en
    end
    local id = L.ids.item[en]
    if not id then
        return en
    end
    return ItemNameById(id) or en
end

-- Russian NPC name (nominative) or the English one; a comma list is mapped part by part.
local function NpcName(en)
    if type(en) ~= "string" or en == "" then
        return en
    end
    local ru = L.npcRu[en]
    if ru then
        return ru
    end
    if en:find(",", 1, true) then
        local parts = {}
        for part in en:gmatch("[^,]+") do
            local name = part:match("^%s*(.-)%s*$")
            parts[#parts + 1] = L.npcRu[name] or name
        end
        return table.concat(parts, ", ")
    end
    return en
end

local RESOLVERS = { z = ZoneName, q = QuestName, f = FactionName, i = ItemName }

L.ZoneName = ZoneName
L.QuestName = QuestName
L.FactionName = FactionName
L.ItemName = ItemName
L.NpcName = NpcName

------------------------------------------------------------------------
-- Ids and skill names for logic
------------------------------------------------------------------------
-- The client reports skills, zones and factions in its own language, while the
-- data keys stay English ("Tailoring", "Elwynn Forest", "Booty Bay"). Compare
-- through these helpers, never by raw client name.

-- English data name -> uiMapID / AreaTable ID / Faction ID (generated tables).
function L.ZoneMapId(en)
    return type(en) == "string" and L.ids.zoneMap[en] or nil
end

function L.ZoneAreaId(en)
    return type(en) == "string" and L.ids.zoneArea[en] or nil
end

function L.FactionId(en)
    return type(en) == "string" and L.ids.faction[en] or nil
end

-- SkillLine.db2 of the WoW Forever client (build 1.60.1.70790, wago.tools):
-- ID -> { English DisplayName, ruRU DisplayName }. Professions, secondary
-- skills and weapon skills that the addon checks.
local SKILL_LINES = {
    [171] = { "Alchemy", "Алхимия" },
    [164] = { "Blacksmithing", "Кузнечное дело" },
    [333] = { "Enchanting", "Наложение чар" },
    [202] = { "Engineering", "Инженерное дело" },
    [182] = { "Herbalism", "Травничество" },
    [165] = { "Leatherworking", "Кожевничество" },
    [186] = { "Mining", "Горное дело" },
    [393] = { "Skinning", "Снятие шкур" },
    [197] = { "Tailoring", "Портняжное дело" },
    [185] = { "Cooking", "Кулинария" },
    [129] = { "First Aid", "Первая помощь" },
    [356] = { "Fishing", "Рыбная ловля" },
    [43] = { "Swords", "Мечи" },
    [44] = { "Axes", "Топоры" },
    [45] = { "Bows", "Луки" },
    [46] = { "Guns", "Огнестрельное оружие" },
    [54] = { "Maces", "Дробящее оружие" },
    [55] = { "Two-Handed Swords", "Двуручные мечи" },
    [136] = { "Staves", "Посохи" },
    [160] = { "Two-Handed Maces", "Двуручное дробящее оружие" },
    [162] = { "Unarmed", "Рукопашный бой" },
    [172] = { "Two-Handed Axes", "Двуручные топоры" },
    [173] = { "Daggers", "Кинжалы" },
    [176] = { "Thrown", "Метательное оружие" },
    [226] = { "Crossbows", "Арбалеты" },
    [228] = { "Wands", "Жезлы" },
    [229] = { "Polearms", "Древковое оружие" },
    [473] = { "Fist Weapons", "Кистевое оружие" },
    [95] = { "Defense", "Защита" },
    [118] = { "Dual Wield", "Бой двумя руками" },
}

local skillKeyByName, skillRuByKey

local function LowerName(s)
    if GQ.LowerUTF8 then
        return GQ.LowerUTF8(s)
    end
    return s:lower()
end

local function BuildSkillMaps()
    skillKeyByName, skillRuByKey = {}, {}
    for _, pair in pairs(SKILL_LINES) do
        local en, ru = pair[1], pair[2]
        skillRuByKey[en] = ru
        skillKeyByName[en] = en
        skillKeyByName[LowerName(en)] = en
        skillKeyByName[ru] = en
        skillKeyByName[LowerName(ru)] = en
    end
end

-- English skill key ("Tailoring") for a skill name printed by the client in
-- any language ("Портняжное дело", "Tailoring", "tailoring"), or nil.
function L.SkillKey(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    if not skillKeyByName then
        BuildSkillMaps()
    end
    name = name:match("^%s*(.-)%s*$")
    return skillKeyByName[name] or skillKeyByName[LowerName(name)]
end

-- English skill key for a SkillLine ID (7th return of GetProfessionInfo).
function L.SkillLineKey(id)
    local pair = SKILL_LINES[tonumber(id) or -1]
    return pair and pair[1] or nil
end

-- Russian name of an English skill key, for display; unknown keys unchanged.
function L.SkillName(en)
    if type(en) ~= "string" then
        return en
    end
    if not skillRuByKey then
        BuildSkillMaps()
    end
    return skillRuByKey[en] or en
end

-- Replace {z:..} {q:..} {f:..} {i:..} with client names (or the English name).
function L:Resolve(s)
    if type(s) ~= "string" or not s:find("{", 1, true) then
        return s
    end
    return (s:gsub("{([zqfi]):([^{}]*)}", function(kind, name)
        local ok, out = pcall(RESOLVERS[kind], name)
        if ok and type(out) == "string" and out ~= "" then
            return out
        end
        return name
    end))
end

function L:Has(en)
    return type(en) == "string" and self.text[en] ~= nil
end

-- Russian for one English data string (instructions, objective, lore, proc).
-- Unknown strings come back unchanged, except that placeholders in text that
-- is already Russian (Data.lua's own instructions) are resolved too.
function L:Text(en)
    if type(en) ~= "string" or en == "" then
        return en
    end
    local ru = self.text[en]
    if not ru then
        return self:Resolve(en)
    end
    return self:Resolve(ru)
end

------------------------------------------------------------------------
-- Tooltip lines
------------------------------------------------------------------------

-- Same numbering as the generator: every run of digits (with an optional
-- ".digits" tail) becomes {1}, {2}, ... in order.
local function ShapeOf(line)
    local nums, out = {}, {}
    local i, n, k = 1, #line, 0
    while i <= n do
        local s, e = line:find("%d+", i)
        if not s then
            out[#out + 1] = line:sub(i)
            break
        end
        local _, e2 = line:find("^%.%d+", e + 1)
        if e2 then
            e = e2
        end
        out[#out + 1] = line:sub(i, s - 1)
        k = k + 1
        nums[k] = line:sub(s, e)
        out[#out + 1] = "{" .. k .. "}"
        i = e + 1
    end
    return table.concat(out), nums
end

local function Fill(template, nums)
    return (template:gsub("{(%d+)}", function(k)
        return nums[tonumber(k)] or ""
    end))
end

local STAT_RU = {
    ["Stamina"] = "к выносливости",
    ["Intellect"] = "к интеллекту",
    ["Strength"] = "к силе",
    ["Spirit"] = "к духу",
    ["Agility"] = "к ловкости",
    ["Armor"] = "к броне",
    ["Defense"] = "к защите",
    ["Attack Power"] = "к силе атаки",
    ["Ranged Attack Power"] = "к силе атаки дальнего боя",
    ["Spell Power"] = "к силе заклинаний",
    ["Spell Penetration"] = "к проникающей способности заклинаний",
    ["Armor Penetration"] = "к пробиванию брони",
    ["Block Value"] = "к показателю блокирования",
    ["Fire Resistance"] = "к сопротивлению огню",
    ["Frost Resistance"] = "к сопротивлению магии льда",
    ["Nature Resistance"] = "к сопротивлению силам природы",
    ["Shadow Resistance"] = "к сопротивлению темной магии",
    ["Arcane Resistance"] = "к сопротивлению тайной магии",
    ["Holy Resistance"] = "к сопротивлению светлой магии",
    ["All Resistances"] = "ко всем видам сопротивления",
    ["to All Resistances"] = "ко всем видам сопротивления",
}

local SCHOOL_RU = {
    Fire = "огонь", Frost = "лёд", Nature = "природа", Shadow = "тьма", Arcane = "тайная магия", Holy = "свет",
}
-- the client's own school names (GlobalStrings DAMAGE_SCHOOL2..7) on a Russian client
local SCHOOL_GLOBAL = {
    Holy = "DAMAGE_SCHOOL2", Fire = "DAMAGE_SCHOOL3", Nature = "DAMAGE_SCHOOL4",
    Frost = "DAMAGE_SCHOOL5", Shadow = "DAMAGE_SCHOOL6", Arcane = "DAMAGE_SCHOOL7",
}

local SLOT = {
    ["Head"] = { "INVTYPE_HEAD", "Голова" },
    ["Neck"] = { "INVTYPE_NECK", "Шея" },
    ["Shoulder"] = { "INVTYPE_SHOULDER", "Плечи" },
    ["Back"] = { "INVTYPE_CLOAK", "Спина" },
    ["Chest"] = { "INVTYPE_CHEST", "Грудь" },
    ["Shirt"] = { "INVTYPE_BODY", "Рубашка" },
    ["Tabard"] = { "INVTYPE_TABARD", "Гербовая накидка" },
    ["Wrist"] = { "INVTYPE_WRIST", "Запястья" },
    ["Hands"] = { "INVTYPE_HAND", "Кисти рук" },
    ["Waist"] = { "INVTYPE_WAIST", "Пояс" },
    ["Legs"] = { "INVTYPE_LEGS", "Ноги" },
    ["Feet"] = { "INVTYPE_FEET", "Ступни" },
    ["Finger"] = { "INVTYPE_FINGER", "Палец" },
    ["Trinket"] = { "INVTYPE_TRINKET", "Аксессуар" },
    ["Main Hand"] = { "INVTYPE_WEAPONMAINHAND", "Правая рука" },
    ["Off Hand"] = { "INVTYPE_WEAPONOFFHAND", "Левая рука" },
    ["One-Hand"] = { "INVTYPE_WEAPON", "Одноручное" },
    ["Two-Hand"] = { "INVTYPE_2HWEAPON", "Двуручное" },
    ["Ranged"] = { "INVTYPE_RANGED", "Дальний бой" },
    ["Relic"] = { "INVTYPE_RELIC", "Реликвия" },
    ["Held In Off-hand"] = { "INVTYPE_HOLDABLE", "Левая рука" },
    ["Held In Off-Hand"] = { "INVTYPE_HOLDABLE", "Левая рука" },
    ["Thrown"] = { "INVTYPE_THROWN", "Метательное оружие" },
    ["Ammo"] = { "INVTYPE_AMMO", "Боеприпасы" },
    ["Bag"] = { "INVTYPE_BAG", "Сумка" },
    ["Quiver"] = { "INVTYPE_QUIVER", "Колчан" },
}

local TYPE_RU = {
    ["Cloth"] = "Ткань", ["Leather"] = "Кожа", ["Mail"] = "Кольчуга", ["Plate"] = "Латы", ["Shield"] = "Щит",
    ["Sword"] = "Меч", ["Axe"] = "Топор", ["Mace"] = "Дробящее оружие", ["Dagger"] = "Кинжал",
    ["Staff"] = "Посох", ["Polearm"] = "Древковое оружие", ["Fist Weapon"] = "Кистевое оружие",
    ["Bow"] = "Лук", ["Gun"] = "Огнестрельное оружие", ["Crossbow"] = "Арбалет", ["Wand"] = "Жезл",
    ["Idol"] = "Идол", ["Libram"] = "Манускрипт", ["Totem"] = "Тотем", ["Relic"] = "Реликвия",
    ["Fishing Pole"] = "Удочка", ["Miscellaneous"] = "Разное", ["Arrow"] = "Стрела", ["Bullet"] = "Пуля",
}

local CLASS_TOKEN = {
    Warrior = "WARRIOR", Paladin = "PALADIN", Hunter = "HUNTER", Rogue = "ROGUE", Priest = "PRIEST",
    Shaman = "SHAMAN", Mage = "MAGE", Warlock = "WARLOCK", Druid = "DRUID",
}

local STANDING_INDEX = {
    Hated = 1, Hostile = 2, Unfriendly = 3, Neutral = 4, Friendly = 5, Honored = 6, Revered = 7, Exalted = 8,
}

local PROFESSION_EN = {
    Tailoring = true, Leatherworking = true, Blacksmithing = true, Engineering = true, Alchemy = true,
    Enchanting = true, Mining = true, Herbalism = true, Skinning = true, Cooking = true,
    ["First Aid"] = true, Fishing = true, Jewelcrafting = true,
}

local function ClassName(en)
    local token = CLASS_TOKEN[en]
    if not token then
        return en
    end
    if IS_RU and type(LOCALIZED_CLASS_NAMES_MALE) == "table" and Str(LOCALIZED_CLASS_NAMES_MALE[token]) then
        return LOCALIZED_CLASS_NAMES_MALE[token]
    end
    return (GQ.RuLabel and GQ.RuLabel("class", token)) or en
end

local function StandingName(en)
    local idx = STANDING_INDEX[en]
    local fallback = GQ.RU and GQ.RU.repStanding and GQ.RU.repStanding[en] or en
    if idx then
        return G("FACTION_STANDING_LABEL" .. idx, fallback)
    end
    return fallback
end

local function SlotName(en)
    local s = SLOT[en]
    if s then
        return G(s[1], s[2])
    end
    return nil
end

-- Structural lines: formula text the client itself prints, so the client's own
-- strings are used on a Russian client. Returns nil when the line is not one.
local function Structural(line)
    local slot = SlotName(line)
    if slot then
        return slot
    end
    if TYPE_RU[line] then
        return TYPE_RU[line]
    end
    local n = line:match("^Item Level (%d+)$")
    if n then
        return F(G("ITEM_LEVEL", "Уровень предмета %d"), "Уровень предмета %d", tonumber(n))
    end
    n = line:match("^Requires Level (%d+)$")
    if n then
        return F(G("ITEM_MIN_LEVEL", "Требуется уровень: %d"), "Требуется уровень: %d", tonumber(n))
    end
    if line == "Binds when picked up" then
        return G("ITEM_BIND_ON_PICKUP", "Становится персональным при получении")
    end
    if line == "Binds when equipped" then
        return G("ITEM_BIND_ON_EQUIP", "Становится персональным при надевании")
    end
    if line == "Binds when used" then
        return G("ITEM_BIND_ON_USE", "Становится персональным при использовании")
    end
    if line == "Quest Item" then
        return G("ITEM_BIND_QUEST", "Предмет, необходимый для задания")
    end
    if line == "Unique" then
        return G("ITEM_UNIQUE", "Уникальный")
    end
    n = line:match("^Unique %((%d+)%)$")
    if n then
        return F(G("ITEM_UNIQUE_MULTIPLE", "Уникальный (%d)"), "Уникальный (%d)", tonumber(n))
    end
    if line == "Unique-Equipped" then
        return G("ITEM_UNIQUE_EQUIPPABLE", "Уникальный (надетый)")
    end
    local cat, cnt = line:match("^Unique%-Equipped: (.+) %((%d+)%)$")
    if cat then
        return F(G("ITEM_LIMIT_CATEGORY_MULTIPLE", "Уникальный (надетый): %s (%d)"),
            "Уникальный (надетый): %s (%d)", cat, tonumber(cnt))
    end
    n = line:match("^([%d%.]+) Armor$")
    if n then
        return F(G("ARMOR_TEMPLATE", "Броня: %s"), "Броня: %s", n)
    end
    n = line:match("^(%d+) Block$")
    if n then
        return F(G("SHIELD_BLOCK_TEMPLATE", "Блок: %d"), "Блок: %d", tonumber(n))
    end
    local a, b = line:match("^Durability (%d+) / (%d+)$")
    if a then
        return F(G("DURABILITY_TEMPLATE", "Прочность: %d / %d"), "Прочность: %d / %d", tonumber(a), tonumber(b))
    end
    local rest = line:match("^Sell Price:(.*)$")
    if rest then
        return G("SELL_PRICE", "Цена продажи") .. ":" .. rest
    end
    n = line:match("^Speed ([%d%.]+)$")
    if n then
        return G("SPEED", "Скорость") .. " " .. n
    end
    local lo, hi, school = line:match("^([%d%.]+) %- ([%d%.]+) (%a+) Damage$")
    if lo and SCHOOL_RU[school] then
        return F("Урон: %s - %s (%s)", "Урон: %s - %s (%s)", lo, hi, G(SCHOOL_GLOBAL[school], SCHOOL_RU[school]))
    end
    lo, hi = line:match("^([%d%.]+) %- ([%d%.]+) Damage$")
    if lo then
        return F(G("DAMAGE_TEMPLATE", "Урон: %s - %s"), "Урон: %s - %s", lo, hi)
    end
    n = line:match("^([%d%.]+) Damage$")
    if n then
        return "Урон: " .. n
    end
    n = line:match("^%(([%d%.]+) damage per second%)$")
    if n then
        return F(G("DPS_TEMPLATE", "(%s ед. урона в секунду)"), "(%s ед. урона в секунду)", n)
    end
    local sign, amount, stat = line:match("^([%+%-])([%d%.]+) (.+)$")
    if sign and STAT_RU[stat] then
        return sign .. amount .. " " .. STAT_RU[stat]
    end
    if line == "<Random enchantment>" then
        return G("ITEM_RANDOM_ENCHANT", "<Случайные чары>")
    end
    if line == "Random enchantment" then
        return "Случайные чары"
    end
    if line == "Crafted" then
        return "Изготовлено"
    end
    -- Wowhead's tag for these items; the client has no string for it, so this
    -- is the addon's own translation.
    if line == "Sanctified" then
        return "Освящённый"
    end
    if line == "This Item Begins a Quest" then
        return G("ITEM_STARTS_QUEST", "Этот предмет позволяет получить задание")
    end
    n = line:match("^Drop Chance: ([%d%.]+)%%$")
    if n then
        return "Шанс выпадения: " .. n .. "%"
    end
    local npc = line:match("^Dropped by: (.+)$")
    if npc then
        return "Выпадает из: " .. NpcName(npc)
    end
    local classes = line:match("^Classes: (.+)$")
    if classes then
        local names = {}
        for part in classes:gmatch("[^,]+") do
            names[#names + 1] = ClassName(strtrim and strtrim(part) or part:match("^%s*(.-)%s*$"))
        end
        return F(G("ITEM_CLASSES_ALLOWED", "Классы: %s"), "Классы: %s", table.concat(names, ", "))
    end
    local races = line:match("^Races: (.+)$")
    if races then
        return F(G("ITEM_RACES_ALLOWED", "Расы: %s"), "Расы: %s", races)
    end
    local prof, skill = line:match("^Requires (.-) %((%d+)%)$")
    if prof and PROFESSION_EN[prof] then
        local label = (GQ.RuLabel and GQ.RuLabel("profession", prof) or prof) .. " (" .. skill .. ")"
        return F(G("ITEM_REQ_SKILL", "Требуется: %s"), "Требуется: %s", label)
    end
    local faction, standing = line:match("^Requires (.+) %- (%a+)$")
    if faction and STANDING_INDEX[standing] then
        return F("Требуется репутация: %s — %s", "Требуется репутация: %s — %s", FactionName(faction), StandingName(standing))
    end
    local title, rank = line:match("^Requires (.+) %(Rank (%d+)%)$")
    if title then
        return "Требуется звание: " .. title .. " (ранг " .. rank .. ")"
    end
    n = line:match("^(%d+) Charges?$")
    if n then
        local count = tonumber(n)
        return count .. " " .. (GQ.Plural and GQ.Plural(count, "заряд", "заряда", "зарядов") or "зарядов")
    end
    n = line:match("^Rank (%d+)$")
    if n then
        return "Ранг " .. n
    end
    -- Wowhead lists a set piece it had no name for as "Item #<id>"
    n = line:match("^Item #?(%d+)$")
    if n then
        return ItemNameById(n) or ("Предмет #" .. n)
    end
    return nil
end

-- Official Russian name of an English set name; itemId (the item whose
-- tooltip is shown) picks the right set when two sets share the English name.
local function SetName(en, itemId)
    local ru = L.setName[en]
    if ru then
        return ru
    end
    local id = tonumber(itemId)
    if not id then
        return nil
    end
    local sid = L.itemSet[id]
    local set = sid and L.setById[sid]
    if set and set[1] == en then
        return set[2]
    end
    -- not a listed piece: the set with the same English name whose piece ids
    -- are nearest to this item's id (original sets have ids far below Forever's)
    local best, bestDistance
    for _, cand in ipairs(L.setCand[en] or {}) do
        local lo, hi = cand[2], cand[3]
        local distance = (id < lo and lo - id) or (id > hi and id - hi) or 0
        if not bestDistance or distance < bestDistance then
            best, bestDistance = cand[1], distance
        end
    end
    set = best and L.setById[best]
    if set and set[1] == en then
        return set[2]
    end
    return nil
end

-- Russian for one stored Wowhead tooltip line (already split by
-- GQ.Data:ForeverTooltipLines). itemId is optional: the item the tooltip is
-- for, used only to name a set. Unknown lines come back unchanged.
function L:Tip(line, itemId)
    if type(line) ~= "string" or line == "" then
        return line
    end
    local lead, body = line:match("^(%s*)(.-)%s*$")
    if not body or body == "" then
        return line
    end
    local ok, out = pcall(function()
        -- Formula lines first: "Mace" on a weapon line is the weapon type,
        -- even though a plain vendor item is also called "Mace".
        local s = Structural(body)
        if s then
            return s
        end
        if self.ids.item[body] then
            return ItemName(body)
        end
        -- set header "Name (2/5)" with the official Russian set name
        local setName, have, total = body:match("^(.-) %((%d+)/(%d+)%)$")
        local setRu = setName and SetName(setName, itemId)
        if setRu then
            return F(G("ITEM_SET_NAME", "%s (%d/%d)"), "%s (%d/%d)", setRu, tonumber(have), tonumber(total))
        end
        local shape, nums = ShapeOf(body)
        local tpl = self.tip[shape]
        if tpl then
            return self:Resolve(Fill(tpl, nums))
        end
        -- a set header of an unknown set keeps its English name
        return nil
    end)
    if ok and type(out) == "string" and out ~= "" then
        return lead .. out
    end
    return line
end
