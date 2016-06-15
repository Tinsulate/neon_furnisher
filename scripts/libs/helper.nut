    //TODO: siirrä helperiin
    // TODO: Voisiko olla esim että actors.remove(condition). Ei olisi teoriassa niin tehokas mutta paljon ymmärrettävämpi
    function actors_containOtherThan(actors, actor_type_strings)
    {
        NX_Print("h " + actors + " " +actors.len());
        if (!actors || actors.len() == 0) return false;
        NX_Print("h1");
        if (!actor_type_strings || actor_type_strings.len() == 0) return true;

        NX_Print("h2");

        foreach(handle in actors)
        {
            NX_Print("inner " + handle);
            local atype = Actor_GetActorType(handle);
            if (!atype) continue;
            //local sotype = StageObject_GetType(handle);

            //failfast,
            if (is_any_found(atype, actor_type_strings)) {
             NX_Print("found" + handle);
             return true;
            }

        }
        NX_Print("okaytodraw");
        return false;
    }


    function is_any_found(atype, strings)
    {
        foreach(string in strings)
        {
          NX_Print("check " + atype);
          if (atype.find(string)){
           return false;
          }
        }
        return true;
    }

    // find topmost actor, exclude those with specified strings
     function actors_findTopmost(actors, actor_type_strings){
             NX_Print("top " + actors + " " + actors.len());
             if (!actors || actors.len() == 0) return false;
             NX_Print("top1");

             local result = {};

             foreach(handle in actors)
             {
                NX_Print("innertop " + handle);
                local atype = Actor_GetActorType(handle);
                if (!atype) continue;

                //local sotype = StageObject_GetType(handle);

                NX_Print("innertop2 " + handle);

                if (is_any_found(atype, actor_type_strings)) continue;

                local xyz = StageObject_GetPosition(handle);

                NX_Print("topxyz " + xyz);

                if (!result.topz || result.topz < xyz[2])
                {
                    result.topz = xyz[2];
                    result.tophandle = handle
                }
             }

             NX_Print("topreturn " + xyz);
             return result.tophandle;
        }


    function getActorsInsideModelBounds(atype, center, bounds_buffer){
            NX_Print(" alku ");
             local pm_dim = ActorType_GetBoundingBoxDimensions(atype);
             NX_Print(" sitten ");
             local pm_pos = center;
            NX_Print(" ja taas ");
             NX_Print(pm_dim);
             NX_Print("3 " + atype + " "+  pm_pos[0] + " " + pm_pos[1] + " " + pm_dim[0] + " "+ pm_dim[1] + " " + bounds_buffer);
             return Stage_QueryStageObjectsInsideRectangle(pm_pos[0],pm_pos[1], pm_dim[0]+bounds_buffer, pm_dim[1]+bounds_buffer);
        }