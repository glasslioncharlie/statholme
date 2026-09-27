local _, addon = ...

function addon.ReadoutName(id)
  if id == "none" then return "None" end
  return addon.GetReadout(id).name
end

function addon.OpenSlotMenu(slot)
  local bar = slot.bar
  MenuUtil.CreateContextMenu(slot, function(_, root)
    root:CreateTitle(string.format("%s, %s bar: slot %d", addon.SpotName(bar.spot), bar.side, slot.index))
    local function add(id)
      root:CreateRadio(addon.ReadoutName(id),
        function() return addon.GetBar(bar.spot, bar.side).slots[slot.index] == id end,
        function() addon.SetSlotReadout(bar.spot, bar.side, slot.index, id) end)
    end
    add("none")
    for _, id in ipairs(addon.READOUT_ORDER) do add(id) end
    root:CreateDivider()
    root:CreateButton("Open settings", addon.OpenSettings)
  end)
end
