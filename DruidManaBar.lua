if playerClass ~= "DRUID" then return end

local DruidManaBar = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")
local DruidManaLib = AceLibrary("DruidManaLib-1.0")

local TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

-- Overwrite this function or the mana cost from shapeshifting will be subtracted twice
function DruidManaLib:Subtract()
	-- Do nothing
end

function DruidManaBar:OnInitialize()
	local bar = CreateFrame("StatusBar", "DruidManaBar", PlayerFrame, "TextStatusBar")
	bar:SetWidth(78)
	bar:SetHeight(12)
	bar:SetPoint("BOTTOMLEFT", 114, 23)
	bar:SetStatusBarTexture(TEXTURE)
	bar:SetStatusBarColor(ManaBarColor[0].r, ManaBarColor[0].g, ManaBarColor[0].b)

	local bg = bar:CreateTexture("$parentBackground", "BACKGROUND")
	bg:SetAllPoints(bar)
	bg:SetTexture(TEXTURE)
	bg:SetVertexColor(0, 0, 0, 0.5)

	local bd = bar:CreateTexture("$parentBorder", "OVERLAY")
	bd:SetWidth(97)
	bd:SetHeight(16)
	bd:SetPoint("TOPLEFT", -10, 0)
	bd:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
	bd:SetTexCoord(0.0234375, 0.6875, 1.0, 0.0)

	local text = bar:CreateFontString("$parentText", "OVERLAY", "TextStatusBarText")
	text:SetPoint("CENTER", 0, 0)
	SetTextStatusBarText(bar, text)
	bar.textLockable = 1

	self.bar = bar
end

function DruidManaBar:OnEnable()
	self:RegisterEvent("UNIT_MANA")
	self:RegisterEvent("UNIT_MAXMANA")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_AURAS_CHANGED")

	self.bar:SetScript("OnMouseUp", function(button)
		this:GetParent():Click(button)
	end)

	self:UNIT_DISPLAYPOWER()
end

function DruidManaBar:UNIT_MANA()
	if not self.bar:IsShown() then return end
	if UnitIsUnit("player", arg1) then
		self:UpdateValue()
	end
end

function DruidManaBar:UNIT_MAXMANA()
	if not self.bar:IsShown() then return end
	if UnitIsUnit("player", arg1) then
		self:UpdateMaxValues()
	end
end

function DruidManaBar:UNIT_DISPLAYPOWER()
	self:UpdateMaxValues()
	self:UpdateValue()
	self:UpdatePowerType()
end

function DruidManaBar:PLAYER_AURAS_CHANGED()
	if not self.bar:IsShown() then return end
	self:UNIT_DISPLAYPOWER()
end

function DruidManaBar:UpdateValue()
	local curMana = DruidManaLib:GetMana()
	self.bar:SetValue(curMana)
end

function DruidManaBar:UpdateMaxValues()
	DruidManaLib:MaxManaScript()
	local _, maxMana = DruidManaLib:GetMana()
	self.bar:SetMinMaxValues(0, maxMana)
end

function DruidManaBar:UpdatePowerType()
	if self.loaded and UnitPowerType("player") ~= 0 then
		self.bar:Show()
	else
		self.bar:Hide()
		self.loaded = true -- so we don't show a mana bar with bogus values
	end
end