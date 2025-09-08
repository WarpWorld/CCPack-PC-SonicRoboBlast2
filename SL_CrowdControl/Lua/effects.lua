-- ===== Ready functions =======================================================

local function exit_check()
	return not (consoleplayer == nil) and (consoleplayer.playerstate == PST_LIVE) and not (consoleplayer.exiting > 0)
end

local function default_ready()
	-- only run while in a level, not paused and not exiting a stage
	return gamestate == GS_LEVEL and not paused and exit_check()
end

local function nights_check()
	return (maptol & TOL_NIGHTS == 0)
end

local function zoomtube_check()
	return not (consoleplayer == nil) and consoleplayer.powers[pw_carry] != CR_ZOOMTUBE
end

local function minecart_check()
	return not (consoleplayer == nil) and consoleplayer.powers[pw_carry] != CR_MINECART
end

-- Effects =====================================================================

/*cc_effects["demo"] = CCEffect("demo", function(t)
	print("This is a demo!")
end, default_ready)*/

local bumpers = {} --list<(mobj, timer)>
local bumperlockouttimer = 0
local BUMPER_LOCKOUT_TIMER_MAX = 10 * TICRATE

cc_effects["bumper"] = CCEffect("bumper", function(t)
	local minecart = minecart_check()
	if not minecart and bumperlockouttimer > 0 then -- Put a cooldown on bumpers on minecarts, as they make progress near impossible with little counterplay
		return CCEffectResponse.FAILED, "Bumpers are restricted while riding a minecart"
	end
	local player = consoleplayer
	local dir_x = cos(player.mo.angle)
	local dir_y = sin(player.mo.angle)
	local x = player.mo.x + player.mo.momx + P_RandomRange(-16, 16) * FRACUNIT + dir_x * 96
	local y = player.mo.y + player.mo.momy + P_RandomRange(-16, 16) * FRACUNIT + dir_y * 96
	local z = player.mo.z + player.mo.momz + P_RandomRange(-8, 8) * FRACUNIT
	local mobj = P_SpawnMobj(x, y, z, MT_BUMPER)
	table.insert(bumpers, {["bumper"]=mobj,["timer"]=0})
	if not minecart then
		bumperlockouttimer = BUMPER_LOCKOUT_TIMER_MAX
	end
end, function() 
	return default_ready() and zoomtube_check()
end)

cc_effects["giverings"] = CCEffect("giverings", function(t, count)
	consoleplayer.rings = $ + count
	S_StartSound(consoleplayer.mo, sfx_itemup)
end, default_ready)

cc_effects["kill"] = CCEffect("kill", function(t)
	if maptol & TOL_NIGHTS == 0 then
		P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_INSTAKILL)
		P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_SPECTATOR)
	else
		consoleplayer.nightstime = 1 -- Game reduces this by one after our code ran without checking for timeout -> integer underflow
		P_PlayerRingBurst(consoleplayer, consoleplayer.rings)
		consoleplayer.rings = 0
	end
end, default_ready)


local minecart_eject_player = false

cc_effects["slap"] = CCEffect("slap", function(t)
	local minecart = minecart_check()
	if not minecart then
		minecart_eject_player = true
	end
	P_DoPlayerPain(consoleplayer, consoleplayer.mo, consoleplayer.mo)
end, function() 
	return default_ready() and nights_check() and zoomtube_check()
end)

cc_effects["sneakers"] = CCEffect("sneakers", function(t)
	consoleplayer.powers[pw_sneakers] = sneakertics
	P_PlayJingle(consoleplayer, JT_SHOES)
end, function()
	return default_ready() and (consoleplayer.powers[pw_sneakers] == 0) and nights_check()
end)

cc_effects["invulnerability"] = CCEffect("invulnerability", function(t)
	consoleplayer.powers[pw_invulnerability] = invulntics
	P_PlayJingle(consoleplayer, JT_INV)
end, function()
	return default_ready() and (consoleplayer.powers[pw_invulnerability] == 0) and nights_check()
end)

-- ===== Controls ==============================================================

cc_effects["nojump"] = CCEffect("nojump", function(t)
	consoleplayer.cmd.buttons = consoleplayer.cmd.buttons & ~BT_JUMP
end, function() 
	return default_ready() and minecart_check()
end, 10 * TICRATE, "NOJPICON")

cc_effects["nospin"] = CCEffect("nospin", function(t)
	consoleplayer.cmd.buttons = consoleplayer.cmd.buttons & ~BT_SPIN
end, default_ready, 10 * TICRATE, "NOSPICON")

cc_effects["invertcontrols"] = CCEffect("invertcontrols", function(t)
	consoleplayer.cmd.forwardmove = -consoleplayer.cmd.forwardmove
	consoleplayer.cmd.sidemove = -consoleplayer.cmd.sidemove
end, default_ready, 15 * TICRATE, "INVCICON")

-- ===== Spawn Enemies =========================================================

local function CC_SpawnMobj(play_mo, h_range, v_range, mt_type, name)
	local dir_x = cos(play_mo.angle)
	local dir_y = sin(play_mo.angle)
	local x = play_mo.x + play_mo.momx + P_RandomRange(-h_range, h_range) * FRACUNIT + dir_x * v_range
	local y = play_mo.y + play_mo.momy + P_RandomRange(-h_range, h_range) * FRACUNIT + dir_y * v_range
	local z = play_mo.floorz + play_mo.momz
	if not (play_mo.eflags & MFE_VERTICALFLIP == 0) then
		z = play_mo.ceilingz + play_mo.momz
	end
	local mobj = P_SpawnMobj(x, y, z, mt_type)
	mobj.name = name
	-- flip with player grav
	mobj.eflags = $ | play_mo.eflags & MFE_VERTICALFLIP
	return mobj
end

cc_effects["crawla"] = CCEffect("crawla", function(t, q, param, sender)
	local mobj = CC_SpawnMobj(consoleplayer.mo, 128, 128, MT_BLUECRAWLA, sender)
end, function()
	return default_ready() and nights_check()
end)

local rosies = {} --list<mobj>
cc_effects["rosy"] = CCEffect("rosy", function(t, q, param, sender)
	local mobj = CC_SpawnMobj(consoleplayer.mo, 128, 128, MT_ROSY, sender)
	table.insert(rosies, mobj)
end, function()
	return default_ready() and nights_check()
end)

cc_effects["commander"] = CCEffect("commander", function(t, q, param, sender)
	local mobj = CC_SpawnMobj(consoleplayer.mo, 256, 128, MT_CRAWLACOMMANDER, sender)
end, default_ready)

cc_effects["fang"] = CCEffect("fang", function(t, q, param, sender)
	local mobj = CC_SpawnMobj(consoleplayer.mo, 256, 128, MT_SIMPLE_FANG, sender)
end, default_ready)

-- ===== Shields ===============================================================

cc_effects["pityshield"] = CCEffect("pityshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_PITY then
		S_StartSound(consoleplayer.mo, sfx_shield)
	end
	consoleplayer.powers[pw_shield] = SH_PITY
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)

cc_effects["fireshield"] = CCEffect("fireshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_FLAMEAURA then
		S_StartSound(consoleplayer.mo, sfx_s3k3e)
	end
	consoleplayer.powers[pw_shield] = SH_FLAMEAURA
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)

cc_effects["bubbleshield"] = CCEffect("bubbleshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_BUBBLEWRAP then
		S_StartSound(consoleplayer.mo, sfx_s3k3f)
	end
	consoleplayer.powers[pw_shield] = SH_BUBBLEWRAP
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)

cc_effects["lightningshield"] = CCEffect("lightningshield", function(t)
	if consoleplayer.powers[pw_shield] ~= SH_THUNDERCOIN then
		S_StartSound(consoleplayer.mo, sfx_s3k41)
	end
	consoleplayer.powers[pw_shield] = SH_THUNDERCOIN
	P_SpawnShieldOrb(consoleplayer)
end, default_ready)

-- ===== Characters ============================================================

local function check_skin(skin)
	if not R_SkinUsable(consoleplayer, skin) then
		return false
	end
	return default_ready()
end

cc_effects["changesonic"] = CCEffect("changesonic", function(t)
	if R_SkinUsable(consoleplayer, "sonic") then
		consoleplayer.mo.skin = "sonic"
		R_SetPlayerSkin(consoleplayer, "sonic")
	else
		return CCEffectResponse.UNAVAILABLE
	end
end, function()
	return check_skin("sonic")
end)

cc_effects["changetails"] = CCEffect("changetails", function(t)
	if R_SkinUsable(consoleplayer, "tails") then
		consoleplayer.mo.skin = "tails"
		R_SetPlayerSkin(consoleplayer, "tails")
	else
		return CCEffectResponse.UNAVAILABLE
	end
end, function()
	return check_skin("tails")
end)

cc_effects["changeknuckles"] = CCEffect("changeknuckles", function(t)
	if R_SkinUsable(consoleplayer, "knuckles") then
		consoleplayer.mo.skin = "knuckles"
		R_SetPlayerSkin(consoleplayer, "knuckles")
	else
		return CCEffectResponse.UNAVAILABLE
	end
end, function()
	return check_skin("knuckles")
end)

cc_effects["changeamy"] = CCEffect("changeamy", function(t)
	if R_SkinUsable(consoleplayer, "amy") then
		consoleplayer.mo.skin = "amy"
		R_SetPlayerSkin(consoleplayer, "amy")
	else
		return CCEffectResponse.UNAVAILABLE
	end
end, function()
	return check_skin("amy")
end)

cc_effects["changefang"] = CCEffect("changefang", function(t)
	if R_SkinUsable(consoleplayer, "fang") then
		consoleplayer.mo.skin = "fang"
		R_SetPlayerSkin(consoleplayer, "fang")
	else
		return CCEffectResponse.UNAVAILABLE
	end
end, function()
	return check_skin("fang")
end)

cc_effects["changemetal"] = CCEffect("changemetal", function(t)
	if R_SkinUsable(consoleplayer, "metalsonic") then
		consoleplayer.mo.skin = "metalsonic"
		R_SetPlayerSkin(consoleplayer, "metalsonic")
	else
		return CCEffectResponse.UNAVAILABLE
	end
end, function()
	return check_skin("metalsonic")
end)

cc_effects["changerandom"] = CCEffect("changerandom", function(t)
	local oldskin = consoleplayer.mo.skin
	local skin = skins[P_RandomKey(#skins)]
	local tries = 0
	while not (skin.valid) or (oldskin == skin) or not R_SkinUsable(consoleplayer, skin.name) do
		skin = skins[P_RandomKey(#skins)]
		tries = $ + 1
		if tries == #skins then
			return CCEffectResponse.UNAVAILABLE -- no skin can be selected, might be due to forcecharacter, disable this effect anyways
		end
	end
	consoleplayer.mo.skin = skin.name
	R_SetPlayerSkin(consoleplayer, skin.name)
end, default_ready)

-- ===== Emotes ================================================================

cc_effects["emoteheart"] = CCEffect("emoteheart", function(t)
	table.insert(cc_emotes, CCEmote("EMOTLOVE"))
end, function()
	return true
end)

cc_effects["emotepog"] = CCEffect("emotepog", function(t)
	table.insert(cc_emotes, CCEmote("EMOTPOGS"))
end, function()
	return true
end)

cc_effects["emotenoway"] = CCEffect("emotenoway", function(t)
	table.insert(cc_emotes, CCEmote("EMOTNOWY"))
end, function()
	return true
end)

-- ===== Extra =================================================================

local bonusfang_returnvector = nil
local escaped_fang = false

cc_effects["bonusfang"] = CCEffect("bonusfang", function(t)
	local mapinfo = mapheaderinfo[15]
	-- heuristics, to make sure it's not another mods' level 15
	if mapinfo == nil or not (mapinfo.keywords == "ACZ3"
			and (mapinfo.bonustype == 1) -- Boss
			and (mapinfo.levelflags & LF_WARNINGTITLE != 0) 
			and (mapinfo.musname == "VSFANG")) then
		return CCEffectResponse.UNAVAILABLE
	end
	if gamemap == 15 then
		return CCEffectResponse.FAILED
	end
	bonusfang_returnvector = {
		["map"] = gamemap,
		["xyz"] = {consoleplayer.mo.x, consoleplayer.mo.y, consoleplayer.mo.z},
		["mom_xyz"] = {consoleplayer.mo.momx, consoleplayer.mo.momy, consoleplayer.mo.momz},
		["state"] = consoleplayer.mo.state,
		["starpost_xyz"] = {consoleplayer.starpostx, consoleplayer.starposty, consoleplayer.starpostz},
		["starpost_angle"] = consoleplayer.starpostangle,
		["starpost_time"] = consoleplayer.realtime,
		["starpost_num"] = consoleplayer.starpostnum,
		["realtime"] = consoleplayer.realtime,
		["rings"] = consoleplayer.rings,
		["score"] = consoleplayer.score,
		["angle"] = consoleplayer.mo.angle,
	}
	escaped_fang = false
	G_SetCustomExitVars(15, 2) -- 2 -> skip stats and cutscene
	G_ExitLevel()
end, function()
	if not nights_check() then
		return false, "Unable to activate Bonus Fang as it disrupts Special Stage logic."
	end
	local is_999 = rawget(_G, "Nines_InProgress")
	if is_999 != nil and is_999 >= 1 then
		return false, "Unable to activate Bonus Fang during 999 challenge."
	end
	return (bonusfang_returnvector == nil) and default_ready()
end)

local scale_active = false

cc_effects["squish"] = CCEffect("squish", function(t)
	consoleplayer.mo.spritexscale = 2*FRACUNIT
	consoleplayer.mo.spriteyscale = FRACUNIT/4
	scale_active = true
end, function() 
	return default_ready() and not CC_IsEffectRunning("tall")
end, 15 * TICRATE, "ICONSQSH")

cc_effects["tall"] = CCEffect("tall", function(t)
	consoleplayer.mo.spritexscale = FRACUNIT/4
	consoleplayer.mo.spriteyscale = 2*FRACUNIT
	scale_active = true
end, function() 
	return default_ready() and not CC_IsEffectRunning("squish")
end, 15 * TICRATE, "ICONTALL")

local qte_active = false
local qte_timer = 0
local QTE_TIMER_MAX = 7*TICRATE
local qte_difficulty = 1
local qte_attempts = 5
local qte_sequence = {}
local qte_pos = 1
local qte_buttons = {
	GC_JUMP, GC_SPIN, GC_FORWARD, GC_BACKWARD, GC_STRAFELEFT, GC_STRAFERIGHT, 
	GC_WEAPONNEXT, GC_WEAPONPREV, GC_CUSTOM1, GC_CUSTOM2, GC_CUSTOM3,
}
local qte_button_patches = {
	[GC_JUMP] = "JUMPQTE", 
	[GC_SPIN] = "SPINQTE", 
	[GC_FORWARD] = "FORWDQTE", 
	[GC_BACKWARD] = "BACKWQTE", 
	[GC_STRAFELEFT] = "LEFTQTE", 
	[GC_STRAFERIGHT] = "RIGHTQTE", 
	[GC_WEAPONNEXT] = "NEXTWQTE", 
	[GC_WEAPONPREV] = "PREVWQTE", 
	[GC_CUSTOM1] = "CUST1QTE", 
	[GC_CUSTOM2] = "CUST2QTE", 
	[GC_CUSTOM3] = "CUST3QTE",
}
local button_dict = {
}

local function setup_qte()
	qte_sequence = {}
	qte_pos = 1
	local qte_valid_buttons = {
	}
	qte_timer = QTE_TIMER_MAX
	for i=1,#qte_buttons do
		local bind1, bind2 = input.gameControlToKeyNum(qte_buttons[i])
		if bind1 > 0 then
			table.insert(qte_valid_buttons, qte_buttons[i])
			button_dict[bind1] = qte_buttons[i]
			if bind2 > 0 then
				button_dict[bind2] = qte_buttons[i]
			end
		end
	end
	local bind1, bind2 = input.gameControlToKeyNum(GC_TURNLEFT)
	if bind1 > 0 then
		table.insert(qte_valid_buttons, GC_STRAFELEFT)
		button_dict[bind1] = GC_STRAFELEFT
		if bind2 > 0 then
			button_dict[bind2] = GC_STRAFELEFT
		end
	end
	bind1, bind2 = input.gameControlToKeyNum(GC_TURNRIGHT)
	if bind1 > 0 then
		table.insert(qte_valid_buttons, GC_STRAFERIGHT)
		button_dict[bind1] = GC_STRAFERIGHT
		if bind2 > 0 then
			button_dict[bind2] = GC_STRAFERIGHT
		end
	end
	for i=1,(1 + qte_difficulty * 2 + qte_difficulty/2) do
		local key = qte_valid_buttons[P_RandomKey(#qte_valid_buttons) + 1]
		table.insert(qte_sequence, key)
	end
end

local function qte_step()
	qte_pos = $ + 1
	if qte_pos > #qte_sequence then
		S_StartSound(nil, sfx_qteok)
		qte_active = false
		if qte_difficulty < 3 then
			qte_difficulty = $ + 1
		end
	else
		S_StartSound(nil, sfx_s3k63)
	end
end

local function qte_fail()
	S_StartSound(nil, sfx_s3kb2)
	qte_attempts = $ - 1
	setup_qte()
	if qte_attempts < 0 then
		P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_INSTAKILL)
		qte_attempts = 5
		qte_difficulty = 1
	end
end

cc_effects["qte"] = CCEffect("qte", function(t)
	qte_active = true
	qte_attempts = 5
	setup_qte()
end, function() 
	return default_ready() and not qte_active
end)

local textures_cache = {
	["sides"] = {},
	["flats"] = {}
}

cc_effects["notextures"] = CCEffect("notextures", function(t)
	for i=1,#sides do
		local side = sides[i]
		local uptex,lowtex,midtex = side.toptexture, side.bottomtexture, side.midtexture
		if uptex or lowtex or midtex then
			table.insert(textures_cache.sides, {i, uptex, lowtex, midtex})
		end
	end
	for i=1,#sectors do
		table.insert(textures_cache.flats, {i, floorpic, ceilingpic})
	end
end, function() 
	return default_ready() and not qte_active
end, 30 * TICRATE, "ICONNOTX")

--- ===== LUA HOOKS ============================================================

local axisheld = false
local axisthreshold = 512

local function pre_think_frame()
	if bumperlockouttimer > 0 then
		bumperlockouttimer = $ - 1
	end
	if qte_timer > 0 and consoleplayer.playerstate != PST_DEAD then
		qte_timer = $ - 1
		if qte_active and qte_timer == 0 then
			P_DamageMobj(consoleplayer.mo, nil, nil, 1, DMG_INSTAKILL)
		end
	end
    -- The following code is adapted from MRCE's Episode Select
	if qte_active and consoleplayer.playerstate != PST_DEAD then
		if (input.joyAxis(JA_STRAFE) > axisthreshold) then
			if not axisheld then
				if qte_sequence[qte_pos] == GC_STRAFERIGHT then
					qte_step()
				else
					qte_fail()
				end
			end
			axisheld = true
		elseif (input.joyAxis(JA_STRAFE) < -axisthreshold) then
			if not axisheld then
				if qte_sequence[qte_pos] == GC_STRAFELEFT then
					qte_step()
				else
					qte_fail()
				end
			end
			axisheld = true
		elseif (input.joyAxis(JA_MOVE) > axisthreshold) then
			if not axisheld then
				if qte_sequence[qte_pos] == GC_BACKWARD then
					qte_step()
				else
					qte_fail()
				end
			end
			axisheld = true
		elseif (input.joyAxis(JA_MOVE) < -axisthreshold) then
			if not axisheld then
				if qte_sequence[qte_pos] == GC_FORWARD then
					qte_step()
				else
					qte_fail()
				end
			end
			axisheld = true
		elseif (input.joyAxis(JA_JUMP) > axisthreshold) then
			if not axisheld then
				if qte_sequence[qte_pos] == GC_JUMP then
					qte_step()
				else
					qte_fail()
				end
			end
			axisheld = true
		elseif (input.joyAxis(JA_SPIN) > axisthreshold) then
			if not axisheld then
				if qte_sequence[qte_pos] == GC_SPIN then
					qte_step()
				else
					qte_fail()
				end
			end
			axisheld = true
		else
			axisheld = false
		end
	else
		axisheld = false
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
	
	if consoleplayer != nil and consoleplayer.mo != nil then
		if scale_active and not (CC_IsEffectRunning("squish") or CC_IsEffectRunning("tall")) then
			scale_active = false
			consoleplayer.mo.spritexscale = FRACUNIT
			consoleplayer.mo.spriteyscale = FRACUNIT
		end
	end
end

addHook("PreThinkFrame", pre_think_frame)

-- quitting: true if the application is exiting, false if returning to titlescreen
local function on_game_quit(quitting)
	escaped_fang = false
	bonusfang_returnvector = nil
end

addHook("GameQuit", on_game_quit)

local function on_map_loaded(mapnum)
	textures_cache.sides = {}
	textures_cache.flats = {}
	for i=1,#sides do
		local side = sides[i]
		if side ~= nil then
			local uptex,lowtex,midtex = side.toptexture, side.bottomtexture, side.midtexture
			if uptex or lowtex or midtex then
				table.insert(textures_cache.sides, {i, uptex, lowtex, midtex})
			end
		end
	end
	for i=1,#sectors do
		table.insert(textures_cache.flats, {i, floorpic, ceilingpic})
	end
	for i,r in ipairs(rosies)
		if not r.valid then
			table.remove(rosies, i)
		end
	end
	if escaped_fang and bonusfang_returnvector != nil and bonusfang_returnvector.map == mapnum then
		-- Fang defeated, let's reset the player's state
		local pos = bonusfang_returnvector.xyz
		local mom = bonusfang_returnvector.mom_xyz
		local starpost_pos = bonusfang_returnvector.starpost_xyz
		P_SetOrigin(consoleplayer.mo, pos[1], pos[2], pos[3])
		consoleplayer.mo.angle = bonusfang_returnvector.angle
		consoleplayer.mo.state = bonusfang_returnvector.state
		consoleplayer.drawangle = bonusfang_returnvector.angle
		consoleplayer.mo.momx, consoleplayer.mo.momy, consoleplayer.mo.momz = mom[1], mom[2], mom[3]
		consoleplayer.realtime, consoleplayer.rings = bonusfang_returnvector.realtime, bonusfang_returnvector.rings
		consoleplayer.starpostx, consoleplayer.starposty, consoleplayer.starpostz = starpost_pos[1], starpost_pos[2], (starpost_pos[3] + consoleplayer.mo.height)
		consoleplayer.starpostangle = bonusfang_returnvector.starpost_angle
		consoleplayer.starposttime = bonusfang_returnvector.starpost_time
		consoleplayer.starpostnum = bonusfang_returnvector.starpost_num
		escaped_fang = false
		bonusfang_returnvector = nil
	end
end

addHook("MapLoad", on_map_loaded)

local function brak_fix(boss)
	for i,r in ipairs(rosies)
		if r.valid then
			P_RemoveMobj(r)
		end
	end
	rosies = {}
end

addHook("BossDeath", brak_fix, MT_CYBRAKDEMON)

local function bonusfang_handler(boss)
	if bonusfang_returnvector != nil then
		escaped_fang = true
		G_SetCustomExitVars(bonusfang_returnvector.map)
		G_ExitLevel()
	end
end

addHook("BossDeath", bonusfang_handler, MT_FANG)

local function minecart_thinker(mobj)
	if not mobj.valid or not (mobj.health > 0) or not mobj.target or not mobj.target.valid then
		return false -- no passenger or destroyed already
	end
	if minecart_eject_player then
		if mobj.target.player == consoleplayer then
			if consoleplayer and (consoleplayer.powers[pw_carry] == CR_MINECART) then
				consoleplayer.powers[pw_carry] = 0
				mobj.target.momx = mobj.momx
				mobj.target.momy = mobj.momy
				mobj.target = nil
			end
			minecart_eject_player = false -- we tried ¯\_(ツ)_/¯
		end
	end
	return false
end

addHook("MobjThinker", minecart_thinker, MT_MINECART)

local function qte_test_key(keyevent)
	if qte_active and consoleplayer.playerstate == PST_LIVE then
		if button_dict[keyevent.num] == qte_sequence[qte_pos] then
			qte_step()
		else
			qte_fail()
		end
		return true
	end
end 

addHook("KeyDown", qte_test_key)

local function qte_block_key(keyevent)
	if qte_active then
		return true
	end
end 

addHook("KeyUp", qte_block_key)

local qtepics = nil
local starorb = nil
local cursor = nil

local function drawQTE(drawer, player, cam)
	local size = #qte_sequence * 16 + 8 * (#qte_sequence - 1)
	if qtepics == nil then
		qtepics = {}
		starorb = drawer.cachePatch("STARORB")
		cursor = drawer.cachePatch("M_CURSOR")
		for i=1,#qte_buttons do
			qtepics[qte_buttons[i]] = drawer.cachePatch(qte_button_patches[qte_buttons[i]])
		end
	end
	local pos = 160 - size/2
	if qte_active then
		for i=1,#qte_sequence do
			if i < qte_pos then
				drawer.drawScaled((pos+2)*FRACUNIT, 102*FRACUNIT, FRACUNIT/2, starorb)
			else
				drawer.drawScaled(pos*FRACUNIT, 100*FRACUNIT, FRACUNIT/2, qtepics[qte_sequence[i]])
			end
			if i == qte_pos then
				drawer.draw(pos, 90, cursor)
			end
			pos = $ + 24
		end
		local ratio = 160 * FRACUNIT / QTE_TIMER_MAX
		drawer.drawFill(80, 120, 160 - (ratio * qte_timer) / FRACUNIT, 10, V_ORANGEMAP)
		drawer.drawFill(80, 120, 160, 2, 0)
		drawer.drawFill(80, 120, 2, 10, 0)
		drawer.drawFill(88, 120, 160, 2, 0)
		drawer.drawFill(80, 278, 2, 10, 0)
		drawer.drawString(80, 130, "Attempts left: "..tostring(qte_attempts))
	end
end

customhud.SetupItem("qte", "crowd_control", drawQTE, "game", 0)