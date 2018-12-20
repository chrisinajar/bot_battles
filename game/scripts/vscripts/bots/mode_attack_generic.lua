
local bot = GetBot()

function GetDesire()
  if #bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE) > 0 then
    return 1
  end
  return 0
end
