local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

---@class LootTrackr : AceAddon, AceConsole-3.0
local LootTrackr = AceAddon:GetAddon("LootTrackr")
---@class LootTrackrUI : AceModule, AceConsole-3.0
local LootTrackrUI = LootTrackr:NewModule("UI", "AceConsole-3.0")

function LootTrackrUI:OnInitialize()
  self:Print("Initializing the UI module")
  self.db = LootTrackr.db

  -- The minimap button
  local dataObject = LDB:NewDataObject("LootTrackr", {
    type = "launcher",
    text = "LootTrackr",
    icon = "Interface\\Icons\\INV_Misc_QuestionMark",
    OnClick = function(clickedFrame, button)
      if button == "LeftButton" then
        self:Open()
      elseif button == "RightButton" then
        -- TODO - Context Menu?
      end
    end,
    OnTooltipShow = function(tooltip)
      tooltip:AddLine("LootTrackr")
      tooltip:AddLine("Click to toggle the UI")
    end,
  })

  LDBIcon:Register("LootTrackr", dataObject, self.db.profile.minimap)
end

function LootTrackrUI:OnEnable()
  self:Print("Enabling the UI module")
end

function LootTrackrUI:OnDisable()
  self:Print("Disabling the UI module")
end

function LootTrackrUI:Open()
  self:Print("Opening the UI")
  ---@type AceGUIFrame
  local frame = AceGUI:Create("Frame")
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
  frame:SetTitle("LootTrackr")
  frame:SetStatusText("Loot tracking time")
  frame:SetLayout("List")

  self:Print("Creating the sidebar")

  local raidEncouterSidebar = AceGUI:Create("TreeGroup")
  raidEncouterSidebar:SetFullHeight(true)
  raidEncouterSidebar:SetFullWidth(true)
  raidEncouterSidebar:SetLayout("Fill")
  raidEncouterSidebar:SetTree(self:BuildEncounterSessionTree())
  frame:AddChild(raidEncouterSidebar)

  local scrollContainer = AceGUI:Create("ScrollFrame")
  scrollContainer:SetLayout("List")
  scrollContainer:SetFullHeight(true)
  scrollContainer:SetFullWidth(true)
  raidEncouterSidebar:AddChild(scrollContainer)

  raidEncouterSidebar:SetCallback("OnGroupSelected", function(widget, event, group)
    local sessionID, encounterID = strsplit("\001", group)

    -- Only update the view if we have a session and encounter
    if sessionID == nil or encounterID == nil then
      return
    end

    scrollContainer:ReleaseChildren()

    self:BuildDropUI(scrollContainer, sessionID, encounterID)

    scrollContainer:DoLayout()
  end)
end

function LootTrackrUI:BuildDropUI(parent, sessionID, encounterID)
  local sessionDrops = self.db.global.drops[sessionID]

  if sessionDrops == nil then
    self:Print("Missing Drops for Session")
    self:MissingDropsUI(parent)
    return
  end

  local nEncounterID = tonumber(encounterID)
  local encounterDrops = sessionDrops[nEncounterID]

  if encounterDrops == nil then
    self:Print("Missing Drops for Encounter")
    self:MissingDropsUI(parent)
    return
  end

  for _, drop in pairs(encounterDrops) do
    parent:AddChild(self:BuildDropItem(drop))
  end
end

function LootTrackrUI:BuildDropItem(drop)
  local itemHyperlink = drop.itemHyperlink

  local dropContainer = AceGUI:Create("SimpleGroup")
  dropContainer:SetLayout("Flow")
  dropContainer:SetFullWidth(true)

  -- Header: Item Information
  local headerGroup = AceGUI:Create("InlineGroup")
  headerGroup:SetTitle("Item Info")
  headerGroup:SetLayout("Flow")
  headerGroup:SetFullWidth(true)

  local headerLabel = AceGUI:Create("Label")
  headerLabel:SetText(drop.itemHyperlink)
  headerLabel:SetFullWidth(true)
  headerGroup:AddChild(headerLabel)

  dropContainer:AddChild(headerGroup)

  -- Table: Players Rolls
  local rollsGroup = AceGUI:Create("InlineGroup")
  rollsGroup:SetTitle("Rolls")
  rollsGroup:SetLayout("List")
  rollsGroup:SetFullWidth(true)

  dropContainer:AddChild(rollsGroup)

  -- Iterate over the rollInfos table to display each player's roll information
  for _, rollInfo in ipairs(drop.rollInfos) do
    local winnerMarker = rollInfo.isWinner and " [Winner]" or ""
    local entryText = string.format("%s (%s): %d%s", 
      rollInfo.playerName, rollInfo.playerClass, rollInfo.roll, winnerMarker)
    
    local rollEntry = AceGUI:Create("Label")
    rollEntry:SetText(entryText)
    rollEntry:SetFullWidth(true)
    rollsGroup:AddChild(rollEntry)
  end

  return dropContainer
end

function LootTrackrUI:MissingDropsUI(parent)
  local missingDropsLabel = AceGUI:Create("Label")
  missingDropsLabel:SetText("Missing Drops")
  missingDropsLabel:SetFullWidth(true)
  parent:AddChild(missingDropsLabel)
end

function LootTrackrUI:BuildEncounterSessionTree()
  local sessions = self.db.global.sessions

  local tree = {}
  for sessionID, session in pairs(sessions) do
    local sessionDateTime = date("%Y-%m-%d", session.startTime)
    local sessionName = session.instanceName

    local label = "(" .. sessionDateTime .. ") " .. sessionName

    local children = self:BuildEncounterTreeForSession(sessionID)

    if children ~= nil and #children ~= 0 then
      local sessionNode = {
        value = sessionID,
        text = label,
        children = children
      }
      table.insert(tree, sessionNode)
    end
  end

  return tree
end

function LootTrackrUI:BuildEncounterTreeForSession(sessionID)
  local encounters = self.db.global.encounters[sessionID]
  local tree = {}

  if encounters == nil then
    return tree
  end

  for encounterID, encounter in pairs(encounters) do
    local encounterNode = { value=encounterID, text=encounter.encounterName }
    table.insert(tree, encounterNode)
  end

  return tree
end
