local _, addon = ...

local MAX_WINDOWS = Constants.ChatFrameConstants.MaxChatWindows
local MINIMAP_GAP = 2
local CHAT_TOP, CHAT_BOTTOM = 26, 2
local MICRO_TOP, MICRO_BOTTOM = 2, 2

local spots = {}
local openWindows = ""
local windowListeners = {}

function addon.OnWindowsChanged(listener)
  table.insert(windowListeners, listener)
end

local function attach(bar, frame, top, bottom)
  bar:ClearAllPoints()
  if bar.side == "top" then
    bar:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, top)
    bar:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, top)
  else
    bar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -bottom)
    bar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -bottom)
  end
end

local function addSpot(spot, count, frame, top, bottom)
  local pair = {}
  for _, side in ipairs({ "top", "bottom" }) do
    pair[side] = addon.CreateBar(spot, side, count)
    attach(pair[side], frame, top, bottom)
  end
  spots[spot] = pair
end

local function edges(frame)
  local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
  return frame:GetTop() * scale, frame:GetBottom() * scale
end

local function placeMinimapBars()
  local mapTop, mapBottom = edges(Minimap)
  local clusterTop, clusterBottom = edges(MinimapCluster)
  attach(spots.minimap.top, Minimap, clusterTop - mapTop + MINIMAP_GAP, 0)
  attach(spots.minimap.bottom, Minimap, 0, mapBottom - clusterBottom + MINIMAP_GAP)
end

local function setAvailable(spot, available)
  for _, bar in pairs(spots[spot]) do
    bar.available = available
    bar:Update()
  end
end

local function updateMinimap()
  setAvailable("minimap", Minimap:IsVisible())
end

local function updateMicro()
  setAvailable("micro", MicroMenuContainer:IsVisible())
end

local function updateChat()
  setAvailable("chat", GeneralDockManager:IsVisible())
  for index = 2, MAX_WINDOWS do
    local frame = _G["ChatFrame" .. index]
    setAvailable(index, frame:IsVisible() and not frame.isDocked)
  end
  -- Chat frames show and hide on every tab switch.
  local open = table.concat(addon.OpenWindows(), ",")
  if open ~= openWindows then
    openWindows = open
    for _, listener in ipairs(windowListeners) do listener() end
  end
end

local function chatSpot(frame)
  if frame == ChatFrame1 or frame.isDocked then return "chat" end
  return frame:GetID()
end

local function setTyping(editBox, typing)
  local bar = spots[chatSpot(editBox.chatFrame)].bottom
  bar.typing = typing
  bar:Update()
end

function addon.SpotName(spot)
  if spot == "minimap" then return "Minimap" end
  if spot == "chat" then return "Main chat" end
  if spot == "micro" then return "Micro menu" end
  return (FCF_GetChatWindowInfo(spot))
end

function addon.OpenWindows()
  local open = {}
  for index = 2, MAX_WINDOWS do
    local frame = _G["ChatFrame" .. index]
    if frame:IsShown() and not frame.isDocked then table.insert(open, index) end
  end
  return open
end

addon.OnLoad(function()
  addSpot("minimap", addon.SLOT_COUNTS.minimap, Minimap, 0, 0)
  addSpot("micro", addon.SLOT_COUNTS.micro, MicroMenuContainer, MICRO_TOP, MICRO_BOTTOM)
  addSpot("chat", addon.SLOT_COUNTS.chat, ChatFrame1.Background, CHAT_TOP, CHAT_BOTTOM)
  for index = 2, MAX_WINDOWS do
    addSpot(index, addon.SLOT_COUNTS.window, _G["ChatFrame" .. index].Background, CHAT_TOP, CHAT_BOTTOM)
  end

  Minimap:HookScript("OnShow", updateMinimap)
  Minimap:HookScript("OnHide", updateMinimap)
  MicroMenuContainer:HookScript("OnShow", updateMicro)
  MicroMenuContainer:HookScript("OnHide", updateMicro)
  GeneralDockManager:HookScript("OnShow", updateChat)
  GeneralDockManager:HookScript("OnHide", updateChat)
  for index = 1, MAX_WINDOWS do
    local frame = _G["ChatFrame" .. index]
    frame:HookScript("OnShow", updateChat)
    frame:HookScript("OnHide", updateChat)
    frame.editBox:HookScript("OnEditFocusGained", function(editBox) setTyping(editBox, true) end)
    frame.editBox:HookScript("OnEditFocusLost", function(editBox) setTyping(editBox, false) end)
  end
  hooksecurefunc("FCF_DockFrame", updateChat)
  hooksecurefunc("FCF_UnDockFrame", updateChat)
  hooksecurefunc("FCF_Close", updateChat)
  hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", placeMinimapBars)
  EventRegistry:RegisterCallback("EditMode.Exit", placeMinimapBars, addon)

  addon.OnBarChanged(function(spot, side) spots[spot][side]:Update() end)

  local events = CreateFrame("Frame")
  events:RegisterEvent("PLAYER_ENTERING_WORLD")
  events:RegisterEvent("UI_SCALE_CHANGED")
  events:RegisterEvent("DISPLAY_SIZE_CHANGED")
  events:RegisterEvent("UPDATE_CHAT_WINDOWS")
  events:RegisterEvent("UPDATE_FLOATING_CHAT_WINDOWS")
  events:SetScript("OnEvent", function()
    placeMinimapBars()
    updateMinimap()
    updateMicro()
    updateChat()
  end)
end)
