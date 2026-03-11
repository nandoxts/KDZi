-- PitchModule
local PitchModule = {}
PitchModule.ids = {

	-- ══════════════════════════════════════
	-- OSNER (pitch 0.53)
	-- ══════════════════════════════════════
	{id = "135417811216530", pitch = 0.53}, -- 1
	{id = "84702328612731",  pitch = 0.53}, -- 2
	{id = "136031513976301", pitch = 0.53}, -- 3
	{id = "111300866748688", pitch = 0.53}, -- 4
	{id = "97689806668639",  pitch = 0.53}, -- 5
	{id = "124499884200973", pitch = 0.53}, -- 6

	-- ══════════════════════════════════════
	-- MIX EVENTO (pitch 0.55)
	-- ══════════════════════════════════════
	{id = "91056654782114",  pitch = 0.55}, -- mix evento 1
	{id = "79636319744368",  pitch = 0.55}, -- mix evento 2
	{id = "106070776936626", pitch = 0.55}, -- mix evento 3
	{id = "99661825852792",  pitch = 0.55}, -- mix evento 4
	{id = "75682300076987",  pitch = 0.55}, -- mix evento 5

	-- ══════════════════════════════════════
	-- BRASIL (pitch 0.55)
	-- ══════════════════════════════════════
	{id = "91835794230886",  pitch = 0.55}, -- Brasil 1
	{id = "135221861285654", pitch = 0.55}, -- Brasil 2
	{id = "123726154148925", pitch = 0.55}, -- Brasil 3
	{id = "71113462173730",  pitch = 0.55}, -- Brasil 4

	-- ══════════════════════════════════════
	-- MAMBO (pitch 0.53)
	-- ══════════════════════════════════════
	{id = "110262504114041", pitch = 0.53}, -- mambo 1
	{id = "132834435895965", pitch = 0.53}, -- mambo 2
	{id = "91771143786217",  pitch = 0.53}, -- mambo 3

	-- ══════════════════════════════════════
	-- ELECTRO (pitch 0.50)
	-- ══════════════════════════════════════
	{id = "139261171534870", pitch = 0.50}, -- electro 1
	{id = "71919225833421",  pitch = 0.50}, -- electro 2
	{id = "112338591664877", pitch = 0.50}, -- electro 3
	{id = "96298510017263",  pitch = 0.50}, -- electro 4
	{id = "87531197067623",  pitch = 0.50}, -- electro 5
	{id = "89003112322262",  pitch = 0.50}, -- electro 6

	-- ══════════════════════════════════════
	-- PR / BOMBÓN / K / BL / GUARA / TECH HOUSE (pitch 0.51)
	-- ══════════════════════════════════════
	{id = "113015869576798", pitch = 0.51}, -- PR 1
	{id = "114549125381610", pitch = 0.51}, -- PR 2
	{id = "124860479994207", pitch = 0.51}, -- PR 3
	{id = "117509664307040", pitch = 0.51}, -- PR 4
	{id = "122625461496810", pitch = 0.51}, -- bombon 1
	{id = "117425562828826", pitch = 0.51}, -- bombon 2
	{id = "139519463786454", pitch = 0.51}, -- bombon 3
	{id = "114561282871171", pitch = 0.51}, -- K 1
	{id = "134856117280847", pitch = 0.51}, -- K 2
	{id = "118884694444310", pitch = 0.51}, -- K 3
	{id = "109907327413337", pitch = 0.51}, -- K 4
	{id = "98562319299238",  pitch = 0.51}, -- BL 1
	{id = "137522578600534", pitch = 0.51}, -- BL 2
	{id = "111944481838185", pitch = 0.51}, -- BL 3
	{id = "77806069857805",  pitch = 0.51}, -- GUARA 1
	{id = "99011867587195",  pitch = 0.51}, -- GUARA 2
	{id = "97732630710408",  pitch = 0.51}, -- tech house
	{id = "99126660768633",  pitch = 0.51}, -- tech house 2
	{id = "138249559268161", pitch = 0.51}, -- tech house 3

	-- ══════════════════════════════════════
	-- TRAP LATINO (pitch 0.37)
	-- ══════════════════════════════════════	 
	{id = "107999669968875", pitch = 0.37},--DEMBOW#1
	{id = "100209555946461", pitch = 0.37},--DEMBOW#2
	{id = "79672009991598", pitch = 0.37},--DEMBOW#3
	{id = "126032896148413", pitch = 0.37},--DEMBOW#4
	{id = "117731862006695", pitch = 0.37},--ELECTRO#1
	{id = "124607435121959", pitch = 0.37},--ELECTRO#2
	{id = "124572928979728", pitch = 0.37},--ELECTRO#3
	{id = "94749813540059", pitch = 0.37},--DADY YANKE
	{id = "130390028541855", pitch = 0.37},--FREAKS
	{id = "84451961706161", pitch = 0.37},--FREAKS

	{id = "98323432740085", pitch = 0.37},--DEMBOW#1
	{id = "132925539733291", pitch = 0.37}, -- Gyal You A Party Animal
	{id = "72406866872082", pitch = 0.37}, -- One Of the Girls
	{id = "133801963582628", pitch = 0.37}, -- TOky
	{id = "117842056144641", pitch = 0.37}, -- Daddy Yankee & Wisin y Yandel - Si Supieras
	{id = "82107477883846", pitch = 0.37}, -- DEMBOWSS 1
	{id = "89810670814532", pitch = 0.37}, -- DEMBOWSS 2
	{id = "118376709882037", pitch = 0.37}, -- DEMBOWSS 3
	{id = "134174859874864", pitch = 0.37},
	{id = "94088385927435", pitch = 0.37},
	{id = "139690188078826", pitch = 0.37},
}

for i, entry in ipairs(PitchModule.ids) do
	if type(entry.id) ~= "string" then
		entry.id = tostring(entry.id)
	end
	if type(entry.pitch) ~= "number" then
		entry.pitch = tonumber(entry.pitch) or 1.0
	end
end

return PitchModule