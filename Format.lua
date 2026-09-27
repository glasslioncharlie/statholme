local _, addon = ...

local Format = {}
addon.Format = Format

Format.GOLD = "ffffd100"
Format.WHITE = "ffffffff"
Format.GREY = "ff808080"
Format.GOOD = "ff20ff20"
Format.WARN = "ffffff00"
Format.BAD = "ffff2020"

function Format.Color(text, color)
  return "|c" .. color .. text .. "|r"
end

function Format.Label(label, value)
  return Format.Color(label .. ":", Format.GOLD) .. " " .. value
end

function Format.Time(hour, minute, twentyFour)
  if twentyFour then
    return string.format("%02d:%02d", hour, minute)
  end
  local suffix = hour < 12 and "AM" or "PM"
  local shown = hour % 12
  if shown == 0 then shown = 12 end
  return string.format("%d:%02d %s", shown, minute, suffix)
end

function Format.Memory(kb)
  if kb < 1024 then
    return string.format("%d KB", math.floor(kb))
  end
  return string.format("%.1f MB", kb / 1024)
end

function Format.FpsColor(fps)
  if fps >= 60 then return Format.GOOD end
  if fps >= 30 then return Format.WARN end
  return Format.BAD
end

function Format.PingColor(ms)
  if ms < 100 then return Format.GOOD end
  if ms < 250 then return Format.WARN end
  return Format.BAD
end

function Format.DurabilityColor(percent)
  if percent >= 50 then return Format.GOOD end
  if percent >= 25 then return Format.WARN end
  return Format.BAD
end

function Format.LowestDurability(items)
  local lowest
  for _, item in ipairs(items) do
    local percent = math.floor(item[1] / item[2] * 100)
    if not lowest or percent < lowest then lowest = percent end
  end
  return lowest
end
