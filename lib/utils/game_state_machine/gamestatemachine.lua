core:import( "CoreGameStateMachine" )

require "lib/states/BootupState"
require "lib/states/CreditsState"
require "lib/states/MenuTitlescreenState"
require "lib/states/MenuMainState"

require "lib/states/EditorState"
require "lib/states/WorldCameraState"

-- Stone cold
require "lib/states/IngamePlayerBase"
require "lib/states/IngameStandard"
require "lib/states/IngameMaskOff"
require "lib/states/IngameBleedOut"
require "lib/states/IngameFatalState"
require "lib/states/IngameWaitingForPlayers"
require "lib/states/IngameWaitingForRespawn"
require "lib/states/IngameArrested"
require "lib/states/IngameElectrified"
require "lib/states/IngameIncapacitated"
require "lib/states/IngameClean"
require "lib/states/MissionEndState"
require "lib/states/VictoryState"
require "lib/states/GameOverState"
require "lib/states/ServerLeftState"
require "lib/states/DisconnectedState"
require "lib/states/KickedState"
require "lib/states/IngameLobbyMenu"
require "lib/states/IngameAccessCamera"

-- Fortress
--[[require "lib/states/IngameAdventureState"
require "lib/states/IngameDuelState"
require "lib/states/IngameBattleState"
require "lib/states/IngameDialogState"
require "lib/states/IngameMinigameState"
require "lib/states/IngameMimicState"
require "lib/states/RoamingState"
require "lib/states/VictoryState"]]

GameStateMachine = GameStateMachine or class( CoreGameStateMachine.GameStateMachine )

function GameStateMachine:init()
	if( not Global.game_state_machine ) then
		Global.game_state_machine = { is_boot_intro_done = false, is_boot_from_sign_out = false }
	end

	self._is_boot_intro_done = Global.game_state_machine.is_boot_intro_done
	Global.game_state_machine.is_boot_intro_done = true

	self._is_boot_from_sign_out = Global.game_state_machine.is_boot_from_sign_out
	Global.game_state_machine.is_boot_from_sign_out = false

	local setup_boot = not self._is_boot_intro_done and not Application:editor()
	local setup_title = ( setup_boot or self._is_boot_from_sign_out ) and not Application:editor()

	local states = {}

	local empty = GameState:new( "empty", self )
	local editor = EditorState:new( self )
	local world_camera = WorldCameraState:new( self )
	local bootup = BootupState:new( self, setup_boot )
	local menu_titlescreen = MenuTitlescreenState:new( self, setup_title )
	local menu_main = MenuMainState:new( self )
	
	-- Stone Cold
	local ingame_standard = IngameStandardState:new( self )
	local ingame_mask_off = IngameMaskOffState:new( self )
	local ingame_bleed_out = IngameBleedOutState:new( self )
	local ingame_fatal = IngameFatalState:new( self )
	local ingame_arrested = IngameArrestedState:new( self )
	local ingame_electrified = IngameElectrifiedState:new( self )
	local ingame_incapacitated = IngameIncapacitatedState:new( self )
	local ingame_waiting_for_players = IngameWaitingForPlayersState:new( self )
	local ingame_waiting_for_respawn = IngameWaitingForRespawnState:new( self )
	local ingame_clean = IngameCleanState:new( self )
	local ingame_access_camera = IngameAccessCamera:new( self )
		
	local ingame_lobby = IngameLobbyMenuState:new( self )	
	local gameoverscreen = GameOverState:new( self )
	local server_left = ServerLeftState:new( self )
	local disconnected = DisconnectedState:new( self )
	local kicked = KickedState:new( self )
		
	-- Fortress
	--[[local ingame_adventure = IngameAdventureState:new( self )
	local ingame_duel = IngameDuelState:new( self )
	local ingame_battle = IngameBattleState:new( self )
	local ingame_dialog = IngameDialogState:new( self )
	local ingame_minigame = IngameMinigameState:new( self )
	local ingame_mimic_interaction = IngameMimicInteractionState:new( self )
	local ingame_mimic = IngameMimicState:new( self )
	local roaming_map = RoamingState:new( self )]]
	local victoryscreen = VictoryState:new( self )
	-- local menu_credits = CreditsState:new( self )
	
		
	

	local empty_func = callback( nil, empty, "default_transition" )
	local editor_func = callback( nil, editor, "default_transition" )
	local world_camera_func = callback( nil, world_camera, "default_transition" )
	local bootup_func = callback( nil, bootup, "default_transition" )
	local menu_titlescreen_func = callback( nil, menu_titlescreen, "default_transition" )
	local menu_main_func = callback( nil, menu_main, "default_transition" )
	
	--Stone Cold
	local ingame_standard_func = callback( nil, ingame_standard, "default_transition" )
	local ingame_mask_off_func = callback( nil, ingame_mask_off, "default_transition" )
	local ingame_bleed_out_func = callback( nil, ingame_bleed_out, "default_transition" )
	local ingame_arrested_func = callback( nil, ingame_arrested, "default_transition" )
	local ingame_fatal_func = callback( nil, ingame_fatal, "default_transition" )
	local ingame_electrified_func = callback( nil, ingame_electrified, "default_transition" )
	local ingame_incapacitated_func = callback( nil, ingame_incapacitated, "default_transition" )
	local ingame_waiting_for_players_func = callback( nil, ingame_waiting_for_players, "default_transition" )
	local ingame_waiting_for_respawn_func = callback( nil, ingame_waiting_for_respawn, "default_transition" )
	local ingame_clean_func = callback( nil, ingame_clean, "default_transition" )
	local ingame_access_camera_func = callback( nil, ingame_access_camera, "default_transition" )
		
	local ingame_lobby_func = callback( nil, ingame_lobby, "default_transition" )
	local gameoverscreen_func = callback( nil, gameoverscreen, "default_transition" )
	local server_left_func = callback( nil, server_left, "default_transition" )
	local disconnected_func = callback( nil, disconnected, "default_transition" )
	local kicked_func = callback( nil, disconnected, "default_transition" )
		
	-- Fortress
	--[[local ingame_adventure_func = callback( nil, ingame_adventure, "default_transition" )
	local ingame_duel_func = callback( nil, ingame_adventure, "default_transition" )
	local ingame_dialog_func = callback( nil, ingame_dialog, "default_transition" )
	local ingame_minigame_func = callback( nil, ingame_minigame, "default_transition" )
	local ingame_mimic_interaction_func = callback( nil, ingame_mimic_interaction, "default_transition" )
	local ingame_mimic_func = callback( nil, ingame_mimic, "default_transition" )
	local roaming_map_func = callback( nil, roaming_map, "default_transition" )]]
	local victoryscreen_func = callback( nil, victoryscreen, "default_transition" )
	-- local menu_credits_func = callback( nil, menu_credits, "default_transition" )
		

	self._controller_enabled_count = 1	-- Positive means that controller is enabled for the state machine.

	CoreGameStateMachine.GameStateMachine.init( self, empty )

	--                   From State,		To State,			Function      
	self:add_transition( editor,			empty,				editor_func )
	self:add_transition( editor,			world_camera,		editor_func )
	self:add_transition( editor,			editor,				editor_func )
	
	-- Stone Cold
	self:add_transition( editor,			ingame_standard,	editor_func )
	self:add_transition( editor,			ingame_mask_off,	editor_func )
	self:add_transition( editor,			ingame_bleed_out,	editor_func )
	self:add_transition( editor,			ingame_fatal,		editor_func )
	self:add_transition( editor,			victoryscreen,		editor_func )
	self:add_transition( editor,			ingame_clean,		editor_func )
		
	-- Fortress
	--[[self:add_transition( editor,			ingame_adventure,	editor_func )
	self:add_transition( editor,			ingame_duel,		editor_func )
	self:add_transition( editor,			ingame_battle,		editor_func )
	self:add_transition( editor,			ingame_mimic_interaction,		editor_func )
	self:add_transition( editor,			ingame_mimic,		editor_func )]]

	self:add_transition( world_camera,		editor,				world_camera_func )
	self:add_transition( world_camera,		empty,				world_camera_func )
	self:add_transition( world_camera,		world_camera,		world_camera_func )
	
	-- Stone Cold
	self:add_transition( world_camera,		ingame_standard,			world_camera_func )
	self:add_transition( world_camera,		ingame_mask_off,			world_camera_func )
	self:add_transition( world_camera,		ingame_bleed_out,			world_camera_func )
	self:add_transition( world_camera,		ingame_fatal,				world_camera_func )
	self:add_transition( world_camera,		ingame_arrested,			world_camera_func )
	self:add_transition( world_camera,		ingame_electrified,			world_camera_func )
	self:add_transition( world_camera,		ingame_incapacitated,		world_camera_func )
	self:add_transition( world_camera,		ingame_waiting_for_players,	world_camera_func )
	self:add_transition( world_camera,		ingame_waiting_for_respawn,	world_camera_func )
	self:add_transition( world_camera,		ingame_clean,				world_camera_func )
	self:add_transition( world_camera,		server_left,				world_camera_func )
	self:add_transition( world_camera,		disconnected,				world_camera_func )
	self:add_transition( world_camera,		kicked,						world_camera_func )
		
	-- Fortress
	--[[self:add_transition( world_camera,		ingame_adventure,	world_camera_func )
	self:add_transition( world_camera,		ingame_duel,		world_camera_func )
	self:add_transition( world_camera,		ingame_battle,		world_camera_func )
	self:add_transition( world_camera,		ingame_mimic_interaction,			world_camera_func )
	self:add_transition( world_camera,		ingame_mimic,			world_camera_func )]]
	self:add_transition( world_camera,		victoryscreen,		world_camera )

	self:add_transition( bootup,			menu_titlescreen,	bootup_func )

	self:add_transition( menu_titlescreen,	menu_main,			menu_titlescreen_func )
	
	-- Stone Cold
	self:add_transition( ingame_standard,	editor,						ingame_standard_func )
	self:add_transition( ingame_standard,	world_camera,				ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_mask_off,			ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_bleed_out,			ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_fatal,				ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_arrested,			ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_electrified,			ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_incapacitated,		ingame_standard_func )
	self:add_transition( ingame_standard,	victoryscreen,				ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_waiting_for_respawn,	ingame_standard_func )
	self:add_transition( ingame_standard, 	ingame_standard,			ingame_standard_func )
	self:add_transition( ingame_standard, 	ingame_waiting_for_players, ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_clean,				ingame_standard_func )
	self:add_transition( ingame_standard,	ingame_access_camera,		ingame_standard_func )
	self:add_transition( ingame_standard, server_left, ingame_standard_func )
	self:add_transition( ingame_standard, gameoverscreen, ingame_standard_func )
	self:add_transition( ingame_standard, 	disconnected, 				ingame_standard_func )
	self:add_transition( ingame_standard, 	kicked,	 				ingame_standard_func )
			
	self:add_transition( ingame_mask_off,	editor,						ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	world_camera,				ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_standard,			ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_bleed_out,			ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_fatal,				ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_arrested,			ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_electrified,			ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_incapacitated,		ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_waiting_for_respawn,	ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_clean,				ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	ingame_access_camera,		ingame_mask_off_func )
	self:add_transition( ingame_mask_off, server_left, ingame_mask_off_func )
	self:add_transition( ingame_mask_off,	victoryscreen,		ingame_mask_off_func )
	self:add_transition( ingame_mask_off, gameoverscreen, ingame_mask_off_func )
	self:add_transition( ingame_mask_off, 	disconnected, 				ingame_mask_off_func )
	self:add_transition( ingame_mask_off, 	kicked, 					ingame_mask_off_func )
			
	self:add_transition( ingame_clean,	editor,						ingame_clean_func )
	self:add_transition( ingame_clean,	world_camera,				ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_mask_off,			ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_standard,			ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_bleed_out,			ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_fatal,				ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_arrested,			ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_electrified,			ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_incapacitated,		ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_waiting_for_respawn,	ingame_clean_func )
	self:add_transition( ingame_clean,	ingame_access_camera,		ingame_clean_func )
	self:add_transition( ingame_clean, server_left, ingame_clean_func )
	self:add_transition( ingame_clean, gameoverscreen, ingame_clean_func )
	self:add_transition( ingame_clean,	disconnected, 				ingame_clean_func )
	self:add_transition( ingame_clean,	kicked, 					ingame_clean_func )
	
	self:add_transition( ingame_access_camera,	editor,				ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	world_camera,				ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	ingame_mask_off,			ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	ingame_standard,			ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	ingame_bleed_out,			ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	ingame_fatal,				ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	ingame_arrested,			ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	ingame_electrified,			ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	ingame_incapacitated,		ingame_access_camera_func )
-- 	self:add_transition( ingame_access_camera,	ingame_waiting_for_respawn,	ingame_access_camera_func )
	self:add_transition( ingame_access_camera, 	server_left, 				ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	victoryscreen,				ingame_access_camera_func )
	self:add_transition( ingame_access_camera, 	gameoverscreen, 			ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	disconnected, 				ingame_access_camera_func )
	self:add_transition( ingame_access_camera,	kicked, 					ingame_access_camera_func )
			
	self:add_transition( ingame_bleed_out,	editor,						ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	world_camera,				ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	ingame_standard,			ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	ingame_mask_off,			ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	ingame_fatal,				ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	ingame_arrested,			ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	victoryscreen,				ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	ingame_waiting_for_respawn,	ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	gameoverscreen,				ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	server_left,				ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	disconnected,				ingame_bleed_out_func )
	self:add_transition( ingame_bleed_out,	kicked,					ingame_bleed_out_func )
		
	self:add_transition( ingame_fatal,		editor,					ingame_fatal_func )
	self:add_transition( ingame_fatal,		world_camera,			ingame_fatal_func )
	self:add_transition( ingame_fatal,		ingame_standard,		ingame_fatal_func )
	self:add_transition( ingame_fatal,		ingame_mask_off,		ingame_fatal_func )
	self:add_transition( ingame_fatal,		ingame_bleed_out,		ingame_fatal_func )
	self:add_transition( ingame_fatal,	victoryscreen,				ingame_fatal_func )
	self:add_transition( ingame_fatal,	ingame_waiting_for_respawn,	ingame_fatal_func )
	self:add_transition( ingame_fatal,	gameoverscreen,				ingame_fatal_func )
	self:add_transition( ingame_fatal,	server_left,				ingame_fatal_func )
	self:add_transition( ingame_fatal,	disconnected,				ingame_fatal_func )
	self:add_transition( ingame_fatal,	kicked,						ingame_fatal_func )
		
	self:add_transition( ingame_arrested,	editor,						ingame_arrested_func )
	self:add_transition( ingame_arrested,	world_camera,				ingame_arrested_func )
	self:add_transition( ingame_arrested,	ingame_standard,			ingame_arrested_func )
	self:add_transition( ingame_arrested,	victoryscreen,				ingame_arrested_func )
	self:add_transition( ingame_arrested,	ingame_waiting_for_respawn,	ingame_arrested_func )
	self:add_transition( ingame_arrested,	gameoverscreen,				ingame_arrested_func )
	self:add_transition( ingame_arrested,	ingame_bleed_out,			ingame_arrested_func )
	self:add_transition( ingame_arrested,	server_left,			ingame_arrested_func )
	self:add_transition( ingame_arrested,	disconnected,			ingame_arrested_func )
	self:add_transition( ingame_arrested,	kicked,				ingame_arrested_func )
	
	self:add_transition( ingame_electrified,	editor,					ingame_electrified_func )
	self:add_transition( ingame_electrified,	world_camera,			ingame_electrified_func )
	self:add_transition( ingame_electrified,	ingame_standard,		ingame_electrified_func )
	self:add_transition( ingame_electrified,	ingame_incapacitated,	ingame_electrified_func )
	self:add_transition( ingame_electrified,	victoryscreen,			ingame_electrified_func )
	self:add_transition( ingame_electrified,	ingame_bleed_out,		ingame_electrified_func )
	self:add_transition( ingame_electrified,	ingame_fatal,		 	ingame_electrified_func )
	self:add_transition( ingame_electrified,	server_left,		 	ingame_electrified_func )
	self:add_transition( ingame_electrified, gameoverscreen, ingame_electrified_func )
	self:add_transition( ingame_electrified,	disconnected,		 	ingame_electrified_func )
	self:add_transition( ingame_electrified,	kicked,				 	ingame_electrified_func )
			
	self:add_transition( ingame_incapacitated,	editor,						ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	world_camera,				ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	ingame_standard,			ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	victoryscreen,				ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	ingame_waiting_for_respawn,	ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	gameoverscreen,				ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	server_left,				ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated, gameoverscreen, ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	disconnected,				ingame_incapacitated_func )
	self:add_transition( ingame_incapacitated,	kicked,						ingame_incapacitated_func )
	
	self:add_transition( ingame_waiting_for_players,	ingame_standard,	ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	ingame_mask_off,	ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	ingame_clean,		ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	gameoverscreen,		ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	victoryscreen,		ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	server_left,		ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	disconnected,		ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	kicked,				ingame_waiting_for_players_func )
	self:add_transition( ingame_waiting_for_players,	ingame_lobby,		ingame_waiting_for_players_func )
	
		
	self:add_transition( ingame_waiting_for_respawn,	ingame_standard,	ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	ingame_mask_off,	ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	editor,				ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	ingame_clean,		ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	gameoverscreen,		ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	victoryscreen,		ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	server_left,		ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	disconnected,		ingame_waiting_for_respawn_func )
	self:add_transition( ingame_waiting_for_respawn,	kicked,				ingame_waiting_for_respawn_func )
	
	self:add_transition( gameoverscreen,	gameoverscreen,		gameoverscreen_func )
	self:add_transition( gameoverscreen,	editor,				gameoverscreen_func )
	self:add_transition( gameoverscreen,	ingame_lobby,		gameoverscreen_func )
	self:add_transition( gameoverscreen,	server_left,		gameoverscreen_func )
	self:add_transition( gameoverscreen,	disconnected,		gameoverscreen_func )
	self:add_transition( gameoverscreen,	kicked,				gameoverscreen_func )
	self:add_transition( gameoverscreen,	empty,				gameoverscreen_func )
	self:add_transition( gameoverscreen,	menu_main,			gameoverscreen_func )
	
	self:add_transition( ingame_lobby,	empty,				ingame_lobby_func )
	self:add_transition( server_left,	ingame_lobby,		ingame_lobby_func )
	self:add_transition( disconnected, ingame_lobby,		ingame_lobby_func )
	self:add_transition( kicked, ingame_lobby,				ingame_lobby_func )
	
	self:add_transition( server_left,	empty,				gameoverscreen_func )
	self:add_transition( server_left,	disconnected,		gameoverscreen_func )
	self:add_transition( disconnected,	empty,				gameoverscreen_func )
	self:add_transition( kicked,		empty,				gameoverscreen_func )
	
	
		-- Fortress
	--[[self:add_transition( ingame_adventure,	editor,				ingame_adventure_func )
	self:add_transition( ingame_adventure,	world_camera,		ingame_adventure_func )
	self:add_transition( ingame_adventure,	ingame_duel,		ingame_adventure_func )
	self:add_transition( ingame_adventure,	ingame_battle,		ingame_adventure_func )
	self:add_transition( ingame_adventure,	ingame_dialog,		ingame_adventure_func )
	self:add_transition( ingame_adventure,	ingame_minigame,	ingame_adventure_func )
	self:add_transition( ingame_adventure,	ingame_mimic_interaction,			ingame_adventure_func )
	self:add_transition( ingame_adventure,	ingame_mimic,			ingame_adventure_func )
	self:add_transition( ingame_adventure,	victoryscreen,		ingame_adventure_func )
	self:add_transition( ingame_adventure,	menu_credits,		ingame_adventure_func )]]

	--[[self:add_transition( ingame_duel,		editor,				ingame_duel_func )
	self:add_transition( ingame_duel,		world_camera,		ingame_duel_func )
	self:add_transition( ingame_duel,		ingame_adventure,	ingame_duel_func )
	self:add_transition( ingame_duel,		ingame_battle,		ingame_duel_func )
	self:add_transition( ingame_duel,		ingame_mimic_interaction,			ingame_duel_func )
	self:add_transition( ingame_duel,		ingame_mimic,			ingame_duel_func )
	self:add_transition( ingame_duel,		victoryscreen,		ingame_duel_func )
	self:add_transition( ingame_duel,		menu_credits,			ingame_duel_func )]]
	
	--[[self:add_transition( ingame_battle,		editor,				ingame_duel_func )
	self:add_transition( ingame_battle,		world_camera,		ingame_duel_func )
	self:add_transition( ingame_battle,		ingame_adventure,	ingame_duel_func )
	self:add_transition( ingame_battle,		ingame_duel,		ingame_duel_func )
	self:add_transition( ingame_battle,		ingame_dialog,		ingame_duel_func )
	self:add_transition( ingame_battle,		ingame_mimic_interaction,			ingame_duel_func )
	self:add_transition( ingame_battle,		ingame_mimic,			ingame_duel_func )
	self:add_transition( ingame_battle,		victoryscreen,		ingame_duel_func )
	self:add_transition( ingame_battle,		menu_credits,		ingame_duel_func )]]
	
	--[[self:add_transition( ingame_dialog,		editor,				ingame_dialog_func )
	self:add_transition( ingame_dialog,		world_camera,		ingame_dialog_func )
	self:add_transition( ingame_dialog,		ingame_adventure,	ingame_dialog_func )
	self:add_transition( ingame_dialog,		ingame_battle,		ingame_dialog_func )
	self:add_transition( ingame_dialog,		ingame_mimic_interaction,			ingame_dialog_func )
	self:add_transition( ingame_dialog,		ingame_mimic,			ingame_dialog_func )
	self:add_transition( ingame_dialog,		victoryscreen,		ingame_dialog_func )
	self:add_transition( ingame_dialog,		menu_credits,		ingame_dialog_func )]]
	
	--[[self:add_transition( ingame_minigame,	editor,				ingame_minigame_func )
	self:add_transition( ingame_minigame,	world_camera,		ingame_minigame_func )
	self:add_transition( ingame_minigame,	ingame_adventure,	ingame_minigame_func )
	self:add_transition( ingame_minigame,	ingame_mimic_interaction,			ingame_minigame_func )
	self:add_transition( ingame_minigame,	ingame_mimic,			ingame_minigame_func )]]

	--[[self:add_transition( roaming_map,		editor,				roaming_map_func )
	self:add_transition( roaming_map,		world_camera,		roaming_map_func )
	self:add_transition( roaming_map,		ingame_adventure,	roaming_map_func )
	self:add_transition( roaming_map,		ingame_battle,		roaming_map_func )
	self:add_transition( roaming_map,		ingame_mimic_interaction,			roaming_map_func )
	self:add_transition( roaming_map,		ingame_mimic,			roaming_map_func )
	self:add_transition( roaming_map,		victoryscreen,		roaming_map_func )]]
	
	
	--[[self:add_transition( ingame_mimic,	editor,				ingame_mimic_func )
	self:add_transition( ingame_mimic,	world_camera,		ingame_mimic_func )
	self:add_transition( ingame_mimic,	ingame_duel,		ingame_mimic_func )
	self:add_transition( ingame_mimic,	ingame_battle,		ingame_mimic_func )
	self:add_transition( ingame_mimic,	ingame_dialog,		ingame_mimic_func )
	self:add_transition( ingame_mimic,	ingame_minigame,	ingame_mimic_func )
	self:add_transition( ingame_mimic,	ingame_mimic_interaction,			ingame_mimic_func )
	self:add_transition( ingame_mimic,	victoryscreen,		ingame_mimic_func )
	self:add_transition( ingame_mimic,	menu_credits,		ingame_mimic_func )]]

	--[[self:add_transition( ingame_mimic_interaction,	editor,				ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	world_camera,		ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	ingame_duel,		ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	ingame_battle,		ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	ingame_dialog,		ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	ingame_minigame,	ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	ingame_mimic,			ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	victoryscreen,		ingame_mimic_interaction_func )
	self:add_transition( ingame_mimic_interaction,	menu_credits,		ingame_mimic_interaction_func )]]
	
	--self:add_transition( menu_main,					victoryscreen,	menu_main_func )
	--self:add_transition( victoryscreen,			menu_main,				victoryscreen_func )
	
	-- Stonecold
	self:add_transition( victoryscreen,			ingame_standard,	victoryscreen_func )
	self:add_transition( victoryscreen,			editor,	victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_fatal,	victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_bleed_out,	victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_arrested,	victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_electrified,	victoryscreen_func )
	self:add_transition( victoryscreen,			world_camera,		victoryscreen_func )
	self:add_transition( victoryscreen,			empty,				victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_lobby,		victoryscreen_func )
	self:add_transition( victoryscreen,			server_left,		victoryscreen_func )
	self:add_transition( victoryscreen,			disconnected,		victoryscreen_func )
	self:add_transition( victoryscreen,			kicked,				victoryscreen_func )
	self:add_transition( victoryscreen,			menu_main,			victoryscreen_func )
	
	
	-- Fortress
	--[[self:add_transition( victoryscreen,			ingame_adventure,	victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_duel,			victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_battle,		victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_dialog,		victoryscreen_func )
	self:add_transition( victoryscreen,			roaming_map,			victoryscreen_func )
	self:add_transition( victoryscreen,			editor,						victoryscreen_func )
	self:add_transition( victoryscreen,			world_camera,			victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_mimic_interaction,			victoryscreen_func )
	self:add_transition( victoryscreen,			ingame_mimic,			victoryscreen_func )]]

	--[[self:add_transition( menu_credits,	menu_main,		menu_credits_func )
	self:add_transition( menu_main,			menu_credits,	menu_main_func )]]
	
	self:add_transition( empty,				editor,				empty_func )
	self:add_transition( empty,				world_camera,		empty_func )
	self:add_transition( empty,				bootup,				empty_func )
	self:add_transition( empty,				menu_titlescreen,	empty_func )
	self:add_transition( empty,				menu_main,			empty_func )
	self:add_transition( empty,				ingame_standard,	empty_func )
	self:add_transition( empty,				ingame_mask_off,	empty_func )
	self:add_transition( empty,				ingame_bleed_out,	empty_func )
	self:add_transition( empty,				ingame_clean,	empty_func )
	self:add_transition( empty,				ingame_waiting_for_players,	empty_func )
	self:add_transition( empty,				ingame_waiting_for_respawn,	empty_func )
	self:add_transition( empty,				gameoverscreen,	empty_func )
	self:add_transition( empty,				server_left,	empty_func )
		
	-- Fortress
	--[[self:add_transition( empty,				ingame_adventure,	empty_func )
	self:add_transition( empty,				ingame_duel,		empty_func )
	self:add_transition( empty,				ingame_battle,		empty_func )
	self:add_transition( empty,				ingame_mimic_interaction,		empty_func )
	self:add_transition( empty,				ingame_mimic,		empty_func )
	self:add_transition( empty,				roaming_map,		empty_func )]]
	self:add_transition( empty,				victoryscreen,		empty_func )
	-- self:add_transition( empty,				menu_credits,		empty_func )
	
	managers.menu:add_active_changed_callback( callback( self, self, "menu_active_changed_callback" ) )
	managers.system_menu:add_active_changed_callback( callback( self, self, "dialog_active_changed_callback" ) )
end

function GameStateMachine:init_finilize()
	if managers.hud then
		managers.hud:add_chatinput_changed_callback( callback( self, self, "chatinput_changed_callback" ) )
	end
end

function GameStateMachine:set_boot_intro_done( is_boot_intro_done )
	Global.game_state_machine.is_boot_intro_done = is_boot_intro_done
	self._is_boot_intro_done = is_boot_intro_done
end

function GameStateMachine:is_boot_intro_done()
	return self._is_boot_intro_done
end

function GameStateMachine:set_boot_from_sign_out( is_boot_from_sign_out )
	Global.game_state_machine.is_boot_from_sign_out = is_boot_from_sign_out
end

function GameStateMachine:is_boot_from_sign_out()
	return self._is_boot_from_sign_out
end

function GameStateMachine:menu_active_changed_callback( active )
	self:_set_controller_enabled( not active )
end

function GameStateMachine:dialog_active_changed_callback( active )
	self:_set_controller_enabled( not active )
end

function GameStateMachine:chatinput_changed_callback( active )
	self:_set_controller_enabled( not active )
end

function GameStateMachine:is_controller_enabled()
	return ( self._controller_enabled_count > 0 )
end

function GameStateMachine:_set_controller_enabled( enabled )
	local was_enabled = self:is_controller_enabled()
	
	if( enabled ) then
		self._controller_enabled_count = self._controller_enabled_count + 1
	else
		self._controller_enabled_count = self._controller_enabled_count - 1
	end

	if( not was_enabled ~= not self:is_controller_enabled() ) then
		local state = self:current_state()

		if( state ) then
			state:set_controller_enabled( enabled )
		end
	end
end