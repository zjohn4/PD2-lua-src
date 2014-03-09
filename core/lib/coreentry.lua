--[[ THIS IS TEST

C o r e E n t r y
-----------------

The CoreEntry is the central starting point for the ingame Lua scripts.
It first requires the CoreSystem (all mandatory core functionality) and 
then the GamePlay entrypoint (the path is harcoded by design).
The next step is that Gameplay creates an instance derived from CoreSetup.
Calling make_entrypoint() on this instance completes the setup.

]]--

require "core/lib/system/CoreSystem"
-- Maby we should check if we are in production or profiling mode? /AJ
if table.contains(Application:argv(), "-slave") then
	require "core/lib/setups/CoreSlaveSetup"
else
	require "lib/Entry"
end
