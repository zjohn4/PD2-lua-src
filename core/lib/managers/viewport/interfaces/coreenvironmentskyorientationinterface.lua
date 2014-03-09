core:module("CoreEnvironmentSkyOrientationInterface")

core:import("CoreClass")

EnvironmentSkyOrientationInterface = EnvironmentSkyOrientationInterface or CoreClass.class()

EnvironmentSkyOrientationInterface.DATA_PATH = {"sky_orientation"}
EnvironmentSkyOrientationInterface.SHARED = true

----------------------------------------------------------------------------
--
--    P U B L I C
--
----------------------------------------------------------------------------

function EnvironmentSkyOrientationInterface:init(handle)
	self._handle = handle
end

function EnvironmentSkyOrientationInterface:rotation()
	return self._handle:parameters()["rotation"]
end

----------------------------------------------------------------------------
--
--    P R I V A T E
--
----------------------------------------------------------------------------

function EnvironmentSkyOrientationInterface:_process_return(rot)
	assert(rot, "[EnvironmentSkyOrientationInterface] You did not return any sky rotation!")
	return {rotation = rot}
end