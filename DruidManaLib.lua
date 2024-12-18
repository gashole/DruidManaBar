local _, class = UnitClass("player")
if class ~= "DRUID" then return end

local _G = getfenv()

local DruidManaLib = {}

local BEAR_FORM_TEXTURE = "Interface\\Icons\\Ability_Racial_BearForm"
local CAT_FORM_TEXTURE = "Interface\\Icons\\Ability_Druid_CatForm"
local INNERVATE_TEXTURE = "Interface\\Icons\\Spell_Nature_Lightning"
-- local RUNE_OF_METAMORPHOSIS_TEXTURE = "Interface\\Icons\\Inv_Misc_Rune_06"

local REFLECTION_TALENT_TAB, REFLECTION_TALENT_SLOT = 3, 6

local function hasBuffTexture(texture)
    for i = 1, 32 do if UnitBuff("player", i) == texture then return true end end
    return false
end

local function calcManaRegen()
    local base = (DruidManaLib.db.spirit / 5) + 15
    local innervate = base * (DruidManaLib.db.innervate and 5 or 1)
    local regen = innervate + DruidManaLib.db.equipBonus
    return regen
end

local function calcShiftRegen()
    local base = (DruidManaLib.db.spirit / 5) + 15
    local reflection = base * (0.05 * DruidManaLib.db.reflectionRank)
    local regen = reflection + DruidManaLib.db.equipBonus
    return regen
end

local function getShiftManaCost()
    local cost = 0

    for form = 1, GetNumShapeshiftForms() do
        local icon = GetShapeshiftFormInfo(form)

        -- Check for Bear or Cat form, as players may not have Bear on customs servers
        if icon and (icon == BEAR_FORM_TEXTURE or icon == CAT_FORM_TEXTURE) then
            DruidManaLib.tooltip:SetShapeshift(form)

            local text = _G["DruidManaLibTooltipTextLeft2"]:GetText()
            if text then
                local numStart, numEnd = string.find(text, "%d+")
                if numStart then
                    cost = tonumber(string.sub(text, numStart, numEnd))
                    break
                end
            end
        end
    end

    return cost
end

local function getEquipManaBonus()
    local bonus = 0
    local manaText = string.lower(MANA)
    local secAbbr = string.lower(SECONDS_ABBR)
    local onProc = string.lower(ITEM_SPELL_TRIGGER_ONPROC)
    local onUse = string.lower(ITEM_SPELL_TRIGGER_ONUSE)
    local pattern = manaText .. ".*" .. secAbbr

    for slot = 1, 19 do
        DruidManaLib.tooltip:ClearLines()
        DruidManaLib.tooltip:SetInventoryItem("player", slot)

        -- Lines can be skipped, needs testing
        for line = 1, DruidManaLib.tooltip:NumLines() do
            local text = _G["DruidManaLibTooltipTextLeft" .. line]:GetText()
            if text then
                local lText = string.lower(text)

                if string.find(lText, "^" .. onProc) or string.find(lText, "^" .. onUse) then break end

                local found = string.find(lText, pattern)
                if found then
                    local numStart, numEnd = string.find(string.sub(lText, 1, found - 1), "(%d+[%d%,]*)%s*$")
                    if numStart then
                        local num = tonumber(string.sub(lText, numStart, numEnd))
                        if num then bonus = bonus + (num * 0.4) end
                    end
                end
            end
        end
    end

    return bonus
end

local function getReflectionTalentRank()
    local _, _, _, _, rank = GetTalentInfo(REFLECTION_TALENT_TAB, REFLECTION_TALENT_SLOT)
    return rank
end

function DruidManaLib:Init()
    self.db = {
        mana = 0,
        maxMana = 0,
        intellect = 0,
        spirit = 0,
        powerType = nil,
        usingMana = nil,
        shiftMana = 0,
        equipBonus = 0,
        innervate = nil,
        reflectionRank = 0,
        skipShiftRegen = false,
        shiftTime = 0,
        shiftDone = false
    }

    self.tooltip = CreateFrame("GameTooltip", "DruidManaLibTooltip", nil, "GameTooltipTemplate")
    self.tooltip:SetOwner(UIParent, "ANCHOR_NONE")

    self.frame = CreateFrame("Frame", "DruidManaLibFrame")
    self.frame:RegisterEvent("VARIABLES_LOADED")
    self.frame:RegisterEvent("PLAYER_LOGOUT")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    self.frame:RegisterEvent("PLAYER_AURAS_CHANGED")
    self.frame:RegisterEvent("UNIT_DISPLAYPOWER")
    self.frame:RegisterEvent("UNIT_MAXMANA")
    self.frame:RegisterEvent("UNIT_MANA")
    self.frame:RegisterEvent("SPELLCAST_STOP")
    self.frame:SetScript("OnEvent", function() self:OnEvent() end)
end

function DruidManaLib:InitDB()
    DruidManaLibDB = DruidManaLibDB or {}

    self.db.mana = DruidManaLibDB.mana or 0
    self.db.maxMana = DruidManaLibDB.maxMana or 0
    self.db.shiftTime = DruidManaLibDB.shiftTime or 0
end

function DruidManaLib:SaveDB()
    -- Save only necessary data for reloading
    DruidManaLibDB.mana = self.db.mana
    DruidManaLibDB.maxMana = self.db.maxMana
    DruidManaLibDB.shiftTime = self.db.shiftTime
end

function DruidManaLib:OnEvent()
    if event == "SPELLCAST_STOP" then
        self:UpdateShiftTime()
    elseif event == "UNIT_MANA" and arg1 == "player" then
        self:UpdateMana()
    elseif event == "UNIT_MAXMANA" and arg1 == "player" then
        self:UpdateMaxMana()
    elseif event == "UNIT_DISPLAYPOWER" and arg1 == "player" then
        self:UpdatePowerType()
        self:UpdateReflectionRank()
    elseif event == "PLAYER_AURAS_CHANGED" then
        self:UpdateMaxMana()
        self:UpdateStats()
        self:UpdateInnervate()
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        self:UpdateStats()
        self:UpdateEquipMana()
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UpdateStats()
        self:UpdatePowerType(true)
        self:UpdateEquipMana()
        self:UpdateReflectionRank()
    elseif event == "PLAYER_LOGOUT" then
        self:SaveDB()
    elseif event == "VARIABLES_LOADED" then
        self:InitDB()
    end
end

function DruidManaLib:UpdateShiftTime()
    if self.db.usingMana then
        self.db.shiftTime = GetTime()
        self.db.shiftDone = false
        self.db.skipShiftRegen = false
    end
end

function DruidManaLib:UpdateMana()
    local usingMana = self:IsUsingMana()
    if usingMana then
        self.db.mana = UnitMana("player")
        return
    end

    -- Prevent updates during a shift to avoid incorrect mana
    -- values from multiple UNIT_MANA events firing before the
    -- shift completes. Skip the initial tick, which can be
    -- missed when shift happens near an update.
    if self.db.usingMana ~= usingMana then return end

    local now = GetTime()
    local elapsed = now - self.db.shiftTime
    local regen = 0

    if elapsed >= 5 or self.db.innervate or self.db.skipShiftRegen then
        regen = calcManaRegen()
    else
        regen = calcShiftRegen()

        -- Double regen for the first tick if over 1.8s have passed,
        -- and force normal regen for the next tick if the time is
        -- under 2s. These calculations are based on personal test
        -- numbers and need revision.
        if elapsed >= 1.8 and not self.db.shiftDone then
            regen = math.floor(regen) * 2
            if elapsed <= 2 then self.db.skipShiftRegen = true end
        end
    end

    self.db.mana = math.min(math.floor(self.db.mana + regen), self.db.maxMana)
    self.db.shiftDone = true
end

function DruidManaLib:UpdateMaxMana()
    if self.db.usingMana then
        self.db.maxMana = UnitManaMax("player")
        return
    end

    local _, int = UnitStat("player", 4)
    if int == self.db.intellect then return end

    local diff = int - self.db.intellect
    self.db.maxMana = math.floor(self.db.maxMana + (diff * 15))
    self.db.intellect = int
end

function DruidManaLib:UpdateStats()
    local _, int = UnitStat("player", 4)
    local _, spi = UnitStat("player", 5)

    self.db.intellect = int
    self.db.spirit = spi
end

function DruidManaLib:UpdatePowerType(skipShiftMana)
    self.db.powerType = UnitPowerType("player")
    self.db.usingMana = self.db.powerType == 0

    -- Skip shift mana update when entering the world
    if not skipShiftMana then
        self:UpdateShiftMana()
    else
        self.db.shiftDone = true
    end
end

function DruidManaLib:UpdateShiftMana()
    if self.db.usingMana then return end

    self.db.shiftMana = getShiftManaCost()
    self.db.mana = math.max(self.db.mana - self.db.shiftMana, 0)
end

function DruidManaLib:UpdateEquipMana() self.db.equipBonus = getEquipManaBonus() end

function DruidManaLib:UpdateInnervate() self.db.innervate = hasBuffTexture(INNERVATE_TEXTURE) end

function DruidManaLib:UpdateReflectionRank() self.db.reflectionRank = getReflectionTalentRank() end

function DruidManaLib:IsUsingMana() return UnitPowerType("player") == 0 end

function DruidManaLib:GetMana() return self.db.mana end

function DruidManaLib:GetMaxMana() return self.db.maxMana end

_G["DruidManaLib"] = DruidManaLib
