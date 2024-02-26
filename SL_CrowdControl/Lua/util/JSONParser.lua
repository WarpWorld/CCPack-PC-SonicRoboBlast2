local JSON_VERSION = {0, 0, 1}
local LOADED_VERSION = rawget(_G, "JSON_LIB_VERSION")

if LOADED_VERSION != nil then
	local numlength = max(#JSON_VERSION, #LOADED_VERSION);
	local outdated = false
	
	for i = 1,numlength 
		local num1 = JSON_VERSION[i]
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

rawset(_G, "JSON_LIB_VERSION", JSON_VERSION)

local function find_any(str, pos, ...)
	if select("#", ...) == 0 then
		warn("No pattern entered")
		return pos, pos, "No pattern entered"
	end
	local match_start, match_end = INT32_MAX,INT32_MAX
	for i=1, select("#", ...) do
		local pattern = select(tostring(i), ...)
		local str_start, str_end = str:find(pattern, pos)
		if (not (str_start == nil)) and str_start < match_start then
			match_start = str_start
			match_end = str_end
		end
	end
	return match_start, match_end
end


local function parse_value(str, pos)
	local str_start, str_end = find_any(str, pos, '{', '%[', '"', 'true', 'false', 'null', '[0-9]', '%-')
	if str:sub(str_start, str_end) == "{" then
		return parse_object(str, str_end)
	elseif str:sub(str_start, str_end) == "[" then
		return parse_array(str, str_end)
	elseif str:sub(str_start, str_end) == "true" then
		return true, pos + 4
	elseif str:sub(str_start, str_end) == "false" then
		return false, pos + 5
	elseif str:sub(str_start, str_end) == "null" then
		return nil, pos + 4
	elseif str:sub(str_start, str_end) == '"' then
		local str_start2, str_end2 = str:find('[^\\]"', str_end + 1)
		return str:sub(str_end + 1, str_end2 - 1), str_end2
	else
	
		-- parsing numbers, the most complicated part
		-- we omit support for exponents and fractions
		local negative = str:sub(str_start, str_end) == "-"
		local match_start, match_end = str:find("[^0-9]", str_end)
		if match_start == nil then
			match_start = #str
			match_end = #str
		end
		return tonumber(str:sub(str_start, match_start - 1)), match_start
	end
end

local function parse_object(str, pos)
	local result = {}
	local match_start, match_end = find_any(str, pos, "}", ",")
	local _, key_start = str:find('"', pos)
	if str:sub(match_start, match_end) == "}" and ((key_start == nil) or match_start < key_start) then
		return result, match_end + 1
	end
	local key_end, _ = str:find('"', key_start + 1)
	local _, value_start = str:find(":", key_end)
	local value, value_end = parse_value(str, value_start)
	--print('"'..str:sub(key_start + 1, key_end - 1)..'":'..stringify(value))
	result[str:sub(key_start + 1, key_end - 1)] = value
	
	local str_start, str_end = find_any(str, value_end + 1, ",", "}")
	local ignored = nil
	while str:sub(str_start, str_end) == "," do
		ignored, key_start = str:find('"', str_end + 1)
		key_end, ignored = str:find('"', key_start + 1)
		ignored, value_start = str:find(":", key_end)
		value, value_end = parse_value(str, value_start)
		--print('"'..str:sub(key_start + 1, key_end - 1)..'":'..stringify(value))
		result[str:sub(key_start + 1, key_end - 1)] = value
		str_start, str_end = find_any(str, value_end, ",", "}")
	end
	return result, str_end + 1
end


local function parse_array(str, pos)
	local result = {}
	local match_start, match_end = find_any(str, pos, "%]", ",")
	local value, value_end = parse_value(str, pos + 1)
	if str:sub(match_start, match_end) == "]" and ((value_end == nil) or match_start < value_end) then
		return result, match_end + 1
	end
	table.insert(result, value)
	local str_start, str_end = find_any(str, value_end, ",", "%]")
	while str:sub(str_start, str_end) == "," do
		value, value_end = parse_value(str, value_end)
		table.insert(result, value)
		str_start, str_end = find_any(str, value_end, ",", "%]")
	end
	return result, str_end
end

local function parse(str)
	local str_start, str_end = find_any(str, 1, "{", "%[")
	if str:sub(str_start, str_end) == "{" then
		return parse_object(str, str_end)
	elseif str:sub(str_start, str_end) == "[" then
		return parse_array(str, str_end)
	end
	return nil, "Invalid JSON string received!", str
end

rawset(_G, "parse_object", parse_object)
rawset(_G, "parse_array", parse_array)
rawset(_G, "parseJSON", parse)

local function stringify(obj)
	local obj_type = type(obj)
	if obj_type == "table" then
		-- array?
		if not (obj[1] == nil) then
			local out = "["
			for i,v in ipairs(obj) do
				if i != 1 then
					out = $..","
				end
				out = $..stringify(v)
			end
			out = $.."]"
			return out
		else
			local out = "{"
			local first = true
			for k,v in pairs(obj) do
				if not first then
					out = $..","
				else
					first = false
				end
				out = $..'"'..k..'":'..stringify(v)
			end
			out = $.."}"
			return out
		end
	elseif obj_type == "string" then
		return '"'..obj..'"'
	elseif obj_type == "number" or obj_type == "boolean" then
		return tostring(obj)
	elseif obj_type == "nil" or obj_type == "no_value"
		return "null"
	end
end

rawset(_G, "stringify", stringify)
