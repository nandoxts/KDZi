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
		900 = Creators    |  400 = Help Creator  |  350 = Lead Admin
		300 = HeadAdmins  |  200 = Administrador  |  150 = Moderador
		100 = DJ          |   75 = Influencer     |   50 = Socio
		 20 = COMMANDS    |   10 = VIP            |    0 = Todos
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
		"ping:900"; "face:900"; "head:900"; "insert:900";
		"change:900"; "subtract:900"; "resetStats:900"; "punish:900";
		"fogColor:900"; "add:900"; "reflectance:900"; "laserEyes:900";
		"bodyTypeScale:900"; "depth:900"; "height:900"; "hipHeight:900";
		"apparate:900"; "lockPlayer:900"; "chatHijacker:900";
		"saveMap:900"; "loadMap:900"; "follow:900";
		"chatTag:900"; "chatTagColor:900"; "chatNameColor:900"; "chatName:900";
		"notice:900"; "permBan:900"; "ban:900"; "unban:900";
		"aura2:900"; "directBan:900"; "sword:900"; "timeBan:900";
		"alert:900"; "kick:900"; "buildingTools:900"; "warp:900";
		"jail:900"; "gear:900"; "clone:900";
		"fiesta:900"; "pulse:900"; "quake:900"; "pyscho:900"; "acid:900";

		-- HELP CREATOR (400)
		"globalAlert:400"; "serverLock:400"; "forcePlace:400";
		"permRank:400"; "shutdown:400"; "chat:400";
		"createTeam:400"; "removeTeam:400"; "place:400";
		"fast:400"; "superJump:400"; "slow:400"; "time:400";
		"jump:400"; "blur:400"; "team:400"; "explode:400";
		"name:400"; "heavyJump:400"; "health:400"; "heal:400";
		"damage:400"; "bring:400"; "handTo:400"; "fling:400";
		"crash:400"; "fog:400"; "lockMap:400"; "globalAnnouncement:400";
		"jumpHeight:400"; "sellGamepass:400"; "sellAsset:400";
		"banland:400"; "tempRank:400"; "globalVote:400";
		"rank:400"; "unRank:400"; "mute:400"; "r15:400";
		"sc:400"; "kill:400"; "message:400"; "serverMessage:400";
		"systemMessage:400"; "control:400"; "freeze:400";
		"respawn:400"; "give:400"; "ice:400"; "spin:400"; "invisible:400";

		-- LEAD ADMIN (350)
		"refresh:350"; "m:350";

		-- HEAD ADMIN (300)
		"countdown:300"; "serverHint:300"; "vote:300";

		-- ADMINISTRADOR (200)
		"nightVision:200";

		-- MODERADOR (150)
		"view:150"; "cmds:150"; "privateMessage:150";
		"chatLogs:150"; "logs:150";

		-- DJ (100)
		"disco:100"; "music:100"; "volume:100";
		"countdown2:100"; "pitch:100"; "ranks:100";

		-- INFLUENCER (75)
		"title:75"; "freecam:75";

		-- SOCIO (50)
		"size:50"; "material:50"; "transparency:50";
		"glass:50"; "neon:50"; "smoke:50"; "fire:50";
		"clear:50"; "clearHats:50"; "teleport:50"; "r6:50";
		"cmdbar2:50"; "cmdbar:50"; "god:50"; "fat:50";
		"thin:50"; "squash:50"; "width:50"; "headSize:50"; "h:50";

		-- COMMANDS (20)
		"hideName:20"; "sparkles:20"; "shine:20"; "ghost:20";
		"dwarf:20"; "giantDwarf:20"; "hat:20"; "char:20";
		"fly:20"; "speed:20"; "fly2:20"; "noclip2:20"; "noclip:20"; "to:20";

		-- FREE (0)
		"hideGuis:0"; "showGuis:0";
	};
}