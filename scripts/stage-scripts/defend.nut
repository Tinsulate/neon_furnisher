 
Include("scripts/libs/lib_dungeonlib.nut");
Include("scripts/stage-scripts/minimap.nut");
 
 local d_enemy_data = {"actors/enemy-security-guard-onlymelee.xml":{"power":10}, "actors/enemy-security-guard.xml":{"power":30}, "actors/enemy-security-guard-shield.xml":{"power":150}, "actors/enemy-soldier-rockets.xml":{"power":200}}

 local objects = {"actors/autoturret-playerowned.xml":{"price":100, "display_name":"Auto Turret"}, "actors/ability-mine.xml":{"price":15, "display_name":"Mine"}};
 


class Player
{
    credits = 0;
    cumulative_credits = 0;
    playerhandle = null;
    build_item = -1;
    
    constructor()
    {
        credits = 300;
        nextBuildItem()
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
                build_item = 0;
            }
        }
    }
    
    function addCredits(amount)
    {
        credits += amount;
        cumulative_credits += amount;
    }
    
    function addCreditsForDeath(handle)
    {
        local atype = Actor_GetActorType(handle);
        if(atype in d_enemy_data)
        {
            //Game_NC_ShowNotification("DOOD", 1.4);
            
            addCredits(d_enemy_data[atype].power)
        }
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
        
    
            Game_NC_ShowNotification(getCurrentBuildItemDisplayName() + " -C" + getCurrentBuildItemPrice(), 1.4);
            local new_soh = Stage_CreateActor(object, ob_pos[0], ob_pos[1], 0);
            StageObject_SetAngle(new_soh, ob_angle);
        
            Actor_SetTargetAngle(new_soh, ob_angle);
        } else {
             Game_NC_ShowNotification("Not enough credits!", 1.4);
        }
    }
   
}

class WavePhases
{
    static START_PAUSED = 0;
    static PREPARATION = 1;
    static SPAWNING = 2;
    static FIGHT = 3;
    static END_PAUSED = 4;
    static MAX = 5;
}

class WaveMaster
{
    current_phase = WavePhases.START_PAUSED;
    current_spawn_list = null
    actors_alive = null;
    wave_timer = 0;
    current_wave = 1;
    spawn_timer = 0;
    current_location = 0;
    locations = null;
    player = null;
    safeguard_fight_phase_timer = 0;
    
    constructor(spawner_locations, player_instance)
    {
        locations = spawner_locations;
        player = player_instance;
        current_spawn_list = [];
        actors_alive = [];
    }
    
    function onActorDeath(actor)
    {
        for(local t = actors_alive.len()-1; t >= 0; t--)
        {
            if(actor == actors_alive[t])
            {
                player.addCreditsForDeath(actor);
                actors_alive.remove(t);
            }
        }
        
        if(current_phase == WavePhases.FIGHT && actors_alive.len() < 1)
        {
            startPreparationPhase();
 
        }
    }

    function startPreparationPhase()
    {
        current_phase = WavePhases.PREPARATION;
        wave_timer = getNextWaveInterval();
    }
    
    function start()
    {
        startPreparationPhase();
    }
    
    function update(tdelta)
    {
        if(current_phase == WavePhases.FIGHT)
        {
            safeguard_fight_phase_timer -= tdelta;
        }
        
        if(current_phase == WavePhases.FIGHT && safeguard_fight_phase_timer < 0)
        {
            startPreparationPhase();
            safeguard_fight_phase_timer = 1.0;
        }
        
        if(wave_timer > 0)
        {
            wave_timer -= tdelta;
            if(wave_timer < 0)
            {
                if( current_phase == WavePhases.PREPARATION)
                {
                    prepareWave();
                } 
                
            }
        }
        
        if(current_phase == WavePhases.SPAWNING && spawn_timer > 0 && current_spawn_list.len() > 0)
        {
            spawn_timer -= tdelta;
            if(spawn_timer <= 0)
            {
                spawn_timer = getNextSpawnInterval();
                spawn();
                
            }
        }
    }
    
    function getNextWaveInterval()
    {
        return 5.0;
    }
    
    function getNextSpawnInterval()
    {
        return 0.7;
    }

    function nextLocation()
    {
        if(current_location+1 > locations.len()-1)
        {
            current_location = 0;
        } else {
            current_location += 1;
        }
    }
    
   

    function getCurrentLocation()
    {
        return locations[current_location];
    }
    
    function spawn()
    {
        if(current_spawn_list.len() < 1)
        {
            
            return;
        }
        
        local tospawn = current_spawn_list.pop();
        if(tospawn == "NEXT_LOCATION")
        {
            nextLocation();
            return;
        }
        local pos = getCurrentLocation()
        
        local new_soh = Stage_CreateActor(tospawn, pos[0], pos[1], 0);
        if(new_soh)
        {
            
            actors_alive.append(new_soh);
            
            // this is important for the chase behavior
            Stage_SendActorCommand(new_soh, "start_chase", 3.0);
        }
        
        if(current_spawn_list.len() < 1)
        {
            current_phase = WavePhases.FIGHT;
            safeguard_fight_phase_timer = 120.0;
            spawn_timer = 0;
        }
    
    }
    
    function prepareWave()
    {
        current_phase = WavePhases.SPAWNING
        current_spawn_list = getEnemyListInWave(current_wave)
        Game_NC_ShowNotification("|#ff0000|Wave " + current_wave + "|#ffffff|", 5.0);
        wave_timer = getNextWaveInterval();
        spawn_timer = getNextSpawnInterval();
        current_wave++;
    }
    
    function getEnemyForPower(power, tolerance)
    {
        local candidates = [];
        
        foreach(k,v in d_enemy_data)
        {
            if(v.power > power - (power*tolerance) &&
            v.power < power + (power*tolerance))
            {
                candidates.append(k);
            }
        }
        
        if(candidates.len() > 0)
        {
            return candidates[getSQRandInt(candidates.len()-1)];
        }
        
        local distance = 999999999999999;
        local closest = null;
        foreach(k,v in d_enemy_data)
        {
            newdist = abs(v.power - power);
            if(newdist < distance)
            {
                closest = k;
                distance = newdist;
            }
        }
        
        return closest;
        
    }
    
    function getEnemyListInWave(wave_number)
    {
        local list = [];
        
        local num_enemies = pow(wave_number, 0.9) * 3;
        local wave_power = pow(wave_number, 1.9) * 30;
        local average_power = wave_power / num_enemies;
        
        local triple_power = average_power * 3.0;
        
        local group_power = average_power*4 + triple_power;
        
        local num_groups = wave_power / group_power;
        
        for(local f = 0; f < num_groups; f++)
        {
            local enemy = getEnemyForPower(triple_power, 2.0);
            if(enemy)
            {
                list.append(enemy);
            }
            for(local t = 0; t < 4; t++)
            {
                local enemy2 = getEnemyForPower(average_power, 2.0);
                if(enemy2)
                {
                    list.append(enemy2);
                }
            }
            
            list.append("NEXT_LOCATION");
        }
        
 
        return list;
    }
    
    function draw()
    {
        return;
        NX_SetDepthDefault(0);
        NX_SetColor(1,1,1);
        NX_SetAlpha(1);
    
        NX_SetBlend(NX_BLEND_NORMAL);
        NX_SetTextTransform (1, 1, 0);
        NX_SetTextAlign (NX_ALIGN_LEFT);
   
        NX_DrawText ("fonts/medium.mft", 120, 80, "Wave: " +  current_wave + " wave timer " + wave_timer + " spawn timer: " + spawn_timer);
        
        NX_DrawText ("fonts/medium.mft", 120, 110, "Actor spawn list: " +  current_spawn_list.len() + " Actors alive: " + actors_alive.len() + " phase " + current_phase + " sguard " + safeguard_fight_phase_timer);
    }
}
 
local level_timer = 0;
local spawn_timer = 0;
local stage_width = 0;
local stage_height = 0;

local spawn_positions = [];

local minimap = null;
local wavemaster = null;
local player = null;
local player_handle = null;
function ScanSpawnerLocations()
{

    spawn_positions = [];
    local cobjects = Stage_QueryStageObjectsInsideRectangle (stage_width/2*Stage_GetCellSize(), stage_height/2*Stage_GetCellSize(), stage_width*Stage_GetCellSize(), stage_height*Stage_GetCellSize());
    foreach(handle in cobjects)
	{
		
		if(StageObject_GetType(handle) == STAGE_OBJECT_TYPE_MARKER)
		{
            local enemy_type = StageObject_GetKeyValue(handle, "enemy_type");
            if(enemy_type)
            {
                local pos = StageObject_GetPosition(handle);
                spawn_positions.append(pos);
            }
        }
    }
    NX_Print("Got " + spawn_positions.len() + " positions")
}

function OnGameStart()
{ 
    stage_width = Stage_GetWidth ()
    stage_height = Stage_GetHeight ()

    ScanSpawnerLocations();
    player = Player();
    
    wavemaster = WaveMaster(spawn_positions, player );
    wavemaster.start();
    
    player.setHandle(player_handle);
    
    minimap = MiniMap(stage_width, stage_height);
}

function OnActorBirth(so_handle)
{   
    local atype = Actor_GetActorType(so_handle);
    if(player_handle == null && atype.find("player-") != null)
    {
        player_handle = so_handle;
        
    }
   
}

function OnKeyDown(key)
{
    if(key == "C")
    {
       player.tryPurchaseCurrent();
        
       
    }
     if(key == "X")
    {
       player.nextBuildItem();
        
       
    }
    
    
}

function OnAllPlayersDied()
{
    UI_SendScreenMessage("DefendDeath", "Score", format("%d", player.cumulative_credits));
    UI_PushScreen("DefendDeath");
}

function OnActorDeath(so_handle)
{
    wavemaster.onActorDeath(so_handle);
    
    minimap.addDeadHandle(so_handle);
}
  
function OnUpdate(tdelta)
{
    level_timer += tdelta;
	wavemaster.update(tdelta);
    minimap.update(tdelta);
}
 
function OnDraw()
{
	//Debug();
    //DebugMeter();
    //NX_DrawRect(10, 10, 300, 300);
 
    //NX_SetDepthDefault(0);
	//NX_DrawRect(10, 10, 300, 300);
    if(wavemaster)
    {
        wavemaster.draw();
    }
    
    if(player)
    {
        player.draw(330, 70);
    }
    
    if(minimap)
    {
        minimap.draw(120,70,40,40);
    }
    
}