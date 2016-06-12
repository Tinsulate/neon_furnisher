 
Include("scripts/libs/lib_dungeonlib.nut");
Include("scripts/libs/lib_rect.nut");

local objects = {"actors/autoturret-playerowned.xml":{"price":100, "display_name":"Auto Turret", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"},"actors/ability-mine.xml":{"price":15, "display_name":"Mine", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"}};
 


class Player
{
    credits = 0;
    cumulative_credits = 0;
    playerhandle = null;
    build_item = -1;
    new_soh = null;
    premodel_position = null;
    
    constructor()
    {
        credits = 300;
    }

    function isItemSelected(){
     if (build_item > -1){
      return true;
     }
     return false;
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

    function getPreModel(){
        return new_soh;
    }

    function removePreModel(){
        new_soh = null;
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
        premodel_position = calcPreModelPosition();
        updatePreModelPosition();

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
        if (isItemSelected() == true){
            tryPurchase(getCurrentBuildItem());
        }
    }
    
    function tryPurchase(object)
    {
        if(!playerhandle) return;
        
        
        if(trySpendCredits(objects[object].price))
        {
            local p = premodel_position;

            Game_NC_ShowNotification(getCurrentBuildItemDisplayName() + " -C" + getCurrentBuildItemPrice(), 1.4);
            local new_soh2 = Stage_CreateActor(object, p[0], p[1], 0);

            StageObject_SetAngle(new_soh2, ob_angle);
            Actor_SetTargetAngle(new_soh2, ob_angle);
        } else {
            Game_NC_ShowNotification("Not enough credits!", 1.4);
        }
    }

    function getPremodelPosition(){
        return premodel_position;
    }

    function calcPreModelPosition(){
         if(!playerhandle) return;
         local ob_pos = StageObject_GetStagePosition(playerhandle);
         local ob_angle = Actor_GetTargetAngle(playerhandle);

         return newPosition(ob_pos,ob_angle,1);
    }

    function setPreModelPosition(new_position){
        premodel_position = new_position;
    }

    function buildPreModel(){
         NX_Print("buidl pre model");

         if(new_soh) return;
         if(!playerhandle) return;
         if(!isItemSelected()) return;

         local p = premodel_position;

         local object = getCurrentBuildItemModel();
         new_soh = Stage_CreateActor(object, p[0], p[1], p[2]);
    }

    //angle and position
    function updatePreModelPosition(){
        if(!new_soh || !premodel_position) return;

        local p = premodel_position;
        StageObject_SetPosition (new_soh,p[0],p[1],p[2]+10);

        local ob_angle = Actor_GetTargetAngle(playerhandle);
        StageObject_SetAngle(new_soh, ob_angle);
        Actor_SetTargetAngle(new_soh, ob_angle);
    }

    // amount of 1 is roughly one cell
    // currentposition [x,y,(z)]. z is unchanged
    // angle is angle around z axis (degrees)
    function newPosition(currentPosition, angle, amount){
        local x2 = round(Stage_GetCellSize()*cos(deg2rad(angle)), amount);
        local y2 = round(Stage_GetCellSize()*sin(deg2rad(angle)), amount);
        return [currentPosition[0]+x2,currentPosition[1]+y2,currentPosition[2]];
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
   NX_Print("onupdate " + tdelta);

}

function OnDraw()
{
	//Debug();
    //DebugMeter();

 
    NX_SetDepthDefault(0);
	//NX_DrawRect(10, 10, 300, 300);
    if(player)
    {
        player.draw(330, 70);
            if (player.isItemSelected() && player.getPremodelPosition() != null){

                local candraw = true;
                local pm_pos = player.getPremodelPosition();
                local offset = ActorType_GetBoundingBoxCenterOffset(player.getCurrentBuildItemModel());

                local pm_dim = ActorType_GetBoundingBoxDimensions(player.getCurrentBuildItemModel());

                NX_Print("pm_pos " + pm_pos[0] + ","+ pm_pos[1]);
                NX_Print("pm_dim " + pm_dim[0] + ","+ pm_dim[1]);
                local cobjects = Stage_QueryStageObjectsInsideRectangle(pm_pos[0],pm_pos[1], pm_dim[0]+20, pm_dim[1]+20);
                // Pitäisi olla containsForbidden(cobjects);

                foreach(handle in cobjects)
                {
                    local atype = Actor_GetActorType(handle);

                    candraw = getTypeWithName(atype);

                    if (!candraw && player.getPreModel() != null){
                       NX_Print("Not drawn! " + cobjects.len());
                       Stage_DeleteStageObject(player.getPreModel());
                       player.removePreModel();
                    }

                    if (!candraw){
                       break;
                    }
                }
                if (candraw && player.getPreModel() == null){
                    NX_Print("drawn! " + cobjects.len());
                    player.buildPreModel();
                    player.updatePreModelPosition();
                }

            }
    }


    
}

function getTypeWithName(atype)
{
    //if there is an object which is not one of the types below, building is forbidden
    if(atype.find("cable") != null || atype.find("ghost") != null)
    {
        return true;
    }

    return false;
}

function ReplaceItem(what, with = null)
{
	if( with != null)
	{
		local angle = StageObject_GetAngle (what);
		local pos = StageObject_GetPosition (what);
		local scale = StageObject_GetScale (what);


		local new_handle = Stage_CreateActor (with, pos[0], pos[1], pos[2]);
		StageObject_SetAngle (new_handle, angle);
		StageObject_SetScale (new_handle, scale);
	}

	Stage_DeleteStageObject(what);
}

