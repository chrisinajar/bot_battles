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

local castIFDesire = 0;
local castBSDesire = 0;
local castLBDesire = 0;

local abilityIF = nil;
local abilityBS = nil;
local abilityLB = nil;

local npcBot = nil;

function AbilityUsageThink()

  if npcBot == nil then npcBot = GetBot(); end
  -- Check if we're already using an ability
  if mutil.CanNotUseAbility(npcBot) then return end

  if abilityIF == nil then abilityIF = npcBot:GetAbilityByName( "huskar_inner_fire" ) end
  if abilityBS == nil then abilityBS = npcBot:GetAbilityByName( "huskar_burning_spear" ) end
  if abilityLB == nil then abilityLB = npcBot:GetAbilityByName( "huskar_life_break" ) end

  -- Consider using each ability
  castIFDesire = ability_item_usage_generic.ConsiderAOERadiusAbility(npcBot, abilityIF);
  castBSDesire, castBSTarget = ConsiderBurningSpear();
  castLBDesire, castLBTarget = ConsiderLifeBreak();

  if ( castIFDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityIF );
    return;
  end

  if ( castBSDesire > 0 )
  then
    npcBot:Action_UseAbilityOnEntity( abilityBS, castBSTarget );
    return;
  end

  if ( castLBDesire > castIFDesire and castLBDesire > castBSDesire )
  then
    npcBot:Action_UseAbilityOnEntity( abilityLB, castLBTarget );
    return;
  end

end


function ConsiderBurningSpear()

  -- Make sure it's castable
  if ( not abilityBS:IsFullyCastable() ) then
    return BOT_ACTION_DESIRE_NONE, 0;
  end

  -- Get some of its values
  local nCastRange = abilityBS:GetCastRange();
  local nDamage = abilityBS:GetAbilityDamage();
  local nRadius = 0;
  local nAttackRange = npcBot:GetAttackRange();

  -- If we're going after someone
  if mutil.IsGoingOnSomeone(npcBot)
  then
    local npcTarget = npcBot:GetTarget();
    if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, npcBot, nAttackRange+200)
    then
      return BOT_ACTION_DESIRE_MODERATE, npcTarget;
    end
  end

  return BOT_ACTION_DESIRE_NONE, 0;
end


function ConsiderLifeBreak()

  -- Make sure it's castable
  if ( not abilityLB:IsFullyCastable() or npcBot:IsRooted() ) then
    return BOT_ACTION_DESIRE_NONE, 0;
  end

  local nCastRange = abilityLB:GetCastRange();

  if mutil.IsGoingOnSomeone(npcBot)
  then
    local npcTarget = npcBot:GetTarget();
    if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnNonMagicImmune(npcTarget) and mutil.IsInRange(npcTarget, npcBot, nCastRange+200)
    then
      return BOT_ACTION_DESIRE_VERYHIGH, npcTarget;
    end
  end

  return BOT_ACTION_DESIRE_NONE, 0;
end
