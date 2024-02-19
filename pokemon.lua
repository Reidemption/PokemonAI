local Game = {
	new = function (self, game)
		self.__index = self
		setmetatable(game, self)
		return game
	end
}

function Game.getParty(game)
	local party = {}
	local monStart = game._party
	local nameStart = game._partyNames
	local otStart = game._partyOt
	for i = 1, emu:read8(game._partyCount) do
		party[i] = game:_readPartyMon(monStart, nameStart, otStart)
		monStart = monStart + game._partyMonSize
		if game._partyNames then
			nameStart = nameStart + game._monNameLength + 1
		end
		if game._partyOt then
			otStart = otStart + game._playerNameLength + 1
		end
	end
	return party
end

function IsBitSet(addr)
	return emu:read8(addr) > 0
end

function GetOpponentPartyCount()
	-- check every 100 bits and see if the values are more than 00s with 1 FF
	local memoryStartValues = { 0x0202402c, 0x02024090, 0x020240F4, 0x02024158, 0x020241bc, 0x02024220 }
	local opponentPartyCount = 0
	for _, v in ipairs(memoryStartValues) do
		if AreBitsSetInRange(v) then
			opponentPartyCount = opponentPartyCount + 1
		end
	end
	return opponentPartyCount
end

function AreBitsSetInRange(startLocation)
	local numSetBits = 0
	local threshold = 5 --  there should be at least a couple of bits set by this point
	local bitCheckSize = 25

	for i = 1, bitCheckSize do
			local currentLocation = startLocation + (0x4 * i-1)
			if IsBitSet(currentLocation) then
					numSetBits = numSetBits + 1
			end
	end
	return numSetBits >= threshold
end

function Game.getEnemyParty(game)
	local party = {}
	local monStart = game._opponentParty
	local opponentPartyCount = GetOpponentPartyCount()
	for i = 1, opponentPartyCount do
		party[i] = game:_readPartyMon(monStart)
		monStart = monStart + game._partyMonSize
	end
	return party
end

function Game.toString(game, rawstring)
	local string = ""
	for _, char in ipairs({rawstring:byte(1, #rawstring)}) do
		if char == game._terminator then
			break
		end
		string = string..game._charmap[char]
	end
	return string
end

function Game.getSpeciesName(game, id)
	if game._speciesIndex then
		local index = game._index
		if not index then
			index = {}
			for i = 0, 255 do
				index[emu.memory.cart0:read8(game._speciesIndex + i)] = i
			end
			game._index = index
		end
		id = index[id]
	end
	local pointer = game._speciesNameTable + (game._speciesNameLength) * id
	return game:toString(emu.memory.cart0:readRange(pointer, game._monNameLength))
end

local GBAGameEn = Game:new{
	_terminator=0xFF,
	_monNameLength=10,
	_speciesNameLength=11,
	_playerNameLength=10,
}

local Generation3En = GBAGameEn:new{
	_boxMonSize=80,
	_partyMonSize=100,
}

GBAGameEn._charmap = { [0]=
	" ", "À", "Á", "Â", "Ç", "È", "É", "Ê", "Ë", "Ì", "こ", "Î", "Ï", "Ò", "Ó", "Ô",
	"Œ", "Ù", "Ú", "Û", "Ñ", "ß", "à", "á", "ね", "ç", "è", "é", "ê", "ë", "ì", "ま",
	"î", "ï", "ò", "ó", "ô", "œ", "ù", "ú", "û", "ñ", "º", "ª", "�", "&", "+", "あ",
	"ぃ", "ぅ", "ぇ", "ぉ", "v", "=", "ょ", "が", "ぎ", "ぐ", "げ", "ご", "ざ", "じ", "ず", "ぜ",
	"ぞ", "だ", "ぢ", "づ", "で", "ど", "ば", "び", "ぶ", "べ", "ぼ", "ぱ", "ぴ", "ぷ", "ぺ", "ぽ",
	"っ", "¿", "¡", "P\u{200d}k", "M\u{200d}n", "P\u{200d}o", "K\u{200d}é", "�", "�", "�", "Í", "%", "(", ")", "セ", "ソ",
	"タ", "チ", "ツ", "テ", "ト", "ナ", "ニ", "ヌ", "â", "ノ", "ハ", "ヒ", "フ", "ヘ", "ホ", "í",
	"ミ", "ム", "メ", "モ", "ヤ", "ユ", "ヨ", "ラ", "リ", "⬆", "⬇", "⬅", "➡", "ヲ", "ン", "ァ",
	"ィ", "ゥ", "ェ", "ォ", "ャ", "ュ", "ョ", "ガ", "ギ", "グ", "ゲ", "ゴ", "ザ", "ジ", "ズ", "ゼ",
	"ゾ", "ダ", "ヂ", "ヅ", "デ", "ド", "バ", "ビ", "ブ", "ベ", "ボ", "パ", "ピ", "プ", "ペ", "ポ",
	"ッ", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "!", "?", ".", "-", "・",
	"…", "“", "”", "‘", "’", "♂", "♀", "$", ",", "×", "/", "A", "B", "C", "D", "E",
	"F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
	"V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
	"l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "▶",
	":", "Ä", "Ö", "Ü", "ä", "ö", "ü", "⬆", "⬇", "⬅", "�", "�", "�", "�", "�", ""
}

function Generation3En._readBoxMon(game, address)
	local mon = {}
	mon.personality = emu:read32(address + 0)
	mon.otId = emu:read32(address + 4)
	mon.nickname = game:toString(emu:readRange(address + 8, game._monNameLength))
	mon.language = emu:read8(address + 18)
	local flags = emu:read8(address + 19)
	mon.isBadEgg = flags & 1
	mon.hasSpecies = (flags >> 1) & 1
	mon.isEgg = (flags >> 2) & 1
	mon.otName = game:toString(emu:readRange(address + 20, game._playerNameLength))
	mon.markings = emu:read8(address + 27)

	local key = mon.otId ~ mon.personality
	local substructSelector = {
		[ 0] = {0, 1, 2, 3},
		[ 1] = {0, 1, 3, 2},
		[ 2] = {0, 2, 1, 3},
		[ 3] = {0, 3, 1, 2},
		[ 4] = {0, 2, 3, 1},
		[ 5] = {0, 3, 2, 1},
		[ 6] = {1, 0, 2, 3},
		[ 7] = {1, 0, 3, 2},
		[ 8] = {2, 0, 1, 3},
		[ 9] = {3, 0, 1, 2},
		[10] = {2, 0, 3, 1},
		[11] = {3, 0, 2, 1},
		[12] = {1, 2, 0, 3},
		[13] = {1, 3, 0, 2},
		[14] = {2, 1, 0, 3},
		[15] = {3, 1, 0, 2},
		[16] = {2, 3, 0, 1},
		[17] = {3, 2, 0, 1},
		[18] = {1, 2, 3, 0},
		[19] = {1, 3, 2, 0},
		[20] = {2, 1, 3, 0},
		[21] = {3, 1, 2, 0},
		[22] = {2, 3, 1, 0},
		[23] = {3, 2, 1, 0},
	}

	local pSel = substructSelector[mon.personality % 24]
	local ss0 = {}
	local ss1 = {}
	local ss2 = {}
	local ss3 = {}

	for i = 0, 2 do
		ss0[i] = emu:read32(address + 32 + pSel[1] * 12 + i * 4) ~ key
		ss1[i] = emu:read32(address + 32 + pSel[2] * 12 + i * 4) ~ key
		ss2[i] = emu:read32(address + 32 + pSel[3] * 12 + i * 4) ~ key
		ss3[i] = emu:read32(address + 32 + pSel[4] * 12 + i * 4) ~ key
	end

	mon.species = ss0[0] & 0xFFFF
	mon.heldItem = ss0[0] >> 16
	mon.experience = ss0[1]
	mon.ppBonuses = ss0[2] & 0xFF
	mon.friendship = (ss0[2] >> 8) & 0xFF

	mon.moves = {
		ss1[0] & 0xFFFF,
		ss1[0] >> 16,
		ss1[1] & 0xFFFF,
		ss1[1] >> 16
	}
	mon.pp = {
		ss1[2] & 0xFF,
		(ss1[2] >> 8) & 0xFF,
		(ss1[2] >> 16) & 0xFF,
		ss1[2] >> 24
	}

	mon.hpEV = ss2[0] & 0xFF
	mon.attackEV = (ss2[0] >> 8) & 0xFF
	mon.defenseEV = (ss2[0] >> 16) & 0xFF
	mon.speedEV = ss2[0] >> 24
	mon.spAttackEV = ss2[1] & 0xFF
	mon.spDefenseEV = (ss2[1] >> 8) & 0xFF
	mon.cool = (ss2[1] >> 16) & 0xFF
	mon.beauty = ss2[1] >> 24
	mon.cute = ss2[2] & 0xFF
	mon.smart = (ss2[2] >> 8) & 0xFF
	mon.tough = (ss2[2] >> 16) & 0xFF
	mon.sheen = ss2[2] >> 24

	mon.pokerus = ss3[0] & 0xFF
	mon.metLocation = (ss3[0] >> 8) & 0xFF
	flags = ss3[0] >> 16
	mon.metLevel = flags & 0x7F
	mon.metGame = (flags >> 7) & 0xF
	mon.pokeball = (flags >> 11) & 0xF
	mon.otGender = (flags >> 15) & 0x1
	flags = ss3[1]
	mon.hpIV = flags & 0x1F
	mon.attackIV = (flags >> 5) & 0x1F
	mon.defenseIV = (flags >> 10) & 0x1F
	mon.speedIV = (flags >> 15) & 0x1F
	mon.spAttackIV = (flags >> 20) & 0x1F
	mon.spDefenseIV = (flags >> 25) & 0x1F
	-- Bit 30 is another "isEgg" bit
	mon.altAbility = (flags >> 31) & 1
	flags = ss3[2]
	mon.coolRibbon = flags & 7
	mon.beautyRibbon = (flags >> 3) & 7
	mon.cuteRibbon = (flags >> 6) & 7
	mon.smartRibbon = (flags >> 9) & 7
	mon.toughRibbon = (flags >> 12) & 7
	mon.championRibbon = (flags >> 15) & 1
	mon.winningRibbon = (flags >> 16) & 1
	mon.victoryRibbon = (flags >> 17) & 1
	mon.artistRibbon = (flags >> 18) & 1
	mon.effortRibbon = (flags >> 19) & 1
	mon.marineRibbon = (flags >> 20) & 1
	mon.landRibbon = (flags >> 21) & 1
	mon.skyRibbon = (flags >> 22) & 1
	mon.countryRibbon = (flags >> 23) & 1
	mon.nationalRibbon = (flags >> 24) & 1
	mon.earthRibbon = (flags >> 25) & 1
	mon.worldRibbon = (flags >> 26) & 1
	mon.eventLegal = (flags >> 27) & 0x1F
	return mon
end

function Generation3En._readPartyMon(game, address)
	local mon = game:_readBoxMon(address)
	mon.status = emu:read32(address + 80)
	mon.level = emu:read8(address + 84)
	mon.mail = emu:read32(address + 85)
	mon.hp = emu:read16(address + 86)
	mon.maxHP = emu:read16(address + 88)
	mon.attack = emu:read16(address + 90)
	mon.defense = emu:read16(address + 92)
	mon.speed = emu:read16(address + 94)
	mon.spAttack = emu:read16(address + 96)
	mon.spDefense = emu:read16(address + 98)
	return mon
end

local gameFireRedEn = Generation3En:new{
	name="FireRed (USA)",
	_party=0x2024284,
	_partyCount=0x2024029,
	_speciesNameTable=0x245ee0,
	_opponentParty=0x202402c,
	_wildEncounterStepAddr=0x20386D6
}

local gameFireRedEnR1 = gameFireRedEn:new{
	name="FireRed (USA) (Rev 1)",
	_speciesNameTable=0x245f50,
}

local moveNamesList = {
  "Pound", "Karate Chop", "Double Slap", "Comet Punch", "Mega Punch", "Pay Day", "Fire Punch", "Ice Punch",
  "Thunder Punch", "Scratch", "Vice Grip", "Guillotine", "Razor Wind", "Swords Dance", "Cut", "Gust", "Wing Attack",
  "Whirlwind", "Fly", "Bind", "Slam", "Vine Whip", "Stomp", "Double Kick", "Mega Kick", "Jump Kick", "Rolling Kick",
  "Sand Attack", "Headbutt", "Horn Attack", "Fury Attack", "Horn Drill", "Tackle", "Body Slam", "Wrap", "Take Down",
  "Thrash", "Double-Edge", "Tail Whip", "Poison Sting", "Twineedle", "Pin Missile", "Leer", "Bite", "Growl", "Roar",
  "Sing", "Supersonic", "Sonic Boom", "Disable", "Acid", "Ember", "Flamethrower", "Mist", "Water Gun", "Hydro Pump",
  "Surf", "Ice Beam", "Blizzard", "Psybeam", "Bubble Beam", "Aurora Beam", "Hyper Beam", "Peck", "Drill Peck",
  "Submission", "Low Kick", "Counter", "Seismic Toss", "Strength", "Absorb", "Mega Drain", "Leech Seed", "Growth",
  "Razor Leaf", "Solar Beam", "Poison Powder", "Stun Spore", "Sleep Powder", "Petal Dance", "String Shot",
  "Dragon Rage", "Fire Spin", "Thunder Shock", "Thunderbolt", "Thunder Wave", "Thunder", "Rock Throw", "Earthquake",
  "Fissure", "Dig", "Toxic", "Confusion", "Psychic", "Hypnosis", "Meditate", "Agility", "Quick Attack", "Rage",
  "Teleport", "Night Shade", "Mimic", "Screech", "Double Team", "Recover", "Harden", "Minimize", "Smokescreen",
  "Confuse Ray", "Withdraw", "Defense Curl", "Barrier", "Light Screen", "Haze", "Reflect", "Focus Energy", "Bide",
  "Metronome", "Mirror Move", "Self-Destruct", "Egg Bomb", "Lick", "Smog", "Sludge", "Bone Club", "Fire Blast",
  "Waterfall", "Clamp", "Swift", "Skull Bash", "Spike Cannon", "Constrict", "Amnesia", "Kinesis", "Soft-Boiled",
  "High Jump Kick", "Glare", "Dream Eater", "Poison Gas", "Barrage", "Leech Life", "Lovely Kiss", "Sky Attack",
  "Transform", "Bubble", "Dizzy Punch", "Spore", "Flash", "Psywave", "Splash", "Acid Armor", "Crabhammer",
  "Explosion", "Fury Swipes", "Bonemerang", "Rest", "Rock Slide", "Hyper Fang", "Sharpen", "Conversion", "Tri Attack",
  "Super Fang", "Slash", "Substitute", "Struggle", "Sketch", "Triple Kick", "Thief", "Spider Web", "Mind Reader",
  "Nightmare", "Flame Wheel", "Snore", "Curse", "Flail", "Conversion 2", "Aeroblast", "Cotton Spore", "Reversal",
  "Spite", "Powder Snow", "Protect", "Mach Punch", "Scary Face", "Feint Attack", "Sweet Kiss", "Belly Drum",
  "Sludge Bomb", "Mud-Slap", "Octazooka", "Spikes", "Zap Cannon", "Foresight", "Destiny Bond", "Perish Song",
  "Icy Wind", "Detect", "Bone Rush", "Lock-On", "Outrage", "Sandstorm", "Giga Drain", "Endure", "Charm", "Rollout",
  "False Swipe", "Swagger", "Milk Drink", "Spark", "Fury Cutter", "Steel Wing", "Mean Look", "Attract", "Sleep Talk",
  "Heal Bell", "Return", "Present", "Frustration", "Safeguard", "Pain Split", "Sacred Fire", "Magnitude",
  "Dynamic Punch", "Megahorn", "Dragon Breath", "Baton Pass", "Encore", "Pursuit", "Rapid Spin", "Sweet Scent",
  "Iron Tail", "Metal Claw", "Vital Throw", "Morning Sun", "Synthesis", "Moonlight", "Hidden Power", "Cross Chop",
  "Twister", "Rain Dance", "Sunny Day", "Crunch", "Mirror Coat", "Psych Up", "Extreme Speed", "Ancient Power",
  "Shadow Ball", "Future Sight", "Rock Smash", "Whirlpool", "Beat Up", "Fake Out", "Uproar", "Stockpile", "Spit Up",
  "Swallow", "Heat Wave", "Hail", "Torment", "Flatter", "Will-O-Wisp", "Memento", "Facade", "Focus Punch",
  "Smelling Salts", "Follow Me", "Nature Power", "Charge", "Taunt", "Helping Hand", "Trick", "Role Play", "Wish",
  "Assist", "Ingrain", "Superpower", "Magic Coat", "Recycle", "Revenge", "Brick Break", "Yawn", "Knock Off", "Endeavor",
  "Eruption", "Skill Swap", "Imprison", "Refresh", "Grudge", "Snatch", "Secret Power", "Dive", "Arm Thrust", "Camouflage",
  "Tail Glow", "Luster Purge", "Mist Ball", "Feather Dance", "Teeter Dance", "Blaze Kick", "Mud Sport", "Ice Ball",
  "Needle Arm", "Slack Off", "Hyper Voice", "Poison Fang", "Crush Claw", "Blast Burn", "Hydro Cannon", "Meteor Mash",
  "Astonish", "Weather Ball", "Aromatherapy", "Fake Tears", "Air Cutter", "Overheat", "Odor Sleuth", "Rock Tomb",
  "Silver Wind", "Metal Sound", "Grass Whistle", "Tickle", "Cosmic Power", "Water Spout", "Signal Beam", "Shadow Punch",
  "Extrasensory", "Sky Uppercut", "Sand Tomb", "Sheer Cold", "Muddy Water", "Bullet Seed", "Aerial Ace", "Icicle Spear",
  "Iron Defense", "Block", "Howl", "Dragon Claw", "Frenzy Plant", "Bulk Up", "Bounce", "Mud Shot", "Poison Tail", "Covet",
  "Volt Tackle", "Magical Leaf", "Water Sport", "Calm Mind", "Leaf Blade", "Dragon Dance", "Rock Blast", "Shock Wave",
  "Water Pulse", "Doom Desire", "Psycho Boost"}

gameCodes = {
	["DMG-AAUE"]=gameGSEn, -- Gold
	["DMG-AAXE"]=gameGSEn, -- Silver
	["CGB-BYTE"]=gameCrystalEn,
	["AGB-AXVE"]=gameRubyEn,
	["AGB-AXPE"]=gameSapphireEn,
	["AGB-BPEE"]=gameEmeraldEn,
	["AGB-BPRE"]=gameFireRedEn,
	["AGB-BPGE"]=gameLeafGreenEn,
}

-- These versions have slight differences and/or cannot be uniquely
-- identified by their in-header game codes, so fall back on a CRC32
gameCrc32 = {
	[0x9f7fdd53] = gameRBEn, -- Red
	[0xd6da8a1a] = gameRBEn, -- Blue
	[0x7d527d62] = gameYellowEn,
	[0x84ee4776] = gameFireRedEnR1,
	[0xdaffecec] = gameLeafGreenEnR1,
	[0x61641576] = gameRubyEnR1, -- Rev 1
	[0xaeac73e6] = gameRubyEnR1, -- Rev 2
	[0xbafedae5] = gameSapphireEnR1, -- Rev 1
	[0x9cc4410e] = gameSapphireEnR1, -- Rev 2
}

function PrintPartyStatus(game, buffer)
	buffer:clear()
	buffer:print("Party Pokemon\n")
	for _, mon in ipairs(game:getParty()) do
		buffer:print(string.format("%-10s (Lv%3i %10s): %3i/%3i\n",
			mon.nickname,
			mon.level,
			game:getSpeciesName(mon.species),
			mon.hp,
			mon.maxHP,
			mon.moves[1],
			mon.moves[2],
			mon.moves[3],
			mon.moves[4]
		))
		buffer:print(string.format("%s: [%2i]; %s: [%2i]; %s: [%2i]; %s: [%2i];\n",
			moveNamesList[mon.moves[1]],
			mon.pp[1],
			moveNamesList[mon.moves[2]],
			mon.pp[2],
			moveNamesList[mon.moves[3]],
			mon.pp[3],
			moveNamesList[mon.moves[4]],
			mon.pp[4]
		))
	end
end

function PrintEnemyParty( game, buffer )
	buffer:clear()
	buffer:print("Enemy Pokemon\n")
	for _, mon in ipairs(game:getEnemyParty()) do
		buffer:print(string.format("%-10s (Lv%3i %10s): %3i/%3i\n",
			mon.nickname,
			mon.level,
			game:getSpeciesName(mon.species),
			mon.hp,
			mon.maxHP,
			mon.moves[1],
			mon.moves[2],
			mon.moves[3],
			mon.moves[4]
		))
		buffer:print(string.format("%s: [%2i]; %s: [%2i]; %s: [%2i]; %s: [%2i];\n",
			moveNamesList[mon.moves[1]],
			mon.pp[1],
			moveNamesList[mon.moves[2]],
			mon.pp[2],
			moveNamesList[mon.moves[3]],
			mon.pp[3],
			moveNamesList[mon.moves[4]],
			mon.pp[4]
		))
	end
end

keyQueue = {
	[0] = 0, --nothing
	[1] = C.GBA_KEY.UP, --64
	[2] = C.GBA_KEY.RIGHT, --16
	[3] = C.GBA_KEY.DOWN, --128
	[4] = C.GBA_KEY.LEFT --32
}

selectedKey = 1

counter = 0
-- takes about 800 frames to enter battle

function RunInSquare(buffer)
	buffer:print("Running\n")
	buffer:print(string.format("Counter: %d\n", counter))
	counter = counter + 1
	emu:clearKey(selectedKey)
	selectedKey = table.remove(keyQueue, 1)
	for _, key in ipairs(keyQueue) do
		buffer:print(string.format("Queue: %s\n", key))
	end
	buffer:print(string.format("Queue: %s\n", selectedKey))
	if selectedKey == nil then
		buffer:print("Error\n")
	end
	
	buffer:print("Moving ")
	if selectedKey == C.GBA_KEY.UP then
		buffer:print("UP\n")
	elseif selectedKey == C.GBA_KEY.DOWN then
		buffer:print("DOWN\n")
	elseif selectedKey == C.GBA_KEY.LEFT then
		buffer:print("LEFT\n")
	elseif selectedKey == C.GBA_KEY.RIGHT then
		buffer:print("RIGHT\n")
	end
	table.insert(keyQueue, selectedKey)
	emu:addKey(selectedKey)
end

fightCounter = 0
-- 60 fps -> 800 frames -> 13.33 seconds
-- Select an action in combat once every 4 seconds
-- 60 / 4 -> 15 frames
FightFrameCounter = 0

function SpamA(buffer, keys)
	buffer:print(string.format("Fight Counter: %d\n", fightCounter))
	emu:clearKeys(C.GBA_KEY.A)
	emu:clearKeys(keys)
	if fightCounter < 1000 then
		fightCounter = fightCounter + 1
	end
	buffer:print(string.format("FightFrame Counter: %d\n", FightFrameCounter))
	FightFrameCounter = FightFrameCounter + 1
	if FightFrameCounter == 15 then
		buffer:print("Pressing A\n")
		emu:addKey(C.GBA_KEY.A)
		FightFrameCounter = 0
	end
end

function postBattle(counter)
	-- need to press A to get through the post battle screen
	-- need to press A to get through the level up screen

end
-- need another buffer for post fight screen + potential level up screen
function MoveAround( game, buffer )
	buffer:clear()
	buffer:print("Debugging Stuff\n")
	keys = emu:getKeys()
	buffer:print(string.format("Keys: %s\n", keys))
	if not WildPokemonPresent() then -- this doesn't work when running away :^(
		buffer:print("No wild Pokemon present\n")

		-- RunInSquare(buffer)

	end
	if WildPokemonPresent() then
		buffer:print("Wild Pokemon Present\n")
		-- RunAway()
		-- SpamA(buffer, keys)
	end
end

function WildPokemonPresent()
	local wildPokemonPresent = false
	for _, mon in ipairs(game:getEnemyParty()) do
		if mon.hp ~= 0 then
			wildPokemonPresent = true
		end
	end
	return wildPokemonPresent
end

function detectGame()
	local checksum = 0
	for i, v in ipairs({emu:checksum(C.CHECKSUM.CRC32):byte(1, 4)}) do
		checksum = checksum * 256 + v
	end
	game = gameCrc32[checksum]
	if not game then
		game = gameCodes[emu:getGameCode()]
	end

	if not game then
		console:error("Unknown game!")
	else
		console:log("Found game: " .. game.name)
		if not partyBuffer then
			partyBuffer = console:createBuffer("Party")
		end
		if not enemyPartyBuffer then
			enemyPartyBuffer = console:createBuffer("Enemy Party")
		end
		if not debugBuffer then
			debugBuffer = console:createBuffer("Debugging")
		end
	end
end

function wrap_cb(cb)
  return function(...)
    local args = table.pack(...)
    local status, result = pcall(function() return cb(table.unpack(args)) end)
    if status then return result end
    print(result)
  end
end

function updateBuffer()
	if not game or not partyBuffer or not enemyPartyBuffer or not debugBuffer then
		return
	end
	PrintPartyStatus(game, partyBuffer)
	PrintEnemyParty(game, enemyPartyBuffer)
	MoveAround(game, debugBuffer)
end

callbacks:add("start", detectGame)
callbacks:add("frame", wrap_cb(updateBuffer))
if emu then
	detectGame()
end
