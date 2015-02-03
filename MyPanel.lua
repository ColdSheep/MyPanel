-----------------------------------------------------------------------------------------------
-- Client Lua Script for MyPanel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- MyPanel Module Definition
-----------------------------------------------------------------------------------------------
local MyPanel = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function MyPanel:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

g_arraySize= 8
g_deltaHealthArray = {}
g_deltaTimeArray = {}

g_back = 0
g_front = g_back+g_arraySize-1
g_prevHealth = 0
g_prevGameTime = 0

function MyPanel:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)

	for i=g_back, g_front do
		g_deltaHealthArray[i] = 0
		g_deltaTimeArray[i] = 0
	end
	
	prevGameTime = GameLib.GetGameTime()
	
end
 

-----------------------------------------------------------------------------------------------
-- MyPanel OnLoad
-----------------------------------------------------------------------------------------------
function MyPanel:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("MyPanel.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- MyPanel OnDocLoaded
-----------------------------------------------------------------------------------------------
function MyPanel:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "MyPanelForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		
	    self.wndMain:Show(false, true)

		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("mypanel", "OnMyPanelOn", self)

		self.timer = ApolloTimer.Create(0.5, true, "OnTimer", self)

		-- Do additional Addon initialization here
	end
end

-----------------------------------------------------------------------------------------------
-- MyPanel Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here

-- on SlashCommand "/mypanel"
function MyPanel:OnMyPanelOn()
	self.wndMain:Invoke() -- show the window
end

function MyPanel:DisplayStatus(targetUnit) --function which displays the status of a unit

	if targetUnit ~= nil then
		local currentHealth = targetUnit:GetHealth()
		local currentGameTime = GameLib.GetGameTime()
		local lastIndex = g_front
		
		g_deltaHealthArray[g_front] = currentHealth - g_prevHealth
		g_deltaTimeArray[g_front] = currentGameTime - g_prevGameTime		
		local totalDeltaHealth = 0
		local totalDeltaTime = 0
		
		self.wndMain:FindChild("Title"):SetText(g_back .. ", " .. g_front)
		
		--find the average delta
		for i=g_back, g_front do
			totalDeltaHealth = totalDeltaHealth + g_deltaHealthArray[i]
			totalDeltaTime  = totalDeltaTime + g_deltaTimeArray[i]
		end
		
		local avgDelta = totalDeltaHealth / totalDeltaTime	
		
		local timeToDeath = -(currentHealth / avgDelta)
		local timeToDeathString = string.format("%.0f",timeToDeath )
		local avgDeltaString = string.format("%.1f",avgDelta)
		
		self.wndMain:FindChild("HealthDelta"):SetText("Avg. Health Delta: " .. avgDeltaString .. " /sec")
		
		
		if timeToDeath > 0 then
			self.wndMain:FindChild("TimeToDeath"):SetText("TtD: " .. timeToDeathString .. " sec(s)")
		else
			self.wndMain:FindChild("TimeToDeath"):SetText("TtD: ---")
		end
		
		g_deltaHealthArray[g_back] = nil
		g_deltaTimeArray[g_back] = nil
		
		--increment current array index for front and back
		g_front = g_front + 1
		g_back = g_back + 1
		
		--record the preious health and game time
		g_prevHealth = currentHealth
		g_prevGameTime = currentGameTime	
	end

end

-- on timer
function MyPanel:OnTimer()
	-- Do your timer-related stuff here.
	--set the latest delta
	local playerUnit = GameLib.GetPlayerUnit()
	
	self:DisplayStatus(playerUnit)
		
end


-----------------------------------------------------------------------------------------------
-- MyPanelForm Functions
-----------------------------------------------------------------------------------------------

-- when the Cancel button is clicked
function MyPanel:OnCancel()
	self.wndMain:Close() -- hide the window
end


-----------------------------------------------------------------------------------------------
-- MyPanel Instance
-----------------------------------------------------------------------------------------------
local MyPanelInst = MyPanel:new()
MyPanelInst:Init()
