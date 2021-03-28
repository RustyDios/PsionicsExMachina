//---------------------------------------------------------------------------------------
//  FILE:   X2StrategyElement_PexMFacilities.uc                                    
//
//	File created by RustyDios	
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    25/10/20	04:30
//
//  ADDS pexm psi facility !!
//
//---------------------------------------------------------------------------------------
class X2StrategyElement_PexMFacilities extends X2StrategyElement_DefaultFacilities config(PsionicsExMachina);

var config array<name> strPexMChamber_COST_TYPE; //175 supplies, 10 edust
var config array<int>  iPexMChamber_COST_AMOUNT;

var config int PexMChamberDAYS, PexMChamberPOWER, PexMChamberUPKEEP; //21 , -5, 55

var config bool bCanTrainPsiOffense;	//true

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Facilities;

	Facilities.AddItem(CreatePexMChamberTemplate());

	return Facilities;
}

//---------------------------------------------------------------------------------------
// PEXM CHAMBER    
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePexMChamberTemplate()
{
	local X2FacilityTemplate Template;
	local ArtifactCost Resources;
	local int i;
	local StaffSlotDefinition StaffSlotDef0, StaffSlotDef1, StaffSlotDef2, StaffSlotDef3, StaffSlotDef4;

	//setup
	`CREATE_X2TEMPLATE(class'X2FacilityTemplate', Template, 'PexMChamber');
	Template.bIsCoreFacility = false;				//is it one of the big rooms
	Template.bIsUniqueFacility = true;				//can only one be built at a time
	Template.bIsIndestructible = false;				//can it be destroyed
	Template.MapName = "AVG_PexMLab_A";
	Template.AnimMapName = "AVG_PexMLab_A_Anim";
	//Template.FlyInMapName = "";					// ??
	Template.FlyInRemoteEvent = '';					//'CIN_Flyin_Infirmary'; //??

	Template.strImage =  "img:///UILibrary_PexM.FacilityIcons.ChooseFacility_PexMLab";// "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab";

	//delegates
	Template.SelectFacilityFn = SelectFacility;
	Template.OnFacilityBuiltFn = OnPexMChamberBuilt;
	Template.CanFacilityBeRemovedFn = CanPexMChamberBeRemoved;
	Template.OnFacilityRemovedFn = OnPexMChamberRemoved;
	Template.IsFacilityProjectActiveFn = IsPexMChamberProjectActive;
	Template.GetQueueMessageFn = GetPexMChamberQueueMessage;

	//upgrades
	Template.Upgrades.AddItem('PexMChamber_SecondCell');		//back area, more staff, faster projects

	if (default.bCanTrainPsiOffense)
	{
		Template.Upgrades.AddItem('PexMChamber_TrainingCell');	//side area, training for clarity, config optional
	}

	//appearances
	Template.bHideStaffSlotOpenPopup = true;					//does it instantly want to staff

	Template.UIFacilityClass = class'UIFacility_PexMLab';		// UIFacility_PsiLab && UIFacility_ProvingGround

	Template.FacilityEnteredAkEvent = "Play_AvengerPsiChamber_Unoccupied";
	Template.FacilityCompleteNarrative = "X2NarrativeMoments.Strategy.Avenger_PsiLab_Complete";
	Template.FacilityUpgradedNarrative = "X2NarrativeMoments.Strategy.Avenger_PsiLab_Upgraded";
	Template.ConstructionStartedNarrative = "X2NarrativeMoments.Strategy.Avenger_Tutorial_Psy_Lab_Construction";

	//crew
	Template.BaseMinFillerCrew = 1;
    	Template.FillerSlots.AddItem('Engineer');
        Template.FillerSlots.AddItem('Scientist');
		Template.FillerSlots.AddItem('Soldier');
        Template.FillerSlots.AddItem('Engineer');
        Template.FillerSlots.AddItem('Scientist');
		Template.FillerSlots.AddItem('Soldier');
		
    	Template.FillerSlots.AddItem('Engineer');
        Template.FillerSlots.AddItem('Scientist');
		Template.FillerSlots.AddItem('Soldier');
        Template.FillerSlots.AddItem('Engineer');
        Template.FillerSlots.AddItem('Scientist');
		Template.FillerSlots.AddItem('Soldier');
	Template.MaxFillerCrew = 12;

	Template.MatineeSlotsForUpgrades.AddItem('SoldierSlot2');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot3');
	Template.MatineeSlotsForUpgrades.AddItem('EngineerSlot4');
	
	//staff slots
	StaffSlotDef1.StaffSlotTemplateName = 'PexMChamberStaffSlot_Sci';
	Template.StaffSlotDefs.AddItem(StaffSlotDef1);

	StaffSlotDef2.StaffSlotTemplateName = 'PexMChamberStaffSlot_Sci';
	StaffSlotDef2.bStartsLocked = true;
	Template.StaffSlotDefs.AddItem(StaffSlotDef2);

	if (default.bCanTrainPsiOffense)
	{
		StaffSlotDef0.StaffSlotTemplateName = 'PexMChamberStaffSlot_Sol';
		StaffSlotDef0.bStartsLocked = true;
		Template.StaffSlotDefs.AddItem(StaffSlotDef0);
	}

	StaffSlotDef3.StaffSlotTemplateName = 'PexMChamberStaffSlot_Eng';
	Template.StaffSlotDefs.AddItem(StaffSlotDef3);

	StaffSlotDef4.StaffSlotTemplateName = 'PexMChamberStaffSlot_Eng';
	StaffSlotDef4.bStartsLocked = true;
	Template.StaffSlotDefs.AddItem(StaffSlotDef4);

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Psionics');

	// Stats
	Template.PointsToComplete = GetFacilityBuildDays(default.PexMChamberDAYS);
	Template.iPower = default.PexMChamberPOWER;
	Template.UpkeepCost = default.PexMChamberUPKEEP;

	// Costs	Code forloop taken from Iridar, looks for arrays in the config file and cycles through them adding the costs
	// default costs are 1 Elerium Core
	for (i = 0; i < default.strPexMChamber_COST_TYPE.Length; i++)
	{
		if (default.iPexMChamber_COST_AMOUNT[i] > 0)
		{
			Resources.ItemTemplateName = default.strPexMChamber_COST_TYPE[i];
			Resources.Quantity = default.iPexMChamber_COST_AMOUNT[i];
			Template.Cost.ResourceCosts.AddItem(Resources);
		}
	}

	return Template;
}

static function OnPexMChamberBuilt(StateObjectReference FacilityRef)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local UIAvengerHUD AvengerHud;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On PexMChamber Built");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	//Then add the avenger shortcut ? ... should this be handled by the UISL ?
	AvengerHud = `HQPRES.m_kAvengerHUD; //Movie.Stack.GetScreen(class'UIAvengerHUD');
	class'UISL_AvengerHUD_Shortcuts_PexM'.static.AddSubMenuItems(AvengerHud);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function bool CanPexMChamberBeRemoved(StateObjectReference FacilityRef)
{
	return !IsPexMChamberProjectActive(FacilityRef);
}

static function OnPexMChamberRemoved(StateObjectReference FacilityRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local StateObjectReference BuildItemRef;
	local int idx;

	local UIAvengerHUD AvengerHud;

    //Empty the soldier staff slots
	EmptyFacilityProjectStaffSlots(FacilityRef);

	//Then cancel all of the active proving ground projects
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cancel All PexM Projects");
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	if (FacilityState != none)
	{
		for (idx = 0; idx < FacilityState.BuildQueue.Length; idx++)
		{
			BuildItemRef = FacilityState.BuildQueue[idx];
			class'XComGameStateContext_HeadquartersOrder_PexM'.static.CancelProvingGroundProject(NewGameState, BuildItemRef);
		}
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState); // we need two separate NewGameStates because facility and XComHQ are changed in both

	// Then actually remove the facility
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("On PexM Chamber Removed");
	RemoveFacility(NewGameState, FacilityRef, NewXComHQ);

	//Then remove the avenger shortcut ? ... should this be handled by the UISL ?
	AvengerHud = `HQPRES.m_kAvengerHUD; //Movie.Stack.GetScreen(class'UIAvengerHUD');
	class'UISL_AvengerHUD_Shortcuts_PexM'.static.ResetSubMenuItems(AvengerHud);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function bool IsPexMChamberProjectActive(StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersProjectPexMTraining PsiProject;			
	local int i;
    local bool bStaffInSlot;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));

    //do we have someone in the training slot ...
	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if (StaffSlot.IsSlotFilled())
		{
			PsiProject = GetPexMProjectFromFacility();		
			if (PsiProject != none)
			{
				bStaffInSlot =  true;
			}
		}
	}

    // ... are there things in the build queue
    if (bStaffInSlot || FacilityState.BuildQueue.Length > 0)
    {
        return true;	//we have projects
    }

	return false;		//no projects
}

//THIS IS THE ANTHILL VIEW MESSAGE
static function string GetPexMChamberQueueMessage(StateObjectReference FacilityRef)
{
    local XComGameStateHistory								History;
	local XComGameState_Tech								TechState;
	local XComGameState_FacilityXCom						FacilityState;
	local XComGameState_StaffSlot							StaffSlot;
	local XComGameState_HeadquartersProjectPexMTraining		PsiProject;				
   	local XComGameState_HeadquartersProjectPexM				PexMProject;		
   	local StateObjectReference								BuildItemRef;

	local string strStatus1, strStatus2, Message;
	local int i;

	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

    //show info for psi soldier
	for (i = 0; i < FacilityState.StaffSlots.Length; i++)
	{
		StaffSlot = FacilityState.GetStaffSlot(i);
		if ( StaffSlot.GetMyTemplate().bSoldierSlot && StaffSlot.IsSlotFilled() )
		{
			//gets the training project
			PsiProject = GetPexMProjectFromFacility();		
			if (PsiProject != none)
			{
				if (PsiProject.GetCurrentNumHoursRemaining() < 0)
					Message = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
				else
					Message = class'UIUtilities_Text'.static.GetTimeRemainingString(PsiProject.GetCurrentNumHoursRemaining());

				strStatus1 = StaffSlot.GetBonusDisplayString() $ ":" @ Message;
				break;
			}
		}
	}
	
	//Show info about the first item in the build queue.
	if (FacilityState.BuildQueue.length == 0)
	{
		strStatus2 = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_PexMLab'.default.m_strEmptyQueue, eUIState_Bad);
	}
	else
	{
		BuildItemRef = FacilityState.BuildQueue[0];
		PexMProject = XComGameState_HeadquartersProjectPexM(History.GetGameStateForObjectID(BuildItemRef.ObjectID));	
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(PexMProject.ProjectFocus.ObjectID));

		if (PexMProject.GetCurrentNumHoursRemaining() < 0)
			Message = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_Powercore'.default.m_strStalledResearch, eUIState_Warning);
		else
			Message = class'UIUtilities_Text'.static.GetTimeRemainingString(PexMProject.GetCurrentNumHoursRemaining());

		strStatus2 = TechState.GetMyTemplate().DisplayName $ ":" @ Message;
	}

	return strStatus1 @" \n" @strStatus2;
}

//Common function to get the necessary training project from the facility
//see also xcgs_hq_projectpexm for the build queue projects
static function XComGameState_HeadquartersProjectPexMTraining GetPexMProjectFromFacility()
{
	local XComGameState_HeadquartersXCom						XComHQ;
	local XComGameState_HeadquartersProjectPexMTraining			PsiProject;
	local XComGameStateHistory									History;
	local int idx;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	History = `XCOMHISTORY;

	for (idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		PsiProject = XComGameState_HeadquartersProjectPexMTraining(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
		if (PsiProject != none)
		{
			return PsiProject;
		}
	}
	return none;
}
