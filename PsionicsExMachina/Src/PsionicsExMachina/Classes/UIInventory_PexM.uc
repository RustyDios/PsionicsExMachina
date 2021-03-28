//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    07/08/20	18:00
//
//	DISPLAYS ALL GEMS AND PCSPSI ITEMS IN A LIST
//
//*******************************************************************************************
class UIInventory_PexM extends UIInventory;

var localized string m_strTitleBig;
var localized string m_strNoLoot;
var localized string m_strBuy; 

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	
	List.SetHeight(680);

	PopulateData();
	List.SetSelectedIndex(0, true);
	SetInventoryLayout();
	SetX(0);	//slide back over to the left :)

	HideQueue();	//technically doesn't work, but whatever
}

simulated function CloseScreen()
{
	Super.CloseScreen();

	ShowQueue();
}

simulated function PopulateData()
{
	local XComGameState_Item Item;
	local X2ItemTemplate ItemTemplate;
	local StateObjectReference ItemRef;
	local UIInventory_ListItem ListItem;
	local array<XComGameState_Item> InventoryItems;

	super.PopulateData();

	foreach XComHQ.Inventory(ItemRef)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
		if (Item == None || Item.GetMyTemplate() == None)
			continue;

		ItemTemplate = Item.GetMyTemplate();
		if((Item.HasBeenModified() || !ItemTemplate.bInfiniteItem) && !ItemTemplate.HideInInventory && ItemTemplate.HasDisplayData() &&
			!XComHQ.IsTechResearched(ItemTemplate.HideIfResearched) && !XComHQ.HasItemByName(ItemTemplate.HideIfPurchased))
		{
			//this is where we add STUFF we want to show 
			if ( (InStr(ItemTemplate.DataName, "GEM") != -1) || (InStr(ItemTemplate.DataName, "PCSPsi") != -1) || (InStr(ItemTemplate.DataName, "InertMeld") != -1) 
					|| (InStr(ItemTemplate.DataName, class'X2StrategyElement_PsionicsExMachina'.default.strCNV_RESOURCE_COST_TYPE[0]) != -1) )
			{
				InventoryItems.AddItem(Item);
			}
		}
	}

	InventoryItems.Sort(SortItemsAlpha);

	foreach InventoryItems(Item)
	{
		Spawn(class'UIInventory_ListItem', List.itemContainer).InitInventoryListItem(Item.GetMyTemplate(), Item.Quantity, Item.GetReference());
	}
	
	if(List.ItemCount > 0)
	{
		TitleHeader.SetText(m_strTitleBig,"");
		ListItem = UIInventory_ListItem(List.GetItem(0));
		PopulateItemCard(ListItem.ItemTemplate, ListItem.ItemRef);
	}
	else
	{
		TitleHeader.SetText(m_strTitleBig, m_strNoLoot);
		SetCategory("");
		SetBuiltLabel("");
	}
}

function int SortItemsAlpha(XComGameState_Item ItemA, XComGameState_Item ItemB)
{
	local X2ItemTemplate ItemTemplateA, ItemTemplateB;

	ItemTemplateA = ItemA.GetMyTemplate();
	ItemTemplateB = ItemB.GetMyTemplate();

	if (ItemTemplateA.GetItemFriendlyName() < ItemTemplateB.GetItemFriendlyName())
	{
		return 1;
	}
	else if (ItemTemplateA.GetItemFriendlyName() > ItemTemplateB.GetItemFriendlyName())
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

//bsg-jrebar (4.10.17): Overriding NavHelp for inventory
simulated function UpdateNavHelp()
{
	local UINavigationHelp NavHelp;

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(CloseScreen);
}
//bsg-jrebar (4.10.17): end

defaultproperties
{
	DisplayTag      = "UIBlueprint_PexMChamber";
	CameraTag       = "UIBlueprint_PexMChamber";
}