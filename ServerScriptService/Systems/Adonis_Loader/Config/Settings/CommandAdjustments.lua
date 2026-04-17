-------------------------------
-- Scroll down for settings  --
-------------------------------

--[[
	Format example for Aliases:

		Aliases = {
			[":alias <arg1> <arg2> ..."] = ":command <arg1> <arg2> ..."
		}


	Format example for CommandCooldowns:

		CommandCooldowns = {
			[":commandname"] = {
				Player = 0; -- (optional) Per player cooldown in seconds
				Server = 0; -- (optional) Per server cooldown in seconds
				Cross = 0; -- (optional) Global cooldown in seconds
			}
		}

		Make sure to include the prefix infront of the command name.


	Format example for Permissions:

		Permissions = {
			"CommandName:NewLevel";
			"CommandName:CustomRank1,CustomRank2,CustomRank3";
		};
--]]

--[[
	Permisos de comandos de Adonis
	Formato: "comando:NivelMínimo"

	Niveles de referencia (ver Configuration.GroupRoles):
		900 = Creators (255, 254)  |  300 = Head Admin (253)
		200 = Admin (252)          |  150 = Moderador (251)
		100 = DJ (250)             |   75 = Influencer (249)
		 20 = COMMANDS (gamepass)   |   10 = VIP (gamepass)   |   0 = Todos
]]

----------------------------------
-- COMMAND ADJUSTMENTS SETTINGS --
----------------------------------

return {
	Aliases = {};

	CommandCooldowns = {};

	Permissions = {
		-- CREATORS (900)
		"morph:900"; "bundle:900"; "forceField:900"; "paint:900";
		"face:900"; "head:900"; "insert:900";
		"change:900"; "subtract:900"; "resetStats:900"; "punish:900";
		"fogColor:900"; "add:900"; "reflectance:900"; "laserEyes:900";
		"bodyTypeScale:900"; "depth:900"; "height:900"; "hipHeight:900";
		"apparate:900"; "lockPlayer:900"; "chatHijacker:900";
		"saveMap:900"; "loadMap:900"; "follow:900";
		"chatTag:900"; "chatTagColor:900"; "chatNameColor:900"; "chatName:900";
		"notice:900"; "permBan:900"; "ban:900"; "unban:900";
		"aura2:900"; "directBan:900";  "timeBan:900";"control:900";"chatLogs:900";"serverMessage:300";
		
		
		
		-- HELP CREATOR (400)
		"serverLock:400"; "forcePlace:400";
		"shutdown:400"; "chat:400";
		"createTeam:400"; "removeTeam:400"; "place:400";
		"name:400"; "heavyJump:400"; "health:400"; "heal:400";
		"damage:400"; "bring:400"; "handTo:400"; "fling:400";
		"lockMap:400"; "globalAnnouncement:400";
		"jumpHeight:400"; "sellGamepass:400"; "sellAsset:400";"banland:400";
		"mute:400"; "sc:400";"invisible:400";
		
		-- HEAD ADMIN (300)
		"countdown:300"; "serverHint:300"; "vote:300"; "m:300"; "give:300";"respawn:300"; "message:300";"kill:300";
		"tempRank:300"; "globalVote:300";"systemMessage:300";"freeze:300";"crash:300"; "fog:300";"r15:300";
		"fast:300";  "slow:300"; "time:300";
		"jump:300"; "blur:300"; "team:300"; "explode:300";"permRank:300";"globalAlert:300";
		"alert:300";  
		

		-- ADMINISTRADOR (200)
		"nightVision:200";"kick:200";"buildingTools:200";"ping:200";"rank:200"; "unRank:200";

		-- MODERADOR (150)
		"view:150"; "cmds:150"; "privateMessage:150";
		"logs:150"; "ranks:100";

		-- DJ (100)
		"countdown2:100"; "pitch:100";
		"disco:100"; "music:100"; "volume:100";
		"fiesta:100"; "pulse:100"; "quake:100"; "pyscho:100"; "acid:100";
		"superJump:100";"warp:100";

		-- INFLUENCER (75)
		"title:75"; "freecam:75";"freecam:75";
		
		-- Socio (50)
		"material:50"; "transparency:50";"can:50";
		"glass:50"; "neon:50"; "smoke:50"; "fire:50";
		"clear:50"; "clearHats:50"; "teleport:50"; "r6:50";
		"cmdbar2:50"; "cmdbar:50"; "god:50"; "fat:50";
		"thin:50"; "squash:50"; "width:50"; "headSize:50"; "h:50";"to:50";"ice:50";"sword:50";
		"jail:50"; "gear:50"; "clone:50";"spin:50";
		

		-- COMMANDS (20)
		"hideName:20"; "sparkles:20"; "shine:20"; "ghost:20";
		"dwarf:20"; "giantDwarf:20"; "hat:20"; "char:20";
		"fly:20"; "speed:20"; "fly2:20"; "noclip2:20"; "noclip:20";"refresh:20";"size:50"; 

		-- FREE (0)
		"hideGuis:0"; "showGuis:0";
	};
}