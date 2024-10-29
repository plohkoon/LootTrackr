local uiFrame = CreateFrame("Frame", "LootTrackrUI", UIParent, "BasicFrameTemplateWithInset")

local _, addonTable = ...
addonTable.uiFrame = uiFrame

local function log(...)
  print("[LootTrackr UI]", ...)
end

uiFrame:SetSize(300, 200)
uiFrame:SetPoint("CENTER")
uiFrame.title = uiFrame:CreateFontString(nil, "OVERLAY")
uiFrame.title:SetFontObject("GameFontHighlight")
uiFrame.title:SetPoint("LEFT", uiFrame.TitleBg, "LEFT", 5, 0)
uiFrame.title:SetText("LootTrackr")

uiFrame:Hide()

function uiFrame:toggle()
  if uiFrame:IsVisible() then
    log("Hiding UI")
    uiFrame:Hide()
  else
    log("Showing UI")
    uiFrame:Show()
  end
end

SLASH_LootTrackr1 = "/loottrackr"
SLASH_LootTrackr2 = "/lt"
SlashCmdList["LootTrackr"] = uiFrame["toggle"]
