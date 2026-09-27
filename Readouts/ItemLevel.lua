local _, addon = ...
local Format = addon.Format

addon.RegisterReadout("itemlevel", {
  name = "Item level",
  events = { "PLAYER_AVG_ITEM_LEVEL_UPDATE", "PLAYER_EQUIPMENT_CHANGED" },
  Update = function()
    local _, equipped = GetAverageItemLevel()
    return Format.Color("ilvl", Format.GOLD) .. " " .. math.floor(equipped)
  end,
  OnTooltipShow = function(tooltip)
    local overall, equipped = GetAverageItemLevel()
    tooltip:SetText("Item level")
    tooltip:AddDoubleLine("Equipped", string.format("%.1f", equipped), nil, nil, nil, 1, 1, 1)
    tooltip:AddDoubleLine("Overall", string.format("%.1f", overall), nil, nil, nil, 1, 1, 1)
  end,
  clickMacros = { LeftButton = "/click CharacterMicroButton" },
})
