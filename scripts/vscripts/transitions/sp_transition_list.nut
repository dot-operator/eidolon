DBG <- 0
FORCE_GUN_AND_HALLWAY <- 0

FIRST_MAP_WITH_UPGRADE_GUN <- "sp_a1_beginning"
FIRST_MAP_WITH_POTATO_GUN <- "sp_a3_speed_ramp"
LAST_PLAYTEST_MAP <- "sp_a5_eidolon"


CHAPTER_TITLES <- 
[
	{ map = "sp_a1_beginning", title_text = "The Beginning", 		displayOnSpawn = true,	displaydelay = 0.0 },
	{ map = "sp_a3_funk_detail", title_text = "Funk Detail", 		displayOnSpawn = true,	displaydelay = 0.0 },
	{ map = "sp_a4_slantedlasers2", title_text = "Slanted Lasers", 	displayOnSpawn = true,	displaydelay = 0.0 },
	{ map = "sp_a5_eidolon1", title_text = "Eidolon",  		 		displayOnSpawn = true,  displaydelay = 0.0 },
	{ map = "sp_a5_eidolon2", title_text = "Eidolon",  		 		displayOnSpawn = true,  displaydelay = 0.0 },
	{ map = "sp_a5_eidolon3", title_text = "Eidolon",  		 		displayOnSpawn = true,  displaydelay = 0.0 },
]

// Display the chapter title
function DisplayChapterTitle()
{
	foreach (index, level in CHAPTER_TITLES)
	{
		if (level.map == GetMapName() )
		{
			EntFire( "@chapter_title_text", "SetTextColor", "170 190 180 128", 0.0 )
			EntFire( "@chapter_title_text", "SetTextColor2", "50 90 116 128", 0.0 )
			EntFire( "@chapter_title_text", "SetPosY", "0.32", 0.0 )
			EntFire( "@chapter_title_text", "SetText", level.title_text, 0.0 )
			EntFire( "@chapter_title_text", "display", "", level.displaydelay )
			
			//lol
			EntFire( "entry_sound", "PlaySound", "", 0.0)
			
			//EntFire( "@chapter_subtitle_text", "SetTextColor", "210 210 210 128", 0.0 )
			//EntFire( "@chapter_subtitle_text", "SetTextColor2", "50 90 116 128", 0.0 )
			//EntFire( "@chapter_subtitle_text", "SetPosY", "0.35", 0.0 )
			//EntFire( "@chapter_subtitle_text", "settext", level.subtitle_text, 0.0 )
			//EntFire( "@chapter_subtitle_text", "display", "", level.displaydelay )
		}
	}
}

// Display the chapter title on spawn if it is flagged to show up on spawn
function TryDisplayChapterTitle()
{
	foreach (index, level in CHAPTER_TITLES)
	{
		if (level.map == GetMapName() && level.displayOnSpawn )
		{
			DisplayChapterTitle()
		}	
	}
}

LOOP_TIMER <- 0

initialized <- false

// This is the order to play the maps
MapPlayOrder<- [

"sp_a1_beginning",
"sp_a2_eidolon",			// Have the portal gun starting here.
"sp_a3_funk_detail",
"sp_a4_slantedlasers2",
"sp_a5_eidolon",

]




// --------------------------------------------------------
// EntFire_MapLoopHelper
// --------------------------------------------------------
function EntFire_MapLoopHelper( classname, suffix, command, param, delay )
{
	// This calls EntFire on an entity of a given type, named with the given suffix.
	// This deals with instance name mangling (though it doesn't guarantee uniqueness)
	local suffix_len = suffix.len()
	for ( local ent = Entities.FindByClassname( null, classname ); ent != null; ent = Entities.FindByClassname( ent, classname ) )
	{
		local ent_name = ent.GetName()
		local suffix_offset = ent_name.find( suffix )
		if ( ( suffix_offset != null ) && ( suffix_offset == ( ent_name.len() - suffix_len ) ) )
		{
			EntFire( ent_name, command, param, delay )
			return
		}
	}
	printl( "MAPLOOP: ---- ERROR! Failed to find entity " + suffix + " while initiating map transition" );
}

// --------------------------------------------------------
// Think
// --------------------------------------------------------
function Think()
{	
	// Start the game loop if the cvar is set
	if ( initialized && LoopSinglePlayerMaps() )
	{
		// initialize the timer
		if( LOOP_TIMER == 0 )
		{
			LOOP_TIMER = Time() + 10 // restart time in seconds
		}
		
		// transition to the next map if the timer has expired
		if ( LOOP_TIMER < Time() )
		{
			// reset loop timer
			LOOP_TIMER = 0

			printl( "\nMAPLOOP: timer expired, moving on..." )

			// Ensure point_viewcontrollers are disabled
			EntFire( "point_viewcontrol", "disable", 0, 0 )
		
			// Change the level (this sequence was originally in the 'transition_without_survey' logic_relay)
			EntFire_MapLoopHelper( "trigger_once",   "survey_trigger",    "Disable",       "",                    0.0 )
			EntFire_MapLoopHelper( "env_fade",       "exit_fade",         "Fade",          "",                    0.0 )
			EntFire_MapLoopHelper( "point_teleport", "exit_teleport",     "Teleport",      "",                    0.3 )
			EntFire_MapLoopHelper( "logic_script",   "transition_script", "RunScriptCode", "TransitionFromMap()", 0.4 )
		}
	}
	
	if(!initialized){
		TryDisplayChapterTitle()
		initialized = true
	}
}

// --------------------------------------------------------
// TransitionFromMap
// --------------------------------------------------------
function DumpMapList()
{
	if(DBG)
	{
		local mapcount = 0
		
		printl("================DUMPING MAP PLAY ORDER")
		
		foreach( index, map in MapPlayOrder )
		{
			// weed out our transitions
			if( MapPlayOrder[index].find("@") == null )
			{
				if( GetMapName() == MapPlayOrder[index] )
				{
					printl( mapcount + " " + MapPlayOrder[index] + " <--- You Are Here" )
				}
				else
				{
					printl( mapcount + " " + MapPlayOrder[index] )
				}
				mapcount++
			}
			
		}
		printl( mapcount + " maps total." )
		
		printl("================END DUMP")
	}
}

// --------------------------------------------------------
// TransitionFromMap
// --------------------------------------------------------
function TransitionFromMap()
{
	local next_map = null
	foreach( index, map in MapPlayOrder )
	{
		if( GetMapName() == MapPlayOrder[index] )
		{
			// make good
			local skipIndex = index
			for(local i=0;i<2;i+=1)
			{
				if( skipIndex + 1 < MapPlayOrder.len() )
				{
					if( MapPlayOrder[skipIndex + 1].find("@") != null )
					{
						skipIndex++
					}
					else
					{
						break
					}
				}
			}		
			
			if( ( skipIndex + 1 < MapPlayOrder.len() ) &&
			    ( GetMapName() != LAST_PLAYTEST_MAP  )    )
			{
				next_map = MapPlayOrder[ skipIndex + 1 ]
				if(DBG) printl( "Map " + GetMapName() + " connects to " + next_map )

				if ( Entities.FindByName( null, "@changelevel" ) == null )
				{
					if(DBG) printl( "('@changelevel' entity missing, using 'map' command instead)" )
					SendToConsole( "map " + next_map );
				}
				else
				{
					EntFire( "@changelevel", "Changelevel", next_map, 0.0 )			
				}
			}
		}
	}

	printl( "" )
}

// --------------------------------------------------------
// MakeBatFile - dumps the map list in a formatted way, for easy recompilin'
// --------------------------------------------------------
function MakeBatFile()
{
		local mapcount = 0
		
		printl("================DUMPING maps formatted for batch file")
		
		foreach( index, map in MapPlayOrder )
		{
			printl( "call build " + MapPlayOrder[index] )	
		}
		
		foreach( index, map in MapPlayOrder )
		{
			printl( "call p2_buildcubemaps " + MapPlayOrder[index] )	
		}
}

// this lets the elevator know that we are ready to transition.
function TransitionReady()
{
	::TransitionReady <- 1	
}
