//*******************************************************************************************
//  FILE:   Psionics Ex Machina. stuff                                 
//  
//	File created	01/10/20    06:00
//	LAST UPDATED    01/10/20    23:00
//
//  This listener uses a CHL event to set the status in the barracks correctly
//  uses CHL issue #322 ((also needs a config setting in xcomgame.ini xcomgame.chhelpers ?? ))
//
//*******************************************************************************************
class X2EventListener_StatusOfPexMTraining extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListenerTemplate_StatusOfPexMTraining());
	
	return Templates; 
}

static function CHEventListenerTemplate CreateListenerTemplate_StatusOfPexMTraining()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'StatusOfPexMTraining');

	Template.RegisterInTactical = false;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('OverridePersonnelStatus', OnStatusOfPexMTraining, ELD_Immediate);

	return Template;
}

/*
//FOR REF/INFO ONLY called in UiUtilities_Strategy 
static function TriggerOverridePersonnelStatus(XComGameState_Unit Unit,	out string Status, out EUIState eState,	out string TimeLabel, out string TimeValueOverride,	out int TimeNum, out int HideTime, out int DoTimeConversion)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverridePersonnelStatus';
	OverrideTuple.Data.Add(7);
	OverrideTuple.Data[0].s = Status;
	OverrideTuple.Data[1].s = TimeLabel;
	OverrideTuple.Data[2].s = TimeValueOverride;
	OverrideTuple.Data[3].i = TimeNum;
	OverrideTuple.Data[4].i = int(eState);
	OverrideTuple.Data[5].b = HideTime != 0;
	OverrideTuple.Data[6].b = DoTimeConversion != 0;

	`XEVENTMGR.TriggerEvent('OverridePersonnelStatus', OverrideTuple, Unit);

}
*/
static function EventListenerReturn OnStatusOfPexMTraining(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComLWTuple           Tuple;
    local XComGameState_Unit    UnitState;

	local XComGameState_HeadquartersProjectPexMTraining PexMProjectTraining;

    Tuple = XComLWTuple(EventData);
    UnitState = XComGameState_Unit(EventSource);

    //grab the training prject from the facility
    PexMProjectTraining = class'X2StrategyElement_PexMFacilities'.static.GetPexMProjectFromFacility();

    //if the training project exists, and this unit = the unit in training
	if (PexMProjectTraining != none && UnitState.ObjectID == PexMProjectTraining.ProjectFocus.ObjectID)
    {
        Tuple.Data[0].s = class'UIFacility_PexMLabSlot'.default.m_strPexMTrainingDialogTitle;                                       //status string
        Tuple.Data[1].s = class'UIUtilities_Text'.static.GetDaysString( FCeil(float(PexMProjectTraining.GetCurrentNumHoursRemaining() ) / 24.0) ); //time string ... get hours/24, rounded up to int, convert to day/days
        Tuple.Data[2].s = "";                                                                                                       //time value override
        Tuple.Data[3].i = PexMProjectTraining.GetCurrentNumHoursRemaining() ;                                                       //time number, days/hrs
        Tuple.Data[4].i = eUIState_Psyonic;                                                                                         //colour from EUI State - see UI Utilities_Colours
        Tuple.Data[5].b = false;                // Indicates whether you should display the time value and label or not. false means don't hide it || display it. true means hide.
        Tuple.Data[6].b = true;                 //convert time to hours
    }

	return ELR_NoInterrupt;
}
