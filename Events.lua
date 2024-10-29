local eventFrame = CreateFrame("Frame")

local addonName, addonTable = ...
addonTable.eventFrame = eventFrame

print("Loot tracking time")

-- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/Mainline/LootHistory.lua

function eventFrame:OnEvent(event, ...)
  self[event](self, ...)
end

function eventFrame:START_LOOT_ROLL(rollID, rollTime, lootHandle)
  print("Starting Loot Roll", rollID, rollTime, lootHandle)
end

function eventFrame:LOOT_ITEM_AVAILABLE(itemTooltip, lootHandle)
  print("A new loot item is available", itemTooltip, lootHandle)
end

function eventFrame:LOOT_ROLLS_COMPLETE(lootHandle)
  print("A loot roll is complete", lootHandle)
end

function eventFrame:CONFIRM_LOOT_ROLL(rollID, rollType, confirmReason)
  print("A loot roll has been confirmed", rollID, rollType, confirmReason)
end

local function log(...)
  print("[LootTrackr Event]", ...)
end

function eventFrame:generateSessionID()
  local playerGUID = UnitGUID("player")  -- Get the player's GUID
  local startTime = GetServerTime()      -- Get the current server time
  local instanceID = select(8, GetInstanceInfo()) or "0"  -- Get the instance ID
  local difficultyID = select(3, GetInstanceInfo()) or "0"  -- Get the difficulty ID
  local sessionID = string.format("%s-%s-%s-%s", playerGUID, startTime, instanceID, difficultyID)
  return sessionID
end

function eventFrame:ADDON_LOADED(name, ...)
  if name == addonName then
    log("Initializing LootTrackr")

    -- Ensure the session data is loaded. We do this or {} thing to preserve
    -- memory references so the data gets saved once the user logs out.

    if LootTrackrSessionData == nil then
      log("No SessionData, initializing")
      LootTrackrSessionData = {}
    end

    if LootTrackrEncounterData == nil then
      log("No EncounterData, initializing")
      LootTrackrEncounterData = {}
    end

    if LootTrackrDropData == nil then
      log("No DropData, initializing")
      LootTrackrDropData = {}
    end

    self.sessions = LootTrackrSessionData
    self.encounters = LootTrackrEncounterData
    self.currentSession = nil
    self.drops = LootTrackrDropData
  end
end

-- Getter for current session
function eventFrame:session()
  if self.currentSession == nil then
    return nil
  else
    return self.sessions[self.currentSession]
  end
end

-- End the current session
function eventFrame:endSession()
  if self.currentSession == nil then
    return
  end

  self:session().endTime = GetServerTime()
  self.currentSession = nil
end

-- Starts a new session and saves it to the data store
function eventFrame:startSession()
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

function eventFrame:updateSessionIfRequired()
  local inInstance, instanceType = IsInInstance()
  local instanceID = select(8, GetInstanceInfo())

  if inInstance and instanceType == "raid" then
    if self.currentSession == nil then
      log("Player entering raid, starting session")
      self:startSession()
    elseif self.sessions[self.currentSession].instanceID ~= instanceID then
      log("Player shifted instance, starting a new session")
      self:endSession()
      self:startSession()
    end
  elseif inInstance and self.currentSession ~= nil then
    log("Player leaving raid, ending session")
    self:endSession()
  end
end

function eventFrame:PLAYER_ENTERING_WORLD()
  self:updateSessionIfRequired()
end

function eventFrame:ZONE_CHANGED_NEW_AREA()
  self:updateSessionIfRequired()
end

function eventFrame:appendEncounterToSession(encounter)
  if self.currentSession == nil then
    log("No session, skipping")
    return
  end

  if self.encounters[self.currentSession] == nil then
    self.encounters[self.currentSession] = {}
  end

  self.encounters[self.currentSession] = self.encounters[self.currentSession] or {}
  local encounters = self.encounters[self.currentSession]

  encounters[encounter.encounterID] = encounter
end

function eventFrame:appendDropToEncounter(encounter, drop)
  if self.currentSession == nil then
    log("No session, skipping")
    return
  end

  if self.encounters[encounter.encounterID] == nil then
    log("No encounter, skipping")
    return
  end

  local drops = self.drops[encounter.encounterID] or {}
  drops[drop.lootListID] = drop
end

function eventFrame:LOOT_HISTORY_UPDATE_ENCOUNTER(encounterID)
  print("Loot history updated", encounterID)

  if self.currentSession == nil then
    log("No session, skipping")
    return
  end

  local encounter = C_LootHistory.GetInfoForEncounter(encounterID)

  if encounter == nil then
    log("No encounter found, skipping")
    return
  end

  self:appendEncounterToSession(encounter)
  local drops = C_LootHistory.GetSortedDropsForEncounter(encounterID)

  if drops == nil then
    log("No drops found, skipping")
    return
  end

  for _, drop in ipairs(drops) do
    self:appendDropToEncounter(encounter, drop)
  end
end

function eventFrame:LOOT_HISTORY_UPDATE_DROP(encounterID, lootListID)
  print("Loot history drop updated", encounterID, lootListID)

  if self.currentSession == nil then
    log("No session, skipping")
    return
  end

  local encounter = C_LootHistory.GetInfoForEncounter(encounterID)

  if encounter == nil then
    log("No encounter found, skipping")
    return
  end

  self:appendEncounterToSession(encounter)

  local info = C_LootHistory.GetSortedInfoForDrop(encounterID, lootListID)

  if info == nil then
    log("No drop found, skipping")
    return
  end

  self:appendDropToEncounter(encounter, info)
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("LOOT_HISTORY_UPDATE_ENCOUNTER")
eventFrame:RegisterEvent("LOOT_HISTORY_UPDATE_DROP")

eventFrame:SetScript("OnEvent", eventFrame.OnEvent)
