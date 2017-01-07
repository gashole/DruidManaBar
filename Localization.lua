if playerClass ~= "DRUID" then return end

local L = AceLibrary("AceLocale-2.2"):new("DruidManaBar")

local function enUS() return {
	["Move Above"] = true,
	["Move the bar above the player frame."] = true,
} end

L:RegisterTranslations("enUS", enUS)
L:RegisterTranslations("enGB", enUS)