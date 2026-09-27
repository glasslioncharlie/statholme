local _, addon = ...
local Format = addon.Format

local function ms(latency)
  return Format.Color(string.format("%d", latency), Format.PingColor(latency)) .. Format.Color(" ms", Format.GOLD)
end

addon.RegisterReadout("ping", {
  name = "Ping",
  interval = 30,
  Update = function()
    local _, _, _, world = GetNetStats()
    return ms(world)
  end,
  OnTooltipShow = function(tooltip)
    local _, _, home, world = GetNetStats()
    tooltip:SetText("Latency")
    tooltip:AddDoubleLine("Home", ms(home))
    tooltip:AddDoubleLine("World", ms(world))
  end,
})
