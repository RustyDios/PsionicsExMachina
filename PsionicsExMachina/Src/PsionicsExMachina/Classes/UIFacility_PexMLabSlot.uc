//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    25/10/20	00:01
//
//  PSIONICS TRAINING STAFF SLOT,	LEBs No More dropdowns incorporated 
//
//*******************************************************************************************
class UIFacility_PexMLabSlot extends UIFacility_StaffSlot dependson(UIPersonnel);

var localized string m_strPexMTrainingDialogTitle;
var localized string m_strPexMTrainingDialogText;
var localized string m_strStopPexMTrainingDialogTitle;
var localized string m_strStopPexMTrainingDialogText;
var localized string m_strPauseAbilityTrainingDialogTitle;
var localized string m_strPauseAbilityTrainingDialogText;

simulated function UIStaffSlot InitStaffSlot(UIStaffContainer OwningContainer, StateObjectReference LocationRef, int SlotIndex, delegate<OnStaffUpdated> onStaffUpdatedDel)
{
	super.InitStaffSlot(OwningContainer, LocationRef, SlotIndex, onStaffUpdatedDel);
	
	return self;
}

//-----------------------------------------------------------------------------
/*
//Kdm's controller support ... works but causes the cancel project box to appear twice?
simulated function OnClickStaffSlot(UIPanel kControl, int cmd)
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local string PopupText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	switch (cmd)
	{
		// KDM : Added FXS_L_MOUSE_UP since this is what OnUnrealCommand() pipes into ShowDropDown() for controllers.
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
			if (StaffSlot.IsLocked())
			{
				ShowUpgradeFacility();	//if slot is locked jump to upgrades
			}
			else if (StaffSlot.IsSlotEmpty())
			{
				OnPexMLabTrainSelected();	//if unlocked and empty open new drop down lists
			}
			else // Ask the user to confirm that they want to empty the slot and stop training
			{
				UnitState = StaffSlot.GetAssignedStaff();

				if (UnitState.GetStatus() == eStatus_Training) //eStatus_PsiTesting) //(IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
				{
					PopupText = m_strStopPexMTrainingDialogText;
					PopupText = Repl(PopupText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

					ConfirmEmptyProjectSlotPopup(m_strStopPexMTrainingDialogTitle, PopupText);
				}
				else if (UnitState.GetStatus() != eStatus_Training) //eStatus_PsiTesting) (IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
				{
					//there shouldn't be anyone in the slot 'not training' but just in case, pause/resume training ?
					PopupText = m_strPauseAbilityTrainingDialogText;
					PopupText = Repl(PopupText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

					ConfirmEmptyProjectSlotPopup(m_strPauseAbilityTrainingDialogTitle, PopupText, false);
				}
			}
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
			if (!StaffSlot.IsLocked())
			{
				StaffContainer.HideDropDown(self);	//hide the original list if not locked
			}
			break;
	}	
}
*/

simulated function ShowDropDown()
{
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_Unit UnitState;
	local string PopupText;

	StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

	//hide the original list if not locked
	if(!StaffSlot.IsLocked())
	{
		StaffContainer.HideDropDown(self);
	}

	//if slot is locked jump to upgrades
	if (StaffSlot.IsLocked())
	{
		ShowUpgradeFacility();
	}
	//if unlocked and empty open new drop down lists
    else if (StaffSlot.IsSlotEmpty())
    {
        //StaffContainer.ShowDropDown(self);
        OnPexMLabTrainSelected();
    }
	//if unlocked and in use ... Ask the user to confirm that they want to empty the slot and stop training
    else
    {
        UnitState = StaffSlot.GetAssignedStaff();

        if (UnitState.GetStatus() == eStatus_Training) //eStatus_PsiTesting) //(IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
        {
            PopupText = m_strStopPexMTrainingDialogText;
            PopupText = Repl(PopupText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

            ConfirmEmptyProjectSlotPopup(m_strStopPexMTrainingDialogTitle, PopupText);
        }
		//there shouldn't be anyone in the slot 'not training' but just in case, pause/resume training ?
        else if (UnitState.GetStatus() != eStatus_Training) //eStatus_PsiTesting) (IsTraining() || IsPsiTraining() || IsPsiAbilityTraining())
        {
            PopupText = m_strPauseAbilityTrainingDialogText;
            PopupText = Repl(PopupText, "%UNITNAME", UnitState.GetName(eNameType_RankFull));

            ConfirmEmptyProjectSlotPopup(m_strPauseAbilityTrainingDialogTitle, PopupText, false);
        }
    }
}

//no special treatment necessary since LW2 doesnt have special psilab slots
simulated function QueueDropDownDisplay()
{
	ShowDropDown();
}

simulated function OnPexMLabTrainSelected()
{
	if(IsDisabled)
	{
		return;
	}

	ShowSoldierList(eUIAction_Accept, none);
}

simulated function ShowSoldierList(eUIAction eAction, UICallbackData xUserData)
{
	local UIPersonnel_PexM kPersonnelList;
	local XComHQPresentationLayer HQPres;
	local XComGameState_StaffSlot StaffSlotState;
	
	if (eAction == eUIAction_Accept)
	{
		HQPres = `HQPRES;
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));

		//Don't allow clicking of Personnel List is active or if staffslot is filled
		if(HQPres.ScreenStack.IsNotInStack(class'UIPersonnel_PexM') && !StaffSlotState.IsSlotFilled())
		{
			kPersonnelList = Spawn( class'UIPersonnel_PexM', HQPres);
			kPersonnelList.m_eListType = eUIPersonnel_Soldiers;
			kPersonnelList.onSelectedDelegate = OnSoldierSelected;
			kPersonnelList.m_bRemoveWhenUnitSelected = true;
			kPersonnelList.SlotRef = StaffSlotRef;
			HQPres.ScreenStack.Push( kPersonnelList );
		}
	}
}

simulated function OnSoldierSelected(StateObjectReference _UnitRef)
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(_UnitRef.ObjectID));

	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative')
	{
		// DO NOTHING FOR PSI OPS <> MAYBE CHANGE THIS TO STANDARD PSI TRAINING ?
		//`HQPRES.UIChoosePsiAbility(_UnitRef, StaffSlotRef);
	}
	else
	{
		PexMPromoteDialog(Unit);
	}
}

simulated function OnPersonnelSelected(StaffUnitInfo UnitInfo)
{
	local XComGameState_Unit Unit;
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	
	if (Unit.GetSoldierClassTemplateName() == 'PsiOperative')
	{
		// DO NOTHING FOR PSI OPS <> MAYBE CHANGE THIS TO STANDARD PSI TRAINING
		//`HQPRES.UIChoosePsiAbility(UnitInfo.UnitRef, StaffSlotRef);
	}
	else
	{
		PexMPromoteDialog(Unit);
	}
}

simulated function PexMPromoteDialog(XComGameState_Unit Unit)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local XComGameState_HeadquartersXCom XComHQ;
	local int TrainingRateModifier;
	local UICallbackData_StateObjectReference CallbackData;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	TrainingRateModifier = XComHQ.PsiTrainingRate / XComHQ.XComHeadquarters_DefaultPsiTrainingWorkPerHour;

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = Unit.GetName(eNameType_RankFull);
	LocTag.IntValue0 = (XComHQ.GetPsiTrainingDays() / TrainingRateModifier);

	CallbackData = new class'UICallbackData_StateObjectReference';
	CallbackData.ObjectRef = Unit.GetReference();
	DialogData.xUserData = CallbackData;
	DialogData.fnCallbackEx = PexMPromoteDialogCallback;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = m_strPexMTrainingDialogTitle;
	DialogData.strText = `XEXPAND.ExpandString(m_strPexMTrainingDialogText);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNo;

	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function PexMPromoteDialogCallback(Name eAction, UICallbackData xUserData)
{	
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_FacilityXCom FacilityState;
	local UICallbackData_StateObjectReference CallbackData;
	local StaffUnitInfo UnitInfo;

	CallbackData = UICallbackData_StateObjectReference(xUserData);

	if(eAction == 'eUIAction_Accept')
	{		
		StaffSlot = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(StaffSlotRef.ObjectID));
		
		if (StaffSlot != none)
		{
			UnitInfo.UnitRef = CallbackData.ObjectRef;
			StaffSlot.FillSlot(UnitInfo); // The Training project is started when the staff slot is filled
            //the training project IS: XComGameState_HeadquartersProjectPexMTraining
			
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Staff_Assign");
			
			XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
			FacilityState = StaffSlot.GetFacility();
			if (FacilityState.GetNumEmptyStaffSlots() > 0)
			{
				StaffSlot = FacilityState.GetStaffSlot(FacilityState.GetEmptyStaffSlotIndex());

				if ((StaffSlot.IsScientistSlot() && XComHQ.GetNumberOfUnstaffedScientists() > 0) ||
					(StaffSlot.IsEngineerSlot() && XComHQ.GetNumberOfUnstaffedEngineers() > 0))
				{
					`HQPRES.UIStaffSlotOpen(FacilityState.GetReference(), StaffSlot.GetMyTemplate());
				}
			}
		}

		UpdateData();	//goes deep into UIStaffSlot via UIFacility_StaffSlot to set the slotstate
		//Update(StaffSlotState.GetNameDisplayString(),		Caps(StaffSlotState.GetBonusDisplayString()),		StaffSlotState.GetUnitTypeImage());
	}
}

//==============================================================================

defaultproperties
{
	width = 370;
	height = 65;
}
