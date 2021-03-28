//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    07/08/20	18:30
//
//	FIXES UP THE ICON FOR PSI PCS'		CURRENTLY HAS OPTIONAL COLOURED VERSION
//
//*******************************************************************************************
class X2EventListener_PCSIcons_Fix_PexM extends X2EventListener;

//add the listener
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreatePCSIconsFix_PexM());

	return Templates;
}

//create the listener	OnGetPCSImage
static function X2EventListenerTemplate CreatePCSIconsFix_PexM()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'PCSIconsFix_PexM');

	Template.RegisterInTactical = true;		//listen during missions
	Template.RegisterInStrategy = true;		//listen during avenger

	//set to listen for event, do a thing, at this time
	Template.AddCHEvent('OnGetPCSImage', FixPCSIcons, ELD_Immediate, 42); //priority 42 to run after MOCX UI changes which set by the ability icon

	return Template;
}

//what does the listener do when it hears a call?
static function EventListenerReturn FixPCSIcons(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Item	ItemState;
	local XComLWTuple			Tuple;

	Tuple = XComLWTuple(EventData);
	ItemState = XComGameState_Item(Tuple.Data[0].o);

	//Add icons for the new PCS' no config option - these icons get added.Period.
	if (ItemState != none)
	{
		//Psi PCS = PsiOffense
		if (InStr(ItemState.GetMyTemplateName(), "PCSPsi", , true) != INDEX_NONE)
		{
			if (class'X2DownloadableContentInfo_PsionicsExMachina'.default.bRustyColoredPCSIcon)
			{
				Tuple.Data[1].s = "img:///UILibrary_PexM.Inventory.UIPerk_combatstim_psi";
			}
			else
			{
				Tuple.Data[1].s = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_CombatSim_Psi";
			}
		}

	}

	return ELR_NoInterrupt;
}
