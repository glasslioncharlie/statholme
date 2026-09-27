local _, addon = ...
local Format = addon.Format

local FIRST_BAG, LAST_BAG = Enum.BagIndex.Backpack, NUM_BAG_SLOTS
local REAGENT_BAG = Enum.BagIndex.ReagentBag

local function addBagLine(tooltip, bag)
  local total = C_Container.GetContainerNumSlots(bag)
  if total == 0 then return end
  local free = C_Container.GetContainerNumFreeSlots(bag)
  tooltip:AddDoubleLine(C_Container.GetBagName(bag), free .. " / " .. total, 1, 1, 1, 1, 1, 1)
end

addon.RegisterReadout("bags", {
  name = "Bags",
  events = { "BAG_UPDATE_DELAYED" },
  Update = function()
    local free = 0
    for bag = FIRST_BAG, LAST_BAG do
      free = free + C_Container.GetContainerNumFreeSlots(bag)
    end
    return Format.Label("Bags", free)
  end,
  OnTooltipShow = function(tooltip)
    tooltip:SetText("Bags (free / total)")
    for bag = FIRST_BAG, LAST_BAG do addBagLine(tooltip, bag) end
    if C_Container.GetContainerNumSlots(REAGENT_BAG) > 0 then
      tooltip:AddLine(" ")
      addBagLine(tooltip, REAGENT_BAG)
    end
  end,
  clickMacros = { LeftButton = "/click MainMenuBarBackpackButton" },
})
