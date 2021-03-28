//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    07/08/20	19:30
//
//	This controls the project stuff
//
//*******************************************************************************************
class XComGameStateContext_HeadquartersOrder_PexM extends XComGameStateContext_HeadquartersOrder;

private function CompleteResearch(XComGameState AddToGameState, StateObjectReference TechReference)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectPexM ResearchProject;
	local XComGameState_Tech TechState;
	local X2TechTemplate TechTemplate;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.TechsResearched.AddItem(TechReference);
		for(idx = 0; idx < XComHQ.Projects.Length; idx++)
		{
			ResearchProject = XComGameState_HeadquartersProjectPexM(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
			
			if (ResearchProject != None && ResearchProject.ProjectFocus == TechReference)
			{
				XComHQ.Projects.RemoveItem(ResearchProject.GetReference());
				AddToGameState.RemoveStateObject(ResearchProject.GetReference().ObjectID);

				if (ResearchProject.bProvingGroundProject || !ResearchProject.bShadowProject)
				{
					//FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(ResearchProject.AuxilaryReference.ObjectID));
                    FacilityState = XComHQ.GetFacilityByName('PexMChamber');
					if (FacilityState != none)
					{
						FacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
						FacilityState.BuildQueue.RemoveItem(ResearchProject.GetReference());
					}
				}
				else if (ResearchProject.bShadowProject)
				{
					XComHQ.EmptyShadowChamber(AddToGameState);
				}

				break;
			}
		}
	}

	TechState = XComGameState_Tech(AddToGameState.ModifyStateObject(class'XComGameState_Tech', TechReference.ObjectID));
	TechState.TimesResearched++;
	TechState.TimeReductionScalar = 0;
	TechState.CompletionTime = `GAME.GetGeoscape().m_kDateTime;

	TechState.OnResearchCompleted(AddToGameState);
	
	TechTemplate = TechState.GetMyTemplate(); // Get the template for the completed tech
	if (!TechState.IsInstant() && !TechTemplate.bShadowProject && !TechTemplate.bProvingGround)
	{
		XComHQ.CheckForInstantTechs(AddToGameState);
		
		// Do not allow two breakthrough techs back-to-back, jump straight to inspired check
		if (TechTemplate.bBreakthrough || !XComHQ.CheckForBreakthroughTechs(AddToGameState))
		{
			// If there is no breakthrough activated, check to activate inspired tech
			XComHQ.CheckForInspiredTechs(AddToGameState);
		}
	}
	
	// Do not clear Breakthrough and Inspired references until after checking for instant
	// to avoid game state conflicts when potentially choosing a new breakthrough tech if the tech tree is exhausted
	if (TechState.bBreakthrough && XComHQ.CurrentBreakthroughTech.ObjectID == TechState.ObjectID)
	{
		XComHQ.CurrentBreakthroughTech.ObjectID = 0;
	}
	else if (TechState.bInspired && XComHQ.CurrentInspiredTech.ObjectID == TechState.ObjectID)
	{
		XComHQ.CurrentInspiredTech.ObjectID = 0;
	}
	
	if (TechState.GetMyTemplate().bProvingGround)
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_ProvingGroundProjectsCompleted');
	else
		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(AddToGameState, 'ResAct_TechsCompleted');

	`XEVENTMGR.TriggerEvent('ResearchCompleted', TechState, ResearchProject, AddToGameState);
}

static function CancelProvingGroundProject(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_FacilityXCom FacilityState, NewFacilityState;
	local XComGameState_HeadquartersProjectPexM ProjectState;
	local XComGameState_HeadquartersProjectPexMTraining ProjectStateTraining;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	ProjectState = XComGameState_HeadquartersProjectPexM(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		//FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));
        FacilityState = XComHQ.GetFacilityByName('PexMChamber');
		if (FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
		}

		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.RefundStrategyCost(AddToGameState, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, ProjectState.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}
	}
	
	ProjectStateTraining = XComGameState_HeadquartersProjectPexMTraining(History.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectStateTraining != none)
	{
		//TechState = XComGameState_Tech(History.GetGameStateForObjectID(ProjectStateTraining.ProjectFocus.ObjectID));
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

		//FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(ProjectState.AuxilaryReference.ObjectID));
        FacilityState = XComHQ.GetFacilityByName('PexMChamber');
		if (FacilityState != none)
		{
			NewFacilityState = XComGameState_FacilityXCom(AddToGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
			NewFacilityState.BuildQueue.RemoveItem(ProjectRef);
		}

		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			//XComHQ.RefundStrategyCost(AddToGameState, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, ProjectStateTraining.SavedDiscountPercent);
			XComHQ.Projects.RemoveItem(ProjectStateTraining.GetReference());
			AddToGameState.RemoveStateObject(ProjectStateTraining.ObjectID);
		}
	}

}

////////////////////////////////////////////

static function CompletePsiTraining(XComGameState AddToGameState, StateObjectReference ProjectRef)
{
	local XComGameState_HeadquartersProjectPexMTraining ProjectState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameStateHistory History;
    	local X2AbilityTemplate AbilityTemplate;
	    local SoldierClassAbilityType AbilityType;
	    local ClassAgnosticAbility Ability;


	History = `XCOMHISTORY;
	ProjectState = XComGameState_HeadquartersProjectPexMTraining(`XCOMHISTORY.GetGameStateForObjectID(ProjectRef.ObjectID));

	if (ProjectState != none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			XComHQ = XComGameState_HeadquartersXCom(AddToGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			XComHQ.Projects.RemoveItem(ProjectState.GetReference());
			AddToGameState.RemoveStateObject(ProjectState.ObjectID);
		}

		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ProjectState.ProjectFocus.ObjectID));
		if (Unit != none)
		{
			// Set the soldier status back to active, and rank them up as a squaddie Psi Operative
			Unit = XComGameState_Unit(AddToGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));

			// Rank up the solder. Will also apply class if they were a Rookie.
			//UnitState.RankUpSoldier(AddToGameState, 'PsiOperative');
			
			// Teach the soldier the ability which was associated with the project // //Decide what and HOW this gets picked, see also PexMTraining, 130ish
			//UnitState.BuySoldierProgressionAbility(AddToGameState, ProjectState.iAbilityRank, ProjectState.iAbilityBranch);
            
           	//Decide what and HOW this gets picked, see also HQorder_PexM line 170ish AND Slots line 286 and Training line 137 ... x2dlc GetPsiAbilityFromUnitComInt(UnitState)
            AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(class'X2DownloadableContentInfo_PsionicsExMachina'.static.GetPsiAbilityFromUnitComInt(Unit));
            AbilityType.AbilityName = AbilityTemplate.DataName;

            Ability.AbilityType = AbilityType;
            Ability.bUnlocked = true;
            Ability.iRank = 0;
            Unit.bSeenAWCAbilityPopup = true;
            Unit.AWCAbilities.AddItem(Ability);

	        if (AbilityTemplate != none && AbilityTemplate.SoldierAbilityPurchasedFn != none)
			{
		        AbilityTemplate.SoldierAbilityPurchasedFn(AddToGameState, Unit);
			}
			
            `LOG("PEXM | Headquarters Order | CompletePsiTraining() :: Adding " $ AbilityType.AbilityName $ " to " $ Unit.GetName(eNameType_FullNick),class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging, 'PsionicsExMachina');			

			Unit.SetStatus(eStatus_Active);

			// Remove the soldier from the staff slot
			StaffSlotState = Unit.GetStaffSlot();
			if (StaffSlotState != none)
			{
				StaffSlotState.EmptySlot(AddToGameState);
			}
			
			`XEVENTMGR.TriggerEvent('PexMTrainingCompleted', Unit, AbilityTemplate, AddToGameState);
		}		
	}
}

/////////////////////////////////////////////

static function IssueHeadquartersOrder_PexM(const out HeadquartersOrderInputContext UseInputContext)
{
	local XComGameStateContext_HeadquartersOrder NewOrderContext;

	NewOrderContext = XComGameStateContext_HeadquartersOrder(class'XComGameStateContext_HeadquartersOrder_PexM'.static.CreateXComGameStateContext());
	NewOrderContext.InputContext = UseInputContext;

	`GAMERULES.SubmitGameStateContext(NewOrderContext);
}
