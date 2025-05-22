-- 本地化表
local locale = GetLocale()
GLayout_L = {}

if locale == "zhCN" or locale == "zhTW" then
  GLayout_L = {
    CONFIRM_OK = "确定",
    CONFIRM_LATER = "稍后",
    CONFIRM_CANCEL = "取消",
    SAVE_CONFIRM = "确定要保存当前设置吗？这将覆盖之前的设置。",
    ADDON_TITLE = "GLayout 设置",
    SAVE_CHAT_CONFIG = "保存聊天配置",
    APPLY_CHAT_CONFIG = "应用聊天配置",
    SAVE_KEYBINDINGS = "保存按键",
    APPLY_KEYBINDINGS = "应用按键",
    CHAT_SAVED = "聊天配置已保存。",
    CHAT_APPLIED = "聊天配置已应用。",
    KEYBINDINGS_SAVED = "按键绑定已保存。",
    KEYBINDINGS_APPLIED = "按键绑定已应用。",
    FORCE_OVERWRITE = "登录时强制覆盖",
    CHAT_SETTINGS = "聊天设置",
    KEYBINDING_SETTINGS = "按键绑定设置",
    ERROR_NO_CHATFRAME = "聊天窗口 ChatFrame%d 不存在。",
    ERROR_NO_KEYBINDINGS = "没有保存的按键绑定。"
  }
else
  GLayout_L = {
    CONFIRM_OK = "OK",
    CONFIRM_LATER = "Later",
    CONFIRM_CANCEL = "Cancel",
    SAVE_CONFIRM = "Are you sure you want to save current settings? This will overwrite previous settings.",
    ADDON_TITLE = "GLayout Settings",
    SAVE_CHAT_CONFIG = "Save Chat Config",
    APPLY_CHAT_CONFIG = "Apply Chat Config",
    SAVE_KEYBINDINGS = "Save Keybindings",
    APPLY_KEYBINDINGS = "Apply Keybindings",
    CHAT_SAVED = "Chat configuration saved.",
    CHAT_APPLIED = "Chat configuration applied.",
    KEYBINDINGS_SAVED = "Keybindings saved.",
    KEYBINDINGS_APPLIED = "Keybindings applied.",
    FORCE_OVERWRITE = "Force Overwrite on Login",
    CHAT_SETTINGS = "Chat Settings",
    KEYBINDING_SETTINGS = "Keybinding Settings",
    ERROR_NO_CHATFRAME = "Chat window ChatFrame%d does not exist.",
    ERROR_NO_KEYBINDINGS = "No saved keybindings."
  }
end

local L = GLayout_L
local CreateFrame, StaticPopup_Show = CreateFrame, StaticPopup_Show
local GetChatWindowInfo, SetChatWindowName, SetChatWindowSize = GetChatWindowInfo, SetChatWindowName, SetChatWindowSize
local GetChatWindowMessages, GetChatWindowChannels = GetChatWindowMessages, GetChatWindowChannels
local SetChatWindowColor, SetChatWindowAlpha = SetChatWindowColor, SetChatWindowAlpha
local SetChatWindowShown, SetChatWindowLocked = SetChatWindowShown, SetChatWindowLocked
local SetChatWindowDocked, SetChatWindowUninteractable = SetChatWindowDocked, SetChatWindowUninteractable
local AddChatWindowMessages, RemoveChatWindowMessages = AddChatWindowMessages, RemoveChatWindowMessages
local AddChatWindowChannel, RemoveChatWindowChannel = AddChatWindowChannel, RemoveChatWindowChannel
local ChangeChatColor, SetChatColorNameByClass = ChangeChatColor, SetChatColorNameByClass
local GetNumBindings, GetBinding, GetBindingKey, SetBinding, SaveBindings = GetNumBindings, GetBinding, GetBindingKey, SetBinding, SaveBindings
local pairs, strlower, C_Timer, table, math = pairs, strlower, C_Timer, table, math

local GLayout = CreateFrame("FRAME")
GLayout:RegisterEvent("ADDON_LOADED")
GLayout:RegisterEvent("UPDATE_CHAT_COLOR")
GLayout:RegisterEvent("LOADING_SCREEN_DISABLED")
GLayout:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS")

local chatColours = {}

StaticPopupDialogs["GLAYOUT_CONFIRM_SAVE"] = {
  text = L.SAVE_CONFIRM,
  button1 = L.CONFIRM_OK,
  button2 = L.CONFIRM_CANCEL,
  OnAccept = function() GLayout_Save_Chat_Impl() end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- 辅助函数：更新聊天窗口消息和频道
local function UpdateChatWindowSettings(frameID, cfg)
  local f = _G["ChatFrame"..frameID]
  if not f then return end
  
  local oldMsgs = {GetChatWindowMessages(frameID)}
  for _, msg in ipairs(oldMsgs) do RemoveChatWindowMessages(frameID, msg) end
  if cfg.messages and #cfg.messages > 0 then
    for _, msg in ipairs(cfg.messages) do AddChatWindowMessages(frameID, msg) end
  end
  
  if cfg.channels and #cfg.channels > 0 then
    local oldChannels = {GetChatWindowChannels(frameID)}
    for _, channel in ipairs(oldChannels) do RemoveChatWindowChannel(frameID, channel) end
    for _, channel in ipairs(cfg.channels) do AddChatWindowChannel(frameID, channel) end
  end
end

function GLayout_Save_Chat_Impl()
  if not GLayoutDB then GLayoutDB = {} end
  
  GLayoutDB.chatFrames = {}
  for i=1,10 do
    local f = _G["ChatFrame"..i]
    if not f then break end
    local point, _, _, xOfs, yOfs = f:GetPoint()
    local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(i)
    
    GLayoutDB.chatFrames[i] = {
      width = f:GetWidth(),
      height = f:GetHeight(),
      point = point,
      xOfs = xOfs,
      yOfs = yOfs,
      name = name,
      fontSize = fontSize,
      r = r,
      g = g,
      b = b,
      alpha = alpha,
      shown = shown,
      locked = locked,
      docked = docked,
      uninteractable = uninteractable,
      messages = {GetChatWindowMessages(f:GetID())},
      channels = {GetChatWindowChannels(f:GetID())},
      parent = f:GetParent():GetName()
    }
  end
  GLayoutDB.channelColours = chatColours
  print("|cFF33FF99GLayout:|r " .. L.CHAT_SAVED)
end

function GLayout_Save_Chat()
  StaticPopup_Show("GLAYOUT_CONFIRM_SAVE")
end

function GLayout_Assimilate_Chat(frames)
  pcall(function()
    for i=1,10 do
      local f = _G["ChatFrame"..i]
      local cfg = frames[i]
      if not f or not cfg or not _G[cfg.parent] then
        if not f then print("|cFF33FF99GLayout:|r " .. L.ERROR_NO_CHATFRAME:format(i)) end
        break
      end
      
      f:SetParent(_G[cfg.parent])
      UpdateChatWindowSettings(i, cfg)
      
      SetChatWindowName(i, cfg.name)
      SetChatWindowSize(i, cfg.fontSize)
      SetChatWindowColor(i, cfg.r, cfg.g, cfg.b)
      SetChatWindowAlpha(i, cfg.alpha)
      SetChatWindowShown(i, cfg.shown)
      SetChatWindowLocked(i, cfg.locked)
      SetChatWindowDocked(i, cfg.docked)
      SetChatWindowUninteractable(i, cfg.uninteractable)
      
      if f:IsMovable() then
        f:ClearAllPoints()
        f:SetWidth(cfg.width)
        f:SetHeight(cfg.height)
        f:SetPoint(cfg.point, cfg.xOfs, cfg.yOfs)
        f:SetUserPlaced(true)
      end
    end
    
    if GLayoutDB.channelColours then
      for chatType, colorInfo in pairs(GLayoutDB.channelColours) do
        if colorInfo[2] and colorInfo[3] and colorInfo[4] then
          ChangeChatColor(colorInfo[1], colorInfo[2], colorInfo[3], colorInfo[4])
        end
        if colorInfo[5] ~= nil then
          SetChatColorNameByClass(colorInfo[1], colorInfo[5])
        end
      end
    end
    print("|cFF33FF99GLayout:|r " .. L.CHAT_APPLIED)
  end)
end

function GLayout_Save_Keybindings()
  if not GLayoutDB then GLayoutDB = {} end
  GLayoutDB.keybindings = {}
  
  local numBindings = GetNumBindings()
  for index = 1, numBindings do
    local command, key1, key2 = GetBinding(index)
    if command then
      GLayoutDB.keybindings[index] = {command = command, key1 = key1, key2 = key2}
    end
  end
  SaveBindings(GetCurrentBindingSet())
  print("|cFF33FF99GLayout:|r " .. L.KEYBINDINGS_SAVED)
end

function GLayout_Apply_Keybindings()
  if not GLayoutDB or not GLayoutDB.keybindings or #GLayoutDB.keybindings == 0 then
    print("|cFF33FF99GLayout:|r " .. L.ERROR_NO_KEYBINDINGS)
    return
  end
  
  -- 清除当前所有绑定
  for index = 1, GetNumBindings() do
    local command = GetBinding(index)
    if command then
      local key1, key2 = GetBindingKey(command)
      if key1 then
        pcall(SetBinding, key1, nil)
      end
      if key2 then
        pcall(SetBinding, key2, nil)
      end
    end
  end
  
  -- 应用保存的绑定
  for _, binding in ipairs(GLayoutDB.keybindings) do
    if binding.command then
      if binding.key1 then
        pcall(SetBinding, binding.key1, binding.command)
      end
      if binding.key2 then
        pcall(SetBinding, binding.key2, binding.command)
      end
      -- 清除不需要的第二按键
      local currentKey1, currentKey2 = GetBindingKey(binding.command)
      if not binding.key2 and currentKey2 then
        pcall(SetBinding, currentKey2, nil)
      end
    end
  end
  
  SaveBindings(GetCurrentBindingSet())
  print("|cFF33FF99GLayout:|r " .. L.KEYBINDINGS_APPLIED)
end

GLayout:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    local addon = ...
    if addon == "GLayout" then
      -- Initialize database
      if not GLayoutDB then GLayoutDB = {} end
      -- Create the settings panel during initialization
      GLayout_CreateSettingsPanel()
    end
  elseif event == "UPDATE_CHAT_COLOR" then
    local chatType, r, g, b = ...
    chatColours[chatType] = {chatType, r, g, b}
  elseif event == "UPDATE_CHAT_COLOR_NAME_BY_CLASS" then
    local chatType = ...
    -- Assume class-based coloring is enabled unless explicitly disabled
    local colorByClass = true -- Default to true; adjust based on your needs
    if chatColours[chatType] then
      chatColours[chatType][5] = colorByClass
    else
      -- Initialize with default color (white) if no color info exists
      chatColours[chatType] = {chatType, 1, 1, 1, colorByClass}
    end
  elseif event == "LOADING_SCREEN_DISABLED" then
    -- Handle any loading screen disabled logic if needed
  end
end)

-- Add slash command to open the settings panel
SLASH_GLAYOUT1 = "/glo"
SlashCmdList["GLAYOUT"] = function()
  local panel = _G["GLayoutSettingsPanel"]
  if panel then
    if panel:IsShown() then
      panel:Hide()
    else
      panel:Show()
    end
  else
    print("|cFF33FF99GLayout:|r Settings panel not found. Please reload the UI.")
  end
end