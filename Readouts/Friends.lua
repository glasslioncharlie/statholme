local _, addon = ...
local Format = addon.Format

local classFiles = {}
for classFile, name in pairs(LocalizedClassList(false)) do classFiles[name] = classFile end
for classFile, name in pairs(LocalizedClassList(true)) do classFiles[name] = classFile end

local function classColored(text, classFile)
  if not classFile then return text end
  return C_ClassColor.GetClassColor(classFile):WrapTextInColorCode(text)
end

local function addWowFriends(tooltip)
  local any = false
  for index = 1, C_FriendList.GetNumFriends() do
    local info = C_FriendList.GetFriendInfoByIndex(index)
    if info.connected then
      if not any then
        tooltip:AddLine("Friends")
        any = true
      end
      local name = classColored(info.name, classFiles[info.className])
      tooltip:AddDoubleLine(name .. " " .. info.level, info.area or "", 1, 1, 1, 1, 1, 1)
    end
  end
  return any
end

local function addBattleNetFriends(tooltip)
  local any = false
  for index = 1, BNGetNumFriends() do
    local account = C_BattleNet.GetFriendAccountInfo(index)
    local game = account and account.gameAccountInfo
    if game and game.isOnline then
      if not any then
        tooltip:AddLine("Battle.net")
        any = true
      end
      local where
      if game.clientProgram == BNET_CLIENT_WOW and game.characterName then
        where = classColored(game.characterName, game.classFilename) .. " " .. (game.areaName or "")
      else
        where = game.richPresence or game.clientProgram
      end
      tooltip:AddDoubleLine(account.accountName, where, 1, 1, 1, 1, 1, 1)
    end
  end
  return any
end

addon.RegisterReadout("friends", {
  name = "Friends",
  events = {
    "FRIENDLIST_UPDATE", "BN_FRIEND_ACCOUNT_ONLINE", "BN_FRIEND_ACCOUNT_OFFLINE",
    "BN_FRIEND_INFO_CHANGED", "BN_FRIEND_LIST_SIZE_CHANGED", "BN_CONNECTED", "BN_DISCONNECTED",
  },
  OnEnable = C_FriendList.ShowFriends,
  Update = function()
    local _, battleNetOnline = BNGetNumFriends()
    return Format.Label("Friends", C_FriendList.GetNumOnlineFriends() + battleNetOnline)
  end,
  OnTooltipShow = function(tooltip)
    tooltip:SetText("Friends online")
    local wow = addWowFriends(tooltip)
    if wow then tooltip:AddLine(" ") end
    local battleNet = addBattleNetFriends(tooltip)
    if not wow and not battleNet then tooltip:AddLine("No friends online", 1, 1, 1) end
  end,
  clickMacros = { LeftButton = "/click QuickJoinToastButton" },
})
