local _, addon = ...
local Format = addon.Format

local TOP_ADDONS = 15

local function measure()
  UpdateAddOnMemoryUsage()
  local total, usage = 0, {}
  for index = 1, C_AddOns.GetNumAddOns() do
    local kb = GetAddOnMemoryUsage(index)
    if kb > 0 then
      local _, title = C_AddOns.GetAddOnInfo(index)
      table.insert(usage, { title = title, kb = kb })
      total = total + kb
    end
  end
  return total, usage
end

local readout = {
  name = "Memory",
  interval = 30,
  Update = function()
    return Format.Label("Mem", (Format.Memory((measure()))))
  end,
  OnTooltipShow = function(tooltip)
    local total, usage = measure()
    table.sort(usage, function(a, b) return a.kb > b.kb end)
    tooltip:SetText("Addon memory")
    for index = 1, math.min(TOP_ADDONS, #usage) do
      tooltip:AddDoubleLine(usage[index].title, Format.Memory(usage[index].kb), 1, 1, 1, 1, 1, 1)
    end
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("Total", Format.Memory(total), nil, nil, nil, 1, 1, 1)
    tooltip:AddLine("Click: free unused memory.", 0.6, 0.6, 0.6)
  end,
}

readout.OnClick = function()
  local before = measure()
  collectgarbage("collect")
  local after = measure()
  print("|cffffd100Statholme|r: freed " .. Format.Memory(math.max(before - after, 0)))
  readout.Refresh()
end

addon.RegisterReadout("memory", readout)
