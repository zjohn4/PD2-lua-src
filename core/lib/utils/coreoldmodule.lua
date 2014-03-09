core:module( "CoreOldModule" )

--[[

This is the old module sytem, will remain here for 
backward compatibility while we make the transition 
to the new system.

]]--

function get_core_or_local(name)
	return rawget( _G, name ) or rawget( _G, "Core" .. name )
end

function core_or_local(name, ...)
	local metatable = get_core_or_local( name )
	return metatable and metatable:new(...)
end
