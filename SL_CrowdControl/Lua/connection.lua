local state_path = "client/crowd_control/connector.txt"
local input_path = "client/crowd_control/input.txt"
local output_path = "client/crowd_control/output.txt"
local log_path = "client/crowd_control/latest-log.txt"

local state_file
local input_file
local output_file
local log_file

local started = false
rawset(_G, "cc_effects", {}) -- <string, effect>
rawset(_G, "cc_running_effects", {}) -- list<(timer, id, was_ready)>
rawset(_G, "CCEffectResponse", {
	SUCCESS = 0,
	FAILED = 1,
	UNAVAILABLE = 2,
	RETRY = 3,
	PAUSED = 6,
	RESUMED = 7,
	FINISHED = 8
})
local function CC_IsEffectRunning(effect)
	return cc_running_effects[effect] != nil and cc_running_effects[effect]["was_ready"]
end
rawset(_G, "CC_IsEffectRunning", CC_IsEffectRunning)

local keepalive_timer = 0
local id = 0

local message_queue = {}

local input_dirty = false -- if this flag is set, input parsing is deferred a tic

local cc_debug = CV_RegisterVar({
	name = "cc_debug",
	defaultvalue = 0,
	flags = CV_NOTINNET|CV_ALLOWLUA,
	PossibleValue = CV_OnOff,
	func = nil
})

local function log_msg_silent(...)
	if (cc_debug.value ~= 0) and (io.type(log_file) == "file") then
		log_file:write("["..tostring(os.clock()).."] ", ...)
		log_file:write("\n")
		log_file:flush()
	end
end

local function log_msg(...)
	print(...)
	log_msg_silent(...)
end

-- these functions are for simple error logging
-- For error handling they return the same values returned by the function they call
local function open_local(path, mode)
	local file, err = io.openlocal(path, mode)
	if err ~= nil then
		log_msg_silent(err)
	end
	return file, err
end

local function write_file(file, ...)
	local success,err,err_code = file:write(...)
	if not success then
		log_msg("[ERROR:",tostring(err_code),"] ", err)
	end
	return success,err,err_code
end

//https://stackoverflow.com/questions/1426954/split-string-in-lua
local function split(inputstr, sep)
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
		["timeRemaining"] = (time_remaining * 1000) / TICRATE,
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
			if code == nil then
				log_msg("[ERROR: Encountered null effect request!]")
				return
			end
			local effect = cc_effects[code]
			if effect == nil or not (getmetatable(effect) == CCEffect.Meta) then
				log_msg("Couldn't find effect '"..code.."'!")
				create_response(id, CCEffectResponse.UNAVAILABLE)
			else
				local ready, ready_msg = effect.ready()
				if ready and (not effect.is_timed or (effect.is_timed and (cc_running_effects[effect.code] == nil))) then
					local sender = msg["viewer"]
					local quantity = msg["quantity"]
					if (quantity == nil) or (quantity == 0) then
						quantity = 1
					end
					local result, out_msg = effect.update(0, quantity, msg["parameters"], sender) -- parameters may be nil
					if result == nil then
						result = CCEffectResponse.SUCCESS
					end
					if effect.is_timed then
						effect.duration = ((msg["duration"] * TICRATE) / 1000)
						cc_running_effects[effect.code] = {["timer"] = 0, ["id"] = id, ["was_ready"] = true}
					end
					create_response(id, result, effect.duration, out_msg)
					if result == CCEffectResponse.SUCCESS then
						if (cc_debug.value ~= 0) then
							log_msg(tostring(msg["viewer"]).." activated effect '"..code.."' ("..tostring(id)..")!")
						else
							log_msg_silent(tostring(msg["viewer"]).." activated effect '"..code.."'!")
						end
					end
				else
					create_response(id, CCEffectResponse.FAILED, 0, ready_msg)
				end
			end
		-- stop
		elseif msg_type == 2 then
			local code = msg["code"]
			if not code == nil then
				local effect = cc_effects[code]
				if effect == nil or not (getmetatable(effect) == CCEffect.Meta) then
					log_msg("Couldn't find effect '"..code.."'!")
					create_response(id, CCEffectResponse.UNAVAILABLE)
					return
				end
				cc_running_effects[code] = nil
				create_response(id, CCEffectResponse.SUCCESS)
			else
				cc_running_effects = {}
				create_response(id, CCEffectResponse.SUCCESS)
			end
		-- keepalive
		elseif msg_type == 255 then
			log_msg_silent("PONG")
			table.insert(message_queue, {["id"] = 0, ["type"] = 255})
		end
	else
		log_msg("Received empty message!")
	end
end

local function setup_cc_effects()
	started = true
	log_file = open_local(log_path, "w")
	for k,v in pairs(cc_effects) do
		log_msg(k)
	end
	log_msg("Effects loaded")
	state_file = open_local(state_path, "w")
	write_file(state_file, "READY")
	state_file:close()
end

local function main_loop()
	if not started then
		setup_cc_effects()
	else
		for k,v in pairs(cc_running_effects) do
			local effect = cc_effects[k]
			if not (v == nil) then
				if effect.ready() then
					cc_running_effects[k]["timer"] = v["timer"] + 1
					effect.update(v["timer"] + 1)
					if not v["was_ready"] then
						create_response(v["id"], CCEffectResponse.RESUMED)
					end
				else
					if v["was_ready"] then
						create_response(v["id"], CCEffectResponse.PAUSED)
					end
				end
			end
			v["was_ready"] = effect.ready()
			if v["timer"] + 1 > effect.duration then
				create_response(v["id"], CCEffectResponse.FINISHED, 0, "'"..effect.code.."' finished!")
				cc_running_effects[k] = nil
			end
		end
		if input_dirty then
			input_file = open_local(input_path,"w")
			if not (input_file == nil)
				input_file:close() -- clear the file
				input_dirty = false
			end
		else
			input_file = open_local(input_path, "r")
			if not (input_file == nil) then
				local content = input_file:read("*a")
				if not (content == "") then
					for i,msg in ipairs(split(content, "%c")) do -- This is a bad assumption, but all control codes should be escaped
						log_msg_silent(msg)
						handle_message(parseJSON(msg))
					end
					input_file:close()
					input_file = open_local(input_path,"w")
					-- in rare cases handling the messages took too long and CC grabbed the file already
					if not (input_file == nil) then
						input_file:close() -- clear the file
					else
						input_dirty = true
					end
				else
					input_file:close()
				end
			end
		end
		if not (#message_queue == 0) then
			output_file = open_local(output_path,"w")
			if not (output_file == nil) then
				local out = stringify(message_queue[1])
				write_file(output_file, out.."\0")
				log_msg_silent(">", out)
				table.remove(message_queue, 1)
			else
				log_msg_silent("Failed to open output file!")
			end
		end
		keepalive_timer = $ + 1
		if keepalive_timer >= TICRATE then
			if io.type(output_file) ~= "file" then
				output_file = open_local(output_path,"w")
			end
			if not (output_file == nil) then
				write_file(output_file, '{"id":0,"type":255}\0')
				keepalive_timer = 0
			else
				log_msg_silent("Failed to send keepalive!")
			end
		end
		if io.type(output_file) == "file" then
			output_file:close()
		end
	end
end

addHook("PreThinkFrame", main_loop)
addHook("IntermissionThinker", main_loop)

-- quitting: true if the application is exiting, false if returning to titlescreen
local function on_game_quit(quitting)
	if quitting then
		open_local(state_path, "w"):close()
	end
end

addHook("GameQuit", on_game_quit)

local function drawRunningEffects(drawer, player, cam)
	local timers = {}
	for k,v in pairs(cc_running_effects)
		if not (v == nil) then
			local timeleft = (cc_effects[k].duration - v["timer"]) + 1 --just to make sure this won't become zero
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
	local times = {}
	for i,v in pairs(timers)
		table.insert(times, i)
	end
	table.sort(times, function(a, b)
		return a > b --inverse order
	end)
	local offset = 32
	for _,i in ipairs(times)
		for j,code in ipairs(timers[i]["effects"])
			local gfx = cc_effects[code].icon
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


customhud.SetupItem("cc_debuffs", "crowd_control", drawRunningEffects, "game")