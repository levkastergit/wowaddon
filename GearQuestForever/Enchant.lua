-- Recommended enchant on a gear tooltip. Wowhead Forever is the source.
-- A formula is shown for every character when the piece can be taken to
-- someone who makes it. It is skipped only when the spell says this
-- character cannot wear it. Armor on an enchant counts for a tank. Every
-- other spec scores the enchant's other stats. Proc scores are a judgment
-- of what the effect does, and they compete with the spec weights.

local _, GQ = ...

GQ.Enchant = GQ.Enchant or {}

local ROLE = {
    PALADIN = { holy = "healer", protection = "tank", retribution = "melee", shockadin = "caster", levelling_1_9 = "melee" },
    PRIEST = { holy = "healer", discipline = "healer", shadow = "caster", levelling_1_9 = "caster" },
    DRUID = { restoration = "healer", balance = "caster", feral = "melee", bear = "tank", levelling_1_9 = "melee" },
    SHAMAN = { restoration = "healer", elemental = "caster", enhancement = "melee", enhancement_tank = "tank", levelling_1_9 = "melee" },
    MAGE = { arcane = "caster", fire = "caster", frost = "caster", battlemage_arcane = "caster", battlemage_fire = "caster", battlemage_frost = "caster", levelling_1_9 = "caster" },
    WARLOCK = { affliction = "caster", demonology = "caster", destruction = "caster", levelling_1_9 = "caster" },
    ROGUE = { assassination = "melee", combat = "melee", subtlety = "melee", levelling_1_9 = "melee" },
    WARRIOR = { arms = "melee", fury = "melee", protection = "tank", levelling_1_9 = "melee" },
    HUNTER = { beast_mastery = "melee", marksmanship = "melee", survival = "melee", levelling_1_9 = "melee" },
}

-- skill is the yellow threshold: an enchanter of this level can use it.
-- slots: wrist chest hands feet cloak neck shield offhand legs weapon two ranged
-- alsoTwo: an Enchant Weapon row also goes on a two-hander.
local ROWS = {
    { slots = "wrist", skill = 20, name = "Enchant Bracer - Inferior Stamina", effect = "+1 к выносливости", stats = { sta = 1 } },
    { slots = "wrist", skill = 100, name = "Enchant Bracer - Minor Stamina", effect = "+3 к выносливости", stats = { sta = 3 } },
    { slots = "wrist", skill = 105, name = "Enchant Bracer - Minor Spirit", effect = "+3 к духу", stats = { spi = 3 } },
    { slots = "wrist", skill = 110, name = "Enchant Bracer - Minor Intellect", effect = "+3 к интеллекту", stats = { int = 3 } },
    { slots = "wrist", skill = 115, name = "Enchant Bracer - Minor Agility", effect = "+3 к ловкости", stats = { agi = 3 } },
    { slots = "wrist", skill = 115, name = "Enchant Bracer - Minor Strength", effect = "+3 к силе", stats = { str = 3 } },
    { slots = "wrist", skill = 120, name = "Enchant Bracer - Minor Healing Power", effect = "+8 к исцелению и +3 к урону от заклинаний", stats = { heal = 8, damageDone = 3 } },
    { slots = "wrist", skill = 145, name = "Enchant Bracer - Lesser Spirit", effect = "+4 к духу", stats = { spi = 4 } },
    { slots = "wrist", skill = 155, name = "Enchant Bracer - Lesser Stamina", effect = "+4 к выносливости", stats = { sta = 4 } },
    { slots = "wrist", skill = 165, name = "Enchant Bracer - Lesser Agility", effect = "+4 к ловкости", stats = { agi = 4 } },
    { slots = "wrist", skill = 165, name = "Enchant Bracer - Lesser Strength", effect = "+4 к силе", stats = { str = 4 } },
    { slots = "wrist", skill = 175, name = "Enchant Bracer - Lesser Intellect", effect = "+5 к интеллекту", stats = { int = 5 } },
    { slots = "wrist", skill = 185, name = "Enchant Bracer - Spirit", effect = "+5 к духу", stats = { spi = 5 } },
    { slots = "wrist", skill = 190, name = "Enchant Bracer - Stamina", effect = "+5 к выносливости", stats = { sta = 5 } },
    { slots = "wrist", skill = 200, name = "Enchant Bracer - Strength", effect = "+5 к силе", stats = { str = 5 } },
    { slots = "wrist", skill = 225, name = "Enchant Bracer - Agility", effect = "+5 к ловкости", stats = { agi = 5 } },
    { slots = "wrist", skill = 225, name = "Enchant Bracer - Lesser Healing Power", effect = "+16 к исцелению и +6 к урону от заклинаний", stats = { heal = 16, damageDone = 6 } },
    { slots = "wrist", skill = 230, name = "Enchant Bracer - Intellect", effect = "+5 к интеллекту", stats = { int = 5 } },
    { slots = "wrist", skill = 240, name = "Enchant Bracer - Greater Spirit", effect = "+7 к духу", stats = { spi = 7 } },
    { slots = "wrist", skill = 255, name = "Enchant Bracer - Deflection", effect = "+7 к защите", stats = { defense = 7 } },
    { slots = "wrist", skill = 260, name = "Enchant Bracer - Greater Agility", effect = "+7 к ловкости", stats = { agi = 7 } },
    { slots = "wrist", skill = 260, name = "Enchant Bracer - Greater Strength", effect = "+7 к силе", stats = { str = 7 } },
    { slots = "wrist", skill = 265, name = "Enchant Bracer - Greater Stamina", effect = "+7 к выносливости", stats = { sta = 7 } },
    { slots = "wrist", skill = 275, name = "Enchant Bracer - Greater Intellect", effect = "+7 к интеллекту", stats = { int = 7 } },
    { slots = "wrist", skill = 290, name = "Enchant Bracer - Superior Spirit", effect = "+9 к духу", stats = { spi = 9 } },
    { slots = "wrist", skill = 310, name = "Enchant Bracer - Mana Regeneration", effect = "+4 маны раз в 5 сек.", stats = { mp5 = 4 } },
    { slots = "wrist", skill = 315, name = "Enchant Bracer - Superior Agility", effect = "+9 к ловкости", stats = { agi = 9 } },
    { slots = "wrist", skill = 315, name = "Enchant Bracer - Superior Strength", effect = "+9 к силе", stats = { str = 9 } },
    { slots = "wrist", skill = 320, name = "Enchant Bracer - Healing Power", effect = "+24 к исцелению и +8 к урону от заклинаний", stats = { heal = 24, damageDone = 8 } },
    { slots = "wrist", skill = 320, name = "Enchant Bracer - Superior Intellect", effect = "+9 к интеллекту", stats = { int = 9 } },
    { slots = "wrist", skill = 320, name = "Enchant Bracer - Superior Stamina", effect = "+9 к выносливости", stats = { sta = 9 } },
    { slots = "wrist", skill = 320, name = "Enchant Bracer - Superior Deflection", effect = "+9 к защите", stats = { defense = 9 } },

    { slots = "chest", skill = 70, name = "Enchant Chest - Inferior Stamina", effect = "+1 к выносливости", stats = { sta = 1 } },
    { slots = "chest", skill = 80, name = "Enchant Chest - Minor Intellect", effect = "+1 к интеллекту", stats = { int = 1 } },
    { slots = "chest", skill = 105, name = "Enchant Chest - Lesser Stamina", effect = "+3 к выносливости", stats = { sta = 3 } },
    { slots = "chest", skill = 115, name = "Enchant Chest - Lesser Intellect", effect = "+3 к интеллекту", stats = { int = 3 } },
    { slots = "chest", skill = 145, name = "Enchant Chest - Stamina", effect = "+4 к выносливости", stats = { sta = 4 } },
    { slots = "chest", skill = 170, name = "Enchant Chest - Intellect", effect = "+4 к интеллекту", stats = { int = 4 } },
    { slots = "chest", skill = 175, name = "Enchant Chest - Minor Stats", effect = "+2 ко всем характеристикам", stats = { str = 2, agi = 2, sta = 2, int = 2, spi = 2 } },
    { slots = "chest", skill = 180, name = "Enchant Chest - Greater Stamina", effect = "+6 к выносливости", stats = { sta = 6 } },
    { slots = "chest", skill = 205, name = "Enchant Chest - Greater Intellect", effect = "+6 к интеллекту", stats = { int = 6 } },
    { slots = "chest", skill = 240, name = "Enchant Chest - Superior Stamina", effect = "+8 к выносливости", stats = { sta = 8 } },
    { slots = "chest", skill = 250, name = "Enchant Chest - Superior Intellect", effect = "+8 к интеллекту", stats = { int = 8 } },
    { slots = "chest", skill = 265, name = "Enchant Chest - Stats", effect = "+3 ко всем характеристикам", stats = { str = 3, agi = 3, sta = 3, int = 3, spi = 3 } },
    { slots = "chest", skill = 295, name = "Enchant Chest - Major Stamina", effect = "+10 к выносливости", stats = { sta = 10 } },
    { slots = "chest", skill = 310, name = "Enchant Chest - Major Intellect", effect = "+10 к интеллекту", stats = { int = 10 } },
    { slots = "chest", skill = 320, name = "Enchant Chest - Greater Stats", effect = "+4 ко всем характеристикам", stats = { str = 4, agi = 4, sta = 4, int = 4, spi = 4 } },

    { slots = "hands", skill = 230, name = "Enchant Gloves - Agility", effect = "+7 к ловкости", stats = { agi = 7 } },
    { slots = "hands", skill = 245, name = "Enchant Gloves - Strength", effect = "+7 к силе", stats = { str = 7 } },
    { slots = "hands", skill = 270, name = "Enchant Gloves - Minor Haste", effect = "+1% к скорости атаки и произнесения заклинаний", stats = { haste = 1 } },
    { slots = "hands", skill = 290, name = "Enchant Gloves - Greater Agility", effect = "+10 к ловкости", stats = { agi = 10 } },
    { slots = "hands", skill = 315, name = "Enchant Gloves - Greater Strength", effect = "+10 к силе", stats = { str = 10 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Superior Agility", effect = "+15 к ловкости", stats = { agi = 15 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Superior Strength", effect = "+15 к силе", stats = { str = 15 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Healing Power", effect = "+35 к исцелению и +12 к урону от заклинаний", stats = { heal = 35, damageDone = 12 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Fire Power", effect = "+20 к урону от заклинаний огня", stats = { spFire = 20 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Frost Power", effect = "+20 к урону от заклинаний льда", stats = { spFrost = 20 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Shadow Power", effect = "+20 к урону от заклинаний тьмы", stats = { spShadow = 20 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Arcane Power", effect = "+20 к урону от заклинаний тайной магии", stats = { spArcane = 20 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Holy Power", effect = "+20 к урону от заклинаний света", stats = { spHoly = 20 } },
    { slots = "hands", skill = 320, name = "Enchant Gloves - Natural Power", effect = "+20 к урону от заклинаний природы", stats = { spNature = 20 } },

    { slots = "feet", skill = 150, name = "Enchant Boots - Minor Agility", effect = "+3 к ловкости", stats = { agi = 3 } },
    { slots = "feet", skill = 150, name = "Enchant Boots - Minor Stamina", effect = "+3 к выносливости", stats = { sta = 3 } },
    { slots = "feet", skill = 180, name = "Enchant Boots - Lesser Agility", effect = "+4 к ловкости", stats = { agi = 4 } },
    { slots = "feet", skill = 190, name = "Enchant Boots - Lesser Stamina", effect = "+4 к выносливости", stats = { sta = 4 } },
    { slots = "feet", skill = 210, name = "Enchant Boots - Lesser Spirit", effect = "+4 к духу", stats = { spi = 4 } },
    { slots = "feet", skill = 235, name = "Enchant Boots - Stamina", effect = "+5 к выносливости", stats = { sta = 5 } },
    { slots = "feet", skill = 245, name = "Enchant Boots - Minor Speed", effect = "Небольшое увеличение скорости передвижения", pace = 3 },
    { slots = "feet", skill = 255, name = "Enchant Boots - Agility", effect = "+5 к ловкости", stats = { agi = 5 } },
    { slots = "feet", skill = 280, name = "Enchant Boots - Greater Stamina", effect = "+7 к выносливости", stats = { sta = 7 } },
    { slots = "feet", skill = 295, name = "Enchant Boots - Spirit", effect = "+5 к духу", stats = { spi = 5 } },
    { slots = "feet", skill = 315, name = "Enchant Boots - Greater Agility", effect = "+7 к ловкости", stats = { agi = 7 } },

    { slots = "cloak", skill = 135, name = "Enchant Cloak - Minor Agility", effect = "+3 к ловкости", stats = { agi = 3 } },
    { slots = "cloak", skill = 175, name = "Enchant Cloak - Defense", effect = "+30 к броне", stats = { armor = 30 } },
    { slots = "cloak", skill = 225, name = "Enchant Cloak - Greater Defense", effect = "+60 к броне", stats = { armor = 60 } },
    { slots = "cloak", skill = 245, name = "Enchant Cloak - Lesser Agility", effect = "+3 к ловкости", stats = { agi = 3 } },
    { slots = "cloak", skill = 305, name = "Enchant Cloak - Superior Defense", effect = "+70 к броне", stats = { armor = 70 } },
    { slots = "cloak", skill = 320, name = "Enchant Cloak - Dodge", effect = "+1% к уклонению", stats = { dodge = 1 } },

    { slots = "neck", skill = 210, name = "Enchant Necklace - Agility", effect = "+5 к ловкости", stats = { agi = 5 } },
    { slots = "neck", skill = 210, name = "Enchant Necklace - Strength", effect = "+5 к силе", stats = { str = 5 } },
    { slots = "neck", skill = 210, name = "Enchant Necklace - Deflection", effect = "+5 к защите", stats = { defense = 5 } },
    { slots = "neck", skill = 210, name = "Enchant Necklace - Healing Power", effect = "+11 к исцелению и +4 к урону от заклинаний", stats = { heal = 11, damageDone = 4 } },
    { slots = "neck", skill = 210, name = "Enchant Necklace - Spell Power", effect = "+6 к урону от заклинаний и исцелению", stats = { sp = 6, heal = 6 } },

    { slots = "shield", skill = 130, name = "Enchant Shield - Minor Stamina", effect = "+3 к выносливости", stats = { sta = 3 } },
    { slots = "shield", skill = 140, name = "Enchant Shield - Lesser Protection", effect = "+30 к броне", stats = { armor = 30 } },
    { slots = "shield", skill = 155, name = "Enchant Shield - Lesser Spirit", effect = "+3 к духу", stats = { spi = 3 } },
    { slots = "shield", skill = 175, name = "Enchant Shield - Lesser Stamina", effect = "+5 к выносливости", stats = { sta = 5 } },
    { slots = "shield", skill = 200, name = "Enchant Shield - Spirit", effect = "+5 к духу", stats = { spi = 5 } },
    { slots = "shield", skill = 230, name = "Enchant Shield - Stamina", effect = "+7 к выносливости", stats = { sta = 7 } },
    { slots = "shield", skill = 250, name = "Enchant Shield - Greater Spirit", effect = "+7 к духу", stats = { spi = 7 } },
    { slots = "shield", skill = 285, name = "Enchant Shield - Greater Stamina", effect = "+9 к выносливости", stats = { sta = 9 } },
    { slots = "shield", skill = 300, name = "Enchant Shield - Superior Spirit", effect = "+9 к духу", stats = { spi = 9 } },

    { slots = "weapon", alsoTwo = true, skill = 120, name = "Enchant Weapon - Minor Striking", effect = "+1 к урону оружия", wpn = 1 },
    { slots = "weapon", alsoTwo = true, skill = 140, name = "Enchant Weapon - Insight", effect = "Шанс при произнесении заклинания: дух повышается на 100% на 10 сек.", roles = { healer = 14 } },
    { slots = "weapon", alsoTwo = true, skill = 140, name = "Enchant Weapon - Revelation", effect = "Шанс, если заклинание не стало критическим: ваше следующее заклинание будет критическим", roles = { caster = 14, healer = 8 } },
    { slots = "weapon", alsoTwo = true, skill = 140, name = "Enchant Weapon - Recovery", effect = "Если ваш удар парирован или от него уклонились: исцеление на 5% от вашего здоровья", roles = { melee = 6, tank = 10 } },
    { slots = "weapon", alsoTwo = true, skill = 165, name = "Enchant Weapon - Lesser Striking", effect = "+2 к урону оружия", wpn = 2 },
    { slots = "weapon", alsoTwo = true, skill = 210, name = "Enchant Weapon - Winter's Might", effect = "+15 к урону от заклинаний льда", stats = { spFrost = 15 } },
    { slots = "weapon", alsoTwo = true, skill = 215, name = "Enchant Weapon - Striking", effect = "+3 к урону оружия", wpn = 3 },
    { slots = "weapon", alsoTwo = true, skill = 265, name = "Enchant Weapon - Greater Striking", effect = "+4 к урону оружия", wpn = 4 },
    { slots = "weapon", alsoTwo = true, skill = 285, name = "Enchant Weapon - Fiery Weapon", effect = "Часто наносит дополнительный урон от огня", roles = { melee = 18, tank = 8 } },
    { slots = "weapon", alsoTwo = true, skill = 280, name = "Enchant Weapon - Grand Crusader", effect = "Часто исцеляет вас и повышает силу", roles = { melee = 42, tank = 34 } },
    { slots = "weapon", alsoTwo = true, skill = 280, name = "Enchant Weapon - Grand Sorcerer", effect = "При попадании заклинанием: восполняет ману и повышает силу заклинаний", roles = { caster = 38 } },
    { slots = "weapon", alsoTwo = true, skill = 310, name = "Enchant Weapon - Agility", effect = "+15 к ловкости", stats = { agi = 15 } },
    { slots = "weapon", alsoTwo = true, skill = 310, name = "Enchant Weapon - Strength", effect = "+15 к силе", stats = { str = 15 } },
    { slots = "weapon", alsoTwo = true, skill = 320, name = "Enchant Weapon - Crusader", effect = "Часто исцеляет вас и повышает силу", roles = { melee = 36, tank = 28 } },
    { slots = "weapon", alsoTwo = true, skill = 320, name = "Enchant Weapon - Lifestealing", effect = "Часто похищает здоровье у противника", roles = { melee = 20, tank = 24 } },
    { slots = "weapon", alsoTwo = true, skill = 320, name = "Enchant Weapon - Healing Power", effect = "+55 к исцелению и +19 к урону от заклинаний", stats = { heal = 55, damageDone = 19 } },
    { slots = "weapon", alsoTwo = true, skill = 320, name = "Enchant Weapon - Spell Power", effect = "+30 к урону от заклинаний", stats = { sp = 30 } },
    { slots = "weapon", alsoTwo = true, skill = 320, name = "Enchant Weapon - Mighty Intellect", effect = "+22 к интеллекту", stats = { int = 22 } },
    { slots = "weapon", alsoTwo = true, skill = 320, name = "Enchant Weapon - Mighty Spirit", effect = "+22 к духу", stats = { spi = 22 } },
    { slots = "weapon", alsoTwo = true, skill = 320, name = "Enchant Weapon - Superior Striking", effect = "+5 к урону оружия", wpn = 5 },

    { slots = "two", skill = 130, name = "Enchant 2H Weapon - Lesser Intellect", effect = "+5 к интеллекту", stats = { int = 5 } },
    { slots = "two", skill = 130, name = "Enchant 2H Weapon - Minor Impact", effect = "+4 к урону оружия", wpn = 4 },
    { slots = "two", skill = 135, name = "Enchant 2H Weapon - Lesser Spirit", effect = "+5 к духу", stats = { spi = 5 } },
    { slots = "two", skill = 170, name = "Enchant 2H Weapon - Lesser Impact", effect = "+5 к урону оружия", wpn = 5 },
    { slots = "two", skill = 220, name = "Enchant 2H Weapon - Impact", effect = "+6 к урону оружия", wpn = 6 },
    { slots = "two", skill = 230, name = "Enchant 2H Weapon - Lesser Agility", effect = "+15 к ловкости", stats = { agi = 15 } },
    { slots = "two", skill = 240, name = "Enchant 2H Weapon - Lesser Strength", effect = "+15 к силе", stats = { str = 15 } },
    { slots = "two", skill = 260, name = "Enchant 2H Weapon - Greater Impact", effect = "+7 к урону оружия", wpn = 7 },
    { slots = "two", skill = 290, name = "Enchant 2H Weapon - Strength", effect = "+25 к силе", stats = { str = 25 } },
    { slots = "two", skill = 310, name = "Enchant 2H Weapon - Agility", effect = "+25 к ловкости", stats = { agi = 25 } },
    { slots = "two", skill = 315, name = "Enchant 2H Weapon - Superior Impact", effect = "+9 к урону оружия", wpn = 9 },
    { slots = "two", skill = 320, name = "Enchant 2H Weapon - Major Intellect", effect = "+9 к интеллекту", stats = { int = 9 } },
    { slots = "two", skill = 320, name = "Enchant 2H Weapon - Major Spirit", effect = "+9 к духу", stats = { spi = 9 } },
    { slots = "two", skill = 320, name = "Enchant 2H Weapon - Mighty Healing Power", effect = "+100 к исцелению и +34 к урону от заклинаний", stats = { heal = 100, damageDone = 34 } },
    { slots = "two", skill = 320, name = "Enchant 2H Weapon - Mighty Spell Power", effect = "+55 к урону от заклинаний и исцелению", stats = { sp = 55, heal = 55 } },

    { slots = { "chest", "hands", "feet", "legs" }, skill = 30, level = 1, name = "Light Armor Kit", effect = "+1 к выносливости и +8 к броне", stats = { sta = 1, armor = 8 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 80, level = 15, name = "Forceful Medium Armor Kit", effect = "+4 к силе атаки и +16 к броне", stats = { ap = 4, armor = 16 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 80, level = 15, name = "Mystic Medium Armor Kit", effect = "+2 к силе заклинаний и +16 к броне", stats = { sp = 2, armor = 16 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 90, level = 5, name = "Medium Armor Kit", effect = "+2 к выносливости и +16 к броне", stats = { sta = 2, armor = 16 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 145, level = 20, minIlvl = 15, name = "Heavy Armor Kit", effect = "+3 к выносливости и +24 к броне", stats = { sta = 3, armor = 24 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 155, level = 30, minIlvl = 15, name = "Forceful Heavy Armor Kit", effect = "+6 к силе атаки и +24 к броне", stats = { ap = 6, armor = 24 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 155, level = 30, minIlvl = 15, name = "Mystic Heavy Armor Kit", effect = "+4 к силе заклинаний и +24 к броне", stats = { sp = 4, armor = 24 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 195, level = 30, minIlvl = 25, name = "Thick Armor Kit", effect = "+4 к выносливости и +32 к броне", stats = { sta = 4, armor = 32 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 205, level = 40, minIlvl = 25, name = "Forceful Thick Armor Kit", effect = "+8 к силе атаки и +32 к броне", stats = { ap = 8, armor = 32 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 205, level = 40, minIlvl = 25, name = "Mystic Thick Armor Kit", effect = "+5 к силе заклинаний и +32 к броне", stats = { sp = 5, armor = 32 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 225, level = 40, minIlvl = 35, name = "Rugged Armor Kit", effect = "+5 к выносливости и +40 к броне", stats = { sta = 5, armor = 40 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 235, level = 50, minIlvl = 35, name = "Forceful Rugged Armor Kit", effect = "+10 к силе атаки и +40 к броне", stats = { ap = 10, armor = 40 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 235, level = 50, minIlvl = 35, name = "Mystic Rugged Armor Kit", effect = "+6 к силе заклинаний и +40 к броне", stats = { sp = 6, armor = 40 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 300, level = 50, name = "Core Armor Kit", effect = "+3 к защите", stats = { defense = 3 } },
    { slots = { "chest", "hands", "feet", "legs" }, skill = 300, level = 60, name = "Wild Leather Armor Kit", effect = "+10 к выносливости и +4 к защите", stats = { sta = 10, defense = 4 } },

    { slots = "ranged", skill = 30, level = 5, name = "Crude Scope", effect = "+1 к урону оружия дальнего боя", rng = 1 },
    { slots = "ranged", skill = 90, level = 10, name = "Standard Scope", effect = "+2 к урону оружия дальнего боя", rng = 2 },
    { slots = "ranged", skill = 180, level = 20, name = "Accurate Scope", effect = "+3 к урону оружия дальнего боя", rng = 3 },
    { slots = "ranged", skill = 210, level = 30, name = "Deadly Scope", effect = "+5 к урону оружия дальнего боя", rng = 5 },
    { slots = "ranged", skill = 240, level = 40, name = "Sniper Scope", effect = "+7 к урону оружия дальнего боя", rng = 7 },
}

-- Recipe spell of each row: the Enchanting (333), Leatherworking (165) or
-- Engineering (202) spell with exactly this English name in the WoW Forever
-- client's SpellName and SkillLineAbility tables (build 1.60.1.70790). The
-- client names the spell in its own language, so a Russian client shows the
-- name from its profession window. Display only: row.name stays the key.
local SPELL_BY_NAME = {
    ["Enchant Bracer - Inferior Stamina"] = 7418,
    ["Enchant Bracer - Minor Stamina"] = 7457,
    ["Enchant Bracer - Minor Spirit"] = 7766,
    ["Enchant Bracer - Minor Intellect"] = 1248458,
    ["Enchant Bracer - Minor Agility"] = 7779,
    ["Enchant Bracer - Minor Strength"] = 7782,
    ["Enchant Bracer - Minor Healing Power"] = 1248459,
    ["Enchant Bracer - Lesser Spirit"] = 7859,
    ["Enchant Bracer - Lesser Stamina"] = 13501,
    ["Enchant Bracer - Lesser Agility"] = 1248460,
    ["Enchant Bracer - Lesser Strength"] = 13536,
    ["Enchant Bracer - Lesser Intellect"] = 13622,
    ["Enchant Bracer - Spirit"] = 13642,
    ["Enchant Bracer - Stamina"] = 13648,
    ["Enchant Bracer - Strength"] = 13661,
    ["Enchant Bracer - Agility"] = 1248497,
    ["Enchant Bracer - Lesser Healing Power"] = 1248498,
    ["Enchant Bracer - Intellect"] = 13822,
    ["Enchant Bracer - Greater Spirit"] = 13846,
    ["Enchant Bracer - Deflection"] = 13931,
    ["Enchant Bracer - Greater Agility"] = 1248500,
    ["Enchant Bracer - Greater Strength"] = 13939,
    ["Enchant Bracer - Greater Stamina"] = 13945,
    ["Enchant Bracer - Greater Intellect"] = 20008,
    ["Enchant Bracer - Superior Spirit"] = 20009,
    ["Enchant Bracer - Mana Regeneration"] = 23801,
    ["Enchant Bracer - Superior Agility"] = 1248599,
    ["Enchant Bracer - Superior Strength"] = 20010,
    ["Enchant Bracer - Healing Power"] = 23802,
    ["Enchant Bracer - Superior Intellect"] = 1248661,
    ["Enchant Bracer - Superior Stamina"] = 20011,
    ["Enchant Bracer - Superior Deflection"] = 1248665,
    ["Enchant Chest - Inferior Stamina"] = 7420,
    ["Enchant Chest - Minor Intellect"] = 7443,
    ["Enchant Chest - Lesser Stamina"] = 7748,
    ["Enchant Chest - Lesser Intellect"] = 7776,
    ["Enchant Chest - Stamina"] = 7857,
    ["Enchant Chest - Intellect"] = 13607,
    ["Enchant Chest - Minor Stats"] = 13626,
    ["Enchant Chest - Greater Stamina"] = 13640,
    ["Enchant Chest - Greater Intellect"] = 13663,
    ["Enchant Chest - Superior Stamina"] = 13858,
    ["Enchant Chest - Superior Intellect"] = 13917,
    ["Enchant Chest - Stats"] = 13941,
    ["Enchant Chest - Major Stamina"] = 20026,
    ["Enchant Chest - Major Intellect"] = 20028,
    ["Enchant Chest - Greater Stats"] = 20025,
    ["Enchant Gloves - Agility"] = 13815,
    ["Enchant Gloves - Strength"] = 13887,
    ["Enchant Gloves - Minor Haste"] = 13948,
    ["Enchant Gloves - Greater Agility"] = 20012,
    ["Enchant Gloves - Greater Strength"] = 20013,
    ["Enchant Gloves - Superior Agility"] = 25080,
    ["Enchant Gloves - Superior Strength"] = 1248640,
    ["Enchant Gloves - Healing Power"] = 25079,
    ["Enchant Gloves - Fire Power"] = 25078,
    ["Enchant Gloves - Frost Power"] = 25074,
    ["Enchant Gloves - Shadow Power"] = 25073,
    ["Enchant Gloves - Arcane Power"] = 1213626,
    ["Enchant Gloves - Holy Power"] = 1213622,
    ["Enchant Gloves - Natural Power"] = 1248645,
    ["Enchant Boots - Minor Agility"] = 7867,
    ["Enchant Boots - Minor Stamina"] = 7863,
    ["Enchant Boots - Lesser Agility"] = 13637,
    ["Enchant Boots - Lesser Stamina"] = 13644,
    ["Enchant Boots - Lesser Spirit"] = 13687,
    ["Enchant Boots - Stamina"] = 13836,
    ["Enchant Boots - Minor Speed"] = 13890,
    ["Enchant Boots - Agility"] = 13935,
    ["Enchant Boots - Greater Stamina"] = 20020,
    ["Enchant Boots - Spirit"] = 20024,
    ["Enchant Boots - Greater Agility"] = 20023,
    ["Enchant Cloak - Minor Agility"] = 13419,
    ["Enchant Cloak - Defense"] = 13635,
    ["Enchant Cloak - Greater Defense"] = 13746,
    ["Enchant Cloak - Lesser Agility"] = 13882,
    ["Enchant Cloak - Superior Defense"] = 20015,
    ["Enchant Cloak - Dodge"] = 25086,
    ["Enchant Necklace - Agility"] = 1249059,
    ["Enchant Necklace - Strength"] = 1249019,
    ["Enchant Necklace - Deflection"] = 1249060,
    ["Enchant Necklace - Healing Power"] = 1249058,
    ["Enchant Necklace - Spell Power"] = 1249057,
    ["Enchant Shield - Minor Stamina"] = 13378,
    ["Enchant Shield - Lesser Protection"] = 13464,
    ["Enchant Shield - Lesser Spirit"] = 13485,
    ["Enchant Shield - Lesser Stamina"] = 13631,
    ["Enchant Shield - Spirit"] = 13659,
    ["Enchant Shield - Stamina"] = 13817,
    ["Enchant Shield - Greater Spirit"] = 13905,
    ["Enchant Shield - Greater Stamina"] = 20017,
    ["Enchant Shield - Superior Spirit"] = 20016,
    ["Enchant Weapon - Minor Striking"] = 7788,
    ["Enchant Weapon - Insight"] = 1248757,
    ["Enchant Weapon - Revelation"] = 1248805,
    ["Enchant Weapon - Recovery"] = 1248760,
    ["Enchant Weapon - Lesser Striking"] = 13503,
    ["Enchant Weapon - Winter's Might"] = 21931,
    ["Enchant Weapon - Striking"] = 13693,
    ["Enchant Weapon - Greater Striking"] = 13943,
    ["Enchant Weapon - Fiery Weapon"] = 13898,
    ["Enchant Weapon - Grand Crusader"] = 1231128,
    ["Enchant Weapon - Grand Sorcerer"] = 1231164,
    ["Enchant Weapon - Agility"] = 23800,
    ["Enchant Weapon - Strength"] = 23799,
    ["Enchant Weapon - Crusader"] = 20034,
    ["Enchant Weapon - Lifestealing"] = 20032,
    ["Enchant Weapon - Healing Power"] = 22750,
    ["Enchant Weapon - Spell Power"] = 22749,
    ["Enchant Weapon - Mighty Intellect"] = 23804,
    ["Enchant Weapon - Mighty Spirit"] = 23803,
    ["Enchant Weapon - Superior Striking"] = 20031,
    ["Enchant 2H Weapon - Lesser Intellect"] = 7793,
    ["Enchant 2H Weapon - Minor Impact"] = 7745,
    ["Enchant 2H Weapon - Lesser Spirit"] = 13380,
    ["Enchant 2H Weapon - Lesser Impact"] = 13529,
    ["Enchant 2H Weapon - Impact"] = 13695,
    ["Enchant 2H Weapon - Lesser Agility"] = 1248510,
    ["Enchant 2H Weapon - Lesser Strength"] = 1248511,
    ["Enchant 2H Weapon - Greater Impact"] = 13937,
    ["Enchant 2H Weapon - Strength"] = 1248668,
    ["Enchant 2H Weapon - Agility"] = 27837,
    ["Enchant 2H Weapon - Superior Impact"] = 20030,
    ["Enchant 2H Weapon - Major Intellect"] = 20036,
    ["Enchant 2H Weapon - Major Spirit"] = 20035,
    ["Enchant 2H Weapon - Mighty Healing Power"] = 1248636,
    ["Enchant 2H Weapon - Mighty Spell Power"] = 1248607,
    ["Light Armor Kit"] = 2152,
    ["Forceful Medium Armor Kit"] = 1255123,
    ["Mystic Medium Armor Kit"] = 1255124,
    ["Medium Armor Kit"] = 2165,
    ["Heavy Armor Kit"] = 3780,
    ["Forceful Heavy Armor Kit"] = 1255095,
    ["Mystic Heavy Armor Kit"] = 1255096,
    ["Thick Armor Kit"] = 10487,
    ["Forceful Thick Armor Kit"] = 1255073,
    ["Mystic Thick Armor Kit"] = 1255074,
    ["Rugged Armor Kit"] = 19058,
    ["Forceful Rugged Armor Kit"] = 1254965,
    ["Mystic Rugged Armor Kit"] = 1254966,
    ["Core Armor Kit"] = 22727,
    ["Wild Leather Armor Kit"] = 1306532,
    ["Crude Scope"] = 3977,
    ["Standard Scope"] = 3978,
    ["Accurate Scope"] = 3979,
    ["Deadly Scope"] = 12597,
    ["Sniper Scope"] = 12620,
}

local spellNameCache = {}

-- The client's own name of a spell id, nil when it has none.
local function ClientSpellName(spellId)
    if not spellId then
        return nil
    end
    local cached = spellNameCache[spellId]
    if cached then
        return cached
    end
    local name
    if C_Spell and C_Spell.GetSpellName then
        local ok, n = pcall(C_Spell.GetSpellName, spellId)
        if ok then
            name = n
        end
    end
    if name == nil and type(GetSpellInfo) == "function" then
        local ok, n = pcall(GetSpellInfo, spellId)
        if ok then
            name = n
        end
    end
    if GQ.PublicText then
        name = GQ.PublicText(name)
    end
    if type(name) ~= "string" or name == "" then
        return nil
    end
    spellNameCache[spellId] = name
    return name
end

-- Name shown for a row: a GQ.L10N translation when there is one, else the
-- client's spell name, else the English name.
local function RowDisplayName(row)
    local name = row.name
    local L10N = GQ.L10N
    if L10N and L10N.Text then
        local ok, text = pcall(L10N.Text, L10N, name)
        if ok and type(text) == "string" and text ~= "" and text ~= name then
            return text
        end
    end
    return ClientSpellName(SPELL_BY_NAME[name]) or name
end

local function SkillNeed(skill)
    skill = skill or 1
    -- A formula learned at 300 turns yellow a little later.
    if skill > 300 then
        return 300
    end
    return skill
end

local function SkillCap(level)
    if level < 10 then
        return 75
    end
    if level < 20 then
        return 150
    end
    if level < 35 then
        return 225
    end
    return 300
end

local function ItemIdOf(entry, link)
    local id = entry and entry.itemId
    if not id and link and GQ.Data and GQ.Data.ItemLinkToId then
        id = GQ.Data:ItemLinkToId(link)
    end
    return tonumber(id)
end

-- GetItemInfo on an id the client has not loaded asks for it. A hover down
-- the hunt list would request every piece and hitch when the answers land.
local function ItemIsCached(id)
    if not id then
        return false
    end
    if C_Item and C_Item.IsItemDataCachedByID then
        return C_Item.IsItemDataCachedByID(id) == true
    end
    if GQ.Equip and GQ.Equip.IsItemDataCached then
        return GQ.Equip:IsItemDataCached(id) == true
    end
    return false
end

-- Classic item class 2 is a weapon. These subclass ids are bows, guns, and crossbows.
local SCOPE_SUBCLASS = { [2] = true, [3] = true, [18] = true }
-- Thrown weapons, wands, and fishing poles take no enchant.
local BARE_SUBCLASS = { [16] = true, [19] = true, [20] = true }

local function InstantSlot(idOrLink)
    if type(GetItemInfoInstant) ~= "function" or not idOrLink then
        return nil, nil
    end
    local ok, _, _, subType, equipLoc, _, classID, subClassID = pcall(GetItemInfoInstant, idOrLink)
    if not ok then
        return nil, nil
    end
    return subType, equipLoc, classID, subClassID
end

-- subType is in the client's language, so the ids decide whenever the client
-- gave them. The English names are only for a client that gave no ids.
local function IsScopeWeapon(subType, classID, subClassID)
    if type(classID) == "number" then
        return classID == 2 and SCOPE_SUBCLASS[subClassID] == true
    end
    return subType == "Bow" or subType == "Bows"
        or subType == "Gun" or subType == "Guns"
        or subType == "Crossbow" or subType == "Crossbows"
end

local function IsBareWeapon(subType, classID, subClassID)
    if type(classID) == "number" then
        return classID == 2 and BARE_SUBCLASS[subClassID] == true
    end
    return subType == "Fishing Pole" or subType == "Fishing Poles"
        or subType == "Wand" or subType == "Wands"
        or subType == "Thrown"
end

local function ItemLevelOf(entry, link)
    local id = ItemIdOf(entry, link)
    if id and ItemIsCached(id) and GetItemInfo then
        local _, _, _, ilvl = GetItemInfo(id)
        if type(ilvl) == "number" and ilvl > 1 then
            return ilvl
        end
    end
    if id and GQ.Data and GQ.Data.GetItemFact then
        local fact = GQ.Data:GetItemFact(id)
        local stored = fact and tonumber(fact.ilvl)
        if stored and stored > 1 then
            return stored
        end
    end
end

local function Fits(row, slotKey)
    local slots = row.slots
    if slots == slotKey then
        return true
    end
    if type(slots) == "table" then
        for i = 1, #slots do
            if slots[i] == slotKey then
                return true
            end
        end
    end
    if slotKey == "two" and row.slots == "weapon" and row.alsoTwo then
        return true
    end
    return false
end

function GQ.Enchant:Enabled()
    local settings = GearQuestForeverDB and GearQuestForeverDB.settings
    return settings and settings.showGearEnchant and true or false
end

function GQ.Enchant:ProfessionRank(name)
    if not name or not GQ.Log or not GQ.Log.PlayerProfessionRanks then
        return 0
    end
    local ranks = GQ.Log:PlayerProfessionRanks()
    if type(ranks) ~= "table" then
        return 0
    end
    local want = string.lower(name)
    for prof, rank in pairs(ranks) do
        if type(prof) == "string" and string.lower(prof) == want then
            return tonumber(rank) or 0
        end
    end
    return 0
end

function GQ.Enchant:Weights()
    local classFile = GQ.GetEffectiveClass and GQ:GetEffectiveClass()
    local specId = GQ.GetEffectiveSpec and GQ:GetEffectiveSpec()
    local level = GQ.GetEffectiveLevel and GQ:GetEffectiveLevel() or 1
    if not classFile or not specId then
        return nil
    end
    local custom = GQ.Custom and GQ.Custom.Get and GQ.Custom:Get(classFile, specId)
    if custom and GQ.Custom.Weights then
        local weights, dps, dpsRanged = GQ.Custom:Weights(classFile, custom, level)
        return weights, dps or 0, dpsRanged or 0, level, classFile, specId
    end
    local classTable = GQ.ScoringWeights and GQ.ScoringWeights[classFile]
    local specRow = classTable and classTable[specId]
    if not specRow or not specRow.weights then
        return nil
    end
    local leveling = GQ.ScoringLeveling
    local useLeveling = leveling and level <= (leveling.untilLevel or 60)
    local weights = {}
    for key, raw in pairs(specRow.weights) do
        local mult = 1
        if useLeveling and leveling[key] then
            mult = leveling[key]
        end
        weights[key] = raw * mult
    end
    if specId == "enhancement_tank" then
        local armorMult = (useLeveling and leveling and leveling.armor) or 1
        local armorW = (specRow.weights.armor or 0) * armorMult
        weights.agi = (weights.agi or 0) + 2 * armorW + (specRow.weights.dodge or 0) / 20 + (specRow.weights.crit or 0) / 20
    end
    return weights, specRow.dpsWeight or 0, specRow.dpsWeightRanged or 0, level, classFile, specId
end

function GQ.Enchant:Score(row, weights, dps, dpsRanged, role)
    local score = row.pace or 0
    if row.roles and role and row.roles[role] then
        score = score + row.roles[role]
    end
    if row.wpn then
        score = score + (dps or 0) * row.wpn / 2.8
    end
    if row.rng then
        score = score + (dpsRanged or 0) * row.rng / 2.8
    end
    local stats = row.stats
    if stats then
        for key, amount in pairs(stats) do
            if key ~= "heal" and key ~= "damageDone" then
                if key ~= "armor" or role == "tank" then
                    score = score + (weights[key] or 0) * amount
                end
            end
        end
        if stats.heal then
            score = score + (weights.heal or 0) * stats.heal
        end
        if stats.damageDone then
            score = score + (weights.sp or 0) * stats.damageDone
        end
    end
    return score
end

function GQ.Enchant:SlotKey(entry, link)
    local id = ItemIdOf(entry, link)
    local subType, equipLoc, classID, subClassID = InstantSlot(id or link)
    if (not equipLoc or equipLoc == "") and id and ItemIsCached(id) and GetItemInfo then
        local name, _, _, _, _, _, knownSub, _, knownLoc, _, _, knownClass, knownSubclass = GetItemInfo(id)
        if name then
            subType = knownSub
            equipLoc = knownLoc
            if type(knownClass) == "number" then
                classID = knownClass
                subClassID = knownSubclass
            end
        end
    end
    if IsBareWeapon(subType, classID, subClassID) or equipLoc == "INVTYPE_THROWN" then
        return nil
    end
    if equipLoc == "INVTYPE_WRIST" then return "wrist" end
    if equipLoc == "INVTYPE_CHEST" or equipLoc == "INVTYPE_ROBE" then return "chest" end
    if equipLoc == "INVTYPE_HAND" then return "hands" end
    if equipLoc == "INVTYPE_FEET" then return "feet" end
    if equipLoc == "INVTYPE_LEGS" then return "legs" end
    if equipLoc == "INVTYPE_CLOAK" then return "cloak" end
    if equipLoc == "INVTYPE_NECK" then return "neck" end
    if equipLoc == "INVTYPE_SHIELD" then return "shield" end
    if equipLoc == "INVTYPE_HOLDABLE" then return "offhand" end
    if equipLoc == "INVTYPE_2HWEAPON" then return "two" end
    if equipLoc == "INVTYPE_WEAPON" or equipLoc == "INVTYPE_WEAPONMAINHAND" or equipLoc == "INVTYPE_WEAPONOFFHAND" then
        return "weapon"
    end
    if equipLoc == "INVTYPE_RANGED" or equipLoc == "INVTYPE_RANGEDRIGHT" then
        if IsScopeWeapon(subType, classID, subClassID) then
            return "ranged"
        end
        -- A named type that is not a bow, gun, or crossbow stays bare.
        -- An unread type falls through to the hunt row.
        if subType and subType ~= "" then
            return nil
        end
    end
    if not entry then
        return nil
    end
    local slot = entry.slot
    if GQ.Data and GQ.Data.NormalizeSlotName then
        slot = GQ.Data:NormalizeSlotName(slot)
    end
    if entry.hand == "two" or slot == "TwoHand" then
        return "two"
    end
    if slot == "MainHand" then
        return "weapon"
    end
    if slot == "SecondaryHand" or slot == "OffHand" then
        local kind = entry.kind
        if kind == "Shield" or kind == "Buckler" then
            return "shield"
        end
        if entry.hand == "off" or entry.hand == "one" or kind == "Dagger" or kind == "Sword1H" or kind == "Mace1H" or kind == "Axe1H" or kind == "Fist" then
            return "weapon"
        end
        return "offhand"
    end
    if slot == "Wrist" then return "wrist" end
    if slot == "Chest" then return "chest" end
    if slot == "Hands" then return "hands" end
    if slot == "Feet" then return "feet" end
    if slot == "Legs" then return "legs" end
    if slot == "Back" then return "cloak" end
    if slot == "Neck" then return "neck" end
    if slot == "Ranged" then
        if entry.kind == "Wand" or entry.kind == "Thrown" then
            return nil
        end
        -- Hunt rows do not store the weapon type. A wand or a thrown weapon
        -- shares this slot, and a scope does not go on either.
        if GQ.Data.RangedTypeOf then
            local kind = GQ.Data:RangedTypeOf(entry)
            if kind == "Bow" or kind == "Gun" or kind == "Crossbow" then
                return "ranged"
            end
        end
        return nil
    end
    return nil
end

function GQ.Enchant:Usable(row, level, ilvl)
    if row.level and level < row.level then
        return false
    end
    if row.minIlvl and (not ilvl or ilvl < row.minIlvl) then
        return false
    end
    local need = SkillNeed(row.skill)
    -- wear: the enchant only functions if this character has that profession.
    -- prof: the character makes it themselves, such as an armor kit.
    local prof = row.wear or row.prof
    if prof then
        return self:ProfessionRank(prof) >= need
    end
    return need <= SkillCap(level)
end

function GQ.Enchant:Text(link, entry)
    if not self:Enabled() then
        return nil
    end
    local weights, dps, dpsRanged, level, classFile, specId = self:Weights()
    if not weights then
        return nil
    end
    local slotKey = self:SlotKey(entry, link)
    if not slotKey then
        return nil
    end
    local classRoles = ROLE[classFile]
    local role = classRoles and classRoles[specId]
    local ilvl = ItemLevelOf(entry, link)
    local best, bestScore
    for i = 1, #ROWS do
        local row = ROWS[i]
        if Fits(row, slotKey) and self:Usable(row, level or 1, ilvl) then
            local score = self:Score(row, weights, dps, dpsRanged, role)
            if not best or score > bestScore or (score == bestScore and row.skill > best.skill) then
                best = row
                bestScore = score
            end
        end
    end
    if not best or not bestScore or bestScore <= 0 then
        return nil
    end
    return string.format("|cffffff00Рекомендуемые чары|r|cffffffff: %s - %s|r", RowDisplayName(best), best.effect)
end

function GQ.Enchant:Add(tooltip, link, entry)
    if not tooltip or not tooltip.AddLine or tooltip.gqEnchantAdded then
        return false
    end
    local text = self:Text(link, entry)
    if not text then
        return false
    end
    tooltip.gqEnchantAdded = true
    tooltip:AddLine(text, 1, 1, 1)
    return true
end
