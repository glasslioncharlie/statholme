local _, addon = ...

local MAX_WINDOWS = Constants.ChatFrameConstants.MaxChatWindows
local ROW_HEIGHT = 30
local DROPDOWN_WIDTH = 130
local ROW_WIDTH = 560

local function scrollPage(panel)
  local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, -8)
  scroll:SetPoint("BOTTOMRIGHT", -28, 8)
  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(ROW_WIDTH + 32, 1)
  scroll:SetScrollChild(content)
  return content
end

local function checkbox(parent, text)
  local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  check:SetSize(24, 24)
  check.label = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  check.label:SetPoint("LEFT", check, "RIGHT", 4, 0)
  check.label:SetText(text)
  return check
end

local panel = CreateFrame("Frame")
panel:Hide()
local content = scrollPage(panel)

local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -8)
title:SetText("Statholme")

local hint = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
hint:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
hint:SetText("Tip: Shift+right-click any slot on a bar to change it there.")

local function createRow(parent, spot, side, count)
  local row = CreateFrame("Frame", nil, parent)
  row:SetSize(ROW_WIDTH, ROW_HEIGHT)
  row.side = side
  row.check = checkbox(row, side == "top" and "Top bar" or "Bottom bar")
  row.check:SetPoint("LEFT")
  row.check:SetScript("OnClick", function(self) addon.SetBarShown(spot, side, self:GetChecked()) end)
  row.dropdowns = {}
  for index = 1, count do
    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle2DropdownTemplate")
    dropdown:SetWidth(DROPDOWN_WIDTH)
    dropdown:SetPoint("LEFT", 110 + (index - 1) * (DROPDOWN_WIDTH + 8), 0)
    dropdown:SetupMenu(function(_, root)
      local function add(id)
        root:CreateRadio(addon.ReadoutName(id),
          function() return addon.GetBar(spot, side).slots[index] == id end,
          function() addon.SetSlotReadout(spot, side, index, id) end)
      end
      add("none")
      for _, id in ipairs(addon.READOUT_ORDER) do add(id) end
    end)
    row.dropdowns[index] = dropdown
  end
  return row
end

local sections = {}
local function addSection(spot, count)
  local section = CreateFrame("Frame", nil, content)
  section:SetSize(ROW_WIDTH, 20 + ROW_HEIGHT * 2)
  section.header = section:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  section.header:SetPoint("TOPLEFT")
  section.rows = { createRow(section, spot, "top", count), createRow(section, spot, "bottom", count) }
  section.rows[1]:SetPoint("TOPLEFT", 0, -20)
  section.rows[2]:SetPoint("TOPLEFT", section.rows[1], "BOTTOMLEFT")
  sections[spot] = section
end

-- Dropdowns read the saved settings as soon as they're set up.
addon.OnLoad(function()
  addSection("minimap", addon.SLOT_COUNTS.minimap)
  addSection("chat", addon.SLOT_COUNTS.chat)
  addSection("micro", addon.SLOT_COUNTS.micro)
  for index = 2, MAX_WINDOWS do addSection(index, addon.SLOT_COUNTS.window) end
end)

local timeSection = CreateFrame("Frame", nil, content)
timeSection:SetSize(ROW_WIDTH, 80)
local timeHeader = timeSection:CreateFontString(nil, "ARTWORK", "GameFontNormal")
timeHeader:SetPoint("TOPLEFT")
timeHeader:SetText("Time")

local function timeOption(text, key, y)
  local check = checkbox(timeSection, text)
  check:SetPoint("TOPLEFT", 0, y)
  check:SetScript("OnClick", function(self)
    addon.db.time[key] = self:GetChecked()
    addon.GetReadout("time").Refresh()
  end)
  return check
end
local serverCheck = timeOption("Show server time instead of local time", "server", -20)
local twentyFourCheck = timeOption("24-hour clock", "twentyFour", -48)

local function refresh()
  for _, section in pairs(sections) do section:Hide() end
  local order = { "minimap", "chat", "micro" }
  for _, index in ipairs(addon.OpenWindows()) do table.insert(order, index) end
  local y = -56
  for _, spot in ipairs(order) do
    local section = sections[spot]
    section.header:SetText(addon.SpotName(spot))
    for _, row in ipairs(section.rows) do
      row.check:SetChecked(addon.GetBar(spot, row.side).shown)
      for _, dropdown in ipairs(row.dropdowns) do dropdown:GenerateMenu() end
    end
    section:ClearAllPoints()
    section:SetPoint("TOPLEFT", 16, y)
    section:Show()
    y = y - section:GetHeight() - 12
  end
  timeSection:ClearAllPoints()
  timeSection:SetPoint("TOPLEFT", 16, y)
  serverCheck:SetChecked(addon.db.time.server)
  twentyFourCheck:SetChecked(addon.db.time.twentyFour)
  content:SetHeight(-y + timeSection:GetHeight())
end

panel:SetScript("OnShow", refresh)
local function refreshIfOpen()
  if panel:IsVisible() then refresh() end
end
addon.OnBarChanged(refreshIfOpen)
addon.OnWindowsChanged(refreshIfOpen)

local category = Settings.RegisterCanvasLayoutCategory(panel, "Statholme")
Settings.RegisterAddOnCategory(category)

local currencyPanel = CreateFrame("Frame")
currencyPanel:Hide()
local currencyContent = scrollPage(currencyPanel)

local currencyTitle = currencyContent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
currencyTitle:SetPoint("TOPLEFT", 16, -8)
currencyTitle:SetText("Currencies")

local currencyHint = currencyContent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
currencyHint:SetPoint("TOPLEFT", currencyTitle, "BOTTOMLEFT", 0, -6)
currencyHint:SetText("Ticked currencies appear in the Gold tooltip, on every character that has them.")

local function readCurrencyList()
  local list, collapsed = {}, {}
  local index = 1
  while index <= C_CurrencyInfo.GetCurrencyListSize() do
    local info = C_CurrencyInfo.GetCurrencyListInfo(index)
    if info.isHeader and not info.isHeaderExpanded then
      C_CurrencyInfo.ExpandCurrencyList(index, true)
      table.insert(collapsed, index)
    end
    table.insert(list, info)
    index = index + 1
  end
  for i = #collapsed, 1, -1 do C_CurrencyInfo.ExpandCurrencyList(collapsed[i], false) end
  return list
end

local currencyRows = {}
local function currencyRow(index)
  local row = currencyRows[index]
  if row then return row end
  row = CreateFrame("Frame", nil, currencyContent)
  row:SetSize(ROW_WIDTH, 24)
  row.check = checkbox(row, "")
  row.check:SetPoint("LEFT", 12, 0)
  row.check:SetScript("OnClick", function(self)
    addon.db.currencies[row.currencyID] = self:GetChecked() or nil
  end)
  row.header = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  row.header:SetPoint("LEFT")
  currencyRows[index] = row
  return row
end

local function refreshCurrencies()
  for _, row in ipairs(currencyRows) do row:Hide() end
  local y = -56
  for index, info in ipairs(readCurrencyList()) do
    local row = currencyRow(index)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", 16, y)
    row.header:SetShown(info.isHeader)
    row.check:SetShown(not info.isHeader)
    row.check.label:SetShown(not info.isHeader)
    if info.isHeader then
      row.header:SetText(info.name)
    else
      row.currencyID = info.currencyID
      row.check.label:SetText("|T" .. info.iconFileID .. ":16|t " .. info.name)
      row.check:SetChecked(addon.db.currencies[info.currencyID])
    end
    row:Show()
    y = y - 24
  end
  currencyContent:SetHeight(-y + 16)
end

currencyPanel:SetScript("OnShow", refreshCurrencies)
Settings.RegisterCanvasLayoutSubcategory(category, currencyPanel, "Currencies")

function addon.OpenSettings()
  Settings.OpenToCategory(category:GetID())
end

SLASH_STATHOLME1 = "/statholme"
SLASH_STATHOLME2 = "/sth"
SlashCmdList.STATHOLME = function()
  addon.OpenSettings()
end
