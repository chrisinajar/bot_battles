
Heroes = Heroes or class({})

function Heroes:Init()
  Debug:EnableDebugging()

  local herolist = {}
  local totalheroes = 0
  local allheroes = LoadKeyValues('scripts/npc/npc_heroes.txt')
  for key,value in pairs(LoadKeyValues('scripts/npc/herolist.txt')) do
    if value == 1 then
      herolist[key] = allheroes[key].AttributePrimary
      totalheroes = totalheroes + 1
    end
  end

  self:Reset()

  CustomGameEventManager:RegisterListener('hero_selected', partial(Heroes.HeroSelected, self))
  CustomGameEventManager:RegisterListener('level_up', partial(Heroes.LevelUp, self))
  CustomGameEventManager:RegisterListener('level_down', partial(Heroes.LevelDown, self))
  CustomGameEventManager:RegisterListener('startgame', partial(Heroes.StartGame, self))
  CustomGameEventManager:RegisterListener('reset', partial(Heroes.Reset, self))
  
  GameEvents:OnHeroKilled(partial(self.OnHeroKilled, self))

  CustomNetTables:SetTableValue( 'hero_selection', 'herolist', {gametype = GetMapName(), herolist = herolist})
end

function Heroes:OnHeroKilled(keys)
  local killer = keys.killer
  local killed = keys.killed
  local killerTeam = killer:GetTeam()
  if killer ~= killed then
    print("?")
    if killerTeam == DOTA_TEAM_GOODGUYS then
      self.selection.radiantKills = self.selection.radiantKills + 1
    elseif killerTeam == DOTA_TEAM_BADGUYS then
      self.selection.direKills = self.selection.direKills + 1
    end
	CustomNetTables:SetTableValue( 'hero_selection', 'selection', self.selection)
  end
end

function Heroes:Reset (playerID, keys)
  self.selection = {
    isSelecting = true,
    radiant = false,
    dire = false,
    level = 1,
  direKills = 0,
  radiantKills = 0,
  }
  CustomNetTables:SetTableValue( 'hero_selection', 'selection', self.selection)
end

function Heroes:StartGame (playerID, keys)
  self.selection.playerID = keys.PlayerID

  DebugPrint('Player: ' .. self.selection.playerID .. ' is on team ' .. PlayerResource:GetTeam(self.selection.playerID))

  if self.selection.radiant and self.selection.dire then
    DebugPrint('Starting game...')
    self.selection.isSelecting = false
    CustomNetTables:SetTableValue( 'hero_selection', 'selection', self.selection)

    ItemSelection:ChooseItems(self.selection)
  end
end

function Heroes:HeroSelected (playerID, keys)
  DebugPrintTable(keys)

  if keys.radiant then
    self.selection.radiant = keys.radiant
  end
  if keys.dire then
    self.selection.dire = keys.dire or false
  end

  CustomNetTables:SetTableValue( 'hero_selection', 'selection', self.selection)
end

function Heroes:LevelUp (playerID, keys)
  self.selection.level = math.min(25, self.selection.level + 1)
  CustomNetTables:SetTableValue( 'hero_selection', 'selection', self.selection)
end

function Heroes:LevelDown (playerID, keys)
  self.selection.level = math.max(1, self.selection.level - 1)
  CustomNetTables:SetTableValue( 'hero_selection', 'selection', self.selection)
end
