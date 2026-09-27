local _, addon = ...
local Format = addon.Format

local function activeSpec()
  local index = C_SpecializationInfo.GetSpecialization()
  if not index or index == 0 or index > GetNumSpecializations() then return nil end
  local id, name, _, icon = C_SpecializationInfo.GetSpecializationInfo(index)
  return index, id, name, icon
end

local function lootSpecName()
  local lootSpec = GetLootSpecialization()
  if lootSpec == 0 then
    local _, _, name = activeSpec()
    return "Current spec (" .. name .. ")"
  end
  return (select(2, GetSpecializationInfoByID(lootSpec)))
end

local function loadoutName(specID)
  if C_ClassTalents.GetStarterBuildActive() then return TALENT_FRAME_DROP_DOWN_STARTER_BUILD end
  local configID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
  local info = configID and C_Traits.GetConfigInfo(configID)
  return info and info.name
end

local function specMenu(owner)
  MenuUtil.CreateContextMenu(owner, function(_, root)
    root:CreateTitle("Specialization")
    for index = 1, GetNumSpecializations() do
      local _, name, _, icon = C_SpecializationInfo.GetSpecializationInfo(index)
      root:CreateRadio("|T" .. icon .. ":14|t " .. name,
        function() return C_SpecializationInfo.GetSpecialization() == index end,
        function() C_SpecializationInfo.SetSpecialization(index) end)
    end
  end)
end

local function lootMenu(owner)
  MenuUtil.CreateContextMenu(owner, function(_, root)
    root:CreateTitle("Loot specialization")
    root:CreateRadio("Current spec",
      function() return GetLootSpecialization() == 0 end,
      function() SetLootSpecialization(0) end)
    for index = 1, GetNumSpecializations() do
      local id, name, _, icon = C_SpecializationInfo.GetSpecializationInfo(index)
      root:CreateRadio("|T" .. icon .. ":14|t " .. name,
        function() return GetLootSpecialization() == id end,
        function() SetLootSpecialization(id) end)
    end
  end)
end

addon.RegisterReadout("spec", {
  name = "Spec",
  events = {
    "PLAYER_SPECIALIZATION_CHANGED", "PLAYER_LOOT_SPEC_UPDATED", "ACTIVE_TALENT_GROUP_CHANGED",
    "TRAIT_CONFIG_UPDATED", "SELECTED_LOADOUT_CHANGED",
  },
  Update = function()
    local _, _, name, icon = activeSpec()
    if not name then return Format.Color("No Spec", Format.GREY) end
    return "|T" .. icon .. ":14|t " .. Format.Color(name, Format.GOLD)
  end,
  OnTooltipShow = function(tooltip)
    local _, id, name = activeSpec()
    if not id then
      tooltip:SetText("No specialization yet")
      return
    end
    tooltip:SetText("Specialization")
    tooltip:AddDoubleLine("Spec", name, nil, nil, nil, 1, 1, 1)
    tooltip:AddDoubleLine("Loot spec", lootSpecName(), nil, nil, nil, 1, 1, 1)
    local loadout = loadoutName(id)
    if loadout then tooltip:AddDoubleLine("Loadout", loadout, nil, nil, nil, 1, 1, 1) end
    tooltip:AddLine(" ")
    tooltip:AddLine("Left-click: change spec. Right-click: change loot spec.", 0.6, 0.6, 0.6)
  end,
  OnClick = function(frame, button)
    if not activeSpec() then return end
    if button == "RightButton" then
      lootMenu(frame)
    else
      specMenu(frame)
    end
  end,
})
