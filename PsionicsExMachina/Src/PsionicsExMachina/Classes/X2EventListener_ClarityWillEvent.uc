//---------------------------------------------------------------------------------------
//  FILE:    X2EventListener_ClarityWillEvent.uc
//
//	File created by RustyDios	
//
//	File created	25/03/21    07:30
//	LAST UPDATED    25/03/21    07:30
//
//  Basically a 'clone' of the SpectreM1 Horror will event!
//
//---------------------------------------------------------------------------------------
class X2EventListener_ClarityWillEvent extends X2EventListener_DefaultWillEvents
	dependson(XComGameStateContext_WillRoll)
	config(PsionicsExMachina_Abilities);
	//native(Core);

var const localized string ClarityActivated;

var config bool bEnableClarityWillRolls, bSkipForCommandersAvatar;
var protected const config WillEventRollData ClarityWillRollData;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateClarityActivatedTemplate());

	return Templates;
}

static function X2EventListenerTemplate CreateClarityActivatedTemplate()
{
	local X2EventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'ClarityActivated');

	Template.RegisterInTactical = true;
	Template.AddEvent('ClarityActivated', OnClarityActivated);

	return Template;
}

static protected function EventListenerReturn OnClarityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_WillRoll WillRollContext;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit TargetUnit;

	//make sure we have the right ability
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && class'XComGameStateContext_Ability'.static.IsHitResultHit(AbilityContext.ResultContext.HitResult))
	{
		//grab the activating unit, target of Clarity is same as Source
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		
		//if the Target exists and Clarity will rolls is on
		if(TargetUnit != none && default.bEnableClarityWillRolls)
		{
			//skip for the commander if activated
			if( Targetunit.GetMyTemplateName() == 'AdvPsiWitchM2' && default.bSkipForCommandersAvatar)
			{
				return ELR_NoInterrupt;
			}
			else if( class'XComGameStateContext_WillRoll'.static.ShouldPerformWillRoll(default.ClarityWillRollData, TargetUnit) )
			{
				//else roll for will loss + panic event
				WillRollContext = class'XComGameStateContext_WillRoll'.static.CreateWillRollContext(TargetUnit, 'ClarityActivated', default.ClarityActivated, false);
				WillRollContext.DoWillRoll(default.ClarityWillRollData);
				WillRollContext.Submit();
			}
		}			
	}

	return ELR_NoInterrupt;
}
