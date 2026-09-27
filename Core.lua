local addonName, addon = ...

addon.READOUT_ORDER = {
  "time", "fps", "ping", "friends", "guild", "mail", "bags",
  "durability", "gold", "location", "spec", "memory", "itemlevel",
}
addon.SLOT_COUNTS = { minimap = 2, chat = 3, micro = 3, window = 3 }

local known = { none = true }
for _, id in ipairs(addon.READOUT_ORDER) do known[id] = true end

local function bar(shown, slots)
  return { shown = shown, slots = slots }
end

local function none(count)
  local slots = {}
  for i = 1, count do slots[i] = "none" end
  return slots
end

local DEFAULTS = {
  bars = {
    minimap = { top = bar(false, none(2)), bottom = bar(true, { "time", "fps" }) },
    chat = { top = bar(false, none(3)), bottom = bar(true, { "mail", "bags", "durability" }) },
    micro = { top = bar(false, none(3)), bottom = bar(false, none(3)) },
  },
  time = { server = false, twentyFour = false },
  currencies = {},
}
local WINDOW_DEFAULT = { top = bar(false, none(3)), bottom = bar(false, none(3)) }

local function copy(value)
  if type(value) ~= "table" then return value end
  local out = {}
  for key, item in pairs(value) do out[key] = copy(item) end
  return out
end

local function cleanSlots(saved, default)
  if type(saved) ~= "table" then return copy(default) end
  local slots = {}
  for i = 1, #default do
    slots[i] = known[saved[i]] and saved[i] or "none"
  end
  return slots
end

local function clean(saved, default)
  if type(saved) ~= type(default) then return copy(default) end
  if type(default) ~= "table" then return saved end
  for key, value in pairs(default) do
    if key == "slots" then
      saved.slots = cleanSlots(saved.slots, value)
    else
      saved[key] = clean(saved[key], value)
    end
  end
  return saved
end

local loadListeners, barListeners = {}, {}

function addon.OnLoad(listener)
  table.insert(loadListeners, listener)
end

function addon.OnBarChanged(listener)
  table.insert(barListeners, listener)
end

function addon.GetBar(spot, side)
  if type(spot) == "number" then
    local window = addon.charDB.chat[spot]
    if not window then
      window = copy(WINDOW_DEFAULT)
      addon.charDB.chat[spot] = window
    end
    return window[side]
  end
  return addon.db.bars[spot][side]
end

local function barChanged(spot, side)
  for _, listener in ipairs(barListeners) do listener(spot, side) end
end

function addon.SetBarShown(spot, side, shown)
  addon.GetBar(spot, side).shown = shown
  barChanged(spot, side)
end

function addon.SetSlotReadout(spot, side, index, id)
  addon.GetBar(spot, side).slots[index] = id
  barChanged(spot, side)
end

local readouts = {}
local boundSlots = {}

function addon.GetReadout(id)
  return readouts[id]
end

function addon.SetText(readout, text)
  readout.text = text
  for slot in pairs(boundSlots[readout.id]) do slot:ShowText(text) end
end

function addon.RegisterReadout(id, readout)
  readout.id = id
  readouts[id] = readout
  boundSlots[id] = {}

  local frame, ticker, pending
  function readout.Refresh()
    addon.SetText(readout, readout.Update())
  end

  local function onEvent()
    if not readout.throttle then return readout.Refresh() end
    if pending then return end
    pending = true
    C_Timer.After(readout.throttle, function()
      pending = false
      readout.Refresh()
    end)
  end

  function readout.Enable()
    if readout.events then
      frame = frame or CreateFrame("Frame")
      frame:SetScript("OnEvent", onEvent)
      for _, event in ipairs(readout.events) do frame:RegisterEvent(event) end
    end
    if readout.interval then
      ticker = C_Timer.NewTicker(readout.interval, readout.Refresh)
    end
    if readout.OnEnable then readout.OnEnable() end
    readout.Refresh()
  end

  function readout.Disable()
    if frame then frame:UnregisterAllEvents() end
    if ticker then
      ticker:Cancel()
      ticker = nil
    end
  end
end

function addon.Bind(slot, id)
  if id == "none" then id = nil end
  local old = slot.readoutId
  if old == id then return end
  if old then
    local slots = boundSlots[old]
    slots[slot] = nil
    if not next(slots) then readouts[old].Disable() end
  end
  slot.readoutId = id
  if not id then
    slot:ShowText("")
    return
  end
  local slots = boundSlots[id]
  local first = not next(slots)
  slots[slot] = true
  if first then readouts[id].Enable() end
  slot:ShowText(readouts[id].text or "")
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, _, name)
  if name ~= addonName then return end
  self:UnregisterEvent("ADDON_LOADED")
  StatholmeDB = clean(StatholmeDB, DEFAULTS)
  StatholmeCharDB = clean(StatholmeCharDB, { chat = {} })
  for index, window in pairs(StatholmeCharDB.chat) do
    StatholmeCharDB.chat[index] = type(index) == "number" and clean(window, WINDOW_DEFAULT) or nil
  end
  addon.db, addon.charDB = StatholmeDB, StatholmeCharDB
  for _, listener in ipairs(loadListeners) do listener() end
end)
