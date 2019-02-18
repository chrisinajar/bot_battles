local ability_item_usage_generic = dofile( GetScriptDirectory().."/ability_item_usage_generic" )

function AbilityUsageThink()
  ability_item_usage_generic.AbilityUsageThink()
end

function ItemUsageThink()
  ability_item_usage_generic.ItemUsageThink()
end
