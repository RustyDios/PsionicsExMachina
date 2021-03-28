//---------------------------------------------------------------------------------------
//  FILE:   X2Item_PsionicsExMachina.uc                                    
//
//	File created by MrCloista , Edited by RustyDios	
//
//	File created	25/07/20    21:00
//	LAST UPDATED    13/10/20	13:30
//
//  ADDS psi PCS && Attachments for psi amp weapons && inert meld
//
//---------------------------------------------------------------------------------------

class X2Item_PsionicsExMachina extends X2Item config (PsionicsExMachina_Abilities);

struct ConvertAbilityToPexM 
{
	var string Type;
	var name AbilityName;
	var int SellValue;
	var string ImagePath;
	var bool bCanBuild;
};

var config array<ConvertAbilityToPexM> AbilitiesToConvert;

var config array<name> RAPID_PSIONICS_VALID_ABILITIES;

//create the templates
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Resources;
    local X2AbilityTemplateManager  AbilityMgr;
	local int i;

    AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	Resources.AddItem(CreateInertMELD());

	//grab stuff from the config files and convert them!
	for (i = 0 ; i <= default.AbilitiesToConvert.length ; i++)
	{
		if(default.AbilitiesToConvert[i].Type == "PCS")
		{
			if(default.AbilitiesToConvert[i].bCanBuild)
			{
				Resources.AddItem(ConvertAbilityTo_PexM_PCS(default.AbilitiesToConvert[i].AbilityName, AbilityMgr, default.AbilitiesToConvert[i].SellValue, default.AbilitiesToConvert[i].ImagePath, 'Experimental_PexM_PCS'));
			}
			else
			{
				Resources.AddItem(ConvertAbilityTo_PexM_PCS(default.AbilitiesToConvert[i].AbilityName, AbilityMgr, default.AbilitiesToConvert[i].SellValue, default.AbilitiesToConvert[i].ImagePath, ''));
			}
		}

		if(default.AbilitiesToConvert[i].Type == "GEM")
		{
			if(default.AbilitiesToConvert[i].bCanBuild)
			{
				Resources.AddItem(ConvertAbilityTo_PexM_GEM(default.AbilitiesToConvert[i].AbilityName, AbilityMgr, default.AbilitiesToConvert[i].SellValue, default.AbilitiesToConvert[i].ImagePath, 'Experimental_PexM_GEM'));
			}
			else
			{
				Resources.AddItem(ConvertAbilityTo_PexM_GEM(default.AbilitiesToConvert[i].AbilityName, AbilityMgr, default.AbilitiesToConvert[i].SellValue, default.AbilitiesToConvert[i].ImagePath, ''));
			}

		}
	}

	//Some more GEMS for colour testing and perk text checking -quickly		NOT ADDED TO PROVING GROUND PROJECTS OR LOOT, but technically Part of 'Clarity Perk', all these are passives though
	Resources.AddItem(ConvertAbilityTo_PexM_GEM('PexM_TestBoost_Standard',	AbilityMgr,	1,	"UILibrary_PexM.Inventory.Gemstone_Purple", ''));
	Resources.AddItem(ConvertAbilityTo_PexM_GEM('PexM_TestBoost_Average',	AbilityMgr,	2,	"UILibrary_PexM.Inventory.Gemstone_Amber", ''));
	Resources.AddItem(ConvertAbilityTo_PexM_GEM('PexM_TestBoost_Gifted',	AbilityMgr,	3,	"UILibrary_PexM.Inventory.Gemstone_Green", ''));
	Resources.AddItem(ConvertAbilityTo_PexM_GEM('PexM_TestBoost_Genius',	AbilityMgr,	4,	"UILibrary_PexM.Inventory.Gemstone_Blue", ''));
	Resources.AddItem(ConvertAbilityTo_PexM_GEM('PexM_TestBoost_Savant',	AbilityMgr,	5,	"UILibrary_PexM.Inventory.Gemstone_Yellow", ''));

	return Resources;
}

// create dead gem/inert meld
static function X2DataTemplate CreateInertMELD()
{
	local X2ItemTemplate Template;

    `CREATE_X2TEMPLATE(class'X2ItemTemplate', Template, 'InertMeld');

    Template.strImage = "img:///UILibrary_PexM.Inventory.Gemstone_InertGrey";
    Template.strInventoryImage = "img:///UILibrary_PexM.Inventory.Gemstone_InertGrey";

	Template.LootStaticMesh = StaticMesh'UI_3D.Loot.EleriumCore';

    Template.ItemCat = 'resource';

	Template.TradingPostValue = 1;
	Template.Tier = 0;
	
	Template.StartingItem = true;
	Template.CanBeBuilt = false;
	Template.bInfiniteItem = false;
	Template.MaxQuantity = 999;

	//Template.bAlwaysRecovered = true;
	Template.RewardDecks.AddItem('InertMeld');
	//Template.ResourceTemplateName = 'InertMeld';	//this IS the resource !!
	//Template.ResourceQuantity = 1;

    return Template;
}

// Convert Psi Ability to PCS'
static function X2DataTemplate ConvertAbilityTo_PexM_PCS(name AbilityTemplate, X2AbilityTemplateManager AbilityMgr, int SellValue, string ImagePath, optional name AddToPGDeck)
{
	local X2EquipmentTemplate Template;
	local X2ItemTemplate DeadTemplate;

	local string TemplateName;
	local X2AbilityTemplate DonerTemplate;

	TemplateName = 'PCSPsi_' $AbilityTemplate; // It is important to give the prefix so that the UIInventory page for the Facility knows what to show :)

	DonerTemplate = AbilityMgr.FindAbilityTemplate(AbilityTemplate); // DONT move this AGAIN, you want name(TemplateName) passed in so you can add "PCSPsi_" to it

	if (DonerTemplate != none)
	{
		`CREATE_X2TEMPLATE(class'X2EquipmentTemplate', Template, name(TemplateName) );
		Template.LootStaticMesh = StaticMesh'UI_3D.Loot.AdventPCS';
		Template.strImage = "img:///"$ImagePath; // UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Psi //icon pre-exist
		Template.ItemCat = 'combatsim';
		Template.InventorySlot = eInvSlot_CombatSim;

		Template.TradingPostValue = SellValue;
		Template.bAlwaysUnique = false;
		//Template.bAlwaysRecovered = true;
		Template.Tier = 5;
		Template.StatBoostPowerLevel = -1;

		Template.Abilities.AddItem(AbilityTemplate);
		
		Template.StatsToBoost.AddItem(eStat_Will);
		Template.StatsToBoost.AddItem(eStat_PsiOffense);
		Template.bUseBoostIncrement = false;//percent bonus
		
		if (AddToPGDeck != '')
		{
			Template.RewardDecks.AddItem(AddToPGDeck);
		}
		
		//copy texts
		CopyAbilityLocalisationsToPCS(Template, DonerTemplate);
		Template.BlackMarketTexts = class'X2Item_DefaultResources'.default.PCSBlackMarketTexts;

		//add ability to the 'Clarity' abilities
		default.RAPID_PSIONICS_VALID_ABILITIES.AddItem(AbilityTemplate);

		`LOG("PCS Ability Conversion :: PASS :: " $TemplateName @" :: ImageResult :: " $Template.strImage @" :: Added to Deck :: " $AddToPGDeck ,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

		return Template;
	}
	else
	{
		`CREATE_X2TEMPLATE(class'X2ItemTemplate', DeadTemplate, name(TemplateName) );

		DeadTemplate.strImage = "img:///UILibrary_PexM.Inventory.Gemstone_InertGrey";
		DeadTemplate.strInventoryImage = "img:///UILibrary_PexM.Inventory.Gemstone_InertGrey";
		DeadTemplate.LootStaticMesh = StaticMesh'UI_3D.Loot.EleriumCore';
		DeadTemplate.ItemCat = 'utility';

		DeadTemplate.TradingPostValue = 1;
		DeadTemplate.Tier = 0;
	
		DeadTemplate.StartingItem = false;
		DeadTemplate.CanBeBuilt = false;
		DeadTemplate.bInfiniteItem = false;

		DeadTemplate.HideInInventory = true;

		DeadTemplate.MaxQuantity = 999;

		//DeadTemplate.bAlwaysRecovered = true;

   		DeadTemplate.RewardDecks.AddItem('InertMeld');
		DeadTemplate.ResourceTemplateName = 'InertMeld';
		DeadTemplate.ResourceQuantity = 10;

		DonerTemplate = AbilityMgr.FindAbilityTemplate('PexM_Meld'); // DONT move this AGAIN, you want name to change the doner template to MELD

		//copy texts
		CopyAbilityLocalisationsFromInert(DeadTemplate, DonerTemplate);

    	`LOG("PCS Ability Conversion :: FAIL :: " $TemplateName @" :: Extra Inert Meld Loot Template Created",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

		return DeadTemplate;
	}
}

// Convert Psi Ability to GEMS
static function X2DataTemplate ConvertAbilityTo_PexM_GEM(name AbilityTemplate, X2AbilityTemplateManager AbilityMgr, int SellValue, string PanelPath, optional name AddToPGDeck)
{
	local X2WeaponUpgradeTemplate Template;
	local X2ItemTemplate DeadTemplate;

	local string TemplateName;
	local X2AbilityTemplate DonerTemplate;

	TemplateName = 'GEM_' $AbilityTemplate; // It is important to give the prefix so that the UIInventory page for the Facility knows what to show :)

	DonerTemplate = AbilityMgr.FindAbilityTemplate(AbilityTemplate); // DONT move this AGAIN, you want name(TemplateName) passed in so you can add "GEM_" to it

	if (DonerTemplate != none)
	{

		`CREATE_X2TEMPLATE(class'X2WeaponUpgradeTemplate', Template, name(TemplateName) );
		
		Template.strImage = "img:///"$PanelPath;
		Template.ItemCat = 'upgrade';

		Template.LootStaticMesh = StaticMesh'UI_3D.Loot.WeapFragmentA';

		Template.TradingPostValue = SellValue;
		//Template.bAlwaysRecovered = true;
		Template.CanBeBuilt = false;
		Template.MaxQuantity = 1;
		Template.Tier = 1;

		Template.BonusAbilities.AddItem(AbilityTemplate);

		//add to project
		if (AddToPGDeck != '')
		{
			Template.RewardDecks.AddItem(AddToPGDeck);
		}
		
		Template.MutuallyExclusiveUpgrades.AddItem(name(TemplateName));	//All GEMS are singular fit only, mutually exclusive with themselves

		// Requires Highlander v1.20 or higher, issue237
		Template.CanApplyUpgradeToWeaponFn = CanApplyUpgradeToWeaponFn_OnlyPsiAmpsAllowed;
			
		// <> UPGRADE ICON VISUALS ETC <>
		//Template.AddUpgradeAttachment(Socket,UITag,MeshName,ProjectileName,MatchWeaponTemplate,AttachToPawn,OverlayIconName,InventoryIconName,InventorySSIcon)
		Template.AddUpgradeAttachment('', '', "", "", 'PsiAmp_CV', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'PsiAmp_MG', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'PsiAmp_BM', , "", Template.strImage, DonerTemplate.IconImage);

		Template.AddUpgradeAttachment('', '', "", "", 'ShardGauntlet_CV', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'ShardGauntlet_MG', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'ShardGauntlet_BM', , "", Template.strImage, DonerTemplate.IconImage);

		//support for Psionic Implants			https://steamcommunity.com/sharedfiles/filedetails/?id=2224463798
		Template.AddUpgradeAttachment('', '', "", "", 'OneMorePsiAmp_CV', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'OneMorePsiAmp_MG', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'OneMorePsiAmp_BM', , "", Template.strImage, DonerTemplate.IconImage);

		//support for  Chosen Reward Variety	 https://steamcommunity.com/sharedfiles/filedetails/?id=1619292810
		Template.AddUpgradeAttachment('', '', "", "", 'PsiAmp_Warlock', , "", Template.strImage, DonerTemplate.IconImage);

		//support for AR's Caster Gauntlets		https://steamcommunity.com/sharedfiles/filedetails/?id=2024073766
		Template.AddUpgradeAttachment('', '', "", "", 'CasterGauntlet_CV', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'CasterGauntlet_MG', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'CasterGauntlet_BM', , "", Template.strImage, DonerTemplate.IconImage);

		//support for PZ_Psionic_Melee			https://steamcommunity.com/sharedfiles/filedetails/?id=1549781357
		Template.AddUpgradeAttachment('', '', "", "", 'PsiShardGauntlet_CV', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'PsiShardGauntlet_MG', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'PsiShardGauntlet_BM', , "", Template.strImage, DonerTemplate.IconImage);

		//support for Playable Aliens 			https://steamcommunity.com/sharedfiles/filedetails/?id=1218007143
		Template.AddUpgradeAttachment('', '', "", "", 'SectoidAmp_CV', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'SectoidAmp_MG', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'SectoidAmp_BM', , "", Template.strImage, DonerTemplate.IconImage);

		//support for Biotic Class 				https://steamcommunity.com/sharedfiles/filedetails/?id=1125004715
		Template.AddUpgradeAttachment('', '', "", "", 'RM_BioAmp_CV', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'RM_BioAmp_MG', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'RM_BioAmp_BM', , "", Template.strImage, DonerTemplate.IconImage);

		//support for Necromancer Staves		https://steamcommunity.com/sharedfiles/filedetails/?id=1137913176
		Template.AddUpgradeAttachment('', '', "", "", 'Necro_Staff_WPN', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'Necro_Staff_L2_WPN', , "", Template.strImage, DonerTemplate.IconImage);
		Template.AddUpgradeAttachment('', '', "", "", 'Necro_Staff_L3_WPN', , "", Template.strImage, DonerTemplate.IconImage);

		//copy texts
		CopyAbilityLocalisationsToGEMS(Template, DonerTemplate);
		Template.BlackMarketTexts = class'X2Item_DefaultUpgrades'.default.UpgradeBlackMarketTexts;

		//add ability to the 'Clarity' abilities
		default.RAPID_PSIONICS_VALID_ABILITIES.AddItem(AbilityTemplate);

		`LOG("GEM Ability Conversion :: PASS :: " $TemplateName @" :: ImageResult :: " $Template.strImage @" :: Added to Deck :: " $AddToPGDeck ,class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

		return Template;
	}
	else
	{
		`CREATE_X2TEMPLATE(class'X2ItemTemplate', DeadTemplate, name(TemplateName) );

		DeadTemplate.strImage = "img:///UILibrary_PexM.Inventory.Gemstone_InertGrey";
		DeadTemplate.strInventoryImage = "img:///UILibrary_PexM.Inventory.Gemstone_InertGrey";
		DeadTemplate.LootStaticMesh = StaticMesh'UI_3D.Loot.EleriumCore';
		DeadTemplate.ItemCat = 'utility';

		DeadTemplate.TradingPostValue = 1;
		DeadTemplate.Tier = 0;
	
		DeadTemplate.StartingItem = false;
		DeadTemplate.CanBeBuilt = false;
		DeadTemplate.bInfiniteItem = false;

		DeadTemplate.HideInInventory = true;

		DeadTemplate.MaxQuantity = 999;

		//DeadTemplate.bAlwaysRecovered = true;

   		DeadTemplate.RewardDecks.AddItem('InertMeld');
		DeadTemplate.ResourceTemplateName = 'InertMeld';
		DeadTemplate.ResourceQuantity = 5;

		DonerTemplate = AbilityMgr.FindAbilityTemplate('PexM_Meld'); // DONT move this AGAIN, you want name to change the doner template to MELD

		//copy texts
		CopyAbilityLocalisationsFromInert(DeadTemplate, DonerTemplate);

    	`LOG("GEM Ability Conversion :: FAIL :: " $TemplateName @" :: Extra Inert Meld Loot Template Created",class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');

		return DeadTemplate;
	}
}

// Ensure GEMS can only attach to Psi Amps category		categories- see also dlcinfo canapply and stratelem breakthrough
// see also x2item, pexmampconvert above, x2item gem for icons
static function bool CanApplyUpgradeToWeaponFn_OnlyPsiAmpsAllowed(X2WeaponUpgradeTemplate UpgradeTemplate, XComGameState_Item Weapon, int SlotIndex)
{
	//support for PZ_Psionic_Melee			https://steamcommunity.com/sharedfiles/filedetails/?id=1549781357
	//support for Playable Aliens 			https://steamcommunity.com/sharedfiles/filedetails/?id=1218007143
	//support for Biotics Class				https://steamcommunity.com/sharedfiles/filedetails/?id=1125004715
	//support for Necromancer				https://steamcommunity.com/sharedfiles/filedetails/?id=1137913176

    if ( (Weapon.GetWeaponCategory() == 'psiamp' )
		|| (Weapon.GetWeaponCategory() == 'replace_psiamp' && class'X2DownloadableContentInfo_PsionicsExMachina'.default.bSupportPZMelee)
		|| (Weapon.GetWeaponCategory() == 'sectoidpsiamp' && class'X2DownloadableContentInfo_PsionicsExMachina'.default.bSupportPASectoid)
		|| (Weapon.GetWeaponCategory() == 'bioamp' && class'X2DownloadableContentInfo_PsionicsExMachina'.default.bSupportRMBiotic)
		|| (Weapon.GetWeaponCategory() == 'necrostaff' && class'X2DownloadableContentInfo_PsionicsExMachina'.default.bSupportNecromancers)
		|| (Weapon.GetWeaponCategory() == 'gauntlet' && class'X2DownloadableContentInfo_PsionicsExMachina'.default.bSupportTemplars)
		)	
    {
        return class'X2Item_DefaultUpgrades'.static.CanApplyUpgradeToWeapon(UpgradeTemplate, Weapon, SlotIndex);
    }
    else return false;
}

//copy localisation data from the ability, PCS ALSO get (+Stat, +Stat) added to Name by PCS scripts
static function CopyAbilityLocalisationsToPCS(out X2EquipmentTemplate Template, X2AbilityTemplate DonerTemplate)
{
	local X2AbilityTag AbilityTag;

	//expand to create the correct tags for cooldowns/name etc
	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = DonerTemplate; //AbilityState == None ? self : AbilityState;

	Template.FriendlyName ="<font color = '#b6b3e3'>PCS: "$DonerTemplate.LocFriendlyName $"</font>";
	Template.FriendlyNamePlural ="<font color = '#b6b3e3'>*****</font>PCS: "$DonerTemplate.LocFriendlyName$"</font>";
	Template.BriefSummary = `XEXPAND.ExpandString("<font color = '#b6b3e3'>*****</font>\n" $DonerTemplate.LocLongDescription $"\n<font color = '#b6b3e3'>*****</font>\n" $DonerTemplate.LocPromotionPopupText $"\n<font color = '#b6b3e3'>*****</font>\n");
	Template.LootTooltip = Template.FriendlyName;
	
	AbilityTag.ParseObj = none;

}

static function CopyAbilityLocalisationsToGEMS(out X2WeaponUpgradeTemplate Template, X2AbilityTemplate DonerTemplate)
{
	local X2AbilityTag AbilityTag;

	//expand to create the correct tags for cooldowns/name etc
	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = DonerTemplate; //AbilityState == None ? self : AbilityState;

	Template.FriendlyName ="<font color = '#b6b3e3'>GEM: "$DonerTemplate.LocFriendlyName $"</font>";
	Template.FriendlyNamePlural ="<font color = '#b6b3e3'>GEM: "$DonerTemplate.LocFriendlyName $"</font>";
	Template.BriefSummary = `XEXPAND.ExpandString("<font color = '#b6b3e3'>*****</font>\n" $DonerTemplate.LocLongDescription $"\n<font color = '#b6b3e3'>*****</font>\n" $DonerTemplate.LocPromotionPopupText $"\n<font color = '#b6b3e3'>*****</font>\n");
	Template.TinySummary = "Grants: "$DonerTemplate.LocFriendlyName;
	Template.LootTooltip = Template.TinySummary;

	AbilityTag.ParseObj = none;

}

static function CopyAbilityLocalisationsFromInert(out X2ItemTemplate Template, X2AbilityTemplate DonerTemplate)
{
	Template.FriendlyName ="<font color = '#b6b3e3'>"$DonerTemplate.LocFriendlyName $"</font>";
	Template.FriendlyNamePlural ="<font color = '#b6b3e3'>"$DonerTemplate.LocFriendlyName$"</font>";
	Template.BriefSummary = "<font color = '#b6b3e3'>*****</font>\n" $DonerTemplate.LocLongDescription $"\n<font color = '#b6b3e3'>*****</font>\n" $DonerTemplate.LocPromotionPopupText $"\n<font color = '#b6b3e3'>*****</font>\n";
	Template.LootTooltip = Template.FriendlyName;
}
