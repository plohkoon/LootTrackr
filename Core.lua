local AceAddon = LibStub("AceAddon-3.0")
---@class LootTrackr : AceAddon, AceConsole-3.0
local LootTrackr = AceAddon:NewAddon("LootTrackr", "AceConsole-3.0")

function LootTrackr:OnInitialize()
  self:Print("Loot tracking time")
  self:Print("Initializing the addon")

  self.db = LibStub("AceDB-3.0"):New("LootTrackrDB", {
    global ={
      sessions = {},
      encounters = {},
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
  self:Print("Enabling the addon")
end

function LootTrackr:OnDisable()
  self:Print("Disabling the addon")
end
