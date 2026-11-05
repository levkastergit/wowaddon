local ADDON_NAME, GQ = ...

GQ.PortraitGuide = GQ.PortraitGuide or {}

local GUIDE = GQ.PortraitGuide

-- The automatic intro is once for the whole account. The portrait can start it again.
local GUIDE_VERSION = 8
local GUIDE_NAME = "Рыцарь GearQuest"

-- The counter is the length of this list. Add a page here, and a matching
-- sound in Sounds/, when the next line is ready.
-- QuestFont has one weight. Black ink is the bold the parchment can show.
local function Bold(text)
    return "|cff000000" .. text .. "|r"
end

local INFO_ICON = "|TInterface\\FriendsFrame\\InformationIcon:14:14|t"

local PAGES = {
    {
        text = "Приветствую, искатель приключений!\n\n"
            .. "Всю свою жизнь я странствовал по землям Azeroth и нашёл кучу отличного снаряжения! Кхм... Я готов поделиться с вами одной-двумя целями... А, была не была... Поделюсь всеми!\n\n"
            .. "Итак, вы готовы отправиться в поход за снаряжением? Погодите... Как-то не так прозвучало, попробуем ещё разок.\n\n"
            .. Bold("ВЫ ГОТОВЫ ОТПРАВИТЬСЯ В GEAR QUEST?"),
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-05.mp3",
        highlight = "log",
    },
    {
        text = "Что ж, начнём.\n\n"
            .. "Это " .. Bold("Журнал GearQuest") .. ". Здесь вы найдёте " .. Bold("список") .. " " .. Bold("активных") .. " целей, целей, которые вы " .. Bold("выполнили") .. ", и целей, которые вам не понравились, так что вы их " .. Bold("убрали") .. "... Не знаю, зачем так делать, но...\n\n"
            .. Bold("Журнал") .. " показывает лучшее снаряжение для вашей текущей фракции, специализации и, конечно же, уровня. По умолчанию в " .. Bold("списке") .. " для каждого слота показаны " .. Bold("3 лучших") .. " предмета из рейтинга — их также можно увидеть, щёлкнув правой кнопкой мыши по слоту в окне персонажа.",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-06.mp3",
        highlight = { "log", "list" },
    },
    {
        text = "В GearQuest собрано очень много снаряжения, поэтому он может предложить вам подходящие варианты, даже когда вы применяете фильтры.\n\n"
            .. "Все варианты из рейтинга для вашего текущего уровня можно увидеть, наведя курсор на " .. Bold("значок информации " .. INFO_ICON) .. " рядом с названием каждого слота.\n\n"
            .. "А с помощью " .. Bold("ползунка") .. " прямо под этим списком можно настроить, сколько вариантов показывать для каждого слота.",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-07.mp3",
        highlight = { "log", "info", "slider" },
    },
    {
        text = Bold("Фильтр") .. " позволяет, ну... фильтровать. Так что если вы хотите видеть в списке только цели из подземелья этого мерзавца Van Cleef, это можно сделать, как и многое другое.\n\n"
            .. "Если прокрутить список почти до самого низа, у раздела " .. Bold("Оружие") .. " тоже есть фильтр.\n\n"
            .. "И наконец, есть " .. Bold("стили игры") .. " — что-то вроде сочетания разных фильтров. Например, " .. Bold("«Фокус на зоне»") .. " оставляет в списке только цели, доступные в зоне, где вы сейчас находитесь, а " .. Bold("«Без подземелий!»") .. " никогда не поведёт вас в подземелье.",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-08.mp3",
        highlight = { "log", "filter", "weapons", "playstyle" },
    },
    {
        text = "Хорошо, теперь попробуйте выбрать любую цель из списка.\n\n"
            .. "После этого в разделе на " .. Bold("пергаменте") .. " появятся подробности о цели: " .. Bold("место") .. " снаряжения в рейтинге, где его добыть, все предварительные условия или рекомендации о том, что от вас потребуется, а также " .. Bold("источник") .. " снаряжения (по нему тоже можно фильтровать) и, наконец, " .. Bold("награда") .. " — тот самый отличный предмет снаряжения.\n\n"
            .. "И кстати, когда вы получаете один из лучших предметов рейтинга на любом уровне, появляется окно «Получено», похожее на уведомление о достижении!",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-09.mp3",
        highlight = { "log", "detail" },
    },
    {
        text = "Внизу этого раздела есть 3 кнопки.\n\n"
            .. Bold("Отслеживать") .. " добавляет эту цель в трекер GearQuest, а также ставит значок на карте мира, чтобы было видно, куда идти. Кроме того, в трекере можно отметить " .. Bold("Проводник") .. " — тогда над трекером появится стрелка, которая приведёт вас к цели. Если вы на другом континенте, сначала она приведёт вас к ближайшему кораблю или дирижаблю.\n\n"
            .. Bold("На карте") .. " не добавляет значок, а сразу показывает, где находится цель, и включает " .. Bold("стрелку проводника") .. ".\n\n"
            .. Bold("Убрать") .. " просто, ну... убирает цель, чтобы вы её больше не видели. Вернуть её можно в любой момент на вкладке " .. Bold("Убранные") .. ".",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-10.mp3",
        highlight = { "log", "track", "map", "remove", "removed" },
    },
    {
        text = Bold("Индекс GearQuest") .. " показывает, насколько хорошо вы экипированы для выбранной специализации.\n\n"
            .. "Если навести курсор на " .. Bold("шкалу оценки") .. ", появится список надетого снаряжения и оценка каждого предмета. Каждый предмет снаряжения оценивается и ранжируется по весам характеристик вашей текущей специализации.\n\n"
            .. "В " .. Bold("выборе специализации") .. " чуть ниже можно попробовать сменить специализацию, и " .. Bold("шкала оценки") .. " обновится по списку снаряжения этой специализации.\n\n"
            .. "Кстати, в режиме симуляции это не работает.",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-11.mp3",
        highlight = { "log", "score", "spec" },
    },
    {
        text = "Когда " .. Bold("специализация") .. " выбрана, можно навести курсор на название " .. Bold("специализации") .. ", чтобы увидеть, по каким " .. Bold("весам характеристик") .. " она оценивается.\n\n"
            .. "Так что если вы один из тех охотников, что обожают снаряжение, вам обычно нужно что-нибудь с " .. Bold("ловкостью") .. ", или с исцелением, или, может, щит? Нет, а если серьёзно, вы должны увидеть, что вес " .. Bold("ловкости") .. " выше, чем, например, у " .. Bold("духа") .. ".\n\n"
            .. "Если вы не согласны с " .. Bold("весами характеристик") .. " какой-либо из готовых специализаций, можете оставить отзыв или просто... не заморачиваться и создать " .. Bold("свою специализацию") .. " с собственными весами характеристик.",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-12.mp3",
        highlight = { "log", "spec" },
    },
    {
        text = "Так, осталось всего несколько моментов, а потом можете бежать начищать морду Hogger... кхм.\n\n"
            .. "Перейдём на вкладку " .. Bold("Поиск") .. ". Здесь можно искать в моей базе всё снаряжение, что попадалось мне за долгие годы, так что попробуйте выполнить " .. Bold("поиск") .. " по чему-нибудь для вашего класса.\n\n"
            .. "Найдя предмет, наведите курсор на " .. Bold("значок информации " .. INFO_ICON) .. ", чтобы увидеть, когда этот предмет подходит специализациям вашего класса.\n\n"
            .. "Если вы не нашли то, что искали, попробуйте " .. Bold("симулировать") .. " класс, которому этот предмет подходит.",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-13.mp3",
        tab = "lookup",
        highlight = { "lookup", "search" },
    },
    {
        text = "Раз уж я о нём уже несколько раз упоминал, давайте взглянем на " .. Bold("Симулятор") .. ".\n\n"
            .. "Он позволяет " .. Bold("симулировать") .. " любой " .. Bold("класс") .. ", " .. Bold("специализацию") .. " и " .. Bold("уровень") .. " — за обе фракции.\n\n"
            .. "Так что... если хотите посмотреть, как выглядит список снаряжения для " .. Bold("воина") .. " " .. Bold("Альянса") .. " " .. Bold("37-го уровня") .. " — вроде меня, — то " .. Bold("Симулятор") .. " для вас!",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-14.mp3",
        tab = "simulator",
        highlight = { "simulator", "warrior", "alliance", "arms", "level", "simulate" },
    },
    {
        text = "Хорошо, последнее. Хочу упомянуть " .. Bold("Настройки") .. ", потому что одним искателям приключений не нравится " .. Bold("кнопка у миникарты") .. ", другие хотят видеть " .. Bold("лучшие чары") .. " в подсказке к снаряжению, и так далее.\n\n"
            .. "Так что загляните в разные настройки, чтобы ваше путешествие стало приятнее.\n\n"
            .. "Ах да, и привет потрясающему сообществу GearQuest в Discord? Не знаю, что значила эта последняя фраза, один парень просто попросил меня её зачитать.",
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-15.mp3",
        tab = "settings",
        highlight = { "settings", "minimap", "enchant" },
    },
    {
        text = "Ну что... Чего же вы ждёте?\n\n"
            .. "Да начнётся " .. Bold("Gear Quest... Forever!"),
        sound = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Sounds\\Guide-16.mp3",
        tab = "any",
        highlight = "frame",
    },
}

-- The side handles stay on screen on every page, so their glow does too.
local HANDLE_MARK = {
    log = true,
    lookup = true,
    simulator = true,
    settings = true,
}

for i = 1, #PAGES do
    local page = PAGES[i]
    local highlight = page.highlight
    if highlight == "frame" then
        page.whole = true
    elseif type(highlight) == "string" then
        page.marks = { highlight }
    else
        page.marks = highlight
    end
end

local PARCHMENT = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-GuideParchment.png"
local TAIL = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-GuideTail.png"
local VOICE_1 = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-GuideVoice1.png"
local VOICE_2 = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-GuideVoice2.png"
local VOICE_3 = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-GuideVoice3.png"
local VOICE_OFF = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\GQ-GuideVoiceOff.png"

local BUBBLE_W = 430

local PORTRAIT_OFFSET_X = -6
local PORTRAIT_OFFSET_Y = 7
local PORTRAIT_SIZE = 61

-- The tail hangs under the left of the parchment. Its tip sits just above the portrait.
local TAIL_W = 48
local TAIL_H = 30
local TAIL_OVERLAP = 11
local TAIL_CENTER_X = 42
local TIP_GAP = 4

local OPEN_DELAY = 5
local FADE_IN = 0.6

local function UI()
    GearQuestForeverDB = GearQuestForeverDB or {}
    GearQuestForeverDB.ui = GearQuestForeverDB.ui or {}
    return GearQuestForeverDB.ui
end

function GUIDE:Onboarded()
    return UI().portraitGuideIntro and true or false
end

function GUIDE:MarkOnboarded()
    UI().portraitGuideIntro = true
end

function GUIDE:VoiceOn()
    return UI().portraitGuideVoice ~= false
end

-- The takes already peak near full, so a live gain would clip the shout.
-- Each step is a separate file: the original, then two limited boosts.
local VOLUME_MAX = 3

function GUIDE:VolumeStep()
    local n = UI().portraitGuideVolume
    if n == nil then
        return 2
    end
    n = tonumber(n) or 2
    if n < 1 then
        return 1
    end
    if n > VOLUME_MAX then
        return VOLUME_MAX
    end
    return math.floor(n)
end

function GUIDE:SoundPath(page)
    local path = page and page.sound
    if not path then
        return nil
    end
    local step = self:VolumeStep()
    if step > 1 then
        path = path:gsub("%.mp3$", "-v" .. step .. ".mp3")
    end
    return path
end

function GUIDE:StopVoice()
    local handle = self._sound
    self._sound = nil
    if handle and StopSound then
        pcall(StopSound, handle)
    end
end

function GUIDE:PlayCurrent()
    self:StopVoice()
    if not self:VoiceOn() or not PlaySoundFile then
        return
    end
    local page = PAGES[self.page or 1]
    local path = self:SoundPath(page)
    if not path then
        return
    end
    local ok, willPlay, handle = pcall(PlaySoundFile, path, "Master")
    if (not ok or not willPlay) and path ~= page.sound then
        ok, willPlay, handle = pcall(PlaySoundFile, page.sound, "Master")
    end
    if ok and willPlay then
        self._sound = handle
    end
end

function GUIDE:CancelWait()
    self._waitGen = (self._waitGen or 0) + 1
    self._waiting = false
end

local function OnBubbleUpdate(self, elapsed)
    if not self:IsShown() then
        self:SetScript("OnUpdate", nil)
        return
    end
    local fade = self._fade
    if fade then
        fade = fade + (elapsed or 0)
        self._fade = fade
        local t = fade / FADE_IN
        if t >= 1 then
            self:SetAlpha(1)
            self._fade = nil
        else
            self:SetAlpha(t * t * (3 - 2 * t))
        end
    end
    if not GUIDE:Place(self) then
        self:SetAlpha(0)
        return
    end
    GUIDE:SyncListGlow()
end

function GUIDE:SetBubbleWatch(on)
    local bubble = self.bubble
    if not bubble then
        return
    end
    if on then
        if bubble:GetScript("OnUpdate") ~= OnBubbleUpdate then
            bubble:SetScript("OnUpdate", OnBubbleUpdate)
        end
    elseif bubble:GetScript("OnUpdate") then
        bubble:SetScript("OnUpdate", nil)
    end
end

function GUIDE:CloseBubble()
    self:StopVoice()
    self:HideListGlow()
    if self.bubble then
        self.bubble._fade = nil
        self.bubble:Hide()
        self:SetBubbleWatch(false)
    end
    if GQ.Log and GQ.Log.GamepadSyncGuide then
        GQ.Log:GamepadSyncGuide()
    end
end

function GUIDE:Dismiss()
    self:CancelWait()
    self:CloseBubble()
    local ui = UI()
    ui.portraitGuideSeen = true
    ui.portraitGuideIntro = true
    ui.portraitGuideVersion = GUIDE_VERSION
end

local function SetArrowEnabled(button, enabled)
    if not button then
        return
    end
    button:SetEnabled(enabled and true or false)
    button:SetAlpha(enabled and 1 or 0.35)
end

function GUIDE:VoiceTexture()
    if not self:VoiceOn() then
        return VOICE_OFF
    end
    local step = self:VolumeStep()
    if step >= 3 then
        return VOICE_3
    elseif step == 2 then
        return VOICE_2
    end
    return VOICE_1
end

function GUIDE:UpdateMute()
    local bubble = self.bubble
    if not bubble or not bubble.muteIcon then
        return
    end
    bubble.muteIcon:SetTexture(self:VoiceTexture())
end

function GUIDE:SetVolume(step)
    if step < 1 then
        step = 1
    elseif step > VOLUME_MAX then
        step = VOLUME_MAX
    end
    UI().portraitGuideVolume = step
    self:UpdateVolume()
    if self:VoiceOn() and self.bubble and self.bubble:IsShown() then
        self:PlayCurrent()
    end
    if GQ.Log and GQ.Log.GamepadSyncGuide then
        GQ.Log:GamepadSyncGuide()
    end
end

function GUIDE:UpdateVolume()
    local bubble = self.bubble
    if not bubble or not bubble.volumeText then
        return
    end
    local step = self:VolumeStep()
    bubble.volumeText:SetText(tostring(step))
    SetArrowEnabled(bubble.volumeDown, step > 1)
    SetArrowEnabled(bubble.volumeUp, step < VOLUME_MAX)
    self:UpdateMute()
end

local GLOW_THICK = 14

local function GlowFile(name)
    return "Interface\\AddOns\\" .. ADDON_NAME .. "\\Art\\" .. name
end

local function Near(a, b)
    if a == b then
        return true
    end
    if not a or not b then
        return false
    end
    local d = a - b
    if d < 0 then
        d = -d
    end
    return d < 0.5
end

local function Plant(tex, point, relative, relPoint, x, y, w, h)
    tex:ClearAllPoints()
    tex:SetSize(w, h)
    tex:SetPoint(point, relative, relPoint, x, y)
    tex:Show()
end

local function MakeEdge(parent, corner)
    local tex = parent:CreateTexture(nil, "ARTWORK")
    tex:SetTexture(GlowFile(corner and "GQ-FocusGlowCorner.png" or "GQ-FocusGlow.png"))
    tex:SetBlendMode("ADD")
    tex:Hide()
    return tex
end

function GUIDE:EnsureGlow(index)
    self.glows = self.glows or {}
    if self.glows[index] then
        return self.glows[index]
    end
    local glow = CreateFrame("Frame", nil, UIParent)
    glow:EnableMouse(false)
    if glow.SetClipsChildren then
        glow:SetClipsChildren(false)
    end
    glow.edgeTop = MakeEdge(glow, false)
    glow.edgeBottom = MakeEdge(glow, false)
    glow.edgeLeft = MakeEdge(glow, false)
    glow.edgeRight = MakeEdge(glow, false)
    glow.cornerTL = MakeEdge(glow, true)
    glow.cornerTR = MakeEdge(glow, true)
    glow.cornerBL = MakeEdge(glow, true)
    glow.cornerBR = MakeEdge(glow, true)
    -- Bright side of each strip stays against the frame.
    glow.edgeTop:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    glow.edgeBottom:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
    glow.edgeRight:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
    glow.edgeLeft:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    glow.cornerTR:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    glow.cornerTL:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
    glow.cornerBL:SetTexCoord(0, 1, 0, 0, 1, 1, 1, 0)
    glow.cornerBR:SetTexCoord(1, 1, 1, 0, 0, 1, 0, 0)
    glow:Hide()
    self.glows[index] = glow
    return glow
end

function GUIDE:HideListGlow()
    if self._glowOff then
        return
    end
    self._glowOff = true
    if self.frameGlow then
        self.frameGlow:Hide()
    end
    local glows = self.glows
    if not glows then
        return
    end
    for i = 1, #glows do
        glows[i]:Hide()
    end
end

function GUIDE:EnsureFrameGlow()
    if self.frameGlow then
        return self.frameGlow
    end
    local function piece(parent, file)
        local tex = parent:CreateTexture(nil, "ARTWORK")
        tex:SetTexture(GlowFile(file))
        tex:SetBlendMode("ADD")
        tex:Hide()
        return tex
    end
    local glow = CreateFrame("Frame", nil, UIParent)
    glow:EnableMouse(false)
    if glow.SetClipsChildren then
        glow:SetClipsChildren(false)
    end
    glow.edgeTop = piece(glow, "GQ-FocusGlow.png")
    glow.edgeBottom = piece(glow, "GQ-FocusGlow.png")
    glow.edgeLeft = piece(glow, "GQ-FocusGlow.png")
    glow.edgeRight = piece(glow, "GQ-FocusGlow.png")
    glow.cornerTR = piece(glow, "GQ-FocusGlowCorner.png")
    glow.cornerBL = piece(glow, "GQ-FocusGlowCorner.png")
    glow.cornerBR = piece(glow, "GQ-FocusGlowCorner.png")
    glow.cornerTL = piece(glow, "GQ-FocusGlowCornerTL.png")
    glow.edgeJoinTop = piece(glow, "GQ-FocusGlowJoin.png")
    glow.edgeJoinLeft = piece(glow, "GQ-FocusGlowJoin.png")
    glow.edgeTop:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
    glow.edgeBottom:SetTexCoord(0, 0, 1, 0, 0, 1, 1, 1)
    glow.edgeRight:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
    glow.edgeLeft:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    glow.cornerTR:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1)
    glow.cornerBL:SetTexCoord(0, 1, 0, 0, 1, 1, 1, 0)
    glow.cornerBR:SetTexCoord(1, 1, 1, 0, 0, 1, 0, 0)
    glow.edgeJoinTop:SetTexCoord(0, 1, 0, 0, 1, 1, 1, 0)
    glow.edgeJoinLeft:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
    glow:Hide()
    self.frameGlow = glow
    return glow
end

function GUIDE:LayoutFrameGlow()
    if GQ.UsesGamepad and GQ:UsesGamepad() then
        if self.frameGlow and self.frameGlow:IsShown() then
            self.frameGlow:Hide()
        end
        return
    end
    local frame = GQ.Log and GQ.Log.frame
    local glow = self:EnsureFrameGlow()
    if not frame or not frame:IsShown() or not glow then
        if glow and glow:IsShown() then
            glow:Hide()
        end
        return
    end
    local strata = frame.GetFrameStrata and frame:GetFrameStrata() or "DIALOG"
    local level = (frame:GetFrameLevel() or 1) + 4
    local width = frame:GetWidth() or 0
    local height = frame:GetHeight() or 0
    local scale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
    -- The glow is anchored to the window, so a drag does not rebuild it.
    if glow:IsShown() and glow._strata == strata and glow._level == level
        and Near(glow._w, width) and Near(glow._h, height) and Near(glow._scale, scale) then
        return
    end
    glow._strata, glow._level = strata, level
    glow._w, glow._h, glow._scale = width, height, scale
    glow:SetFrameStrata(strata)
    glow:SetFrameLevel(level)
    local thick = GLOW_THICK
    local overlap = 2
    local fadeStart = 62
    local fadeEnd = 80
    local cornerPad = 48
    local cornerSide = 128

    local top = glow.edgeTop
    top:ClearAllPoints()
    top:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", fadeEnd - 4, -overlap)
    top:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -overlap, -overlap)
    top:SetHeight(thick)
    top:Show()

    local joinTop = glow.edgeJoinTop
    joinTop:ClearAllPoints()
    joinTop:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", fadeStart, -overlap)
    joinTop:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", fadeEnd, -overlap)
    joinTop:SetHeight(thick)
    joinTop:Show()

    local bottom = glow.edgeBottom
    bottom:ClearAllPoints()
    bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", overlap, overlap)
    bottom:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", -overlap, overlap)
    bottom:SetHeight(thick)
    bottom:Show()

    local left = glow.edgeLeft
    left:ClearAllPoints()
    left:SetPoint("TOPRIGHT", frame, "TOPLEFT", overlap, -(fadeEnd - 4))
    left:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", overlap, overlap)
    left:SetWidth(thick)
    left:Show()

    local joinLeft = glow.edgeJoinLeft
    joinLeft:ClearAllPoints()
    joinLeft:SetPoint("TOPRIGHT", frame, "TOPLEFT", overlap, -fadeStart)
    joinLeft:SetPoint("BOTTOMRIGHT", frame, "TOPLEFT", overlap, -fadeEnd)
    joinLeft:SetWidth(thick)
    joinLeft:Show()

    local right = glow.edgeRight
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", frame, "TOPRIGHT", -overlap, -overlap)
    right:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -overlap, overlap)
    right:SetWidth(thick)
    right:Show()

    Plant(glow.cornerTR, "BOTTOMLEFT", frame, "TOPRIGHT", -overlap, -overlap, thick, thick)
    Plant(glow.cornerBL, "TOPRIGHT", frame, "BOTTOMLEFT", overlap, overlap, thick, thick)
    Plant(glow.cornerBR, "TOPLEFT", frame, "BOTTOMRIGHT", -overlap, overlap, thick, thick)
    Plant(glow.cornerTL, "TOPLEFT", frame, "TOPLEFT", -cornerPad, cornerPad, cornerSide, cornerSide)
    glow:Show()
end

function GUIDE:LayoutGlow(glow, topBar, list, cap, wide)
    local frame = GQ.Log and GQ.Log.frame
    local strata = frame and frame.GetFrameStrata and frame:GetFrameStrata() or "DIALOG"
    local level = ((list.GetFrameLevel and list:GetFrameLevel()) or 1) + 12
    local barW = topBar:GetWidth() or 0
    local barH = topBar:GetHeight() or 0
    local listW = list:GetWidth() or 0
    local listH = list:GetHeight() or 0
    local wideW = wide and wide:GetWidth() or 0
    local wideH = wide and wide:GetHeight() or 0
    local wideTop = wide and wide.GetTop and wide:GetTop() or 0
    local capTop = cap and cap.GetTop and cap:GetTop() or 0
    local barTop = topBar.GetTop and topBar:GetTop() or 0
    local scale = (topBar.GetEffectiveScale and topBar:GetEffectiveScale()) or 1
    if glow:IsShown() and glow._topBar == topBar and glow._list == list and glow._wide == wide and glow._cap == cap
        and glow._strata == strata and glow._level == level
        and Near(glow._barW, barW) and Near(glow._barH, barH)
        and Near(glow._listW, listW) and Near(glow._listH, listH)
        and Near(glow._wideW, wideW) and Near(glow._wideH, wideH) and Near(glow._wideTop, wideTop)
        and Near(glow._capTop, capTop) and Near(glow._barTop, barTop) and Near(glow._scale, scale) then
        return
    end
    glow._topBar, glow._list, glow._wide, glow._cap = topBar, list, wide, cap
    glow._strata, glow._level = strata, level
    glow._barW, glow._barH, glow._listW, glow._listH = barW, barH, listW, listH
    glow._wideW, glow._wideH, glow._wideTop = wideW, wideH, wideTop
    glow._capTop, glow._barTop, glow._scale = capTop, barTop, scale
    glow:SetFrameStrata(strata)
    glow:SetFrameLevel(level)
    local thick = GLOW_THICK
    local overlap = 2
    local lift = 0
    if cap and cap.GetTop and topBar.GetTop then
        local capTop = cap:GetTop()
        local barTop = topBar:GetTop()
        local scale = (topBar.GetEffectiveScale and topBar:GetEffectiveScale()) or 1
        if capTop and barTop and scale > 0 and capTop > barTop then
            lift = (capTop - barTop) / scale
        end
    end
    local topY = -overlap + lift
    local rightFrame = wide or topBar
    local rightTopY = topY
    local rightBotY = overlap
    if wide and wide ~= topBar and wide.GetTop and topBar.GetTop then
        local scale = (topBar.GetEffectiveScale and topBar:GetEffectiveScale()) or 1
        local barTop, wideTop = topBar:GetTop(), wide:GetTop()
        local barBot, wideBot = topBar:GetBottom(), wide:GetBottom()
        if barTop and wideTop and scale > 0 then
            rightTopY = topY + (barTop - wideTop) / scale
        end
        if barBot and wideBot and scale > 0 then
            rightBotY = overlap + (barBot - wideBot) / scale
        end
    end

    local top = glow.edgeTop
    top:ClearAllPoints()
    top:SetPoint("BOTTOMLEFT", topBar, "TOPLEFT", overlap, topY)
    top:SetPoint("BOTTOMRIGHT", rightFrame, "TOPRIGHT", -overlap, rightTopY)
    top:SetHeight(thick)
    top:Show()

    local bottom = glow.edgeBottom
    bottom:ClearAllPoints()
    bottom:SetPoint("TOPLEFT", list, "BOTTOMLEFT", overlap, overlap)
    bottom:SetPoint("TOPRIGHT", wide or list, "BOTTOMRIGHT", -overlap, rightBotY)
    bottom:SetHeight(thick)
    bottom:Show()

    local left = glow.edgeLeft
    left:ClearAllPoints()
    left:SetPoint("TOPRIGHT", topBar, "TOPLEFT", overlap, topY)
    left:SetPoint("BOTTOMRIGHT", list, "BOTTOMLEFT", overlap, overlap)
    left:SetWidth(thick)
    left:Show()

    local right = glow.edgeRight
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", rightFrame, "TOPRIGHT", -overlap, rightTopY)
    right:SetPoint("BOTTOMLEFT", wide or list, "BOTTOMRIGHT", -overlap, rightBotY)
    right:SetWidth(thick)
    right:Show()

    Plant(glow.cornerTL, "BOTTOMRIGHT", topBar, "TOPLEFT", overlap, topY, thick, thick)
    Plant(glow.cornerTR, "BOTTOMLEFT", rightFrame, "TOPRIGHT", -overlap, rightTopY, thick, thick)
    Plant(glow.cornerBL, "TOPRIGHT", list, "BOTTOMLEFT", overlap, overlap, thick, thick)
    Plant(glow.cornerBR, "TOPLEFT", wide or list, "BOTTOMRIGHT", -overlap, rightBotY, thick, thick)
    glow:Show()
end

function GUIDE:TopHeaderInfo()
    local log = GQ.Log
    local rows = log and log.listRows
    local scroll = log and log.frame and log.frame.scroll
    if not rows then
        return nil
    end
    local best, bestTop
    local viewTop = scroll and scroll:GetTop()
    local viewBottom = scroll and scroll:GetBottom()
    for i = 1, #rows do
        local row = rows[i]
        local info = row and row.info
        if row and row:IsShown() and row.rowType == "header" and info and info:IsShown() then
            local top = info:GetTop()
            local bottom = info:GetBottom()
            local visible = true
            if viewTop and viewBottom and top and bottom then
                visible = bottom < viewTop - 2 and top > viewBottom + 2
            end
            if visible and top and (not bestTop or top > bestTop) then
                best = info
                bestTop = top
            end
        end
    end
    return best
end

function GUIDE:WeaponsFilterArrow()
    local log = GQ.Log
    local rows = log and log.listRows
    local scroll = log and log.frame and log.frame.scroll
    if not rows then
        return nil
    end
    local viewTop = scroll and scroll:GetTop()
    local viewBottom = scroll and scroll:GetBottom()
    for i = 1, #rows do
        local row = rows[i]
        local arrow = row and row.weaponArrow
        if row and row:IsShown() and arrow and arrow:IsShown() and row.slotName ~= "Ranged" then
            local top = arrow:GetTop()
            local bottom = arrow:GetBottom()
            if not viewTop or not viewBottom or not top or not bottom
                or (bottom < viewTop - 2 and top > viewBottom + 2) then
                return arrow, i
            end
            return nil, i
        end
    end
    return nil
end

-- The Weapons arrow sits on that header. Bring it into the list once per visit.
function GUIDE:RevealWeaponsFilter()
    if self._weaponsShown == self.page then
        return
    end
    local arrow, index = self:WeaponsFilterArrow()
    if arrow then
        self._weaponsShown = self.page
        return
    end
    if not index then
        return
    end
    local log = GQ.Log
    if log and log.ScrollListToRow then
        log:ScrollListToRow(index)
        self._weaponsShown = self.page
    end
end

function GUIDE:HighlightPair(kind)
    local log = GQ.Log
    local frame = log and log.frame
    if not frame then
        return nil
    end
    if kind == "list" then
        local list = frame.listInset
        if not list or not list:IsShown() then
            return nil
        end
        local topBar = frame.pageBar or frame.tabBar or list
        if not topBar:IsShown() then
            topBar = list
        end
        return topBar, list
    end
    local widget, cap, wide
    if kind == "info" then
        widget = self:TopHeaderInfo()
    elseif kind == "slider" then
        widget = frame.huntsPerSlot
    elseif kind == "filter" then
        widget = frame.sourceFilterBtn
    elseif kind == "weapons" then
        self:RevealWeaponsFilter()
        widget = self:WeaponsFilterArrow()
    elseif kind == "playstyle" then
        widget = frame.playStyleBtn
    elseif kind == "detail" then
        widget = frame.detailBg
    elseif kind == "track" then
        widget = frame.trackBtn
    elseif kind == "map" then
        widget = frame.mapBtn
    elseif kind == "remove" then
        widget = frame.removeBtn
    elseif kind == "removed" then
        widget = frame.tabRemoved
    elseif kind == "score" then
        widget = frame.gearScoreBar
        cap = widget and widget.title
    elseif kind == "spec" then
        widget = frame.tabSpecControl
    elseif kind == "log" then
        widget = frame.tabLog
    elseif kind == "lookup" then
        widget = frame.tabLookup
    elseif kind == "search" then
        widget = frame.lookupBox
    elseif kind == "simulator" then
        widget = frame.tabSimulator
    elseif kind == "warrior" then
        local buttons = frame.simClassButtons
        if buttons then
            for i = 1, #buttons do
                if buttons[i] and buttons[i].classFile == "WARRIOR" then
                    widget = buttons[i]
                    break
                end
            end
        end
    elseif kind == "alliance" then
        widget = frame.simAllianceBtn
    elseif kind == "arms" then
        local buttons = frame.simSpecButtons
        if buttons then
            for i = 1, #buttons do
                local btn = buttons[i]
                if btn and (btn.specId == "arms" or btn.specLabel == "Arms") then
                    widget = btn
                    break
                end
            end
        end
    elseif kind == "level" then
        widget = frame.simLevelEdit
    elseif kind == "simulate" then
        widget = frame.simApplyBtn
    elseif kind == "settings" then
        widget = frame.tabSettings
    elseif kind == "minimap" then
        widget = frame.settingsMinimapCheck
        wide = frame.settingsMinimapLabelHit
    elseif kind == "enchant" then
        widget = frame.settingsEnchantCheck
        wide = frame.settingsEnchantLabelHit
    end
    if widget and widget:IsShown() then
        if not cap or not cap.IsShown or not cap:IsShown() then
            cap = nil
        end
        if not wide or not wide.IsShown or not wide:IsShown() then
            wide = nil
        end
        return widget, widget, cap, wide
    end
    return nil
end

function GUIDE:SyncListGlow()
    local bubble = self.bubble
    if not bubble or not bubble:IsShown() then
        self:HideListGlow()
        return
    end
    local page = PAGES[self.page or 1]
    local log = GQ.Log
    local pageTab = log and log.GetPageTab and log:GetPageTab()
    local whole = page and page.whole
    local wantTab = (page and page.tab) or "log"
    local marks = page and page.marks
    local tabOk = wantTab == "any" or pageTab == wantTab
    if whole then
        if not tabOk then
            self:HideListGlow()
            return
        end
    elseif not marks then
        self:HideListGlow()
        return
    end
    self._glowOff = false
    if whole then
        local glows = self.glows
        if glows then
            for i = 1, #glows do
                if glows[i]:IsShown() then
                    glows[i]:Hide()
                end
            end
        end
        self:LayoutFrameGlow()
        return
    end
    if self.frameGlow and self.frameGlow:IsShown() then
        self.frameGlow:Hide()
    end
    local shown = 0
    for i = 1, #marks do
        local kind = marks[i]
        if tabOk or HANDLE_MARK[kind] then
            local topBar, list, cap, wide = self:HighlightPair(kind)
            if topBar and list then
                shown = shown + 1
                self:LayoutGlow(self:EnsureGlow(shown), topBar, list, cap, wide)
            end
        end
    end
    local glows = self.glows
    if glows then
        for i = shown + 1, #glows do
            if glows[i]:IsShown() then
                glows[i]:Hide()
            end
        end
    end
end

function GUIDE:Refresh()
    local bubble = self.bubble
    if not bubble then
        return
    end
    local count = #PAGES
    local index = self.page or 1
    if index < 1 then
        index = 1
    elseif index > count then
        index = count
    end
    self.page = index
    local page = PAGES[index]
    bubble.body:SetText(page and page.text or "")
    local textHeight = bubble.body:GetStringHeight() or 0
    if textHeight < 20 then
        textHeight = 84
        if not bubble._heightTried and C_Timer and C_Timer.After then
            bubble._heightTried = true
            C_Timer.After(0, function()
                if not self.bubble or not self.bubble:IsShown() then
                    return
                end
                local measured = self.bubble.body:GetStringHeight() or 0
                if measured >= 20 then
                    self:Refresh()
                end
            end)
        end
    end
    local titleHeight = (bubble.title and bubble.title:GetStringHeight()) or 16
    if titleHeight < 12 then
        titleHeight = 16
    end
    bubble:SetHeight(textHeight + titleHeight + 72)
    if index == 1 then
        bubble.counter:SetText("")
        if bubble.nav then
            bubble.nav:Hide()
        end
        if bubble.yes then
            bubble.yes:Show()
        end
    else
        bubble.counter:SetText(string.format("%d/%d", index, count))
        if bubble.nav then
            bubble.nav:Show()
        end
        if bubble.yes then
            bubble.yes:Hide()
        end
    end
    SetArrowEnabled(bubble.back, index > 1)
    SetArrowEnabled(bubble.forward, index < count)
    self:UpdateMute()
    self:SyncListGlow()
end

function GUIDE:SetPage(index)
    local count = #PAGES
    if index < 1 then
        index = 1
    elseif index > count then
        index = count
    end
    if index == self.page and self.bubble and self.bubble:IsShown() then
        return
    end
    self._weaponsShown = nil
    self.page = index
    self:Refresh()
    self:PlayCurrent()
    if GQ.Log and GQ.Log.GamepadSyncGuide then
        GQ.Log:GamepadSyncGuide()
    end
end

-- Puts the parchment above the window and the tail tip just above the portrait.
-- Returns false until the log has a screen position.
function GUIDE:Place(bubble, frame)
    bubble = bubble or self.bubble
    frame = frame or (GQ.Log and GQ.Log.frame)
    if not bubble or not frame or not frame.GetLeft then
        return false
    end
    local left, top = frame:GetLeft(), frame:GetTop()
    if not left or not top then
        return false
    end
    local frameScale = frame:GetEffectiveScale() or 1
    local parentScale = UIParent:GetEffectiveScale() or 1
    if frameScale <= 0 or parentScale <= 0 then
        return false
    end
    local rel = frameScale / parentScale
    local strata = frame.GetFrameStrata and frame:GetFrameStrata() or "DIALOG"
    local level = (frame:GetFrameLevel() or 1) + 30
    local tipX = PORTRAIT_OFFSET_X + (PORTRAIT_SIZE * 0.5)
    local tipY = PORTRAIT_OFFSET_Y + TIP_GAP
    local boxX = tipX - TAIL_CENTER_X
    local boxY = tipY + (TAIL_H - TAIL_OVERLAP)
    -- GetLeft/GetTop are already in UIParent space. The portrait offset is in
    -- the window's own pixels, so only that offset grows with the window scale.
    local blX = left + boxX * rel
    local blY = top + boxY * rel
    local height = bubble:GetHeight() or 0
    if height < 40 then
        height = 120
    end
    local screenH = UIParent:GetHeight() or 0
    local topY = blY + height * rel
    if topY > screenH - 8 then
        blY = blY - (topY - (screenH - 8))
    end
    if bubble._strata == strata and bubble._level == level
        and Near(bubble._blX, blX) and Near(bubble._blY, blY) and Near(bubble._want, rel) then
        return true
    end
    bubble._strata, bubble._level = strata, level
    bubble._blX, bubble._blY, bubble._want = blX, blY, rel
    if math.abs((bubble:GetScale() or 1) - rel) > 0.001 then
        bubble:SetScale(rel)
    end
    if bubble.SetFrameStrata then
        bubble:SetFrameStrata(strata)
    end
    if bubble.SetFrameLevel then
        bubble:SetFrameLevel(level)
    end
    bubble:ClearAllPoints()
    bubble:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", blX, blY)
    return true
end

function GUIDE:Begin(frame)
    frame = frame or (GQ.Log and GQ.Log.frame)
    if not frame then
        return
    end
    self:Ensure(frame)
    local bubble = self.bubble
    bubble._fade = 0
    bubble:SetAlpha(0)
    self:Place(bubble, frame)
    bubble:Show()
    self:SetBubbleWatch(true)
    self:MarkOnboarded()
    self.page = nil
    self:SetPage(1)
    if GQ.Log and GQ.Log.GamepadSyncGuide then
        GQ.Log:GamepadSyncGuide()
    end
end

function GUIDE:Open(frame)
    self:CancelWait()
    frame = frame or (GQ.Log and GQ.Log.frame)
    if not frame then
        return
    end
    self:Ensure(frame)
    if self.bubble:IsShown() then
        self:PlayCurrent()
        return
    end
    self:Begin(frame)
end

function GUIDE:OnLogShown(frame)
    if not frame then
        return
    end
    self:Ensure(frame)
    if self:Onboarded() then
        return
    end
    if self.bubble and self.bubble:IsShown() then
        self:Place(self.bubble, frame)
        return
    end
    if self._waiting then
        return
    end
    self._waiting = true
    local gen = self._waitGen or 0
    if not C_Timer or not C_Timer.After then
        self._waiting = false
        self:Begin(frame)
        return
    end
    C_Timer.After(OPEN_DELAY, function()
        if gen ~= (GUIDE._waitGen or 0) then
            return
        end
        GUIDE._waiting = false
        if GUIDE:Onboarded() then
            return
        end
        local log = GQ.Log
        if not log or not log.frame or not log.frame:IsShown() then
            return
        end
        GUIDE:Begin(log.frame)
    end)
end

local function MakeArrow(parent, previous)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(26, 26)
    local side = previous and "PrevPage" or "NextPage"
    button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. side .. "-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. side .. "-Down")
    button:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. side .. "-Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return button
end

local function MakeTitle(parent)
    local ok, title = pcall(parent.CreateFontString, parent, nil, "OVERLAY", "GameFontNormalLarge")
    if not ok or not title then
        title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    end
    return title
end

local function MakeBody(parent)
    local ok, body = pcall(parent.CreateFontString, parent, nil, "OVERLAY", "QuestFont")
    if not ok or not body then
        body = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    end
    return body
end

function GUIDE:Ensure(frame)
    if not frame then
        return
    end
    if self.bubble then
        if self.hit and self.hit:GetParent() ~= frame then
            self.hit:SetParent(frame)
        end
        return
    end

    local hit = CreateFrame("Button", nil, frame)
    hit:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    hit:SetPoint("TOPLEFT", frame, "TOPLEFT", PORTRAIT_OFFSET_X, PORTRAIT_OFFSET_Y)
    hit:EnableMouse(true)
    hit:SetFrameLevel((frame:GetFrameLevel() or 1) + 12)
    local glow = hit:CreateTexture(nil, "OVERLAY")
    glow:SetAllPoints(hit)
    local colored = glow.SetColorTexture and pcall(glow.SetColorTexture, glow, 1, 0.82, 0.45, 1)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.45)
    local masked = false
    if colored and hit.CreateMaskTexture and glow.AddMaskTexture then
        local masks = {
            "Interface\\Masks\\CircleMaskScalable",
            "Interface\\CharacterFrame\\TempPortraitAlphaMask",
        }
        for i = 1, #masks do
            local mask = hit:CreateMaskTexture()
            mask:SetAllPoints(glow)
            local texOk = pcall(mask.SetTexture, mask, masks[i])
            local addOk = texOk and pcall(glow.AddMaskTexture, glow, mask)
            if addOk then
                masked = true
                break
            end
            mask:Hide()
        end
    end
    if not masked then
        glow:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
        glow:SetBlendMode("ADD")
        glow:SetAlpha(0.9)
    end
    glow:Hide()
    hit.glow = glow
    hit:SetScript("OnClick", function()
        GUIDE:Open(frame)
    end)
    hit:SetScript("OnEnter", function(self)
        if self.glow then
            self.glow:Show()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Проводник GearQuest", 1, 0.82, 0)
        GameTooltip:AddLine("Щёлкните по портрету, чтобы послушать его снова.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    hit:SetScript("OnLeave", function(self)
        if self.glow then
            self.glow:Hide()
        end
        GameTooltip:Hide()
    end)
    self.hit = hit

    -- The log clips its children, so the bubble lives on UIParent and follows the window.
    local bubble = CreateFrame("Frame", "GearQuestPortraitGuide", UIParent)
    bubble:SetWidth(BUBBLE_W)
    bubble:SetHeight(120)
    bubble:SetFrameStrata("DIALOG")
    bubble:SetFrameLevel((frame:GetFrameLevel() or 1) + 30)
    bubble:EnableMouse(true)
    bubble:Hide()
    bubble:SetAlpha(0)

    local parchment = bubble:CreateTexture(nil, "BACKGROUND", nil, 0)
    parchment:SetTexture(PARCHMENT)
    parchment:SetAllPoints(bubble)

    local tail = bubble:CreateTexture(nil, "BACKGROUND", nil, -1)
    tail:SetTexture(TAIL)
    tail:SetSize(TAIL_W, TAIL_H)
    tail:SetPoint("TOP", bubble, "BOTTOMLEFT", TAIL_CENTER_X, TAIL_OVERLAP)

    local title = MakeTitle(bubble)
    title:SetPoint("TOPLEFT", bubble, "TOPLEFT", 18, -14)
    title:SetPoint("RIGHT", bubble, "RIGHT", -36, 0)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(false)
    title:SetText(GUIDE_NAME)
    title:SetTextColor(0.28, 0.12, 0.04)
    bubble.title = title

    local body = MakeBody(bubble)
    body:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    body:SetPoint("RIGHT", bubble, "RIGHT", -18, 0)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetWordWrap(true)
    body:SetTextColor(0.16, 0.08, 0.03)
    bubble.body = body

    local close = CreateFrame("Button", nil, bubble)
    close:SetSize(18, 18)
    close:SetPoint("TOPRIGHT", bubble, "TOPRIGHT", -10, -8)
    close:SetFrameLevel(bubble:GetFrameLevel() + 2)
    local closeText = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER", close, "CENTER", 0, 0)
    closeText:SetText("X")
    closeText:SetTextColor(0.35, 0.16, 0.06)
    close:SetScript("OnClick", function()
        GUIDE:Dismiss()
    end)
    close:SetScript("OnEnter", function(self)
        closeText:SetTextColor(0.55, 0.12, 0.08)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Закрыть")
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function()
        closeText:SetTextColor(0.35, 0.16, 0.06)
        GameTooltip:Hide()
    end)

    local nav = CreateFrame("Frame", nil, bubble)
    nav:SetSize(120, 26)
    nav:SetPoint("BOTTOM", bubble, "BOTTOM", -6, 8)
    nav:Hide()
    bubble.nav = nav

    local back = MakeArrow(nav, true)
    back:SetPoint("LEFT", nav, "LEFT", 0, 0)
    back:SetScript("OnClick", function()
        GUIDE:SetPage((GUIDE.page or 1) - 1)
    end)
    bubble.back = back

    local counter = nav:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    counter:SetPoint("LEFT", back, "RIGHT", 6, 0)
    counter:SetWidth(46)
    counter:SetJustifyH("CENTER")
    counter:SetTextColor(0.28, 0.14, 0.05)
    bubble.counter = counter

    local forward = MakeArrow(nav, false)
    forward:SetPoint("LEFT", counter, "RIGHT", 6, 0)
    forward:SetScript("OnClick", function()
        GUIDE:SetPage((GUIDE.page or 1) + 1)
    end)
    bubble.forward = forward

    local yes = CreateFrame("Button", nil, bubble, "UIPanelButtonTemplate")
    yes:SetSize(88, 22)
    yes:SetPoint("BOTTOM", bubble, "BOTTOM", 0, 10)
    yes:SetFrameLevel(bubble:GetFrameLevel() + 2)
    yes:SetText("Да!")
    yes:SetScript("OnClick", function()
        GUIDE:SetPage(2)
    end)
    yes:Hide()
    bubble.yes = yes

    local mute = CreateFrame("Button", nil, bubble)
    mute:SetSize(22, 22)
    mute:SetPoint("BOTTOMRIGHT", bubble, "BOTTOMRIGHT", -28, 10)
    mute:SetFrameLevel(bubble:GetFrameLevel() + 2)
    local muteIcon = mute:CreateTexture(nil, "ARTWORK")
    muteIcon:SetAllPoints()
    bubble.muteIcon = muteIcon
    mute:SetScript("OnClick", function()
        local on = not GUIDE:VoiceOn()
        UI().portraitGuideVoice = on and true or false
        GUIDE:UpdateMute()
        if on then
            GUIDE:PlayCurrent()
        else
            GUIDE:StopVoice()
        end
    end)
    mute:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if GUIDE:VoiceOn() then
            GameTooltip:SetText("Выключить голос проводника")
        else
            GameTooltip:SetText("Включить голос проводника")
        end
        GameTooltip:Show()
    end)
    mute:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local function VolumeButton(text)
        local button = CreateFrame("Button", nil, bubble)
        button:SetSize(16, 22)
        button:SetFrameLevel(bubble:GetFrameLevel() + 2)
        local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("CENTER", button, "CENTER", 0, 0)
        label:SetText(text)
        label:SetTextColor(0.35, 0.16, 0.06)
        button:SetScript("OnEnter", function(self)
            label:SetTextColor(0.55, 0.12, 0.08)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            if text == "+" then
                GameTooltip:SetText("Сделать голос проводника громче")
            else
                GameTooltip:SetText("Сделать голос проводника тише")
            end
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            label:SetTextColor(0.35, 0.16, 0.06)
            GameTooltip:Hide()
        end)
        return button
    end

    local volumeUp = VolumeButton("+")
    volumeUp:SetPoint("RIGHT", mute, "LEFT", -2, 0)
    volumeUp:SetScript("OnClick", function()
        GUIDE:SetVolume(GUIDE:VolumeStep() + 1)
    end)
    bubble.volumeUp = volumeUp

    local volumeText = bubble:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    volumeText:SetPoint("RIGHT", volumeUp, "LEFT", -1, 0)
    volumeText:SetWidth(12)
    volumeText:SetJustifyH("CENTER")
    volumeText:SetTextColor(0.28, 0.14, 0.05)
    bubble.volumeText = volumeText

    local volumeDown = VolumeButton("-")
    volumeDown:SetPoint("RIGHT", volumeText, "LEFT", -1, 0)
    volumeDown:SetScript("OnClick", function()
        GUIDE:SetVolume(GUIDE:VolumeStep() - 1)
    end)
    bubble.volumeDown = volumeDown

    if frame.HookScript and not frame.gqGuideHooked then
        frame.gqGuideHooked = true
        frame:HookScript("OnHide", function()
            GUIDE:CancelWait()
            GUIDE:CloseBubble()
        end)
    end

    self.bubble = bubble
    self:UpdateMute()
    self:UpdateVolume()
end
