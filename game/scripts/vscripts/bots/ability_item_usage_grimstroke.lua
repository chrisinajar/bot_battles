local ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

local bot = GetBot()

function ItemUsageThink()
  ability_item_usage_generic.ItemUsageThink()
end

function AbilityUsageThink()
  local didAct = false
  local couldAct = false
  local couldAct2 = false
  local npcTarget = bot:GetTarget()

  didAct, couldAct2 = ability_item_usage_generic.CheckAndUseSpell("grimstroke_dark_artistry", "modifier_grimstroke_dark_artistry_debuff", npcTarget, true)
  if didAct then return end
  couldAct = couldAct or couldAct2
  didAct, couldAct2 = ability_item_usage_generic.CheckAndUseSpell("grimstroke_soul_chain", "modifier_grimstroke_soul_chain_debuff", npcTarget, true)
  if didAct then return end
  couldAct = couldAct or couldAct2
  didAct, couldAct2 = ability_item_usage_generic.CheckAndUseSpell("grimstroke_ink_creature", "modifier_grimstroke_ink_creature_debuff", npcTarget, false)
  if didAct then return end
  couldAct = couldAct or couldAct2

  if couldAct then
    -- last, change targets
    local targets = bot:GetNearbyHeroes(1200, true, BOT_MODE_NONE)
    if #targets < 1 then
      return
    end
    local newTarget = targets[RandomInt(1, #targets)]
    bot:SetTarget(newTarget)
  end

end
