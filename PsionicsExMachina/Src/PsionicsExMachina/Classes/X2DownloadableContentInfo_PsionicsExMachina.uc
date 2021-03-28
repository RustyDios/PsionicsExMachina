//---------------------------------------------------------------------------------------
//  FILE:   X2DownloadableContentInfo_PsionicsExMachina                                    
//
//	File created by MrCloista , Edited by RustyDios	
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    01/11/20	04:00
//
//  Adds the loot tables, trashes the old psi lab, adjusts base game psi amps, adjust psionics tech to require a priest and lost autopsy
//
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_PsionicsExMachina extends X2DownloadableContentInfo config (PsionicsExMachina);

var config array<LootTable> LootTables, LootEntry;

var config int Slots_PexMamp_CV, Slots_PexMamp_MG, Slots_PexMamp_BM, TechPsi_DaysToComplete;
var config name StartingPsiPerk;

var config array<name>	strTechPsi_COST_TYPE;
var config array<int>	iTechPsi_COST_AMOUNT;

var config bool bEnablePexMLogging, bTrashTheOldLab, bRustyColoredPCSIcon, bCommandersAvatarHasSavantClarity; //, bLimitToPsiOffenseUnit;
var config bool bSupportTemplars, bSupportPZMelee, bSupportChosenRewardVariety, bSupportPASectoid, bSupportRMBiotic, bSupportNecromancers;

var config array<name>	DisallowedClasses;
//var localized string  	m_strNeedsPsionicUnit;	//disused -- string for weapon equips

////////////////////////////////////////////////////////////////////////
//	ON LOADED GAME
////////////////////////////////////////////////////////////////////////

static event OnLoadedSavedGame()
{
	AddTechGameStates();
}

static event OnLoadedSavedGameToStrategy()
{
	AddTechGameStates();
}

static event InstallNewCampaign(XComGameState StartState){} //empty func

////////////////////////////////////////////////////////////////////////
//	OPTC MASTER
////////////////////////////////////////////////////////////////////////

static event OnPostTemplatesCreated()
{
    if(default.bTrashTheOldLab)
    {
        TrashTheOldPsiLab();
    }

    AdjustPsionicsTech();

    ConvertAmpToPexM('PsiAmp_CV', default.Slots_PexMamp_CV, default.StartingPsiPerk);
    ConvertAmpToPexM('PsiAmp_MG', default.Slots_PexMamp_MG, default.StartingPsiPerk);
    ConvertAmpToPexM('PsiAmp_BM', default.Slots_PexMamp_BM, default.StartingPsiPerk);

	if (default.bSupportTemplars)
	{
		ConvertAmpToPexM('ShardGauntlet_CV', default.Slots_PexMamp_CV, '');
		ConvertAmpToPexM('ShardGauntlet_MG', default.Slots_PexMamp_CV, '');
		ConvertAmpToPexM('ShardGauntlet_BM', default.Slots_PexMamp_CV, '');

		// support for Caster Gauntlets			https://steamcommunity.com/sharedfiles/filedetails/?id=2024073766
		ConvertAmpToPexM('CasterGauntlet_CV', default.Slots_PexMamp_CV, '');
		ConvertAmpToPexM('CasterGauntlet_MG', default.Slots_PexMamp_CV, '');
		ConvertAmpToPexM('CasterGauntlet_BM', default.Slots_PexMamp_CV, '');
	}

	//support for PZ_Psionic_Melee			https://steamcommunity.com/sharedfiles/filedetails/?id=1549781357
	//psi melee and shard gauntlets dont get fuse because they get rend :)
	if (default.bSupportPZMelee)
	{
    	ConvertAmpToPexM('PsiShardGauntlet_CV', default.Slots_PexMamp_CV, '');
    	ConvertAmpToPexM('PsiShardGauntlet_MG', default.Slots_PexMamp_MG, '');
    	ConvertAmpToPexM('PsiShardGauntlet_BM', default.Slots_PexMamp_BM, '');
	}

	//support for  Chosen Reward Variety	 https://steamcommunity.com/sharedfiles/filedetails/?id=1619292810
	if (default.bSupportChosenRewardVariety)
	{
    	ConvertAmpToPexM('PsiAmp_Warlock', default.Slots_PexMamp_BM+1, default.StartingPsiPerk);
	}

	//support for Playable Aliens 			https://steamcommunity.com/sharedfiles/filedetails/?id=1218007143
	//sectoid psi amp's are 'depleted' psi amps, designed to work for humans the sectoid can get no natural ability from the amp itself
	//this is purely because sectoids have fuse in their tree
	if (default.bSupportPASectoid)
	{
    	ConvertAmpToPexM('SectoidAmp_CV', default.Slots_PexMamp_CV -1, '');
    	ConvertAmpToPexM('SectoidAmp_MG', default.Slots_PexMamp_MG -1, '');
    	ConvertAmpToPexM('SectoidAmp_BM', default.Slots_PexMamp_BM -1, '');
	}

	//support for Biotics Class				https://steamcommunity.com/sharedfiles/filedetails/?id=1125004715
	//biotics already have a whole suite of powerful psionic abilities, but they have an 'implant'
	if (default.bSupportRMBiotic)
	{
    	ConvertAmpToPexM('RM_BioAmp_CV', default.Slots_PexMamp_CV -1, '');
    	ConvertAmpToPexM('RM_BioAmp_MG', default.Slots_PexMamp_MG -1, '');
    	ConvertAmpToPexM('RM_BioAmp_BM', default.Slots_PexMamp_BM -1, '');
	}

	//support for Necromancer Class			https://steamcommunity.com/sharedfiles/filedetails/?id=1137913176
	//necromancers already have a whole suite of powerful psionic abilities, but no fuse
	//they do however get a damn psi-amp as their only damn secondary... 
	if (default.bSupportNecromancers)
	{
    	ConvertAmpToPexM('Necro_Staff_WPN', default.Slots_PexMamp_CV -2, '');
    	ConvertAmpToPexM('Necro_Staff_L2_WPN', default.Slots_PexMamp_MG -2, '');
    	ConvertAmpToPexM('Necro_Staff_L3_WPN', default.Slots_PexMamp_BM -2, '');
	}

    AddLootTables();

	if (default.bCommandersAvatarHasSavantClarity)
	{
		AdjustCommandersAvatar();
	}

	//SUPPORT FOR LWOTC PISTOL SLOT, NOT WORKING REMOVED
	//if (IsModInstalled('LongWarOfTheChosen'))
	//{
	//	JailbreakLWPistolSlot();
	//}
}

////////////////////////////////////////////////////////////////////////
//	CHL HOOK requires CHL v 1.21 or higher
//	Called from XComGameState_HeadquartersXCom
//	lets mods add their own events to the event queue when the player is at the Avenger or the Geoscape
////////////////////////////////////////////////////////////////////////

static function bool GetDLCEventInfo(out array<HQEvent> arrEvents)
{
	GetPexMHQEvents(arrEvents);
	return true; //returning true will tell the game to add the events have been added to the above array
}

static function GetPexMHQEvents(out array<HQEvent> arrEvents)
{
	class'XComGameState_HeadquartersProjectPexM'.static.GetAllPexMProjects(arrEvents);
}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO TRASH THE ORIGINAL PSILAB, MAY ALSO BE DONE IN OTHER MODS
//	NAMELY ADVENT AVENGERS PSIONICS FROM START
////////////////////////////////////////////////////////////////////////

static function TrashTheOldPsiLab()
{
    local X2StrategyElementTemplateManager  AllStratElements;
    local X2GameplayMutatorTemplate         FakeTemplate;

    AllStratElements = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

    // Disable the PSI Labs.
    `CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', FakeTemplate, 'PsiChamber');
        FakeTemplate.Category = "None";
        AllStratElements.AddStrategyElementTemplate(FakeTemplate, true);
   
    // Just in case. Difficulty modifiers.
    `CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', FakeTemplate, 'PsiChamber_Diff_0');
        FakeTemplate.Category = "None";
        AllStratElements.AddStrategyElementTemplate(FakeTemplate, true);
    `CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', FakeTemplate, 'PsiChamber_Diff_1');
        FakeTemplate.Category = "None";
        AllStratElements.AddStrategyElementTemplate(FakeTemplate, true);
    `CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', FakeTemplate, 'PsiChamber_Diff_2');
        FakeTemplate.Category = "None";
        AllStratElements.AddStrategyElementTemplate(FakeTemplate, true);
    `CREATE_X2TEMPLATE(class'X2GameplayMutatorTemplate', FakeTemplate, 'PsiChamber_Diff_3');
        FakeTemplate.Category = "None";
        AllStratElements.AddStrategyElementTemplate(FakeTemplate, true);
    
    `LOG("Psionics Ex Machina just burned the OLD Psi Lab schematics",default.bEnablePexMLogging,'PsionicsExMachina');

}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO ADJUST MAIN PSIONICS TECH
////////////////////////////////////////////////////////////////////////

static function AdjustPsionicsTech()
{
    local X2StrategyElementTemplateManager  AllStratElements;
   	local X2StrategyElementTemplate         CurrentStrat;
	local X2TechTemplate                    CurrentTech;
    local StrategyRequirement               AltReq1, AltReq2;

	local int i;
	local ArtifactCost Resources;

    AllStratElements = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

    CurrentStrat = AllStratElements.FindStrategyElementTemplate('Psionics');
    if (X2TechTemplate (CurrentStrat) != none)
    {
        CurrentTech = X2TechTemplate (CurrentStrat);

        CurrentTech.PointsToComplete = class'X2StrategyElement_DefaultTechs'.static.StafferXDays(1, default.TechPsi_DaysToComplete);

        //reset the requirements
        CurrentTech.Requirements.RequiredTechs.Length = 0;

        CurrentTech.Requirements.RequiredTechs.AddItem('AutopsySectoid');

        //Alternative requirement
        AltReq1.RequiredTechs.AddItem('AutopsyAdventPriest');
        AltReq2.RequiredTechs.AddItem(class'X2StrategyElement_PsionicsExMachina'.default.CONVERT_AutopsyName);
            CurrentTech.AlternateRequirements.AddItem(AltReq1);
            CurrentTech.AlternateRequirements.AddItem(AltReq2);

        //reset the costs
        CurrentTech.Cost.ResourceCosts.Length = 0;

        // Costs	Code forloop taken from Iridar, looks for arrays in the config file and cycles through them adding the costs
        // default costs are 5 Elerium Dust
        for (i = 0; i < default.strTechPsi_COST_TYPE.Length; i++)
        {
            if (default.iTechPsi_COST_AMOUNT[i] > 0)
            {
                Resources.ItemTemplateName = default.strTechPsi_COST_TYPE[i];
                Resources.Quantity = default.iTechPsi_COST_AMOUNT[i];
                CurrentTech.Cost.ResourceCosts.AddItem(Resources);
            }
        }

    	`LOG("Psionics Ex Machina adjusted the Psionics Tech",default.bEnablePexMLogging,'PsionicsExMachina');
	}
}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO CONVERT PSIAMPS TO PEXM - ADDS SLOTS AND ABILITY
////////////////////////////////////////////////////////////////////////

static function ConvertAmpToPexM(name TemplateName, int NumSlots, name AbilityName)
{
    local X2ItemTemplateManager ItemTemplateMgr;
    local X2DataTemplate        Template;

    local X2WeaponTemplate      	WeaponTemplate;
	local X2PairedWeaponTemplate	PairedWeaponTemplate;

    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	Template = ItemTemplateMgr.FindItemTemplate(TemplateName);

	WeaponTemplate = X2WeaponTemplate(Template);
	if (WeaponTemplate != none)
	{
		WeaponTemplate.NumUpgradeSlots = NumSlots;
		WeaponTemplate.Abilities.Additem(AbilityName);

		`LOG("Psionics Ex Machina adjusted amp :: " @TemplateName @" :: Slots :: " @NumSlots @" :: Free Ability :: " @AbilityName,default.bEnablePexMLogging,'PsionicsExMachina');
	}
	
	//support for PZ_Psionic_Melee			https://steamcommunity.com/sharedfiles/filedetails/?id=1549781357
	//psi melee and shard gauntlets dont get fuse because they get rend :)
	PairedWeaponTemplate = X2PairedWeaponTemplate(Template);
	if (PairedWeaponTemplate != none)
	{
		PairedWeaponTemplate.NumUpgradeSlots = NumSlots;
		PairedWeaponTemplate.Abilities.AddItem(AbilityName);	

		`LOG("Psionics Ex Machina adjusted amp :: " @TemplateName @" :: Slots :: " @NumSlots @" :: Free Ability :: " @AbilityName,default.bEnablePexMLogging,'PsionicsExMachina');
	}
}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO ADD PEXM PSI AMPS AND GEMS 
//	categories- see also x2item canapply and stratelem breakthrough
////////////////////////////////////////////////////////////////////////

static function bool CanWeaponApplyUpgrade(XComGameState_Item WeaponState, X2WeaponUpgradeTemplate UpgradeTemplate)
{
	//support for PZ_Psionic_Melee			https://steamcommunity.com/sharedfiles/filedetails/?id=1549781357
	//support for Playable Aliens 			https://steamcommunity.com/sharedfiles/filedetails/?id=1218007143
	//support for Biotics Class				https://steamcommunity.com/sharedfiles/filedetails/?id=1125004715
	//support for Necromancer				https://steamcommunity.com/sharedfiles/filedetails/?id=1137913176

    if ( (WeaponState.GetWeaponCategory() == 'psiamp' )
		|| (WeaponState.GetWeaponCategory() == 'replace_psiamp' && default.bSupportPZMelee)
		|| (WeaponState.GetWeaponCategory() == 'sectoidpsiamp' && default.bSupportPASectoid)
		|| (WeaponState.GetWeaponCategory() == 'bioamp' && default.bSupportRMBiotic)
		|| (WeaponState.GetWeaponCategory() == 'necrostaff' && default.bSupportNecromancers)
		|| (WeaponState.GetWeaponCategory() == 'gauntlet' && default.bSupportTemplars)
		)	
    {
        if ( InStr(UpgradeTemplate.DataName, "GEM_") != INDEX_NONE )
        {
            return true;
        }
        else return false;
    }
    else return true;
}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO ADD PEXM LOOT TABLES
////////////////////////////////////////////////////////////////////////

static function AddLootTables()
{
	local X2LootTableManager	LootManager;
	local LootTable				LootBag;
	local LootTableEntry		Entry;
	
	LootManager = X2LootTableManager(class'Engine'.static.FindClassDefaultObject("X2LootTableManager"));

	foreach default.LootEntry(LootBag)
	{
		if ( LootManager.default.LootTables.Find('TableName', LootBag.TableName) != INDEX_NONE )
		{
			foreach LootBag.Loots(Entry)
			{
				class'X2LootTableManager'.static.AddEntryStatic(LootBag.TableName, Entry, false);
			}
		}	
	}
}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO ADD SAVANT CLARITY TO THE COMMANDERS AVATAR
////////////////////////////////////////////////////////////////////////

static function AdjustCommandersAvatar()
{
	local X2CharacterTemplate			Template;
	local X2CharacterTemplateManager	ChrMgr;

	//KAREN !! list of all character templates
	ChrMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	//find the template
	Template = ChrMgr.FindCharacterTemplate('AdvPsiWitchM2');

	//ensure the template exists
	if (Template != none)
	{
		//add the abilities
		Template.Abilities.AddItem('PexM_TestBoost_Savant');

		//output patch to log
		`LOG("Commanders Template Patched With Clarity" , default.bEnablePexMLogging,'PsionicsExMachina');
	}
}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO ADD TECHS FOR THE PEXM GROUNDS
////////////////////////////////////////////////////////////////////////

static function AddTechGameStates()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local X2TechTemplate TechTemplate;
	local X2StrategyElementTemplateManager	StratMgr;

	//This adds the techs to games that installed the mod in the middle of a campaign.
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	History = `XCOMHISTORY;	

	//Create a pending game state change
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding PexM Tech Templates");

	//Find tech templates
	if ( !IsResearchInHistory('Tech_PexM_PCS') )
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('Tech_PexM_PCS'));
		NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
	}

	if ( !IsResearchInHistory('Tech_PexM_GEMS') )
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('Tech_PexM_GEMS'));
		NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
	}

	if ( !IsResearchInHistory('Tech_PexM_CONVERT') )
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('Tech_PexM_CONVERT'));
		NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
	}

	//Find Breakthroughs
	if ( !IsResearchInHistory('BreakthroughPsiAmpWeaponUpgrade') )
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('BreakthroughPsiAmpWeaponUpgrade'));
		NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
	}

	if ( !IsResearchInHistory('BreakthroughPexMChamberCostReduction') )
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('BreakthroughPexMChamberCostReduction'));
		NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
	}

	if ( !IsResearchInHistory('BreakthroughPexMChamberSecondCellCostReduction') )
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('BreakthroughPexMChamberSecondCellCostReduction'));
		NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
	}

	if ( !IsResearchInHistory('BreakthroughPexMChamberTrainingCellCostReduction') )
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate('BreakthroughPexMChamberTrainingCellCostReduction'));
		if (class'X2StrategyElement_PexMFacilities'.default.bCanTrainPsiOffense )
		{
			NewGameState.CreateNewStateObject(class'XComGameState_Tech', TechTemplate);
		}
	}

    `LOG("Psionics Ex Machina techs checked and added if required",default.bEnablePexMLogging,'PsionicsExMachina');

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		//Commit the state change into the history.
		History.AddGameStateToHistory(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}
}

static function bool IsResearchInHistory(name ResearchName)
{
	// Check if we've already injected the tech templates
	local XComGameState_Tech	TechState;
	
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if ( TechState.GetMyTemplateName() == ResearchName )
		{
			return true;
		}
	}
	return false;
}

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO FIND ABILITY FROM COMBAT INTELLIGENCE
// 	Soldier Com Int states	
//		eComInt_Standard,	eComInt_AboveAverage,
//		eComInt_Gifted,		eComInt_Genius,			eComInt_Savant,
////////////////////////////////////////////////////////////////////////
static function name GetPsiAbilityFromUnitComInt(XComGameState_Unit Unit)
{
	local name AbilityName;
	local ECombatIntelligence	Brain;

	Brain = Unit.ComInt;

	switch( Brain )
		{
			case eComInt_Savant:		AbilityName = 'PexM_TestBoost_Savant';		break;
			case eComInt_Genius:		AbilityName = 'PexM_TestBoost_Genius';		break;
			case eComInt_Gifted:		AbilityName = 'PexM_TestBoost_Gifted';		break;
			case eComInt_AboveAverage:	AbilityName = 'PexM_TestBoost_Average';		break;
			case eComInt_Standard:		AbilityName = 'PexM_TestBoost_Standard';	break;
			default:					AbilityName = 'PexM_TestBoost_Error';		break;
		}
	
	return AbilityName;
}

////////////////////////////////////////////////////////////////////////
//  FUNCTION TO ALLOW TRAINED SOLDIERS TO USE PSIONIC WEAPONS
//  NOT RELIANT ON XCOMCLASSDATA.INI CHANGES !!
//  MANY THANKS TO IRIDAR AND SOLARNOUGAT AND ROBOJUMPER
//  **** NOT WORKING -- CRASHES ON (ROBOJUMPERS) SQUAD SELECT ON ANY CHANGE TO SOLDIER LINEUP ****
//  **** WORKS FINE IN ARMOURY *****
////////////////////////////////////////////////////////////////////////
/*
static function bool CanAddItemToInventory_CH_Improved( out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason, optional XComGameState_Item ItemState)
{
    local name PsiAbilityName;
    local array<name> PSI_IDENTIFIER_SKILLS;
 
    local bool OverrideNormalBehavior;
    local bool DoNotOverrideNormalBehavior;
 
    OverrideNormalBehavior = CheckGameState != none;        //change things
    DoNotOverrideNormalBehavior = CheckGameState == none;   //not change things
 
 
    if(DisabledReason != "")
    {
        return DoNotOverrideNormalBehavior; 
    }
 
    //Check/confirm slot
    if (Slot != eInvSlot_PrimaryWeapon)
    {
        return DoNotOverrideNormalBehavior; 
    }

    //check confirm weapons
    if (ItemTemplate.DataName != 'Weapon_AshXcomPsionicReaper' || ItemTemplate.DataName != 'GatlingVorpalRifle_XC') 
    {
        return DoNotOverrideNormalBehavior; 
    }

    //check/confirm class
    if (   UnitState.GetSoldierClassTemplateName() == 'Templar' 
        || UnitState.GetSoldierClassTemplateName() == 'Stormrider' 
        || UnitState.GetSoldierClassTemplateName() == 'Samurai' 
        || UnitState.GetSoldierClassTemplateName() == 'Jedi'
        || UnitState.GetSoldierClassTemplateName() == 'Akimbo'
        )
    {
        //not a class we're interested in -- do nothing (not equip, or as per classdata.ini)
        return DoNotOverrideNormalBehavior;
    }

    //create the psi identifier array
    PSI_IDENTIFIER_SKILLS.AddItem('PexM_TestBoost_Standard');
    PSI_IDENTIFIER_SKILLS.AddItem('PexM_TestBoost_Average');
    PSI_IDENTIFIER_SKILLS.AddItem('PexM_TestBoost_Gifted');
    PSI_IDENTIFIER_SKILLS.AddItem('PexM_TestBoost_Genius');
    PSI_IDENTIFIER_SKILLS.AddItem('PexM_TestBoost_Savant');

    //check/confirm psi training skills
    foreach PSI_IDENTIFIER_SKILLS(PsiAbilityName) 
    {
        if (UnitState.HasSoldierAbility(PsiAbilityName, true))
        {
            `LOG("Weapon Equip Override for soldier :: " @UnitState.GetFullName() @" :: Psi Skill Confirmed :: " @PsiAbilityName @" :: Weapon :: " @ItemTemplate.DataName,default.bEnablePexMLogging,'PsionicsExMachina');
            //slot correct, class correct, weapon correct, psi ability correct -- allow equip
            bCanAddItem = 1;
            return OverrideNormalBehavior;
        }

        //slot correct, weapon correct, psi ability not -- disable equip
        DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(default.m_strNeedsPsionicUnit);
    }
 
    if (DisabledReason != "")
    {
        bCanAddItem = 0;
        return OverrideNormalBehavior;
    }

    //not an item or slot or class or ability we're interested in -- do nothing
    return DoNotOverrideNormalBehavior;
}
*/

////////////////////////////////////////////////////////////////////////
//	FUNCTION TO ADD PEXM PSI AMPS TO PISTOL SLOTS FOR LWOTC ONLY
//	ENTIRE THING DOESN'T 'WORK'		LWOTC LOCKS THE PISTOL SLOT
//	LWOTC FILES:	x2eventListener_soldiers.uc line 968ish, CannotEditSlots.AddItem(eInvSlot_Pistol);
//	LWOTC FILES:	CHItemSlot_PistolSlot_LW.uc
//	LWOTC FILES:	LW_Overhaul.ini
////////////////////////////////////////////////////////////////////////
/*static function bool CanAddItemToInventory_CH_Improved(out int bCanAddItem, const EInventorySlot Slot, const X2ItemTemplate ItemTemplate, int Quantity, XComGameState_Unit UnitState, optional XComGameState CheckGameState, optional out string DisabledReason, optional XComGameState_Item ItemState)
{
    local X2WeaponTemplate                    WeaponTemplate;
    local XGParamTag                          LocTag;
    local bool                                OverrideNormalBehavior;
    local bool                                DoNotOverrideNormalBehavior;
 
    OverrideNormalBehavior = CheckGameState != none;
    DoNotOverrideNormalBehavior = CheckGameState == none;
	if (IsModInstalled('LongWarOfTheChosen'))
	{	
		if(DisabledReason != "")
		return DoNotOverrideNormalBehavior; 
	
		WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	
		if(WeaponTemplate != none && Slot == eInvSlot_Pistol )
		{
			if(WeaponTemplate.WeaponCat == 'pistol' || WeaponTemplate.WeaponCat == 'psiamp')
			{
				`LOG("CAITICHI DETECTED LWOTC :: WEAPON AND SLOT PASS",default.bEnablePexMLogging,'PsionicsExMachina');
				bCanAddItem = 1; //0

				return OverrideNormalBehavior; //DoNotOverrideNormalBehavior;
			}
			else
			{
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = UnitState.GetSoldierClassTemplate().DisplayName;
		
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(class'UIArmory_Loadout'.default.m_strUnavailableToClass));
	
			bCanAddItem = 0;
	
			return OverrideNormalBehavior;
			}
		}
		return DoNotOverrideNormalBehavior;
	}
}

static function JailbreakLWPistolSlot()
{
	local CHItemSlot		SlotTemplate;
	local array<CHItemSlot> AllSlots;
	local CHItemSlotStore	SlotMgr;
	local int s;

	//EInventorySlot Slot = eInvSlot_Pistol

	if (IsModInstalled('LongWarOfTheChosen'))
	{	
		SlotMgr = class'CHItemSlotStore'.static.GetStore();
		AllSlots = SlotMgr.GetAllSlotTemplates();

		`LOG("LW Jailbreak Pistol Slot RAN " ,default.bEnablePexMLogging,'PsionicsExMachina');

		SlotTemplate = SlotMgr.GetSlot(eInvSlot_Pistol);
		`LOG("LW Jailbreak Slots Inv Slot" @SlotTemplate.InvSlot,default.bEnablePexMLogging,'PsionicsExMachina');
		`LOG("LW Jailbreak Slots DataName" @SlotTemplate.DataName,default.bEnablePexMLogging,'PsionicsExMachina');
		`LOG("LW Jailbreak Slots Template" @SlotTemplate.GetDisplayName(),default.bEnablePexMLogging,'PsionicsExMachina');
		`LOG("LW Jailbreak Slots Template" @SlotTemplate.GetDisplayLetter(),default.bEnablePexMLogging,'PsionicsExMachina');

		SlotTemplate.CanAddItemToSlotFn = CanAddItemToPistolSlot_PEXM;   // Overridden by CanAddItemToInventory_CH_Improved apparently
		SlotTemplate.ShowItemInLockerListFn = ShowPistolItemInLockerList_PEXM;

		`LOG("LW Jailbreak Pistol Slot DONE " ,default.bEnablePexMLogging,'PsionicsExMachina');
	}
}

//apperently overriden by CanAddItemToInventory_CH_Improved ABOVE
static function bool CanAddItemToPistolSlot_PEXM( CHItemSlot Slot, XComGameState_Unit UnitState, X2ItemTemplate Template, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{    
    //local X2WeaponTemplate WeaponTemplate;

    //WeaponTemplate = X2WeaponTemplate(Template);
    //if (WeaponTemplate != none)
    //{
	//	if (default.LWOTCPistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE || default.LWOTCPistolTemplates.Find(WeaponTemplate.DataName) !=INDEX_NONE)
	//	{
			`LOG("LW Jailbreak Slot CanAdd true" ,default.bEnablePexMLogging,'PsionicsExMachina');
        	return true;
	//	}
    //}
    //return false;
}

static function bool ShowPistolItemInLockerList_PEXM( CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, X2ItemTemplate ItemTemplate, XComGameState CheckGameState)
{
    local X2WeaponTemplate WeaponTemplate;

    WeaponTemplate = X2WeaponTemplate(ItemTemplate);
    if (WeaponTemplate != none)
    {
		if (default.LWOTCPistolCategories.Find(WeaponTemplate.WeaponCat) != INDEX_NONE || default.LWOTCPistolTemplates.Find(WeaponTemplate.DataName) !=INDEX_NONE)
		{
			`LOG("LW Jailbreak Slot show true" ,default.bEnablePexMLogging,'PsionicsExMachina');
        	return true;
		}
    }
    return false;
}

////////////////////////////////////////////////////////////////////////
//	Helpers	// Robojumper code from a discord post. Great stuff.
////////////////////////////////////////////////////////////////////////

static function bool IsModInstalled(name ModNameIdentifier)
{
	local XComOnlineEventMgr EventManager;
	local int i;

	EventManager = `ONLINEEVENTMGR;
	for(i = EventManager.GetNumDLC() - 1; i >= 0; i--)
	{
		if(EventManager.GetDLCNames(i) == ModNameIdentifier)
		{
			return true;
		}
	}
	return false;
}
*/
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
// RUSTY CHEATS FOR TESTING
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

exec function RustyFix_ToolBox_PexM()
{
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_Fortress", 2);
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_Solace", 2);
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_Sustain", 2);
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_TargetDefinition", 2);

	RustyFix_PsionicsToolBox_AddItem("PCSPsi_BS_Unstable", 2);
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_BS_PsionicAtrophy", 2);
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_BS_BattleMeditation", 2);
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_BS_MindOverMatter", 2);
	RustyFix_PsionicsToolBox_AddItem("PCSPsi_BS_MindThief", 2);

	RustyFix_PsionicsToolBox_AddItem("GEM_Insanity", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_SoulSteal", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_Stasis", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_StasisShield", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_Inspire", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_SoulFire", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_Domination", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_NullLance", 2);
    RustyFix_PsionicsToolBox_AddItem("GEM_VoidRift", 2);

	RustyFix_PsionicsToolBox_AddItem("GEM_BS_MCDetonate", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_BS_StrainMind", 2);

	RustyFix_PsionicsToolBox_AddItem("GEM_IRI_PsiReanimation", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_IRI_Soulmerge", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_IRI_Soulstorm", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_IRI_Nullward", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_IRI_PhaseWalk", 2);
    
	RustyFix_PsionicsToolBox_AddItem("InertMeld", 20);
	RustyFix_PsionicsToolBox_AddItem("GEM_PexM_TestBoost_Standard", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_PexM_TestBoost_Average", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_PexM_TestBoost_Gifted", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_PexM_TestBoost_Genius", 2);
	RustyFix_PsionicsToolBox_AddItem("GEM_PexM_TestBoost_Savant", 2);

}

static function RustyFix_PsionicsToolBox_AddItem(string strItemTemplate, optional int Quantity = 1, optional bool bLoot = false)
{
	local X2ItemTemplateManager ItemManager;
	local X2ItemTemplate ItemTemplate;
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersXCom HQState;
	local XComGameStateHistory History;
	local bool bWasInfinite;

	ItemManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemManager.FindItemTemplate(name(strItemTemplate));

	if (ItemTemplate == none)
	{
		`log("No item template named" @ strItemTemplate @ "was found.",, 'PsionicsExMachina');
		return;
	}

	if (ItemTemplate.bInfiniteItem)
	{
		bWasInfinite = true;
		ItemTemplate.bInfiniteItem = false;
	}

	History = `XCOMHISTORY;
	HQState = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	`assert(HQState != none);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Item Cheat: Create Item");
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	ItemState.Quantity = Quantity;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Add Item Cheat: Complete");
	HQState = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(HQState.Class, HQState.ObjectID));
	HQState.PutItemInInventory(NewGameState, ItemState, bLoot);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	`log("Added item" @ strItemTemplate @ "object id" @ ItemState.ObjectID,,'PsionicsExMachina');

	if (bWasInfinite)
	{
		ItemTemplate.bInfiniteItem = true;
	}
}

exec function RustyFix_ToolBox_PexM_DumpRapidClarityList()
{
	local array<name> PSIONICS_VALID_ABILITIES;
	local int i;

    PSIONICS_VALID_ABILITIES = class'X2Item_PsionicsExMachina'.default.RAPID_PSIONICS_VALID_ABILITIES;

	for (i = 0 ; i <= PSIONICS_VALID_ABILITIES.length ; i++)
	{
		`log("Validated List :: " @i @" :: " @PSIONICS_VALID_ABILITIES[i],,'PsionicsExMachina_Clarity');
	}
}


// colorize name and hair/eyes
exec function RustyFix_ToolBox_PexM_PsionColours(bool bRustyPsi = true, bool bAndCosmetics = false)
{
	local XComGameStateHistory				History;
	local UIArmory							Armory;
	local StateObjectReference				UnitRef;
	local XComGameState_Unit				UnitState;
	local XComGameState						NewGameState;
	local XComGameState_HeadquartersXCom	XComHQ;

	local string fName, lName, nName;

	History = `XCOMHISTORY;

	Armory = UIArmory(`SCREENSTACK.GetFirstInstanceOf(class'UIArmory'));
	if (Armory == none)
	{
		return;
	}

	UnitRef = Armory.GetUnitRef();
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
	if (UnitState == none)
	{
		return;
	}
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Psionic Soldier Colours");
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));

	if (bRustyPsi)
	{
		fName = "<font color='#B6B3E3'>" $ UnitState.GetFirstName() $ "</font>";
		lName = "<font color='#B6B3E3'>" $ UnitState.GetLastName() $ "</font>";
		nName = UnitState.GetNickName();
	}
	else
	{
		fName = "<font color='#C08EDA'>" $ UnitState.GetFirstName() $ "</font>";
		lName = "<font color='#C08EDA'>" $ UnitState.GetLastName() $ "</font>";
		nName = UnitState.GetNickName();
	}

	UnitState.SetUnitName(fName, lName, nName);

	if(bAndCosmetics)
	{
		//Default psi operative colors
		UnitState.kAppearance.iHairColor = 25;
		UnitState.kAppearance.iEyeColor = 19;
	}

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	Armory.PopulateData();
}
