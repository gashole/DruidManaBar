local _, playerClass = UnitClass("player")
if playerClass ~= "DRUID" then return end

local DruidManaBar = AceLibrary("AceAddon-2.0"):new("AceConsole-2.0", "AceEvent-2.0", "AceDB-2.0")
local DruidManaLib = AceLibrary("DruidManaLib-1.0")
local L = AceLibrary("AceLocale-2.2"):new("DruidManaBar")

local TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"

function DruidManaBar:OnInitialize()
	self:RegisterDB("DruidManaBarDB")
	self:RegisterDefaults("profile", { moveAbove = false })
	self:RegisterChatCommand({ "/druidmanabar", "/dmb" }, {
		type = "group",
		args = {
			moveabove = {
				type = "toggle",
				name = L["Move Above"],
				desc = L["Move the bar above the player frame."],
				get = "IsMoveAbove",
				set = "ToggleMoveAbove",
			},
		},
	})
end

function DruidManaBar:OnEnable()
	if not self.bar then
		local bar = CreateFrame("StatusBar", "DruidManaBar", PlayerFrame, "TextStatusBar")
		bar:SetWidth(78)
		bar:SetHeight(12)
		bar:SetStatusBarTexture(TEXTURE)
		bar:SetStatusBarColor(ManaBarColor[0].r, ManaBarColor[0].g, ManaBarColor[0].b)

		local bg = bar:CreateTexture("$parentBackground", "BACKGROUND")
		bg:SetAllPoints(bar)
		bg:SetTexture(TEXTURE)
		bg:SetVertexColor(0, 0, 0, 0.5)
		bar.bg = bg

		local bd = bar:CreateTexture("$parentBorder", "OVERLAY")
		bd:SetWidth(97)
		bd:SetHeight(16)
		bd:SetTexture("Interface\\CharacterFrame\\UI-CharacterFrame-GroupIndicator")
		bar.bd = bd

		local text = bar:CreateFontString("$parentText", "OVERLAY", "TextStatusBarText")
		text:SetPoint("CENTER", 0, 0)
		SetTextStatusBarText(bar, text)
		bar.textLockable = 1
		bar.text = text

		bar:SetScript("OnMouseUp", function(button)
			this:GetParent():Click(button)
		end)

		bar:SetScript("OnUpdate", function()
			local curMana, maxMana = DruidManaLib:GetMana()
			this:SetMinMaxValues(0, maxMana)
			this:SetValue(curMana)
		end)
		
		self.bar = bar
	end

	self:UpdatePosition()

	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_AURAS_CHANGED")

	self:UpdatePowerType()
end

function DruidManaBar:OnDisable()
	self.bar:Hide()
end

function DruidManaBar:UNIT_DISPLAYPOWER()
	self:UpdatePowerType()
end

function DruidManaBar:PLAYER_AURAS_CHANGED()
	if not self.bar:IsShown() then return end
	self:UpdatePowerType()
end

function DruidManaBar:IsMoveAbove()
	return self.db.profile.moveAbove
end

function DruidManaBar:ToggleMoveAbove()
	self.db.profile.moveAbove = not self.db.profile.moveAbove
	self:UpdatePosition()
end

function DruidManaBar:UpdatePosition()
	self.bar:ClearAllPoints()
	if self.db.profile.moveAbove then
		self.bar:SetPoint("TOPLEFT", 114, -10)
		self.bar.bd:SetPoint("TOPLEFT", -10, 4)
		self.bar.bd:SetTexCoord(0.0234375, 0.6875, 0.0, 1.0)
	else
		self.bar:SetPoint("BOTTOMLEFT", 114, 23)
		self.bar.bd:SetPoint("TOPLEFT", -10, 0)
		self.bar.bd:SetTexCoord(0.0234375, 0.6875, 1.0, 0.0)
	end
end

function DruidManaBar:UpdatePowerType()
	if self.loaded and UnitPowerType("player") ~= 0 then
		self.bar:Show()
	else
		self.bar:Hide()
		self.loaded = true -- so we don't show a mana bar with bogus values
	end
end