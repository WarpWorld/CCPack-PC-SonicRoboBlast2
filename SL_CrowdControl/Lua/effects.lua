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

cc_effects["crawla"] = CCEffect("crawla", function(t)
	local play_mo = consoleplayer.mo
	local dir_x = cos(play_mo.angle)
	local dir_y = sin(play_mo.angle)
	local x = play_mo.x + play_mo.momx + P_RandomRange(-128, 128) * FRACUNIT + dir_x * 128
	local y = play_mo.y + play_mo.momy + P_RandomRange(-128, 128) * FRACUNIT + dir_y * 128
	local z = play_mo.z + play_mo.momz
	local mobj = P_SpawnMobj(x, y, z, MT_BLUECRAWLA)
	-- flip with player grav
	mobj.eflags = $ | play_mo.eflags & MFE_VERTICALFLIP
end, function()
	return default_ready() and nights_check()
end)

local rosies = {} --list<mobj>
cc_effects["rosy"] = CCEffect("rosy", function(t)
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
	table.insert(rosies, mobj)
end, function()
	return default_ready() and nights_check()
end)

cc_effects["commander"] = CCEffect("commander", function(t)
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
	return (bonusfang_returnvector == nil) and default_ready()
end)

local scale_active = false

cc_effects["squish"] = CCEffect("squish", function(t)
	consoleplayer.mo.spritexscale = 2*FRACUNIT
	consoleplayer.mo.spriteyscale = FRACUNIT/4
	scale_active = true
end, function() 
	return default_ready() and not (cc_running_effects["tall"] != nil and cc_running_effects["tall"]["was_ready"])
end, 15 * TICRATE, "ICONSQSH")

cc_effects["tall"] = CCEffect("tall", function(t)
	consoleplayer.mo.spritexscale = FRACUNIT/4
	consoleplayer.mo.spriteyscale = 2*FRACUNIT
	scale_active = true
end, function() 
	return default_ready() and not (cc_running_effects["squish"] != nil and cc_running_effects["squish"]["was_ready"])
end, 15 * TICRATE, "ICONTALL")

--- ===== LUA HOOKS ============================================================

local function pre_think_frame()
	if bumperlockouttimer > 0 then
		bumperlockouttimer = $ - 1
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
		if scale_active and not ((cc_running_effects["squish"] != nil and cc_running_effects["squish"]["was_ready"]) 
				or (cc_running_effects["tall"] != nil and cc_running_effects["tall"]["was_ready"])) then
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