local _, addon = ...
local Format = addon.Format

local function localTime()
  local now = date("*t")
  return Format.Time(now.hour, now.min, addon.db.time.twentyFour)
end

local function serverTime()
  local hour, minute = GetGameTime()
  return Format.Time(hour, minute, addon.db.time.twentyFour)
end

addon.RegisterReadout("time", {
  name = "Time",
  interval = 1,
  OnEnable = RequestRaidInfo,
  Update = function()
    return addon.db.time.server and serverTime() or localTime()
  end,
  OnTooltipShow = function(tooltip)
    RequestRaidInfo()
    tooltip:SetText("Time")
    tooltip:AddDoubleLine("Local time", localTime(), nil, nil, nil, 1, 1, 1)
    tooltip:AddDoubleLine("Server time", serverTime(), nil, nil, nil, 1, 1, 1)
    tooltip:AddLine(" ")
    local any = false
    for index = 1, GetNumSavedInstances() do
      local name, _, reset, _, locked, extended, _, _, _, difficultyName = GetSavedInstanceInfo(index)
      if locked or extended then
        if not any then
          tooltip:AddLine("Saved instances")
          any = true
        end
        tooltip:AddDoubleLine(name .. " (" .. difficultyName .. ")", SecondsToTime(reset, true), 1, 1, 1, 1, 1, 1)
      end
    end
    if not any then tooltip:AddLine("No saved instances", 1, 1, 1) end
    tooltip:AddLine(" ")
    tooltip:AddLine("Left-click: calendar. Right-click: stopwatch and alarm.", 0.6, 0.6, 0.6)
  end,
  clickMacros = { LeftButton = "/click GameTimeFrame", RightButton = "/click TimeManagerClockButton" },
})
