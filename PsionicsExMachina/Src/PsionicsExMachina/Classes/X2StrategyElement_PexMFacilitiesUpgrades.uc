//---------------------------------------------------------------------------------------
//  FILE:   X2StrategyElement_PexMFacilitiesUpgrades.uc                                    
//
//	File created by RustyDios	
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    06/09/20	22:00
//
//  ADDS pexm psi facility upgrades !!
//
//---------------------------------------------------------------------------------------
class X2StrategyElement_PexMFacilitiesUpgrades extends X2StrategyElement_DefaultFacilityUpgrades config(PsionicsExMachina);

var config array<name> strPexMChamberUPGRADE_COST_TYPE1, strPexMChamberUPGRADE_COST_TYPE2;	//225 suplies, 15dust
var config array<int>  iPexMChamberUPGRADE_COST_AMOUNT1, iPexMChamberUPGRADE_COST_AMOUNT2;	//42 supplies, 1ecore

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Upgrades;

	// rear area, more space, more staff
	Upgrades.AddItem(CreatePexMChamber_SecondCell());
	
	// side area, only create the training if its enabled
	if (class'X2StrategyElement_PexMFacilities'.default.bCanTrainPsiOffense)
	{
		Upgrades.AddItem(CreatePexMChamber_TrainingCell());
	}
	
	return Upgrades;
}

//---------------------------------------------------------------------------------------
// PEXM CHAMBER UPGRADES
//---------------------------------------------------------------------------------------
static function X2DataTemplate CreatePexMChamber_SecondCell()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;
	local int i;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'PexMChamber_SecondCell');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.iPower = class'X2StrategyElement_PexMFacilities'.default.PexMChamberPOWER;
	Template.UpkeepCost = class'X2StrategyElement_PexMFacilities'.default.PexMChamberUPKEEP;
	Template.strImage = "img:///UILibrary_PexM.FacilityIcons.ChooseFacility_PexMLab_Secondcell"; //"img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab_SecondCell";

	Template.OnUpgradeAddedFn = OnUpgradeAdded_UnlockStaffSlot_ALL_nonSoldier;
	
	// Costs	Code forloop taken from Iridar, looks for arrays in the config file and cycles through them adding the costs
	for (i = 0; i < default.strPexMChamberUPGRADE_COST_TYPE1.Length; i++)
	{
		if (default.iPexMChamberUPGRADE_COST_AMOUNT1[i] > 0)
		{
			Resources.ItemTemplateName = default.strPexMChamberUPGRADE_COST_TYPE1[i];
			Resources.Quantity = default.iPexMChamberUPGRADE_COST_AMOUNT1[i];
			Template.Cost.ResourceCosts.AddItem(Resources);
		}
	}

	return Template;
}

static function X2DataTemplate CreatePexMChamber_TrainingCell()
{
	local X2FacilityUpgradeTemplate Template;
	local ArtifactCost Resources;
	local int i;

	`CREATE_X2TEMPLATE(class'X2FacilityUpgradeTemplate', Template, 'PexMChamber_TrainingCell');
	Template.PointsToComplete = 0;
	Template.MaxBuild = 1;
	Template.iPower = class'X2StrategyElement_PexMFacilities'.default.PexMChamberPOWER;
	Template.UpkeepCost = class'X2StrategyElement_PexMFacilities'.default.PexMChamberUPKEEP;
	Template.strImage = "img:///UILibrary_PexM.FacilityIcons.ChooseFacility_PexMLab_Testbed"; //"img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_PsionicLab_SecondCell";
	
	Template.OnUpgradeAddedFn = OnUpgradeAdded_UnlockStaffSlot_ALL_PsiSoldier;
	
	// Costs	Code forloop taken from Iridar, looks for arrays in the config file and cycles through them adding the costs
	for (i = 0; i < default.strPexMChamberUPGRADE_COST_TYPE2.Length; i++)
	{
		if (default.iPexMChamberUPGRADE_COST_AMOUNT2[i] > 0)
		{
			Resources.ItemTemplateName = default.strPexMChamberUPGRADE_COST_TYPE2[i];
			Resources.Quantity = default.iPexMChamberUPGRADE_COST_AMOUNT2[i];
			Template.Cost.ResourceCosts.AddItem(Resources);
		}
	}

	return Template;
}

//Unlocks ALL staff slots that ARE NOT soldier slots ... sci or eng
static function OnUpgradeAdded_UnlockStaffSlot_ALL_nonSoldier(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	local XComGameState_StaffSlot StaffSlotState;
	local int i;

	for (i = 0; i <= Facility.StaffSlots.Length; i++)
	{
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(Facility.StaffSlots[i].ObjectID));
		if (StaffSlotState.IsLocked() && StaffSlotState.GetMyTemplate().bSoldierSlot != true)
		{
			StaffSlotState = XComGameState_StaffSlot(NewGameState.ModifyStateObject(class'XComGameState_StaffSlot', Facility.StaffSlots[i].ObjectID));
			StaffSlotState.UnlockSlot();
			//return;
		}
	}
	
	return;	
}

//Unlocks ALL staff slots that ARE soldier slots ... training slot
static function OnUpgradeAdded_UnlockStaffSlot_ALL_PsiSoldier(XComGameState NewGameState, XComGameState_FacilityUpgrade Upgrade, XComGameState_FacilityXCom Facility)
{
	local XComGameState_StaffSlot StaffSlotState;
	local int i;

	for (i = 0; i <= Facility.StaffSlots.Length; i++)
	{
		StaffSlotState = XComGameState_StaffSlot(`XCOMHISTORY.GetGameStateForObjectID(Facility.StaffSlots[i].ObjectID));
		if (StaffSlotState.IsLocked() && StaffSlotState.GetMyTemplate().bSoldierSlot != false)
		{
			StaffSlotState = XComGameState_StaffSlot(NewGameState.ModifyStateObject(class'XComGameState_StaffSlot', Facility.StaffSlots[i].ObjectID));
			StaffSlotState.UnlockSlot();
			//return;
		}
	}
	
	return;	
}