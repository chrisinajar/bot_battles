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
function AbilityUsageThink()
  local didAct, couldAct = ability_item_usage_generic.AbilityUsageThink()

  if didAct then
    return
  end

  local npcBot = GetBot()

  local abilitySR1 = npcBot:GetAbilityByName( "nevermore_shadowraze1" )
  local abilitySR2 = npcBot:GetAbilityByName( "nevermore_shadowraze2" )
  local abilitySR3 = npcBot:GetAbilityByName( "nevermore_shadowraze3" )


  if mutil.IsGoingOnSomeone(npcBot) then
    local npcTarget = npcBot:GetTarget();
    local distance = GetUnitToUnitDistance(npcBot, npcTarget);

    if IsWithinShadowRaze(abilitySR1, distance) then
      npcBot:Action_UseAbility( abilitySR1 );
      return;
    end

    if IsWithinShadowRaze(abilitySR2, distance) then
      npcBot:Action_UseAbility( abilitySR2 );
      return;
    end

    if IsWithinShadowRaze(abilitySR3, distance) then
      npcBot:Action_UseAbility( abilitySR3 );
      return;
    end
  end
end

function IsWithinShadowRaze (ability, distance)
    return
      distance > (ability:GetSpecialValueInt("shadowraze_range") - ability:GetSpecialValueInt("shadowraze_radius"))
      and distance < (ability:GetSpecialValueInt("shadowraze_range") - ability:GetSpecialValueInt("shadowraze_radius"))
end
