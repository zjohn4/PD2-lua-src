core:module( "CoreAccessObjectBase" )


AccessObjectBase = AccessObjectBase or class()

----------------------------------------------------------------------------
--    P U B L I C
----------------------------------------------------------------------------

function AccessObjectBase:init( manager, name )
	self.__manager = manager
	self.__name    = name
	self.__active_requested = false
	self.__really_activated = false
end

function AccessObjectBase:name()
	return self.__name
end

function AccessObjectBase:active()
	return self.__active_requested
end

function AccessObjectBase:active_requested()
	return self.__active_requested
end

function AccessObjectBase:really_active()
	-- Exposing this method is maybe/probably a bad move,
	-- please use it sparingly or not at all /Andreas
	return self.__really_activated
end

function AccessObjectBase:set_active( active )
	if self.__active_requested ~= active then
		self.__active_requested = active
		self.__manager:_prioritize_and_activate()
	end
end

----------------------------------------------------------------------------
--    C O R E   I N T E R N A L
----------------------------------------------------------------------------

function AccessObjectBase:_really_activate()
	-- This method is core internal, override in a core subclass
	self.__really_activated = true
end

function AccessObjectBase:_really_deactivate()
	-- This method is core internal, override in a core subclass
	self.__really_activated = false
end
