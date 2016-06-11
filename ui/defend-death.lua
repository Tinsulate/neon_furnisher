-- ui/defend-death.lua

-- using default named events script 'ui/defend-death-events.lua'

CreateComp ("ShaderFilter", "fader");

CreateComp ("Marker", "panel");
SetProperty ("position", 0.498437, 0.508333);
SetProperty ("angle.x", -0.00990294);
SetProperty ("angle.y", -0.0283184);
SetProperty ("align", "CENTER");
SetProperty ("marker.area_width", 935.111);
SetProperty ("marker.area_height", 526.222);

CreateComp ("Textbox", "title");
SetProperty ("inherit", "LargeTextboxDigi");
SetProperty ("parent", "panel");
SetProperty ("position", 0.00117789, -0.555653);
SetProperty ("position.z", -0.0531915);
SetProperty ("align", "HCENTER");
SetProperty ("textbox.text", "You Died");

CreateComp ("Textbox", "title3");
SetProperty ("inherit", "MediumTextboxDigi");
SetProperty ("parent", "panel");
SetProperty ("position", 0.00260363, 0.0487387);
SetProperty ("align", "HCENTER");
SetProperty ("textbox.textbox_align", "HCENTER");
SetProperty ("textbox.text", "Score:");

CreateComp ("Textbox", "Score");
SetProperty ("inherit", "LargeTextboxDigi");
SetProperty ("localize", 0);
SetProperty ("parent", "panel");
SetProperty ("position", 0.00331667, 0.16259);
SetProperty ("align", "CENTER");
SetProperty ("textbox.text", "290");

CreateComp ("Aligner", "aligner");
SetProperty ("parent", "panel");
SetProperty ("position", 0.00522779, 0.404289);
SetProperty ("position.z", -0.0586115);
SetProperty ("aligner.area_width", 108.341);
SetProperty ("aligner.area_height", 157.4);

CreateComp ("Button", "TryAgain");
SetProperty ("parent", "aligner");
SetProperty ("position", 0, -0.25);
SetProperty ("button.text", "Try Again");

CreateComp ("Button", "Exit");
SetProperty ("parent", "aligner");
SetProperty ("position", 0, 0.25);
SetProperty ("button.text", "Exit");

CreateComp ("Image", "image_1");
SetProperty ("parent", "panel");
SetProperty ("position", 0.00190114, -0.197635);
SetProperty ("scale", 0.832265);
SetProperty ("align", "CENTER");
SetProperty ("image.bitmap", "preview.jpg");

