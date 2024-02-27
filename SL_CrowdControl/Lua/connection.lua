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
			elseif (not effect.is_timed and effect.ready()) or (effect.is_timed and (running_effects[effect.code] == nil)) then
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
	local mobj = P_SpawnMobj(player.mo.x + player.mo.momx, player.mo.y + player.mo.momx, player.mo.z + player.mo.momz, MT_BUMPER)
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

effects["nojump"] = CCEffect.New("nojump", function(t)
	consoleplayer.cmd.buttons = consoleplayer.cmd.buttons & ~BT_JUMP
end, default_ready, 15 * TICRATE)
effects["nospin"] = CCEffect.New("nospin", function(t)
	consoleplayer.cmd.buttons = consoleplayer.cmd.buttons & ~BT_SPIN
end, default_ready, 15 * TICRATE)
effects["invertcontrols"] = CCEffect.New("invertcontrols", function(t)
	consoleplayer.cmd.forwardmove = -consoleplayer.cmd.forwardmove
	consoleplayer.cmd.sidemove = -consoleplayer.cmd.sidemove
	consoleplayer.cmd.angleturn = -consoleplayer.cmd.angleturn
end, default_ready, 15 * TICRATE)

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