local AceAddon = LibStub("AceAddon-3.0")
---@class LootTrackr : AceAddon, AceConsole-3.0
local LootTrackr = AceAddon:GetAddon("LootTrackr")
---@class LootTrackrEvents : AceModule, AceConsole-3.0, AceEvent-3.0
local LootTrackrEvents = LootTrackr:NewModule("Events", "AceEvent-3.0", "AceConsole-3.0")

function LootTrackrEvents:OnInitialize()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Initializing the event tracking module")
  self.db = LootTrackr.db

  self.sessions = self.db.global.sessions
  self.encounters = self.db.global.encounters
  self.drops = self.db.global.drops
  self.currentSession = nil
end

function LootTrackrEvents:OnEnable()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Enabling the event tracking module")
  -- self:RegisterEvent("START_LOOT_ROLL")
  -- self:RegisterEvent("LOOT_ITEM_AVAILABLE")
  -- self:RegisterEvent("LOOT_ROLLS_COMPLETE")
  -- self:RegisterEvent("CONFIRM_LOOT_ROLL")

  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  self:RegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER")
  self:RegisterEvent("LOOT_HISTORY_UPDATE_DROP")
end

function LootTrackrEvents:OnDisable()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Disabling the event tracking module")
end

-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/Mainline/LootHistory.lua

----------------------
-- Event handlers
----------------------

function LootTrackrEvents:LOOT_HISTORY_UPDATE_ENCOUNTER(_eventName, encounterID)
  -- self:Print("Loot history updated", encounterID)

  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local encounter = C_LootHistory.GetInfoForEncounter(encounterID)

  if encounter == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No encounter found, skipping")
    return
  end

  self:appendEncounterToSession(encounter)
  local drops = C_LootHistory.GetSortedDropsForEncounter(encounterID)

  if drops == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No drops found, skipping")
    return
  end

  for _, drop in ipairs(drops) do
    self:appendDropToEncounter(encounter, drop)
  end
end

function LootTrackrEvents:LOOT_HISTORY_UPDATE_DROP(_eventName, encounterID, lootListID)
  -- self:Print("Loot history drop updated", encounterID, lootListID)

  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local encounter = C_LootHistory.GetInfoForEncounter(encounterID)

  if encounter == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No encounter found, skipping")
    return
  end

  self:appendEncounterToSession(encounter)

  local info = C_LootHistory.GetSortedInfoForDrop(encounterID, lootListID)

  if info == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No drop found, skipping")
    return
  end

  self:appendDropToEncounter(encounter, info)
end

function LootTrackrEvents:PLAYER_ENTERING_WORLD()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Player entering world")
  self:updateSessionIfRequired()
end

function LootTrackrEvents:ZONE_CHANGED_NEW_AREA()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Player changed zone")
  self:updateSessionIfRequired()
end


function LootTrackrEvents:START_LOOT_ROLL(_eventName, rollID, rollTime, lootHandle)
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Starting Loot Roll", rollID, rollTime, lootHandle)
end

function LootTrackrEvents:LOOT_ITEM_AVAILABLE(_eventName, itemTooltip, lootHandle)
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("A new loot item is available", itemTooltip, lootHandle)
end

function LootTrackrEvents:LOOT_ROLLS_COMPLETE(_eventName, lootHandle)
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("A loot roll is complete", lootHandle)
end

function LootTrackrEvents:CONFIRM_LOOT_ROLL(_eventName, rollID, rollType, confirmReason)
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("A loot roll has been confirmed", rollID, rollType, confirmReason)
end

----------------------
-- Utility functions
----------------------

function LootTrackrEvents:generateSessionID()
  local playerGUID = UnitGUID("player")  -- Get the player's GUID
  local startTime = GetServerTime()      -- Get the current server time
  local instanceID = select(8, GetInstanceInfo()) or "0"  -- Get the instance ID
  local difficultyID = select(3, GetInstanceInfo()) or "0"  -- Get the difficulty ID
  local sessionID = string.format("%s-%s-%s-%s", playerGUID, startTime, instanceID, difficultyID)
  return sessionID
end

-- Getter for current session
function LootTrackrEvents:session()
  if self.currentSession == nil then
    return nil
  else
    return self.sessions[self.currentSession]
  end
end

-- End the current session
function LootTrackrEvents:endSession()
  if self.currentSession == nil then
    return
  end

  self:session().endTime = GetServerTime()
  self.currentSession = nil
end

-- Starts a new session and saves it to the data store
function LootTrackrEvents:startSession()
  local instanceName, _, difficultyID, difficultyName, _, _, _, instanceID = GetInstanceInfo()

  self.currentSession = self:generateSessionID()
  self.sessions[self.currentSession] = {
    sessionID = self.currentSession,
    instanceID = instanceID,
    instanceName = instanceName,
    difficultID = difficultyID,
    difficultName = difficultyName,
    startTime = GetServerTime(),
  }
end

function LootTrackrEvents:updateSessionIfRequired()
  local inInstance, instanceType = IsInInstance()
  local instanceID = select(8, GetInstanceInfo())

  if inInstance and instanceType == "raid" then
    if self.currentSession == nil then
      -- TODO - Settings for addon. Allow logging on
      -- self:Print("Player entering raid, starting session")
      self:startSession()
    elseif self.sessions[self.currentSession].instanceID ~= instanceID then
      -- TODO - Settings for addon. Allow logging on
      -- self:Print("Player shifted instance, starting a new session")
      self:endSession()
      self:startSession()
    end
  elseif inInstance and self.currentSession ~= nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("Player leaving raid, ending session")
    self:endSession()
  end
end

function LootTrackrEvents:appendEncounterToSession(encounter)
  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local sessionEncounters = self.encounters[self.currentSession]
  if sessionEncounters == nil then
    self.encounters[self.currentSession] = {}
    sessionEncounters = self.encounters[self.currentSession]
  end


  sessionEncounters[encounter.encounterID] = encounter
end

---@param encounter EncounterLootInfo
---@param drop EncounterLootDropInfo
function LootTrackrEvents:appendDropToEncounter(encounter, drop)
  if self.currentSession == nil then
    -- TODO - Settings for addon. Allow logging on
    -- self:Print("No session, skipping")
    return
  end

  local sessionDrops = self.drops[self.currentSession]
  if sessionDrops == nil then
    self.drops[self.currentSession] = {}
    sessionDrops = self.drops[self.currentSession]
  end

  local encounterDrops = sessionDrops[encounter.encounterID]
  if encounterDrops == nil then
    sessionDrops[encounter.encounterID] = {}
    encounterDrops = sessionDrops[encounter.encounterID]
  end

  encounterDrops[drop.lootListID] = drop
end
