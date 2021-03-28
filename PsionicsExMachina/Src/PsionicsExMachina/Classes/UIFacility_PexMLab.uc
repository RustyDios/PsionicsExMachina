//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    12/10/20	07:00
//
//	UI OVERVIEW OF THE FACILITY
//
//*******************************************************************************************
class UIFacility_PexMLab extends UIFacility; //UIFacility_PsiLab;

var public UIEventQueue m_NewBuildQueue;
var public UIFacility_ResearchProgress m_BuildProgress;

var localized string m_strEditQueue;
var localized string m_strMoveItemUp;
var localized string m_strMoveItemDown;
var localized string m_strRemoveItem;

var localized string m_strStartProject;
var localized string m_strProjectedHours;
var localized string m_strProjectedDays;
var localized string m_strEmptyQueue;
var localized string m_strCurrentProject;
var localized string m_strCancelPexMProjectTitle;
var localized string m_strCancelPexMProjectBody;
var localized String m_strProgress;
var localized String m_strCheckInventory;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_HeadquartersXCom XComHQ;
	//local XComGameState_FacilityXCom Facility;

	super.InitScreen(InitController, InitMovie, InitName);

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	//stop the psi lab introduction screen tutorial bit
	if (!XComHQ.bHasSeenPsiLabIntroPopup)
	{
		XComHQ.bHasSeenPsiLabIntroPopup = true;
	}

   	// Build Queue
	m_NewBuildQueue = Spawn(class'UIEventQueue', self).InitEventQueue();
	m_BuildProgress = Spawn(class'UIFacility_ResearchProgress', self).InitResearchProgress();

	Navigator.OnSelectedIndexChanged = NavigatorSelectionChanged;
	Navigator.SelectFirstAvailable();

	UpdateBuildQueue();
	UpdateBuildProgress();
	RealizeNavHelp();

	`LOG("UIFacility_PexM InitScreen",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

simulated function OnInit()
{
	local UIChoosePexMProject kScreen;

	local XComGameState_Tech TechState;
	local array<StateObjectReference> TechRefs;
	local int idx;

	super.OnInit();

	if (NeedResearchReportPopup(TechRefs))
	{
		bInstantInterp = false; // Can turn instant interp off now that we're in the facility

		if (`HQPRES.ScreenStack.IsNotInStack(class'UIChoosePexMProject'))
		{
			kScreen = `HQPRES.Spawn(class'UIChoosePexMProject', `HQPRES);
			`HQPRES.ScreenStack.Push(kScreen, `HQPRES.Get3DMovie());
		}

		for (idx = 0; idx < TechRefs.Length; idx++)
		{
			// Check for additional unlocks from this tech to generate popups
			TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(TechRefs[idx].ObjectID));
			TechState.DisplayTechCompletePopups();
		}
	}

	`LOG("UIFacility_PexM OnInt",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

simulated function NavigatorSelectionChanged(int newIndex)
{
	RealizeNavHelp();
}

simulated function RealizeNavHelp()
{
	super.RealizeNavHelp();

	if(`ISCONTROLLERACTIVE)
	{
		if(Navigator.GetSelected() == m_NewBuildQueue)
		{
			NavHelp.ClearButtonHelp();
			NavHelp.bIsVerticalHelp = true;
			NavHelp.AddBackButton(OnCancel);
			NavHelp.AddLeftHelp(m_strRemoveItem, class'UIUtilities_Input'.const.ICON_X_SQUARE); //bsg-jneal (5.12.17): moving input to X/SQUARE
			NavHelp.AddLeftHelp(m_strMoveItemDown, class'UIUtilities_Input'.const.ICON_LT_L2);
			NavHelp.AddLeftHelp(m_strMoveItemUp, class'UIUtilities_Input'.const.ICON_RT_R2);
		}
		else if(m_NewBuildQueue.GetListItemCount() > 1)
		{
			NavHelp.AddLeftHelp(m_strEditQueue, class'UIUtilities_Input'.const.ICON_X_SQUARE); //bsg-jneal (5.12.17): moving input to X/SQUARE
		}
	}
}

simulated function CreateFacilityButtons()
{
	AddFacilityButton(m_strStartProject, OnChoosePexMProject);
	AddFacilityButton(m_strCheckInventory, OnCheckInventory);
	
	`LOG("UIFacility_PexM FacilityButtons Created",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
}

simulated function OnChoosePexMProject()
{
	local UIChoosePexMProject kScreen;

	if (`HQPRES.ScreenStack.IsNotInStack(class'UIChoosePexMProject'))
	{
		kScreen = `HQPRES.Spawn(class'UIChoosePexMProject', `HQPRES);
		`HQPRES.ScreenStack.Push(kScreen, `HQPRES.Get3DMovie());

	}
	Navigator.SetSelected(kScreen.List);

	`LOG("UIFacility_PexM Choose Project Selected",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

// <>TODO EITHER ADD A DISABLE CHECK ON EMPTY INVENTORY OR A DUMMY FIRST ITEM
// QUITE LIKE THE DUMMY FIRST ITEM ROUTE WHICH COULD EXPLAIN PEX M 'BASICS'

simulated function OnCheckInventory()
{
	local UIInventory_PexM kScreen;

	if (`HQPRES.ScreenStack.IsNotInStack(class'UIInventory_PexM'))
	{
		kScreen = `HQPRES.Spawn(class'UIInventory_PexM', `HQPRES);
		`HQPRES.ScreenStack.Push(kScreen,`HQPRES.Get3DMovie());

	}
	Navigator.SetSelected(kScreen.List);

	`LOG("UIFacility_PexM Choose Inventory Selected",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

simulated function String GetProgressString()
{
	local XComGameState_HeadquartersProjectPexM PexMProject;
	
	PexMProject = XComGameState_HeadquartersProjectPexM(`XCOMHISTORY.GetGameStateForObjectID(class'XComGameState_HeadquartersProjectPexM'.static.GetCurrentPexMProject().ObjectID));
	
	if(PexMProject != none)
	{
		return m_strProgress @ class'UIUtilities_Strategy'.static.GetResearchProgressString(XCOMHQ().GetResearchProgress(class'XComGameState_HeadquartersProjectPexM'.static.GetCurrentPexMProject() )); //.GetReference()) );
	}
	else
	{
		return "";
	}
}

simulated function EUIState GetProgressColor()
{
	return class'UIUtilities_Strategy'.static.GetResearchProgressColor(XCOMHQ().GetResearchProgress(class'XComGameState_HeadquartersProjectPexM'.static.GetCurrentPexMProject() )); //.GetReference()) );
}

simulated function UpdateBuildQueue()
{
	local int i;
	local XComGameState_Tech PexMTech;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectPexM PexMProject;
	//	local XComGameState_HeadquartersProjectPexMTraining PexMProjectTraining;
	//	local XComGameState_Unit Unit;

	local StateObjectReference BuildItemRef;
	local int ProjectHours;
	local array<HQEvent> BuildItems;
	local HQEvent BuildItem;
	
	Facility = GetFacility();

	for (i = 0; i < Facility.BuildQueue.Length; ++i)
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

	/*	// NO i DON'T WANT TO ADD THE PSI TEST TO THE BUILD QUEUE HERE, AS IT CAN'T BE MOVED UP/DOWN ETC
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
	}*/

	m_NewBuildQueue.OnUpButtonClicked = OnUpButtonClicked;
	m_NewBuildQueue.OnDownButtonClicked = OnDownButtonClicked;
	m_NewBuildQueue.OnCancelButtonClicked = CancelProjectPopup;
	m_NewBuildQueue.UpdateEventQueue(BuildItems, true, true);
	m_NewBuildQueue.HideDateTime();
	
	//this isn't the main event queue, it doesn't break but it doesn't work
	//`HQPRES.m_kAvengerHUD.EventQueue.UpdateEventQueue(BuildItems, true, true);

	`LOG("UIFacility_PexM Build Queue Updated",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

simulated function UpdateBuildProgress()
{
	local int ProjectHours;
	local string days, progress;
	local XComGameState_Tech PexMTech;

	local XComGameState_HeadquartersProjectPexM PexMProject;

	PexMProject = XComGameState_HeadquartersProjectPexM(`XCOMHISTORY.GetGameStateForObjectID(class'XComGameState_HeadquartersProjectPexM'.static.GetCurrentPexMProject().ObjectID));

	if(PexMProject != none)
	{
		PexMTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(PexMProject.ProjectFocus.ObjectID));

		ProjectHours = PexMProject.GetCurrentNumHoursRemaining();

		if (ProjectHours < 0)
			days = class'UIUtilities_Text'.static.GetColoredText(class'UIFacility_PowerCore'.default.m_strStalledResearch, eUIState_Warning);
		else
			days = class'UIUtilities_Text'.static.GetTimeRemainingString(ProjectHours);

		progress = class'UIUtilities_Text'.static.GetColoredText(GetProgressString(), GetProgressColor());
		m_BuildProgress.Update(m_strCurrentProject, PexMTech.GetMyTemplate().DisplayName, days, progress, int(100 * PexMProject.GetPercentComplete()));
		m_BuildProgress.Show();
		m_NewBuildQueue.SetY(-250); // move up to make room for BuildProgress bar //-250
	}
	else
	{
		m_BuildProgress.Hide();
		m_NewBuildQueue.SetY(-120); // restore to its original location
	}
	
	`LOG("UIFacility_PexM Build Progress Updated",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

simulated function bool IsProjectStalled()
{
	local XComGameState_HeadquartersProjectPexM PexMProject;

	PexMProject = XComGameState_HeadquartersProjectPexM(`XCOMHISTORY.GetGameStateForObjectID(class'XComGameState_HeadquartersProjectPexM'.static.GetCurrentPexMProject().ObjectID));
	if(PexMProject != none)
	{
		return PexMProject.GetCurrentNumHoursRemaining() < 0;
	}
	else
	{
		return false;
	}

	`LOG("UIFacility_PexM Project Stalled",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

}

simulated function OnUpButtonClicked(int ListItemIndex)
{
	local StateObjectReference BuildItemRef;
	local XComGameState_FacilityXCom NewFacilityState;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Edit PexM Build Queue: Move Item Up");
	NewFacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));

	// swap projects
	BuildItemRef = NewFacilityState.BuildQueue[ListItemIndex];
	NewFacilityState.BuildQueue[ListItemIndex] = NewFacilityState.BuildQueue[ListItemIndex - 1];
	NewFacilityState.BuildQueue[ListItemIndex - 1] = BuildItemRef;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();
	UpdateBuildQueue();
	UpdateBuildProgress();

	`HQPRES.m_kAvengerHUD.UpdateResources();
	UpdateBuildProgress();

}

// fired when a build queue UI list item has its down button clicked
simulated function OnDownButtonClicked(int ListItemIndex)
{
	local StateObjectReference BuildItemRef;
	local XComGameState_FacilityXCom NewFacilityState;
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Edit PexM Build Queue: Move Item Down");
	NewFacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityRef.ObjectID));

	// swap projects
	BuildItemRef = NewFacilityState.BuildQueue[ListItemIndex];
	NewFacilityState.BuildQueue[ListItemIndex] = NewFacilityState.BuildQueue[ListItemIndex + 1];
	NewFacilityState.BuildQueue[ListItemIndex + 1] = BuildItemRef;
		
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();
	UpdateBuildQueue();
	UpdateBuildProgress();

	`HQPRES.m_kAvengerHUD.UpdateResources();
	UpdateBuildProgress();

}

simulated function CancelProjectPopup(int ListItemIndex)
{
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectPexM PexMProject;
	local XComGameState_Tech PexMTech;
	local StateObjectReference BuildItemRef;
	local TDialogueBoxData kData;
	local XGParamTag ParamTag;
	local UICallbackData_StateObjectReference CallbackData;

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));
	BuildItemRef = FacilityState.BuildQueue[ListItemIndex];
	PexMProject = XComGameState_HeadquartersProjectPexM(`XCOMHISTORY.GetGameStateForObjectID(BuildItemRef.ObjectID));
	PexMTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(PexMProject.ProjectFocus.ObjectID));
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = PexMTech.GetDisplayName();

	kData.strTitle = m_strCancelPexMProjectTitle;
	kData.strText = `XEXPAND.ExpandString(m_strCancelPexMProjectBody);
	kData.strAccept = m_strOK;
	kData.strCancel = m_strCancel;
	kData.eType = eDialog_Alert;

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = BuildItemRef;
	kData.xUserData = CallbackData;
	kData.fnCallbackEx = OnCancelProjectPopupCallback;

	Movie.Pres.UIRaiseDialog(kData);
}

simulated function OnCancelProjectPopupCallback(Name eAction, UICallbackData xUserData)
{
	local UICallbackData_StateObjectReference CallbackData;
	local StateObjectReference BuildItemRef;
	local XComGameState NewGameState;
	
	if (eAction == 'eUIAction_Accept')
	{
		CallbackData = UICallbackData_StateObjectReference(xUserData);
		BuildItemRef = CallbackData.ObjectRef;

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Edit PexM Build Queue: Remove Project");
		class'XComGameStateContext_HeadquartersOrder_PexM'.static.CancelProvingGroundProject(NewGameState, BuildItemRef);
		class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
		`HQPRES.m_kAvengerHUD.Objectives.Hide();

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		class'UIUtilities_Strategy'.static.GetXComHQ().HandlePowerOrStaffingChange();
		UpdateBuildQueue();

		`HQPRES.m_kAvengerHUD.UpdateResources();
		UpdateBuildProgress();

		//bsg-jneal (5.12.17): with controller, rehighlight the start of the event queue after deleting an entry
		if(`ISCONTROLLERACTIVE)
		{
			if(m_NewBuildQueue.GetListItemCount() > 0)
			{
				SetTimer(0.25f, false, 'DelayedSelectOnRefresh');
			}
			else
			{
				OnUnrealCommand(class'UIUtilities_Input'.const.FXS_BUTTON_B, 
								class'UIUtilities_Input'.const.FXS_ACTION_RELEASE);
			}
		}
		//bsg-jneal (5.12.17): end
	}
}

//bsg-jneal (5.12.17): with controller, rehighlight the start of the event queue after deleting an entry
function DelayedSelectOnRefresh()
{
	Navigator.SetSelected(m_NewBuildQueue.List);
	m_NewBuildQueue.List.SetSelectedIndex(0, true);
}
//bsg-jneal (5.12.17): end

// ------------------------------------------------------------

simulated function RealizeStaffSlots()
{
	onStaffUpdatedDelegate = UpdateBuildQueue;
	super.RealizeStaffSlots();
	
	UpdateBuildProgress();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	if (m_kTitle != none)
		m_kTitle.Hide();

	m_NewBuildQueue.DeactivateButtons();
} 

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	
	UpdateBuildQueue();
	UpdateBuildProgress();

	if (m_kTitle != none)
		m_kTitle.Show();
}

function bool NeedResearchReportPopup(out array<StateObjectReference> TechRefs)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local int idx;
	local bool bNeedPopup;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	bNeedPopup = false;

	for (idx = 0; idx < XComHQ.TechsResearched.Length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(XComHQ.TechsResearched[idx].ObjectID));

		if (TechState != none  && !TechState.bSeenResearchCompleteScreen && !TechState.GetMyTemplate().bShadowProject && TechState.GetMyTemplate().bProvingGround)
		{
			TechRefs.AddItem(TechState.GetReference());
			bNeedPopup = true;
		}
	}

	return bNeedPopup;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{

	if(!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return false;

	if(Navigator.GetSelected() != m_NewBuildQueue && m_NewBuildQueue.GetListItemCount() > 0 && cmd == class'UIUtilities_Input'.const.FXS_BUTTON_X) //bsg-jneal (5.12.17): moving input to X/SQUARE
	{
		if(Navigator.GetSelected() != none)
			Navigator.GetSelected().OnLoseFocus();

		m_NewBuildQueue.EnableNavigation();
		m_kRoomContainer.DisableNavigation(); //bsg-jneal (5.12.17): disable navigation on room elements to prevent controller navigation slipping off the build queue when it has only 1 item
		m_kStaffSlotContainer.DisableNavigation();
		m_NewBuildQueue.Navigator.SelectFirstAvailable();
		Navigator.SetSelected(m_NewBuildQueue);
		RealizeNavHelp();
		return true;
	}
	
	if(Navigator.GetSelected() == m_NewBuildQueue)
	{
		if(cmd == class'UIUtilities_Input'.const.FXS_BUTTON_B || cmd == class'UIUtilities_Input'.const.FXS_KEY_ESCAPE)
		{
			m_NewBuildQueue.DeactivateButtons();
			m_NewBuildQueue.DisableNavigation();
			m_kRoomContainer.EnableNavigation(); //bsg-jneal (5.12.17): disable navigation on room elements to prevent controller navigation slipping off the build queue when it has only 1 item
			m_kStaffSlotContainer.EnableNavigation();
			Navigator.SelectFirstAvailable();
			RealizeNavHelp();
		}
		else
		{
			if(!m_NewBuildQueue.OnUnrealCommand(cmd, arg))
				m_NewBuildQueue.Navigator.OnUnrealCommand(cmd, arg);
		}

		return true; // consume all events if build queue is being manipulated
	}

	return super.OnUnrealCommand(cmd, arg);
}

//==============================================================================

defaultproperties
{
	bHideOnLoseFocus = false;
	bProcessMouseEventsIfNotFocused = true; //needed to process interacting on the queue. 
	
	InputState = eInputState_Evaluate; //eInputState_Consume; //

	bHitTestDisabled = false;

}

