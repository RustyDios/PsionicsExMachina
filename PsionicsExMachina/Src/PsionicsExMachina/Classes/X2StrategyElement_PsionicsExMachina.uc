//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    12/10/20	07:00
//
//  ADDS psi PCS && psi GEMS techs and pexm breakthroughs
// 		a tech needs bProvingGround + "Tech_PexM" as the prefix of the template name to show up in the PexM grounds
//		or added to the 'bypass' list for UIChoosePexMProject .. PsionicsExMachina configs
//		the three new techs here won't show up in the proving ground list due to the SpecialRequirementsFn :)
//
//*******************************************************************************************
class X2StrategyElement_PsionicsExMachina extends X2StrategyElement_XpackTechs config (PsionicsExMachina);

var config int Tech_PexM_PCS_DAYS, Tech_PexM_GEM_DAYS, Tech_PexM_CNV_DAYS;

var config array<name> strPCS_RESOURCE_COST_TYPE, strGEM_RESOURCE_COST_TYPE, strCNV_RESOURCE_COST_TYPE;
var config array<int>  iPCS_RESOURCE_COST_AMOUNT, iGEM_RESOURCE_COST_AMOUNT, iCNV_RESOURCE_COST_AMOUNT;

var config name CONVERT_AutopsyName;
var config int ConvertInput, ConvertOutput;

var config bool bSkipPGExclusion;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Techs;

	//'proving ground techs' ... these will go to the pexmchamber due to the Tech_PexM prefix in the template name
		Techs.AddItem(CreateTech_PexM_PCS());
		Techs.AddItem(CreateTech_PexM_GEMS());
		Techs.AddItem(CreateTech_PexM_CONVERT());

	//Breakthroughs
		// Weapon Damage
		//Techs.AddItem(CreateBreakthroughPsiAmpDamageTemplate());

		// Weapon Upgrades
		Techs.AddItem(CreateBreakthroughPsiAmpWeaponUpgradeTemplate());

		// Facility Cost Reduction
		Techs.AddItem(CreateBreakthroughPexMChamberCostReductionTemplate());

		// Facility Upgrade Cost Reduction
		Techs.AddItem(CreateBreakthroughPexMChamberSecondCellCostReductionTemplate());

		if (class'X2StrategyElement_PexMFacilities'.default.bCanTrainPsiOffense)
		{
			Techs.AddItem(CreateBreakthroughPexMChamberTrainingCellCostReductionTemplate());
		}

		// Strategy Modifiers
		//	Techs.AddItem(CreateBreakthroughPexMProjectCostReductionM1Template());
		//	Techs.AddItem(CreateBreakthroughPexMProjectCostReductionM2Template());

	return Techs;
}

//*******************************************************************************************
//*******************************************************************************************

static function X2DataTemplate CreateTech_PexM_CONVERT()
{
	local X2TechTemplate Template;
    local ArtifactCost Resources;
	local int i;

	// It is important to give the prefix "Tech_PexM" so that the UIChoose page for the Facility knows what to show :)
    `CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Tech_PexM_CONVERT') ;
    Template.PointsToComplete = StafferXDays(1, default.Tech_PexM_CNV_DAYS); //444;
	
	if(default.CONVERT_AutopsyName == 'AutopsyTheLost')
	{
    	Template.strImage = "img:///UILibrary_PexM.Tech_Images.TECH_PSI_CNV_LOST";
	}
	else
	{
    	Template.strImage = "img:///UILibrary_PexM.Tech_Images.TECH_PSI_CNV";
	}
    Template.bProvingGround = true;
    Template.bRepeatable = true;
    Template.SortingTier = 0;

    // Requirements
    Template.Requirements.RequiredTechs.AddItem(default.CONVERT_AutopsyName);
	Template.Requirements.RequiredTechs.AddItem('Psionics');

	Template.Requirements.SpecialRequirementsFn = AreWeInThePexMChamber;

    Template.Requirements.bVisibleIfItemsNotMet=false;

    // Item Rewards
    Template.ResearchCompletedFn = GiveMultipleItems;
	//for (i = 0 ; i < default.ConvertOutput ; i++)
	//{
		Template.ItemRewards.AddItem('InertMeld');
	//}

	// Costs	Code forloop taken from Iridar, looks for arrays in the config file and cycles through them adding the costs
	for (i = 0; i < default.strCNV_RESOURCE_COST_TYPE.Length; i++)
	{
		if (default.iCNV_RESOURCE_COST_AMOUNT[i] > 0)
		{
			Resources.ItemTemplateName = default.strCNV_RESOURCE_COST_TYPE[i];
			Resources.Quantity = default.iCNV_RESOURCE_COST_AMOUNT[i];
			Template.Cost.ResourceCosts.AddItem(Resources);
		}
	}

    return Template;
}

//*******************************************************************************************
//*******************************************************************************************

static function GiveMultipleItems(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ItemTemplate;
	local array<name> ItemRewards;
	local name ItemName;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	
	TechState.ItemRewards.Length = 0; // Reset the item rewards array in case the tech is repeatable

	ItemRewards = TechState.GetMyTemplate().ItemRewards;
	foreach ItemRewards(ItemName)
	{
		ItemTemplate = ItemTemplateManager.FindItemTemplate(ItemName);
		GiveItem_Multiple(NewGameState, ItemTemplate, default.ConvertOutput);

		if (TechState.GetMyTemplate().bProvingGround)
		{
			// Proving Ground projects don't have research reports, but display item rewards on the Geoscape, so save them here
			TechState.ItemRewards.AddItem(ItemTemplate);
		}
	}

	TechState.bSeenResearchCompleteScreen = false; // Reset the research report for techs that are repeatable
}

// Gives an item as though it was just constructed. Gives the highest available upgraded version of the item.
static function GiveItem_Multiple(XComGameState NewGameState, out X2ItemTemplate ItemTemplate, optional int Quantity = 1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Item ItemState;
	
	if (ItemTemplate != none)
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}

		if (XComHQ == none)
		{
			History = `XCOMHISTORY;
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		}

		// Find the highest available upgraded version of the item
		XComHQ.UpdateItemTemplateToHighestAvailableUpgrade(ItemTemplate);
		ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		ItemState.Quantity = Quantity;
		
		// Act as though it was just built, and immediately add it to the inventory
		ItemState.OnItemBuilt(NewGameState);
		XComHQ.PutItemInInventory(NewGameState, ItemState);

		`XEVENTMGR.TriggerEvent('ItemConstructionCompleted', ItemState, ItemState, NewGameState);
	}
}

//*******************************************************************************************
//*******************************************************************************************

static function X2DataTemplate CreateTech_PexM_PCS()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;
	local int i;

	// It is important to give the prefix "Tech_PexM" so that the UIChoose page for the Facility knows what to show :)
	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Tech_PexM_PCS');
	Template.PointsToComplete = StafferXDays(1, default.Tech_PexM_PCS_DAYS); //8 days = 960 
	Template.strImage = "img:///UILibrary_PexM.Tech_Images.TECH_PSI_PCS";
	Template.bProvingGround = true;
	Template.bRepeatable = true;
	Template.SortingTier = 5;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Psionics');

	Template.Requirements.SpecialRequirementsFn = AreWeInThePexMChamber;

	Template.Requirements.bVisibleIfItemsNotMet=false;

	// Item Rewards
	Template.ResearchCompletedFn = class'X2StrategyElement_DefaultTechs'.static.GiveDeckedItemReward;
	Template.RewardDeck = 'Experimental_PexM_PCS';
	
	// Costs	Code forloop taken from Iridar, looks for arrays in the config file and cycles through them adding the costs
	for (i = 0; i < default.strPCS_RESOURCE_COST_TYPE.Length; i++)
	{
		if (default.iPCS_RESOURCE_COST_AMOUNT[i] > 0)
		{
			Resources.ItemTemplateName = default.strPCS_RESOURCE_COST_TYPE[i];
			Resources.Quantity = default.iPCS_RESOURCE_COST_AMOUNT[i];
			Template.Cost.ResourceCosts.AddItem(Resources);
		}
	}

	return Template;
}

//*******************************************************************************************
//*******************************************************************************************

static function X2DataTemplate CreateTech_PexM_GEMS()
{
	local X2TechTemplate Template;
	local ArtifactCost Resources;
	local int i;

	// It is important to give the prefix "Tech_PexM" so that the UIChoose page for the Facility knows what to show :)
	`CREATE_X2TEMPLATE(class'X2TechTemplate', Template, 'Tech_PexM_GEMS');
	Template.PointsToComplete = StafferXDays(1, default.Tech_PexM_GEM_DAYS); //4 days = 480
	Template.strImage = "img:///UILibrary_PexM.Tech_Images.TECH_PSI_GEM";
	Template.bProvingGround = true;
	Template.bRepeatable = true;
	Template.SortingTier = 5;

	// Requirements
	Template.Requirements.RequiredTechs.AddItem('Psionics');
	
	Template.Requirements.SpecialRequirementsFn = AreWeInThePexMChamber;

	Template.Requirements.bVisibleIfItemsNotMet=false;

	// Item Rewards
	Template.ResearchCompletedFn = class'X2StrategyElement_DefaultTechs'.static.GiveDeckedItemReward;
	Template.RewardDeck = 'Experimental_PexM_GEM';

	// Costs	Code forloop taken from Iridar, looks for arrays in the config file and cycles through them adding the costs
	for (i = 0; i < default.strGEM_RESOURCE_COST_TYPE.Length; i++)
	{
		if (default.iGEM_RESOURCE_COST_AMOUNT[i] > 0)
		{
			Resources.ItemTemplateName = default.strGEM_RESOURCE_COST_TYPE[i];
			Resources.Quantity = default.iGEM_RESOURCE_COST_AMOUNT[i];
			Template.Cost.ResourceCosts.AddItem(Resources);
		}
	}

	return Template;
}

//*******************************************************************************************
//*******************************************************************************************

//NO LONGER REQUIRED AS EXTENDING _DEFAULTTECHS ... STOP PUTTING IT BACK IN !!
//static function int StafferXDays(int iNumScientists, int iNumDays)
//{
//	return (iNumScientists * 5) * (24 * iNumDays); // Scientists at base skill level
//}

/*
static function X2DataTemplate CreateBreakthroughPsiAmpDamageTemplate()
{
	local X2TechTemplate Template;
	local X2BreakthroughCondition_WeaponType WeaponTypeCondition;

	Template = CreateBreakthroughTechTemplate('BreakthroughPsiAmpDamage');
	Template.strImage = "img:///UILibrary_PexM.Tech_Images.BT_modpsiamp";
	Template.ResearchCompletedFn = BreakthroughItemTacticalBonusCompleted;

	WeaponTypeCondition = new class'X2BreakthroughCondition_WeaponType';
	WeaponTypeCondition.WeaponTypeMatch = 'psiamp';
	Template.BreakthroughCondition = WeaponTypeCondition;

	WeaponTypeCondition = new class'X2BreakthroughCondition_WeaponType';
	WeaponTypeCondition.WeaponTypeMatch = 'replace_psiamp';
	Template.BreakthroughCondition = WeaponTypeCondition;

	Template.RewardName = 'WeaponTypeBreakthroughBonus';

	return Template;
}
*/

//*******************************************************************************************
//*******************************************************************************************

static function X2DataTemplate CreateBreakthroughPsiAmpWeaponUpgradeTemplate()
{
	local X2TechTemplate Template;

	Template = CreateBreakthroughTechTemplate('BreakthroughPsiAmpWeaponUpgrade');
	Template.strImage = "img:///UILibrary_PexM.Tech_Images.BT_modpsiamp";
	Template.ResearchCompletedFn = BreakthroughWeaponUpgradeCompleted_MultiPexM;
	Template.RewardName = 'psiamp';

	Template.Requirements.RequiredTechs.AddItem('ModularWeapons');
	Template.Requirements.RequiredTechs.AddItem('Psionics');

	return Template;
}

function BreakthroughWeaponUpgradeCompleted_MultiPexM(XComGameState NewGameState, XComGameState_Tech TechState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	//XComHQ.ExtraUpgradeWeaponCats.AddItem(TechState.GetMyTemplate().RewardName);		categories- see also dlcinfo canapply and x2item canapply
	XComHQ.ExtraUpgradeWeaponCats.AddItem('psiamp');
	XComHQ.ExtraUpgradeWeaponCats.AddItem('replace_psiamp');	//support for PZ_Psionic_Melee			https://steamcommunity.com/sharedfiles/filedetails/?id=1549781357
	XComHQ.ExtraUpgradeWeaponCats.AddItem('sectoidpsiamp');		//support for Playable Aliens 			https://steamcommunity.com/sharedfiles/filedetails/?id=1218007143
	XComHQ.ExtraUpgradeWeaponCats.AddItem('RM_Bioamp');			//support for Biotic Class	 			https://steamcommunity.com/sharedfiles/filedetails/?id=1125004715

}

static function X2DataTemplate CreateBreakthroughPexMChamberCostReductionTemplate()
{
	local X2TechTemplate Template;

	Template = CreateBreakthroughTechTemplate('BreakthroughPexMChamberCostReduction');
	Template.strImage = "img:///UILibrary_PexM.Tech_Images.BT_PexMChamber1";
	Template.ResearchCompletedFn = BreakthroughFacilityDiscountCompleted;
	Template.GetValueFn = GetValueFacilityCostReduction;

	Template.Requirements.SpecialRequirementsFn = IsBreakthroughPexMChamberCostReductionAvailable;
	Template.RewardName = 'PexMChamber';

	return Template;
}

function bool IsBreakthroughPexMChamberCostReductionAvailable()
{
	return IsFacilityCostReductionAvailable('PexMChamber');
}

static function X2DataTemplate CreateBreakthroughPexMChamberSecondCellCostReductionTemplate()
{
	local X2TechTemplate Template;

	Template = CreateBreakthroughTechTemplate('BreakthroughPexMChamberSecondCellCostReduction');
	Template.strImage = "img:///UILibrary_PexM.Tech_Images.BT_PexMChamber2";
	Template.ResearchCompletedFn = BreakthroughFacilityUpgradeDiscountCompleted;
	Template.GetValueFn = GetValueFacilityUpgradeCostReduction;

	Template.Requirements.SpecialRequirementsFn = IsBreakthroughPexMChamberSecondCellCostReductionAvailable;
	Template.RewardName = 'PexMChamber_SecondCell';

	return Template;
}

function bool IsBreakthroughPexMChamberSecondCellCostReductionAvailable()
{
	return IsFacilityUpgradeCostReductionAvailable('PexMChamber_SecondCell');
}

static function X2DataTemplate CreateBreakthroughPexMChamberTrainingCellCostReductionTemplate()
{
	local X2TechTemplate Template;

	Template = CreateBreakthroughTechTemplate('BreakthroughPexMChamberTrainingCellCostReduction');
	Template.strImage = "img:///UILibrary_PexM.Tech_Images.BT_PexMChamber3";
	Template.ResearchCompletedFn = BreakthroughFacilityUpgradeDiscountCompleted;
	Template.GetValueFn = GetValueFacilityUpgradeCostReduction;

	Template.Requirements.SpecialRequirementsFn = IsBreakthroughPexMChamberTrainingCellCostReductionAvailable;
	Template.RewardName = 'PexMChamber_TrainingCell';

	return Template;
}


function bool IsBreakthroughPexMChamberTrainingCellCostReductionAvailable()
{
	return IsFacilityUpgradeCostReductionAvailable('PexMChamber_TrainingCell') && class'X2StrategyElement_PexMFacilities'.default.bCanTrainPsiOffense;
}

//*******************************************************************************************
//*******************************************************************************************

//helper func			
//Template.Requirements.SpecialRequirementsFn = AreWeInThePexMChamber;
static function bool AreWeInThePexMChamber()
{
	if(default.bSkipPGExclusion)
	{
		`LOG("PexM Project Access :: ---- :: SkipPGExclusion Active",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
		return true;
	}

	//if the screen is not in the stack, assume we're not in the pexm facility buy menu
	if (`HQPRES.ScreenStack.IsNotInStack(class'UIChoosePexMProject'))
	{
       `LOG("PexM Project Access :: FAIL :: NOT In Chamber",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
		return false;
	}

	`LOG("PexM Project Access :: PASS :: In Chamber",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
	return true;
}
