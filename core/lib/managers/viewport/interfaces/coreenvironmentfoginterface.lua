core:module("CoreEnvironmentFogInterface")

core:import("CoreClass")

EnvironmentFogInterface = EnvironmentFogInterface or CoreClass.class()

EnvironmentFogInterface.DATA_PATH = {"post_effect", "fog_processor", "fog", "fog"}
EnvironmentFogInterface.SHARED = false

----------------------------------------------------------------------------
--
--    P U B L I C
--
----------------------------------------------------------------------------

function EnvironmentFogInterface:init(handle)
	self._handle = handle
end

function EnvironmentFogInterface:parameters()
	return table.list_copy( self._handle:parameters() )
end

----------------------------------------------------------------------------
--
--    P R I V A T E
--
----------------------------------------------------------------------------

function EnvironmentFogInterface:_process_return(params)
	assert(table.maxn(params) == 4, "[EnvironmentFogInterface] You did not return all parameters!")
	return params
end