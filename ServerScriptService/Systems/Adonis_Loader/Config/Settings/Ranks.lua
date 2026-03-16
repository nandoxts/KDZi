-------------------------------
-- Scroll down for settings  --
-------------------------------

--[[
	RANGOS DINÁMICOS - Lee todo desde Configuration.lua
	NO edites este archivo. Edita ReplicatedStorage.Config.Configuration
	
	Secciones en Configuration.lua:
		AdminOwners          → Creators (nivel 900)
		CreatorGroupRanks    → Group ranks que son Creator
		AdminRanksByGroup    → Rangos del grupo con su nivel
		AdminRanksByGamepass → Rangos por gamepass con su nivel
--]]

--------------------
-- RANKS SETTINGS --
--------------------

local Configuration = require(game.ReplicatedStorage.Config.Configuration)
local GroupID = tostring(Configuration.GroupID)

-- Construir tabla de rangos dinámicamente desde GroupRoles
local Ranks = {}

-- 1) Rangos por Grupo (lee AdminRank y AdminLevel de GroupRoles)
for groupRank, role in pairs(Configuration.GroupRoles) do
	if role.AdminRank and role.AdminLevel then
		local rankName = role.AdminRank
		if not Ranks[rankName] then
			Ranks[rankName] = {
				Level = role.AdminLevel;
				Users = {};
			}
		end
		table.insert(Ranks[rankName].Users, "Group:" .. GroupID .. ":" .. tostring(groupRank))
	end
end

-- 2) Rangos por Gamepass
for _, entry in ipairs(Configuration.AdminRanksByGamepass) do
	local gpId = Configuration.Gamepasses[entry.Gamepass]
	if gpId then
		Ranks[entry.Name] = {
			Level = entry.Level;
			Users = {
				"GamePass:" .. tostring(gpId.id);
			};
		}
	end
end

-- 3) Creators (Owners manuales + los que ya se agregaron por GroupRoles)
if not Ranks["Creators"] then
	Ranks["Creators"] = { Level = 900; Users = {}; }
end
for _, owner in ipairs(Configuration.AdminOwners) do
	table.insert(Ranks["Creators"].Users, owner.Username .. ":" .. tostring(owner.UserId))
end

return {
	Ranks = Ranks;
};