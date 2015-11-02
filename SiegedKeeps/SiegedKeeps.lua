--[[

Sieged Keeps
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Addon info
SiegedKeeps = {}
SiegedKeeps.name = "Sieged Keeps"

-- Libraries
local LMP = LibStub("LibMapPins-1.0")

-- Constatnts
local NUM_KEEPS = 144  -- GetNumKeeps() returns 93 which isn't what we need
local COLOR_AD = "|cF9F280"
local COLOR_DC = "|c7CA4C5"
local COLOR_EP = "|cDC564A"
local COLOR_ESO = "|cC5C29E"
local PIN_TYPE_SIEGE = SiegedKeeps.name.." siege"
local PIN_ICON_DIR = "SiegedKeeps/icons/"
local PIN_ICON_AD       = PIN_ICON_DIR.."pin_AD.dds"
local PIN_ICON_DC       = PIN_ICON_DIR.."pin_DC.dds"
local PIN_ICON_EP       = PIN_ICON_DIR.."pin_EP.dds"
local PIN_ICON_AD_DC    = PIN_ICON_DIR.."pin_AD_DC.dds"
local PIN_ICON_AD_EP    = PIN_ICON_DIR.."pin_AD_EP.dds"
local PIN_ICON_DC_EP    = PIN_ICON_DIR.."pin_DC_EP.dds"
local PIN_ICON_AD_DC_EP = PIN_ICON_DIR.."pin_AD_DC_EP.dds"

-- Settings (TODO: Maybe move to settings menu)
local REFRESH_INTERVAL_MS = 5000
local PIN_SIZE = 70
local PIN_SIZE_RESOURCE = 40
local PIN_LEVEL = 10

-- Local variables
local isReadyForRefresh = true


-- Function to get the correct battleground context
local function GetBattlegroundContext()
	local bgquery = BGQUERY_UNKNOWN 
	if GetCurrentCampaignId() == GetAssignedCampaignId() then
		bgquery = BGQUERY_ASSIGNED_CAMPAIGN
	else
		bgquery = BGQUERY_LOCAL 
	end
	return bgquery
end

-- Callback function which is called every time another map is viewed, creates quest pins
local function MapCallbackQuestPins()
	-- if ZO_WorldMap:IsHidden() then return end
	if LMP:GetZoneAndSubzone(true) ~= "cyrodiil/ava_whole" then return end	
	
	for i=1, NUM_KEEPS, 1 do
		local ad = GetNumSieges(i, GetBattlegroundContext(), ALLIANCE_ALDMERI_DOMINION)
		local ep = GetNumSieges(i, GetBattlegroundContext(), ALLIANCE_EBONHEART_PACT)
		local dc = GetNumSieges(i, GetBattlegroundContext(), ALLIANCE_DAGGERFALL_COVENANT)
		if ad+ep+dc > 0 then
			-- Smaller icon for resources
			if GetKeepType(i) == KEEPTYPE_RESOURCE then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "size", PIN_SIZE_RESOURCE)
			else
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "size", PIN_SIZE)
			end
			 
			-- Set correct pin icon
			if ad > 0 and dc > 0 and ep > 0 then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "texture", PIN_ICON_AD_DC_EP)
			elseif ad > 0 and dc > 0 then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "texture", PIN_ICON_AD_DC)
			elseif ad > 0 and ep > 0 then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "texture", PIN_ICON_AD_EP)
			elseif dc > 0 and ep > 0 then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "texture", PIN_ICON_DC_EP)
			elseif ad > 0 then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "texture", PIN_ICON_AD)
			elseif dc > 0 then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "texture", PIN_ICON_DC)
			elseif ep > 0 then
				LMP:SetLayoutKey(PIN_TYPE_SIEGE, "texture", PIN_ICON_EP)
			else -- Never reached
			end
			
			-- Create tooltip text
			local pinInfo = {COLOR_ESO.."Siege: "}
			if ad > 0 then pinInfo[1] = pinInfo[1]..COLOR_AD..tostring(ad).."  " end
			if dc > 0 then pinInfo[1] = pinInfo[1]..COLOR_DC..tostring(dc).."  " end
			if ep > 0 then pinInfo[1] = pinInfo[1]..COLOR_EP..tostring(ep) end
			pinInfo[1] = pinInfo[1]:gsub("%s+$", "")
			
			-- Get keep position and create pin
			local pinType, normalizedX, normalizedY = GetKeepPinInfo(i, GetBattlegroundContext())
			LMP:CreatePin(PIN_TYPE_SIEGE, pinInfo, normalizedX, normalizedY)
		end
	end
	
	-- Refresh in the defined interval
	if isReadyForRefresh then
		isReadyForRefresh = false
		-- Set the variable 100 ms before refreshing to avoid multiple parallel loops
		zo_callLater(function() isReadyForRefresh = true end, REFRESH_INTERVAL_MS - 100)
		zo_callLater(function() LMP:RefreshPins(PIN_TYPE_SIEGE) end, REFRESH_INTERVAL_MS)
	end
end

-- Event handler function for EVENT_PLAYER_ACTIVATED
local function OnPlayerActivated(event)
	-- Get tootip of each individual pin
	local pinTooltipCreator = {
		creator = function(pin)
			local _, pinTag = pin:GetPinTypeAndTag()
			for _, lineData in ipairs(pinTag) do
				SetTooltipText(InformationTooltip, lineData)
			end
		end,
		tooltip = 1,
	}
	local pinLayout = {size = PIN_SIZE, level = PIN_LEVEL}
	LMP:AddPinType(PIN_TYPE_SIEGE, MapCallbackQuestPins, nil, pinLayout, pinTooltipCreator)
	
	EVENT_MANAGER:UnregisterForEvent(SiegedKeeps.name, EVENT_PLAYER_ACTIVATED)
end

-- Registering the event handler functions for the events
EVENT_MANAGER:RegisterForEvent(SiegedKeeps.name, EVENT_PLAYER_ACTIVATED, OnPlayerActivated)