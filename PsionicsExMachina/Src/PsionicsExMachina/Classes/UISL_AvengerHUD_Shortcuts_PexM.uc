//---------------------------------------------------------------------------------------
//  AUTHOR:  Xymanek && RustyDios
//  PURPOSE: This class is used to add a button to "Avenger" menus to goto the PexM Lab
//
//	File created	27/07/20    21:00
//	LAST UPDATED	24/10/20	19:00
//
//---------------------------------------------------------------------------------------
//  WOTCStrategyOverhaul Team << these guys rock !!
//	Made possible thanks to CHL  Issue #163
//---------------------------------------------------------------------------------------

class UISL_AvengerHUD_Shortcuts_PexM extends UIScreenListener;

var localized string LabelShortcut_PexMChamber;
var localized string TooltipShortcut_PexMChamber;

//on init, so this will cover a load game, or tactical > strategy transition
event OnInit(UIScreen Screen)
{
	local UIAvengerHUD AvengerHud;

	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState, PexMFacilityState;

	//ensure we have the right screen
	AvengerHud = UIAvengerHUD(Screen);
	if (AvengerHud == none) 
	{
		return;
	}

	//reset if the facility exists
	PexMFacilityState = none;

	//check we have a facility and it's not being built
	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if (FacilityState.GetMyTemplateName() == 'PexMChamber' && !FacilityState.IsUnderConstruction()  )
		{
			PexMFacilityState = FacilityState;
			break;
		}
	}

	//confirm we have the facility built
	if (PexMFacilityState != none && HasPexMChamber() )
	{
		AddSubMenuItems(AvengerHud);	//its built add the shortcut link
    }
	else
	{
		ResetSubMenuItems(AvengerHud);	//its not built remove the link
	}	
}

//does HQ have a pexm facility, right now
simulated function bool HasPexMChamber()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	return (XComHQ.GetFacilityByName('PexMChamber') != none);
}

//add the button ... also called from building the facility
static function AddSubMenuItems(UIScreen Screen) 
{
	local UIAvengerHUD AvengerHud;
	
	local UIAvengerShortcutSubMenuItem MenuItem, MenuCheck;
    local string AlertIcon;

	//ensure the screen is the HUD
	AvengerHud = UIAvengerHUD(Screen);
	if (AvengerHud == none) 
	{
		return;
	}

	// Create button for simple transition, pulled from UIAvengerShortcuts
	AlertIcon = class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.EventQueue_Psi, 20, 20, 0) $" ";

	MenuItem.Id = 'GotoPexMChamber';
	MenuItem.Message.Label = AlertIcon $ default.LabelShortcut_PexMChamber;
	MenuItem.Message.Description = default.TooltipShortcut_PexMChamber;
		//MenuItem.Message.Urgency = eUIAvengerShortcutMsgUrgency_Low;
		//MenuItem.Message.HotLinkRef = PexMFacilityState.GetReference();
	MenuItem.Message.OnItemClicked = OnButtonClickedSimple; // see below	//SelectFacilityHotlink

	//shortcut not added ... add it ... stops it being added twice
    if (AvengerHud.Shortcuts.FindSubMenu(eUIAvengerShortcutCat_Barracks, MenuItem.Id, MenuCheck) == false)
	{
		AvengerHud.Shortcuts.AddSubMenu(eUIAvengerShortcutCat_Barracks, MenuItem);
	}

	if (AvengerHud.Shortcuts.FindSubMenu(eUIAvengerShortcutCat_Research, MenuItem.Id, MenuCheck) == false)
	{
		AvengerHud.Shortcuts.AddSubMenu(eUIAvengerShortcutCat_Research, MenuItem);
	}
		
	if (AvengerHud.Shortcuts.FindSubMenu(eUIAvengerShortcutCat_Engineering, MenuItem.Id, MenuCheck) == false)
	{
	    AvengerHud.Shortcuts.AddSubMenu(eUIAvengerShortcutCat_Engineering, MenuItem);
	}

	//refresh the HUD buttons
	AvengerHud.Shortcuts.UpdateCategories();
}

//remove the button ... also called by destroying the facility
static function ResetSubMenuItems(UIScreen Screen) 
{
	local UIAvengerHUD AvengerHud;

	//ensure screen is the HUD
	AvengerHud = UIAvengerHUD(Screen);
	if (AvengerHud == none) 
	{
		return;
	}

	//remove the button directly
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_Barracks, 'GotoPexMChamber');
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_Research, 'GotoPexMChamber');
	AvengerHud.Shortcuts.RemoveSubMenu(eUIAvengerShortcutCat_Engineering, 'GotoPexMChamber');

	//refresh the HUD buttons
	AvengerHud.Shortcuts.UpdateCategories();
}

//push the button ... pu push the button
static protected function OnButtonClickedSimple(optional StateObjectReference Facility)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom PexMChamberState;

	//find and go to the pexm
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	PexMChamberState = XComHQ.GetFacilityByName('PexMChamber');

	GoDirectToPexMChamber(PexMChamberState.GetReference());
}

//do not pass go, do not collect £200, go direct to jail.. wait.. pexm
static function GoDirectToPexMChamber(StateObjectReference FacilityRef)
{
	local UIFacility CurrentScreen;
	local XComGameState_FacilityXCom FacilityState;

	CurrentScreen = UIFacility(`HQPRES.ScreenStack.GetCurrentScreen());
	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityRef.ObjectID));

	if( (CurrentScreen == none || CurrentScreen.FacilityRef != FacilityRef ) && !FacilityState.IsUnderConstruction() )
	{		
		`HQPRES.SetFacilityTransition(FacilityRef, false);

		`HQPRES.ClearUIToHUD(false);
		FacilityState.GetMyTemplate().SelectFacilityFn(FacilityRef);
	}
}
