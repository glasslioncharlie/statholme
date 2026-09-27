local _, addon = ...
local Format = addon.Format

local MAX_LISTED = 30
local IN_GAME = {
  [Enum.ClubMemberPresence.Online] = true,
  [Enum.ClubMemberPresence.Away] = true,
  [Enum.ClubMemberPresence.Busy] = true,
}

local function onlineMembers(clubId)
  local online = {}
  for _, memberId in ipairs(C_Club.GetClubMembers(clubId)) do
    local info = C_Club.GetMemberInfo(clubId, memberId)
    if info and info.name and IN_GAME[info.presence] then table.insert(online, info) end
  end
  return online
end

local function classColored(text, classID)
  local classInfo = classID and C_CreatureInfo.GetClassInfo(classID)
  if not classInfo then return text end
  return C_ClassColor.GetClassColor(classInfo.classFile):WrapTextInColorCode(text)
end

local readout = {
  name = "Guild",
  events = {
    "GUILD_ROSTER_UPDATE", "PLAYER_GUILD_UPDATE", "INITIAL_CLUBS_LOADED",
    "CLUB_MEMBER_PRESENCE_UPDATED", "CLUB_MEMBER_ADDED", "CLUB_MEMBER_REMOVED",
    "ADDON_RESTRICTION_STATE_CHANGED",
  },
  throttle = 2,
  OnEnable = C_GuildInfo.GuildRoster,
  clickMacros = { LeftButton = "/click GuildMicroButton" },
}

readout.Update = function()
  if not IsInGuild() then return Format.Color("No Guild", Format.GREY) end
  local clubId = C_Club.GetGuildClubId()
  -- The roster is secret in dungeons and raids, and missing until clubs load at login.
  if not clubId or C_ChatInfo.InChatMessagingLockdown() then
    return readout.text or Format.Label("Guild", "...")
  end
  return Format.Label("Guild", #onlineMembers(clubId))
end

readout.OnTooltipShow = function(tooltip)
  if not IsInGuild() then
    tooltip:SetText("Not in a guild")
    return
  end
  tooltip:SetText(GetGuildInfo("player") or "Guild")
  local clubId = C_Club.GetGuildClubId()
  if not clubId or C_ChatInfo.InChatMessagingLockdown() then
    tooltip:AddLine("The guild roster is hidden here.", 1, 1, 1)
    return
  end
  local motd = C_GuildInfo.GetMOTD()
  if motd ~= "" then tooltip:AddLine(motd, 1, 1, 1, true) end
  tooltip:AddLine(" ")
  local online = onlineMembers(clubId)
  for index = 1, math.min(MAX_LISTED, #online) do
    local info = online[index]
    tooltip:AddDoubleLine(classColored(info.name, info.classID) .. " " .. (info.level or ""), info.zone or "", 1, 1, 1, 1, 1, 1)
  end
  if #online > MAX_LISTED then tooltip:AddLine("+" .. (#online - MAX_LISTED) .. " more", 0.6, 0.6, 0.6) end
end

addon.RegisterReadout("guild", readout)
