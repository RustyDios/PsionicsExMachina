//---------------------------------------------------------------------------------------
//  FILE:   X2Effect_AbilityCostRefund_PexM.uc                                    
//
//  AUTHOR:  xylthixlm && RustyDios
//
//	File created	18/08/20    16:00
//	LAST UPDATED    21/08/20    05:00
//
//  ADDS psi abilities effects
//  ADAPTED FROM XMB CODE TO WORK WITHOUT XMB   FILE:    XMBEffect_AbilityCostRefund.uc
//  CBAC HAS THE COLOUR CHANGE HANDLED BY CBAC CONFIG BRIDGE !!
//---------------------------------------------------------------------------------------
class X2Effect_AbilityCostRefund_PexM extends X2Effect_Persistent;// implements(XMBEffectInterface);

var int MaxRefundsPerTurn;							// Maximum number of actions to refund per turn. Requires CountUnitValue to be set.
var bool bFreeCost;

var array<X2Condition> AbilityTargetConditions;		// Conditions on the target of the ability being refunded.
var array<X2Condition> AbilityShooterConditions;	// Conditions on the shooter of the ability being refunded.

//---------------------------------------------------------------------------------------
//register listener to trigger for other abilities
//---------------------------------------------------------------------------------------
function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;

	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));

	EventMgr.RegisterForEvent(EffectObj, 'RapidPsionics', EffectGameState.TriggerAbilityFlyover, ELD_OnStateSubmitted, , UnitState);
}

//---------------------------------------------------------------------------------------
//adds a free action point for Applying costs, match the RapidPsionics array set up in items (any gem ability)
//actually adds an action point that does the `HAIR TRIGGER: FREE ACTION` flyover and free point cost
//---------------------------------------------------------------------------------------

/*
function bool GrantsFreeActionPointForApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState GameState)
{ 
    local XComGameState_Unit SourceUnit;
    local XComGameState_Ability kAbility, AbilityState;
	local int i;
	local array<name> PSIONICS_VALID_ABILITIES;

    PSIONICS_VALID_ABILITIES = class'X2Item_PsionicsExMachina'.default.RAPID_PSIONICS_VALID_ABILITIES;

    SourceUnit = Shooter;

    kAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

	for (i = 0; i <= SourceUnit.Abilities.Length; ++i)
	{
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.Abilities[i].ObjectID));
		if (AbilityState != none && PSIONICS_VALID_ABILITIES.Find(AbilityState.GetMyTemplateName()) != -1 && kAbility == AbilityState)
		{
            //AbilityState.GetMyTemplate.AbilityCosts.AddItem(default.FreeActionCost); // or something looping through the costs array and adding.bFreeCost = true;
       		`LOG("Ability FreePoint For ApplyCostGranted :: " $AbilityState.GetMyTemplateName() @" :: " $kAbility.GetMyTemplateName(),class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
            return true;
        }
	}

    return false;
}
*/
//---------------------------------------------------------------------------------------
//when an ability is used for a unit under this effect, check the refunds limit, match the RapidPsionics array set up in items (any gem ability)
//CBAC will check for this effect active and change the colour to set config
//reset the unit AP, CHARGES AND COOLDOWN to before the ability was used, and remove the effect
//---------------------------------------------------------------------------------------
function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints)
{
	local X2EventManager EventMgr;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit TargetUnit;
	local UnitValue CountUnitValue;
	local XComGameState_Effect_TemplarFocus FocusState;

    //ensure we have a target
	TargetUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	if (TargetUnit == none)
    {
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
    }

    //check and bail if we reached our limit .. limit is hardcoded at 1, and the activation doesn't count, should never get this, safety net
	SourceUnit.GetUnitValue('RapidPsionics_Uses', CountUnitValue);
	if (MaxRefundsPerTurn >= 0 && CountUnitValue.fValue >= MaxRefundsPerTurn)
	{
   		`LOG("Rapid Psionics FAIL Max Refunds Breached :: " $kAbility.GetMyTemplateName() ,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid_ERROR');
        return false;
    }

    //check and bail if it's not on the psi-gems list ...
	if (ValidateAttack(EffectState, SourceUnit, TargetUnit, kAbility) != 'AA_Success')
	{
		//if the ability used (kability) and the effect origin (abilitystate) are the same then this is 'RapidPsionics' initiation...
   		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
        if (kAbility.GetMyTemplateName() == AbilityState.GetMyTemplateName())
        {
            `LOG("Rapid Psionics INIT Validate :: " $kAbility.GetMyTemplateName() ,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid_INIT');
            return false;
        }
		//if they are different then it's an ability failing to be validated against the 'psi-list' that all GEM abilities add to in x2item_pexm and associated config
        else 
        {
   		    `LOG("Rapid Psionics FAIL Validate :: " $kAbility.GetMyTemplateName() ,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
            return false;
        }
    }

	//  restore the pre cost action points to fully refund this action
	if (bFreeCost || SourceUnit.ActionPoints.Length != PreCostActionPoints.Length)
	{
        //Ability State is the EFFECT GIVER ability , kAbility is the EFFECT USER ability
		AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
		if (AbilityState != none)
		{
			SourceUnit.ActionPoints = PreCostActionPoints;
            `LOG("Rapid Psionics PASS Refund AP :: " $kAbility.GetMyTemplateName(),class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');

			SourceUnit.SetUnitFloatValue('RapidPsionics_Uses', CountUnitValue.fValue + 1, eCleanup_BeginTurn);

            //if the ability had charges assume we just spent one so refund it
            if (kAbility.GetMyTemplate().AbilityCharges != none)
            {
                kAbility.iCharges = kAbility.iCharges +1;
                `LOG("Rapid Psionics PASS Refund CHARGE :: " $kAbility.GetMyTemplateName() @" :: SET at :: " $kAbility.iCharges,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
            }

            //if the ability has a cooldown assume it activated so reset it to 0, it must have been at 0 to be able to use !?
            if (kAbility.GetMyTemplate().AbilityCooldown != none)
            {
                kAbility.iCooldown = 0;
                `LOG("Rapid Psionics PASS Refund COOLDOWN :: " $kAbility.GetMyTemplateName() @" :: SET at :: " $kAbility.iCooldown,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
            }

            //if the ability has a focus component give it back
            if (kAbility.GetFocusCost(SourceUnit) > 0)
            {
				FocusState = SourceUnit.GetTemplarFocusEffectState();

                if (FocusState != none)
				{
					FocusState = XComGameState_Effect_TemplarFocus(NewGameState.ModifyStateObject(FocusState.Class, FocusState.ObjectID));
					FocusState.SetFocusLevel(FocusState.FocusLevel + kAbility.GetFocusCost(SourceUnit), SourceUnit, NewGameState);		
				}

                `LOG("Rapid Psionics PASS Refund FOCUS :: " $kAbility.GetMyTemplateName() @" :: SET at :: " $FocusState.FocusLevel,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
            }

            //signal the event manager to ping the listener
			EventMgr = `XEVENTMGR;
			EventMgr.TriggerEvent('RapidPsionics', AbilityState, SourceUnit, NewGameState);

            //we was a success, remove the buff effect, hardcoded 1 max refunds limit
       		EffectState.RemoveEffect(NewGameState, NewGameState);

            `LOG("Rapid Psionics PASS Refund COMPLETE :: " $AbilityState.GetMyTemplateName() @" == " $kAbility.GetMyTemplateName() @" :: EFFECT REMOVED ",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid_COMPLETE');
            return true;
		}
	}

    //everything went wrong !!, do nothing and bail
	return false;
}
//---------------------------------------------------------------------------------------
//match the RapidPsionics array set up in items (any gem ability), check source and target conditions match effect state/ability
//CBAC will check for this effect active and change the colour to set config
//---------------------------------------------------------------------------------------
function private name ValidateAttack(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState)
{
	local name AvailableCode;
    local array<name> PSIONICS_VALID_ABILITIES;

    PSIONICS_VALID_ABILITIES = class'X2Item_PsionicsExMachina'.default.RAPID_PSIONICS_VALID_ABILITIES;

    if (PSIONICS_VALID_ABILITIES.Find(AbilityState.GetMyTemplateName()) != -1)
    {
        AvailableCode = 'AA_Success';
   		`LOG("Rapid Psionics PASS Valid Ability Found :: " $AbilityState.GetMyTemplateName() ,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
		return AvailableCode;
    }

	AvailableCode = CheckTargetConditions(AbilityTargetConditions, EffectState, Attacker, Target, AbilityState);
	if (AvailableCode != 'AA_Success')
	{
   		`LOG("Rapid Psionics FAIL Valid CheckTargetCondition :: " $AbilityState.GetMyTemplateName() @" :: " $AvailableCode,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
		return AvailableCode;
    }
		
	AvailableCode = CheckShooterConditions(AbilityShooterConditions, EffectState, Attacker, Target, AbilityState);
	if (AvailableCode != 'AA_Success')
	{
   		`LOG("Rapid Psionics FAIL Valid CheckShooterCondition :: " $AbilityState.GetMyTemplateName() @" :: " $AvailableCode,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina_Rapid');
		return AvailableCode;
	}

    //didn't PASS a thing, not valid
	return 'AA_AbilityUnavailable';
}

//---------------------------------------------------------------------------------------
// Checks a list of target conditions for an ability.
//---------------------------------------------------------------------------------------
function static name CheckTargetConditions(out array<X2Condition> CheckAbilityTargetConditions, XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState)
{
	local X2Condition kCondition;
	local name AvailableCode;
		
	foreach CheckAbilityTargetConditions(kCondition)
	{
		AvailableCode = kCondition.AbilityMeetsCondition(AbilityState, Target);
		if (AvailableCode != 'AA_Success')
        {
			return AvailableCode;
        }

		AvailableCode = kCondition.MeetsCondition(Target);
		if (AvailableCode != 'AA_Success')
        {
			return AvailableCode;
        }

		AvailableCode = kCondition.MeetsConditionWithSource(Target, Attacker);
		if (AvailableCode != 'AA_Success')
		{
            return AvailableCode;
        }
	}

    //didn't FAIL a thing, valid
	return 'AA_Success';
}

//---------------------------------------------------------------------------------------
// Checks a list of shooter conditions for an ability.
//---------------------------------------------------------------------------------------
function static name CheckShooterConditions(out array<X2Condition> CheckAbilityShooterConditions, XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState)
{
	local X2Condition kCondition;
	local name AvailableCode;
		
	foreach CheckAbilityShooterConditions(kCondition)
	{
		AvailableCode = kCondition.MeetsCondition(Attacker);
		if (AvailableCode != 'AA_Success')
        {
			return AvailableCode;
	    }
    }

    //didn't FAIL a thing, valid
	return 'AA_Success';
}

//---------------------------------------------------------------------------------------
//    ==============  FUX ME THIS WAS AN AMAZING PIECE OF CODE  ====================
//---------------------------------------------------------------------------------------

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	MaxRefundsPerTurn = -1;
   	EffectName="RapidPsionics_FreeAction"
}
