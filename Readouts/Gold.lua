local _, addon = ...

local function trackedCurrencies()
  local list = {}
  for id in pairs(addon.db.currencies) do
    local info = C_CurrencyInfo.GetCurrencyInfo(id)
    if info and info.discovered then table.insert(list, info) end
  end
  table.sort(list, function(a, b) return a.name < b.name end)
  return list
end

addon.RegisterReadout("gold", {
  name = "Gold",
  events = { "PLAYER_MONEY", "CURRENCY_DISPLAY_UPDATE" },
  Update = function()
    return GetMoneyString(GetMoney(), true)
  end,
  OnTooltipShow = function(tooltip)
    tooltip:SetText("Gold")
    tooltip:AddLine(GetMoneyString(GetMoney(), true), 1, 1, 1)
    tooltip:AddLine(" ")
    local list = trackedCurrencies()
    if #list == 0 then
      tooltip:AddLine("No currencies tracked", 1, 1, 1)
      tooltip:AddLine("Pick some under Options > AddOns > Statholme > Currencies.", 0.6, 0.6, 0.6)
      return
    end
    tooltip:AddLine("Currencies")
    for _, info in ipairs(list) do
      local amount = BreakUpLargeNumbers(info.quantity)
      if info.maxQuantity > 0 then amount = amount .. " / " .. BreakUpLargeNumbers(info.maxQuantity) end
      tooltip:AddDoubleLine("|T" .. info.iconFileID .. ":14|t " .. info.name, amount, 1, 1, 1, 1, 1, 1)
    end
  end,
  clickMacros = { LeftButton = '/run ToggleCharacter("TokenFrame")' },
})
