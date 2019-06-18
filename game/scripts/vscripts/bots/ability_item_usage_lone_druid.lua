if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or  GetBot():IsIllusion() then
  return;
end


local ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )
local utils = require(GetScriptDirectory() ..  "/util")
local mutil = require(GetScriptDirectory() ..  "/MyUtility")


function AbilityLevelUpThink()
  ability_item_usage_generic.AbilityLevelUpThink();
end
function BuybackUsageThink()
  ability_item_usage_generic.BuybackUsageThink();
end
function CourierUsageThink()
  ability_item_usage_generic.CourierUsageThink();
end
function ItemUsageThink()
  ability_item_usage_generic.ItemUsageThink()
end

local castFGDesire = 0;
local castOPDesire = 0;
local castESDesire = 0;
local castTFDesire = 0;
local castDFDesire = 0;
local castBCDesire = 0;

local abilityFG = nil;
local abilityOP = nil;
local abilityES = nil;
local abilityTF = nil;
local abilityDF = nil;
local abilityBC = nil;

local npcBot = nil;

function AbilityUsageThink()

  if npcBot == nil then npcBot = GetBot(); end

  -- Check if we're already using an ability
  if mutil.CanNotUseAbility(npcBot) then return end

  if abilityFG == nil then abilityFG = npcBot:GetAbilityByName( "lone_druid_spirit_bear" ) end
  if abilityOP == nil then abilityOP = npcBot:GetAbilityByName( "lone_druid_spirit_link" ) end
  if abilityES == nil then abilityES = npcBot:GetAbilityByName( "lone_druid_savage_roar" ) end
  if abilityTF == nil then abilityTF = npcBot:GetAbilityByName( "lone_druid_true_form" ) end
  if abilityDF == nil then abilityDF = npcBot:GetAbilityByName( "lone_druid_true_form_druid" ) end
  if abilityBC == nil then abilityBC = npcBot:GetAbilityByName( "lone_druid_true_form_battle_cry" ) end

  -- Consider using each ability
  castFGDesire, castFGTarget = ConsiderFleshGolem();
  castOPDesire = ConsiderOverpower();
  castESDesire = ConsiderEarthshock();
  castTFDesire = ConsiderTrueForm();
  castDFDesire = ConsiderDruidForm();
  castBCDesire = ConsiderBattleCry();

  if ( castFGDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityFG );
    return;
  end
  if ( castOPDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityOP );
    return;
  end
  if ( castESDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityES );
    return;
  end
  if ( castBCDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityBC );
    return;
  end
  if ( castTFDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityTF );
    return;
  end
  if ( castDFDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityDF );
    return;
  end

end

function ConsiderFleshGolem()

  -- Make sure it's castable
  if ( not abilityFG:IsFullyCastable() ) then
    return BOT_ACTION_DESIRE_NONE;
  end

  local numBear = 0;

  local listBear = GetUnitList(UNIT_LIST_ALLIES);
  for _,unit in pairs(listBear)
  do
    if string.find(unit:GetUnitName(), "npc_dota_lone_druid_bear") then
      numBear = numBear + 1;
    end
  end

  if  numBear == 0 then
    return BOT_ACTION_DESIRE_MODERATE;
  end

  return BOT_ACTION_DESIRE_NONE;
end

function ConsiderOverpower()

  -- Make sure it's castable
  if ( not abilityOP:IsFullyCastable() ) then
    return BOT_ACTION_DESIRE_NONE;
  end

  local attackRange = npcBot:GetAttackRange();

  -- If we're going after someone
  if mutil.IsGoingOnSomeone(npcBot)
  then
    local npcTarget = npcBot:GetTarget();
    if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, npcBot, attackRange+200)
    then
      return BOT_ACTION_DESIRE_MODERATE;
    end
  end

  return BOT_ACTION_DESIRE_NONE;
end

function ConsiderEarthshock()

  -- Make sure it's castable
  if ( not abilityES:IsFullyCastable() ) then
    return BOT_ACTION_DESIRE_NONE;
  end

  -- Get some of its values
  local nRadius = abilityES:GetSpecialValueInt( "radius" );

  -- If we're going after someone
  if mutil.IsGoingOnSomeone(npcBot)
  then
    local npcTarget = npcBot:GetTarget();
    if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, npcBot, nRadius)
    then
      return BOT_ACTION_DESIRE_MODERATE;
    end
  end

  return BOT_ACTION_DESIRE_NONE;

end

function ConsiderTrueForm()

  -- Make sure it's castable
  if ( not abilityTF:IsFullyCastable() or abilityTF:IsHidden() ) then
    return BOT_ACTION_DESIRE_NONE;
  end

  if mutil.IsGoingOnSomeone(npcBot)
  then
    local npcTarget = npcBot:GetTarget();
    if ( mutil.IsValidTarget(npcTarget) and mutil.IsInRange(npcTarget, npcBot, 1000) and abilityBC:IsFullyCastable() and abilityBC:IsHidden()  )
    then
      return BOT_ACTION_DESIRE_MODERATE;
    end
  end

  return BOT_ACTION_DESIRE_NONE;
end

function ConsiderDruidForm()

  -- Make sure it's castable
  if ( not abilityDF:IsFullyCastable() or abilityDF:IsHidden() ) then
    return BOT_ACTION_DESIRE_NONE;
  end

  if mutil.IsGoingOnSomeone(npcBot)
  then
    local npcTarget = npcBot:GetTarget();
    if ( mutil.IsValidTarget(npcTarget) and mutil.IsInRange(npcTarget, npcBot, 1000) and not abilityBC:IsFullyCastable() and not abilityBC:IsHidden() )
    then
      return BOT_ACTION_DESIRE_MODERATE;
    end
  end

  return BOT_ACTION_DESIRE_NONE;
end

function ConsiderBattleCry()

  -- Make sure it's castable
  if ( not abilityBC:IsFullyCastable() or abilityBC:IsHidden() ) then
    return BOT_ACTION_DESIRE_NONE;
  end

  if mutil.IsPushing(npcBot)
  then
    local tableNearbyEnemyTowers = npcBot:GetNearbyTowers( 800, true );
    if tableNearbyEnemyTowers[1] ~= nil and mutil.IsInRange(tableNearbyEnemyTowers[1], npcBot, 1000)
    then
      return BOT_ACTION_DESIRE_MODERATE;
    end
  end

  if mutil.IsGoingOnSomeone(npcBot)
  then
    local npcTarget = npcBot:GetTarget();
    if mutil.IsValidTarget(npcTarget) and mutil.IsInRange(npcTarget, npcBot, 1000)
    then
      return BOT_ACTION_DESIRE_MODERATE;
    end
  end

  return BOT_ACTION_DESIRE_NONE;
end
