
LuaInclude ("ui/common-ui-funcs.lua");

function OnLoad ()
end;

function OnEnter ()
  
end;

function OnLeave ()
end;


function OnScreenMessage(key, value)
	if (key == "Score") then
		SetProperty("Score:textbox.text", value);
	end;
end;

function OnClick (name)
	Print ("OnClick " .. name .. "\n");
	
	if (name == "TryAgain") then
		Misc_LoadAndPlayStage("stages/defend_base_1.xml");
		return;
	end;
	
	if (name == "Exit") then
		BeginTimelineEvent("Mods");
		return;
	end;
		
end;


function OnUpdate (tdelta)
	DoPanelTransitionRotateFall ("fader", "panel");
end;

function OnDraw ()
end;

function OnBackAction ()
end;
