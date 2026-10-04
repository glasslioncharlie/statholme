local _, addon = ...

local MAX_WINDOWS = Constants.ChatFrameConstants.MaxChatWindows

-- Bars sit on the chat background: above the tabs, and below the edit box's spot.
local host = { top = 26, bottom = 2 }

local function window(index)
  return _G["ChatFrame" .. index]
end

function host.IsActive()
  return true
end

function host.Frame(spot)
  if spot == "chat" then return ChatFrame1.Background end
  return window(spot).Background
end

function host.IsAvailable(spot)
  if spot == "chat" then return GeneralDockManager:IsVisible() end
  local frame = window(spot)
  return frame:IsVisible() and not frame.isDocked
end

function host.OpenWindows()
  local open = {}
  for index = 2, MAX_WINDOWS do
    local frame = window(index)
    if frame:IsShown() and not frame.isDocked then table.insert(open, index) end
  end
  return open
end

function host.WindowName(index)
  return (FCF_GetChatWindowInfo(index))
end

local function spotOf(frame)
  if frame == ChatFrame1 or frame.isDocked then return "chat" end
  return frame:GetID()
end

function host.Watch(onChanged, onTyping)
  GeneralDockManager:HookScript("OnShow", onChanged)
  GeneralDockManager:HookScript("OnHide", onChanged)
  for index = 1, MAX_WINDOWS do
    local frame = window(index)
    frame:HookScript("OnShow", onChanged)
    frame:HookScript("OnHide", onChanged)
    frame.editBox:HookScript("OnEditFocusGained", function(editBox) onTyping(spotOf(editBox.chatFrame), "bottom", true) end)
    frame.editBox:HookScript("OnEditFocusLost", function(editBox) onTyping(spotOf(editBox.chatFrame), "bottom", false) end)
  end
  hooksecurefunc("FCF_DockFrame", onChanged)
  hooksecurefunc("FCF_UnDockFrame", onChanged)
  hooksecurefunc("FCF_Close", onChanged)
end

addon.chatHosts.blizzard = host
