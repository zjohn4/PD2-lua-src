--[[

C o r e S y s t e m
-------------------

The CoreSystem is the central starting point for Core. It must be required
before any other core functionality is used.

]]--

require "core/lib/system/CorePatchLua"
require "core/lib/system/CorePatchEngine"
require "core/lib/system/CoreModule"
require "core/lib/system/CoreModules"
core:import('CoreExtendLua')
core:import('CoreEngineAccess')


-- The global table 'managers' are (for now) considered part
-- of the programming interface that Core presents to Gameplay.
managers = managers or {}
core:_add_to_pristine_and_global( 'managers', managers )

-- HACK ------------------------------------------------------------
-- ...while new module system is being introduced...
core:_copy_module_to_global( "CoreClass" )
core:_copy_module_to_global( "CoreCode" )
core:_copy_module_to_global( "CoreDebug" )
core:_copy_module_to_global( "CoreEvent" )
core:_copy_module_to_global( "CoreEws" )
core:_copy_module_to_global( "CoreInput" )
core:_copy_module_to_global( "CoreMath" )
core:_copy_module_to_global( "CoreOldModule" )
core:_copy_module_to_global( "CoreString" )
core:_copy_module_to_global( "CoreTable" )
core:_copy_module_to_global( "CoreUnit" )
core:_copy_module_to_global( "CoreXml" )
core:_copy_module_to_global( "CoreApp" )
-- END HACK ------------------------------------------------------------

core:_close_pristine_namespace()
