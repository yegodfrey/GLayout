local L = GLayout_L
local CreateFrame = CreateFrame

function GLayout_CreateSettingsPanel()
  local panel = CreateFrame("Frame", "GLayoutSettingsPanel", UIParent, "BackdropTemplate")
  panel:SetSize(400, 300)
  panel:SetPoint("CENTER")
  panel:SetFrameStrata("HIGH")
  
  panel:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  panel:SetBackdropColor(0, 0, 0, 1)
  
  panel:Hide()
  panel:SetClampedToScreen(true)
  panel:SetMovable(true)
  panel:EnableMouse(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", panel.StartMoving)
  panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
  
  local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -20)
  title:SetText(L.ADDON_TITLE)
  
  -- 第一行：聊天设置表头
  local chatSectionTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  chatSectionTitle:SetPoint("TOPLEFT", 30, -50)
  chatSectionTitle:SetText(L.CHAT_SETTINGS)
  
  -- 第二行：保存聊天配置、应用聊天配置按钮
  local saveChatButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  saveChatButton:SetSize(120, 25)
  saveChatButton:SetPoint("TOPLEFT", 30, -80)
  saveChatButton:SetText(L.SAVE_CHAT_CONFIG)
  saveChatButton:SetScript("OnClick", function() GLayout_Save_Chat() end)
  
  local applyChatButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  applyChatButton:SetSize(120, 25)
  applyChatButton:SetPoint("TOPRIGHT", -30, -80)
  applyChatButton:SetText(L.APPLY_CHAT_CONFIG)
  applyChatButton:SetScript("OnClick", function()
    if GLayoutDB.chatFrames and #GLayoutDB.chatFrames > 0 then
      GLayout_Assimilate_Chat(GLayoutDB.chatFrames)
    else
      print("|cFF33FF99GLayout:|r 没有保存的聊天配置")
    end
  end)
  
  -- 第三行：按键绑定表头
  local keybindingSectionTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  keybindingSectionTitle:SetPoint("TOPLEFT", 30, -120)
  keybindingSectionTitle:SetText(L.KEYBINDING_SETTINGS)
  
  -- 第四行：保存按键、应用按键按钮
  local saveKeybindingsButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  saveKeybindingsButton:SetSize(120, 25)
  saveKeybindingsButton:SetPoint("TOPLEFT", 30, -150)
  saveKeybindingsButton:SetText(L.SAVE_KEYBINDINGS)
  saveKeybindingsButton:SetScript("OnClick", function() GLayout_Save_Keybindings() end)
  
  local applyKeybindingsButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  applyKeybindingsButton:SetSize(120, 25)
  applyKeybindingsButton:SetPoint("TOPRIGHT", -30, -150)
  applyKeybindingsButton:SetText(L.APPLY_KEYBINDINGS)
  applyKeybindingsButton:SetScript("OnClick", function() GLayout_Apply_Keybindings() end)
  
  -- 第五行：强制覆盖复选框
  local forceOverwriteCheckbox = CreateFrame("CheckButton", "GLayoutForceOverwriteCheckbox", panel, "UICheckButtonTemplate")
  forceOverwriteCheckbox:SetPoint("TOPLEFT", 30, -190)
  forceOverwriteCheckbox:SetChecked(GLayoutDB and GLayoutDB.forceOverwrite)
  forceOverwriteCheckbox.text = forceOverwriteCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  forceOverwriteCheckbox.text:SetPoint("LEFT", forceOverwriteCheckbox, "RIGHT", 5, 0)
  forceOverwriteCheckbox.text:SetText(L.FORCE_OVERWRITE)
  forceOverwriteCheckbox:SetScript("OnClick", function(self) 
    if not GLayoutDB then GLayoutDB = {} end
    GLayoutDB.forceOverwrite = self:GetChecked() 
  end)
  
  local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -5, -5)
  closeButton:SetScript("OnClick", function() panel:Hide() end)
  
  _G["GLayoutSettingsPanel"] = panel
  return panel
end