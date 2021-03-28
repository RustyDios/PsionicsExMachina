//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    07/08/20	19:30 
//
//	controls unique pop-ups etc
//
//*******************************************************************************************
class XComHQPresentationLayer_PexM extends XComHQPresentationLayer;

static function UIPexMTrainingComplete(StateObjectReference UnitRef, X2AbilityTemplate AbilityTemplate)
{
	local DynamicPropertySet PropertySet;

	BuildUIAlert(PropertySet, 'eAlert_PsiTrainingComplete', PexMTrainingCompleteCB, '', "Geoscape_CrewMemberLevelledUp", true);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicIntProperty(PropertySet, 'UnitRef', UnitRef.ObjectID);
	class'X2StrategyGameRulesetDataStructures'.static.AddDynamicNameProperty(PropertySet, 'AbilityTemplate', AbilityTemplate.DataName);
	QueueDynamicPopup(PropertySet);
}

simulated function PexMTrainingCompleteCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local StateObjectReference UnitRef;

	if (eAction == 'eUIAction_Accept')
	{
		
		UnitRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(AlertData, 'UnitRef');

		GoToPexMChamber(UnitRef, true);
	}
}

simulated function GoToPexMChamber(StateObjectReference UnitRef, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom PsiChamberState;
	local StaffUnitInfo UnitInfo;
	local UIFacility CurrentFacilityScreen;
	local int emptyStaffSlotIndex;

	if (`GAME.GetGeoscape().IsScanning())
		StrategyMap2D.ToggleScan();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	PsiChamberState = XComHQ.GetFacilityByName('PexMChamber');
	PsiChamberState.GetMyTemplate().SelectFacilityFn(PsiChamberState.GetReference(), true);

	if (PsiChamberState.GetNumEmptyStaffSlots() > 0) // First check if there are any open staff slots
	{
		// get to choose scientist screen (from staff slot)
		CurrentFacilityScreen = UIFacility(m_kAvengerHUD.Movie.Stack.GetCurrentScreen());
		emptyStaffSlotIndex = PsiChamberState.GetEmptySoldierStaffSlotIndex();
		if (CurrentFacilityScreen != none && emptyStaffSlotIndex > -1)
		{
			// Only allow the unit to be selected if they are valid
			UnitInfo.UnitRef = UnitRef;
			if (PsiChamberState.GetStaffSlot(emptyStaffSlotIndex).ValidUnitForSlot(UnitInfo))
			{
				CurrentFacilityScreen.SelectPersonnelInStaffSlot(emptyStaffSlotIndex, UnitInfo);
			}
		}
	}
}
