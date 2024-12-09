local CCEFFECT_VERSION = {0, 0, 3}
local LOADED_VERSION = rawget(_G, "CCEFFECT_LIB_VERSION")

if LOADED_VERSION != nil then
	local numlength = max(#CCEFFECT_VERSION, #LOADED_VERSION);
	local outdated = false
	
	for i = 1,numlength 
		local num1 = CCEFFECT_VERSION[i]
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

rawset(_G, "CCEFFECT_LIB_VERSION", CCEFFECT_VERSION)

local CCEffect = {}
CCEffect.Meta = {}

CCEffect.New = function(code, func, ready_func, duration, icon) -- string, function(remainingtime), function, number, string
	if duration == nil or not (type(duration) == "number") then
		duration = 0
	end
	if icon == nil or not (type(icon) == "string") then
		icon = ""
	end
	local cceffect = {}
	setmetatable(cceffect, CCEffect.Meta)
	cceffect.code = code
	-- can return CCEffectStatus, string
	cceffect.update = func
	-- can return bool, string
	cceffect.ready = ready_func
	-- 35 ticks per second
	cceffect.duration = duration
	cceffect.is_timed = not (duration == 0)
	cceffect.icon = icon
	return cceffect
end

CCEffect.Meta = {
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

registerMetatable(CCEffect.Meta);

local CCEffect_ClassMeta = {
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
		return CCEffect.New(...)
	end
}

registerMetatable(CCEffect_ClassMeta);
setmetatable(CCEffect, CCEffect_ClassMeta)

rawset(_G, "CCEffect", CCEffect);
