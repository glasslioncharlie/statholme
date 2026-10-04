local _, addon = ...

local MINIMAP_GAP = 2
local MICRO_TOP, MICRO_BOTTOM = 2, 2
-- The first one running wins; Blizzard's chat is the fallback.
local CHAT_HOSTS = { "chattynator", "blizzard" }

local spots = {}
local chat
local openWindows = ""
local windowListeners = {}

function addon.OnWindowsChanged(listener)
  table.insert(windowListeners, listener)
end

-- A covering bar keeps its usual height, centred on the frame and inset from its sides.
local function attach(bar, frame, top, bottom, inset)
  bar.anchor, bar.inset = frame, inset
  bar:ClearAllPoints()
  if inset then
    bar:SetPoint("LEFT", frame, "LEFT", inset, 0)
    bar:SetPoint("RIGHT", frame, "RIGHT", -inset, 0)
  elseif bar.side == "top" then
    bar:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, top)
    bar:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, top)
  else
    bar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -bottom)
    bar:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -bottom)
  end
end

local function addSpot(spot)
  local count = addon.SLOT_COUNTS[spot] or addon.SLOT_COUNTS.window
  spots[spot] = { top = addon.CreateBar(spot, "top", count), bottom = addon.CreateBar(spot, "bottom", count) }
end

local function attachSpot(spot, frame, top, bottom)
  for _, bar in pairs(spots[spot]) do attach(bar, frame, top, bottom) end
end

-- Chat addons can hand a window to a different frame, e.g. after closing another window.
local function chatBars(spot)
  if not spots[spot] then addSpot(spot) end
  for side, bar in pairs(spots[spot]) do
    local frame, inset = chat.Frame(spot, side)
    if frame and (bar.anchor ~= frame or bar.inset ~= inset) then attach(bar, frame, chat.top, chat.bottom, inset) end
  end
  return spots[spot]
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

local function isChatSpot(spot)
  return spot == "chat" or type(spot) == "number"
end

local function updateChat()
  local windows = chat.OpenWindows()
  for _, index in ipairs(windows) do chatBars(index) end
  for spot in pairs(spots) do
    if isChatSpot(spot) then
      chatBars(spot)
      setAvailable(spot, chat.IsAvailable(spot))
    end
  end
  -- Chat frames show and hide on every tab switch.
  local open = table.concat(windows, ",")
  if open ~= openWindows then
    openWindows = open
    for _, listener in ipairs(windowListeners) do listener() end
  end
end

local function setTyping(spot, side, typing)
  local bar = chatBars(spot)[side]
  bar.typing = typing
  bar:Update()
end

function addon.SpotName(spot)
  if spot == "minimap" then return "Minimap" end
  if spot == "chat" then return "Main chat" end
  if spot == "micro" then return "Micro menu" end
  return chat.WindowName(spot)
end

function addon.OpenWindows()
  return chat.OpenWindows()
end

addon.OnLoad(function()
  for _, name in ipairs(CHAT_HOSTS) do
    chat = addon.chatHosts[name]
    if chat.IsActive() then break end
  end

  addSpot("minimap")
  attachSpot("minimap", Minimap, 0, 0)
  addSpot("micro")
  attachSpot("micro", MicroMenuContainer, MICRO_TOP, MICRO_BOTTOM)
  chatBars("chat")

  Minimap:HookScript("OnShow", updateMinimap)
  Minimap:HookScript("OnHide", updateMinimap)
  MicroMenuContainer:HookScript("OnShow", updateMicro)
  MicroMenuContainer:HookScript("OnHide", updateMicro)
  chat.Watch(updateChat, setTyping)
  hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", placeMinimapBars)
  EventRegistry:RegisterCallback("EditMode.Exit", placeMinimapBars, addon)

  -- Window bars are only made once their window first opens.
  addon.OnBarChanged(function(spot, side)
    if spots[spot] then spots[spot][side]:Update() end
  end)

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
