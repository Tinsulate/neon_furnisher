Include("scripts/libs/lib_dungeonlib.nut");
Include("scripts/libs/lib_casks_and_more.nut");
Include("scripts/libs/lib_doorsystems.nut");

local elevator_spacing = 3;
class HubDoorType
{
    static NORMAL = 1;
    static UNLIT = 2;
    static RED = 4;
 }
  

function CreateTutorialAtMarker(marker_name, tutorial_text)
{
    local marker = StageObject_GetById(marker_name);
     
    if(marker)
    {
        local angle = StageObject_GetAngle(marker);
    
        local pos = StageObject_GetPosition (marker)
         
      
        local actor = Stage_CreateScriptableSurface ("scriptable-surfaces/player_reactive_floating_text_surface.nut", pos[0], pos[1], pos[2]);
        ScriptableSurface_SetKeyValue (actor, "text", tutorial_text);        
        ScriptableSurface_SetKeyValue(actor, "radius", 120);   
        StageObject_SetAngle(actor, angle);
        
    } 
    else 
    {
        NX_Popup("No tutorial marker: " + name);
    }
}

function SetSingleDoorState(name, state)
{
    local marker = StageObject_GetById(name);
    if(marker)
    {
        local angle = StageObject_GetAngle(marker);
        local door_model = "actors/door-sliding.xml";
        
        local pos = StageObject_GetPosition (marker)
         
        if(state == HubDoorType.RED)
        {   
            door_model = "actors/door-red-sliding.xml";
        } 
        else if(state == HubDoorType.UNLIT)
        {   
            door_model = "actors/door-sliding-unlit.xml";
        }
        else if(state == HubDoorType.NORMAL)
        {   
            door_model = "actors/door-sliding.xml";
        }
        else 
        {
            door_model = "actors/door-sliding-unlit.xml";
        }
        
        
        local actor = Stage_CreateActor (door_model, pos[0], pos[1], 0);

        StageObject_SetAngle(actor, angle);
        
    } else {
        NX_Popup("No door marker: " + name);
    }
}

function SetDoors()
{
    //SetSingleDoorState("holo_room_door", HubDoorType.UNLIT);
    //SetSingleDoorState("dining_room_door", HubDoorType.UNLIT);
     
   // SetSingleDoorState("balcony_door_1", HubDoorType.UNLIT);
      
   //SetSingleDoorState("balcony_door_2", HubDoorType.UNLIT);
    
   //  SetSingleDoorState("upgrade_room_door", HubDoorType.UNLIT);
}

function GenerateElevatorTargets(arg_elevator_targets, num_elevators)
{
    local target_list = array(num_elevators, null);
    target_list[arg_elevator_targets["START"][0]] = arg_elevator_targets["START"][1];


    local open_all_elevators = false;

    local max_playthroughs_str = Profile_GetValue("GAME_INFO", "playthroughs", "value");
    local selected_playthroughs_str = Profile_GetValue("GAME_INFO", "selected_playthroughs", "value");
    if (max_playthroughs_str && selected_playthroughs_str)
    {
        if (selected_playthroughs_str.tointeger() < max_playthroughs_str.tointeger())
        {
            open_all_elevators = true;
        }
    }

    if (open_all_elevators)
    {
        foreach (target in arg_elevator_targets)
        {
            local target_list_index = target[0];
            if (target_list_index < target_list.len())
            {
                target_list[target_list_index] = target[1];
            }
        }

        return target_list;
    }


    local open_elevators_str = Profile_GetValue("ELEVATORS", "OPEN", "value");
    if (open_elevators_str)
    {
        local open_elevators = split(open_elevators_str, ",");
        foreach (id in open_elevators)
        {
            if (id in arg_elevator_targets)
            {
                local target_list_index = arg_elevator_targets[id][0];
                if (target_list_index < target_list.len())
                {
                    target_list[target_list_index] = arg_elevator_targets[id][1];
                }
            }
        }
    }

    return target_list;
} 
function GetTargetArrayFromGameStructureFile(file)
{
    local num_nodes = DM_GetArrayNumberOfNodes(file, "GAME_PHASES");
    assert(num_nodes > 0);
    NX_Print("Tags---");
    
    local targets = {};
    
    targets["START"] <- [0, "1"]; 
    
    local num_elevators = 1;
    
    for(local t = 0; t < num_nodes; t++)
    {
       
        local elevator_key_at_start = DM_GetArrayNodeValue (file, "GAME_PHASES", t, "elevator_key_at_start");
        local elevator_key_at_end = DM_GetArrayNodeValue (file, "GAME_PHASES", t, "elevator_key_at_end");
        if(elevator_key_at_start != null)
        {
            local tindex = num_elevators+1;
            targets[elevator_key_at_start] <- [num_elevators, tindex.tostring()]; 
            num_elevators++;
        } 
        else if(elevator_key_at_end != null)
        {
            local tindex = num_elevators+1;
            targets[elevator_key_at_end] <- [num_elevators, tindex.tostring()]; 
            num_elevators++;
        }
    }
    foreach(k,v in targets)
    {
        NX_Print(k + " " + v[0] + " " + v[1]);
    }
    local final_targets = GenerateElevatorTargets(targets, num_elevators);
    
    return final_targets;
}

function SpawnElevators(xt, yt, game_structure_file)
{
    
    local targets = GetTargetArrayFromGameStructureFile(game_structure_file);
    
    
    local xp = xt;
    local yp = yt;
    for(local t = 0; t < targets.len(); t++)
    {
        local extra_tiles = 0;

        local ex = xp+(t*elevator_spacing*Stage_GetCellSize())+1*Stage_GetCellSize()+(extra_tiles*Stage_GetCellSize());

        local ey = yt+1*Stage_GetCellSize()
        local actor = Stage_CreateActor ("actors/elevator-small.xml", ex, ey, 0);

        StageObject_SetAngle(actor, 90);

        local light = Stage_CreateLight(LIGHT_TYPE_POINT, ex, ey, -50);

        Light_SetRadius(light, 110);

        local door_model = "actors/door-double-sliding-unlit.xml";
        if((t < targets.len() && targets[t]) || targets.len() == 1)
        {
            Light_SetColor(light, 0.1, 1.0, 0.4);
            local marker = Stage_CreateMarker("jump_to_level", ex, ey, 0);
            door_model = "actors/door-double-sliding.xml";
            Marker_SetRadius(marker, 80);
            StageObject_SetKeyValueString(marker, "target", targets[t]);
            StageObject_SetKeyValueString(marker, "game_structure_file", game_structure_file);
            if(!(t+1 < targets.len() - 1 && targets[t+1]))
            {
            
                local light2 = Stage_CreateLight(LIGHT_TYPE_POINT, ex, ey+160, -50);
                
                Light_SetRadius(light2, 74);
            }
        } else {
            Light_SetColor(light, 1.0, 0.2, 0.1);
        }

        local door = Stage_CreateActor (door_model, ex-Stage_GetCellSize()/2, ey+(2*Stage_GetCellSize())-Stage_GetCellSize()/2, 0);
        
        local door2 = Stage_CreateActor (door_model, ex+Stage_GetCellSize()/2, ey+(2*Stage_GetCellSize())-Stage_GetCellSize()/2, 0);

        local decal = Stage_CreateTextDecalOnGround ("fonts/big-text.mft", ""+(t+1), ex, ey+160, 0, 1);

        StageObject_SetAngle(door, 90);
        StageObject_SetAngle(door2, 270);
    }
}

function ReplaceStartLocation(new_location_id)
{
    local default_player_start = StageObject_GetById("player_1");
    assert(default_player_start);
    local alt_start = StageObject_GetById(new_location_id);
        
    local pos =  StageObject_GetPosition (alt_start);
    local ang = StageObject_GetAngle(alt_start);
    
    local newmark = Stage_CreateMarker ("player_1", pos[0], pos[1], pos[2]);
        
     StageObject_SetAngle(newmark, ang);
    Stage_DeleteStageObject(default_player_start);
    
    NX_Print("Replaced start at " + pos[0] + " " + pos[1]);
}

function GenerateLevel()
{
    local stage_width = 55;
	local stage_height = 68;
    
    Stage_Create (stage_width, stage_height);
    Stage_SetAmbientLight(0.19, 0.19, 0.19);

	Game_NC_SetFogColor(0.3, 0.2, 0.3);
 
    SpawnArea(0, 0, "stages/hubv2.xml");
    
    
    local cobjects = Stage_QueryStageObjectsInsideRectangle (stage_width/2*Stage_GetCellSize(), stage_height/2*Stage_GetCellSize(), stage_width*Stage_GetCellSize(), stage_height*Stage_GetCellSize());
    local num_spawn_casks = 0;
    foreach(handle in cobjects)
	{
		if(StageObject_GetType(handle) == STAGE_OBJECT_TYPE_MARKER)
		{
            local cask_rows = StageObject_GetKeyValue(handle, "cask_rows");
            local cask_cols = StageObject_GetKeyValue(handle, "cask_cols");
            local spawn_casks = StageObject_GetKeyValue(handle, "real_spawn_casks");
            if(cask_rows  && cask_cols && spawn_casks)
            { 
                num_spawn_casks = cask_cols * cask_rows;
            }
        }   
        
    }
    
    local vault = 1;
    local casks_opened = 1;

    local num_deaths = Profile_GetValue("STATS", "deaths", "int");
  
    if (num_deaths && num_deaths.tointeger() > 0)
    {
        vault = ceil((num_deaths.tofloat() + 1) / num_spawn_casks.tofloat()).tointeger();
        casks_opened = ceil((num_deaths.tofloat() + 1) - num_spawn_casks.tofloat() * (vault - 1)).tointeger();
    }
    NX_Print(num_deaths + " vault " + vault + " casks opened " + casks_opened + " spawn casks " + num_spawn_casks);
    local is_coop = Profile_GetValue("CURRENT_GAME", "is_coop", "value") != null;
    if (is_coop)
    {
        casks_opened = 4;
    }

    local objects = Stage_QueryStageObjectsInsideRectangle (stage_width/2*Stage_GetCellSize(), stage_height/2*Stage_GetCellSize(), stage_width*Stage_GetCellSize(), stage_height*Stage_GetCellSize());
 
    
    if(num_deaths && num_deaths.tointeger() == 3)
    {
         ReplaceStartLocation("start_location_upgrades");
    }
    
    if(num_deaths && num_deaths.tointeger() == 4)
    {
         ReplaceStartLocation("start_location_research");
         CreateTutorialAtMarker("unlocks_tutorial_here", "Use the unlock console to browse and boost unlocks.");
         CreateTutorialAtMarker("mission_tutorial_here", "Use the mission console to browse missions and claim rewards.");
    }
	
	// local game_struct_file = Profile_GetValue("GENERATOR_SETTINGS", "game_structure_filename", "value");
	// if( game_struct_file && game_struct_file.find("gunrange") )
	// {
		// ReplaceStartLocation("start_location_guns");
    // }
 
    local cobjects = Stage_QueryStageObjectsInsideRectangle (stage_width/2*Stage_GetCellSize(), stage_height/2*Stage_GetCellSize(), stage_width*Stage_GetCellSize(), stage_height*Stage_GetCellSize());
  
    local achitext = StageObject_GetById ("achitext_here")
   
    if(achitext)
	{
		local pos = StageObject_GetPosition(achitext);
		if(Game_NC_DoesFeatureExist("TROPHIES")) 
		{
			Stage_CreateTextDecalOnGround("fonts/big-text.mft", "TROPHIES", pos[0], pos[1], -45, 0.3);
		} 
		else 
		{
			Stage_CreateTextDecalOnGround("fonts/big-text.mft", "ACHIEVEMENTS", pos[0], pos[1], -45, 0.3);
		}
		Stage_DeleteStageObject(achitext);
	}
    
    foreach(handle in cobjects)
	{
		
		if(StageObject_GetType(handle) == STAGE_OBJECT_TYPE_MARKER)
		{
            local cask_rows = StageObject_GetKeyValue(handle, "cask_rows");
            local cask_cols = StageObject_GetKeyValue(handle, "cask_cols");
            local spawn_casks = StageObject_GetKeyValue(handle, "real_spawn_casks");
            local elevator_spawn_type = StageObject_GetKeyValue(handle, "elevator_spawn_type");
            local door_color = StageObject_GetKeyValue(handle, "door_color");
            local type = StageObject_GetKeyValue(handle, "type");
            local pos = StageObject_GetPosition (handle);
             
            if(type == "double_door")
            {
                local angle = StageObject_GetAngle (handle);
                local model = "actors/door-outer-double-sliding-unlit.xml";
                
                if(num_deaths && num_deaths.tointeger() > 0)
                {
                    model = "actors/door-double-sliding.xml";
                }
                DoorSystems.MakeDoubleDoor(pos, angle, model)
           
                
            } 
            else if(elevator_spawn_type)
            {
                

                SpawnElevators(pos[0], pos[1], elevator_spawn_type);
            
            }
            else if(cask_rows  && cask_cols)
            {
               
                if(spawn_casks)
                {
                    SpawnCasks(pos[0], pos[1], cask_cols, cask_rows, casks_opened, is_coop);
                    
                } else {
                    SpawnCasks(pos[0], pos[1], cask_cols, cask_rows, 0, 0);
                }
                
            }
        }   
        
    }
    
    SetDoors();
    
    Stage_SetMusicTrack("music/arming_and_briefing");
    
    if(num_deaths && num_deaths.tointeger() < 2)
    {
        CreateTutorialAtMarker("credits_tutorial_here", "Use credits to upgrade your stats.");
        CreateTutorialAtMarker("chair_tutorial_here", "Use the chair to connect to an asset.");
      
    }
    
  
    
    
     local display_marker = StageObject_GetById("info");
    if(display_marker != null)
    {
         ScriptableSurface_SetKeyValue (display_marker, "set_text", "Batch #" + vault + ": " + (num_spawn_casks-casks_opened) + "/" + num_spawn_casks);
 
    } else {
        NX_Popup("No info display!!");
    }
    Stage_SetStageScript("scripts/stage-scripts/thehub_v2.nut");
    Stage_SetName ("Home")
}



// Call a method right away when the script is loaded.
GenerateLevel();

