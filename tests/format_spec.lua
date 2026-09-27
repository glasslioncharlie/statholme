-- Run from the addon folder: luajit tests/format_spec.lua
local addon = {}
assert(loadfile("Format.lua"))("Statholme", addon)
local Format = addon.Format

local passed, failed = 0, 0
local function check(name, actual, expected)
  if actual == expected then
    passed = passed + 1
  else
    failed = failed + 1
    print(string.format("FAIL %s: expected %s, got %s", name, tostring(expected), tostring(actual)))
  end
end

check("colour", Format.Color("x", Format.GOOD), "|cff20ff20x|r")
check("label", Format.Label("Bags", "42"), "|cffffd100Bags:|r 42")

check("midnight 12h", Format.Time(0, 5, false), "12:05 AM")
check("morning 12h", Format.Time(9, 41, false), "9:41 AM")
check("noon 12h", Format.Time(12, 0, false), "12:00 PM")
check("afternoon 12h", Format.Time(13, 7, false), "1:07 PM")
check("last minute 12h", Format.Time(23, 59, false), "11:59 PM")
check("morning 24h", Format.Time(9, 5, true), "09:05")
check("midnight 24h", Format.Time(0, 0, true), "00:00")
check("evening 24h", Format.Time(21, 41, true), "21:41")

check("memory KB", Format.Memory(850.4), "850 KB")
check("memory just under 1 MB", Format.Memory(1023.9), "1023 KB")
check("memory exactly 1 MB", Format.Memory(1024), "1.0 MB")
check("memory MB", Format.Memory(46285), "45.2 MB")

check("fps 60 good", Format.FpsColor(60), Format.GOOD)
check("fps 59.9 warn", Format.FpsColor(59.9), Format.WARN)
check("fps 30 warn", Format.FpsColor(30), Format.WARN)
check("fps 29.9 bad", Format.FpsColor(29.9), Format.BAD)

check("ping 99 good", Format.PingColor(99), Format.GOOD)
check("ping 100 warn", Format.PingColor(100), Format.WARN)
check("ping 249 warn", Format.PingColor(249), Format.WARN)
check("ping 250 bad", Format.PingColor(250), Format.BAD)

check("durability 50 good", Format.DurabilityColor(50), Format.GOOD)
check("durability 49 warn", Format.DurabilityColor(49), Format.WARN)
check("durability 25 warn", Format.DurabilityColor(25), Format.WARN)
check("durability 24 bad", Format.DurabilityColor(24), Format.BAD)

check("lowest of two", Format.LowestDurability({ { 50, 100 }, { 20, 40 } }), 50)
check("lowest picks the worse", Format.LowestDurability({ { 90, 100 }, { 10, 40 } }), 25)
check("lowest rounds down", Format.LowestDurability({ { 1, 3 } }), 33)
check("lowest of none", Format.LowestDurability({}), nil)

print(string.format("%d passed, %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
