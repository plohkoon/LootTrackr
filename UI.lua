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
  frame:SetLayout("Flow")
end
