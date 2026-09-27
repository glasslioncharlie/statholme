local _, addon = ...
local Format = addon.Format

addon.RegisterReadout("mail", {
  name = "Mail",
  events = { "UPDATE_PENDING_MAIL", "MAIL_INBOX_UPDATE", "MAIL_CLOSED" },
  Update = function()
    if HasNewMail() then return Format.Label("Mail", "New") end
    return Format.Color("Mail: None", Format.GREY)
  end,
  OnTooltipShow = function(tooltip)
    tooltip:SetText("Mail")
    if not HasNewMail() then
      tooltip:AddLine("No new mail", 1, 1, 1)
      return
    end
    local senders = { GetLatestThreeSenders() }
    if #senders == 0 then
      tooltip:AddLine("You have new mail", 1, 1, 1)
      return
    end
    tooltip:AddLine("New mail from:")
    for _, sender in ipairs(senders) do tooltip:AddLine(sender, 1, 1, 1) end
  end,
})
