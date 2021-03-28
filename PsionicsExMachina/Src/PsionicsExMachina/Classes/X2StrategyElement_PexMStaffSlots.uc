//---------------------------------------------------------------------------------------
//  FILE:   X2StrategyElement_PexMStaffSlots.uc                                    
//
//	File created by RustyDios	
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    07/08/20	19:00
//
//  ADDS pexm psi facility staffslots !!
//
//---------------------------------------------------------------------------------------
class X2StrategyElement_PexMStaffSlots extends X2StrategyElement_DefaultStaffSlots;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> StaffSlots;

    StaffSlots.AddItem(CreatePexMChamberScientistStaffSlotTemplate());
	StaffSlots.AddItem(CreatePexMChamberEngineerStaffSlotTemplate());

	StaffSlots.AddItem(CreatePexMChamberSoldierStaffSlotTemplate());
	return StaffSlots;
}

//#############################################################################################
//----------------   SCIENTIST 'from PsiLab' --------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreatePexMChamberScientistStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('PexMChamberStaffSlot_Sci');
	Template.bScientistSlot = true;
	Template.FillFn = FillPexMChamberSlot;
	Template.EmptyFn = EmptyPexmChamberSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayPexMChamberToDoWarning;
	Template.GetAvengerBonusAmountFn = GetPexMChamberAvengerBonus;
	Template.GetBonusDisplayStringFn = GetPexMChamberBonusDisplayString;
	Template.MatineeSlotName = "Scientist";

	return Template;
}

//#############################################################################################
//----------------   ENGINEER 'from PG'  ------------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreatePexMChamberEngineerStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('PexMChamberStaffSlot_Eng');
	Template.bEngineerSlot = true;
	Template.FillFn = FillPexMChamberSlot;
	Template.EmptyFn = EmptyPexMChamberSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayPexMChamberToDoWarning;
	Template.GetAvengerBonusAmountFn = GetPexMChamberAvengerBonus;
	Template.GetBonusDisplayStringFn = GetPexMChamberBonusDisplayString;
	Template.MatineeSlotName = "Engineer";

	return Template;
}

//#############################################################################################
//	BOTH ENGI'S AND SCI'S BEHAVE THE SAME
//	PROGRESS ADDED TO 'PSI TRAINING RATE' WHICH IS USED AS BUILD TIME FOR PEX M PROJECTS
//#############################################################################################

static function FillPexMChamberSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	NewXComHQ.PsiTrainingRate += NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function EmptyPexMChamberSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);
	NewXComHQ = GetNewXComHQState(NewGameState);

	NewXComHQ.PsiTrainingRate -= NewSlotState.GetMyTemplate().GetContributionFromSkillFn(NewUnitState);
}

static function bool ShouldDisplayPexMChamberToDoWarning(StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot SlotState;
	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));

	if (SlotState.GetFacility().HasFilledSoldierSlot() || SlotState.GetFacility().BuildQueue.Length > 0)
	{
		return true;
	}
	
	return false;
}

static function int GetPexMChamberAvengerBonus(XComGameState_Unit Unit, optional bool bPreview)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local float PercentIncrease;
	local int NewWorkPerHour;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// Need to return the percent increase in overall project speed provided by this unit
	NewWorkPerHour = GetContributionDefault(Unit) + XComHQ.XComHeadquarters_DefaultProvingGroundWorkPerHour;
	PercentIncrease = (GetContributionDefault(Unit) * 100.0) / NewWorkPerHour;

	return Round(PercentIncrease);
}

static function string GetPexMChamberBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		Contribution = string(GetPexMChamberAvengerBonus(SlotState.GetAssignedStaff(), bPreview));
	}

	return GetBonusDisplayString(SlotState, "%AVENGERBONUS", Contribution);
}

//#############################################################################################
//----------------   SOLDIER 'from PsiLab' ----------------------------------------------------
//#############################################################################################

static function X2DataTemplate CreatePexMChamberSoldierStaffSlotTemplate()
{
	local X2StaffSlotTemplate Template;

	Template = CreateStaffSlotTemplate('PexMChamberStaffSlot_Sol');
	Template.bSoldierSlot = true;
	Template.bRequireConfirmToEmpty = true;
	Template.bPreventFilledPopup = true;
	Template.UIStaffSlotClass = class'UIFacility_PexMLabSlot';
	Template.AssociatedProjectClass = class'XComGameState_HeadquartersProjectPexMTraining';
	Template.FillFn = FillPexMChamberSoldierSlot;
	Template.EmptyFn = EmptyPexMChamberSoldierSlot;
	Template.EmptyStopProjectFn = EmptyStopProjectPexMChamberSoldierSlot;
	Template.ShouldDisplayToDoWarningFn = ShouldDisplayPexMChamberSoldierToDoWarning;
	Template.GetSkillDisplayStringFn = GetPexMChamberSoldierSkillDisplayString;
	Template.GetBonusDisplayStringFn = GetPexMChamberSoldierBonusDisplayString;
	Template.IsUnitValidForSlotFn = IsUnitValidForPexMChamberSoldierSlot;

	Template.ExcludeClasses = class'X2DownloadableContentInfo_PsionicsExMachina'.default.DisallowedClasses;

	Template.MatineeSlotName = "Soldier";

	return Template;
}

static function FillPexMChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef, StaffUnitInfo UnitInfo, optional bool bTemporary = false)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_HeadquartersProjectPexMTraining ProjectState;
	local StateObjectReference EmptyRef;
	local int SquadIndex;

	FillSlot(NewGameState, SlotRef, UnitInfo, NewSlotState, NewUnitState);

	if (NewUnitState.GetRank() >= 0) // If the Unit is a rookie or higher, start the project to test them for Psionics
	{
		//NewUnitState.SetStatus(eStatus_PsiTesting);
		NewUnitState.SetStatus(eStatus_Training);

		NewXComHQ = GetNewXComHQState(NewGameState);

		ProjectState = XComGameState_HeadquartersProjectPexMTraining(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectPexMTraining'));
		ProjectState.SetProjectFocus(UnitInfo.UnitRef, NewGameState, NewSlotState.Facility);

		NewXComHQ.Projects.AddItem(ProjectState.GetReference());

		// Remove their gear
		NewUnitState.MakeItemsAvailable(NewGameState, false);

		// If the unit undergoing training is in the squad, remove them
		SquadIndex = NewXComHQ.Squad.Find('ObjectID', UnitInfo.UnitRef.ObjectID);
		if (SquadIndex != INDEX_NONE)
		{
			// Remove them from the squad
			NewXComHQ.Squad[SquadIndex] = EmptyRef;
		}
	}
	else // The unit is either starting or resuming an ability training project, so set their status appropriately
	{
		//NewUnitState.SetStatus(eStatus_PsiTesting);
		NewUnitState.SetStatus(eStatus_Training);
	}
}

static function EmptyPexMChamberSoldierSlot(XComGameState NewGameState, StateObjectReference SlotRef)
{
	local XComGameState_StaffSlot NewSlotState;
	local XComGameState_Unit NewUnitState;

	EmptySlot(NewGameState, SlotRef, NewSlotState, NewUnitState);

	NewUnitState.SetStatus(eStatus_Active);
}

static function EmptyStopProjectPexMChamberSoldierSlot(StateObjectReference SlotRef)
{
	local XComGameState NewGameState;
	local HeadquartersOrderInputContext OrderInput;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersProjectPexMTraining PsiTrainingProject;

	SlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(SlotRef.ObjectID));
	Unit = SlotState.GetAssignedStaff();

	//PsiTrainingProject = XComHQ.GetPsiTrainingProject(SlotState.GetAssignedStaffRef());
	PsiTrainingProject = class'X2StrategyElement_PexMFacilities'.static.GetPexMProjectFromFacility();
	if (PsiTrainingProject != none)
	{
		// If the unit is undergoing initial Psi Op training, cancel the project
		if (Unit.GetStatus() == eStatus_Training) // eStatus_PsiTesting // (IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
		{
			OrderInput.OrderType = eHeadquartersOrderType_CancelPsiTraining;
			OrderInput.AcquireObjectReference = PsiTrainingProject.GetReference();

			class'XComGameStateContext_HeadquartersOrder_PexM'.static.IssueHeadquartersOrder_PexM(OrderInput);
		}
		else if (Unit.GetStatus() != eStatus_Training) // eStatus_PsiTesting // (IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause Psi Ability Training");

			PsiTrainingProject = XComGameState_HeadquartersProjectPexMTraining(NewGameState.ModifyStateObject(PsiTrainingProject.Class, PsiTrainingProject.ObjectID));
			PsiTrainingProject.bForcePaused = true;

			SlotState.EmptySlot(NewGameState);

			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
	}
}

static function bool ShouldDisplayPexMChamberSoldierToDoWarning(StateObjectReference SlotRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_Unit Unit;
	local StaffUnitInfo UnitInfo;
	local int i;

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(SlotRef.ObjectID));

	for (i = 0; i < XComHQ.Crew.Length; i++)
	{
		UnitInfo.UnitRef = XComHQ.Crew[i];
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Crew[i].ObjectID));

		//<> TODO change should show requirements ?? currently anyone NOT a PsiOperative
		if (Unit.GetSoldierClassTemplateName() != 'PsiOperative' && IsUnitValidForPsiChamberSoldierSlot(SlotState, UnitInfo))
		{
			return true;
		}
	}

	return false;
}

static function bool IsUnitValidForPexMChamberSoldierSlot(XComGameState_StaffSlot SlotState, StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit; 
	local SCATProgression ProgressAbility;
	local name AbilityName;
	local array<name> CombatIntPsiArray;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));

	if (Unit.CanBeStaffed()	&& Unit.IsSoldier()	&& Unit.IsActive()	&& SlotState.GetMyTemplate().ExcludeClasses.Find(Unit.GetSoldierClassTemplateName()) == INDEX_NONE)
	{
           	//Decide what and HOW this gets picked, see also HQorder_PexM line 170ish AND Slots line 286 and Training line 137
			//.. x2dlc GetPsiAbilityFromUnitComInt(UnitState)
			// Everyone who has not yet ranked up can be trained as Psi Ops, if they haven't already got the ability for thier combat int :)

		//build the psi combat array ... this stops from 'doubling up' if combat intelligence is increased by covert op
		CombatIntPsiArray.AddItem('PexM_TestBoost_Savant');
		CombatIntPsiArray.AddItem('PexM_TestBoost_Genius');
		CombatIntPsiArray.AddItem('PexM_TestBoost_Gifted');
		CombatIntPsiArray.AddItem('PexM_TestBoost_Average');
		CombatIntPsiArray.AddItem('PexM_TestBoost_Standard');
		CombatIntPsiArray.AddItem('PexM_TestBoost_Error');

		if (Unit.GetRank() >= 0 && !Unit.CanRankUpSoldier() && //(!Unit.HasSoldierAbility(class'X2DownloadableContentInfo_PsionicsExMachina'.static.GetPsiAbilityFromUnitComInt(Unit))) 
			!Unit.HasAnyOfTheAbilitiesFromAnySource(CombatIntPsiArray)	)
		{
			return true;
		}
		else if (Unit.GetSoldierClassTemplateName() == 'PsiOperative') // But Psi Ops can only train until they learn all abilities
		{
			foreach Unit.PsiAbilities(ProgressAbility) //array<SoldierClassAbilityType>GetEarnedSoldierAbilities // HasSoldierAbility(abilityname, true)
			{
				AbilityName = Unit.GetAbilityName(ProgressAbility.iRank, ProgressAbility.iBranch);
				if (AbilityName != '' && !Unit.HasSoldierAbility(AbilityName))
				{
					return true; // If we find an ability that the soldier hasn't learned yet, they are valid
				}
			}
		}
	}

	return false;
}

/*		FROM XCOM_GAMESTATE_UNIT
// Psi Abilities - only for Psi Operatives
var() array<SCATProgression>		PsiAbilities;

function RollForPsiAbilities()
{
	local SCATProgression PsiAbility;
	local array<SCATProgression> PsiAbilityDeck;
	local int NumRanks, iRank, iBranch, idx;

	NumRanks = m_SoldierClassTemplate.GetMaxConfiguredRank();
		
	for (iRank = 0; iRank < NumRanks; iRank++)
	{
		for (iBranch = 0; iBranch < 2; iBranch++)
		{
			PsiAbility.iRank = iRank;
			PsiAbility.iBranch = iBranch;
			PsiAbilityDeck.AddItem(PsiAbility);
		}
	}

	while (PsiAbilityDeck.Length > 0)
	{
		// Choose an ability randomly from the deck
		idx = `SYNC_RAND(PsiAbilityDeck.Length);
		PsiAbility = PsiAbilityDeck[idx];
		PsiAbilities.AddItem(PsiAbility);
		PsiAbilityDeck.Remove(idx, 1);
	}
}
 */

static function string GetPexMChamberSoldierBonusDisplayString(XComGameState_StaffSlot SlotState, optional bool bPreview)
{
	local XComGameState_HeadquartersProjectPexMTraining TrainProject;
	local XComGameState_Unit Unit;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;
	local string Contribution;

	if (SlotState.IsSlotFilled())
	{
		//TrainProject = XComHQ.GetPsiTrainingProject(SlotState.GetAssignedStaffRef());
		TrainProject = class'X2StrategyElement_PexMFacilities'.static.GetPexMProjectFromFacility();
		Unit = SlotState.GetAssignedStaff();

		//<> TODO CHANGE THIS ??
		if (Unit.GetSoldierClassTemplateName() == 'PsiOperative' && TrainProject != none)
		{
			AbilityName = Unit.GetAbilityName(TrainProject.iAbilityRank, TrainProject.iAbilityBranch);
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
			Contribution = Caps(AbilityTemplate.LocFriendlyName);
		}
		else
		{
			Contribution = SlotState.GetMyTemplate().BonusText;
		}
	}

	return GetBonusDisplayString(SlotState, "%SKILL", Contribution);
}

static function string GetPexMChamberSoldierSkillDisplayString(XComGameState_StaffSlot SlotState)
{
	return "";
}
