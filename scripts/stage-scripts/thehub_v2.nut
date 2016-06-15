 
Include("scripts/libs/lib_dungeonlib.nut");
Include("scripts/libs/lib_rect.nut");
Include("scripts/libs/helper.nut");

local objects = {"actors/autoturret-playerowned.xml":{"price":100, "display_name":"Auto Turret", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"},"actors/ability-mine.xml":{"price":15, "display_name":"Mine", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"}};
 


class Player
{
    credits = 0;
    cumulative_credits = 0;
    playerhandle = null;
    build_item = -1;
    carried_model = null;
    carried_type = null
    carried_position = null;
    candraw = true;
    angle_offset = 0;
    
    constructor()
    {
     credits = 300;
    }

    
    function nextBuildItem()
    {
        NX_Print("Nextbuilditem" + carried_model);

        build_item++;
        if (carried_model){
         Stage_DeleteStageObject(carried_model);
         NX_Print("Deleted carry from stage, carried_model: " + carried_model);
         carried_model = null;
         carried_type = null;
        }
        if(build_item > objects.len()-1)
        {
            build_item = -1;
        }else
        {
         carried_model =  buildCarriedModel(getCurrentBuildItemModel());
         carried_type = Actor_GetActorType(carried_model)
         updateCarriedModelPosition();
         NX_Print("built new " + carried_model);
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




    function drawCarried()
    {

        carried_position = calcCarriedModelPosition();

        if (!carried_type || !carried_position) return;
        //NX_Print("0: " + carried_position + " " + carried_model);

        //NX_Print("1");
        //TODO: unused
        //local offset = ActorType_GetBoundingBoxCenterOffset(carried_model);

        //NX_Print("2");
        //TODO: isOkToPlaceHere(actor_type, position, bounds_buffer, allowed_types)

        NX_Print(" fuuuu" + carried_model);

        local cobjects = getActorsInsideModelBounds(carried_type,carried_position, 10);
        NX_Print("3.5 " + cobjects);
        candraw  = !actors_containOtherThan(cobjects, ["cable", "ghost"]);

        //NX_Print("4" + candraw + " " + carried_model);
        if (!candraw)
        {
           NX_Print("Not drawn! " + cobjects.len());
           Stage_DeleteStageObject(carried_model);
           carried_model = null;
           NX_Print("Deleted, carried model: " + carried_model);
        }
        NX_Print("5");
        if (candraw)
        {
          if (!carried_model && carried_type){
          NX_Print("before crash, mo " + carried_model + " , ty" + carried_type);
           carried_model = buildCarriedModel(carried_type);
          }
          if (carried_model){
          NX_Print("before crash2 , mo" + carried_model + " ,ty" + carried_type);
            updateCarriedModelPosition();
          }

        }

        NX_Print("6");

    }



    function draw(x, y)
    {
        drawCarried();

        // TODO: Are all these needed:
        NX_SetDepthDefault(10);
        NX_SetColor(1,1,1);
        NX_SetAlpha(1);

        NX_SetBlend(NX_BLEND_NORMAL);
        NX_SetTextTransform (1, 1, 0);
        NX_SetTextAlign (NX_ALIGN_LEFT);
        NX_DrawText ("fonts/medium.mft", x, y, "C" +  credits + " Build: " +  getCurrentBuildItemDisplayName() + " C" + getCurrentBuildItemPrice());
    }

     function isItemSelected(){
         if (build_item > -1){
          return true;
         }
         return false;
     }

    function pickUpButtonPressed(){
        if (isItemSelected()){
            tryPurchase(getCurrentBuildItem());
        }else
        if (!carried_model){
         tryPickUp();
        }else{
         tryPutDown();
        }
    }
    
    function tryPickUp()
    {
      //local cobjects = getActorsInsideModelBounds("actors/armchair.xml" ,carried_position,5);
      //local topmost = actors_findTopmost(cobjects, ["cable", "wall"])
      //carried_model = topmost;
      //carried_model = Actor_GetActorType(topmost);

    }

    
    function tryPurchase(object)
    {
        if(!playerhandle) return;
        
        if(trySpendCredits(objects[object].price))
        {
            local p = carried_position;

            Game_NC_ShowNotification(getCurrentBuildItemDisplayName() + " -C" + getCurrentBuildItemPrice(), 1.4);
            local new_soh2 = Stage_CreateActor(object, p[0], p[1], 0);

            StageObject_SetAngle(new_soh2, ob_angle);
            Actor_SetTargetAngle(new_soh2, ob_angle);
        } else {
            Game_NC_ShowNotification("Not enough credits!", 1.4);
        }
    }

    function calcCarriedModelPosition(){
         if(!playerhandle) return;
         local ob_pos = StageObject_GetStagePosition(playerhandle);
         local ob_angle = Actor_GetTargetAngle(playerhandle);

         return newPosition(ob_pos,ob_angle,1);
    }

    function buildCarriedModel(atype){
         NX_Print("buidl pre model");

         if(!playerhandle) return;

         local p = carried_position;

         local object = atype;
         return Stage_CreateActor(object, p[0], p[1], p[2]);
    }

    //angle and position
    function updateCarriedModelPosition(){
        if(!carried_model || !carried_position) return;

        local p = carried_position;
        NX_Print("before set position, " + carried_model + " , " + p[0] + " " + p[1] + " " + (p[2]+10));
        StageObject_SetPosition (carried_model,p[0],p[1],(p[2]+10));

        NX_Print("before get target angle");

        local ob_angle = Actor_GetTargetAngle(playerhandle) + angle_offset;
        NX_Print("before segt angle " + carried_model + " , angle " + ob_angle);
        StageObject_SetAngle(carried_model, ob_angle);
        Actor_SetTargetAngle(carried_model, ob_angle);
    }

    // TODO: Move to helper
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

    if(key == "C")
    {
       player.pickUpButtonPressed();
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
    if(!player) return;

    player.draw(330, 70);

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

