local AceAddon = LibStub("AceAddon-3.0")
---@class LootTrackr : AceAddon, AceConsole-3.0
local LootTrackr = AceAddon:GetAddon("LootTrackr")
---@class LootTrackrCommands : AceModule, AceConsole-3.0
local LootTrackrCommands = LootTrackr:NewModule("Commands", "AceConsole-3.0")
---@class LootTrackrUI : AceModule, AceConsole-3.0
local LootTrackrUI = LootTrackr:GetModule("UI")

function LootTrackrCommands:OnInitialize()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Initializing the commands module")
  self.db = LootTrackr.db
end

function LootTrackrCommands:OnEnable()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Enabling the commands module")
  self:RegisterChatCommand("loottrackr", "OpenUI")
  self:RegisterChatCommand("lt", "OpenUI")
end

function LootTrackrCommands:OnDisable()
  -- TODO - Settings for addon. Allow logging on
  -- self:Print("Disabling the commands module")
end

function LootTrackrCommands:OpenUI()
  LootTrackrUI:Open()
end
