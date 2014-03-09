CoreMissionElementData = CoreMissionElementData or class()

-- This is the prepared class for a project heritance
MissionElementData = MissionElementData or class( CoreMissionElementData )
function MissionElementData:init( ... )
	CoreMissionElementData.init( self, ... )
end

function CoreMissionElementData:init( unit )
	
end
