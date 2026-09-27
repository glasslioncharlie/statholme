local _, addon = ...
local Format = addon.Format

addon.RegisterReadout("fps", {
  name = "FPS",
  interval = 1,
  Update = function()
    local fps = GetFramerate()
    return Format.Color(string.format("%d", fps), Format.FpsColor(fps)) .. Format.Color(" fps", Format.GOLD)
  end,
  OnTooltipShow = function(tooltip)
    tooltip:SetText("Frame rate")
    tooltip:AddDoubleLine("Current", string.format("%.1f fps", GetFramerate()), nil, nil, nil, 1, 1, 1)
    tooltip:AddLine(" ")
    tooltip:AddLine("Click: graphics settings.", 0.6, 0.6, 0.6)
  end,
  clickMacros = {
    LeftButton = "/run for _,c in ipairs(SettingsPanel:GetAllCategories()) do if c:GetName()==GRAPHICS_LABEL then Settings.OpenToCategory(c:GetID()) end end",
  },
})
