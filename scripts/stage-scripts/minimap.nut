
class MapItem
{
    x = 0;
    y = 0;
    type = 0;
    handle = null;
    constructor(x,y,type,handle)
    {
        this.x = x;
        this.y = y;
        this.type = type;
        this.handle = handle;
    }
}

class MiniMap
{
    sector_index = 0;
    
    dead_handles = [];
    sectors = [];
    width = 0;
    height = 0;
    sector_size = 16.0;
    update_timer = 0;
    num_sectors = 0;
    constructor(w,h)
    {
        width = w;
        height = h;
        
        num_sectors = ceil(width/sector_size) * ceil(height/sector_size);
        NX_Print("MINIMAP w " + width + " h " + height + " sectors " + num_sectors);
        for(local t = 0; t < num_sectors; t++)
        {
            local items = [];
            sectors.append(items);
        }
    }
    
    function getTypeWithName(atype)
    {
        if(atype == null) return "MISC";
        
        if(atype.find("enemy") != null)
        {
            return "ENEMY";
        }
        else if(atype.find("player-") != null)
        {
            return "PLAYER";
        }
         else if(atype.find("turret") != null)
        {
            return "TURRET";
        }
        else if(atype.find("power-cell") != null)
        {
            return "POWERCELL";
        }
        
        return "MISC";
    }
    function nextScan()
    {
        local rows = ceil(height / sector_size)
        local cols = ceil(width / sector_size);
 
        local row = floor(sector_index / rows);
        local col = sector_index % (row*cols);
        if(sector_index < cols)
        {
            col = sector_index;
        }
        
        local scansize = sector_size * Stage_GetCellSize();
        local sx = sector_size*row*Stage_GetCellSize() + (scansize*0.5);
        local sy = sector_size*col*Stage_GetCellSize() + (scansize*0.5);
        
        
        //NX_Print("MINIMAP scan area " sector_index + " " + sx + " " + sy + " " + scansize + " (" + row + ","+ col + ")")
        
     
        local cobjects = Stage_QueryStageObjectsInsideRectangle (sx, sy, scansize, scansize);
        local items = [];
        foreach(handle in cobjects)
        {
            local pos = StageObject_GetPosition(handle);
         
            local atype = Actor_GetActorType(handle);
            
            local type = getTypeWithName(atype);
            
            items.append(MapItem(pos[0], pos[1], type, handle));
            
            sectors[sector_index] = items;
        }
        sector_index++;
        if(sector_index > num_sectors-1)
        {
            sector_index = 0;
        }
    }
    
    function update(tdelta)
    {
        update_timer++;
        if(update_timer > 0.3)
        {
            nextScan();
            update_timer = 0;
        }
    }
    
    function addDeadHandle(handle)
    {
        dead_handles.append(handle);
    }    
    
    
   
    function draw(x,y, w, h)
    {
        NX_SetDepthDefault(0);
        NX_SetColor(1,1,1);
        NX_SetAlpha(1);
    
        NX_SetBlend(NX_BLEND_NORMAL);
        
        NX_SetTextTransform (1, 1, 0);
        NX_SetTextAlign (NX_ALIGN_LEFT);
  
        local tw = width*Stage_GetCellSize();
        local th = height*Stage_GetCellSize();
        for(local t = 0; t < num_sectors; t++)
        {
            for(local f = 0; f < sectors[t].len(); f++ )
            {
                //NX_Print("MINIMAP item " + sectors[t][f][0] + " " + sectors[t][f][1]);
                
                local m = sectors[t][f];
                local xc = 15.0*(m.x/170.0) + x;
                local yc = 15.0*(m.y/170.0) + y;
                
                local hilight = false;
                if(m.type == "ENEMY")
                {
                    
                    if(dead_handles.find(m.handle) != null)
                    {
                         
                        continue;
                    }
                    NX_SetColor(1,0,0);
                    hilight = true;
                } 
                else if(m.type == "PLAYER")
                {
                    NX_SetColor(0.8,1,0);
                    hilight = true;
                }
                else if(m.type == "POWERCELL")
                {
                    NX_SetColor(1,0,1);
                    hilight = true;
                }
                else if(m.type == "TURRET")
                {
                    NX_SetColor(1,1,1);
                    hilight = true;
                }
                else 
                {
                    NX_SetColor(0,0.5,1);
                }
                NX_DrawBitmapRS ("ui/gfx/grey_dot.png", xc, yc, 0, 0.3);
                
                if(hilight)
                {
                     NX_SetBlend(NX_BLEND_ADDITIVE);
                     NX_DrawBitmapRS ("ui/gfx/grey_dot.png", xc, yc, 0, 0.3);
                     NX_SetBlend(NX_BLEND_NORMAL);
                }
                
            }
        }
    }
    
}