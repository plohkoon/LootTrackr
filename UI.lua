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

  -- local raidEncouterSidebar = AceGUI:Create("TreeGroup")
  -- raidEncouterSidebar:SetFullHeight(true)
  -- raidEncouterSidebar:SetFullWidth(true)
  -- raidEncouterSidebar:SetLayout("Flow")
  -- raidEncouterSidebar:SetTree(self:BuildEncounterSessionTree())
  -- frame:AddChild(raidEncouterSidebar)

  self:BuildDropdowns(frame)
end

function LootTrackrUI:BuildDropdowns(frame)
  local activeSession = nil

  local dropdownContainer = AceGUI:Create("SimpleGroup")
  dropdownContainer:SetLayout("Flow")
  dropdownContainer:SetFullWidth(true)
  frame:AddChild(dropdownContainer)

  local raidSessionDropdown = AceGUI:Create("Dropdown")
  raidSessionDropdown:SetLabel("Session")
  raidSessionDropdown:SetList(self:BuildSessionList())
  -- raidSessionDropdown:SetWidth(200)
  dropdownContainer:AddChild(raidSessionDropdown)

  local raidEncounterDropdown = AceGUI:Create("Dropdown")
  raidEncounterDropdown:SetLabel("Encounter")
  raidEncounterDropdown:SetList(self:BuildEncounterList())
  -- raidEncounterDropdown:SetWidth(200)
  dropdownContainer:AddChild(raidEncounterDropdown)

  local function changeActiveSession(key)
    activeSession = key
    raidEncounterDropdown:SetList(self:BuildEncounterList(activeSession))
    raidEncounterDropdown:SetValue(nil)
  end

  raidSessionDropdown:SetCallback("OnValueChanged", function (_widget, _event, key)
    changeActiveSession(key)
  end)
end

function LootTrackrUI:BuildSessionList()
  local sessions = self.db.global.sessions
  local sessionList = {}

  for sessionID, session in pairs(sessions) do
    local encounters = self.db.global.encounters[sessionID]
    local sessionDateTime = date("%Y-%m-%d", session.startTime)
    local sessionName = session.instanceName

    local label = "(" .. sessionDateTime .. ") " .. sessionName

    if not (encounters == nil) then
      sessionList[sessionID] = label
    end
  end

  table.sort(sessionList, function (a, b)
    return a[2] < b[2]
  end)

  return sessionList
end

function LootTrackrUI:BuildEncounterList(sessionID)
  local encounters = self.db.global.encounters[sessionID]
  local encounterList = {}

  if encounters == nil then
    return encounterList
  end

  for encounterID, encounter in pairs(encounters) do
    encounterList[encounterID] = encounter.encounterName
  end

  return encounterList
end

function LootTrackrUI:BuildEncounterSessionTree()
  local sessions = self.db.global.sessions

  local tree = {}
  for sessionID, session in pairs(sessions) do
    local sessionDateTime = date("%Y-%m-%d", session.startTime)
    local sessionName = session.instanceName

    local label = "(" .. sessionDateTime .. ") " .. sessionName

    local sessionNode = {
      value=sessionID,
      text=label,
      children=self:BuildEncounterTreeForSession(session)
    }
    table.insert(tree, sessionNode)
  end

  return tree
end

function LootTrackrUI:BuildEncounterTreeForSession(session)
  local encounters = self.db.global.encounters[session]
  local tree = {}

  if encounters == nil or encounters[session.sessionID] == nil then
    return tree
  end

  for encounterID, encounter in pairs(encounters) do
    local encounterNode = { value=encounterID, text=encounter.name }
    table.insert(tree, encounterNode)
  end

  return tree
end
