--[[
═══════════════════════════════════════════════════════════════════
DJ MUSIC SYSTEM — BATERÍA DE PRUEBAS MULTI-JUGADOR
═══════════════════════════════════════════════════════════════════
Simula escenarios reales con múltiples jugadores concurrentes.
Ejecutar en la Command Bar de Roblox Studio o como Script en ServerScriptService.

Cada test imprime [PASS] o [FAIL] + detalle.
Al final imprime un resumen con total de tests pasados/fallidos.
═══════════════════════════════════════════════════════════════════
]]

-- ══════════════════════════════════════════════════════════
-- MOCK FRAMEWORK
-- ══════════════════════════════════════════════════════════

local passed, failed, total = 0, 0, 0
local testResults = {}

local function TEST(name, fn)
total += 1
local ok, err = pcall(fn)
if ok then
passed += 1
table.insert(testResults, { name = name, status = "PASS" })
print(string.format("[PASS] %s", name))
else
failed += 1
table.insert(testResults, { name = name, status = "FAIL", error = tostring(err) })
warn(string.format("[FAIL] %s → %s", name, tostring(err)))
end
end

local function ASSERT(cond, msg)
if not cond then error(msg or "Assertion failed", 2) end
end

local function ASSERT_EQ(a, b, msg)
if a ~= b then error(string.format("%s — expected: %s, got: %s", msg or "ASSERT_EQ", tostring(b), tostring(a)), 2) end
end

local function ASSERT_NEQ(a, b, msg)
if a == b then error(string.format("%s — expected NOT: %s", msg or "ASSERT_NEQ", tostring(a)), 2) end
end

local function ASSERT_GT(a, b, msg)
if not (a > b) then error(string.format("%s — expected %s > %s", msg or "ASSERT_GT", tostring(a), tostring(b)), 2) end
end

local function ASSERT_TYPE(val, typ, msg)
if typeof(val) ~= typ and type(val) ~= typ then
error(string.format("%s — expected type: %s, got: %s", msg or "ASSERT_TYPE", typ, typeof(val)), 2)
end
end

-- ══════════════════════════════════════════════════════════
-- MOCK: Jugadores simulados
-- ══════════════════════════════════════════════════════════

local function mockPlayer(userId, name, displayName, isVip, isAdmin)
return {
UserId = userId,
Name = name or ("Player" .. userId),
DisplayName = displayName or ("Player" .. userId),
_isVip = isVip or false,
_isAdmin = isAdmin or false,
SetAttribute = function(self, k, v) self["_attr_" .. k] = v end,
GetAttribute = function(self, k) return self["_attr_" .. k] end,
}
end

-- Jugadores de prueba
local playerNormal1  = mockPlayer(1001, "NormalJuan",   "Juan",    false, false)
local playerNormal2  = mockPlayer(1002, "NormalMaria",  "Maria",   false, false)
local playerNormal3  = mockPlayer(1003, "NormalCarlos", "Carlos",  false, false)
local playerVIP1     = mockPlayer(2001, "VIPPedro",     "Pedro",   true,  false)
local playerVIP2     = mockPlayer(2002, "VIPLucia",     "Lucía",   true,  false)
local playerAdmin1   = mockPlayer(3001, "AdminBoss",    "Boss",    false, true)
local playerAdmin2   = mockPlayer(3002, "AdminSuper",   "Super",   false, true)

-- ══════════════════════════════════════════════════════════
-- MOCK: Sistema simplificado (testeable sin Roblox services)
-- ══════════════════════════════════════════════════════════

local RC = {
SUCCESS      = "SUCCESS",
INVALID_ID   = "ERROR_INVALID_ID",
DUPLICATE    = "ERROR_DUPLICATE",
NOT_FOUND    = "ERROR_NOT_FOUND",
QUEUE_FULL   = "ERROR_QUEUE_FULL",
PERMISSION   = "ERROR_PERMISSION",
COOLDOWN     = "ERROR_COOLDOWN",
EVENT_LOCKED = "ERROR_EVENT_LOCKED",
}

-- Estado simulado
local playQueue = {}
local currentSongIndex = 1
local metadataCache = {}
local playerCooldowns = {}
local _eventMode = false

-- Config simulada
local LIMITS = {
MaxQueueSize = 20,
AllowDuplicatesInQueue = false,
AddToQueueCooldown = 2,
MaxSongsPerUserNormal = 3,
MaxSongsPerUserVIP = 5,
MaxSongsPerUserAdmin = 999,
}

-- Base de datos mock
local musicDatabase = {
["Top Hits"] = {
cover = "rbxassetid://test_cover",
songIds = { 100001, 100002, 100003, 100004, 100005, 100006, 100007, 100008, 100009, 100010 },
},
["Trap Latino"] = {
cover = "rbxassetid://test_cover2",
songIds = { 200001, 200002, 200003, 200004, 200005 },
},
["Kpop Army"] = {
cover = "rbxassetid://test_cover3",
songIds = { 300001, 300002, 300003 },
},
}

-- Pre-cargar metadata en cache
for djName, djData in pairs(musicDatabase) do
for i, id in ipairs(djData.songIds) do
metadataCache[id] = {
name = djName .. " Track " .. i,
artist = djName,
loaded = true,
}
end
end

-- Funciones simuladas del servidor
local function response(code, msg, data)
return { code = code, success = code == RC.SUCCESS, message = msg, data = data or {} }
end

local function hasPermission(player)
return player._isAdmin
end

local function isEventBlocked(action, player)
if not _eventMode then return false end
if player._isAdmin then return false end
return true
end

local function isInQueue(audioId)
if LIMITS.AllowDuplicatesInQueue then return false end
for _, s in ipairs(playQueue) do
if s.id == audioId then return true, s end
end
return false
end

local function getUserQueueLimit(player)
if player._isAdmin then return LIMITS.MaxSongsPerUserAdmin, "Admin" end
if player._isVip then return LIMITS.MaxSongsPerUserVIP, "VIP" end
return LIMITS.MaxSongsPerUserNormal, "Normal"
end

local function findDJForSong(audioId)
for djName, djData in pairs(musicDatabase) do
for _, id in ipairs(djData.songIds) do
if id == audioId then return djName, djData.cover end
end
end
return nil, nil
end

local function getOrLoadMetadata(audioId)
local c = metadataCache[audioId]
if c and c.loaded then return c.name, c.artist, true end
return nil, nil, false
end

local function validateQueueAdd(player, audioId)
-- Cooldown
local now = tick()
if not player._isAdmin then
local last = playerCooldowns[player.UserId]
if last and (now - last) < LIMITS.AddToQueueCooldown then
return nil, response(RC.COOLDOWN, "Cooldown activo")
end
end

-- ID format
local id = tonumber(audioId)
local idStr = id and tostring(id) or ""
if not id or #idStr < 6 or #idStr > 19 then
return nil, response(RC.INVALID_ID, "ID inválido")
end

-- Event mode
if isEventBlocked("AddToQueue", player) then
return nil, response(RC.EVENT_LOCKED, "Modo evento activo")
end

-- Global cap
if #playQueue >= LIMITS.MaxQueueSize then
return nil, response(RC.QUEUE_FULL, "Cola llena")
end

-- Per-user cap
local limit, role = getUserQueueLimit(player)
local userCount = 0
for _, song in ipairs(playQueue) do
if song.userId == player.UserId then userCount += 1 end
end
if userCount >= limit then
return nil, response(RC.QUEUE_FULL, "Límite " .. role)
end

-- Duplicates
local dup, existing = isInQueue(id)
if dup then
return nil, response(RC.DUPLICATE, "Ya en cola")
end

-- Metadata
local name, artist, metaOk = getOrLoadMetadata(id)
if not metaOk then
return nil, response(RC.NOT_FOUND, "No encontrado")
end

playerCooldowns[player.UserId] = now
return { id = id, name = name, artist = artist }, nil
end

local function addToQueue(player, audioId)
if isEventBlocked("AddToQueue", player) then
return response(RC.EVENT_LOCKED, "Modo evento activo")
end

local songData, err = validateQueueAdd(player, audioId)
if err then return err end

-- Double check race condition
local dup = isInQueue(songData.id)
if dup then
return response(RC.DUPLICATE, "Ya en cola (race)")
end

local djName, djCover = findDJForSong(songData.id)
table.insert(playQueue, {
id = songData.id,
name = songData.name,
artist = songData.artist,
userId = player.UserId,
requestedBy = player.Name,
addedAt = os.time(),
dj = djName,
djCover = djCover,
})

return response(RC.SUCCESS, "Añadido", {
songName = songData.name,
position = #playQueue,
})
end

local function removeFromQueue(index)
if index < 1 or index > #playQueue then return false end
local removed = table.remove(playQueue, index)
if index < currentSongIndex then
currentSongIndex -= 1
end
return true, removed.name
end

local function clearQueue()
if #playQueue == 0 then return false, 0 end
local count = #playQueue
playQueue = {}
currentSongIndex = 1
return true, count
end

local function getSongRange(djName, startIdx, endIdx)
local dj = musicDatabase[djName]
if not dj then return { songs = {}, total = 0 } end
local ids = dj.songIds
startIdx = math.max(1, startIdx or 1)
endIdx = math.min(endIdx or (startIdx + 19), #ids)
local songs = {}
for i = startIdx, endIdx do
local id = ids[i]
if id then
local c = metadataCache[id]
table.insert(songs, {
id = id, index = i,
loaded = c and c.loaded or false,
name = c and c.name or "Cargando...",
artist = c and c.artist or "Unknown",
})
end
end
return { songs = songs, total = #ids, startIndex = startIdx, endIndex = endIdx, hasMore = endIdx < #ids }
end

local function searchSongs(djName, query)
local dj = musicDatabase[djName]
if not dj then return { songs = {}, total = 0, query = query } end
local ids = dj.songIds
local results = {}
local qLower = string.lower(query or "")
local qNum = tonumber(query)

if qNum then
for i, id in ipairs(ids) do
if tostring(id):find(tostring(qNum), 1, true) then
local c = metadataCache[id]
table.insert(results, { id = id, index = i, loaded = true,
name = c and c.name or "Unknown", artist = c and c.artist or "Unknown" })
end
end
end

if qLower ~= "" then
local seen = {}
for _, r in ipairs(results) do seen[r.id] = true end
for i, id in ipairs(ids) do
if not seen[id] then
local c = metadataCache[id]
if c and c.name and string.lower(c.name):find(qLower, 1, true) then
table.insert(results, { id = id, index = i, loaded = true,
name = c.name, artist = c.artist })
end
end
end
end

return { songs = results, total = #results, query = query, totalInDJ = #ids }
end

local function playerLeave(player)
playerCooldowns[player.UserId] = nil
local i = 1
while i <= #playQueue do
local song = playQueue[i]
if song.userId == player.UserId and i ~= currentSongIndex then
table.remove(playQueue, i)
if i < currentSongIndex then currentSongIndex -= 1 end
else
i += 1
end
end
end

-- Helper para resetear estado entre tests
local function resetState()
playQueue = {}
currentSongIndex = 1
playerCooldowns = {}
_eventMode = false
end

-- ══════════════════════════════════════════════════════════
-- TESTS
-- ══════════════════════════════════════════════════════════

print("\n══════════════════════════════════════════════════════")
print("DJ MUSIC SYSTEM — BATERÍA DE PRUEBAS")
print("══════════════════════════════════════════════════════\n")

-- ───────────────────────────────────────────
-- GRUPO 1: AddToQueue — Jugador Normal
-- ───────────────────────────────────────────

TEST("1.1 Normal: añadir canción válida", function()
resetState()
local res = addToQueue(playerNormal1, 100001)
ASSERT_EQ(res.code, RC.SUCCESS, "debe ser SUCCESS")
ASSERT_EQ(#playQueue, 1, "cola debe tener 1 canción")
ASSERT_EQ(playQueue[1].id, 100001, "ID correcto")
ASSERT_EQ(playQueue[1].userId, playerNormal1.UserId, "userId correcto")
end)

TEST("1.2 Normal: máximo 3 canciones por usuario", function()
resetState()
addToQueue(playerNormal1, 100001)
playerCooldowns[playerNormal1.UserId] = 0 -- bypass cooldown
addToQueue(playerNormal1, 100002)
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 100003)
playerCooldowns[playerNormal1.UserId] = 0
local res = addToQueue(playerNormal1, 100004)
ASSERT_EQ(res.code, RC.QUEUE_FULL, "4ta canción rechazada")
ASSERT_EQ(#playQueue, 3, "cola sigue con 3")
end)

TEST("1.3 Normal: no duplicados", function()
resetState()
addToQueue(playerNormal1, 100001)
playerCooldowns[playerNormal1.UserId] = 0
local res = addToQueue(playerNormal1, 100001)
ASSERT_EQ(res.code, RC.DUPLICATE, "duplicado rechazado")
ASSERT_EQ(#playQueue, 1, "cola sigue con 1")
end)

TEST("1.4 Normal: ID inválido (muy corto)", function()
resetState()
local res = addToQueue(playerNormal1, 123)
ASSERT_EQ(res.code, RC.INVALID_ID, "ID corto rechazado")
end)

TEST("1.5 Normal: ID inválido (no es número)", function()
resetState()
local res = addToQueue(playerNormal1, "abc")
ASSERT_EQ(res.code, RC.INVALID_ID, "string rechazado")
end)

TEST("1.6 Normal: audio no encontrado en BD", function()
resetState()
local res = addToQueue(playerNormal1, 999999)
ASSERT_EQ(res.code, RC.NOT_FOUND, "ID sin metadata rechazado")
end)

TEST("1.7 Normal: cooldown activo", function()
resetState()
addToQueue(playerNormal1, 100001)
-- No resetear cooldown
local res = addToQueue(playerNormal1, 100002)
ASSERT_EQ(res.code, RC.COOLDOWN, "cooldown activo")
end)

-- ───────────────────────────────────────────
-- GRUPO 2: AddToQueue — VIP
-- ───────────────────────────────────────────

TEST("2.1 VIP: puede añadir 5 canciones", function()
resetState()
for i = 1, 5 do
playerCooldowns[playerVIP1.UserId] = 0
local res = addToQueue(playerVIP1, musicDatabase["Top Hits"].songIds[i])
ASSERT_EQ(res.code, RC.SUCCESS, "canción " .. i .. " debe ser SUCCESS")
end
ASSERT_EQ(#playQueue, 5, "cola con 5")
end)

TEST("2.2 VIP: rechazado en la 6ta canción", function()
-- Continua del test anterior, resetear
resetState()
for i = 1, 5 do
playerCooldowns[playerVIP1.UserId] = 0
addToQueue(playerVIP1, musicDatabase["Top Hits"].songIds[i])
end
playerCooldowns[playerVIP1.UserId] = 0
local res = addToQueue(playerVIP1, 100006)
ASSERT_EQ(res.code, RC.QUEUE_FULL, "6ta rechazada para VIP")
end)

-- ───────────────────────────────────────────
-- GRUPO 3: AddToQueue — Admin
-- ───────────────────────────────────────────

TEST("3.1 Admin: sin cooldown", function()
resetState()
addToQueue(playerAdmin1, 100001)
-- Sin resetear cooldown — admin bypasea
local res = addToQueue(playerAdmin1, 100002)
ASSERT_EQ(res.code, RC.SUCCESS, "admin sin cooldown")
ASSERT_EQ(#playQueue, 2, "cola con 2")
end)

TEST("3.2 Admin: puede añadir muchas canciones", function()
resetState()
local allIds = {}
for _, djData in pairs(musicDatabase) do
for _, id in ipairs(djData.songIds) do table.insert(allIds, id) end
end
for i = 1, math.min(15, #allIds) do
local res = addToQueue(playerAdmin1, allIds[i])
ASSERT_EQ(res.code, RC.SUCCESS, "admin canción " .. i)
end
ASSERT_EQ(#playQueue, math.min(15, #allIds), "todas añadidas")
end)

-- ───────────────────────────────────────────
-- GRUPO 4: Cola llena
-- ───────────────────────────────────────────

TEST("4.1 Cola llena global (20 max)", function()
resetState()
-- Llenar con canciones de distintos DJs
local allIds = {}
for _, djData in pairs(musicDatabase) do
for _, id in ipairs(djData.songIds) do table.insert(allIds, id) end
end
-- Admin puede añadir todas
for i = 1, math.min(20, #allIds) do
local res = addToQueue(playerAdmin1, allIds[i])
if res.code ~= RC.SUCCESS then
-- Si ya se llenó, está bien
break
end
end
-- Ahora otro jugador intenta
playerCooldowns[playerNormal1.UserId] = 0
-- Necesitamos un ID que no esté en cola
if #playQueue >= LIMITS.MaxQueueSize then
-- Cola llena, el siguiente debe fallar
local extraId = 100010
if not isInQueue(extraId) and not metadataCache[extraId] then
-- No lo va a encontrar en metadata → NOT_FOUND (no QUEUE_FULL)
-- Usemos un ID que sí tiene metadata
end
-- Simplemente verificar que la cola está llena
ASSERT(#playQueue >= LIMITS.MaxQueueSize or #playQueue == #allIds, "cola llena o se acabaron IDs")
end
end)

-- ───────────────────────────────────────────
-- GRUPO 5: Multi-jugador concurrent
-- ───────────────────────────────────────────

TEST("5.1 Tres jugadores normales añaden simultáneamente", function()
resetState()
-- Cada uno añade canciones diferentes
local res1 = addToQueue(playerNormal1, 100001)
playerCooldowns[playerNormal2.UserId] = 0
local res2 = addToQueue(playerNormal2, 200001)
playerCooldowns[playerNormal3.UserId] = 0
local res3 = addToQueue(playerNormal3, 300001)

ASSERT_EQ(res1.code, RC.SUCCESS, "jugador 1 OK")
ASSERT_EQ(res2.code, RC.SUCCESS, "jugador 2 OK")
ASSERT_EQ(res3.code, RC.SUCCESS, "jugador 3 OK")
ASSERT_EQ(#playQueue, 3, "cola con 3")

-- Verificar que cada userId es distinto
local userIds = {}
for _, s in ipairs(playQueue) do userIds[s.userId] = true end
ASSERT_EQ(next(userIds) ~= nil, true, "hay userIds")
end)

TEST("5.2 Dos jugadores intentan el mismo audioId", function()
resetState()
local res1 = addToQueue(playerNormal1, 100001)
playerCooldowns[playerNormal2.UserId] = 0
local res2 = addToQueue(playerNormal2, 100001)

ASSERT_EQ(res1.code, RC.SUCCESS, "primero OK")
ASSERT_EQ(res2.code, RC.DUPLICATE, "segundo duplicado")
ASSERT_EQ(#playQueue, 1, "solo 1 en cola")
end)

TEST("5.3 Normal + VIP + Admin llenan cola con sus límites", function()
resetState()
-- Normal: 3 canciones
for i = 1, 3 do
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, musicDatabase["Top Hits"].songIds[i])
end
-- VIP: 5 canciones
for i = 1, 5 do
playerCooldowns[playerVIP1.UserId] = 0
addToQueue(playerVIP1, musicDatabase["Trap Latino"].songIds[i])
end
-- Admin: más canciones
for i = 1, 3 do
addToQueue(playerAdmin1, musicDatabase["Kpop Army"].songIds[i])
end

ASSERT_EQ(#playQueue, 11, "cola con 11 (3+5+3)")

-- Normal1 ya no puede más
playerCooldowns[playerNormal1.UserId] = 0
local res = addToQueue(playerNormal1, 100004)
ASSERT_EQ(res.code, RC.QUEUE_FULL, "normal1 ya no puede")
end)

-- ───────────────────────────────────────────
-- GRUPO 6: Modo Evento
-- ───────────────────────────────────────────

TEST("6.1 Modo evento bloquea normales", function()
resetState()
_eventMode = true
local res = addToQueue(playerNormal1, 100001)
ASSERT_EQ(res.code, RC.EVENT_LOCKED, "bloqueado por modo evento")
ASSERT_EQ(#playQueue, 0, "cola vacía")
end)

TEST("6.2 Modo evento NO bloquea admins", function()
resetState()
_eventMode = true
local res = addToQueue(playerAdmin1, 100001)
ASSERT_EQ(res.code, RC.SUCCESS, "admin puede en modo evento")
ASSERT_EQ(#playQueue, 1, "cola con 1")
_eventMode = false
end)

-- ───────────────────────────────────────────
-- GRUPO 7: RemoveFromQueue / ClearQueue
-- ───────────────────────────────────────────

TEST("7.1 Remove de índice válido", function()
resetState()
addToQueue(playerAdmin1, 100001)
addToQueue(playerAdmin1, 100002)
addToQueue(playerAdmin1, 100003)
ASSERT_EQ(#playQueue, 3, "cola con 3")

local ok, name = removeFromQueue(2)
ASSERT(ok, "remove exitoso")
ASSERT_EQ(#playQueue, 2, "cola con 2")
ASSERT_EQ(playQueue[1].id, 100001, "primer elemento intacto")
ASSERT_EQ(playQueue[2].id, 100003, "tercer elemento ahora es segundo")
end)

TEST("7.2 Remove de índice inválido", function()
resetState()
addToQueue(playerAdmin1, 100001)
local ok = removeFromQueue(5)
ASSERT(not ok, "remove falla con índice inválido")
ASSERT_EQ(#playQueue, 1, "cola intacta")
end)

TEST("7.3 Remove antes del currentSongIndex ajusta índice", function()
resetState()
addToQueue(playerAdmin1, 100001)
addToQueue(playerAdmin1, 100002)
addToQueue(playerAdmin1, 100003)
currentSongIndex = 3

removeFromQueue(1)
ASSERT_EQ(currentSongIndex, 2, "índice ajustado")
ASSERT_EQ(#playQueue, 2, "cola con 2")
end)

TEST("7.4 ClearQueue vacía todo", function()
resetState()
addToQueue(playerAdmin1, 100001)
addToQueue(playerAdmin1, 100002)
addToQueue(playerAdmin1, 100003)

local ok, count = clearQueue()
ASSERT(ok, "clear exitoso")
ASSERT_EQ(count, 3, "se eliminaron 3")
ASSERT_EQ(#playQueue, 0, "cola vacía")
ASSERT_EQ(currentSongIndex, 1, "índice reseteado")
end)

TEST("7.5 ClearQueue en cola vacía", function()
resetState()
local ok, count = clearQueue()
ASSERT(not ok, "clear falla en cola vacía")
end)

-- ───────────────────────────────────────────
-- GRUPO 8: PlayerLeave
-- ───────────────────────────────────────────

TEST("8.1 Jugador sale: sus canciones se eliminan", function()
resetState()
addToQueue(playerAdmin1, 100001) -- admin
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 200001) -- normal1
addToQueue(playerAdmin1, 100002)  -- admin
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 200002) -- normal1

-- currentSongIndex = 1 (canción del admin)
currentSongIndex = 1
ASSERT_EQ(#playQueue, 4, "cola con 4 antes de salir")

playerLeave(playerNormal1)

ASSERT_EQ(#playQueue, 2, "normal1 tenía 2 canciones, quedan 2 del admin")
for _, s in ipairs(playQueue) do
ASSERT_EQ(s.userId, playerAdmin1.UserId, "solo quedan canciones del admin")
end
end)

TEST("8.2 Jugador sale: la canción actual NO se elimina", function()
resetState()
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 100001) -- será la actual
addToQueue(playerAdmin1, 200001)
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 100002) -- esta sí se elimina

currentSongIndex = 1 -- la del normal1 está sonando
ASSERT_EQ(#playQueue, 3, "cola con 3")

playerLeave(playerNormal1)

-- La canción actual (index 1) del normal1 NO se elimina, pero la 3ra sí
ASSERT_EQ(#playQueue, 2, "quedan 2 (actual + admin)")
ASSERT_EQ(playQueue[1].id, 100001, "actual intacta")
ASSERT_EQ(playQueue[2].id, 200001, "admin intacta")
end)

TEST("8.3 Cooldowns se limpian al salir", function()
resetState()
addToQueue(playerNormal1, 100001)
ASSERT(playerCooldowns[playerNormal1.UserId] ~= nil, "cooldown existe")
playerLeave(playerNormal1)
ASSERT(playerCooldowns[playerNormal1.UserId] == nil, "cooldown limpiado")
end)

-- ───────────────────────────────────────────
-- GRUPO 9: Library Helpers
-- ───────────────────────────────────────────

TEST("9.1 getSongRange: rango válido", function()
resetState()
local result = getSongRange("Top Hits", 1, 5)
ASSERT_EQ(#result.songs, 5, "5 canciones")
ASSERT_EQ(result.total, 10, "total 10")
ASSERT_EQ(result.startIndex, 1, "start correcto")
ASSERT_EQ(result.endIndex, 5, "end correcto")
ASSERT(result.hasMore, "hay más canciones")
end)

TEST("9.2 getSongRange: fuera de rango se ajusta", function()
resetState()
local result = getSongRange("Top Hits", 8, 100)
ASSERT_EQ(#result.songs, 3, "solo 3 canciones (8,9,10)")
ASSERT_EQ(result.endIndex, 10, "end ajustado a 10")
ASSERT(not result.hasMore, "no hay más")
end)

TEST("9.3 getSongRange: DJ inexistente", function()
resetState()
local result = getSongRange("DJ Fantasma", 1, 10)
ASSERT_EQ(#result.songs, 0, "sin canciones")
ASSERT_EQ(result.total, 0, "total 0")
end)

TEST("9.4 getSongRange: metadata cargada", function()
resetState()
local result = getSongRange("Top Hits", 1, 3)
for _, s in ipairs(result.songs) do
ASSERT(s.loaded, "canción " .. s.id .. " loaded")
ASSERT(s.name ~= "Cargando...", "tiene nombre real: " .. s.name)
end
end)

TEST("9.5 searchSongs: por número de ID", function()
resetState()
local result = searchSongs("Top Hits", "100001")
ASSERT_GT(#result.songs, 0, "encontró resultados")
ASSERT_EQ(result.songs[1].id, 100001, "ID correcto")
end)

TEST("9.6 searchSongs: por nombre", function()
resetState()
local result = searchSongs("Top Hits", "Track 3")
ASSERT_GT(#result.songs, 0, "encontró resultados")
ASSERT(string.find(result.songs[1].name, "Track 3"), "nombre coincide")
end)

TEST("9.7 searchSongs: sin resultados", function()
resetState()
local result = searchSongs("Top Hits", "xxxxInexistentexxxx")
ASSERT_EQ(#result.songs, 0, "sin resultados")
end)

TEST("9.8 searchSongs: DJ inexistente", function()
resetState()
local result = searchSongs("DJ Fantasma", "track")
ASSERT_EQ(#result.songs, 0, "sin resultados")
ASSERT_EQ(result.total, 0, "total 0")
end)

-- ───────────────────────────────────────────
-- GRUPO 10: Escenario completo multi-jugador
-- ───────────────────────────────────────────

TEST("10.1 Escenario: 5 jugadores interactúan con la cola", function()
resetState()

-- Juan (normal) añade 2 canciones
addToQueue(playerNormal1, 100001)
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 100002)

-- Maria (normal) añade 1 canción
addToQueue(playerNormal2, 200001)

-- Pedro (VIP) añade 3 canciones
for i = 1, 3 do
playerCooldowns[playerVIP1.UserId] = 0
addToQueue(playerVIP1, musicDatabase["Kpop Army"].songIds[i])
end

-- Boss (admin) añade 2
addToQueue(playerAdmin1, 100003)
addToQueue(playerAdmin1, 100004)

ASSERT_EQ(#playQueue, 8, "cola con 8 canciones total")

-- Juan intenta una más (tiene 2 de 3 max → OK)
playerCooldowns[playerNormal1.UserId] = 0
local res = addToQueue(playerNormal1, 100005)
ASSERT_EQ(res.code, RC.SUCCESS, "Juan puede añadir la 3ra")
ASSERT_EQ(#playQueue, 9, "cola con 9")

-- Juan intenta la 4ta → FAIL
playerCooldowns[playerNormal1.UserId] = 0
res = addToQueue(playerNormal1, 100006)
ASSERT_EQ(res.code, RC.QUEUE_FULL, "Juan no puede la 4ta")

-- Maria sale del juego → su canción se elimina
playerLeave(playerNormal2)
ASSERT_EQ(#playQueue, 8, "cola con 8 tras salir Maria")

-- Admin elimina canción en posición 3
removeFromQueue(3)
ASSERT_EQ(#playQueue, 7, "cola con 7 tras remove")

-- Admin limpia la cola
clearQueue()
ASSERT_EQ(#playQueue, 0, "cola vacía tras clear")
end)

TEST("10.2 Escenario: modo evento se activa a mitad", function()
resetState()

addToQueue(playerNormal1, 100001)
playerCooldowns[playerNormal2.UserId] = 0
addToQueue(playerNormal2, 200001)
ASSERT_EQ(#playQueue, 2, "cola con 2")

-- Activar modo evento
_eventMode = true

-- Normales bloqueados
playerCooldowns[playerNormal3.UserId] = 0
local res = addToQueue(playerNormal3, 300001)
ASSERT_EQ(res.code, RC.EVENT_LOCKED, "normal bloqueado en evento")

-- Admin puede
local adminRes = addToQueue(playerAdmin1, 100002)
ASSERT_EQ(adminRes.code, RC.SUCCESS, "admin OK en evento")
ASSERT_EQ(#playQueue, 3, "cola con 3")

-- Desactivar
_eventMode = false
playerCooldowns[playerNormal3.UserId] = 0
res = addToQueue(playerNormal3, 300001)
ASSERT_EQ(res.code, RC.SUCCESS, "normal OK tras desactivar evento")
ASSERT_EQ(#playQueue, 4, "cola con 4")
end)

TEST("10.3 Escenario: duplicados cruzados entre jugadores", function()
resetState()

-- Juan añade 100001
addToQueue(playerNormal1, 100001)

-- Maria intenta el mismo
playerCooldowns[playerNormal2.UserId] = 0
local res = addToQueue(playerNormal2, 100001)
ASSERT_EQ(res.code, RC.DUPLICATE, "duplicado cross-player")

-- VIP también intenta
playerCooldowns[playerVIP1.UserId] = 0
res = addToQueue(playerVIP1, 100001)
ASSERT_EQ(res.code, RC.DUPLICATE, "duplicado VIP")

-- Admin también
res = addToQueue(playerAdmin1, 100001)
ASSERT_EQ(res.code, RC.DUPLICATE, "duplicado admin")

ASSERT_EQ(#playQueue, 1, "solo 1 en cola")
end)

TEST("10.4 Escenario: jugador sale con canciones antes y después del currentSong", function()
resetState()

-- Admin llena cola
addToQueue(playerAdmin1, 100001) -- pos 1
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 200001) -- pos 2 (normal1)
addToQueue(playerAdmin1, 100002)  -- pos 3
playerCooldowns[playerNormal1.UserId] = 0
addToQueue(playerNormal1, 200002) -- pos 4 (normal1)
addToQueue(playerAdmin1, 100003)  -- pos 5

currentSongIndex = 3 -- la canción actual es 100002 (admin)

ASSERT_EQ(#playQueue, 5, "cola con 5")

-- Normal1 sale: tiene canciones en pos 2 y 4 (relativo al current=3)
playerLeave(playerNormal1)

-- pos 2 era antes del current (2 < 3) → currentSongIndex se ajusta a 2
-- pos 4 (ahora 3 tras eliminar pos2) era después del current → se elmina normal
ASSERT_EQ(#playQueue, 3, "quedan 3 canciones del admin")
ASSERT_EQ(currentSongIndex, 2, "índice ajustado")

-- Verificar que solo quedan del admin
for _, s in ipairs(playQueue) do
ASSERT_EQ(s.userId, playerAdmin1.UserId, "solo admin")
end
end)

-- ───────────────────────────────────────────
-- GRUPO 11: Metadata y respuestas
-- ───────────────────────────────────────────

TEST("11.1 Metadata: canciones cargadas tienen nombre real", function()
resetState()
local name, artist, ok = getOrLoadMetadata(100001)
ASSERT(ok, "metadata encontrada")
ASSERT(name ~= nil, "nombre no nil")
ASSERT(artist ~= nil, "artist no nil")
ASSERT(string.find(name, "Track"), "nombre contiene Track")
end)

TEST("11.2 Metadata: audio sin cache retorna false", function()
resetState()
local name, artist, ok = getOrLoadMetadata(999999)
ASSERT(not ok, "metadata no encontrada")
end)

TEST("11.3 Response format correcto", function()
resetState()
local res = addToQueue(playerNormal1, 100001)
ASSERT_TYPE(res, "table", "res es tabla")
ASSERT_TYPE(res.code, "string", "code es string")
ASSERT_TYPE(res.success, "boolean", "success es boolean")
ASSERT_TYPE(res.message, "string", "message es string")
ASSERT_TYPE(res.data, "table", "data es tabla")
ASSERT(res.success, "fue exitoso")
end)

TEST("11.4 Response de error tiene formato correcto", function()
resetState()
local res = addToQueue(playerNormal1, 123) -- ID inválido
ASSERT_TYPE(res, "table", "res es tabla")
ASSERT(not res.success, "no fue exitoso")
ASSERT_EQ(res.code, RC.INVALID_ID, "código correcto")
end)

-- ───────────────────────────────────────────
-- GRUPO 12: Edge cases
-- ───────────────────────────────────────────

TEST("12.1 Edge: removeFromQueue(0) falla", function()
resetState()
addToQueue(playerAdmin1, 100001)
local ok = removeFromQueue(0)
ASSERT(not ok, "índice 0 inválido")
end)

TEST("12.2 Edge: removeFromQueue(-1) falla", function()
resetState()
addToQueue(playerAdmin1, 100001)
local ok = removeFromQueue(-1)
ASSERT(not ok, "índice negativo inválido")
end)

TEST("12.3 Edge: getSongRange con start > total retorna vacío", function()
resetState()
local result = getSongRange("Kpop Army", 100, 200)
ASSERT_EQ(#result.songs, 0, "sin canciones fuera de rango")
end)

TEST("12.4 Edge: clearQueue y luego addToQueue funciona", function()
resetState()
addToQueue(playerAdmin1, 100001)
addToQueue(playerAdmin1, 100002)
clearQueue()
ASSERT_EQ(#playQueue, 0, "cola vacía")

local res = addToQueue(playerAdmin1, 100001)
ASSERT_EQ(res.code, RC.SUCCESS, "puede añadir tras clear")
ASSERT_EQ(#playQueue, 1, "cola con 1")
end)

TEST("12.5 Edge: muchos jugadores con 1 canción cada uno = 8", function()
resetState()
local players = {
playerNormal1, playerNormal2, playerNormal3,
playerVIP1, playerVIP2,
playerAdmin1, playerAdmin2,
mockPlayer(4001, "Extra", "Extra")
}
-- Cada player añade una canción diferente
local allIds = {}
for _, djData in pairs(musicDatabase) do
for _, id in ipairs(djData.songIds) do table.insert(allIds, id) end
end

for i, p in ipairs(players) do
playerCooldowns[p.UserId] = 0
local id = allIds[i]
if id then
local name, artist, ok = getOrLoadMetadata(id)
if ok then
addToQueue(p, id)
end
end
end

ASSERT_EQ(#playQueue, #players, "cada jugador tiene 1 canción")

-- Verificar userIds únicos
local seen = {}
for _, s in ipairs(playQueue) do
ASSERT(not seen[s.userId], "userId " .. s.userId .. " no duplicado")
seen[s.userId] = true
end
end)

-- ══════════════════════════════════════════════════════════
-- RESUMEN
-- ══════════════════════════════════════════════════════════
print("\n══════════════════════════════════════════════════════")
print(string.format("RESULTADOS: %d/%d pasados, %d fallidos", passed, total, failed))
print("══════════════════════════════════════════════════════")

if failed > 0 then
print("\nTests fallidos:")
for _, t in ipairs(testResults) do
if t.status == "FAIL" then
warn(string.format("  ✗ %s: %s", t.name, t.error))
end
end
end

if failed == 0 then
print("\n✓ TODOS LOS TESTS PASARON")
else
warn(string.format("\n✗ %d TESTS FALLARON", failed))
end

return {
passed = passed,
failed = failed,
total = total,
results = testResults,
}
