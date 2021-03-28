//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	25/07/20    21:00
//	LAST UPDATED    18/01/21	17:45
//
// updates its resource display based upon the screen being shown;  Therefore, we need to create a listener which listens 
// for the Community Highlander event 'UpdateResources', so we can set up the resource display ourself.
//
//	FROM REDDOBES GRIM HORIZON FIX/ DARK EVENTS LIST WITH A TOUCH OF MAGIC FROM ABB AND RUSTY
//
//*******************************************************************************************
class X2EventListener_UIChoosePexM_Resources extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplate_UIChoosePexMResources());
	
	return Templates; 
}

static function CHEventListenerTemplate CreateListenerTemplate_UIChoosePexMResources()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'UIChoosePexMResources');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('UpdateResources', OnUIChoosePexMResources, ELD_Immediate);

	return Template;
}

static function EventListenerReturn OnUIChoosePexMResources(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local UIAvengerHUD			HUD;
    local UIScreen				CurrentScreen;
	local X2ItemTemplateManager	ItemMgr;

	HUD = `HQPRES.m_kAvengerHUD;
	CurrentScreen = `SCREENSTACK.GetCurrentScreen();
	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// KDM : We are only interested when our custom Screens are on the top of the screen stack.
	if ( ( CurrentScreen.Class.Name == 'UIChoosePexMProject') || ( CurrentScreen.Class.Name == 'UIInventory_PexM') )
	{
		// KDM : Display the same information a normal Screen would show.

		HUD.HideResources();				//hide resources while we tinker about with them
		HUD.ClearResources();				//reset the current display of this screen

		HUD.UpdateMonthlySupplies();
		HUD.UpdateSupplies();
        HUD.UpdateAlienAlloys();
        HUD.UpdateEleriumCrystals();
        HUD.UpdateEleriumCores();

		AddModResource(HUD, ItemMgr, 'InertMeld', "");	//add new resource from mod

        HUD.UpdateScientistScore();
        HUD.UpdateEngineerScore();

		HUD.ShowResources();				//show the new layout
	}

	return ELR_NoInterrupt;
}

//PULLED from DerBK's ABB !!	USE TO ADD A NEW RESOURCE TO THE BAR ... 
//THIS ENSURES HUD RESOURCE ELEMENTS ARE ALWAYS ADDED TO THE BAR IN THE SAME ORDER FOR A PERSONS GAME
static function AddModResource(UIAvengerHUD HUD, X2ItemTemplateManager ItemMgr, name ResourceName, string DisplayStr)
{
    local X2ItemTemplate    Template;
	local int				ResourceCount;

    //find a matching resource
    Template = ItemMgr.FindItemTemplate(ResourceName);

    //check if this item actually exists in this game !! and add it to the bar
    if (Template != none)
    {
		//find out how much of this item xcom has
       	ResourceCount = `XCOMHQ.GetResourceAmount(ResourceName);

        //create or find the correct string name
        if (DisplayStr == "")
        {
            DisplayStr = Template.AbilityDescName;

            //if it still blank use item name
            if (DisplayStr == "")
            {
                DisplayStr = Template.FriendlyName;
            }
        }

        //if name is STILL blank resort to hardcode error
        if (DisplayStr == "")
        {
            DisplayStr = class'UIUtilities_Text'.static.GetColoredText("ERROR", eUIState_Bad);
        }

        //actually add the resource display
	    HUD.AddResource(DisplayStr, class'UIUtilities_Text'.static.GetColoredText(string(ResourceCount), (ResourceCount > 0) ? eUIState_Normal : eUIState_Bad));
    }
	else
	{
		//report to the log if the item isn't found
		`LOG("ERROR :: NO ITEM TEMPLATE ::" @ResourceName @" :: DISPLAY ::" @DisplayStr , class'X2DownloadableContentInfo_PsionicsExMachina'.default.bEnablePexMLogging,'PsionicsExMachina');
	}
}
