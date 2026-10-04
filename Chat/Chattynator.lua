local _, addon = ...

-- Chattynator's windows hold their own tabs, so bars sit just outside them.
local host = { top = 2, bottom = 2 }
-- The input's border is drawn this far inside its frame on each side, at a font scaling of 1.
local EDIT_BOX_INSET = 7

-- Chattynator doesn't expose its windows, so find them among its hyperlink handler's children.
local function windowFrames()
  local frames = {}
  for _, child in ipairs({ ChattynatorHyperlinkHandler:GetChildren() }) do
    -- Closed windows go back to Chattynator's pool with an ID of 0.
    if child.TabsBar and child:GetID() > 0 then frames[child:GetID()] = child end
  end
  return frames
end

function host.IsActive()
  return C_AddOns.IsAddOnLoaded("Chattynator") and ChattynatorHyperlinkHandler ~= nil
end

-- Chattynator puts the edit box inside the top or bottom of the main window.
local function editBoxSide(main)
  local _, relativeTo, relativePoint = ChatFrame1EditBox:GetPoint(1)
  if relativeTo ~= main then return nil end
  return relativePoint == "BOTTOMLEFT" and "bottom" or "top"
end

function host.Frame(spot, side)
  local frame = windowFrames()[spot == "chat" and 1 or spot]
  -- Like Blizzard's chat, the bar on the edit box's side takes its place.
  if frame and spot == "chat" and side == editBoxSide(frame) then
    return ChatFrame1EditBox, EDIT_BOX_INSET * ChatFrame1EditBox:GetScale()
  end
  return frame
end

function host.IsAvailable(spot)
  local frame = host.Frame(spot)
  return frame ~= nil and frame:IsVisible()
end

function host.OpenWindows()
  local open = {}
  for index, frame in pairs(windowFrames()) do
    if index > 1 and frame:IsShown() then table.insert(open, index) end
  end
  table.sort(open)
  return open
end

function host.WindowName(index)
  local tabs = Chattynator.API.GetWindowsAndTabs()[index]
  local name = tabs and tabs[1]
  if not name then return "Window " .. index end
  -- Some tab names are stored as the key of a localized global string, e.g. GENERAL.
  return type(_G[name]) == "string" and _G[name] or name
end

function host.Watch(onChanged, onTyping)
  local hooked, pending = {}, false
  local hook

  local function changed()
    -- Closing a window renumbers the rest after it hides, so wait for that to finish.
    if pending then return end
    pending = true
    C_Timer.After(0, function()
      pending = false
      for _, frame in pairs(windowFrames()) do hook(frame) end
      onChanged()
    end)
  end

  function hook(frame)
    if hooked[frame] then return end
    hooked[frame] = true
    frame:HookScript("OnShow", changed)
    frame:HookScript("OnHide", changed)
    -- A brand new window shows before we can hook it, but opening one refreshes every window's tabs.
    hooksecurefunc(frame.TabsBar, "RefreshTabs", changed)
    hooksecurefunc(frame, "UpdateEditBox", changed)
  end

  for _, frame in pairs(windowFrames()) do hook(frame) end

  ChatFrame1EditBox:HookScript("OnEditFocusGained", function()
    local side = editBoxSide(windowFrames()[1])
    if side then onTyping("chat", side, true) end
  end)
  ChatFrame1EditBox:HookScript("OnEditFocusLost", function()
    onTyping("chat", "top", false)
    onTyping("chat", "bottom", false)
  end)
end

addon.chatHosts.chattynator = host
