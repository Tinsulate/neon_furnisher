 
Include("scripts/libs/lib_dungeonlib.nut");

 local objects = {"actors/autoturret-playerowned.xml":{"price":100, "display_name":"Auto Turret", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"},"actors/ability-mine.xml":{"price":15, "display_name":"Mine", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"}};
 


class Player
{
    credits = 0;
    cumulative_credits = 0;
    playerhandle = null;
    build_item = -1;
    new_soh = null;
    
    constructor()
    {
        credits = 300;

    }
    
    function nextBuildItem()
    {
        if(build_item == -1)
        {
            build_item = 0;
        }
        else 
        {
            build_item++;
            if(build_item > objects.len()-1)
            {
                build_item = -1;
            }
        }
    }
    
    function addCredits(amount)
    {
        credits += amount;
        cumulative_credits += amount;
    }

    
    function setHandle(handle)
    {
        playerhandle = handle;
    }
    
    function trySpendCredits(amount)
    {
        if(amount <= credits)
        {
            credits -= amount;
            return true;
        }
        
        return false;
    }
    
    function getCurrentBuildItem()
    {
        local t = 0;
        foreach(k,v in objects)
        {
            if(t == build_item)
            {
                return k;
            }
            t++;
        }
        return null;
    }
    
    function getCurrentBuildItemPrice()
    {
        local t = 0;
        foreach(k,v in objects)
        {
            if(t == build_item)
            {
                return v.price;
            }
            t++;
        }
        return 0;
    }

    function getCurrentBuildItemModel()
    {
        local t = 0;
        foreach(k,v in objects)
        {
            if(t == build_item)
            {
                return v.pre_build_model;
            }
            t++;
        }
        return 0;
    }
    
    function getCurrentBuildItemDisplayName()
    {
        local t = 0;
        foreach(k,v in objects)
        {
            if(t == build_item)
            {
                return v.display_name;
            }
            t++;
        }
        return "";
    }
    
    function draw(x, y)
    {
        NX_SetDepthDefault(10);
        NX_SetColor(1,1,1);
        NX_SetAlpha(1);
    
        NX_SetBlend(NX_BLEND_NORMAL);
        NX_SetTextTransform (1, 1, 0);
        NX_SetTextAlign (NX_ALIGN_LEFT);
  
        NX_DrawText ("fonts/medium.mft", x, y, "C" +  credits + " Build: " +  getCurrentBuildItemDisplayName() + " C" + getCurrentBuildItemPrice());
 
    }
    
    function tryPurchaseCurrent()
    {
        tryPurchase(getCurrentBuildItem());
    }
    
    function tryPurchase(object)
    {
        if(!playerhandle) return;
        
        
        if(trySpendCredits(objects[object].price))
        {
            local ob_pos = StageObject_GetStagePosition(playerhandle);     
            local ob_angle = Actor_GetTargetAngle(playerhandle);

            local x2 = round(Stage_GetCellSize()*cos(deg2rad(ob_angle)), 1);
            local y2 = round(Stage_GetCellSize()*sin(deg2rad(ob_angle)), 1);

            Game_NC_ShowNotification(getCurrentBuildItemDisplayName() + " -C" + getCurrentBuildItemPrice(), 1.4);
            local new_soh2 = Stage_CreateActor(object, ob_pos[0] +x2, ob_pos[1]+y2, 0);
            StageObject_SetAngle(new_soh2, ob_angle);
        
            Actor_SetTargetAngle(new_soh2, ob_angle);
        } else {
             Game_NC_ShowNotification("Not enough credits!", 1.4);
        }
    }

    function buildPreModel(){
         if(!playerhandle) return;
          local ob_pos = StageObject_GetStagePosition(playerhandle);
          local ob_angle = Actor_GetTargetAngle(playerhandle);

          local x2 = round(Stage_GetCellSize()*cos(deg2rad(ob_angle)), 1);
          local y2 = round(Stage_GetCellSize()*sin(deg2rad(ob_angle)), 1);

         if(new_soh){

          StageObject_SetPosition (new_soh,ob_pos[0]+x2,ob_pos[1]+y2,ob_pos[2]+10);
         }else {

        local object = getCurrentBuildItemModel();
        new_soh = Stage_CreateActor(object, ob_pos[0], ob_pos[1], 0);

        }
        Actor_SetTargetAngle(new_soh, ob_angle);

    }
   
}



local player = null;
local player_handle = null;

function OnGameStart()
{
    Game_NC_ShowNotification("ongamestart ", 1.4);

    player = Player();

    player.setHandle(player_handle);

}

function OnActorBirth(so_handle)
{
    Game_NC_ShowNotification("onactorRB ", 1.4);
    local atype = Actor_GetActorType(so_handle);
    if(player_handle == null && atype.find("player") != null)
    {
        player_handle = so_handle;
    }
   
}

function OnKeyDown(key)
{
    Game_NC_ShowNotification("onKeyDown: ", 1.4);

    if(key == "C")
    {
       player.tryPurchaseCurrent();
    }
     if(key == "X")
    {
       player.nextBuildItem();
    }

}


function OnUpdate(tdelta)
{

}
 
function OnDraw()
{
	//Debug();
    //DebugMeter();
    //NX_DrawRect(10, 10, 300, 300);
 
    //NX_SetDepthDefault(0);
	//NX_DrawRect(10, 10, 300, 300);

    if(player)
    {
        player.draw(330, 70);
    }

    if (player.getCurrentBuildItem() != null){
        player.buildPreModel()
    }
    
}