
BotController = BotController or class({})

function BotController:Init()
  Debug:EnableDebugging()
  GameEvents:OnCustomGameSetup(function ()
    -- Set bot difficulty
    SendToServerConsole("dota_bot_set_difficulty 4")
    SendToServerConsole("dota_bot_practice_difficulty 4")
    SendToServerConsole("dota_bot_purchase_item_enable 0")

    -- Fill all empty slots with bots
    SendToServerConsole("dota_all_vision")

    Timers:CreateTimer(2, function()
      DebugPrint(PlayerResource:GetAllTeamPlayerIDs():length())
      SendToServerConsole("dota_bot_populate")
      return 10
    end)
  end)

  self.locations = {
    dire = Entities:FindByName(nil, 'dire_spawn'):GetAbsOrigin(),
    radiant = Entities:FindByName(nil, 'radiant_spawn'):GetAbsOrigin(),
    center = Entities:FindByName(nil, 'battle'):GetAbsOrigin()
  }

  local function setupVision ()
    AddFOWViewer(DOTA_TEAM_GOODGUYS, self.locations.dire, 999999.0, 999999.0, false)
    AddFOWViewer(DOTA_TEAM_GOODGUYS, self.locations.radiant, 999999.0, 999999.0, false)
    AddFOWViewer(DOTA_TEAM_GOODGUYS, self.locations.center, 999999.0, 999999.0, false)

    AddFOWViewer(DOTA_TEAM_BADGUYS, self.locations.dire, 999999.0, 999999.0, false)
    AddFOWViewer(DOTA_TEAM_BADGUYS, self.locations.radiant, 999999.0, 999999.0, false)
    AddFOWViewer(DOTA_TEAM_BADGUYS, self.locations.center, 999999.0, 999999.0, false)

    AddFOWViewer(DOTA_TEAM_CUSTOM_1, self.locations.dire, 999999.0, 999999.0, false)
    AddFOWViewer(DOTA_TEAM_CUSTOM_1, self.locations.radiant, 999999.0, 999999.0, false)
    AddFOWViewer(DOTA_TEAM_CUSTOM_1, self.locations.center, 999999.0, 999999.0, false)

    Timers:CreateTimer(999999, function()
      setupVision()
    end)
  end
  setupVision()
end

function BotController:SetTeams (selection, items)
  Debug:EnableDebugging()
  DebugPrint('Teams locked in! time to populate bots...')
  SendToServerConsole("dota_bot_populate")
  self.selection = selection
  self.items = items

  local function spawnBot (team, botID)
    if botID == selection.playerID then
      return
    end
    ItemSelection:CacheHeroForPlayer(self.selection[team], botID, function (hero)
      BotController:InitBot(hero, team)
    end)
  end

  each(partial(spawnBot, 'radiant'), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_GOODGUYS))
  each(partial(spawnBot, 'dire'), PlayerResource:GetPlayerIDsForTeam(DOTA_TEAM_BADGUYS))
end

function BotController:InitBot (hero, team)
  hero:SetRespawnsDisabled(false)
  hero:RespawnHero(false, false)
  ItemSelection:LevelUpHero(hero)
  BotController:Teleport(hero, team)

  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
    local item = hero:GetItemInSlot(i)
    if item and not item:IsNull() then
      hero:RemoveItem(item)
    end
  end

  for _,itemName in ipairs(self.items[team]) do
    hero:AddItemByName(itemName)
  end

  Timers:CreateTimer(0.1, function()
    if not hero or hero:IsNull() then
      return
    end
    hero:MoveToPositionAggressive(self.locations.center + RandomVector(RandomFloat(200, 600)))
    if (hero:GetAbsOrigin() - self.locations[team]):Length2D() < 1500 then
      return 1
    end
    return 5
  end)
end

function BotController:Teleport (hero, home)
  FindClearSpaceForUnit(hero, self.locations[home], false)
end
