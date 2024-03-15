local ready_path = "client/crowd_control/connector.txt"
local input_path = "client/crowd_control/input.txt"
local output_path = "client/crowd_control/output.txt"
local log_path = "client/crowd_control/latest-log.txt"

local ready_file
local input_file
local output_file
local log_file

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

local cc_debug = CV_RegisterVar({
	name = "cc_debug",
	defaultvalue = 0,
	flags = CV_NOTINNET|CV_ALLOWLUA,
	PossibleValue = CV_OnOff,
	func = nil
})

local function log_msg_silent(...)
	if (cc_debug.value ~= 0) and (io.type(log_file) == "file") then
		log_file:write("["..tostring(os.clock()).."] ", ..., "\r\n")
		log_file:flush()
	end
end

local function log_msg(...)
	print(...)
	log_msg_silent(...)
end

//https://stackoverflow.com/questions/1426954/split-string-in-lua
local function split (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

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
				log_msg("Couldn't find effect '"..code.."'!")
				create_response(id, UNAVAILABLE)
			elseif effect.ready() and (not effect.is_timed or (effect.is_timed and (running_effects[effect.code] == nil))) then
				log_msg(tostring(msg["viewer"]).." activated effect '"..code.."'!")
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
				log_msg("Couldn't find effect '"..code.."'!")
				create_response(id, UNAVAILABLE)
			end
			running_effects[code] = nil
			create_response(id, SUCCESS)
		-- keepalive
		elseif msg_type == 255 then
			log_msg_silent("PONG")
		end
	end
end

local function main_loop()
	if not started then
		started = true
		log_file = io.openlocal(log_path, "w")
		for k,v in pairs(effects) do
			log_msg(k)
		end
		log_msg("Effects loaded")
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
				for i,msg in ipairs(split(line, "%c")) do -- This is a bad assumption, but all control codes should be escaped
					handle_message(parseJSON(msg))
				end
			end
			input_file:close()
			io.openlocal(input_path,"w"):close() -- clear the file
		end
		if not (#message_queue == 0) then
			io.openlocal(ready_path, "w"):close()
			output_file = io.openlocal(output_path,"w")
			if not (output_file == nil) then
				for i,v in ipairs(message_queue) do
					output_file:write(stringify(v).."\0")
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

-- HUD Drawer ==================================================================

local function drawRunningEffects(drawer, player, cam)
	local timers = {}
	for k,v in pairs(running_effects)
		if not (v == nil) then
			local timeleft = (effects[k].duration - v["timer"]) + 1 --just to make sure this won't become zero
			if (timers[timeleft] == nil) then
				timers[timeleft] = {
					["time"]=timeleft, 
					["effects"]={k}
				}
			else
				table.insert(timers[timeleft]["effects"], k)
			end
		end
	end
	table.sort(timers, function(a, b)
		return a.time > b.time
	end)
	local offset = 32
	for i,v in pairs(timers)
		table.sort(timers[i]["effects"])
		for j,code in ipairs(timers[i]["effects"])
			local gfx = ""
			if (code == "invertcontrols") then
				gfx = "INVCICON"
			elseif (code == "nojump") then
				gfx = "NOJPICON"
			elseif (code == "nospin") then
				gfx = "NOSPICON"
			end
			if drawer.patchExists(gfx) then
				if not((i < 3 * TICRATE) and (i % 2 == 0)) then
					local patch = drawer.cachePatch(gfx)
					drawer.drawScaled((320 - offset) * FRACUNIT, (200 - 44) * FRACUNIT, FRACUNIT/2, patch)
					drawer.drawString(320 - offset + 16, 200 - 36, i/TICRATE, 0, "thin-right")
				end
				offset = $ + 4 + 16
			end
		end
	end
end


customhud.SetupItem("cc_debuffs", "crowd_control", drawRunningEffects, "game");


-- Effects =====================================================================

local function default_ready()
	-- only run while in a level, not paused and not exiting a stage
	return gamestate == GS_LEVEL and not paused and not (consoleplayer == nil) and (consoleplayer.playerstate == PST_LIVE) and not (consoleplayer.exiting > 0)
end

/*effects["demo"] = CCEffect.New("demo", function(t)
	print("This is a demo!")
end, default_ready)*/
effects["bumper"] = CCEffect.New("bumper", function(t)
	local player = consoleplayer
	local dir_x = cos(player.mo.angle)
	local dir_y = sin(player.mo.angle)
	local x = player.mo.x + player.mo.momx + P_RandomRange(-16, 16) * FRACUNIT + dir_x * 128
	local y = player.mo.y + player.mo.momy + P_RandomRange(-16, 16) * FRACUNIT + dir_y * 128
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
	if maptol & TOL_NIGHTS == 0 then
		P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_INSTAKILL)
		P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_SPECTATOR)
	else
		consoleplayer.nightstime = 1 -- Game reduces this by one after our code ran without checking for timeout -> integer underflow
		P_PlayerRingBurst(consoleplayer, consoleplayer.rings)
		consoleplayer.rings = 0
	end
end, default_ready)
effects["slap"] = CCEffect.New("slap", function(t)
	P_DoPlayerPain(consoleplayer, consoleplayer.mo, consoleplayer.mo)
end, default_ready)
effects["sneakers"] = CCEffect.New("sneakers", function(t)
	consoleplayer.powers[pw_sneakers] = sneakertics
	P_PlayJingle(consoleplayer, JT_SHOES)
end, function()
	return default_ready() and (consoleplayer.powers[pw_sneakers] == 0) and (maptol & TOL_NIGHTS == 0)
end)
effects["invulnerability"] = CCEffect.New("invulnerability", function(t)
	consoleplayer.powers[pw_invulnerability] = invulntics
	P_PlayJingle(consoleplayer, JT_INV)
end, function()
	return default_ready() and (consoleplayer.powers[pw_invulnerability] == 0) and (maptol & TOL_NIGHTS == 0)
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
	local dir_x = cos(play_mo.angle)
	local dir_y = sin(play_mo.angle)
	local x = play_mo.x + play_mo.momx + P_RandomRange(-256, 256) * FRACUNIT + dir_x * 128
	local y = play_mo.y + play_mo.momy + P_RandomRange(-256, 256) * FRACUNIT + dir_y * 128
	local z = play_mo.z + play_mo.momz
	local mobj = P_SpawnMobj(x, y, z, MT_BLUECRAWLA)
	-- flip with player grav
	mobj.eflags = $ | play_mo.eflags & MFE_VERTICALFLIP
end, function()
	return default_ready() and (maptol & TOL_NIGHTS == 0)
end)
effects["rosy"] = CCEffect.New("rosy", function(t)
	local play_mo = consoleplayer.mo
	local dir_x = cos(play_mo.angle)
	local dir_y = sin(play_mo.angle)
	local x = play_mo.x + play_mo.momx + P_RandomRange(-128, 128) * FRACUNIT + dir_x * 128
	local y = play_mo.y + play_mo.momy + P_RandomRange(-128, 128) * FRACUNIT + dir_y * 128
	local z = play_mo.floorz + play_mo.momz
	if not (play_mo.eflags & MFE_VERTICALFLIP == 0) then
		z = play_mo.ceilingz + play_mo.momz
	end
	local mobj = P_SpawnMobj(x, y, z, MT_ROSY)
end, function()
	return default_ready() and (maptol & TOL_NIGHTS == 0)
end)
effects["commander"] = CCEffect.New("commander", function(t)
	local play_mo = consoleplayer.mo
	local dir_x = cos(play_mo.angle)
	local dir_y = sin(play_mo.angle)
	local x = play_mo.x + play_mo.momx + P_RandomRange(-256, 256) * FRACUNIT + dir_x * 128
	local y = play_mo.y + play_mo.momy + P_RandomRange(-256, 256) * FRACUNIT + dir_y * 128
	local z = play_mo.z + play_mo.momz
	local mobj = P_SpawnMobj(x, y, z, MT_CRAWLACOMMANDER)
	-- flip with player grav
	mobj.eflags = $ | play_mo.eflags & MFE_VERTICALFLIP
end, default_ready)

effects["pityshield"] = CCEffect.New("pityshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_PITY then
		S_StartSound(consoleplayer.mo, sfx_shield)
	end
	consoleplayer.powers[pw_shield] = SH_PITY
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)
effects["fireshield"] = CCEffect.New("fireshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_FLAMEAURA then
		S_StartSound(consoleplayer.mo, sfx_s3k3e)
	end
	consoleplayer.powers[pw_shield] = SH_FLAMEAURA
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)
effects["bubbleshield"] = CCEffect.New("bubbleshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_BUBBLEWRAP then
		S_StartSound(consoleplayer.mo, sfx_s3k3f)
	end
	consoleplayer.powers[pw_shield] = SH_BUBBLEWRAP
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)
effects["lightningshield"] = CCEffect.New("lightningshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_THUNDERCOIN then
		S_StartSound(consoleplayer.mo, sfx_s3k41)
	end
	consoleplayer.powers[pw_shield] = SH_THUNDERCOIN
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)

local function check_skin(skin)
	if not R_SkinUsable(consoleplayer, skin) then
		create_response(id, UNAVAILABLE)
		return false
	end
	return default_ready()
end

effects["changesonic"] = CCEffect.New("changesonic", function(t)
	if R_SkinUsable(consoleplayer, "sonic") then
		consoleplayer.mo.skin = "sonic"
		R_SetPlayerSkin(consoleplayer, "sonic")
	end
end, function()
	return check_skin("sonic")
end)
effects["changetails"] = CCEffect.New("changetails", function(t)
	if R_SkinUsable(consoleplayer, "tails") then
		consoleplayer.mo.skin = "tails"
		R_SetPlayerSkin(consoleplayer, "tails")
	end
end, function()
	return check_skin("tails")
end)
effects["changeknuckles"] = CCEffect.New("changeknuckles", function(t)
	if R_SkinUsable(consoleplayer, "knuckles") then
		consoleplayer.mo.skin = "knuckles"
		R_SetPlayerSkin(consoleplayer, "knuckles")
	end
end, function()
	return check_skin("knuckles")
end)
effects["changeamy"] = CCEffect.New("changeamy", function(t)
	if R_SkinUsable(consoleplayer, "amy") then
		consoleplayer.mo.skin = "amy"
		R_SetPlayerSkin(consoleplayer, "amy")
	end
end, function()
	return check_skin("amy")
end)
effects["changefang"] = CCEffect.New("changefang", function(t)
	if R_SkinUsable(consoleplayer, "fang") then
		consoleplayer.mo.skin = "fang"
		R_SetPlayerSkin(consoleplayer, "fang")
	end
end,  function()
	return check_skin("fang")
end)
effects["changemetal"] = CCEffect.New("changemetal", function(t)
	if R_SkinUsable(consoleplayer, "metalsonic") then
		consoleplayer.mo.skin = "metalsonic"
		R_SetPlayerSkin(consoleplayer, "metalsonic")
	end
end,  function()
	return check_skin("metalsonic")
end)
effects["changerandom"] = CCEffect.New("changerandom", function(t)
	local skin = skins[P_RandomKey(#skins)]
	while not (skin.valid) or not R_SkinUsable(consoleplayer, skin.name) do
		skin = skins[P_RandomKey(#skins)]
	end
	consoleplayer.mo.skin = skin.name
	R_SetPlayerSkin(consoleplayer, skin.name)
end, default_ready)