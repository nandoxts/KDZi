--[[
	Adonis API - Punto de conexión con el sistema KDZi
	
	Si necesitas acceder a Adonis desde otros scripts, usa:
		_G.Adonis.CheckAdmin(player)  -- Verificar si es admin
		_G.Adonis.GetLevel(player)    -- Obtener nivel del jugador
	
	Requiere G_API = true en _GAPI.lua

	Wiki: https://github.com/Epix-Incorporated/Adonis/wiki
	
	Mapeo de Niveles (referencia rápida):
		0   = Sin rango (NonAdmin)
		10  = VIP (Gamepass)
		20  = COMMANDS (Gamepass)
		50  = Socio (Grupo rank 246)
		75  = Influencer (Grupo rank 247)
		100 = DJ (Grupo rank 248)
		150 = Moderador (Grupo rank 249)
		200 = Administrador (Grupo rank 250)
		300 = Head Admin (Grupo rank 251)
		350 = Lead Admin (Grupo rank 252)
		400 = Help Creator (Grupo rank 253)
		900 = Creators/Owner (Grupo rank 254-255)
]]
