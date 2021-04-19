#include <sourcemod>
#include <store>
#include <lvl_ranks>
#include <multicolors>

ConVar c_servercredit,    
	   c_playercredit;

int playerrank[MAXPLAYERS+1],
    servercredit,
	playercredit,
	userclient,
	targetclient;

char username[MAX_NAME_LENGTH];
char targetname[MAX_NAME_LENGTH];



public Plugin myinfo =
{
	name = "Level Ranks [Sell Rank Module]",
	author = "NEXTARS",
	description = "Sell Level Ranks Global Elite Rank For Store Credits",
	version = "1.0",
	url = "https://fiverr.com/nextars"
};

public void OnClientPostAdminCheck(int client)
{
   playerrank[client] = LR_GetClientInfo(client, ST_RANK);
}

public void OnPluginStart(){
	LoadTranslations("sell_rank.phrases");
    RegConsoleCmd("sm_sellrank", checksellrank);
	c_servercredit = CreateConVar("sm_sell_servercredit", "5000", "For How Much Credit You Wanna Sell Rank To Server");
	c_playercredit = CreateConVar("sm_sell_playercredit", "6000", "For How Much Credit You Wanna Sell Rank To Player");
	AutoExecConfig(true, "sellrank_nextars");
	HookConVarChange(c_servercredit, OnSettingChanged);
	HookConVarChange(c_playercredit, OnSettingChanged);
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(oldValue, newValue, true))
        return;
	
	if (convar == c_servercredit)
	{
		servercredit = StringToInt(newValue);
	}
	else if (convar == c_playercredit)
	{
		playercredit = StringToInt(newValue);
	}
	
}
public void OnConfigsExecuted()
{
	servercredit = GetConVarInt(c_servercredit);
	playercredit = GetConVarInt(c_playercredit);
}

public Action checksellrank(int client,int args)
{
	playerrank[client] = LR_GetClientInfo(client, ST_RANK);
	char sName[MAX_NAME_LENGTH];
	char sID[24];
    char itemname[255];
    Format(itemname, sizeof(itemname), "%T", "menuitem", client,servercredit);
	if (playerrank[client]<18)
	{
       	CPrintToChat(client,"%t","norank");
        return Plugin_Handled;
	}

	else {
	userclient = client;
    Menu menu = new Menu(sellrankhandler);
	menu.SetTitle("%t","menutitle");
	menu.ExitBackButton = true;
	AddMenuItem(menu,"server", itemname);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i))
		//if (IsClientInGame(i))
		{
			IntToString(GetClientUserId(i), sID, sizeof(sID));
            GetClientName(i, sName, sizeof(sName));
            AddMenuItem(menu, sID, sName);
		}
	}
	 
	menu.Display(client, MENU_TIME_FOREVER);
	}
        return Plugin_Continue;

}


public sellrankhandler(Handle:menu, MenuAction:action, client, param2)
{
	new String:item[64];
    GetMenuItem(menu, param2, item, sizeof(item));

	decl String:info[32];
	new userid;

	GetMenuItem(menu, param2, info, sizeof(info));
	userid = StringToInt(info);
	targetclient = GetClientOfUserId(userid);

	if (action == MenuAction_Select)
	{
		if (StrEqual(item, "server"))
        {
	            Store_SetClientCredits(userclient, Store_GetClientCredits(userclient) + servercredit);
				LR_ResetPlayerStats(userclient);
				CPrintToChat(userclient, "%t","sellserver",servercredit);
	            delete menu;
        } 
		else
		{      
			    GetClientName(userclient, username, sizeof(username));
			    GetClientName(targetclient, targetname, sizeof(targetname));

				if(Store_GetClientCredits(targetclient)>=playercredit)
				{
                    char titlemenu[255];
                    Format(titlemenu, sizeof(titlemenu), "%t","sellrequest",username,playercredit,targetclient);
                    Menu menuconfirm = new Menu(confirmsellrankHandler);
                    menuconfirm.SetTitle(titlemenu);
                    menuconfirm.AddItem("yes", "Yes");
                    menuconfirm.AddItem("no", "No");
                    menuconfirm.ExitButton = false;
                    menuconfirm.Display(targetclient, MENU_TIME_FOREVER);
					CPrintToChat(userclient,"%t","requestwaiting",targetname,playercredit);
				}

				else
				{
		        CPrintToChat(userclient,"%t", "enoughcredit",targetname,playercredit);
				}
	    }
	   		
	}
	return Plugin_Continue;
}

public int confirmsellrankHandler(Menu menuconfirm, MenuAction action, int param1, int param2)
{
	targetclient = param1;
	new String:pending[64];
    GetMenuItem(menuconfirm, param2, pending, sizeof(pending));
    if (action == MenuAction_Select)
    {
 	if (StrEqual(pending, "yes"))
        {
			LR_ChangeClientValue(targetclient,10000);
			Store_SetClientCredits(targetclient, Store_GetClientCredits(targetclient) - playercredit);
			CPrintToChat(targetclient,"%t","rankrecieved",playercredit);
	        Store_SetClientCredits(userclient, Store_GetClientCredits(userclient) + playercredit);
			LR_ResetPlayerStats(userclient);
			CPrintToChat(userclient,"%t","ranksold",playercredit);
			delete menuconfirm;
		}
		else {
			CPrintToChat(userclient,"%t","offerreject1",targetname); 
			CPrintToChat(targetclient,"%t", "offerreject2",username); 
			delete menuconfirm;
		}
    }
	return Plugin_Handled;
}