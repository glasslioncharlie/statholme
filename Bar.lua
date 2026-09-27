local _, addon = ...

local HEIGHT = 22

local function showText(slot, text)
  slot.label:SetText(text)
end

local function onEnter(slot)
  if not slot.readoutId then return end
  GameTooltip:SetOwner(slot, "ANCHOR_NONE")
  local _, y = slot:GetCenter()
  if y > UIParent:GetHeight() / 2 then
    GameTooltip:SetPoint("TOP", slot, "BOTTOM", 0, -4)
  else
    GameTooltip:SetPoint("BOTTOM", slot, "TOP", 0, 4)
  end
  addon.GetReadout(slot.readoutId).OnTooltipShow(GameTooltip)
  GameTooltip:Show()
end

local function onClick(slot, button, down)
  if down then return end
  if button == "RightButton" and IsShiftKeyDown() then
    addon.OpenSlotMenu(slot)
    return
  end
  local readout = slot.readoutId and addon.GetReadout(slot.readoutId)
  if readout and readout.OnClick then readout.OnClick(slot, button) end
end

-- Blizzard windows opened from addon code are tainted and error on secret values, so slots run a macro through Blizzard's own button code.
local function setClickMacros(slot)
  local readout = slot.readoutId and addon.GetReadout(slot.readoutId)
  local macros = readout and readout.clickMacros or {}
  for index, mouseButton in ipairs({ "LeftButton", "RightButton" }) do
    slot:SetAttribute("type" .. index, macros[mouseButton] and "macro" or nil)
    slot:SetAttribute("macrotext" .. index, macros[mouseButton])
  end
end

local function layout(bar)
  local width = bar:GetWidth() / #bar.slots
  for i, slot in ipairs(bar.slots) do
    slot:ClearAllPoints()
    slot:SetPoint("TOPLEFT", bar, "TOPLEFT", (i - 1) * width, 0)
    slot:SetSize(width, HEIGHT)
  end
end

local function update(bar)
  local settings = addon.GetBar(bar.spot, bar.side)
  local visible = settings.shown and bar.available and not bar.typing
  bar:SetShown(visible)
  for i, slot in ipairs(bar.slots) do
    addon.Bind(slot, visible and settings.slots[i] or nil)
    setClickMacros(slot)
  end
end

function addon.CreateBar(spot, side, count)
  local bar = CreateFrame("Frame", nil, UIParent, "TooltipBackdropTemplate")
  bar:SetHeight(HEIGHT)
  bar.spot, bar.side = spot, side
  bar.available, bar.typing = false, false
  bar.Update = update
  bar.slots = {}
  for i = 1, count do
    local slot = CreateFrame("Button", nil, bar, "InsecureActionButtonTemplate")
    slot.bar, slot.index = bar, i
    slot.ShowText = showText
    slot.label = slot:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slot.label:SetPoint("LEFT", 4, 0)
    slot.label:SetPoint("RIGHT", -4, 0)
    slot.label:SetWordWrap(false)
    -- Blizzard's handler acts on key down or key up depending on a game setting.
    slot:RegisterForClicks("AnyUp", "AnyDown")
    slot:SetAttribute("shift-type2", ATTRIBUTE_NOOP)
    slot:SetScript("OnEnter", onEnter)
    slot:SetScript("OnLeave", GameTooltip_Hide)
    slot:HookScript("OnClick", onClick)
    bar.slots[i] = slot
  end
  bar:SetScript("OnSizeChanged", layout)
  bar:Hide()
  return bar
end
