local _, addon = ...
local Format = addon.Format

local PVP_COLORS = {
  sanctuary = "ff69ccf0",
  arena = "ffff1a1a",
  combat = "ffff1a1a",
  hostile = "ffff1a1a",
  friendly = "ff1aff1a",
  contested = "ffffb300",
}

local function zoneColor()
  return PVP_COLORS[C_PvP.GetZonePVPInfo()] or Format.GOLD
end

addon.RegisterReadout("location", {
  name = "Location",
  events = { "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA" },
  Update = function()
    return Format.Color(GetZoneText(), zoneColor())
  end,
  OnTooltipShow = function(tooltip)
    tooltip:SetText(Format.Color(GetZoneText(), zoneColor()))
    local subzone = GetSubZoneText()
    if subzone ~= "" then tooltip:AddLine(subzone, 1, 1, 1) end
    local map = C_Map.GetBestMapForUnit("player")
    local position = map and C_Map.GetPlayerMapPosition(map, "player")
    if position then
      local x, y = position:GetXY()
      tooltip:AddLine(string.format("%.1f, %.1f", x * 100, y * 100), 1, 1, 1)
    else
      tooltip:AddLine("No coordinates here", 1, 1, 1)
    end
    tooltip:AddLine(" ")
    tooltip:AddLine("Click: world map.", 0.6, 0.6, 0.6)
  end,
  clickMacros = { LeftButton = "/run ToggleWorldMap()" },
})
