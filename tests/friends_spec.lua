-- Run from the addon folder: luajit tests/friends_spec.lua
local passed, failed = 0, 0
local function check(name, actual, expected)
  if actual == expected then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("FAIL %s: expected %s, got %s", name, tostring(expected), tostring(actual)))
  end
end

LocalizedClassList = function() return {} end
-- A new character's friends list hasn't arrived from the server yet.
C_FriendList = {
  GetNumFriends = function() return nil end,
  GetNumOnlineFriends = function() return nil end,
}
BNGetNumFriends = function() return 0, 0 end

local addon = {}
assert(loadfile("Format.lua"))("Statholme", addon)
local friends
addon.RegisterReadout = function(id, readout) friends = readout end
assert(loadfile("Readouts/Friends.lua"))("Statholme", addon)

local ok, text = pcall(friends.Update)
check("unloaded friends list doesn't error", ok, true)
check("unloaded friends list counts as none", text, addon.Format.Label("Friends", 0))

local lines = {}
local tooltip = {
  SetText = function() end,
  AddLine = function(_, line) table.insert(lines, line) end,
  AddDoubleLine = function() end,
}
ok = pcall(friends.OnTooltipShow, tooltip)
check("tooltip with an unloaded friends list doesn't error", ok, true)
check("tooltip says nobody is online", lines[#lines], "No friends online")

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
