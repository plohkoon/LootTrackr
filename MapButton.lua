local function log(...)
  print("[LootTrackr MapButton]", ...)
end

local _, addonTable = ...
local uiFrame = addonTable.uiFrame

local minimapButton = CreateFrame("Button", "LootTrackrMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:RegisterForClicks("AnyUp")
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Create the background texture
local background = minimapButton:CreateTexture(nil, "BACKGROUND")
background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
background:SetSize(24, 24)
background:SetPoint("CENTER")

-- Create the icon texture
local icon = minimapButton:CreateTexture(nil, "ARTWORK")
icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")  -- Replace with your icon path
icon:SetSize(20, 20)
icon:SetPoint("CENTER")

-- Create the border texture
local border = minimapButton:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
border:SetSize(54, 54)
border:SetPoint("TOPLEFT")

minimapButton:SetScript("OnClick", function(self, button)
  if button == "LeftButton" then
    log("Left click!")
    uiFrame:toggle()
  elseif button == "RightButton" then
    log("Right click!")
  end
end)
