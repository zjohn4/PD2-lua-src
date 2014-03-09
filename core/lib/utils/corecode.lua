
core:module( "CoreCode" )

core:import( "CoreTable" )
core:import( "CoreDebug" )
core:import( "CoreClass" )
core:import( "CoreApp" )


--[[ 

The CoreCode module has functionality for inspection of
objects, both on code level and object level, and for
reporting memory usage.

Please also see module 'CoreDebug'.

]]-- 


---------------------------------------------------------------------- 
--  Functions for Accessing Source Code 
----------------------------------------------------------------------
local function open_lua_source_file(source)
	if DB:is_bundled() then
		return "[N/A in bundle]"
	end
	local entry_type = Idstring("lua_source")
	local entry_name = source:match("([^\.]*)"):lower()
	return DB:has(entry_type, entry_name:id()) and DB:open(entry_type, entry_name:id()) or nil
end

-- Get a single-line function prototype
function get_prototype(info)
	if info.source == "=[C]" then
		return "(C++ method)"
	end
	
	local prototype = info.source -- We only return this if we can't do any better
	local source_file = open_lua_source_file(info.source)
	
	if source_file then
		for i = 1, info.linedefined do
			prototype = source_file:gets()
		end
		source_file:close()
	end
	
	return prototype
end

-- Get source code for a function
function get_source(info)
	if info.source == "=[C]" then
		return "(C++ method)"
	end
	
	local source_file = open_lua_source_file(info.source)
	local lines = {}
	
	-- Append any comment lines immediately preceeding the function
	for i = 1, info.linedefined - 1 do
		local line = source_file:gets()
		if line:match("^%s*%-%-") then
			table.insert(lines, line)
		else
			lines = {}
		end
	end
	
	-- Append the lines of the function itself
	for i = info.linedefined, info.lastlinedefined do
		table.insert(lines, source_file:gets())
	end
	
	source_file:close()
	return table.concat(lines, "\n")
end

function traceback ( max_level )
	-- set level = 3, to skip the three first function levels
	max_level = max_level or 2
	local level = 2
	while true do
		local info = debug.getinfo(level, "Sl")
		if not info or level >= ( max_level + 2 ) then break end
		
		if info.what == "C" then   -- is a C function?
			CoreDebug.cat_print( "debug", level, "C function" )
		else   -- a Lua function
			CoreDebug.cat_print( "debug", string.format( "[%s]:%d",
              		info.source, info.currentline ) )
		end
		
	level = level + 1
	end
end

function alive(obj)
	if obj and obj:alive() then
		return true
	end
	return false
end

function deprecation_warning(method_name, breaking_release_name)
	CoreDebug.cat_print("debug", string.format("DEPRECATION WARNING: %s will be removed in %s", method_name, breaking_release_name or "a future release"))
end

---------------------------------------------------------------------- 
--  Functions for Printing Objects 
---------------------------------------------------------------------- 

--- Returns a iterator similar to pairs, except that the items
--  has been sorted (on keys). If the optional parameter 'raw' 
--  is true then the iterator uses rawget to get the values from 
--  the table; by default the metatable is honored.
--  @usage: sort_iterator( t [,raw] ) --> iterator; iterator() --> k,v
local function sort_iterator(t,raw)
    local sorted = {}
    for k,v in pairs(t) do sorted[#sorted+1] = k end
    table.sort(sorted, function (a,b)
    	if type(a) == "number" then
    		if type(b) == "number" then
    			-- Both are numbers.
	    		return a < b
	    	else
	    		-- A is a number but B is not. A should be ordered ahead of B
	    		return true
	    	end
	    else
	    	if type(b) == "number" then
	    		-- B is a number but A is not. B should be oredered ahead of A
	    		return false
	    	end
		end
		-- Neither are numbers
    	return tostring(a) < tostring(b)
    end)
    local index = 0
    return function ()
        index = index + 1 
        local k = sorted[index]
		if raw then
			return k, rawget(t,k)
		else
	        return k, t[k]
	    end 
    end
end

--- Returns a representation of an object suitable for printing on a
--  single line. If the additional parameter 'raw' is true the values 
--  of the table is retrieved with rawget; by default the metatable is 
--  honored.
function line_representation(x,seen,raw)
	if DB:is_bundled() then
		return "[N/A in bundle]"
	end
    local w = 60
    if type(x) == "userdata" then
        return tostring(x)
    elseif type(x) == "table" then
        if not seen then seen = {} end
        if seen[x] then return "..." end
        seen[x] = true
        local r = "{"
        for k,v in sort_iterator(x,raw) do
            r = r .. line_representation(k,seen,raw) .. '=' .. line_representation(v,seen,raw) .. ', '
            if r:len() > w then
                r = r:sub(1,w)
                r = r .. '...'
                break
            end
        end
        r = r .. '}'
        return r
    elseif type(x) == "string" then
        x = string.gsub(x, '\n', '\\n')
        x = string.gsub(x, '\r', '\\r')
        x = string.gsub(x, '\t', '\\t')
        if x:len() > w then
            x = x:sub(1,w) .. '...'
        end
        return x
    elseif type(x) == "function" then
        local info = debug.getinfo(x)
        if info.source == '=[C]' then
            return "(C++ method)"
        else
            return line_representation(get_prototype(info),nil,raw)
        end
    else
        return tostring(x)
    end
end

-- Returns a representation of an object suitable for printing on multiple
-- lines.
function full_representation(x, seen)
	if DB:is_bundled() then
		return "[N/A in bundle]"
	end
	if type(x) == "function" then
		local info = debug.getinfo(x)
		return get_source(info)
	elseif type(x) == "table" then
		return ascii_table(x,true)
--[[ This crashes on some userdata (ie SoundInstance:key()):
	elseif type(x) == "userdata" and x.__properties and next(x.__properties) then
		return tostring(x) .. "\nTry properties(...) for more detailed information"
]]
	else
		return tostring(x)
	end
end
inspect = full_representation

function properties(x)
    local t = {}
    for i,p in ipairs(x.__properties) do
        t[p] = x[p](x)
    end
    CoreDebug.cat_print( "debug", ascii_table(t))
end

-- List all functions in an object
function help(o)
    local methods = {}
    local function add_methods(t)
        if type(t) == "table" then
            for k,v in pairs(t) do
                if type(v) == "function" then
                    local info = debug.getinfo(v, "S")
                    if info.source ~= "=[C]" then
                        local h = get_prototype(info)
                        local name = k
                        k = nil
                        if h:match("= function") then k = name end
                        k = k or h:match(":(.*)")
                        k = k or h:match("%.(.*)")
                        k = k or h
                    end
                    k = k .. string.rep(" ", 40 - #k)
                    if info.what == "Lua" then
                        k = k .. "(" .. info.source .. ":" .. info.linedefined .. ")"
                    else
                        k = k .. "(C++ function)"
                    end
                    methods[k] = true
                end
            end
        end
        if getmetatable(t) then
            add_methods(getmetatable(t))
        end
    end
    add_methods(o)
    local sorted_methods = {}
    for k,v in pairs(methods) do table.insert(sorted_methods, k) end
    table.sort(sorted_methods)
    for i,name in ipairs(sorted_methods) do
        CoreDebug.cat_print( "debug", name )
    end
end

--- Formats and prints a table with ascii. If the additional 
--  parameter 'raw' is true the values of the table is retrieved 
--  with rawget; by default the metatable is honored. 
function ascii_table(t,raw)
    local out = ''
    local klen = 20
    local vlen = 20
    for k,v in pairs(t) do
        local kl = line_representation(k,nil,raw):len() + 2
        local vl = line_representation(v,nil,raw):len() + 2
        if kl > klen then klen = kl end
        if vl > vlen then vlen = vl end
    end
    out = out .. ("-"):rep(klen+vlen+5) .. "\n"
    for k,v in sort_iterator(t,raw) do
        out = out .. "| " .. line_representation(k,nil,raw):left(klen) .. "| " .. 
            line_representation(v,nil,raw):left(vlen) .."|\n"
    end
    out = out .. ("-"):rep(klen+vlen+5) .. "\n"
    return out
end

----------------------------------------------------------------------
-- Functions to facilitate reducing lua memory
----------------------------------------------------------------------
function memory_report( limit )
    local seen = {}
    local count = {}
    
    local name = {_G = _G}
    for k,v in pairs(_G) do
    	if (type(v) == "userdata" and v.key or type(v) ~= "userdata" ) then
    		name[ type(v) == "userdata" and v:key() or v] = k
    	end
    end
    
    local function simple(item)
        local t = type(item)
        if t == "table" then return false end
        if t == "userdata" then return getmetatable(t) end
        return true
    end
    
    local function recurse(item, parent, key)
    	local index = type(item) == "userdata" and item:key() or item
        if seen[index] then return end
        seen[index] = true
        local t = name[index] or name[getmetatable(item)] or (parent .. "/" .. key)
        count[t] = (count[t] or 0) + 1
        if type(item) == "table" then
            for k,v in pairs(item) do
                count[t .. "/*"] = (count[t .. "/*"] or 0) + 1
                if not simple(v) and not seen[v] then
                    recurse(v, t, tostring(k))
                end
            end
        end
       if CoreClass.type_name(item) == "Unit" then
            for _,e in ipairs(item:extensions()) do
                recurse(item[e](item), t, e)
            end
        end
        if getmetatable(item) and not seen[getmetatable(item)] then
          recurse(getmetatable(item), t, "metatable")
        end
    end
    
    recurse(_G, nil, nil)
    local units = World:unit_manager():get_units()
    local is_windows = SystemInfo:platform() == Idstring( "win32" )
    for _,u in ipairs(units) do
    	recurse(u, "Units", is_windows and u:name():s() or u:name(), u)
    end

    local total = 0
    local res = {}
    for k,v in pairs(count) do
        total = total + v
        if v > (limit or 100) then 
            res[#res + 1] = string.format("%6i  %s", v, k)
        end
    end
    table.sort(res)
    for _,l in ipairs(res) do CoreDebug.cat_print( "debug", l) end
    CoreDebug.cat_print( "debug", string.format("\n%6i  TOTAL", total))
end

----------------------------------------------------------------------
-- Functions to profile lua code
----------------------------------------------------------------------

__old_profiled = __old_profiled or {}
if __profiled then
  __old_profiled = __profiled
  for k,v in pairs(__profiled) do
    Application:console_command("profiler remove " .. k)
  end
end
__profiled = {}

function profile(s)
	if __profiled[s] then return end
	
	local t = {}
	t.s = s
	local start, stop = s:find(":")
	if start then
		t.class = s:sub(0,start-1)
		t.name = s:sub(stop+1)
		if not rawget(_G, t.class) then
			CoreDebug.cat_print( "debug", "Could not find class " .. t.class)
			return
		end
		t.f = rawget(_G, t.class)[t.name]
		t.patch = function(f) _G[t.class][t.name] = f end
	else
		t.name = s
		t.f = rawget(_G, t.name)
		t.patch = function(f) _G[t.name] = f end
	end
	
	if not t.f or type(t.f) ~= "function" then
		CoreDebug.cat_print( "debug", "Could not find function " .. s)
		return
	end
	
	t.instrumented = function (...)
		local id = Profiler:start(t.s)
		res = t.f(...)
		Profiler:stop(id)
		return res
	end
	t.patch(t.instrumented)
	__profiled[s] = t
	
	Application:console_command("profiler add " .. s)
end

function unprofile(s)
	local t = __profiled[s]
	if t then
		t.patch(t.f)
	end
	Application:console_command("profiler remove " .. s)
	__profiled[s] = nil
end

function reprofile()
	for k,v in pairs(__old_profiled) do
		profile(k)
	end
	__old_profiled = {}
end


