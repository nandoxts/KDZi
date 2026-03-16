----------------------
-- GENERAL SETTINGS --
----------------------

return {
	Prefix = {";", ":"};		-- Prefijos (migrado de HD Admin: ";")
	PlayerPrefix = "!";			-- El ! en !donate
	SpecialPrefix = "";			-- Usado para "all", "me", "others"
	SplitKey = " ";				-- Separador (migrado de HD Admin)
	BatchKey = "|";				-- ;kill me | ;ff bob
	ConsoleKeyCode = "Quote";	-- Keybind consola

	HideScript = true;

	DataStoreEnabled = true;
	LocalDatastore = false;
	DataStore = "Adonis_1";
	DataStoreKey = "KDZi_Adonis_2026";	-- Clave encriptación DataStore

	SaveAdmins = true;			-- Guardar rangos dados en juego (migrado SaveRank = true)
	LoadAdminsFromDS = true;

	SaveCommandLogs = true;
	MaxLogs = 5000;

	Storage = game:GetService("ServerStorage");
	RecursiveTools = false;

	Theme = "Default";
	MobileTheme = "Mobilius";
	DefaultTheme = "Default";
	HiddenThemes = {};

	BanMessage = "Has sido baneado de este servidor.";
	LockMessage = "Servidor bloqueado - No estás en la whitelist.";
	SystemTitle = "System Message";

	Banned = {};
	Muted = {};
	Blacklist = {};
	Whitelist = {};

	WhitelistEnabled = false;

	MusicList = {};
	CapeList = {};
	InsertList = {};

	OnStartup = {};
	OnJoin = {};
	OnSpawn = {};

	FunCommands = true;
	PlayerCommands = true;
	AgeRestrictedCommands = true;
	ChatCommands = true;
	CrossServerCommands = true;
	WarnDangerousCommand = false;
	CommandFeedback = false;
	SilentCommandDenials = false;
	OverrideChatCallbacks = true;
	ChatCreateRobloxCommands = false;

	CodeExecution = false;

	Notification = false;		-- Migrado de DisableAllNotices = true
	SongHint = true;
	TopBarShift = false;

	AutoClean = false;
	AutoCleanDelay = 60;
	AutoBackup = false;
	ReJail = false;

	Console = true;
	Console_AdminsOnly = false;

	HelpSystem = true;
	HelpButton = true;
	HelpButtonImage = "rbxassetid://357249130";

	HttpWait = 60;
};