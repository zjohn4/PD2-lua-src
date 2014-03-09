core:module( "CoreDynamicsLayer" )

-- CoreDynamicsLayer.DynamicsLayer is the layer called Dynamics in the editor. It contains and handels 
-- all dynamic units.
core:import( "CoreDynamicLayer" )
core:import( "CoreEditorUtils" )

DynamicsLayer = DynamicsLayer or class( CoreDynamicLayer.DynamicLayer )

function DynamicsLayer:init( owner )
	local types = CoreEditorUtils.layer_type( "dynamics" )
	DynamicsLayer.super.init( self, owner, "dynamics", types, "dynamics_layer" )
	self._uses_continents = true
end
