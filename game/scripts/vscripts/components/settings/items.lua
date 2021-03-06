
ItemSelection = ItemSelection or class({})

function ItemSelection:Init()
  Debug:EnableDebugging()
  self:Reset()
  self.loadedHeroes = {}
  self.prisonLocation = Entities:FindByName(nil, "player_prison"):GetAbsOrigin()
  self.abilitySelection = {}

  CustomGameEventManager:RegisterListener('repeat_fight', partial(ItemSelection.RepeatFight, self))
  CustomGameEventManager:RegisterListener('done_shopping', partial(ItemSelection.DoneShopping, self))
  CustomGameEventManager:RegisterListener('reset', partial(ItemSelection.Reset, self))
end

function ItemSelection:ResetHeroes ()
  local function killHero (playerID)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if not hero then
      return
    end
    hero:SetRespawnsDisabled(true)

    hero:ClearLastHitMultikill()
    hero:ClearLastHitStreak()
    hero:ClearStreak()
    PlayerResource:ClearKillsMatrix(playerID)

    if hero:IsAlive() then
      hero:Kill(nil, hero)
    end
  end
  each(killHero, PlayerResource:GetAllTeamPlayerIDs())
  GridNav:RegrowAllTrees()
  GameRules:SetTimeOfDay(0.5)
end

function ItemSelection:Reset (playerID, keys)
  self:ResetHeroes()

  self.state = {
    isSelecting = false,
    radiant = {},
    dire = {}
  }
  self.abilitySelection = {}
  CustomNetTables:SetTableValue( 'hero_selection', 'items', self.state)
end

function ItemSelection:ChooseItems (selection)
  Debug:EnableDebugging()

  DebugPrint('Starting choose items flow!')
  self.selection = selection
  self.state = {
    isSelecting = 'radiant',
    radiant = {},
    dire = {}
  }
  CustomNetTables:SetTableValue( 'hero_selection', 'items', self.state)

  local index = #self.state.radiant + 1
  self:EnableHero(self.selection.radiant[index])
end

function ItemSelection:DoneShopping (playerID, keys)
  local player = PlayerResource:GetPlayer(self.selection.playerID)
  local hero = PlayerResource:GetSelectedHeroEntity(self.selection.playerID)
  local items = {}
  -- Store items of current hero
  for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
    local item = hero:GetItemInSlot(i)
    if item  then
      table.insert(items, item:GetName())
      UTIL_Remove(item)
    end
  end

  local skillTable = {}
  for i = 0, 23 do
    local ability = hero:GetAbilityByIndex(i)
    if ability and ability:GetLevel() > 0 then
      skillTable[ability:GetName()] = ability:GetLevel()
    end
  end

  self:AssignAbilitySelectionToHero(hero:GetName(), skillTable)

  if self.state.isSelecting == 'dire' then
    table.insert(self.state.dire, items)
    local index = #self.state.dire + 1

    if index > self.selection.heroCount then
      self.state.isSelecting = false
      DebugPrint('All done calculating items!')
      hero:SetRespawnsDisabled(true)
      FindClearSpaceForUnit(hero, self.prisonLocation, true)
      BotController:SetTeams(self.selection, self.state)
    else
      self:EnableHero(self.selection.dire[index])
    end
  end
  if self.state.isSelecting == 'radiant' then
    table.insert(self.state.radiant, items)
    local index = #self.state.radiant + 1

    if index > self.selection.heroCount then
      self.state.isSelecting = 'dire'
      self:EnableHero(self.selection.dire[1])
    else
      self:EnableHero(self.selection.radiant[index])
    end
  end

  CustomNetTables:SetTableValue( 'hero_selection', 'items', self.state)
end

function ItemSelection:RepeatFight ()
  self:ResetHeroes()
  BotController:SetTeams(self.selection, self.state)
end

function ItemSelection:EnableHero (heroName)
  DebugPrint('Replacing the hero so they can select items! ' .. heroName)
  local oldHero = PlayerResource:GetSelectedHeroEntity(self.selection.playerID)

  if oldHero then
    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = oldHero:GetItemInSlot(i)
      if item and not item:IsNull() then
        oldHero:RemoveItem(item)
        UTIL_Remove(item)
      end
    end
  end

  GameRules:SetUseUniversalShopMode(true)
  HudTimer:SetGameTime(0)
  self:CacheHeroForPlayer(heroName, self.selection.playerID, function (hero)
    hero:RespawnHero(false, false)
    local goldAmount = 1000
    if self.selection.level >= 25 then
      goldAmount = 20000
    elseif self.selection.level >= 15 then
      goldAmount = 10000
    end
    PlayerResource:SetGold(self.selection.playerID, goldAmount, true)
    self:LevelUpHero(hero)

    for i = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
      local item = hero:GetItemInSlot(i)
      if item and not item:IsNull() then
        hero:RemoveItem(item)
      end
    end

    BotController:Teleport(hero, 'radiant')
  end)
end

function ItemSelection:CacheHeroForPlayer (heroName, playerID, cb)
  if self.loadedHeroes[heroName] then
    PlayerResource:ReplaceHeroWith(playerID, heroName, 0, 0)
    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero:IsAlive() then
      hero:Kill(nil, hero)
    end
    hero:SetRespawnsDisabled(true)
    cb(hero)
    return
  end

  PrecacheUnitByNameAsync(heroName, function()
    self.loadedHeroes[heroName] = true

    local player = PlayerResource:GetPlayer(playerID)
    if player == nil then -- disconnected! don't give em a hero yet...
      return
    end
    DebugPrint('Giving player ' .. playerID .. ' ' .. heroName)
    PlayerResource:ReplaceHeroWith(playerID, heroName, 0, 0)

    local hero = PlayerResource:GetSelectedHeroEntity(playerID)
    if hero:IsAlive() then
      hero:Kill(nil, hero)
    end
    hero:SetRespawnsDisabled(true)
    cb(hero)
  end)
end

function ItemSelection:LevelUpHero(hero)
  if hero:GetLevel() >= self.selection.level then
    return
  end

  hero:AddExperience(XP_PER_LEVEL_TABLE[self.selection.level], 0, false, false)

  Timers:CreateTimer(0.1, function()
    self:LevelUpHero(hero)
  end)
end

function ItemSelection:AssignAbilitySelectionToHero( heroName, skillTable )
  self.abilitySelection[heroName] = skillTable
end

function ItemSelection:GetAbilitySelectionForHero( heroName )
  return self.abilitySelection[heroName]
end
