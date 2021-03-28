//---------------------------------------------------------------------------------------
//  FILE:   X2Effect_ManualOverride_PexM.uc                                    
//
//	File created by RustyDios	
//
//	File created	18/08/20    16:00
//	LAST UPDATED    21/08/20    00:20
//
//  ADDS psi abilities effects
//
//---------------------------------------------------------------------------------------
class X2Effect_ManualOverride_PexM extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;
    local array<name> PSIONICS_VALID_ABILITIES;
	local int i;

    PSIONICS_VALID_ABILITIES = class'X2Item_PsionicsExMachina'.default.RAPID_PSIONICS_VALID_ABILITIES;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(kNewTargetState);
	for (i = 0; i < UnitState.Abilities.Length; ++i)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.Abilities[i].ObjectID));
		if (AbilityState != none && AbilityState.iCooldown > 0 && PSIONICS_VALID_ABILITIES.Find(AbilityState.GetMyTemplateName()) != -1)
		{
			AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
			AbilityState.iCooldown = 0;

       		`LOG("Ability Cooldown Reset :: " $AbilityState.GetMyTemplateName() ,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid_MO');
		}
	}
}