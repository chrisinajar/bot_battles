local BotsInit = require( "game/botsinit" );
local MyModule = BotsInit.CreateGeneric();
local Data = require(GetScriptDirectory() ..  "/ability_item_data")

local mutil = require(GetScriptDirectory() ..  "/MyUtility")

local bot = GetBot();

function AbilityLevelUpThink ()
end
function CourierUsageThink ()
end
function BuybackUsageThink ()
end

if bot:GetUnitName() == 'npc_dota_hero_monkey_king' then
  local trueMK = nil;
  for i, id in pairs(GetTeamPlayers(GetTeam())) do
    if IsPlayerBot(id) and GetSelectedHeroName(id) == 'npc_dota_hero_monkey_king' then
      local member = GetTeamMember(i);
      if member ~= nil then
        trueMK = member;
      end
    end
  end
  if trueMK ~= nil and bot ~= trueMK then
    print("AbilityItemUsage "..tostring(bot).." isn't true MK")
    return;
  elseif trueMK == nil or bot == trueMK then
    print("AbilityItemUsage "..tostring(bot).." is true MK")
  end
end

if bot:IsInvulnerable() or bot:IsHero() == false or bot:IsIllusion()
then
  return;
end

function GetNumEnemyNearby(building)
  local nearbynum = 0;
  for i,id in pairs(GetTeamPlayers(GetOpposingTeam())) do
    if IsHeroAlive(id) then
      local info = GetHeroLastSeenInfo(id);
      if info ~= nil then
        local dInfo = info[1];
        if dInfo ~= nil and GetUnitToLocationDistance(building, dInfo.location) <= 2750 and dInfo.time_since_seen < 1.0 then
          nearbynum = nearbynum + 1;
        end
      end
    end
  end
  return nearbynum;
end

function GetNumOfAliveHeroes(team)
  local nearbynum = 0;
  for i,id in pairs(GetTeamPlayers(team)) do
    if IsHeroAlive(id) then
      nearbynum = nearbynum + 1;
    end
  end
  return nearbynum;
end

function GetRemainingRespawnTime()
  if TimeDeath == nil then
    return 0;
  else
    return bot:GetRespawnTime() - ( DotaTime() - TimeDeath );
  end
end

function IsMeepoClone()
  if bot:GetUnitName() == "npc_dota_hero_meepo" and bot:GetLevel() > 1
  then
    for i=0, 5 do
      local item = bot:GetItemInSlot(i);
      if item ~= nil and not ( string.find(item:GetName(),"boots") or string.find(item:GetName(),"treads") )
      then
        return false;
      end
    end
    return true;
    end
  return false;
end

function ItemUsageThink()
  --print(bot:GetUnitName().."item usage")
  if GetGameState() ~= GAME_STATE_PRE_GAME and GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then
    return;
  end

  UnImplementedItemUsage()
  --UseShrine()
end

function AbilityUsageThink()
  if GetGameState() ~= GAME_STATE_PRE_GAME and GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS then
    return;
  end

  local bot = GetBot()
  if mutil.CanNotUseAbility(bot) then return end

  if bot:IsChanneling() or bot:IsUsingAbility() or bot:IsInvisible() or bot:IsMuted( ) or bot:HasModifier("modifier_doom_bringer_doom") then
    return;
  end

  mutil.IsGoingOnSomeone(bot) -- setup targets if needed
  local name = bot:GetUnitName()
  local shortName = name:sub(15, -1)
  if shortName == "sand_king" then
    shortName = "sandking"
  end
  local enemies = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE )
  local allies = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE )
  local enemy = bot:GetTarget()
  local didAct = false
  local couldAct = false
  if not enemy then
    enemy = enemies[1]
  end

  if #enemies == 0 then
    return
  end

  for abilityIndex = 0, 8 do
    local ability = bot:GetAbilityInSlot(abilityIndex)
    local target = enemy
    if bit.band(ability:GetTargetTeam(), 3) == 1 then
      target = allies[RandomInt(1, #allies)]
    end

    if not didAct and ability and ability:GetName():sub(-4) ~= "aura" then
      local abilityName = ability:GetName()
      if not ability:IsHidden() and not ability:IsPassive() and not ability:IsTalent() and ability:IsFullyCastable() and ability:GetName():sub(0, #shortName) == shortName then
        local modifier = Data[abilityName]
        local behave = ability:GetBehavior()
        local targetFlags = ability:GetTargetType()
        if modifier ~= false then
          modifier = modifier or "none"
          if not bot:HasModifier(modifier) and bit.band(behave, 4) == 4 then
            local shouldCast, isAOE = ConsiderAOERadiusAbility(bot, ability)
            if shouldCast > 0 then
              print('Casting AOE ability ' .. ability:GetName() .. ' / ' .. tostring(ability:GetToggleState()))
              didAct, couldAct = CheckAndUseAbility(ability, modifier, nil, true)
            elseif not isAOE then
              didAct, couldAct = CheckAndUseAbility(ability, modifier, nil, true)
            end
          elseif bit.band(targetFlags, 64) == 64 then
            -- this ability targets trees
            local trees = bot:GetNearbyTrees(600)
            if #trees > 0 then
              didAct = true
              bot:Action_UseAbilityOnTree(ability, trees[1])
            end
          elseif target then
            didAct, couldAct = CheckAndUseAbility(ability, modifier, target, true)
          end
        end
      end
    end
  end

  if couldAct then
    -- last, change targets
    local targets = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    if #targets < 1 then
      return didAct, couldAct
    end
    local newTarget = targets[RandomInt(1, #targets)]
    bot:SetTarget(newTarget)
  end

  -- if not didAct and bot:IsIdle() then
  --   bot:Action_ClearActions(false)
  --   bot:ActionQueue_AttackUnit(enemy, true)
  -- end
  return didAct, couldAct
end

function PrintCourierState(state)

    if state == 0 then
      print("COURIER_STATE_IDLE ");
    elseif state == 1 then
      print("COURIER_STATE_AT_BASE");
    elseif state == 2 then
      print("COURIER_STATE_MOVING");
    elseif state == 3 then
      print("COURIER_STATE_DELIVERING_ITEMS");
    elseif state == 4 then
      print("COURIER_STATE_RETURNING_TO_BASE");
    elseif state == 5 then
      print("COURIER_STATE_DEAD");
    else
      print("UNKNOWN");
    end

end

local courierTime = -90;
local cState = -1;
bot.SShopUser = false;
local returnTime = -90;
local apiAvailable = false;

function IsHumanHaveItemInCourier()
  local numPlayer =  GetTeamPlayers(GetTeam());
  for i = 1, #numPlayer
  do
    if not IsPlayerBot(numPlayer[i]) then
      local member = GetTeamMember(i);
      if member ~= nil and member:IsAlive() and member:GetCourierValue( ) > 0
      then
        return true;
      end
    end
  end
  return false;
end

function GetCourierEmptySlot(courier)
  local amount = 0;
  for i=0, 8 do
    if courier:GetItemInSlot(i) == nil then
      amount = amount + 1;
    end
  end
  return amount;
end

function GetNumStashItem(unit)
  local amount = 0;
  for i=9, 14 do
    if unit:GetItemInSlot(i) ~= nil then
      amount = amount + 1;
    end
  end
  return amount;
end

function UpdateSShopUserStatus(bot)
  local numPlayer =  GetTeamPlayers(GetTeam());
  for i = 1, #numPlayer
  do
    local member =  GetTeamMember(i);
    if member ~= nil and IsPlayerBot(numPlayer[i]) and  member:GetUnitName() ~= bot:GetUnitName()
    then
      member.SShopUser = false;
    end
  end
end

function IsTargetedByUnit(courier)
  for i = 0, 10 do
  local tower = GetTower(GetOpposingTeam(), i)
    if tower ~= nil and tower:GetAttackTarget() == courier then
      return true;
    end
  end
  for i,id in pairs(GetTeamPlayers(GetOpposingTeam())) do
    if IsHeroAlive(id) then
      local info = GetHeroLastSeenInfo(id);
      if info ~= nil then
        local dInfo = info[1];
        if dInfo ~= nil and GetUnitToLocationDistance(courier, dInfo.location) <= 700 and dInfo.time_since_seen < 0.5 then
          return true;
        end
      end
    end
  end
  return false;
end

function IsInvFull(npcHero)
  for i=0, 8 do
    if(npcHero:GetItemInSlot(i) == nil) then
      return false;
    end
  end
  return true;
end

function CanCastOnTarget( npcTarget )
  return npcTarget:CanBeSeen() and not npcTarget:IsMagicImmune() and not npcTarget:IsInvulnerable();
end
function CanCastOnMagicImmuneTarget( npcTarget )
  return npcTarget:CanBeSeen() and not npcTarget:IsInvulnerable();
end

function IsDisabled(npcTarget)
  if npcTarget:IsRooted( ) or npcTarget:IsStunned( ) or npcTarget:IsHexed( ) or npcTarget:IsSilenced() or npcTarget:IsNightmared() then
    return true;
  end
  return false;
end

function UseConsumables()



end

function GiveToMidLaner()
  local teamPlayers = GetTeamPlayers(GetTeam())
  local target = nil;
  for k,v in pairs(teamPlayers)
  do
    local member = GetTeamMember(k);
    if member ~= nil and not member:IsIllusion() and member:IsAlive() then
      local num_stg = GetItemCount(member, "item_tango_single");
      local num_ff = GetItemCount(member, "item_faerie_fire");
      if num_ff > 0 and num_stg < 1 then
        return member;
      end
    end
  end
  return nil;
end

function GetItemCount(unit, item_name)
  local count = 0;
  for i = 0, 8
  do
    local item = unit:GetItemInSlot(i)
    if item ~= nil and item:GetName() == item_name then
      count = count + 1;
    end
  end
  return count;
end

function CanSwitchPTStat(pt)
  if bot:GetPrimaryAttribute() == ATTRIBUTE_STRENGTH and pt:GetPowerTreadsStat() ~= ATTRIBUTE_STRENGTH then
    return true;
  elseif bot:GetPrimaryAttribute() == ATTRIBUTE_AGILITY  and pt:GetPowerTreadsStat() ~= ATTRIBUTE_INTELLECT then
    return true;
  elseif bot:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT and pt:GetPowerTreadsStat() ~= ATTRIBUTE_AGILITY then
    return true;
  end
  return false;
end

local giveTime = -90;
function UnImplementedItemUsage()

  if bot:IsChanneling() or bot:IsUsingAbility() or bot:IsInvisible() or bot:IsMuted( ) or bot:HasModifier("modifier_doom_bringer_doom") then
    return;
  end

  local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
  local npcTarget = bot:GetTarget();
  local mode = BOT_MODE_ATTACK

  local pt = IsItemAvailable("item_power_treads");
  if pt~=nil and pt:IsFullyCastable() then
    if mode == BOT_MODE_RETREAT and pt:GetPowerTreadsStat() ~= ATTRIBUTE_STRENGTH and bot:WasRecentlyDamagedByAnyHero(5.0) then
      bot:Action_UseAbility(pt);
      return
    elseif mode == BOT_MODE_ATTACK and CanSwitchPTStat(pt) then
      bot:Action_UseAbility(pt);
      return
    else
      local enemies = bot:GetNearbyHeroes( 1300, true, BOT_MODE_NONE );
      if #enemies == 0 and  mode ~= BOT_MODE_RETREAT and CanSwitchPTStat(pt)  then
        bot:Action_UseAbility(pt);
        return
      end
    end
  end

  local bas = IsItemAvailable("item_ring_of_basilius");
  if bas~=nil and bas:IsFullyCastable() then
    if mode == BOT_MODE_LANING and not bas:GetToggleState() then
      bot:Action_UseAbility(bas);
      return
    elseif mode ~= BOT_MODE_LANING and bas:GetToggleState() then
      bot:Action_UseAbility(bas);
      return
    end
  end

  local aq = IsItemAvailable("item_ring_of_aquila");
  if aq~=nil and aq:IsFullyCastable() then
    if mode == BOT_MODE_LANING and not aq:GetToggleState() then
      bot:Action_UseAbility(aq);
      return
    elseif mode ~= BOT_MODE_LANING and aq:GetToggleState() then
      bot:Action_UseAbility(aq);
      return
    end
  end

  local itg=IsItemAvailable("item_tango");
  if itg~=nil and itg:IsFullyCastable() then
    local tCharge = itg:GetCurrentCharges()
    if DotaTime() > -80 and DotaTime() < 0 and bot:DistanceFromFountain() == 0 and role.CanBeSupport(bot:GetUnitName())
       and bot:GetAssignedLane() ~= LANE_MID and tCharge > 2 and DotaTime() > giveTime + 2.0 then
      local target = GiveToMidLaner()
      if target ~= nil then
        bot:ActionImmediate_Chat(string.gsub(bot:GetUnitName(),"npc_dota_hero_","")..
            " giving tango to "..
            string.gsub(target:GetUnitName(),"npc_dota_hero_","")
            , false);
        bot:Action_UseAbilityOnEntity(itg, target);
        giveTime = DotaTime();
        return;
      end
    elseif bot:GetActiveMode() == BOT_MODE_LANING and role.CanBeSupport(bot:GetUnitName()) and tCharge > 1 and DotaTime() > giveTime + 2.0 then
      local allies = bot:GetNearbyHeroes(1200, false, BOT_MODE_NONE)
      for _,ally in pairs(allies)
      do
        local tangoSlot = ally:FindItemSlot('item_tango');
        if ally:GetUnitName() ~= bot:GetUnitName() and not ally:IsIllusion()
           and tangoSlot == -1 and GetItemCount(ally, "item_tango_single") == 0
        then
          bot:Action_UseAbilityOnEntity(itg, ally);
          giveTime = DotaTime();
          return
        end
      end
    end
  end

  local bdg=IsItemAvailable("item_blink");
  if bdg~=nil and bdg:IsFullyCastable() then
    if mutil.IsStuck(bot)
    then
      bot:ActionImmediate_Chat("I'm using blink while stuck.", true);
      bot:Action_UseAbilityOnLocation(bdg, bot:GetXUnitsTowardsLocation( GetAncient(GetTeam()):GetLocation(), 1100 ));
      return;
    end
  end

  local fst=IsItemAvailable("item_force_staff");
  if fst~=nil and fst:IsFullyCastable() then
    if mutil.IsStuck(bot)
    then
      bot:ActionImmediate_Chat("I'm using force staff while stuck.", true);
      bot:Action_UseAbilityOnEntity(fst, bot);
      return;
    end
  end

  local tpt=IsItemAvailable("item_tpscroll");
  if tpt~=nil and tpt:IsFullyCastable() then
    if mutil.IsStuck(bot)
    then
      bot:ActionImmediate_Chat("I'm using tp while stuck.", true);
      bot:Action_UseAbilityOnLocation(tpt, GetAncient(GetTeam()):GetLocation());
      return;
    end
  end

  local its=IsItemAvailable("item_tango_single");
  if its~=nil and its:IsFullyCastable() and bot:DistanceFromFountain() > 1000 then
    if DotaTime() > 10*60
    then
      local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
      local trees = bot:GetNearbyTrees(1000);
      if trees[1] ~= nil  and ( IsLocationVisible(GetTreeLocation(trees[1])) or IsLocationPassable(GetTreeLocation(trees[1])) )
         and #tableNearbyEnemyHeroes == 0
      then
        bot:Action_UseAbilityOnTree(its, trees[1]);
        return;
      end
    end
  end

  local irt=IsItemAvailable("item_iron_talon");
  if irt~=nil and irt:IsFullyCastable() then
    if bot:GetActiveMode() == BOT_MODE_FARM
    then
      local neutrals = bot:GetNearbyNeutralCreeps(500);
      local maxHP = 0;
      local target = nil;
      for _,c in pairs(neutrals) do
        local cHP = c:GetHealth();
        if cHP > maxHP and not c:IsAncientCreep() then
          maxHP = cHP;
          target = c;
        end
      end
      if target ~= nil then
        bot:Action_UseAbilityOnEntity(irt, target);
        return;
      end
    end
  end

  local msh=IsItemAvailable("item_moon_shard");
  if msh~=nil and msh:IsFullyCastable() then
    if not bot:HasModifier("modifier_item_moon_shard_consumed")
    then
      bot:Action_UseAbilityOnEntity(msh, bot);
      return;
    end
  end

  local mg=IsItemAvailable("item_enchanted_mango");
  if mg~=nil and mg:IsFullyCastable() then
    if bot:GetMana()/bot:GetMaxMana() < 0.10 and mode == BOT_MODE_ATTACK then
      bot:Action_UseAbility(mg);
      return;
    end
  end

  local tok=IsItemAvailable("item_tome_of_knowledge");
  if tok~=nil and tok:IsFullyCastable() then
    bot:Action_UseAbility(tok);
    return;
  end

  local ff=IsItemAvailable("item_faerie_fire");
  if ff~=nil and ff:IsFullyCastable() then
    if ( mode == BOT_MODE_RETREAT and
      bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH and
      bot:DistanceFromFountain() > 0 and
      ( bot:GetHealth() / bot:GetMaxHealth() ) < 0.15 ) or DotaTime() > 10*60
    then
      bot:Action_UseAbility(ff);
      return;
    end
  end

  local bst=IsItemAvailable("item_bloodstone");
  if bst ~= nil and bst:IsFullyCastable() then
    if  mode == BOT_MODE_RETREAT and
      bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH and
      ( bot:GetHealth() / bot:GetMaxHealth() ) < 0.30 - ( bot:GetLevel() / 500 )
    then
      bot:Action_UseAbilityOnLocation(bst, bot:GetLocation());
      return;
    end
  end

  local pb=IsItemAvailable("item_phase_boots");
  if pb~=nil and pb:IsFullyCastable()
  then
    if ( mode == BOT_MODE_ATTACK or
       mode == BOT_MODE_RETREAT or
       mode == BOT_MODE_ROAM or
       mode == BOT_MODE_TEAM_ROAM or
       mode == BOT_MODE_GANK or
       mode == BOT_MODE_DEFEND_ALLY )
    then
      bot:Action_UseAbility(pb);
      return;
    end
  end

  local eb=IsItemAvailable("item_ethereal_blade");
  if eb~=nil and eb:IsFullyCastable() and bot:GetUnitName() ~= "npc_dota_hero_morphling"
  then
    if ( mode == BOT_MODE_ATTACK or
       mode == BOT_MODE_ROAM or
       mode == BOT_MODE_TEAM_ROAM or
       mode == BOT_MODE_GANK or
       mode == BOT_MODE_DEFEND_ALLY )
    then
      local npcTarget = bot:GetTarget();
      if ( npcTarget ~= nil and npcTarget:IsHero() and CanCastOnTarget(npcTarget) and GetUnitToUnitDistance(npcTarget, bot) < 1000 )
      then
          bot:Action_UseAbilityOnEntity(eb,npcTarget);
        return
      end
    end
  end

  local rs=IsItemAvailable("item_refresher_shard");
  if rs~=nil and rs:IsFullyCastable()
  then
    if ( mode == BOT_MODE_ATTACK or
       mode == BOT_MODE_ROAM or
       mode == BOT_MODE_TEAM_ROAM or
       mode == BOT_MODE_GANK or
       mode == BOT_MODE_DEFEND_ALLY ) and mutil.CanUseRefresherShard(bot)
    then
      bot:Action_UseAbility(rs);
      return
    end
  end

  local ro=IsItemAvailable("item_refresher");
  if ro~=nil and ro:IsFullyCastable()
  then
    if ( mode == BOT_MODE_ATTACK or
       mode == BOT_MODE_ROAM or
       mode == BOT_MODE_TEAM_ROAM or
       mode == BOT_MODE_GANK or
       mode == BOT_MODE_DEFEND_ALLY ) and mutil.CanUseRefresherOrb(bot)
    then
      bot:Action_UseAbility(ro);
      return
    end
  end

  local sc=IsItemAvailable("item_solar_crest");
  if sc~=nil and sc:IsFullyCastable()
  then
    if ( mode == BOT_MODE_ATTACK or
       mode == BOT_MODE_ROAM or
       mode == BOT_MODE_TEAM_ROAM or
       mode == BOT_MODE_GANK or
       mode == BOT_MODE_DEFEND_ALLY )
    then
      if ( npcTarget ~= nil and npcTarget:IsHero()
         and not npcTarget:HasModifier('modifier_item_solar_crest_armor_reduction')
         and not npcTarget:IsMagicImmune()
         and GetUnitToUnitDistance(npcTarget, bot) < 900 )
      then
          bot:Action_UseAbilityOnEntity(sc, npcTarget);
        return
      end
    end
  end

  if sc~=nil and sc:IsFullyCastable() then
    local Allies=bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
    for _,Ally in pairs(Allies) do
      if Ally:GetUnitName() ~= bot:GetUnitName() and not Ally:HasModifier('modifier_item_solar_crest_armor_reduction') and
         ( ( Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 and tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 and CanCastOnTarget(Ally) ) or
         ( IsDisabled(Ally) and CanCastOnTarget(Ally) ) )
      then
        bot:Action_UseAbilityOnEntity(sc,Ally);
        return;
      end
    end
  end

  local se=IsItemAvailable("item_silver_edge");
    if se ~= nil and se:IsFullyCastable() then
    if mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH and
      tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0
    then
      bot:Action_UseAbility(se);
      return;
      end
    if ( mode == BOT_MODE_ROAM or
       mode == BOT_MODE_TEAM_ROAM or
       mode == BOT_MODE_GANK )
    then
      if ( npcTarget ~= nil and npcTarget:IsHero() and GetUnitToUnitDistance(npcTarget, bot) > 1000 and  GetUnitToUnitDistance(npcTarget, bot) < 2500 )
      then
          bot:Action_UseAbility(se);
        return;
      end
    end
  end

  local hood=IsItemAvailable("item_pipe") or IsItemAvailable("item_hood_of_defiance");
    if hood~=nil and hood:IsFullyCastable() and bot:GetHealth()/bot:GetMaxHealth()<0.8 and not bot:HasModifier('modifier_item_pipe_barrier')
  then
    if tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 then
      bot:Action_UseAbility(hood);
      return;
    end
  end

  local cguard=IsItemAvailable("item_crimson_guard")
    if cguard~=nil and cguard:IsFullyCastable() and not bot:HasModifier('modifier_item_crimson_guard_nostack')
  then
    if tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 then
      bot:Action_UseAbility(cguard);
      return;
    end
  end

  local cguard=IsItemAvailable("item_ancient_janggo")
    if cguard~=nil and cguard:IsFullyCastable() and not bot:HasModifier('modifier_item_ancient_janggo_active')
  then
    if tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 then
      bot:Action_UseAbility(cguard);
      return;
    end
  end

  local lotus=IsItemAvailable("item_lotus_orb");
  if lotus~=nil and lotus:IsFullyCastable()
  then
    if  not bot:HasModifier('modifier_item_lotus_orb_active')
      and not bot:IsMagicImmune()
      and (
        bot:IsSilenced()
        or ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 and bot:GetHealth()/bot:GetMaxHealth() < 0.35 + (0.05*#tableNearbyEnemyHeroes) )
        or HasLotusableProjectile(bot)
      )
      then
      bot:Action_UseAbilityOnEntity(lotus,bot);
      return;
    end
  end

  if lotus~=nil and lotus:IsFullyCastable()
  then
    local Allies=bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
    for _,Ally in pairs(Allies) do
      if  not Ally:HasModifier('modifier_item_lotus_orb_active')
        and not Ally:IsMagicImmune()
        and (
          Ally:IsSilenced()
          or HasLotusableProjectile(Ally)
        )
      then
        bot:Action_UseAbilityOnEntity(lotus,Ally);
        return;
      end
    end
  end

  local hurricanpike = IsItemAvailable("item_hurricane_pike");
  if hurricanpike~=nil and hurricanpike:IsFullyCastable()
  then
    if ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH )
    then
      for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
      do
        if ( GetUnitToUnitDistance( npcEnemy, bot ) < 400 and CanCastOnTarget(npcEnemy) )
        then
          bot:Action_UseAbilityOnEntity(hurricanpike,npcEnemy);
          return
        end
      end
      if bot:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),10) and bot:DistanceFromFountain() > 0
      then
        bot:Action_UseAbilityOnEntity(hurricanpike,bot);
        return;
      end
    end
  end

  local glimer=IsItemAvailable("item_glimmer_cape");
  if glimer~=nil and glimer:IsFullyCastable() then
    if  not bot:HasModifier('modifier_item_glimmer_cape')
      and not bot:IsMagicImmune()
      and ( bot:IsSilenced() or ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 and bot:GetHealth()/bot:GetMaxHealth() < 0.35 + (0.05*#tableNearbyEnemyHeroes) ) )
      then
      bot:Action_UseAbilityOnEntity(glimer,bot);
      return;
    end
  end

  if glimer~=nil and glimer:IsFullyCastable() then
    local Allies=bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
    for _,Ally in pairs(Allies) do
      if not Ally:HasModifier('modifier_item_glimmer_cape')
         and not Ally:IsMagicImmune()
         and Ally:WasRecentlyDamagedByAnyHero(2.0)
         and (( Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 and tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes > 0 ) or IsDisabled(Ally) or Ally:IsChanneling())
      then
        bot:Action_UseAbilityOnEntity(glimer,Ally);
        return;
      end
    end
  end

  local hom=IsItemAvailable("item_hand_of_midas");
  if hom~=nil and hom:IsFullyCastable() then
    local range = bot:GetAttackRange() + 200;
    local tableNearbyCreeps = bot:GetNearbyCreeps( range, true );
    if #tableNearbyCreeps > 0
      and tableNearbyCreeps[1] ~= nil
      and tableNearbyCreeps[1]:IsMagicImmune() == false
      and tableNearbyCreeps[1]:IsAncientCreep() == false
    then
      bot:Action_UseAbilityOnEntity(hom, tableNearbyCreeps[1]);
      return;
    end
  end

  local guardian=IsItemAvailable("item_guardian_greaves");
  if guardian~=nil and guardian:IsFullyCastable() then
    local Allies=bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
    for _,Ally in pairs(Allies) do
      if  Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 and tableNearbyEnemyHeroes~=nil and #tableNearbyEnemyHeroes > 0
      then
        bot:Action_UseAbility(guardian);
        return;
      end
    end
  end

  local satanic=IsItemAvailable("item_satanic");
  if satanic~=nil and satanic:IsFullyCastable() then
    if  bot:GetHealth()/bot:GetMaxHealth() < 0.50 and
      tableNearbyEnemyHeroes~=nil and #tableNearbyEnemyHeroes > 0 and
      bot:GetActiveMode() == BOT_MODE_ATTACK
    then
      bot:Action_UseAbility(satanic);
      return;
    end
  end

  local cyclone=IsItemAvailable("item_cyclone");
  if cyclone~=nil and cyclone:IsFullyCastable() then
    if npcTarget ~= nil and ( npcTarget:HasModifier('modifier_teleporting') or npcTarget:HasModifier('modifier_abaddon_borrowed_time') )
       and CanCastOnTarget(npcTarget) and GetUnitToUnitDistance(bot, npcTarget) < 775
    then
      bot:Action_UseAbilityOnEntity(cyclone, npcTarget);
      return;
    end
  end

  local metham=IsItemAvailable("item_meteor_hammer");
  if metham~=nil and metham:IsFullyCastable() then
    if mutil.IsPushing(bot) then
      local towers = bot:GetNearbyTowers(800, true);
      if #towers > 0 and towers[1] ~= nil and  towers[1]:IsInvulnerable() == false then
        bot:Action_UseAbilityOnLocation(metham, towers[1]:GetLocation());
        return;
      end
    elseif  mutil.IsInTeamFight(bot, 1200) then
      local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), 600, 300, 0, 0 );
      if ( locationAoE.count >= 2 )
      then
        bot:Action_UseAbilityOnLocation(metham, locationAoE.targetloc);
        return;
      end
    elseif mutil.IsGoingOnSomeone(bot) then
      if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, bot, 800)
         and mutil.IsDisabled(true, npcTarget) == true
      then
        bot:Action_UseAbilityOnLocation(metham, npcTarget:GetLocation());
        return;
      end
    end
  end

  local sv=IsItemAvailable("item_spirit_vessel");
  if sv~=nil and sv:IsFullyCastable() and sv:GetCurrentCharges() > 0
  then
    if mutil.IsGoingOnSomeone(bot)
    then
      if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, bot, 900)
         and npcTarget:HasModifier("modifier_item_spirit_vessel_damage") == false and npcTarget:GetHealth()/npcTarget:GetMaxHealth() < 0.65
      then
          bot:Action_UseAbilityOnEntity(sv, npcTarget);
        return;
      end
    else
      local Allies=bot:GetNearbyHeroes(1150,false,BOT_MODE_NONE);
      for _,Ally in pairs(Allies) do
        if Ally:HasModifier('modifier_item_spirit_vessel_heal') == false and mutil.CanCastOnNonMagicImmune(Ally) and
           Ally:GetHealth()/Ally:GetMaxHealth() < 0.35 and #tableNearbyEnemyHeroes == 0 and Ally:WasRecentlyDamagedByAnyHero(2.5) == false
        then
          bot:Action_UseAbilityOnEntity(sv,Ally);
          return;
        end
      end
    end
  end

  local hod=IsItemAvailable("item_helm_of_the_dominator");
  if hod and hod:IsFullyCastable() and ThinkAboutMindControl(hod, "none") then
    return
  end

  local armlet = IsItemAvailable("item_armlet");
  if armlet then
    local shouldArmlet = npcTarget and npcTarget:IsAlive() and mutil.IsInRange(npcTarget, bot, bot:GetAttackRange() + 200)
    shouldArmlet = not (not shouldArmlet)
    local isArmlet = bot:HasModifier('modifier_item_armlet_unholy_strength')
    -- print('armlet? ' .. tostring(shouldArmlet) .. ', ' .. tostring(isArmlet))
    if isArmlet ~= shouldArmlet then
      if armlet:IsFullyCastable() then
        CastAbility(armlet, nil)
        print('Toggled armlet')
        return
      end
    end
  end

  local bkb = IsItemAvailable("item_black_king_bar");
  if bkb then
    if bot:IsSilenced()
      or (npcTarget and npcTarget:IsAlive() and mutil.IsInRange(npcTarget, bot, bot:GetAttackRange() + 200))
    then
      if not bot:IsMagicImmune() and bkb:IsFullyCastable() then
        CastAbility(bkb, nil)
      end
    end
  end

  local itemTable = {
    item_heavens_halberd = "modifier_heavens_halberd_debuff",
    item_nullifier = "modifier_item_nullifier_mute",
    item_sheepstick = "modifier_sheepstick_debuff",
    item_bloodthorn = "modifier_bloodthorn_debuff",
    item_medallion_of_courage = "modifier_item_medallion_of_courage_armor_reduction",
    item_solar_crest = "modifier_item_solar_crest_armor_reduction",
    item_rod_of_atos = "modifier_rod_of_atos_debuff",
  }
  local didAct = false
  local couldAct = false

  if npcTarget then
    for itemName, modifier in pairs(itemTable) do
      local tempCouldAct
      didAct, tempCouldAct = CheckAndUseItem(itemName, modifier, npcTarget, false)
      if didAct then
        return
      end
      if tempCouldAct then
        couldAct = true
      end
    end
  end

  if couldAct then
    -- last, change targets
    local targets = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    local newTarget = targets[RandomInt(1, #targets)]
    bot:SetTarget(newTarget)
  end
end

function HasLotusableProjectile (bot)
  local incProj = bot:GetIncomingTrackingProjectiles()
  for _,proj in ipairs(incProj) do
    if not proj.is_attack then
      if GetUnitToLocationDistance(bot, proj.location) < 200 then
        return true
      end
    end
  end
  return false
end

function CastAbility (ability, npcTarget)
  local behave = ability:GetBehavior()
  if bit.band(behave, 8) == 8 and npcTarget ~= nil then
    print('Casting ' .. ability:GetName() .. ' directly')
    bot:Action_UseAbilityOnEntity(ability, npcTarget);
    return
  end
  if bit.band(behave, 16) == 16 and npcTarget ~= nil then
    print('Casting ' .. ability:GetName() .. ' by location ' .. tostring(npcTarget:GetLocation()))
    bot:Action_UseAbilityOnLocation(ability, npcTarget:GetLocation());
    return
  end
  print('Casting ' .. ability:GetName())
  bot:Action_UseAbility(ability);
end

function CheckAndUseSpell (spellName, modifier, npcTarget, castThroughStuns)
  local ability = bot:GetAbilityByName(spellName)
  return CheckAndUseAbility(ability, modifier, npcTarget, castThroughStuns)
end

function CheckAndUseAbility (ability, modifier, npcTarget, castThroughStuns)
  if ability~=nil and ability:IsFullyCastable()
  then
    if mutil.IsGoingOnSomeone(bot)
    then
      if npcTarget == nil then
        CastAbility(ability, nil)
        return true, false;
      end
      if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, bot, ability:GetCastRange())
         and not npcTarget:HasModifier(modifier)
      then
        if not castThroughStuns and IsDisabled(npcTarget) then
          return false, true
        end
        print('Casting stuff on this badguy! ' .. ability:GetName())
        CastAbility(ability, npcTarget)
        return true, false;
      end
    end
    return false, true
  end
  return false, false
end

function CheckAndUseItem (itemName, modifier, npcTarget, castThroughStuns)
  local item = IsItemAvailable(itemName);
  return CheckAndUseAbility(item, modifier, npcTarget, castThroughStuns)
end

function IsItemAvailable(item_name)
    --[[for i = 0, 5 do
        local item = bot:GetItemInSlot(i);
    if item~=nil and item:GetName() == item_name then
      return item;
    end
    end]]--
  local slot = bot:FindItemSlot(item_name);
  if bot:GetItemSlotType(slot) == ITEM_SLOT_TYPE_MAIN then
    return bot:GetItemInSlot(slot);
  end
    return nil;
end

function ThinkAboutMindControl (ability, modifier)
  if ability == nil or not ability:IsFullyCastable() then
    return false
  end
  local maxHP = 0;
  local NCreep = nil;
  local canTargetAncients = bit.band(ability:GetTargetFlags(), 512) == 0
  local tableNearbyNeutrals = bot:GetNearbyNeutralCreeps( 1600 );
  if tableNearbyNeutrals ~= nil and #tableNearbyNeutrals >= 1 then
    for _,neutral in pairs(tableNearbyNeutrals)
    do
      local NeutralHP = neutral:GetHealth();
      if NeutralHP > maxHP and neutral:GetTeam() ~= bot:GetTeam() and (canTargetAncients or not neutral:IsAncientCreep())
      then
        NCreep = neutral;
        maxHP = NeutralHP;
      end
    end
  end

  tableNearbyNeutrals = bot:GetNearbyCreeps( 1600, true );
  if tableNearbyNeutrals ~= nil and #tableNearbyNeutrals >= 1 then
    for _,neutral in pairs(tableNearbyNeutrals)
    do
      local NeutralHP = neutral:GetHealth();
      if NeutralHP > maxHP and neutral:GetTeam() ~= bot:GetTeam() and (canTargetAncients or not neutral:IsAncientCreep())
      then
        NCreep = neutral;
        maxHP = NeutralHP;
      end
    end
  end

  local tableNearbyAllies = nil
  local distances = {}
  local myDistance = 0
  local alliedNeutralCount = 0
  if NCreep then
    myDistance = GetUnitToUnitDistance(bot, NCreep)
    tableNearbyAllies = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE)
    alliedNeutralCount = #(bot:GetNearbyCreeps( 1600, false ));
  end
  if NCreep and tableNearbyAllies ~= nil and #tableNearbyAllies >= 1 then
    for _,hero in pairs(tableNearbyAllies) do
      if NCreep and GetUnitToUnitDistance(hero, NCreep) < myDistance then
        if alliedNeutralCount > 0 then
          alliedNeutralCount = alliedNeutralCount - 1
        else
          NCreep = nil
        end
      end
    end
  end

  if NCreep == nil then
    return false
  end

  bot:Action_UseAbilityOnEntity(ability, NCreep);
  return true
end

function ConsiderAOERadiusAbility(unit, ability, nRadius)
  local isToggle = bit.band(ability:GetBehavior(), 512) == 512
  local desireNone = BOT_ACTION_DESIRE_NONE
  local desireHigh = BOT_ACTION_DESIRE_HIGH
  local abilityName = ability:GetName()

  -- print(ability:GetName() .. ' . ' .. tostring(isToggle) .. ' / ' .. tostring(ability:GetToggleState()))


  if not nRadius then
    nRadius = math.max(ability:GetCastRange(), ability:GetSpecialValueInt( "radius" ))
  end

  if unit:HasScepter() then
    local scepterRadius = ability:GetSpecialValueInt( "radius_scepter" )
    nRadius = math.max(scepterRadius, nRadius)
  end

  if nRadius < 1 then
    local shortName = abilityName:sub(abilityName:find('_') + 1, -1)
    nRadius = ability:GetSpecialValueInt( shortName .. "_radius" )
  end

  local isAOE = nRadius > 0

  if isToggle and ability:GetToggleState() then
    nRadius = nRadius + 100
    desireHigh = BOT_ACTION_DESIRE_NONE
    desireNone = BOT_ACTION_DESIRE_HIGH
  end

  -- Make sure it's castable
  if (not ability or not ability:IsFullyCastable() or ability:IsHidden()) then
    return BOT_ACTION_DESIRE_NONE, isAOE;
  end

  local tableAllNearbyEnemyHeroes = unit:GetNearbyHeroes( nRadius, true, BOT_MODE_NONE );
  local tableNearbyEnemyHeroes = {}

  if Data[ability:GetName()] then
    local modifier = Data[ability:GetName()]
    for _,unit in ipairs(tableAllNearbyEnemyHeroes) do
      if not unit:HasModifier(modifier) then
        table.insert(tableNearbyEnemyHeroes, unit)
      end
    end
  else
    tableNearbyEnemyHeroes = tableAllNearbyEnemyHeroes
  end

  if ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes >= 1 ) then
    return desireHigh, isAOE;
  end

  return desireNone, isAOE;
end

return MyModule;

