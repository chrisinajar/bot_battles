
BotController = BotController or class({})
DELAY_TO_WALK = 20
function BotController:Init()
  Debug:EnableDebugging()
  GameEvents:OnCustomGameSetup(function ()
    -- Set bot difficulty
    SendToServerConsole("dota_bot_set_difficulty 4")
    SendToServerConsole("dota_bot_practice_difficulty 4")
    SendToServerConsole("dota_bot_purchase_item_enable 0")
    SendToServerConsole("dota_all_vision 1")

    -- Fill all empty slots with bots
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
    AddFOWViewer(DOTA_TEAM_GOODGUYS, self.locations.dire, -1, -1, false)
    AddFOWViewer(DOTA_TEAM_GOODGUYS, self.locations.radiant, -1, -1, false)
    AddFOWViewer(DOTA_TEAM_GOODGUYS, self.locations.center, -1, -1, false)

    AddFOWViewer(DOTA_TEAM_BADGUYS, self.locations.dire, -1, -1, false)
    AddFOWViewer(DOTA_TEAM_BADGUYS, self.locations.radiant, -1, -1, false)
    AddFOWViewer(DOTA_TEAM_BADGUYS, self.locations.center, -1, -1, false)

    AddFOWViewer(DOTA_TEAM_CUSTOM_1, self.locations.dire, -1, -1, false)
    AddFOWViewer(DOTA_TEAM_CUSTOM_1, self.locations.radiant, -1, -1, false)
    AddFOWViewer(DOTA_TEAM_CUSTOM_1, self.locations.center, -1, -1, false)

    Timers:CreateTimer(999999, function()
      setupVision()
    end)
  end
  setupVision()

  ChatCommand:LinkCommand('-modifiers', function ()
    local function printModifiers (playerID)
      local hero = PlayerResource:GetSelectedHeroEntity(playerID)
      if not hero or not hero:IsAlive() then
        return
      end
      print(hero:GetName())
      for i = 1,hero:GetModifierCount() do
        print(' - ' .. hero:GetModifierNameByIndex(i))
      end
    end
    each(printModifiers, PlayerResource:GetAllTeamPlayerIDs())
  end)
end

function BotController:SetTeams (selection, items)
  Debug:EnableDebugging()
  DebugPrint('Teams locked in! time to populate bots...')
  SendToServerConsole("dota_bot_populate")
  self.selection = selection
  self.items = items
  HudTimer:SetGameTime(DELAY_TO_WALK)
  HudTimer:SetCountDown(true)

  Timers:CreateTimer(1, function()
    local tTime = HudTimer:GetGameTime()
    if HudTimer:GetCountDown() then
      if tTime <= 10 and tTime > 0 then
        Notifications:TopToAll({text=tTime, duration=0.8})
      elseif tTime == 0 then
        HudTimer:SetGameTime(0)
        HudTimer:SetCountDown(false)
        Notifications:TopToAll({text="GO!", duration=1})
        EmitGlobalSound("GameStart.RadiantAncient")
      end
      return 1
    end
  end)

  local function spawnBot (team, botID)
    if botID == selection.playerID then
      return
    end
    print(botID)
    ItemSelection:CacheHeroForPlayer(self.selection[team][(((botID - 1) % 5) % self.selection.heroCount) + 1], botID, function (hero)
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

  local heroIndex = 0
  local myHeroName = hero:GetName()
  for index,heroName in ipairs(self.selection[team]) do
    if heroName == myHeroName then
      heroIndex = index
    end
  end

  for _,itemName in ipairs(self.items[team][heroIndex]) do
    hero:AddItemByName(itemName)
  end
  hero:SetAbilityPoints(0)
  hero:SetAcquisitionRange(1200)
  hero:SetHealth(hero:GetMaxHealth())
  hero:SetMana(hero:GetMaxMana())

  local skillSelection = ItemSelection:GetAbilitySelectionForHero(hero:GetName())
  Timers:CreateTimer(0.1, function()
    for i = 0, 23 do
      local ability = hero:GetAbilityByIndex(i)
      if ability then
        if skillSelection[ability:GetName()] then
          ability:SetLevel( tonumber(skillSelection[ability:GetName()]) )
        elseif ability:GetLevel() > 0 then
          ability:SetLevel( 0 )
        end
        ability:EndCooldown()
        ability:RefreshCharges()
      end
    end
  end)
  Timers:CreateTimer(DELAY_TO_WALK, function()
    if not hero or hero:IsNull() then
      return
    end
    if not hero:IsIdle() then
      return 1
    end
    hero:MoveToPositionAggressive( self.locations.center + RandomVector(RandomFloat(200, 600)))
    if (hero:GetAbsOrigin() - self.locations[team]):Length2D() < 1500 then
      return 1
    end
    return 5
  end)
end

function BotController:Teleport (hero, home)
  FindClearSpaceForUnit(hero, self.locations[home], false)
end
