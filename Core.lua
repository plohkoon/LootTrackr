local AceAddon = LibStub("AceAddon-3.0")
---@class LootTrackr : AceAddon, AceConsole-3.0
local LootTrackr = AceAddon:NewAddon("LootTrackr", "AceConsole-3.0")

function LootTrackr:OnInitialize()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Loot tracking time")
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Initializing the addon")

  self.db = LibStub("AceDB-3.0"):New("LootTrackrDB", {
    global ={
      ---@type table<string, table> @ A table mapping session IDS to some session Data
      sessions = {},
      ---@type table<string, table<string, table>> @ A table mapping session and encounter IDS to the encounter Data
      encounters = {},
      ---@type table<string, table<string, table<string, table>>> @ A table mapping session, encounter, and drop IDS to the drop Data
      drops = {}
    },
    profile = {
      minimap = {
        hide = false
      },
    },
  })
end

function LootTrackr:OnEnable()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Enabling the addon")
end

function LootTrackr:OnDisable()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Disabling the addon")
end
