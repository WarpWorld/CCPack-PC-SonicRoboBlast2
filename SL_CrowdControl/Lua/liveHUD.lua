local deaths = 0

-- HUD Drawer ==================================================================

-- (p_user.c) P_GetPlayerColor(player_t)
local function P_GetPlayerColor(player)
	if (G_GametypeHasTeams() and player.ctfteam) then
		if (player.ctfteam == 1)
			return skincolor_redteam
		elseif (player.ctfteam == 2)
			return skincolor_blueteam
		end
	end

	return player.skincolor
end
	
local emeraldpics = nil
-- (st_stuff.c) ST_drawLivesArea()
-- Implements a few unneeded things for Singleplayer, might be useful when expanding this to Multiplayer
local function drawDeathCounter(drawer, player, cam)
	if not player.skincolor then
		return --not fully inited
	end
	
	local livehud = hudinfo[HUD_LIVES]
	local frac_x, frac_y = livehud.x << FRACBITS, livehud.y << FRACBITS
	local livesback = drawer.cachePatch("STLIVEBK")
	
	drawer.drawScaled(frac_x, frac_y, FRACUNIT/2, livesback, livehud.f|V_PERPLAYER|V_HUDTRANS)
	
	local facecolor = P_GetPlayerColor(player)
	
	if player.spectator then
		local colormap = drawer.getColormap(TC_DEFAULT, SKINCOLOR_CLOUDY)
		local face = drawer.getSprite2Patch(player.skin, SPR2_XTRA, false, A)
		drawer.drawScaled(frac_x, frac_y, FRACUNIT/2, face, livehud.f|V_PERPLAYER|V_HUDTRANSHALF, colormap)
	elseif player.mo and player.mo.color then
		local colormap = drawer.getColormap(TC_DEFAULT, player.mo.color)
		local use_super = player.powers[pw_super] and not (player.charflags & SF_NOSUPERSPRITES)
		local face = drawer.getSprite2Patch(player.skin, SPR2_XTRA, use_super, A)
		drawer.drawScaled(frac_x, frac_y, FRACUNIT/2, face, livehud.f|V_PERPLAYER|V_HUDTRANS, colormap)
		if player.powers[pw_super] == 1 and player.mo.tracer then
			local supertrans = (player.mo.tracer.frame & FF_TRANSMASK) >> FF_TRANSSHIFT
			if supertrans < 10 then
				supertrans = $ << V_ALPHASHIFT
				colormap = drawer.getColormap(TC_DEFAULT, player.mo.tracer.color)
				drawer.drawScaled(frac_x, frac_y, FRACUNIT/2, face, livehud.f|V_PERPLAYER|supertrans, colormap)
			end
		end
	elseif facecolor then
		local colormap = drawer.getColormap(TC_DEFAULT, facecolor)
		local face = drawer.getSprite2Patch(player.skin, SPR2_XTRA, false, A)
		drawer.drawScaled(frac_x, frac_y, FRACUNIT/2, face, livehud.f|V_PERPLAYER|V_HUDTRANS, colormap)
	end
	
	// Metal Sonic recording
	local colmap = V_YELLOWMAP
	if metalrecording then
		if ((2*leveltime)/TICRATE) & 1 then
			drawer.drawString(livehud.x + 58, livehud.y + 8, "REC", livehud.f|V_PERPLAYER|V_REDMAP|V_HUDTRANS, "right");
		end
	elseif player.spectator then
		colmap = V_GRAYMAP
	else
		local candrawlives = false
		// Set the player's name color.
		if G_TagGametype() and (player.pflags & PF_TAGIT) then
			colmap = V_ORANGEMAP
		elseif G_GametypeHasTeams() then
			if (player.ctfteam == 1)
				colmap = V_REDMAP
			elseif (player.ctfteam == 2) then
				colmap = V_BLUEMAP
			end
		end
		// Co-op and Competition, normal life counter
		if G_GametypeUsesLives() or (G_PlatformGametype() and not(gametyperules & GTR_LIVES)) then
			candrawlives = true
		end
		if candrawlives then
			// x
			local stlivex = drawer.cachePatch("STLIVEX")
			drawer.drawScaled((livehud.x + 22) << FRACBITS, (livehud.y + 10) << FRACBITS, FRACUNIT, stlivex, livehud.f|V_PERPLAYER|V_HUDTRANS)
			drawer.drawString(livehud.x + 58, livehud.y + 8, tostring(deaths), livehud.f|V_PERPLAYER|V_HUDTRANS, "right")
		end
	end
	
	colmap = $|(V_HUDTRANS|livehud.f|V_PERPLAYER)
	local hudname = skins[player.skin].hudname
	if (#hudname <= 5)
		drawer.drawString(livehud.x + 58, livehud.y, hudname, colmap, "right")
	elseif (drawer.stringWidth(hudname, colmap) <= 48)
		drawer.drawString(livehud.x + 18, livehud.y, hudname, colmap)
	elseif (drawer.stringWidth(hudname, colmap, "thin") <= 40)
		drawer.drawString(livehud.x + 58, livehud.y, hudname, colmap, "right")
	else
		drawer.drawString(livehud.x + 18, livehud.y, hudname, colmap)
	end
	
	if emeraldpics == nil then
		emeraldpics = {
			[1] = drawer.cachePatch("TEMER1"),
			[2] = drawer.cachePatch("TEMER2"),
			[3] = drawer.cachePatch("TEMER3"),
			[4] = drawer.cachePatch("TEMER4"),
			[5] = drawer.cachePatch("TEMER5"),
			[6] = drawer.cachePatch("TEMER6"),
			[7] = drawer.cachePatch("TEMER7")
		}
	end
	
	// Power Stones collected
	if (G_RingSlingerGametype() and customhud.enabled("powerstones")) then
		local workx = livehud.x + 1
		local j
		if (leveltime & 1) and player.powers[pw_invulnerability] and (player.powers[pw_sneakers] == player.powers[pw_invulnerability]) then // hack; extremely unlikely to be activated unintentionally
			for j=0,7 // "super" indicator
				drawer.drawScaled(workx << FRACBITS, (livehud.y - 9)  << FRACBITS, emeraldpics[j + 1], V_HUDTRANS|livehud.f|V_PERPLAYER);
				workx = $ + 8;
			end
		else
			for j=0,7 // powerstones
				if (player.powers[pw_emeralds] & (1 << j)) then
					drawer.drawScaled(workx << FRACBITS, (livehud.y - 9)  << FRACBITS, emeraldpics[j + 1], V_HUDTRANS|livehud.f|V_PERPLAYER);
				end
				workx = $ + 8;
			end
		end
	end
end

customhud.SetupItem("lives", "crowd_control", drawDeathCounter, "game", 0)

-- ===== LUA HOOKS =============================================================

-- quitting: true if the application is exiting, false if returning to titlescreen
local function on_game_quit(quitting)
	deaths = 0
	if quitting then
		open_local(ready_path, "w"):close()
	end
end

addHook("GameQuit", on_game_quit)

local oldmap = 0
local died = false

local function on_map_loaded(mapnum)
	if oldmap != 0 and oldmap == mapnum and not died then -- retry?
		if G_GametypeUsesLives() then
			deaths = $ + 1
		end
	end
	died = false
	oldmap = mapnum
end

addHook("MapLoad", on_map_loaded)

local function on_player_death(mobj, inflictor, source, damagetype)
	if G_GametypeUsesLives() then
		deaths = $ + 1
		died = true -- hacky workaround for retries
	end
	return false
end

addHook("MobjDeath", on_player_death, MT_PLAYER)

local function pre_think_frame()
	if consoleplayer != nil then
		consoleplayer.lives = 2
	end
end

addHook("PreThinkFrame", pre_think_frame)