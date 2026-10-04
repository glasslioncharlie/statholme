-- Run from the addon folder: luajit tests/load_spec.lua

local function stub()
  return setmetatable({}, {
    __index = function(self, key)
      local value = stub()
      rawset(self, key, value)
      return value
    end,
    __call = function() return stub() end,
  })
end

local frames = {}
CreateFrame = function(frameType)
  local frame = stub()
  rawset(frame, "events", {})
  rawset(frame, "RegisterEvent", function(self, event) self.events[event] = true end)
  rawset(frame, "SetScript", function(self, script, handler) rawset(self, script, handler) end)
  if frameType == "DropdownButton" then
    rawset(frame, "SetupMenu", function(self, generator)
      local root = stub()
      rawset(root, "CreateRadio", function(_, _, isSelected) isSelected() end)
      generator(self, root)
    end)
  end
  table.insert(frames, frame)
  return frame
end
Constants = { ChatFrameConstants = { MaxChatWindows = 10 } }
C_AddOns = stub()
rawset(C_AddOns, "IsAddOnLoaded", function() return false end)
SlashCmdList = {}

local unset = { StatholmeDB = true, StatholmeCharDB = true }
setmetatable(_G, {
  __index = function(_, key)
    if unset[key] then return nil end
    return stub()
  end,
})

local addon = {}
local loaded, failures = 0, 0
local function try(name, fn)
  local ok, err = pcall(fn)
  if ok then
    loaded = loaded + 1
  else
    failures = failures + 1
    print("FAIL " .. name .. ": " .. tostring(err))
  end
end

for line in io.lines("Statholme.toc") do
  local file = line:match("^([^#].*%.lua)%s*$")
  if file then
    file = file:gsub("\\", "/")
    try(file, function() assert(loadfile(file))("Statholme", addon) end)
  end
end

try("ADDON_LOADED", function()
  for _, frame in ipairs(frames) do
    if frame.events.ADDON_LOADED then frame.OnEvent(frame, "ADDON_LOADED", "Statholme") end
  end
end)

try("settings opened", function() assert(type(addon.OpenSettings) == "function") end)
try("slash command registered", function() assert(SLASH_STATHOLME1 == "/statholme" and type(SlashCmdList.STATHOLME) == "function") end)

print(string.format("%d passed, %d failed", loaded, failures))
os.exit(failures == 0 and 0 or 1)
