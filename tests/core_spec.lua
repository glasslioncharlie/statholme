-- Run from the addon folder: luajit tests/core_spec.lua
local frames = {}
CreateFrame = function()
  local frame = { events = {} }
  function frame:RegisterEvent(event) self.events[event] = true end
  function frame:UnregisterEvent(event) self.events[event] = nil end
  function frame:UnregisterAllEvents() self.events = {} end
  function frame:SetScript(_, handler) self.onEvent = handler end
  table.insert(frames, frame)
  return frame
end

local tickers = {}
local delayed = {}
C_Timer = {
  After = function(_, callback) table.insert(delayed, callback) end,
  NewTicker = function(interval, callback)
    local ticker = { interval = interval, callback = callback, active = true }
    function ticker:Cancel() self.active = false end
    table.insert(tickers, ticker)
    return ticker
  end,
}

local addon = {}
assert(loadfile("Core.lua"))("Statholme", addon)
local coreFrame = frames[1]

local passed, failed = 0, 0
local function check(name, actual, expected)
  if actual == expected then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("FAIL %s: expected %s, got %s", name, tostring(expected), tostring(actual)))
  end
end
local function slotsOf(spot, side)
  return table.concat(addon.GetBar(spot, side).slots, ",")
end

local loaded = 0
addon.OnLoad(function() loaded = loaded + 1 end)

coreFrame.onEvent(coreFrame, "ADDON_LOADED", "SomeOtherAddon")
check("other addons loading are ignored", loaded, 0)

StatholmeDB = {
  bars = {
    minimap = { bottom = { shown = "yes", slots = { "time", "bogus", "fps" } } },
    chat = "broken",
    micro = { top = { shown = true, slots = "broken" } },
  },
  time = { twentyFour = true },
  currencies = { [1792] = true },
}
StatholmeCharDB = {
  chat = {
    [3] = { top = { shown = true, slots = { "gold" } } },
    bogus = {},
  },
}
coreFrame.onEvent(coreFrame, "ADDON_LOADED", "Statholme")
check("load listeners run", loaded, 1)

check("wrong type falls back to default", addon.GetBar("minimap", "bottom").shown, true)
check("unknown readout becomes none, extra slot trimmed", slotsOf("minimap", "bottom"), "time,none")
check("missing bar filled from defaults", addon.GetBar("minimap", "top").shown, false)
check("broken spot replaced by defaults", slotsOf("chat", "bottom"), "mail,bags,durability")
check("broken slot list replaced by default", slotsOf("micro", "top"), "none,none,none")
check("valid setting kept", addon.GetBar("micro", "top").shown, true)
check("saved time option kept", addon.db.time.twentyFour, true)
check("missing time option filled", addon.db.time.server, false)
check("currencies kept", addon.db.currencies[1792], true)
check("window bar kept", addon.GetBar(3, "top").shown, true)
check("short window slot list padded", slotsOf(3, "top"), "gold,none,none")
check("missing window bar filled", addon.GetBar(3, "bottom").shown, false)
check("non-numbered window dropped", StatholmeCharDB.chat.bogus, nil)
check("new window starts off", addon.GetBar(4, "bottom").shown, false)
check("new window starts empty", slotsOf(4, "top"), "none,none,none")

StatholmeDB, StatholmeCharDB = nil, nil
coreFrame.onEvent(coreFrame, "ADDON_LOADED", "Statholme")
check("fresh minimap bottom", slotsOf("minimap", "bottom"), "time,fps")
check("fresh minimap bottom shown", addon.GetBar("minimap", "bottom").shown, true)
check("fresh minimap top hidden", addon.GetBar("minimap", "top").shown, false)
check("fresh chat bottom", slotsOf("chat", "bottom"), "mail,bags,durability")
check("fresh micro bottom hidden", addon.GetBar("micro", "bottom").shown, false)
check("fresh currencies empty", next(addon.db.currencies), nil)

local changes = {}
addon.OnBarChanged(function(spot, side) table.insert(changes, tostring(spot) .. ":" .. side) end)
addon.SetSlotReadout("chat", "top", 2, "gold")
check("slot readout saved", slotsOf("chat", "top"), "none,gold,none")
addon.SetBarShown(5, "bottom", true)
check("window bar shown saved", addon.GetBar(5, "bottom").shown, true)
check("listeners hear both changes", table.concat(changes, " "), "chat:top 5:bottom")

local function newSlot()
  local slot = { text = "untouched" }
  function slot:ShowText(text) self.text = text end
  return slot
end

local updates, enables = 0, 0
local fps = {
  name = "FPS",
  events = { "EVENT_A", "EVENT_B" },
  interval = 1,
  OnEnable = function() enables = enables + 1 end,
  Update = function()
    updates = updates + 1
    return "fps " .. updates
  end,
}
addon.RegisterReadout("fps", fps)
local mail = { name = "Mail", events = { "UPDATE_PENDING_MAIL" }, Update = function() return "Mail: None" end }
addon.RegisterReadout("mail", mail)
check("registry returns the readout", addon.GetReadout("fps"), fps)
check("registered readouts start idle", enables, 0)

local first, second = newSlot(), newSlot()
addon.Bind(first, "fps")
check("first slot enables the readout", enables, 1)
check("enable starts its timer", tickers[1].active, true)
check("timer interval", tickers[1].interval, 1)
check("first slot shows text", first.text, "fps 1")
local readoutFrame = frames[#frames]
check("events registered", readoutFrame.events.EVENT_A and readoutFrame.events.EVENT_B, true)

addon.Bind(second, "fps")
check("second slot doesn't enable again", enables, 1)
check("second slot shows current text", second.text, "fps 1")

tickers[1].callback()
check("timer refresh updates first slot", first.text, "fps 2")
check("timer refresh updates second slot", second.text, "fps 2")
readoutFrame.onEvent(readoutFrame, "EVENT_A")
check("event refresh updates slots", first.text, "fps 3")

addon.Bind(first, "fps")
check("rebinding the same readout does nothing", updates, 3)

addon.Bind(first, nil)
check("unbound slot is cleared", first.text, "")
check("readout keeps running while a slot remains", tickers[1].active, true)

addon.Bind(second, "mail")
check("last slot leaving disables the timer", tickers[1].active, false)
check("last slot leaving unregisters events", next(readoutFrame.events), nil)
check("switched slot shows the new readout", second.text, "Mail: None")

addon.Bind(second, "none")
check("none clears the slot", second.text, "")
check("none unbinds the readout", second.readoutId, nil)

local guildUpdates = 0
local guild = {
  name = "Guild",
  events = { "CLUB_MEMBER_PRESENCE_UPDATED" },
  throttle = 2,
  Update = function()
    guildUpdates = guildUpdates + 1
    return "Guild: " .. guildUpdates
  end,
}
addon.RegisterReadout("guild", guild)
local guildSlot = newSlot()
addon.Bind(guildSlot, "guild")
local guildFrame = frames[#frames]
check("throttled readout refreshes once on enable", guildUpdates, 1)
guildFrame.onEvent(guildFrame, "CLUB_MEMBER_PRESENCE_UPDATED")
guildFrame.onEvent(guildFrame, "CLUB_MEMBER_PRESENCE_UPDATED")
guildFrame.onEvent(guildFrame, "CLUB_MEMBER_PRESENCE_UPDATED")
check("a burst of events doesn't refresh straight away", guildUpdates, 1)
check("a burst of events schedules one refresh", #delayed, 1)
delayed[1]()
check("the scheduled refresh runs once", guildUpdates, 2)
check("the scheduled refresh updates the slot", guildSlot.text, "Guild: 2")
guildFrame.onEvent(guildFrame, "CLUB_MEMBER_PRESENCE_UPDATED")
check("the next event schedules again", #delayed, 2)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
