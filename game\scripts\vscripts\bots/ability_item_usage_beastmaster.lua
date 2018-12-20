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


local castWADesire = 0;
local castWBDesire = 0;
local castPRDesire = 0;

local abilityWA = nil;
local abilityWB = nil;
local abilityWH = nil;
local abilityPR = nil;

local npcBot = nil;

function AbilityUsageThink()

	if npcBot == nil then npcBot = GetBot(); end

	-- Check if we're already using an ability
	if mutil.CanNotUseAbility(npcBot) then return end

	if abilityWA == nil then abilityWA = npcBot:GetAbilityByName( "beastmaster_wild_axes" ) end
  if abilityWB == nil then abilityWB = npcBot:GetAbilityByName( "beastmaster_call_of_the_wild_boar" ) end
	if abilityWH == nil then abilityWH = npcBot:GetAbilityByName( "beastmaster_call_of_the_wild_hawk" ) end
  if abilityPR == nil then abilityPR = npcBot:GetAbilityByName( "beastmaster_primal_roar" ) end

	-- Consider using each ability
	castWADesire, castWALocation = ConsiderWildAxes();
  castWBDesire = ConsiderWildBoar();
	castWHDesire = ConsiderWildHawk();

  local didAct = false
  local couldAct = false
  local npcTarget = npcBot:GetTarget()

  didAct, couldAct = ability_item_usage_generic.CheckAndUseAbility(abilityPR, "none", npcTarget, false)
  if didAct then return end

  if couldAct then
    -- last, change targets
    local targets = npcBot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    if #targets < 1 then
      return
    end
    local newTarget = targets[RandomInt(1, #targets)]
    npcBot:SetTarget(newTarget)
  end

	if ( castWADesire > 0 )
	then
		npcBot:Action_UseAbilityOnLocation( abilityWA, castWALocation );
		return;
	end

  if ( castWBDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityWB );
    return;
  end

  if ( castWHDesire > 0 )
  then
    npcBot:Action_UseAbility( abilityWH );
    return;
  end
end


function ConsiderWildAxes()

	-- Make sure it's castable
	if ( not abilityWA:IsFullyCastable() )
	then
		return BOT_ACTION_DESIRE_NONE, 0;
	end

	-- Get some of its values
	local nRadius = abilityWA:GetSpecialValueInt( "radius" );
	local nCastRange = abilityWA:GetCastRange();
	local nCastPoint = abilityWA:GetCastPoint( );
	local nDamage = abilityWA:GetSpecialValueInt("axe_damage");

	if nCastRange > 1600 then nCastRange = 1600 end
	--------------------------------------
	-- Mode based usage
	--------------------------------------

	-- If a mode has set a target, and we can kill them, do it
	local npcTarget = npcBot:GetTarget();
	if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnMagicImmune(npcTarget) and
	   mutil.CanKillTarget(npcTarget, nDamage, DAMAGE_TYPE_PHYSICAL) and mutil.IsInRange(npcTarget, npcBot, nCastRange)
	then
		return BOT_ACTION_DESIRE_MODERATE, npcTarget:GetExtrapolatedLocation( (GetUnitToUnitDistance(npcTarget, npcBot )/800) + nCastPoint );
	end


	-- If we're going after someone
	if mutil.IsGoingOnSomeone(npcBot)
	then
		if mutil.IsValidTarget(npcTarget) and mutil.CanCastOnMagicImmune(npcTarget) and  mutil.IsInRange(npcTarget, npcBot, nCastRange)
		then
			return BOT_ACTION_DESIRE_MODERATE, npcTarget:GetExtrapolatedLocation( (GetUnitToUnitDistance(npcTarget, npcBot )/800) + nCastPoint );
		end
	end

	local skThere, skLoc = mutil.IsSandKingThere(npcBot, nCastRange, 2.0);

	if skThere then
		return BOT_ACTION_DESIRE_MODERATE, skLoc;
	end

	return BOT_ACTION_DESIRE_NONE, 0;
end

function ConsiderWildBoar()

  -- Make sure it's castable
  if ( not abilityWB:IsFullyCastable() )
  then
    return BOT_ACTION_DESIRE_NONE;
  end

  return BOT_ACTION_DESIRE_MODERATE
end

function ConsiderWildHawk()

  -- Make sure it's castable
  if ( not abilityWH:IsFullyCastable() )
  then
    return BOT_ACTION_DESIRE_NONE;
  end

  return BOT_ACTION_DESIRE_LOW;
end
