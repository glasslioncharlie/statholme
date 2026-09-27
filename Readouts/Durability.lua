local _, addon = ...
local Format = addon.Format

local SLOTS = {
  { INVSLOT_HEAD, HEADSLOT },
  { INVSLOT_SHOULDER, SHOULDERSLOT },
  { INVSLOT_CHEST, CHESTSLOT },
  { INVSLOT_WAIST, WAISTSLOT },
  { INVSLOT_LEGS, LEGSSLOT },
  { INVSLOT_FEET, FEETSLOT },
  { INVSLOT_WRIST, WRISTSLOT },
  { INVSLOT_HAND, HANDSSLOT },
  { INVSLOT_MAINHAND, MAINHANDSLOT },
  { INVSLOT_OFFHAND, SECONDARYHANDSLOT },
  { INVSLOT_RANGED, RANGEDSLOT },
}

local function percentText(percent)
  return Format.Color(percent .. "%", Format.DurabilityColor(percent))
end

addon.RegisterReadout("durability", {
  name = "Durability",
  events = { "UPDATE_INVENTORY_DURABILITY", "PLAYER_EQUIPMENT_CHANGED" },
  Update = function()
    local items = {}
    for _, slot in ipairs(SLOTS) do
      local current, maximum = GetInventoryItemDurability(slot[1])
      if current then table.insert(items, { current, maximum }) end
    end
    return Format.Label("Dur", percentText(Format.LowestDurability(items) or 100))
  end,
  OnTooltipShow = function(tooltip)
    tooltip:SetText("Durability")
    local repairCost = 0
    for _, slot in ipairs(SLOTS) do
      local current, maximum = GetInventoryItemDurability(slot[1])
      if current then
        tooltip:AddDoubleLine(slot[2], percentText(Format.LowestDurability({ { current, maximum } })), 1, 1, 1)
        repairCost = repairCost + (C_TooltipInfo.GetInventoryItem("player", slot[1]).repairCost or 0)
      end
    end
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("Repair cost", GetMoneyString(repairCost, true), nil, nil, nil, 1, 1, 1)
  end,
  clickMacros = { LeftButton = "/click CharacterMicroButton" },
})
