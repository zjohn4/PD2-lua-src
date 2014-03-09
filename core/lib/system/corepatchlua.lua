--[[

C o r e P a t c h L u a
-----------------------

The CorePatchLua fixes some of the worst warts in Lua.
See also CoreExtendLua.
  
]]--


--  Make sure that we do not assign to global variables by mistake
local mt = getmetatable(_G)
if mt == nil then
  mt = {}
  setmetatable(_G, mt)
end

mt.__declared = {}

mt.__newindex = function (t, n, v)
  if not mt.__declared[n] then
    local info = debug.getinfo(2, "S")
    if info and info.what ~= "main" and info.what ~= "C" then
      error("cannot assign undeclared global '" .. tostring( n ) .. "'", 2)
    end
    mt.__declared[n] = true
  end
  rawset(t, n, v)
end

mt.__index = function (t,n)
	if not mt.__declared[n] then
		local info = debug.getinfo(2, "S")
		if info and info.what ~= "main" and info.what ~= "C" then
			error( "cannot use undeclared global '" .. tostring( n ) .. "'", 2 )
		end
	end
end
