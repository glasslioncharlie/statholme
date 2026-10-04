-- Run from the addon folder: luajit tests/chattynator_spec.lua
local passed, failed = 0, 0
local function check(name, actual, expected)
  if actual == expected then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("FAIL %s: expected %s, got %s", name, tostring(expected), tostring(actual)))
  end
end

local function newFrame(id, shown)
  local frame = { id = id, shown = shown, scripts = {} }
  function frame:GetID() return self.id end
  function frame:IsShown() return self.shown end
  function frame:IsVisible() return self.shown end
  function frame:HookScript(script, handler) self.scripts[script] = handler end
  return frame
end

local function newWindow(id, shown)
  local frame = newFrame(id, shown)
  frame.TabsBar = { RefreshTabs = function() end }
  frame.UpdateEditBox = function() end
  return frame
end

local children = {}
ChattynatorHyperlinkHandler = {
  GetChildren = function() return unpack(children) end,
}
local loaded = true
C_AddOns = { IsAddOnLoaded = function(name) return loaded and name == "Chattynator" end }
local windowNames = { { "GENERAL" }, { "Trade" }, {}, { "Guild" } }
Chattynator = { API = { GetWindowsAndTabs = function() return windowNames end } }
GENERAL = "General"

local delayed = {}
C_Timer = { After = function(_, callback) table.insert(delayed, callback) end }
local hooks = {}
hooksecurefunc = function(target, method, hook)
  hooks[target] = hooks[target] or {}
  hooks[target][method] = hook
end

local addon = { chatHosts = {} }
assert(loadfile("Chat/Chattynator.lua"))("Statholme", addon)
local host = addon.chatHosts.chattynator

local main, trade, closed, guild = newWindow(1, true), newWindow(4, false), newWindow(0, false), newWindow(2, true)
children = { guild, newFrame(5, true), main, closed, trade }

ChatFrame1EditBox = newFrame(0, true)
local editBoxPoint = "BOTTOMLEFT"
function ChatFrame1EditBox:GetPoint() return "TOPLEFT", main, editBoxPoint, 0, 0 end
local editBoxScale = 1
function ChatFrame1EditBox:GetScale() return editBoxScale end

check("active when Chattynator is loaded", host.IsActive(), true)
loaded = false
check("inactive without Chattynator", host.IsActive(), false)

check("main chat is window 1", host.Frame("chat"), main)
local frame, covers = host.Frame("chat", "bottom")
check("edit box at the bottom: bottom bar covers it", frame, ChatFrame1EditBox)
check("covering bar is inset to the input's border", covers, 7)
check("edit box at the bottom: top bar sits on the window", host.Frame("chat", "top"), main)
editBoxPoint = "TOPLEFT"
frame, covers = host.Frame("chat", "top")
check("edit box at the top: top bar covers it", frame, ChatFrame1EditBox)
check("covering bar is inset at the top too", covers, 7)
editBoxScale = 1.5
frame, covers = host.Frame("chat", "top")
check("inset grows with Chattynator's font scaling", covers, 10.5)
editBoxScale = 1
check("edit box at the top: bottom bar sits on the window", host.Frame("chat", "bottom"), main)
editBoxPoint = "BOTTOMLEFT"
check("other windows' bars sit on the window", host.Frame(2, "bottom"), guild)
check("windows found by ID", host.Frame(2), guild)
check("non-window children ignored", host.Frame(5), nil)
check("pooled windows ignored", host.Frame(0), nil)
check("missing window has no frame", host.Frame(3), nil)
check("shown window available", host.IsAvailable(2), true)
check("hidden window unavailable", host.IsAvailable(4), false)
check("missing window unavailable", host.IsAvailable(3), false)

trade.shown = true
check("open windows sorted, main excluded", table.concat(host.OpenWindows(), ","), "2,4")

check("global string names translated", host.WindowName(1), "General")
check("plain names kept", host.WindowName(2), "Trade")
check("tabless window gets a fallback name", host.WindowName(3), "Window 3")
check("unknown window gets a fallback name", host.WindowName(9), "Window 9")

local changes = 0
local typing = {}
host.Watch(function() changes = changes + 1 end, function(spot, side, isTyping) table.insert(typing, spot .. ":" .. side .. ":" .. tostring(isTyping)) end)
check("windows hooked for showing", main.scripts.OnShow ~= nil, true)
check("windows hooked for tab refreshes", hooks[guild.TabsBar].RefreshTabs ~= nil, true)
check("windows hooked for edit box moves", hooks[main].UpdateEditBox ~= nil, true)

ChatFrame1EditBox.scripts.OnEditFocusGained(ChatFrame1EditBox)
check("typing hides the bar covering a bottom edit box", table.concat(typing, " "), "chat:bottom:true")
typing = {}
ChatFrame1EditBox.scripts.OnEditFocusLost(ChatFrame1EditBox)
check("done typing brings both bars back", table.concat(typing, " "), "chat:top:false chat:bottom:false")
typing = {}
editBoxPoint = "TOPLEFT"
ChatFrame1EditBox.scripts.OnEditFocusGained(ChatFrame1EditBox)
editBoxPoint = "BOTTOMLEFT"
check("typing hides the bar covering a top edit box", table.concat(typing, " "), "chat:top:true")
check("pooled windows not hooked", closed.scripts.OnShow, nil)

guild.scripts.OnHide()
hooks[main.TabsBar].RefreshTabs()
hooks[main].UpdateEditBox()
check("changes wait for Chattynator to finish", changes, 0)
check("a burst of changes schedules one update", #delayed, 1)

-- Chattynator reuses a pooled frame for a new window.
closed.id = 3
delayed[1]()
check("the update runs", changes, 1)
check("newly numbered windows get hooked", closed.scripts.OnShow ~= nil, true)
closed.scripts.OnShow()
check("the next change schedules again", #delayed, 2)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
