HUDStatsScreen = HUDStatsScreen or class()

function HUDStatsScreen:init()
	--self._hud_panel = managers.hud:script( managers.hud.STATS_SCREEN_SAFERECT ).panel
	self._full_hud_panel = managers.hud:script( managers.hud.STATS_SCREEN_FULLSCREEN ).panel
	self._full_hud_panel:clear()
	
	local left_panel = self._full_hud_panel:panel( { name = "left_panel", valign = "scale", w = self._full_hud_panel:w()/3 }  )
	left_panel:set_x( -left_panel:w() )
	left_panel:rect( { name = "rect_bg", color = Color( 0.0, 0.0, 0.0 ):with_alpha( 0.75 ), valign = "scale", blend_mode = "normal" } )
	-- left_panel:bitmap( { name = "blur_bg", color = Color( 1, 1, 1 ):with_alpha( 0.75 ), valign = "scale", blend_mode = "normal", layer = -1 } )
	local blur_bg = left_panel:bitmap( { name = "blur_bg", texture="guis/textures/test_blur_df", w = left_panel:w(), h = left_panel:h(), valign = "scale", render_template="VertexColorTexturedBlur3D", layer=-1 } )
			
	local objectives_title = left_panel:text( { layer = 1, name = "objectives_title", color = Color.white, font_size = tweak_data.hud_stats.objectives_title_size, font= tweak_data.hud_stats.objectives_font, text=utf8.to_upper( managers.localization:text( "hud_objective" ) ), align = "left", vertical = "top", w = 512, h = 32 } )
	local x, y = managers.gui_data:corner_safe_to_full( 0, 0 )
	objectives_title:set_position( math.round( x ), math.round( y ) )
	objectives_title:set_valign( {math.round( y )/managers.gui_data:full_scaled_size().h,0} )
	managers.hud:make_fine_text( objectives_title )
	-- objectives_title:set_debug( true )
	
	local pad = 8
	local objectives_panel = left_panel:panel( { layer = 1, name = "objectives_panel", x = math.round( objectives_title:x() + pad ), y = math.round( objectives_title:bottom() ), w = left_panel:w() - (objectives_title:x() + pad) } )
	objectives_panel:set_valign( {math.round( y )/managers.gui_data:full_scaled_size().h,0} )
	-- objectives_panel:set_debug( true )
	
	--------------------------------------------------------------------------------------------------------
	-- Loot panel
	local loot_wrapper_panel = left_panel:panel( { visible = true, layer = 1, name = "loot_wrapper_panel", x = 0, y = 0 + math.round( managers.gui_data:full_scaled_size().height/2 ), h = math.round( managers.gui_data:full_scaled_size().height/2 ), w = left_panel:w() } )
	loot_wrapper_panel:set_valign( "center" )
	-- , valign = {1/2,1/2}
	-- loot_wrapper_panel:set_debug( true )
	
	local secured_loot_title = loot_wrapper_panel:text( { layer = 1, valign = "center", name = "secured_loot_title", color = Color.white, font_size = tweak_data.hud_stats.loot_title_size, font= tweak_data.hud_stats.objectives_font, text = utf8.to_upper( managers.localization:text( "hud_secured_loot" ) ), align = "left", vertical = "top", w = 512, h = 32 } )
	secured_loot_title:set_position( math.round( x ), 0 )
	managers.hud:make_fine_text( secured_loot_title )
	
	local mission_bags_title = loot_wrapper_panel:text( { layer = 1, valign = "center", name = "mission_bags_title", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = utf8.to_upper( managers.localization:text( "hud_mission_bags" ) ), align = "left", vertical = "top", w = 512, h = 32 } )
	mission_bags_title:set_position( math.round( x + pad ), secured_loot_title:bottom() )
	managers.hud:make_fine_text( mission_bags_title )
	
	local mission_bags_panel = loot_wrapper_panel:panel( { visible = true, name = "mission_bags_panel", x = 0, y = 0, h = 44, w = left_panel:w() } )
	mission_bags_panel:set_lefttop( mission_bags_title:leftbottom() )
	mission_bags_panel:set_position( mission_bags_panel:x(), mission_bags_panel:y())
	-- mission_bags_panel:bitmap( { name = "bag_test", texture="guis/textures/pd2/hud_bag" } )
	-- "guis/textures/pd2/hud_bag"
	
	local mission_bags_payout = loot_wrapper_panel:text( { layer = 1, valign = "center", name = "mission_bags_payout", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = "", align = "left", vertical = "top", w = 512, h = 32 } )
	mission_bags_payout:set_text( utf8.to_upper( managers.localization:text( "hud_bonus_bags_payout", { MONEY = managers.experience:cash_string( 0 ) } ) ) )
	mission_bags_payout:set_position( mission_bags_title:left(), mission_bags_panel:bottom() )
	managers.hud:make_fine_text( mission_bags_payout )
	mission_bags_payout:set_w( loot_wrapper_panel:w() )

	local bonus_bags_title = loot_wrapper_panel:text( { layer = 1, valign = "center", name = "bonus_bags_title", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = utf8.to_upper( managers.localization:text( "hud_bonus_bags" ) ), align = "left", vertical = "top", w = 512, h = 32 } )
	bonus_bags_title:set_position( math.round( x + pad ), mission_bags_payout:bottom() + 4 )
	managers.hud:make_fine_text( bonus_bags_title )
	
	local bonus_bags_panel = loot_wrapper_panel:panel( { visible = true, name = "bonus_bags_panel", x = 0, y = 0, h = 44, w = left_panel:w() } )
	bonus_bags_panel:set_lefttop( bonus_bags_title:leftbottom() )
	bonus_bags_panel:set_position( bonus_bags_panel:x(), bonus_bags_panel:y() )
	bonus_bags_panel:grow( -bonus_bags_panel:x(), 0 )
	-- bonus_bags_panel:bitmap( { name = "bag_test", texture="guis/textures/pd2/hud_bag" } )
	
	local bonus_bags_payout = loot_wrapper_panel:text( { layer = 1, valign = "center", name = "bonus_bags_payout", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = "", align = "left", vertical = "top", w = 512, h = 32 } )
	bonus_bags_payout:set_text( utf8.to_upper( managers.localization:text( "hud_bonus_bags_payout", { MONEY = managers.experience:cash_string( 0 ) } ) ) )
	bonus_bags_payout:set_position( bonus_bags_title:left(), bonus_bags_panel:bottom() )
	managers.hud:make_fine_text( bonus_bags_payout )
	bonus_bags_payout:set_w( loot_wrapper_panel:w() )
	
	local instant_cash_title = loot_wrapper_panel:text( { layer = 1, valign = "center", name = "instant_cash_title", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = utf8.to_upper( managers.localization:text( "hud_instant_cash" ) ), align = "left", vertical = "top", w = 512, h = 32 } )
	instant_cash_title:set_position( math.round( x + pad ), bonus_bags_payout:bottom() + 4 )
	managers.hud:make_fine_text( instant_cash_title )
	
	local instant_cash_text = loot_wrapper_panel:text( { layer = 1, valign = "center", name = "instant_cash_text", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = managers.experience:cash_string( 0 ), align = "left", vertical = "top", w = 512, h = 32 } )
	instant_cash_text:set_position( instant_cash_title:left(), instant_cash_title:bottom() )
	managers.hud:make_fine_text( instant_cash_text )
	instant_cash_text:set_w( loot_wrapper_panel:w() )
	
	
	
		
	-- HIDDEN CHALLENGES PANEL!
	local challenges_wrapper_panel = left_panel:panel( { visible = false, layer = 1, valign = {1/2,1/2}, name = "challenges_wrapper_panel", x = 0, y = y + math.round( managers.gui_data:scaled_size().height/2 ), h = math.round( managers.gui_data:scaled_size().height/2 ), w = left_panel:w() } )
	-- challenges_wrapper_panel:set_debug( true )
	local _, by = managers.gui_data:corner_safe_to_full( 0, managers.gui_data:corner_scaled_size().height ) -- + managers.gui_data:corner_scaled_size().y/2 )
	challenges_wrapper_panel:set_bottom( by )
	challenges_wrapper_panel:set_valign( {by/managers.gui_data:full_scaled_size().h,0} ) 
	
	local last_completed_challenge_title = challenges_wrapper_panel:text( { layer = 1, valign = "center", name = "last_completed_challenge_title", color = Color.white, font_size = tweak_data.hud_stats.objectives_title_size, font= tweak_data.hud_stats.objectives_font, text_id="victory_last_completed_challenge", align = "left", vertical = "top", w = 512, h = 32 } )
	last_completed_challenge_title:set_position( math.round( x ), 0 )
	managers.hud:make_fine_text( last_completed_challenge_title )
	
	local challenges_panel = challenges_wrapper_panel:panel( { layer = 1, valign = "center", name = "challenges_panel", x = math.round( objectives_title:x() + pad ), y = last_completed_challenge_title:bottom(), w = left_panel:w() - (last_completed_challenge_title:x() + pad) } )
	
	local near_completion_title = challenges_wrapper_panel:text( { layer = 1, valign = "center", name = "near_completion_title", color = Color.white, font_size = tweak_data.hud_stats.objectives_title_size, font= tweak_data.hud_stats.objectives_font, text_id="menu_near_completion_challenges", align = "left", vertical = "top", w = 512, h = 32 } )
	near_completion_title:set_position( math.round( x ), math.round( challenges_wrapper_panel:h()/3 ) )
	managers.hud:make_fine_text( near_completion_title )
	
	local near_completion_panel = challenges_wrapper_panel:panel( { layer = 1, valign = "center", name = "near_completion_panel", x = math.round( objectives_title:x() + pad ), y = near_completion_title:bottom(), w = left_panel:w() - (near_completion_title:x() + pad) } )
	
	local right_panel = self._full_hud_panel:panel( { name = "right_panel", valign = "scale", w = self._full_hud_panel:w()/3 }  )
	right_panel:set_x( self._full_hud_panel:w() )
	right_panel:rect( { name = "rect_bg", color = Color( 0.0, 0.0, 0.0 ):with_alpha( 0.75 ), valign = "scale", blend_mode = "normal" } )
	local blur_bg = right_panel:bitmap( { name = "blur_bg", texture="guis/textures/test_blur_df", w = right_panel:w(), h = right_panel:h(), valign = "scale", render_template="VertexColorTexturedBlur3D", layer=-1 } )
	
	-----------------------------------------------------------------------
	-- Day panel
	local days_title = right_panel:text( { layer = 1, x = 20, y = y, name = "days_title", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = "DAY 1 OF 3", align = "left", vertical = "top", w = 512, h = 32 } )
	managers.hud:make_fine_text( days_title )
	days_title:set_w( right_panel:w() )
		
	local day_wrapper_panel = right_panel:panel( { visible = true, layer = 1, name = "day_wrapper_panel", x = 0, y = y + math.round( managers.gui_data:scaled_size().height/2 ), h = math.round( managers.gui_data:scaled_size().height/1.5 ), w = right_panel:w() } )
	day_wrapper_panel:set_position( days_title:x() + pad, days_title:bottom() )
	-- day_wrapper_panel:set_debug( true )
	day_wrapper_panel:set_w( right_panel:w() - x - day_wrapper_panel:x() )
	
	local day_title = day_wrapper_panel:text( { layer = 0, x = 0, y = 0, name = "day_title", color = Color.white, font_size = tweak_data.hud_stats.objectives_title_size, font= tweak_data.hud_stats.objectives_font, text = "BLUH!", align = "left", vertical = "top", w = 512, h = 32 } )
	managers.hud:make_fine_text( day_title )
	day_title:set_w( day_wrapper_panel:w() )
	
	local paygrade_title = day_wrapper_panel:text( { name = "paygrade_title", font=tweak_data.menu.pd2_medium_font, font_size=tweak_data.hud_stats.loot_size, text=managers.localization:to_upper_text( "cn_menu_contract_paygrade_header" ), color=Color.white } )
	managers.hud:make_fine_text( paygrade_title )
	paygrade_title:set_top( math.round( day_title:bottom() ) )
	
	-- Stars
	local job_data = managers.job:current_job_data()
	if job_data then
		local job_stars = managers.job:current_job_stars()
		local job_and_difficulty_stars = managers.job:current_job_and_difficulty_stars()
		
		local risk_color = tweak_data.screen_colors.risk
		local filled_star_rect = { 0, 32, 32, 32 }
		local empty_star_rect = { 32, 32, 32, 32 }
		
		local cy = paygrade_title:center_y()
		local sx = paygrade_title:right() + 8
		
		local level_data = { texture = "guis/textures/pd2/mission_briefing/difficulty_icons", texture_rect = filled_star_rect, w = 16, h = 16, color = tweak_data.screen_colors.text, alpha = 1 }
		local risk_data = { texture = "guis/textures/pd2/crimenet_skull", w = 16, h = 16, color = risk_color, alpha = 1 }
		for i = 1, job_and_difficulty_stars do -- job_and_difficulty_stars do
			local x = sx + (i-1)*18
			local is_risk = i>job_stars
			local star_data = is_risk and risk_data or level_data
			
			local star = day_wrapper_panel:bitmap( star_data )
			star:set_x( x )
			star:set_center_y( math.round( cy ) )
		end
	end
	










	local day_payout = day_wrapper_panel:text( { layer = 0, x = 0, y = 0, name = "day_payout", color = Color.white, font_size = tweak_data.hud_stats.loot_size, font= tweak_data.hud_stats.objectives_font, text = "BLUH!", align = "left", vertical = "top", w = 512, h = 32 } )
	day_payout:set_text( utf8.to_upper( managers.localization:text( "hud_day_payout", { MONEY = managers.experience:cash_string( 0 ) } ) ) )
	managers.hud:make_fine_text( day_payout )
	day_payout:set_w( day_wrapper_panel:w() )
	day_payout:set_y( math.round( paygrade_title:bottom() ) )
	
	
	local bains_plan = day_wrapper_panel:text( { name = "bains_plan", text = managers.localization:to_upper_text("menu_description"), font = tweak_data.hud_stats.objective_desc_font, font_size = tweak_data.hud_stats.day_description_size+2, color = Color(1, 1, 1, 1), align = "left", vertical = "top", wrap = true, word_wrap = true, h = 128 } )
	managers.hud:make_fine_text( bains_plan )
	bains_plan:set_y( math.round( day_payout:bottom() + 20 ) )
	
	local day_description = day_wrapper_panel:text( { name = "day_description", text = "sdsd", font = tweak_data.hud_stats.objective_desc_font, font_size = tweak_data.hud_stats.day_description_size, color = Color(1, 1, 1, 1), align = "left", vertical = "top", wrap = true, word_wrap = true, h = 128 } )
	day_description:set_y( math.round( bains_plan:bottom() ) )
	day_description:set_h( day_wrapper_panel:h() )
	
	--------------------------------------------------------------------------
	--
	
	local profile_wrapper_panel = right_panel:panel( { layer = 1, valign = {1/2,1/2}, name = "profile_wrapper_panel", x = 20, y = y + math.round( managers.gui_data:scaled_size().height/2 ), h = math.round( managers.gui_data:scaled_size().height/2 ), w = left_panel:w() } )
	profile_wrapper_panel:set_w( right_panel:w() - x - profile_wrapper_panel:x() )
	-- challenges_wrapper_panel:set_debug( true )
	local _, by = managers.gui_data:corner_safe_to_full( 0, managers.gui_data:corner_scaled_size().height ) -- + managers.gui_data:corner_scaled_size().y/2 )
	profile_wrapper_panel:set_bottom( by )
	profile_wrapper_panel:set_valign( {by/managers.gui_data:full_scaled_size().h,0} )
	-- profile_wrapper_panel:set_debug( true )
	
	--[[local next_level_data = managers.experience:next_level_data() or {}
		
	local bg_ring = profile_wrapper_panel:bitmap( { texture="guis/textures/pd2/endscreen/exp_ring", w=64, h=64, color=Color.black, alpha=0.4 } )
	local exp_ring = profile_wrapper_panel:bitmap( { texture="guis/textures/pd2/endscreen/exp_ring", w=64, h=64, color=Color((next_level_data.current_points or 1) / (next_level_data.points or 1), 1, 1), render_template="VertexColorTexturedRadial", blend_mode="add", layer=1 } )
	bg_ring:set_bottom( profile_wrapper_panel:h() )
	exp_ring:set_bottom( profile_wrapper_panel:h() )
	
	local level_text = profile_wrapper_panel:text( { name = "level_text", font=tweak_data.menu.pd2_medium_font, font_size=tweak_data.hud_stats.day_description_size, text=tostring(managers.experience:current_level()), color=tweak_data.screen_colors.text } )	
	managers.hud:make_fine_text( level_text )
	level_text:set_center( exp_ring:center() )
	
	-- managers.localization:text( "menu_cash", { money=managers.money:total_string() } )
	local money_text = profile_wrapper_panel:text( { name = "money_text", text=utf8.to_upper( managers.localization:text( "menu_cash", { money=managers.money:total_string() } ) ), font_size=tweak_data.hud_stats.day_description_size, font=tweak_data.menu.pd2_small_font, color=tweak_data.screen_colors.text } )
	managers.hud:make_fine_text( money_text )	
	money_text:set_left( math.round( exp_ring:right() ) )
	money_text:set_bottom( math.round( exp_ring:center_y() ) )
	
	local next_level_in = profile_wrapper_panel:text( { name = "next_level_in", text="", font_size=tweak_data.menu.pd2_small_font_size, font=tweak_data.menu.pd2_small_font, color=tweak_data.screen_colors.text } )
	local points = next_level_data.points - next_level_data.current_points
	next_level_in:set_text( utf8.to_upper( managers.localization:text( "menu_next_level" ).." "..points ) )
	managers.hud:make_fine_text( next_level_in )	
	next_level_in:set_left( math.round( exp_ring:right() ) )
	next_level_in:set_top( math.round( exp_ring:center_y() ) )]]
		
	-- local loot_text = right_panel:text( { layer = 1, name = "loot_text", color = Color.white, font_size = tweak_data.hud_stats.objectives_title_size, font= tweak_data.hud_stats.objectives_font, text="$250.000", align = "right", vertical = "top", w = right_panel:w()/3, h = 32 } )
	-- loot_text:set_position( math.round( -x ), math.round( y ) )
	
	-- local small_loot_text = right_panel:text( { layer = 1, name = "small_loot_text", color = Color.white, font_size = tweak_data.hud_stats.objectives_title_size, font= tweak_data.hud_stats.objectives_font, text="$250.000", align = "right", vertical = "top", w = right_panel:w()/3, h = 32 } )
	-- small_loot_text:set_position( math.round( -x ), math.round( y + 28 ) )
	
	-- local total_loot_text = right_panel:text( { layer = 1, name = "total_loot_text", color = Color.white, font_size = tweak_data.hud_stats.objectives_title_size, font= tweak_data.hud_stats.objectives_font, text="$250.000", align = "right", vertical = "top", w = right_panel:w()/3, h = 32 } )
	-- total_loot_text:set_position( math.round( -x ), math.round( y + 60 ) )
	
	-- right_panel:set_debug( true )
	-- self._full_hud_panel:set_debug( false )
	self:_rec_round_object( left_panel )
	self:_rec_round_object( right_panel )
end

function HUDStatsScreen:_rec_round_object ( object )
	if object.children then
		for i, d in ipairs( object:children() ) do
			self:_rec_round_object( d )
		end
	end
	local x, y = object:position()
	object:set_position( math.round( x ), math.round (y ) )
end

function HUDStatsScreen:show()
	
	local safe = managers.hud.STATS_SCREEN_SAFERECT
	local full = managers.hud.STATS_SCREEN_FULLSCREEN
	--[[if not managers.hud:exists( safe ) then
		managers.hud:load_hud( full, false, true, false, {} )
		managers.hud:load_hud( safe, false, true, true, {} )
	end]]
	-- self:script( safe ):layout()
	-- managers.hud:show( safe )
	managers.hud:show( full )
	
	-- local full_hud = managers.hud:script( self.STATS_SCREEN_FULLSCREEN )
	local left_panel = self._full_hud_panel:child( "left_panel" )
	local right_panel = self._full_hud_panel:child( "right_panel" )
	-- right_panel:child( "loot_text" ):set_text( managers.experience:cash_string( managers.loot:get_real_total_loot_value() ) )
	-- right_panel:child( "small_loot_text" ):set_text( managers.experience:cash_string( managers.loot:get_real_total_small_loot_value() ) )
	-- right_panel:child( "total_loot_text" ):set_text( managers.experience:cash_string( managers.loot:get_real_total_value() ) )
	left_panel:stop()

	self:_create_stats_screen_profile( right_panel:child( "profile_wrapper_panel" ) )
	self:_create_stats_screen_objectives( left_panel:child( "objectives_panel" ) )
	self:_update_stats_screen_loot( left_panel:child( "loot_wrapper_panel" ) )
	self:_update_stats_screen_day( right_panel )
	-- self:_create_stats_screen_challenges( left_panel:child( "challenges_wrapper_panel" ):child( "challenges_panel" ), left_panel:child( "challenges_wrapper_panel" ):child( "near_completion_panel" ) )
	local teammates_panel = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_PD2 ).panel:child( "teammates_panel" )
	local objectives_panel = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_PD2 ).panel:child( "objectives_panel" )
	local chat_panel = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_PD2 ).panel:child( "chat_panel" )
	left_panel:animate( callback( self, self, "_animate_show_stats_left_panel" ), right_panel, teammates_panel, objectives_panel, chat_panel )
	-- self:script( safe ).panel:set_debug( true )
		
	self._showing_stats_screen = true
end

function HUDStatsScreen:hide()
	self._showing_stats_screen = false
	
	local safe = managers.hud.STATS_SCREEN_SAFERECT
	local full = managers.hud.STATS_SCREEN_FULLSCREEN
	if not managers.hud:exists( safe ) then
		return
	end
	-- self:script( safe ):hide()
	managers.hud:hide( safe)
	-- managers.hud:hide( full)
	-- NEED TO HIDE WHEN DONE ANIMATING
		
	local left_panel = self._full_hud_panel:child( "left_panel" )
	local right_panel = self._full_hud_panel:child( "right_panel" )
	left_panel:stop()
	local teammates_panel = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_PD2 ).panel:child( "teammates_panel" )
	local objectives_panel = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_PD2 ).panel:child( "objectives_panel" )
	local chat_panel = managers.hud:script( PlayerBase.PLAYER_INFO_HUD_PD2 ).panel:child( "chat_panel" )
	left_panel:animate( callback( self, self, "_animate_hide_stats_left_panel" ), right_panel, teammates_panel, objectives_panel, chat_panel )
		
	-- self:script( safe ).panel:set_debug( false )
end

function HUDStatsScreen:_create_stats_screen_objectives( panel )
	panel:clear()

	local x, y = 0, 0
	local panel_w = panel:w() - x
	for i,data in pairs( managers.objectives:get_active_objectives() ) do
		local obj_panel = panel:panel( { name = "obj_panel", x = x, y = y, w = panel_w } )
		-- obj_panel:set_debug( true )
		local obj_title = obj_panel:text( { name = "title", text = utf8.to_upper( data.text ), font = tweak_data.hud.medium_font, font_size = tweak_data.hud.active_objective_title_font_size, color = Color.white, align = "left", vertical = "top", wrap = true, word_wrap = true, h = tweak_data.hud.active_objective_title_font_size } )
		managers.hud:make_fine_text( obj_title )
		obj_title:set_w( obj_title:w() + 1 )
		local obj_description = obj_panel:text( { name = "description", text = data.description, font = tweak_data.hud_stats.objective_desc_font, font_size = 24, color = Color(1, 1, 1, 1), align = "left", vertical = "top", wrap = true, word_wrap = true, h = 128 } )
		managers.hud:make_fine_text( obj_description )
		obj_description:set_h( obj_description:h() + 10 )
		obj_panel:set_h( obj_title:h() + obj_description:h() )
		obj_description:set_lefttop( obj_title:leftbottom() )
		y = math.ceil( y + obj_panel:h() )
	end
	
	--[[local completed_objectives = managers.objectives:get_completed_objectives()
	for i,id in ipairs( managers.objectives:get_completed_objectives_ordered() ) do
		if i <= 11 then
			local data = completed_objectives[ id ]
			local obj_panel = panel:panel( { name = "obj_panel", x = x, y = y, w = panel_w, h = 16 } )
			-- obj_panel:set_debug( true )
			local obj_title = obj_panel:text( { name = "title", text = utf8.to_upper( (i == 11 and "...") or data.text ), font = tweak_data.hud.medium_font, font_size = tweak_data.hud.completed_objective_title_font_size, color = Color( 0.5, 0.5, 0.5 ), align = "left", vertical = "top", wrap = true, word_wrap = true, w = obj_panel:w(), h = tweak_data.hud.completed_objective_title_font_size } )
			managers.hud:make_fine_text( obj_title )
			-- print( "obj_title:h()", obj_title:x(), obj_title:y(), obj_title:w(), obj_title:h() )
			obj_panel:set_h( obj_title:h() )
			y = math.ceil( y + obj_panel:h() )
		end
	end]]
end

function HUDStatsScreen:_create_stats_screen_profile( profile_wrapper_panel )
	-- print( "_create_stats_screen_profile" )
	
	profile_wrapper_panel:stop()
	profile_wrapper_panel:clear()
	local next_level_data = managers.experience:next_level_data() or {}
	
	local bg_ring = profile_wrapper_panel:bitmap( { texture="guis/textures/pd2/level_ring_small", w=64, h=64, color=Color.black, alpha=0.4 } )
	local exp_ring = profile_wrapper_panel:bitmap( { texture="guis/textures/pd2/level_ring_small", rotation = 360, w=64, h=64, color=Color((next_level_data.current_points or 1) / (next_level_data.points or 1), 1, 1), render_template="VertexColorTexturedRadial", blend_mode="add", layer=1 } )
	bg_ring:set_bottom( profile_wrapper_panel:h() )
	exp_ring:set_bottom( profile_wrapper_panel:h() )
	
	local gain_xp = managers.experience:get_xp_dissected( true, 0 )
	local at_max_level = managers.experience:current_level() == managers.experience:level_cap()
	local can_lvl_up = not at_max_level and ( gain_xp >= (next_level_data.points - next_level_data.current_points) )
		
	local progress = (next_level_data.current_points or 1) / (next_level_data.points or 1)
	local gain_progress = (gain_xp or 1) / (next_level_data.points or 1)
	local exp_gain_ring = profile_wrapper_panel:bitmap( { texture="guis/textures/pd2/level_ring_potential_small", rotation = 360, w=64, h=64, color=Color(gain_progress, 1, 0), render_template="VertexColorTexturedRadial", blend_mode="normal", layer=2 } )
	-- print( "gain_progress", gain_progress, gain_xp, next_level_data.points )
	exp_gain_ring:rotate( 360 * (progress) )
	exp_gain_ring:set_center( exp_ring:center() )
	
	local level_text = profile_wrapper_panel:text( { name = "level_text", font=tweak_data.menu.pd2_medium_font, font_size=tweak_data.hud_stats.day_description_size, text=tostring(managers.experience:current_level()), color=tweak_data.screen_colors.text } )	
	managers.hud:make_fine_text( level_text )
	level_text:set_center( exp_ring:center() )
		
	--[[local money_text = profile_wrapper_panel:text( { name = "money_text", text=utf8.to_upper( managers.localization:text( "menu_cash", { money=managers.money:total_string() } ) ), font_size=tweak_data.hud_stats.day_description_size, font=tweak_data.menu.pd2_small_font, color=tweak_data.screen_colors.text } )
	managers.hud:make_fine_text( money_text )	
	money_text:set_left( math.round( exp_ring:right() ) )
	money_text:set_bottom( math.round( exp_ring:center_y() ) - 100 )]]
	
	if at_max_level then
		local text = managers.localization:to_upper_text( "hud_at_max_level" )
		local at_max_level_text = profile_wrapper_panel:text( { name = "at_max_level_text", text=text, font_size=tweak_data.menu.pd2_small_font_size, font=tweak_data.menu.pd2_small_font, color=tweak_data.hud_stats.potential_xp_color } )
		managers.hud:make_fine_text( at_max_level_text )
		at_max_level_text:set_left( math.round( exp_ring:right() + 4 ) )
		at_max_level_text:set_center_y( math.round( exp_ring:center_y() ) + 0 )
	else
		local next_level_in = profile_wrapper_panel:text( { name = "next_level_in", text="", font_size=tweak_data.menu.pd2_small_font_size, font=tweak_data.menu.pd2_small_font, color=tweak_data.screen_colors.text } )
		local points = next_level_data.points - next_level_data.current_points
		next_level_in:set_text( utf8.to_upper( managers.localization:text( "menu_es_next_level" ).." "..points ) )
		managers.hud:make_fine_text( next_level_in )	
		next_level_in:set_left( math.round( exp_ring:right() + 4 ) )
		next_level_in:set_center_y( math.round( exp_ring:center_y() ) - 20 )
		
		local text = managers.localization:to_upper_text( "hud_potential_xp", { XP = gain_xp } )
		local gain_xp_text = profile_wrapper_panel:text( { name = "gain_xp_text", text=text, font_size=tweak_data.menu.pd2_small_font_size, font=tweak_data.menu.pd2_small_font, color=tweak_data.hud_stats.potential_xp_color } )
		managers.hud:make_fine_text( gain_xp_text )	
		gain_xp_text:set_left( math.round( exp_ring:right() + 4 ) )
		gain_xp_text:set_center_y( math.round( exp_ring:center_y() ) + 0 )
		
		if can_lvl_up then
			local text = managers.localization:to_upper_text( "hud_potential_level_up" )
			local potential_level_up_text = profile_wrapper_panel:text( { layer = 3, name = "potential_level_up_text", align = "left", vertical = "center", blend_mode = "normal", visible = can_lvl_up, text=text, font_size=tweak_data.menu.pd2_small_font_size, font=tweak_data.menu.pd2_small_font, color=tweak_data.hud_stats.potential_xp_color } )
			managers.hud:make_fine_text( potential_level_up_text )	
			potential_level_up_text:set_left( math.round( exp_ring:right() + 4 ) )
			potential_level_up_text:set_center_y( math.round( exp_ring:center_y() ) + 20 )
			potential_level_up_text:animate( callback( self, self, "_animate_text_pulse" ), exp_gain_ring, exp_ring )
		end
	end
	
end

function HUDStatsScreen:_animate_text_pulse( text, exp_gain_ring, exp_ring )
	local t = 0
	local c = text:color()
	local w,h = text:size()
	local cx, cy = text:center()
	local ecx, ecy = exp_gain_ring:center()
	while true do
		local dt = coroutine.yield()
		t = t + dt

		local alpha = math.abs( ( (math.sin( (t) * 180 * 1) ) ) )
		
		-- text:set_color( Color( math.lerp( 1, c.red, alpha * alpha ), math.lerp( 1, c.green, alpha * alpha ), math.lerp( 1, c.blue, alpha * alpha ) ) )
		text:set_size( math.lerp( w * 2, w, alpha ), math.lerp( h * 2, h, alpha ) )
		text:set_font_size( math.lerp( 25, tweak_data.menu.pd2_small_font_size, alpha * alpha ) )
		-- text:set_center( cx, cy )
		text:set_center_y( cy )
		
		exp_gain_ring:set_size( math.lerp( 72, 64, alpha * alpha ), math.lerp( 72, 64, alpha * alpha ) )
		exp_gain_ring:set_center( ecx, ecy )
		
		exp_ring:set_size( exp_gain_ring:size() )
		exp_ring:set_center( exp_gain_ring:center() )
	end
end

function HUDStatsScreen:_update_stats_screen_loot( loot_wrapper_panel )
	print( "HUDStatsScreen:_update_stats_screen_loot" )
	local mandatory_bags_data = managers.loot:get_mandatory_bags_data()
	local secured_amount = managers.loot:get_secured_mandatory_bags_amount()
	
	local x
	local bag_texture, bag_rect = tweak_data.hud_icons:get_icon_data( "bag_icon" )
	
	--[[
	if mandatory_bags_data and mandatory_bags_data.amount then
		for i = 1, mandatory_bags_data.amount do
			local x = (i-1)*32
			local alpha = secured_amount >= i and 1 or 0.25
			mission_bags_panel:bitmap( { name = "bag"..i, texture=bag_texture, texture_rect = bag_rect, x = x, alpha = alpha } )
		end
	end
	
	local mission_amount = managers.loot:get_secured_mandatory_bags_amount()
	local mission_vis = mission_amount > 0 or secured_amount > 0
	]]
	
	local mission_amount = managers.loot:get_secured_mandatory_bags_amount()
	local mission_vis = mission_amount > 0 or secured_amount > 0
	
	local mission_bags_panel = loot_wrapper_panel:child( "mission_bags_panel" )
	mission_bags_panel:clear()
	
	if mandatory_bags_data and mandatory_bags_data.amount then
		if mandatory_bags_data.amount > 18 then
			local x = 0
			local bag = mission_bags_panel:bitmap( { name = "bag1", texture = bag_texture, texture_rect = bag_rect, x = x, alpha = 0.25 } )
			local bag_text = mission_bags_panel:text( { name = "bag_amount", text = " x" .. tostring( mandatory_bags_data.amount - mission_amount ), font_size = tweak_data.menu.pd2_small_font_size, font = tweak_data.menu.pd2_small_font } )
			managers.hud:make_fine_text( bag_text )
			bag_text:set_left( bag:right() )
			bag_text:set_center_y( math.round( bag:center_y() ) )
			
			local bag_gotten = mission_bags_panel:bitmap( { name = "bag1", texture = bag_texture, texture_rect = bag_rect, x = x } )
			local bag_text_gotten = mission_bags_panel:text( { name = "bag_amount", text = " x" .. tostring( mission_amount ), font_size = tweak_data.menu.pd2_small_font_size, font = tweak_data.menu.pd2_small_font } )
			managers.hud:make_fine_text( bag_text_gotten )
			bag_gotten:set_left( bag_text:right() + 10 )
			bag_text_gotten:set_left( bag_gotten:right() )
			bag_text_gotten:set_center_y( math.round( bag_gotten:center_y() ) )
		else
			local x = 0
			local y = 0
			for i = 1, mandatory_bags_data.amount do
				local alpha = secured_amount >= i and 1 or 0.25
				
				mission_bags_panel:bitmap( { name = "bag"..i, texture=bag_texture, texture_rect = bag_rect, x = x, y = y, alpha = alpha } )
				
				x = x + 32
				if x >= 288 then
					x = 0
					y = 22
				end
			end
		end
	end
	
	
	local bonus_amount = managers.loot:get_secured_bonus_bags_amount()
	local bonus_vis = bonus_amount > 0 or secured_amount > 0
	
	local bonus_bags_title = loot_wrapper_panel:child( "bonus_bags_title" )
	bonus_bags_title:set_alpha( bonus_vis and 1 or 0.5 )
	
	local bonus_bags_panel = loot_wrapper_panel:child( "bonus_bags_panel" )
	bonus_bags_panel:clear()
	
	if bonus_amount >= 10 then
		local x = 0
		local bag = bonus_bags_panel:bitmap( { name = "bag1", texture=bag_texture, texture_rect = bag_rect, x = x } )
		local bag_text = bonus_bags_panel:text( { name="bag_amount", text=" x"..tostring(bonus_amount), font_size=tweak_data.menu.pd2_small_font_size, font=tweak_data.menu.pd2_small_font } )
		
		managers.hud:make_fine_text(bag_text)
		bag_text:set_left( bag:right() )
		bag_text:set_center_y( math.round(bag:center_y()) )
	else
		for i = 1, bonus_amount do
			local x = (i-1) * 32
			bonus_bags_panel:bitmap( { name = "bag"..i, texture=bag_texture, texture_rect = bag_rect, x = x } )
		end
	end
	
	local mandatory_cash = managers.money:get_secured_mandatory_bags_money() -- bonus_amount * ( tweak_data.money_manager.bag_value * managers.money:get_job_bag_value() )
	local mission_bags_payout = loot_wrapper_panel:child( "mission_bags_payout" )
	mission_bags_payout:set_visible( mission_vis )
	mission_bags_payout:set_text( utf8.to_upper( managers.localization:text( "hud_bonus_bags_payout", { MONEY = managers.experience:cash_string( mandatory_cash ) } ) ) )
	
	local bonus_cash = managers.money:get_secured_bonus_bags_money() -- bonus_amount * ( tweak_data.money_manager.bag_value * managers.money:get_job_bag_value() )
	local bonus_bags_payout = loot_wrapper_panel:child( "bonus_bags_payout" )
	bonus_bags_payout:set_visible( bonus_vis )
	bonus_bags_payout:set_text( utf8.to_upper( managers.localization:text( "hud_bonus_bags_payout", { MONEY = managers.experience:cash_string( bonus_cash ) } ) ) )
	
	local instant_cash = managers.loot:get_real_total_small_loot_value()
	local instant_vis = instant_cash > 0
	
	local instant_cash_title = loot_wrapper_panel:child( "instant_cash_title" )
	instant_cash_title:set_alpha( instant_vis and 1 or 0.5 )
	
	local instant_cash_text = loot_wrapper_panel:child( "instant_cash_text" )
	instant_cash_text:set_text( utf8.to_upper( managers.experience:cash_string( instant_cash ) ) )
	instant_cash_text:set_alpha( instant_vis and 1 or 0.5 )
end

function HUDStatsScreen:_update_stats_screen_day( right_panel )
	local job_data = managers.job:current_job_data()
	local stage_data = managers.job:current_stage_data()
	local has_stage_data = stage_data and true or false
	
	local days_title = right_panel:child( "days_title" )
	days_title:set_visible( has_stage_data )
	
	local day_wrapper_panel = right_panel:child( "day_wrapper_panel" )
	day_wrapper_panel:set_visible( has_stage_data )
	
	if job_data and managers.job:current_job_id() == "safehouse" and Global.mission_manager.saved_job_values.playedSafeHouseBefore then
		right_panel:set_visible( false )
		return
	end
	
	if has_stage_data then
		local num_stages = self._current_job_data and #self._current_job_data.chain or 0
		
		local day = managers.job:current_stage()
		local days = job_data and #job_data.chain or 0
		days_title:set_text( utf8.to_upper( managers.localization:text( "hud_days_title", { DAY = day, DAYS = days } ) ) )
		
		--[[
		local job_and_difficulty_stars = managers.job:current_job_and_difficulty_stars() or 1
		local job_stars = managers.job:current_job_stars() or 1
		local difficulty_stars = job_and_difficulty_stars - job_stars
		local money_multiplier = managers.money:get_contract_difficulty_multiplier( difficulty_stars )
		]]
		
		local payout = managers.money:get_potential_payout_from_current_stage()
		-- payout = payout + payout * money_multiplier
		local day_payout = day_wrapper_panel:child( "day_payout" )
		day_payout:set_text( utf8.to_upper( managers.localization:text( "hud_day_payout", { MONEY = managers.experience:cash_string( payout ) } ) ) )
		
		local level_data = managers.job:current_level_data()
		if level_data then
			local day_title = day_wrapper_panel:child( "day_title" )
			day_title:set_text( utf8.to_upper( managers.localization:text( level_data.name_id ) ) )
			
			local briefing_id = stage_data.briefing_id or level_data.briefing_id
			local day_description = day_wrapper_panel:child( "day_description" )
			day_description:set_text( managers.localization:text( briefing_id ) )
			-- local desc_text = self._panel:text( { name="description_text", text=managers.localization:text(level_data.briefing_id), font_size=tweak_data.menu.pd2_small_font_size, font=tweak_data.menu.pd2_small_font, wrap=true, word_wrap=true, y=tweak_data.menu.pd2_medium_font_size+15, x=10, color=tweak_data.screen_colors.text } )
			
		end
	end
end

function HUDStatsScreen:_create_stats_screen_challenges( challenges_panel, near_completion_panel )
	challenges_panel:clear()
	
	local last_comleted_title_text = challenges_panel:text( { name = "last_comleted_title_text", text = utf8.to_upper( managers.challenges:get_last_comleted_title_text() ), font_size = tweak_data.menu.loading_challenge_name_font_size, font= tweak_data.hud_stats.objectives_font } )
	managers.hud:make_fine_text( last_comleted_title_text )
	local last_comleted_description_text = challenges_panel:text( { name = "last_comleted_description_text", text = utf8.to_upper( managers.challenges:get_last_comleted_description_text() ), font_size = tweak_data.hud.small_font_size, font = tweak_data.hud.small_font, y = last_comleted_title_text:bottom(), wrap = true, word_wrap = true } )
	managers.hud:make_fine_text( last_comleted_description_text )
	-- utf8.to_upper( managers.challenges:get_last_comleted_title_text() )
	-- utf8.to_upper( managers.challenges:get_last_comleted_description_text() )
	
	near_completion_panel:clear()
	
	local challenges = managers.challenges:get_near_completion()
	challenges = { challenges[1], challenges[2], challenges[3] }
	
	local w = near_completion_panel:w() - 8
	local y = 0
	for i,challenge in ipairs( challenges ) do
		local text = near_completion_panel:text( { text = utf8.to_upper( challenge.name ), y = y, font = tweak_data.hud.medium_font, font_size = tweak_data.menu.loading_challenge_name_font_size, color = Color.white, align="left", layer = 1 } )
		managers.hud:make_fine_text( text )
		y = y + text:h()
		
		local c_panel = near_completion_panel:panel( { w = w, h = 22, y = y } )
		local bg_bar = c_panel:rect( { x = 0, y = 0, w = c_panel:w(), h = c_panel:h(), color = Color.black:with_alpha( 0.5 ), align="center", halign="center", vertical="center", layer = 1 } )
		local bar = c_panel:gradient( { orientation = "vertical", gradient_points = { 0, Color( 1,255/255,168/255,0), 1, Color( 1,154/255,102/255,0) },
										x = 2, y = 2, w = (bg_bar:w() - 4) * (challenge.amount/challenge.count), h = bg_bar:h() - 4, layer = 2, align="center", halign="center", vertical="center", } )
		local progress_text = c_panel:text( { font_size = tweak_data.menu.loading_challenge_progress_font_size, font = tweak_data.hud.medium_font, x = 0, y = 0, h = bg_bar:h(), w = bg_bar:w(),
										align="center", halign="center", vertical="center", valign="center", color = Color.white, layer = 3,
										text = challenge.amount.."/"..challenge.count,
									} )
									
		y = y + c_panel:h()
	end
	
	--[[for i,challenge in ipairs( c_panels ) do
		local h = challenge.panel:h() + challenge.text:h()
		challenge.text:set_bottom( near_completion_title:bottom() + 42 * tweak_data.scale.loading_challenge_bar_scale + ( h + 16 * tweak_data.scale.loading_challenge_bar_scale ) * (i-1) )
		challenge.panel:set_top( challenge.text:bottom() )
		
		challenge.text:set_right( safe_rect_pixels.width )
		challenge.panel:set_left( near_completion_title:left() )
	end]]
	
end

----------------------------------------------------------------------------

function HUDStatsScreen:loot_value_updated()
	local right_panel = self._full_hud_panel:child( "right_panel" )
	-- right_panel:child( "loot_text" ):set_text( managers.experience:cash_string( managers.loot:get_real_total_loot_value() ) )
	-- right_panel:child( "small_loot_text" ):set_text( managers.experience:cash_string( managers.loot:get_real_total_small_loot_value() ) )
	-- right_panel:child( "total_loot_text" ):set_text( managers.experience:cash_string( managers.loot:get_real_total_value() ) )
	
	local left_panel = self._full_hud_panel:child( "left_panel" )
	self:_update_stats_screen_loot( left_panel:child( "loot_wrapper_panel" ) )
end

----------------------------------------------------------------------------

function HUDStatsScreen:_animate_show_stats_left_panel( left_panel, right_panel, teammates_panel, objectives_panel, chat_panel )
	-- left_panel:set_x( -left_panel:w() )
	local start_x = left_panel:x()
	local start_a = 1-start_x/-left_panel:w()
	local TOTAL_T = 0.33 * (start_x/-left_panel:w())
	local t = 0
	-- print( "TOTAL_T", TOTAL_T )
	while t < TOTAL_T do
	-- while left_panel:x() ~= 0 do
		local dt = coroutine.yield() * (1/TimerManager:game():multiplier())
		t = t + dt
		local a = math.lerp( start_a, 1, t/TOTAL_T)
		left_panel:set_alpha( a )
		left_panel:set_x( math.lerp( start_x, 0, t/TOTAL_T ) )
		
		right_panel:set_alpha( a )
		right_panel:set_x( right_panel:parent():w() - ( left_panel:x() + right_panel:w() ) )
		
		local a_half = ( 0.5 + (1 - a)*0.5 )
		teammates_panel:set_alpha( a_half )
		objectives_panel:set_alpha( (1 - a) )
		chat_panel:set_alpha( a_half )
		-- self._test_circle:set_current( 10 *( t/2) )
	end
	left_panel:set_x( 0 )
	left_panel:set_alpha( 1 )
	teammates_panel:set_alpha( 0.5 )
	objectives_panel:set_alpha( 0 )
	chat_panel:set_alpha( 0.5 )
	
	right_panel:set_alpha( 1 )
	right_panel:set_x( right_panel:parent():w() - ( right_panel:w() ) )
	-- print( "HUDStatsScreen:_animate_show_stats_left_panel done" )
end

function HUDStatsScreen:_animate_hide_stats_left_panel( left_panel, right_panel, teammates_panel, objectives_panel, chat_panel )
	-- left_panel:set_x( -left_panel:w() )
	local start_x = left_panel:x()
	local start_a = 1-start_x/-left_panel:w()
	local TOTAL_T = 0.33 * (1 - start_x/-left_panel:w())
	local t = 0
	while t < TOTAL_T do
	-- while left_panel:x() ~= 0 do
		local dt = coroutine.yield() * (1/TimerManager:game():multiplier())
		t = t + dt
		local a = math.lerp( start_a, 0, t/TOTAL_T)
		left_panel:set_alpha( a )
		left_panel:set_x( math.lerp( start_x, -left_panel:w(), t/TOTAL_T ) )
		
		right_panel:set_alpha( a )
		right_panel:set_x( right_panel:parent():w() - ( left_panel:x() + right_panel:w() ) )
		
		local a_half = ( 0.5 + (1 - a)*0.5 )
		teammates_panel:set_alpha( a_half )
		objectives_panel:set_alpha( (1 - a) )
		chat_panel:set_alpha( a_half )
		-- self._test_circle:set_current( 10 *( t/2) )
	end
	left_panel:set_x( -left_panel:w() )
	left_panel:set_alpha( 0 )
	teammates_panel:set_alpha( 1 )
	objectives_panel:set_alpha( 1 )
	chat_panel:set_alpha( 1 )
	
	right_panel:set_alpha( 0 )
	right_panel:set_x( right_panel:parent():w() )
	-- print( "HUDStatsScreen:_animate_hide_stats_left_panel done" )
end
