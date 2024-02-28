local ready_path = "client/crowd_control/connector.txt"
local input_path = "client/crowd_control/input.txt"
local output_path = "client/crowd_control/output.txt"

local ready_file
local input_file
local output_file

local started = false
local effects = {} -- <string, effect>
local running_effects = {} -- list<(timer, id, was_ready)>

local keepalive_timer = 0
local id = 0

local message_queue = {}
local bumpers = {} --list<(mobj, timer)>

local SUCCESS = 0
local FAILED = 1
local UNAVAILABLE = 2
local RETRY = 3
local PAUSED = 6
local RESUMED = 7
local FINISHED = 8

local function create_response(msg_id, result, time_remaining, message)
	if not (type(time_remaining) == "number") then
		time_remaining = 0
	end
	if not (type(message) == "string") then
		message = ""
	end
	local response = {
		["id"] = msg_id,
		["status"] = result,
		["timeRemaining"] = (time_remaining * 1000) / 35,
		["message"] = message,
		["type"] = 0
	}
	table.insert(message_queue, response)
end

local function handle_message(msg)
	if not (msg == nil) then
		id = msg["id"]
		local msg_type = msg["type"]
		-- test or start
		if msg_type == 0 or msg_type == 1 then
			local code = msg["code"]
			local effect = effects[code]
			if effect == nil or not (getmetatable(effect) == CCEffect.Meta) then
				print("Couldn't find effect '"..code.."'!")
				create_response(id, UNAVAILABLE)
			elseif effect.ready() and (not effect.is_timed or (effect.is_timed and (running_effects[effect.code] == nil))) then
				print(tostring(msg["viewer"]).." activated effect '"..code.."'!")
				local quantity = msg["quantity"]
				if quantity == nil or quantity == 0 then
					quantity = 1
				end
				for i=1,quantity do
					effect.update(0, msg["parameters"]) -- parameters may be nil
				end
				if effect.is_timed then
					running_effects[effect.code] = {["timer"] = 0, ["id"] = id, ["was_ready"] = true}
				end
				create_response(id, SUCCESS, effect.duration)
			else
				create_response(id, RETRY)
			end
		-- stop
		elseif msg_type == 2 then
			local code = msg["code"]
			local effect = effects[code]
			if effect == nil or not (getmetatable(effect) == CCEffect.Meta) then
				print("Couldn't find effect '"..code.."'!")
				create_response(id, UNAVAILABLE)
			end
			running_effects[code] = nil
			create_response(id, SUCCESS)
		-- keepalive
		elseif msg_type == 255 then
			--print("PONG")
		end
	end
end

local function main_loop()
	if not started then
		started = true
		for k,v in pairs(effects) do
			print(k)
		end
		print("Effects loaded")
	else
		for k,v in pairs(running_effects) do
			if not (v == nil) then
				if effects[k].ready() then
					running_effects[k]["timer"] = v["timer"] + 1
					effects[k].update(v["timer"] + 1)
					if not v["was_ready"] then
						create_response(v["id"], RESUMED)
					end
				else
					if v["was_ready"] then
						create_response(v["id"], PAUSED)
					end
				end
				
			end
			v["was_ready"] = effects[k].ready()
			if v["timer"] + 1 > effects[k].duration then
				create_response(v["id"], FINISHED)
				running_effects[k] = nil
			end
		end
		io.openlocal(ready_path, "w"):close()
		input_file = io.openlocal(input_path, "r+")
		if not (input_file == nil) then
			for line in input_file:lines() do
				handle_message(parseJSON(line))
			end
			input_file:close()
			io.openlocal(input_path,"w"):close() -- clear the file
		end
		if not (#message_queue == 0) then
			io.openlocal(ready_path, "w"):close()
			output_file = io.openlocal(output_path,"w")
			if not (output_file == nil) then
				for i,v in ipairs(message_queue) do
					output_file:write(stringify(v).."\0\n")
				end
				message_queue = {}
				output_file:close()
			end
		end
		keepalive_timer = $ + 1
		if keepalive_timer >= TICRATE then
			io.openlocal(ready_path, "w"):close()
			output_file = io.openlocal(output_path,"w")
			if not (output_file == nil) then
				output_file:write('{"id":'..tostring(id+1)..',"type":255}')
				output_file:close()
				keepalive_timer = 0
			end
		end
		ready_file = io.openlocal(ready_path, "w")
		ready_file:write("SRB2 READY!\0")
		ready_file:close()
	end
	for i,v in ipairs(bumpers) do
		v["timer"] = v["timer"] + 1
		if v["timer"] >= 5*TICRATE then
			if v["bumper"].valid then
				P_RemoveMobj(v["bumper"])
			end
			table.remove(bumpers, i)
		end
	end
end

addHook("PreThinkFrame", main_loop)

-- quitting: true if the application is exiting, false if returning to titlescreen
local function on_game_quit(quitting)
	if quitting then
		io.openlocal(ready_path, "w"):close()
	end
end

addHook("GameQuit", on_game_quit)

local function default_ready()
	-- only run while in a level, not paused and not exiting a stage
	return gamestate == GS_LEVEL and not paused and not (consoleplayer == nil) and not (consoleplayer.exiting > 0)
end

/*effects["demo"] = CCEffect.New("demo", function(t)
	print("This is a demo!")
end, default_ready)*/
effects["bumper"] = CCEffect.New("bumper", function(t)
	local player = consoleplayer
	local x = player.mo.x + player.mo.momx + P_RandomRange(-16, 16) * FRACUNIT
	local y = player.mo.y + player.mo.momy + P_RandomRange(-16, 16) * FRACUNIT
	local z = player.mo.z + player.mo.momz + P_RandomRange(-8, 8) * FRACUNIT
	local mobj = P_SpawnMobj(x, y, z, MT_BUMPER)
	table.insert(bumpers, {["bumper"]=mobj,["timer"]=0})
end, default_ready)
effects["giverings"] = CCEffect.New("giverings", function(t)
	consoleplayer.rings = $ + 1
end, default_ready)
effects["givelife"] = CCEffect.New("givelife", function(t)
	consoleplayer.lives = $ + 1
end, default_ready)
effects["kill"] = CCEffect.New("kill", function(t)
	P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_INSTAKILL)
	P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_SPECTATOR)
end, default_ready)
effects["slap"] = CCEffect.New("slap", function(t)
	P_DoPlayerPain(consoleplayer, consoleplayer.mo, consoleplayer.mo)
end, default_ready)
effects["sneakers"] = CCEffect.New("sneakers", function(t)
	consoleplayer.powers[pw_sneakers] = sneakertics
	P_PlayJingle(consoleplayer, JT_SHOES)
end, function()
	return default_ready() and (consoleplayer.powers[pw_sneakers] == 0)
end)
effects["invulnerability"] = CCEffect.New("invulnerability", function(t)
	consoleplayer.powers[pw_invulnerability] = invulntics
	P_PlayJingle(consoleplayer, JT_INV)
end, function()
	return default_ready() and (consoleplayer.powers[pw_invulnerability] == 0)
end)

effects["nojump"] = CCEffect.New("nojump", function(t)
	consoleplayer.cmd.buttons = consoleplayer.cmd.buttons & ~BT_JUMP
end, default_ready, 15 * TICRATE)
effects["nospin"] = CCEffect.New("nospin", function(t)
	consoleplayer.cmd.buttons = consoleplayer.cmd.buttons & ~BT_SPIN
end, default_ready, 15 * TICRATE)
effects["invertcontrols"] = CCEffect.New("invertcontrols", function(t)
	consoleplayer.cmd.forwardmove = -consoleplayer.cmd.forwardmove
	consoleplayer.cmd.sidemove = -consoleplayer.cmd.sidemove
end, default_ready, 15 * TICRATE)

effects["crawla"] = CCEffect.New("crawla", function(t)
	local play_mo = consoleplayer.mo
	local x = play_mo.x + play_mo.momx + P_RandomRange(-256, 256) * FRACUNIT
	local y = play_mo.y + play_mo.momy + P_RandomRange(-256, 256) * FRACUNIT
	local z = play_mo.z + play_mo.momz
	local mobj = P_SpawnMobj(x, y, z, MT_BLUECRAWLA)
	-- flip with player grav
	mobj.eflags = $ | play_mo.eflags & MFE_VERTICALFLIP
end, default_ready)
effects["rosy"] = CCEffect.New("rosy", function(t)
	local play_mo = consoleplayer.mo
	local x = play_mo.x + play_mo.momx + P_RandomRange(-128, 128) * FRACUNIT
	local y = play_mo.y + play_mo.momy + P_RandomRange(-128, 128) * FRACUNIT
	local z = play_mo.floorz + play_mo.momz
	if not (play_mo.eflags & MFE_VERTICALFLIP == 0) then
		z = play_mo.ceilingz + play_mo.momz
	end
	local mobj = P_SpawnMobj(x, y, z, MT_ROSY)
end, default_ready)
effects["commander"] = CCEffect.New("commander", function(t)
	local play_mo = consoleplayer.mo
	local x = play_mo.x + play_mo.momx + P_RandomRange(-256, 256) * FRACUNIT
	local y = play_mo.y + play_mo.momy + P_RandomRange(-256, 256) * FRACUNIT
	local z = play_mo.z + play_mo.momz
	local mobj = P_SpawnMobj(x, y, z, MT_CRAWLACOMMANDER)
	-- flip with player grav
	mobj.eflags = $ | play_mo.eflags & MFE_VERTICALFLIP
end, default_ready)

effects["pityshield"] = CCEffect.New("pityshield", function(t)
	consoleplayer.powers[pw_shield] = SH_PITY
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)
effects["fireshield"] = CCEffect.New("pityshield", function(t)
	consoleplayer.powers[pw_shield] = SH_FLAMEAURA
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)
effects["bubbleshield"] = CCEffect.New("pityshield", function(t)
	consoleplayer.powers[pw_shield] = SH_BUBBLEWRAP
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)
effects["lightningshield"] = CCEffect.New("pityshield", function(t)
	consoleplayer.powers[pw_shield] = SH_THUNDERCOIN
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)

effects["changesonic"] = CCEffect.New("changesonic", function(t)
	consoleplayer.mo.skin = "sonic"
	R_SetPlayerSkin(consoleplayer, "sonic")
end, default_ready)
effects["changetails"] = CCEffect.New("changetails", function(t)
	consoleplayer.mo.skin = "tails"
	R_SetPlayerSkin(consoleplayer, "tails")
end, default_ready)
effects["changeknuckles"] = CCEffect.New("changeknuckles", function(t)
	consoleplayer.mo.skin = "knuckles"
	R_SetPlayerSkin(consoleplayer, "knuckles")
end, default_ready)
effects["changeamy"] = CCEffect.New("changeamy", function(t)
	consoleplayer.mo.skin = "amy"
	R_SetPlayerSkin(consoleplayer, "amy")
end, default_ready)
effects["changefang"] = CCEffect.New("changefang", function(t)
	consoleplayer.mo.skin = "fang"
	R_SetPlayerSkin(consoleplayer, "fang")
end, default_ready)
effects["changemetal"] = CCEffect.New("changemetal", function(t)
	consoleplayer.mo.skin = "metalsonic"
	R_SetPlayerSkin(consoleplayer, "metalsonic")
end, default_ready)
effects["changerandom"] = CCEffect.New("changerandom", function(t)
	local skin = skins[P_RandomKey(#skins)]
	while not (skin.valid) do
		skin = skins[P_RandomKey(#skins)]
	end
	consoleplayer.mo.skin = skin.name
	R_SetPlayerSkin(consoleplayer, skin.name)
end, default_ready)