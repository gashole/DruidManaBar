local _, class = UnitClass("player")
if class ~= "DRUID" then return end

if SUPERWOW_VERSION then
    local function getManaValue(func)
        if DruidManaLib:IsUsingMana() then
            return func("player")
        else
            local _, value = func("player")
            return value
        end
    end

    function DruidManaLib:GetMana() return getManaValue(UnitMana) end

    function DruidManaLib:GetMaxMana() return getManaValue(UnitManaMax) end
else
    DruidManaLib:Init()
end

local DruidManaBar = {}

local TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

function DruidManaBar:Init()
    self.bar = CreateFrame("StatusBar", "DruidManaBar", PlayerFrame, "TextStatusBar")
    self.bar:SetWidth(78)
    self.bar:SetHeight(12)
    self.bar:SetPoint("BOTTOMLEFT", 114, 23)
    self.bar:SetStatusBarTexture(TEXTURE)
    self.bar:SetStatusBarColor(ManaBarColor[0].r, ManaBarColor[0].g, ManaBarColor[0].b)

    self.bar.bg = self.bar:CreateTexture("$parentBackground", "BACKGROUND")
    self.bar.bg:SetAllPoints(self.bar)
    self.bar.bg:SetTexture(TEXTURE)
    self.bar.bg:SetVertexColor(0, 0, 0, 0.5)

    self.bar.bd = self.bar:CreateTexture("$parentBorder", "OVERLAY")
    self.bar.bd:SetWidth(97)
    self.bar.bd:SetHeight(16)
    self.bar.bd:SetPoint("TOPLEFT", -10, 0)
    self.bar.bd:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
    self.bar.bd:SetTexCoord(0.0234375, 0.6875, 1.0, 0.0)

    self.bar.text = self.bar:CreateFontString("$parentText", "OVERLAY", "TextStatusBarText")
    self.bar.text:SetPoint("CENTER", 0, 0)
    SetTextStatusBarText(self.bar, self.bar.text)
    self.bar.textLockable = 1

    self.bar:SetScript("OnMouseUp", function() this:GetParent():Click() end)

    self.frame = CreateFrame("Frame", "DruidManaBarFrame")
    self.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.frame:RegisterEvent("PLAYER_AURAS_CHANGED")
    self.frame:RegisterEvent("UNIT_DISPLAYPOWER")
    self.frame:RegisterEvent("UNIT_MAXMANA")
    self.frame:RegisterEvent("UNIT_MANA")
    self.frame:SetScript("OnEvent", function() self:OnEvent() end)

    self:UpdatePowerType()
end

function DruidManaBar:OnEvent()
    if event == "UNIT_MANA" and arg1 == "player" then
        self:UpdateMana()
    elseif event == "UNIT_MAXMANA" and arg1 == "player" then
        self:UpdateMaxMana()
    elseif event == "UNIT_DISPLAYPOWER" and arg1 == "player" then
        self:UpdatePowerType()
    elseif event == "PLAYER_AURAS_CHANGED" then
        self:UpdateMaxMana()
        self:UpdateMana()
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UpdateMaxMana()
        self:UpdateMana()
        self:UpdatePowerType()
    end
end

function DruidManaBar:UpdateMana()
    if not self.bar:IsShown() then return end
    self.bar:SetValue(DruidManaLib:GetMana())
end

function DruidManaBar:UpdateMaxMana()
    if not self.bar:IsShown() then return end
    self.bar:SetMinMaxValues(0, DruidManaLib:GetMaxMana())
end

function DruidManaBar:UpdatePowerType()
    if DruidManaLib:IsUsingMana() then
        self.bar:Hide()
    else
        self.bar:Show()
    end
end

DruidManaBar:Init()
