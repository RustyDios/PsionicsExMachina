//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    09/08/20	11:30
//
//	CONTAINS EVERYTHING NEEDED TO CHOOSE A NEW PEXM PROJECT TO BUILD
//
//*******************************************************************************************
class UIChoosePexMProject extends UISimpleCommodityScreen dependson (UIButton) config (PsionicsExMachina); //UIChooseProject;

var StateObjectReference CurrentProjectRef_PexM;

var localized String m_strPriority;
var localized String m_strPaused;
var localized String m_strResume;

var bool bPlayedConfirmationVO;

var config array<name> ExtraTechTemplatesNames;

//THESE ARE FROM UISIMPLECOMMODITY, FOR REF
//var UIPanel ListContainer; 
//var UIList List;
//var UIPanel ListBG;

simulated function BuildScreen()
{
	super.BuildScreen();

	ListBG.bHitTestDisabled = false;
	ListBG.bProcessesMouseEvents = true;
	ListBG.EnableMouseHit();
	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	List.bHitTestDisabled = false;
	List.bProcessesMouseEvents = true;
	List.EnableMouseHit();

	ListContainer.bHitTestDisabled = false;
	ListContainer.bProcessesMouseEvents = true;
	ListContainer.EnableMouseHit();
	ListContainer.ProcessMouseEvents(List.OnChildMouseEvent);

	`LOG("ChoosePexM Build Screen true",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnPurchaseClicked(UIList kList, int itemIndex)
{
	if (itemIndex != iSelectedItem)
	{
		iSelectedItem = itemIndex;
	}

	if (CanAffordItem(iSelectedItem))
	{
		PlaySFX("BuildItem");

		`LOG("ChoosePexM OnPurchaseClicked Can Afford",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

		OnTechTableOption(iSelectedItem);

		GetItems();
		PopulateData();
	}
	else
	{
		`LOG("ChoosePexM OnPurchaseClicked failed",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

		PlayNegativeSound(); // bsg-jrebar (4/20/17): New PlayNegativeSound Function in Parent Class
	}
}

simulated function bool CanAffordItem(int ItemIndex)
{
	if( ItemIndex > -1 && ItemIndex < arrItems.Length )
	{
		return XComHQ.CanAffordCommodity(arrItems[ItemIndex]);
	}
	else
	{
		return false;
	}
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------
simulated function GetItems()
{
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	arrItems = ConvertTechsToCommodities();
}

simulated function array<Commodity> ConvertTechsToCommodities()
{
	local XComGameState_Tech TechState;
	local int iProject;
	local bool bPausedProject;
	local array<Commodity> arrCommodoties;
	local Commodity TechComm;
	local StrategyCost EmptyCost;
	local StrategyRequirement EmptyReqs;

	m_arrRefs.Remove(0, m_arrRefs.Length);
	m_arrRefs = GetProjects();
	m_arrRefs.Sort(SortProjectsTime);
	m_arrRefs.Sort(SortProjectsTier);
	m_arrRefs.Sort(SortProjectsPriority);
	m_arrRefs.Sort(SortProjectsCanResearch);

	for (iProject = 0; iProject < m_arrRefs.Length; iProject++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iProject].ObjectID));
		bPausedProject = XComHQ.HasPausedProject(m_arrRefs[iProject]);
		
		TechComm.Title = TechState.GetDisplayName();

		if (bPausedProject)
		{
			TechComm.Title = TechComm.Title @ m_strPaused;
		}
		TechComm.Image = TechState.GetImage();
		TechComm.Desc = TechState.GetSummary();
		TechComm.OrderHours = XComHQ.GetResearchHours(m_arrRefs[iProject]);
		TechComm.bTech = true;

		if (bPausedProject)
		{
			TechComm.Cost = EmptyCost;
			TechComm.Requirements = EmptyReqs;
		}
		else
		{
			// <> TODO Can Staff adjust the required items//costs ?
			TechComm.Cost = TechState.GetMyTemplate().Cost;
			TechComm.Requirements = GetBestStrategyRequirementsForUI(TechState.GetMyTemplate());
			TechComm.CostScalars = XComHQ.ProvingGroundCostScalars;									//<> HQ.ref
			TechComm.DiscountPercent = XComHQ.ProvingGroundPercentDiscount;							//<> HQ.ref
		}

		arrCommodoties.AddItem(TechComm);
	}

	return arrCommodoties;
}

simulated function bool NeedsAttention(int ItemIndex)
{
	local XComGameState_Tech TechState;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[ItemIndex].ObjectID));
	return TechState.IsPriority();
}

simulated function bool ShouldShowGoodState(int ItemIndex)
{
	// Implement in subclasses
	// <> TODO	THIS IS THE SUBCLASS, WHAT AM I SUPPOSE TO DO WITH THIS ??
	return false;
}

//-----------------------------------------------------------------------------

simulated function String GetButtonString(int ItemIndex)
{
	if (XComHQ.HasPausedProject(m_arrRefs[ItemIndex]))
	{
		return m_strResume;
	}
	else
	{
		return m_strBuy;
	}
}

//This is overwritten from the research archives. 
simulated function array<StateObjectReference> GetProjects()
{
	//	ORIGINAL UICHOOSE's HAVE ONE SIMPLE LINE, BUT i NEED TO COMBINE AND FILTER THE LIST
	//return class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableProvingGroundProjects();
	//return class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableTechsForResearch(bShadowChamber);

	local array<StateObjectReference> PexMProjects, Projects, Research; //, Shadow;
	local int p,r;
	local XComGameState_Tech	TechState;
	local X2TechTemplate		TechTemplate;
	local name NameCheck;

	//Grab the games lists of proving ground projects and research (but not shadow chamber)
	Projects = class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableProvingGroundProjects();			
	Research = class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableTechsForResearch(false);
	//Shadow = class'UIUtilities_Strategy'.static.GetXComHQ().GetAvailableTechsForResearch(true);

	for (p = 0 ; p <= Projects.length ; p++)
	{
		//Add any Proving Grounds Techs with Tech_PexM to the list.. these are from this mod or a mod with this one in mind ;)
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(Projects[p].ObjectID));
		TechTemplate = TechState.GetMyTemplate();
		NameCheck = TechTemplate.DataName;
		if (InStr (NameCheck, "Tech_PexM") != -1 )
		{
			PexMProjects.AddItem(Projects[p]);
		}

		//Add anything in the config from mods that was given in extra
		if (default.ExtraTechTemplatesNames.Find(TechTemplate.DataName) != INDEX_NONE)
		{
			PexMProjects.AddItem(Projects[p]);
		}
	}

	for (r = 0 ; r <= Research.length ; r++)
	{
		//Add any Research Techs with Tech_PexM to the list.. these are from this mod or a mod with this one in mind ;)
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(Research[r].ObjectID));
		TechTemplate = TechState.GetMyTemplate();
		NameCheck = TechTemplate.DataName;
		if (InStr (NameCheck, "Tech_PexM") != -1 )
		{
			PexMProjects.AddItem(Research[r]);
		}

		//Add anything in the config from mods that was given in extra
		if (default.ExtraTechTemplatesNames.Find(TechTemplate.DataName) != INDEX_NONE)
		{
			PexMProjects.AddItem(Research[r]);
		}
	}

	return PexMProjects;
}

// <> TODO Can Staff adjust the required items//costs ?
simulated function StrategyRequirement GetBestStrategyRequirementsForUI(X2TechTemplate TechTemplate)
{
	local StrategyRequirement AltRequirement;
	
	if (!XComHQ.MeetsAllStrategyRequirements(TechTemplate.Requirements) && TechTemplate.AlternateRequirements.Length > 0)
	{
		foreach TechTemplate.AlternateRequirements(AltRequirement)
		{
			if (XComHQ.MeetsAllStrategyRequirements(AltRequirement))
			{
				return AltRequirement;
			}
		}
	}

	return TechTemplate.Requirements;
}

function int SortProjectsPriority(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local XComGameState_Tech TechStateA, TechStateB;

	TechStateA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID));
	TechStateB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID));

	if(TechStateA.IsPriority() && !TechStateB.IsPriority())
	{
		return 1;
	}
	else if(!TechStateA.IsPriority() && TechStateB.IsPriority())
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortProjectsCanResearch(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local X2TechTemplate TechTemplateA, TechTemplateB;
	local bool CanResearchA, CanResearchB;

	TechTemplateA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID)).GetMyTemplate();
	TechTemplateB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID)).GetMyTemplate();
	CanResearchA = XComHQ.MeetsRequirmentsAndCanAffordCost(TechTemplateA.Requirements, TechTemplateA.Cost, XComHQ.ResearchCostScalars, 0.0, TechTemplateA.AlternateRequirements);
	CanResearchB = XComHQ.MeetsRequirmentsAndCanAffordCost(TechTemplateB.Requirements, TechTemplateB.Cost, XComHQ.ResearchCostScalars, 0.0, TechTemplateB.AlternateRequirements);

	if (CanResearchA && !CanResearchB)
	{
		return 1;
	}
	else if (!CanResearchA && CanResearchB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortProjectsTime(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local int HoursA, HoursB;

	HoursA = XComHQ.GetResearchHours(TechRefA);
	HoursB = XComHQ.GetResearchHours(TechRefB);

	if (HoursA < HoursB)
	{
		return 1;
	}
	else if (HoursA > HoursB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

function int SortProjectsTier(StateObjectReference TechRefA, StateObjectReference TechRefB)
{
	local int TierA, TierB;

	TierA = XComGameState_Tech(History.GetGameStateForObjectID(TechRefA.ObjectID)).GetMyTemplate().SortingTier;
	TierB = XComGameState_Tech(History.GetGameStateForObjectID(TechRefB.ObjectID)).GetMyTemplate().SortingTier;

	if (TierA < TierB) return 1;
	else if (TierA > TierB) return -1;
	else return 0;
}

function bool OnTechTableOption(int iOption)
{
	local XComGameState_Tech TechState;

	TechState = XComGameState_Tech(History.GetGameStateForObjectID(m_arrRefs[iOption].ObjectID));
		
	if (!XComHQ.HasPausedProject(m_arrRefs[iOption]) && 
		!XComHQ.MeetsRequirmentsAndCanAffordCost(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, XComHQ.ProvingGroundPercentDiscount, TechState.GetMyTemplate().AlternateRequirements))
	{	//<> HQ.ref on above
		//SOUND().PlaySFX(SNDLIB().SFX_UI_No);

		`LOG("ChoosePexM TechTable false",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

		return false;
	}
	
	StartNewPexMProject(m_arrRefs[iOption]);
	//	XComHQ.SetNewResearchProject(m_arrRefs[iOption]); // ?? in UIchooseresearch ?

	`LOG("ChoosePexM TechTable true",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

	return true;
}

//-------------------------------------------------
//---------------------------------------------------------------------------------------
function StartNewPexMProject(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_Tech TechState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_StaffSlot StaffSlotState;
	local XComGameState_HeadquartersProjectPexM PexMProject;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Proving Ground Project");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
			
	FacilityState = XComHQ.GetFacilityByName('PexMChamber');
	FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));

	PexMProject = XComGameState_HeadquartersProjectPexM(NewGameState.CreateNewStateObject(class'XComGameState_HeadquartersProjectPexM'));
	PexMProject.SetProjectFocus(TechRef, NewGameState, FacilityState.GetReference());
	PexMProject.SavedDiscountPercent = XComHQ.ProvingGroundPercentDiscount; // Save the current discount in case the project needs a refund		//<> HQ.ref
	
	XComHQ.Projects.AddItem(PexMProject.GetReference()); // Investigate XCOMHQ.Projects ... takes a StateObjectReference
	
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
	XComHQ.PayStrategyCost(NewGameState, TechState.GetMyTemplate().Cost, XComHQ.ProvingGroundCostScalars, XComHQ.ProvingGroundPercentDiscount);	//<> HQ.ref

	//Add proving ground project to the build queues
	FacilityState.BuildQueue.AddItem(PexMProject.GetReference());

	if (!TechState.IsInstant() && !bPlayedConfirmationVO)
	{
		`XEVENTMGR.TriggerEvent('ChoosePexMProject', , , NewGameState);
		bPlayedConfirmationVO = true;
	}
			
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if (PexMProject.bInstant)
	{
		PexMProject.OnProjectCompleted();
	}
	else if (FacilityState.GetNumEmptyStaffSlots() > 0)
	{
		StaffSlotState = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

		if ((StaffSlotState.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
			(StaffSlotState.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
		{
			`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlotState.GetMyTemplate());
		}
	}
	
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	XComHQ.HandlePowerOrStaffingChange();

	RefreshQueue();

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
	//We don't want to force this to be visible; it will turn on when the strategy screen listener triggers it on at the top base view. 
	`HQPRES.m_kAvengerHUD.Objectives.Hide();

	`LOG("ChoosePexM New Project started :: " @TechState.GetMyTemplate().DataName,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

simulated function RefreshQueue()
{
	local UIScreen QueueScreen;

	QueueScreen = Movie.Stack.GetScreen(class'UIFacility_PexMLab');
	if (QueueScreen != None)
	{
		UIFacility_PexMLab(QueueScreen).UpdateBuildQueue();
		UIFacility_PexMLab(QueueScreen).UpdateBuildProgress();
		UIFacility_PexMLab(QueueScreen).m_NewBuildQueue.DeactivateButtons();
	}
	
	
	`HQPRES.m_kAvengerHUD.UpdateResources();

	`LOG("ChoosePexM Refresh Queue Run",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

//----------------------------------------------------------------
simulated function OnCancelButton(UIButton kButton) { OnCancel(); }
simulated function OnCancel()
{
	CloseScreen();

	`LOG("ChoosePexM Cancel or Closed",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
}

//==============================================================================

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();

	`LOG("ChoosePexM Lost Focus",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(OnCancel);

	`LOG("ChoosePexM Received Focus",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
}

//override the UIPanel OnMouseEvent to enable sticky highlighting of selected squad
simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");
		if( List.HasItem(self) )
		{
			List.SetSelectedIndex(List.GetItemIndex(self));
			if(List.OnItemClicked != none)
				List.OnItemClicked(List, List.SelectedIndex);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		if( `XENGINE.m_SteamControllerManager.IsSteamControllerActive() )
		{
			if( List.HasItem(self) )
			{
				List.SetSelectedIndex(List.GetItemIndex(self));
				if(List.OnItemClicked != none)
					List.OnItemClicked(List, List.SelectedIndex);
			}
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");
		if( List.HasItem(self) )
		{
			List.SetSelectedIndex(List.GetItemIndex(self));
			if(List.OnItemDoubleClicked != none)
				List.OnItemDoubleClicked(List, List.SelectedIndex);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
		//OnReceiveFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
		//OnLoseFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_DOWN:
		if( List.Scrollbar != none )
			List.Scrollbar.OnMouseScrollEvent(1);
		break;
	case class'UIUtilities_Input'.const.FXS_MOUSE_SCROLL_UP:
		if( List.Scrollbar != none )
			List.Scrollbar.OnMouseScrollEvent(-1);
		break;
	}

	if( OnMouseEventDelegate != none )
		OnMouseEventDelegate(self, cmd);
}

defaultproperties
{
	InputState = eInputState_Evaluate;

	DisplayTag      = "UIBlueprint_PexMChamber";
	CameraTag       = "UIBlueprint_PexMChamber";

	bAnimateOnInit = true;
	bSelectFirstAvailable = true;

	bHideOnLoseFocus = true;

	Package = "/ package/gfxInventory/Inventory";

	InventoryListName="inventoryListMC";

	bProcessMouseEventsIfNotFocused = true; //needed to process interacting on the queue. 
	//bProcessesMouseEvents = FALSE;		//AND DONT SET IT TRUE, IT BREAKS THE 3D VIEW
	//bConsumeMouseEvents = FALSE;			// DITTO
	//bCascadeSelection = FALSE;			// DITTO, AGAIN

	bHitTestDisabled = false;

	OverrideInterpTime = -1;
}