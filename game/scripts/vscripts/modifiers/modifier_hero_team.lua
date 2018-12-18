modifier_hero_team_1 = class(ModifierBaseClass)

function modifier_hero_team_1:GetStatusEffectName()
	return "particles/status_effect_team_1.vpcf"
end

function modifier_hero_team_1:StatusEffectPriority()
	return 50
end

function modifier_hero_team_1:IsHidden()
	return true
end

modifier_hero_team_2 = class(ModifierBaseClass)

function modifier_hero_team_2:GetStatusEffectName()
	return "particles/status_effect_team_2.vpcf"
end

function modifier_hero_team_2:StatusEffectPriority()
	return 50
end

function modifier_hero_team_2:IsHidden()
	return true
end