local CCEMOTE_VERSION = {0, 0, 1}
local LOADED_VERSION = rawget(_G, "CCEMOTE_LIB_VERSION")

if LOADED_VERSION != nil then
	local numlength = max(#CCEMOTE_VERSION, #LOADED_VERSION);
	local outdated = false
	
	for i = 1,numlength 
		local num1 = CCEMOTE_VERSION[i]
		local num2 = LOADED_VERSION[i]
		-- We shouldn't be adding more numbers but just to make sure
		if num1 == nil then
			num1 = 0
		end
		if num2 == nil then
			num2 = 0
		end
		if num2 < num1 then
			// loaded version is outdated
			outdated = true
		elseif num1 < num2 then
			break
		end
	end
	if not outdated then
		return
	end
end

rawset(_G, "CCEMOTE_LIB_VERSION", CCEMOTE_VERSION)

local SCREEN_SIZE = 48

local CCEmote = {}
CCEmote.Meta = {}

CCEmote.New = function(gfx) -- string
	local this = {}
	setmetatable(this, CCEmote.Meta)
	this.xspeed = max(P_RandomKey(3) * FRACUNIT + P_RandomFixed(), FRACUNIT / 2)
	this.yspeed = (P_RandomKey(3) + 1) * FRACUNIT / 2
	if P_RandomKey(2) then
		this.xspeed = -$
	end
	this.gfx = gfx
	this.patch = nil --patches can only be loaded with a drawer :/
	this.x = (P_RandomKey(320) + 1) * FRACUNIT
	this.y = 200 * FRACUNIT
	this.mirror = P_RandomKey(2)
	this.scale = FRACUNIT
	this.Update = CCEmote.Update
	this.Draw = CCEmote.Draw
	return this
end

CCEmote.Update = function(this) -- update function 35 Hz
	if this.patch == nil then
		return false -- not fully intialised yet, just skip this tic
	end
	if this.y <= (0 - ((this.patch.height - this.patch.topoffset) * FRACUNIT)) then
		return true -- we left the screen, remove us
	end
	this.y = $ - this.yspeed * 4
	local angle = FixedAngle((this.y / 200) * 360 * 8)
	this.x = $ + FixedMul(this.xspeed, sin(angle))
	return false
end

CCEmote.Draw = function(this, drawer, player, cam) -- draw function, framerate dependent
	if this.patch == nil then
		if player.exiting then
			return false -- do not init emotes that will vanish soon, delay until next level load
		end
		if not drawer.patchExists(this.gfx) then
			return true -- can't init, remove
		end
		this.patch = drawer.cachePatch(this.gfx)
		this.scale = FRACUNIT / this.patch.height * SCREEN_SIZE
		this.y = $ + (this.patch.topoffset * this.scale) -- (move the emote out of the screen)
	end
	drawer.drawScaled(this.x, this.y, this.scale, this.patch, (V_FLIP*this.mirror))
	return false
end

CCEmote.Meta = {
	__add = nil,
	__sub = nil,
	__mul = nil,
	__div = nil,
	__pow = nil,
	__unm = nil,
	__concat = nil,
	__len = nil,
	__eq = nil,
	__lt = nil,
	__le = nil,
	__index = nil,
	__newindex = nil,
	__usedindex = nil,
	__call = nil
}

registerMetatable(CCEmote.Meta);

local CCEmote_ClassMeta = {
	__add = nil,
	__sub = nil,
	__mul = nil,
	__div = nil,
	__pow = nil,
	__unm = nil,
	__concat = nil,
	__len = nil,
	__eq = nil,
	__lt = nil,
	__le = nil,
	__index = nil,
	__newindex = nil,
	__usedindex = nil,
	__call = function(class, ...)
		return CCEmote.New(...)
	end
}

registerMetatable(CCEmote_ClassMeta);
setmetatable(CCEmote, CCEmote_ClassMeta)

rawset(_G, "CCEmote", CCEmote);
rawset(_G, "cc_emotes", {});

local function drawEmotes(drawer, player, cam)
	local to_remove = {}
	local removed = 0
	for i,emote in ipairs(cc_emotes) do
		if emote:Draw(drawer, player, cam) then
			table.insert(to_remove, i - removed)
			removed = $ + 1
		end
	end
	for i,idx in ipairs(to_remove) do
		table.remove(cc_emotes, idx)
	end
end

customhud.SetupItem("cc_emotes", "crowd_control", drawEmotes, "game", INT8_MAX) -- draw over other UI, but if you really want INT32_MAX is the actual max

local function updateEmotes()
	local to_remove = {}
	local removed = 0
	for i,emote in ipairs(cc_emotes) do
		if emote:Update() then
			table.insert(to_remove, i - removed)
			removed = $ + 1
		end
	end
	for i,idx in ipairs(to_remove) do
		table.remove(cc_emotes, idx)
	end
end

addHook("PreThinkFrame", updateEmotes)
