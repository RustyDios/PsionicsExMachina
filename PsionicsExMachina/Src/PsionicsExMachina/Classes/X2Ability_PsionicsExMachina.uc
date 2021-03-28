//---------------------------------------------------------------------------------------
//  FILE:   X2Ability_PsionicsExMachina.uc                                    
//
//	File created by RustyDios	
//
//	File created	10/08/20    16:00
//	LAST UPDATED    22/01/21	19:22
//
//  ADDS psi abilities for the testing phase
//
//---------------------------------------------------------------------------------------

class X2Ability_PsionicsExMachina extends X2Ability config (PsionicsExMachina_Abilities);

//grab the config variables
var config bool bShowPassiveIcons, bRapid_Cost_Free, bRapid_Cost_EndTurn, bRapid_Resets_PsiAbility_Cooldowns, bRapid_GivesNext_PsiAbility_FreeAction;

var config int iRapid_Cost_AP;
var config int iPSIBOOST_STANDARD, iRapid_Cost_Cooldown_STANDARD, iRapid_Cost_xCharges_STANDARD;
var config int iPSIBOOST_AVERAGE, iRapid_Cost_Cooldown_AVERAGE, iRapid_Cost_xCharges_AVERAGE;
var config int iPSIBOOST_GIFTED, iRapid_Cost_Cooldown_GIFTED, iRapid_Cost_xCharges_GIFTED;
var config int iPSIBOOST_GENIUS, iRapid_Cost_Cooldown_GENIUS, iRapid_Cost_xCharges_GENIUS;
var config int iPSIBOOST_SAVANT, iRapid_Cost_Cooldown_SAVANT, iRapid_Cost_xCharges_SAVANT;

//add the new abilities
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	//Clarity of Mind ... Active Perk
	Templates.AddItem(Create_RapidPsionics('RapidPsionics_Standard',default.iRapid_Cost_Cooldown_STANDARD,default.iRapid_Cost_xCharges_STANDARD));
	Templates.AddItem(Create_RapidPsionics('RapidPsionics_Average',default.iRapid_Cost_Cooldown_AVERAGE,default.iRapid_Cost_xCharges_AVERAGE));
	Templates.AddItem(Create_RapidPsionics('RapidPsionics_Gifted',default.iRapid_Cost_Cooldown_GIFTED,default.iRapid_Cost_xCharges_GIFTED));
	Templates.AddItem(Create_RapidPsionics('RapidPsionics_Genius',default.iRapid_Cost_Cooldown_GENIUS,default.iRapid_Cost_xCharges_GENIUS));
	Templates.AddItem(Create_RapidPsionics('RapidPsionics_Savant',default.iRapid_Cost_Cooldown_SAVANT,default.iRapid_Cost_xCharges_SAVANT));

	//Psionic Grade ... Passive Perk Plus
	Templates.AddItem(Create_PsiComIntAbility('PexM_TestBoost_Standard','RapidPsionics_Standard', default.iPSIBOOST_STANDARD, "img:///UILibrary_PexM.Icons.UIPerk_psionicboost1"));
	Templates.AddItem(Create_PsiComIntAbility('PexM_TestBoost_Average','RapidPsionics_Average', default.iPSIBOOST_AVERAGE, "img:///UILibrary_PexM.Icons.UIPerk_psionicboost2"));
	Templates.AddItem(Create_PsiComIntAbility('PexM_TestBoost_Gifted','RapidPsionics_Gifted', default.iPSIBOOST_GIFTED, "img:///UILibrary_PexM.Icons.UIPerk_psionicboost3"));
	Templates.AddItem(Create_PsiComIntAbility('PexM_TestBoost_Genius','RapidPsionics_Genius', default.iPSIBOOST_GENIUS, "img:///UILibrary_PexM.Icons.UIPerk_psionicboost4"));
	Templates.AddItem(Create_PsiComIntAbility('PexM_TestBoost_Savant','RapidPsionics_Savant', default.iPSIBOOST_SAVANT, "img:///UILibrary_PexM.Icons.UIPerk_psionicboost5"));

	//Errors and Extras
   	Templates.AddItem(Create_PsiComIntAbility('PexM_Error','', 0, "img:///UILibrary_PexM.Icons.UIPerk_psionicboostE")); //lol this will be the rainbow.img
   	Templates.AddItem(Create_PsiComIntAbility('PexM_MELD','', 0, "img:///UILibrary_PexM.Icons.UIPerk_rapidpsionics"));	//used for localisation text for MELD items

	return Templates;
}

//create the abilities
static function X2AbilityTemplate Create_PsiComIntAbility(name TemplateName, name AbilityName, int Bonus, string ImagePath)
{
	local X2AbilityTemplate                 Template;	
	local X2AbilityTrigger					Trigger;
	local X2AbilityTarget_Self				TargetStyle;
	local X2Effect_PersistentStatChange		PersistentStatChangeEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	//Setup	
	Template.IconImage = ImagePath;
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;
	Template.Hostility = eHostility_Neutral;
	Template.bDisplayInUITacticalText = false;
	
	//Targetting & Triggers
	Template.AbilityToHitCalc = default.DeadEye;
	TargetStyle = new class'X2AbilityTarget_Self';
	Template.AbilityTargetStyle = TargetStyle;

	//Pure Passive
	Trigger = new class'X2AbilityTrigger_UnitPostBeginPlay';
	Template.AbilityTriggers.AddItem(Trigger);
	
	// Bonus to psi stat Effect
	PersistentStatChangeEffect = new class'X2Effect_PersistentStatChange';
	PersistentStatChangeEffect.BuildPersistentEffect(1, true, false, false);
	PersistentStatChangeEffect.SetDisplayInfo(ePerkBuff_Passive, Template.LocFriendlyName, Template.GetMyLongDescription(), Template.IconImage,default.bShowPassiveIcons, , Template.AbilitySourceName);
	PersistentStatChangeEffect.AddPersistentStatChange(eStat_PsiOffense, Bonus);
	Template.AddTargetEffect(PersistentStatChangeEffect);

	//Visualizations and Extras
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	//add the extra ability if we have one ... error and meld have no ability this stops them spamming the log
	if (AbilityName != '')
	{
		Template.AdditionalAbilities.AddItem(AbilityName);
	}

	Template.SetUIStatMarkup(class'XLocalizedData'.default.PsiOffenseLabel, eStat_PsiOffense, Bonus);

	return Template;	
}

//============================================================================
//	THE BIG ONE - 	stolen from XMB and carefully reconstructed !!
//============================================================================
static function X2AbilityTemplate Create_RapidPsionics(name TemplateName, int iRapid_Cost_Cooldown = 0, int iRapid_Cost_Charges = 0)
{
	local X2AbilityTemplate Template;
   	local X2AbilityCost_ActionPoints        ActionPointCost;
	local X2AbilityCooldown                 Cooldown;
	local X2AbilityCharges					Charges;
	local X2AbilityCost_Charges				ChargeCost;

	local X2Effect_AbilityCostRefund_PexM   ACREffect;
    local X2Effect_ManualOverride_PexM      MOEffect;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

    //setup
	Template.IconImage = "img:///UILibrary_PexM.Icons.UIPerk_rapidpsionics";
	Template.AbilitySourceName = 'eAbilitySource_Psionic';
	Template.eAbilityIconBehaviorHUD = eAbilityIconBehavior_AlwaysShow;
	Template.Hostility = eHostility_Neutral;
   	Template.ShotHUDPriority = 3000; // end of bar
	Template.bDisplayInUITacticalText = true;

    //Targeting & Triggers
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.PlayerInputTrigger);

	// Cannot be used while burning, etc.
	//Template.AddShooterEffectExclusions();

    //Costs
   	ActionPointCost = new class'X2AbilityCost_ActionPoints';
	ActionPointCost.iNumPoints = default.iRapid_Cost_AP;
    ActionPointCost.bFreeCost = default.bRapid_Cost_Free;
	ActionPointCost.bConsumeAllPoints = default.bRapid_Cost_EndTurn;
	Template.AbilityCosts.AddItem(ActionPointCost);

	if (iRapid_Cost_Cooldown > 0)
	{
		Cooldown = New class'X2AbilityCooldown';
		Cooldown.iNumTurns = iRapid_Cost_Cooldown;
		Template.AbilityCooldown = Cooldown;
	}

	if (iRapid_Cost_Charges > 0)
	{
		Charges = new class'X2AbilityCharges';
		Charges.InitialCharges = iRapid_Cost_Charges;
		Template.AbilityCharges = Charges;

		ChargeCost = new class'X2AbilityCost_Charges';
		ChargeCost.NumCharges = 1;
		Template.AbilityCosts.AddItem(ChargeCost);
	}

    //Visualisation
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;
	Template.BuildVisualizationFn = TypicalAbility_BuildVisualization;
   	Template.AbilityConfirmSound = "Manual_Override_Activate";
	Template.ActivationSpeech = 'ManualOverride';

	Template.bSkipFireAction = true;

	Template.bCrossClassEligible = false;

	// Create effect that will refund actions points
	if (default.bRapid_GivesNext_PsiAbility_FreeAction)
	{
		ACREffect = new class'X2Effect_AbilityCostRefund_PexM';
		ACREffect.MaxRefundsPerTurn = 1; //refund 1 action
		ACREffect.bFreeCost = true;
		ACREffect.BuildPersistentEffect(1, false, true, false, eGameRule_PlayerTurnEnd);
    	ACREffect.SetDisplayInfo(ePerkBuff_Bonus, Template.LocFriendlyName, Template.LocLongDescription, Template.IconImage, true, , Template.AbilitySourceName);
		Template.AddTargetEffect(ACREffect);
	}

	// Create effect that resets all psi ability cooldowns
	if (default.bRapid_Resets_PsiAbility_Cooldowns)
	{
    	MOEffect = new class'X2Effect_ManualOverride_PexM';
		Template.AddTargetEffect(MOEffect);
	}

	// drains will - mental immunity will not prevent!
	// may cause either berserk or shattered
	Template.PostActivationEvents.AddItem('ClarityActivated');

	return Template;
}