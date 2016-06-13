 
Include("scripts/libs/lib_dungeonlib.nut");
Include("scripts/libs/lib_rect.nut");

local objects = {"actors/autoturret-playerowned.xml":{"price":100, "display_name":"Auto Turret", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"},"actors/ability-mine.xml":{"price":15, "display_name":"Mine", "pre_build_model":"actors/autoturret-playerowned-ghost.xml"}};
 


class Player
{
    credits = 0;
    cumulative_credits = 0;
    playerhandle = null;
    build_item = -1;
    premodel = null;
    premodel_position = null;
    angle_offset = 0;
    
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

    //TODO: siirrä helperiin
    function actors_containOtherThan(actors, actor_type_strings)
    {
        if (!actors || actors.len() == 0) return false;
        if (!actor_type_strings || actor_type_strings.len() == 0) return true;

        NX_Print("h2");
        foreach(handle in actors)
        {
            NX_Print("inner " + handle);
            local atype = Actor_GetActorType(handle);

            if (!atype) continue;

            local sotype = StageObject_GetType(handle);

            //include in result if allowed not found
            local found = true;
            foreach(string in actor_type_strings)
            {
              NX_Print("check " + atype);
              NX_Print("check2 " + sotype);
              if (atype.find(string)){
               found = false;
              }
            }

            //failfast,
            if (found) {
             NX_Print("found" + handle);
            return true;}

        }
        NX_Print("notokaytodraw");
        return false;
    }


    function draw(x, y)
    {
        premodel_position = calcPreModelPosition();

        if (!isItemSelected() || !premodel_position) return;

        NX_Print("1");
        //TODO: unused
        local offset = ActorType_GetBoundingBoxCenterOffset(getCurrentBuildItemModel());

        NX_Print("2");
        //TODO: isOkToPlaceHere(actor_type, position, bounds_buffer, allowed_types)
        local pm_dim = ActorType_GetBoundingBoxDimensions(getCurrentBuildItemModel());
        local pm_pos = premodel_position;

        NX_Print("3");
        local cobjects = Stage_QueryStageObjectsInsideRectangle(pm_pos[0],pm_pos[1], pm_dim[0]+10, pm_dim[1]+10);
        NX_Print("3.5 " + cobjects);
        local candraw  = !actors_containOtherThan(cobjects, ["cable", "ghost"]);


        NX_Print("4" + candraw + " " + premodel);
        if (!candraw && premodel)
        {
           NX_Print("Not drawn! " + cobjects.len());
           Stage_DeleteStageObject(premodel);
           premodel = null;
        }
        NX_Print("5");
        if (candraw)
        {
          buildPreModel();
          updatePreModelPosition();
        }

        NX_Print("6");

        // TODO: Are all these needed:
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
         // TODO: here is abug
         if(premodel) return;
         if(!playerhandle) return;
         if(!isItemSelected()) return;

         local p = premodel_position;

         local object = getCurrentBuildItemModel();
         premodel = Stage_CreateActor(object, p[0], p[1], p[2]);
    }

    //angle and position
    function updatePreModelPosition(){
        if(!premodel || !premodel_position) return;

        local p = premodel_position;
        StageObject_SetPosition (premodel,p[0],p[1],p[2]+10);

        local ob_angle = Actor_GetTargetAngle(playerhandle) + angle_offset;
        StageObject_SetAngle(premodel, ob_angle);
        Actor_SetTargetAngle(premodel, ob_angle);
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
     NX_Print("ondraw ");
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

