require "lib/states/GameState"

GameOverState = GameOverState or class( MissionEndState )

function GameOverState:init( game_state_machine, setup )
	GameOverState.super.init( self, "gameoverscreen", game_state_machine, setup )
	self._type = "gameover"
end

function GameOverState:at_enter( ... )
	self._success = false
	GameOverState.super.at_enter( self, ... )
end

function GameOverState:_shut_down_network( ... )
	if managers.dlc:is_trial() then
		GameOverState.super._shut_down_network( self )
	end
	
	if managers.job:is_current_job_professional() and Global.game_settings.single_player then
		GameOverState.super._shut_down_network( self, ...  )
	end
end

function GameOverState:_load_start_menu( ... )
	if managers.dlc:is_trial() then
		Global.open_trial_buy = true
		setup:load_start_menu()
	end
	
	-- Takes us back to main menu
	if managers.job:is_current_job_professional() and Global.game_settings.single_player then
		GameOverState.super._load_start_menu( self, ...  )
	end
end

function GameOverState:_set_continue_button_text()
	local text_id = (self._continue_block_timer and self._continue_block_timer > Application:time() and "menu_es_calculating_experience") or
					(not self._completion_bonus_done and "menu_es_calculating_experience") or
					((Network:is_server() or managers.dlc:is_trial())
					-- If professional, message is continue to lobby in multiplayer or continue to menu in singleplayer
					and (managers.job:is_current_job_professional() and (Global.game_settings.single_player and "failed_disconnected_continue" or "debug_mission_end_continue") -- server proffessional 
					or "menu_victory_retry_stage") ) -- Server retry
					or "victory_client_waiting_for_server" -- client
	local text = utf8.to_upper( managers.localization:text( text_id, { CONTINUE = managers.localization:btn_macro( "continue" ) } ) )
	managers.menu_component:set_endscreen_continue_button_text( text, text_id ~= "failed_disconnected_continue" and text_id ~= "debug_mission_end_continue" and text_id ~= "menu_victory_retry_stage" )




	-- managers.hud:set_continue_button_text_endscreen_hud( text )
end

function GameOverState:_continue()
	if Network:is_server() or managers.dlc:is_trial() then
		self:continue()
	end
end

function GameOverState:continue()
	if self:_continue_blocked() then
		return
	end
	
	if Network:is_server() and not managers.dlc:is_trial() then
		managers.network:session():send_to_peers_loaded( "enter_ingame_lobby_menu" )
	end
	
	if managers.dlc:is_trial() then
		self:gsm():change_state_by_name( "empty" )
		return
	end
	
	-- Takes us back to main menu
	if managers.job:is_current_job_professional() and Global.game_settings.single_player then
		self:gsm():change_state_by_name( "empty" )
		return
	end
	
	if( self._old_state ) then
		self:_clear_controller()
		managers.menu_component:close_stage_endscreen_gui()
		self:gsm():change_state_by_name( "ingame_lobby_menu" )
	else
		Application:error( "Trying to continue from game over screen, but I have no state to goto" )
	end
end

