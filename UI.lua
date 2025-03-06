local AceAddon = LibStub("AceAddon-3.0")
local AceGUI = LibStub("AceGUI-3.0")
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

---@class LootTrackr : AceAddon, AceConsole-3.0
local LootTrackr = AceAddon:GetAddon("LootTrackr")
---@class LootTrackrUI : AceModule, AceConsole-3.0
local LootTrackrUI = LootTrackr:NewModule("UI", "AceConsole-3.0")

function LootTrackrUI:OnInitialize()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Initializing the UI module")
  self.db = LootTrackr.db

  -- The minimap button
  local dataObject = LDB:NewDataObject("LootTrackr", {
    type = "launcher",
    text = "LootTrackr",
    icon = "Interface\\AddOns\\LootTrackr\\Assets\\LootTrackr_icon.png",
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
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Enabling the UI module")
end

function LootTrackrUI:OnDisable()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Disabling the UI module")
end

function LootTrackrUI:Open()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Opening the UI")
  ---@type AceGUIFrame
  local frame = AceGUI:Create("Frame")
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
  frame:SetTitle("LootTrackr")
  frame:SetStatusText("Loot tracking time")
  frame:SetLayout("List")

  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Creating the sidebar")

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
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("Missing Drops for Session")
    self:MissingDropsUI(parent)
    return
  end

  local nEncounterID = tonumber(encounterID)
  local encounterDrops = sessionDrops[nEncounterID]

  if encounterDrops == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("Missing Drops for Encounter")
    self:MissingDropsUI(parent)
    return
  end

  for _, drop in pairs(encounterDrops) do
    parent:AddChild(self:BuildDropItem(drop))
  end
end

function LootTrackrUI:BuildDropItem(drop)
  -- Create the main container
  local dropContainer = AceGUI:Create("InlineGroup")
  dropContainer:SetTitle(drop.itemHyperlink)
  dropContainer:SetLayout("Flow")
  dropContainer:SetFullWidth(true)

  -- Header: Item Information

  local itemInfo = self:BuildItemInfo(drop.itemHyperlink)
  dropContainer:AddChild(itemInfo)

  local rollHeading = AceGUI:Create("Heading")
  rollHeading:SetText("Rolls")
  rollHeading:SetFullWidth(true)
  dropContainer:AddChild(rollHeading)

  local rollTable = AceGUI:Create("SimpleGroup")
  rollTable:SetLayout("List")
  rollTable:SetFullWidth(true)
  dropContainer:AddChild(rollTable)

  local tableHeader = self:BuildRollRow({
    "",
    "Name",
    "Class",
    "Roll Type",
    "Roll"
  })
  rollTable:AddChild(tableHeader)

  -- Create a row for each player's roll
  for _, rollInfo in ipairs(drop.rollInfos) do
    local icon = ""
    local playerName = rollInfo.playerName
    local playerClass = rollInfo.playerClass
    local rollTypeString = (function()
      local switch = {
        [0] = "Need",
        [1] = "Need (OS)",
        [2] = "Transmog",
        [3] = "Greed",
        [4] = "",
        [5] = "Pass"
      }
      return switch[rollInfo.state] or ""
    end)()

    -- Convert to switch statement

    local roll = rollInfo.roll

    if rollInfo.isWinner then
      icon = "Interface\\Icons\\INV_Misc_Coin_01"
    end

    if roll == nil then
      roll = ""
    end

    local rowGroup = self:BuildRollRow({
      icon,
      playerName,
      playerClass,
      rollTypeString,
      roll
    })
    rollTable:AddChild(rowGroup)
  end

  return dropContainer
end

function LootTrackrUI:BuildItemInfo(sItemLink)
  local itemID, itemType, itemSubType, itemEquipLoc, icon, _, _ = C_Item.GetItemInfoInstant(sItemLink)

  local itemInfoGroup = AceGUI:Create("SimpleGroup")
  itemInfoGroup:SetLayout("Flow")
  itemInfoGroup:SetFullWidth(true)

  local itemIcon = AceGUI:Create("Label")
  itemIcon:SetImage(icon)
  itemIcon:SetImageSize(50, 50)
  itemIcon:SetWidth(60)
  itemInfoGroup:AddChild(itemIcon)

  local detailsGroup = AceGUI:Create("SimpleGroup")
  detailsGroup:SetLayout("List")
  itemInfoGroup:AddChild(detailsGroup)

  local itemNameLabel = AceGUI:Create("Label")
  itemNameLabel:SetText("Item Name: " .. "N/A")
  itemNameLabel:SetFullWidth(true)
  detailsGroup:AddChild(itemNameLabel)

  local itemLevelLabel = AceGUI:Create("Label")
  itemLevelLabel:SetText("Item Level: " .. "N/A")
  itemLevelLabel:SetFullWidth(true)
  detailsGroup:AddChild(itemLevelLabel)

  local item = Item:CreateFromItemLink(sItemLink)
  item:ContinueOnItemLoad(function()
    local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent = C_Item.GetItemInfo(sItemLink)
    local actualIlvl, previewLvl, sparseItemLvl = C_Item.GetDetailedItemLevelInfo(sItemLink)

    itemNameLabel:SetText("Item Name: " .. itemName)
    itemLevelLabel:SetText("Item Level: " .. actualIlvl)
  end)

  return itemInfoGroup
end

function LootTrackrUI:BuildRollRow(columns)
  local rowGroup = AceGUI:Create("SimpleGroup")
  rowGroup:SetLayout("Flow")
  rowGroup:SetFullWidth(true)

  local iconColumn = AceGUI:Create("Label")
  iconColumn:SetWidth(20)
  iconColumn:SetHeight(10)
  iconColumn:SetImageSize(15, 15)
  iconColumn:SetImage(columns[1])
  rowGroup:AddChild(iconColumn)

  -- Name column
  local nameLabel = AceGUI:Create("Label")
  nameLabel:SetText(columns[2])
  nameLabel:SetWidth(100)
  local classColor = RAID_CLASS_COLORS[columns[3]]
  if classColor ~= nil then
    nameLabel:SetColor(classColor.r, classColor.g, classColor.b)
  end
  rowGroup:AddChild(nameLabel)

  -- Roll Type column (for now, simply "Roll")
  local rollTypeLabel = AceGUI:Create("Label")
  rollTypeLabel:SetText(columns[4])
  rollTypeLabel:SetWidth(80)
  rowGroup:AddChild(rollTypeLabel)

  -- Roll column
  local rollLabel = AceGUI:Create("Label")
  rollLabel:SetText(columns[5])
  rollLabel:SetWidth(50)
  rowGroup:AddChild(rollLabel)

  return rowGroup
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
        startTime = session.startTime,
        value = sessionID,
        text = label,
        children = children
      }
      table.insert(tree, sessionNode)
    end
  end

  -- Intentionally reverse sort by start time
  -- so more recent sessions are at the top
  table.sort(tree, function(a, b)
    return a.startTime > b.startTime
  end)

  return tree
end

function LootTrackrUI:BuildEncounterTreeForSession(sessionID)
  local encounters = self.db.global.encounters[sessionID]
  local tree = {}

  if encounters == nil then
    return tree
  end

  for encounterID, encounter in pairs(encounters) do
    local encounterNode = {
      value = encounterID,
      text=encounter.encounterName,
      startTime = encounter.startTime
    }
    table.insert(tree, encounterNode)
  end

  -- Intentionally sort in order of encounter start time
  -- This list is shorter then sessions so we want it forward in time
  table.sort(tree, function(a, b)
    return a.startTime < b.startTime
  end)

  return tree
end
