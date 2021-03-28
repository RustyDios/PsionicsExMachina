//*******************************************************************************************
//  FILE:    XComGameState_HeadquartersProjectPexM.uc
//  AUTHOR:  Joe Weinhoffer  --  05/19/2015 && RustyDios
//  PURPOSE: This object represents the instance data for an XCom HQ proving ground project
//           Will eventually be a component
//           
//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    07/08/20	19:00
//
//*******************************************************************************************
class XComGameState_HeadquartersProjectPexM extends XComGameState_HeadquartersProjectResearch;

//var bool bShadowProject;
//var bool bProvingGroundProject;
//var bool bForcePaused;
//var bool bIgnoreScienceScore;

//--------------------------------------------------------------------------------------
//THIS RETURNS THE CURRENT BUILD QUEUE PROJECT !!
//SEE class'X2StrategyElement_PexMFacilities'.static.GetPexMProjectFromFacility(); FOR THE TRAINING PROJECT
static function StateObjectReference GetCurrentPexMProject()
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	FacilityState = XComHQ.GetFacilityByName('PexMChamber');

	if ( (FacilityState != none) && (FacilityState.BuildQueue.Length > 0) )
	{
		return FacilityState.BuildQueue[0]; //.ObjectID;
	}
}

//re-creation of the UIFacility_PexMLab BuildQueue > UpdateBuildQueue
static function GetAllPexMProjects(out array<HQEvent> arrEvents)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local int i, ProjectHours;
	local StateObjectReference BuildItemRef;
	local XComGameState_HeadquartersProjectPexM PexMProject;
	local XComGameState_HeadquartersProjectPexMTraining PexMProjectTraining;
	local XComGameState_Tech PexMTech;
	local XComGameState_Unit Unit;
	local HQEvent BuildItem;
	local array<HQEvent> BuildItems;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	Facility = XComHQ.GetFacilityByName('PexMChamber');

	for (i = 0; i <= Facility.BuildQueue.Length; ++i)
	{
		BuildItemRef = Facility.BuildQueue[i];
		PexMProject = XComGameState_HeadquartersProjectPexM(`XCOMHISTORY.GetGameStateForObjectID(BuildItemRef.ObjectID));
		if (PexMProject != none)
		{
			// Calculate the hours based on which type of Headquarters Project this queue item is
			if (i == 0)
			{
				ProjectHours = PexMProject.GetCurrentNumHoursRemaining();
			}
			else
			{
				ProjectHours += PexMProject.GetProjectedNumHoursRemaining();
			}

			PexMTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(PexMProject.ProjectFocus.ObjectID));

			BuildItem.Hours = ProjectHours;
			BuildItem.Data = PexMTech.GetMyTemplate().DisplayName;
			BuildItem.ImagePath = class'UIUtilities_Image'.const.EventQueue_Psi;
			BuildItems.AddItem(BuildItem);
		}
	}

	//PexMProjectTraining = XComGameState_HeadquartersProjectPexMTraining(`XCOMHISTORY.GetGameStateForObjectID(BuildItemRef.ObjectID));
	PexMProjectTraining = class'X2StrategyElement_PexMFacilities'.static.GetPexMProjectFromFacility();
	if (PexMProjectTraining != none)
	{
		// Calculate the hours based on which type of Headquarters Project this queue item is
		if (i == 0)
		{
			ProjectHours = PexMProjectTraining.GetCurrentNumHoursRemaining();
		}
		else
		{
			ProjectHours += PexMProjectTraining.GetProjectedNumHoursRemaining();
		}

		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(PexMProjectTraining.ProjectFocus.ObjectID));

		BuildItem.Hours = ProjectHours;
		BuildItem.Data = Unit.GetFullName();
		BuildItem.ImagePath = class'UIUtilities_Image'.const.EventQueue_Psi;
		BuildItems.AddItem(BuildItem);
	}
	
	arrEvents = BuildItems;
}

//---------------------------------------------------------------------------------------
// Call when you start a new project
function SetProjectFocus(StateObjectReference FocusRef, optional XComGameState NewGameState, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Tech Tech;

	History = `XCOMHISTORY;

	ProjectFocus = FocusRef;
	AuxilaryReference = AuxRef;
	Tech = XComGameState_Tech(History.GetGameStateForObjectID(FocusRef.ObjectID));

	if (Tech.GetMyTemplate().bShadowProject)
	{
		bShadowProject = true;
	}
	if (Tech.GetMyTemplate().bProvingGround)
	{
		bProvingGroundProject = true;
	}
	bInstant = Tech.IsInstant();
	
	if (Tech.bBreakthrough) // If this tech is a breakthrough, duration is not modified by science score
	{
		bIgnoreScienceScore = true;
	}

	UpdateWorkPerHour();
	InitialProjectPoints = Tech.GetProjectPoints(WorkPerHour);
	ProjectPointsRemaining = InitialProjectPoints;
	StartDateTime = `STRATEGYRULES.GameTime;
	if(MakingProgress())
	{
		SetProjectedCompletionDateTime(StartDateTime);
	}
	else
	{
		// Set completion time to unreachable future
		CompletionDateTime.m_iYear = 9999;
	}
}

//---------------------------------------------------------------------------------------
function int CalculateWorkPerHour(optional XComGameState StartState = none, optional bool bAssumeActive = false)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int iTotalWork;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	//iTotalWork = XComHQ.ProvingGroundRate;	//<> HQ.ref
	iTotalWork = XcomHQ.PsiTrainingRate;

	// Can't make progress when paused or instant
	// The only time instant projects should be calculating work per hour is right when an Order that turns them instant activates
	// Keeping work per hour at zero prevents a project in the queue from assuming it is now active and getting stuck
	if (!FrontOfBuildQueue() && !bAssumeActive || bInstant)
	{
		return 0;
	}
	else
	{
		// Check for Higher Learning
		iTotalWork += Round(float(iTotalWork) * (float(XComHQ.EngineeringEffectivenessPercentIncrease) / 100.0));
	}

	return iTotalWork;
}

//---------------------------------------------------------------------------------------
// Add the tech to XComs list of completed research, and call any OnResearched methods for the tech
function OnProjectCompleted()
{
	local XComGameState_Tech TechState;
	local HeadquartersOrderInputContext OrderInput;
	local StateObjectReference TechRef;
	local X2ItemTemplate ItemTemplate;

	TechRef = ProjectFocus;

	OrderInput.OrderType = eHeadquartersOrderType_ResearchCompleted;
	OrderInput.AcquireObjectReference = ProjectFocus;

	class'XComGameStateContext_HeadquartersOrder_PexM'.static.IssueHeadquartersOrder_PexM(OrderInput);

	`GAME.GetGeoscape().Pause();

	if (bProvingGroundProject || !bShadowProject)
	{
		TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(TechRef.ObjectID));

		// If the Proving Ground project rewards an item, display all the project popups on the Geoscape
		if (TechState.ItemRewards.Length > 0)
		{
			TechState.DisplayTechCompletePopups();

			foreach TechState.ItemRewards(ItemTemplate)
			{
				`HQPRES.UIProvingGroundItemReceived(ItemTemplate, TechRef);
			}
		}
		else // Otherwise give the normal project complete popup
		{
			`HQPRES.UIProvingGroundProjectComplete(TechRef);
		}
	}
	else if(bInstant)
	{
		TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(TechRef.ObjectID));
		TechState.DisplayTechCompletePopups();

		`HQPRES.ResearchReportPopup(TechRef);
	}
	else
	{
		`HQPRES.UIResearchComplete(TechRef);
	}
}

//---------------------------------------------------------------------------------------
// Is it currently at the front of the build queue
function bool FrontOfBuildQueue()
{
	local XComGameState_FacilityXCom Facility;

	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(AuxilaryReference.ObjectID));

	if ((Facility != none) && (Facility.BuildQueue.Length > 0))
	{
		if (Facility.BuildQueue[0].ObjectID == self.ObjectID)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}