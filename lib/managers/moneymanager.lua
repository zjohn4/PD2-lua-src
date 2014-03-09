MoneyManager = MoneyManager or class()
--[[ MoneyManager.PATH = "gamedata/hints"
MoneyManager.FILE_EXTENSION = "hint"
MoneyManager.FULL_PATH = MoneyManager.PATH .. "." .. MoneyManager.FILE_EXTENSION ]]

function MoneyManager:init()
	self:_setup()
end

function MoneyManager:_setup()
	if not Global.money_manager then
		Global.money_manager = {}
		Global.money_manager.total = Application:digest_value( 0, true ) -- Total spendable amount
		Global.money_manager.total_collected = Application:digest_value( 0, true ) -- Total aquired without any costs or deductions
		Global.money_manager.offshore = Application:digest_value( 0, true )
		Global.money_manager.total_spent = Application:digest_value( 0, true )
	end
	self._global = Global.money_manager
	self._heist_total = 0
	self._heist_spending = 0
	self._heist_offshore = 0
	self._active_multipliers = {}
	
	self._stage_payout = 0
	self._job_payout = 0
	self._bag_payout = 0
	self._small_loot_payout = 0
	self._crew_payout = 0
	
	self._cash_tousand_separator = managers.localization:text( "cash_tousand_separator" )
	self._cash_sign = managers.localization:text( "cash_sign" )
end

function MoneyManager:total_string_no_currency()
	local total = math.round( self:total() )
	total = tostring( total )
	local reverse = string.reverse( total )
	local s = ""
	for i = 1, string.len( reverse ) do
		s = s..string.sub( reverse, i, i )..((math.mod( i, 3 ) == 0 and (i ~= string.len( reverse )) and self._cash_tousand_separator) or "")
	end
	return string.reverse( s )
end

function MoneyManager:total_string()
	local total = math.round( self:total() )
	total = tostring( total )
	local reverse = string.reverse( total )
	local s = ""
	for i = 1, string.len( reverse ) do
		s = s..string.sub( reverse, i, i )..((math.mod( i, 3 ) == 0 and (i ~= string.len( reverse )) and self._cash_tousand_separator) or "")
	end
	return self._cash_sign..string.reverse( s )
end

function MoneyManager:total_collected_string_no_currency()
	local total = math.round( self:total_collected() )
	total = tostring( total )
	local reverse = string.reverse( total )
	local s = ""
	for i = 1, string.len( reverse ) do
		s = s..string.sub( reverse, i, i )..((math.mod( i, 3 ) == 0 and (i ~= string.len( reverse )) and self._cash_tousand_separator) or "")
	end
	return string.reverse( s )
end

function MoneyManager:total_collected_string()
	local total = math.round( self:total_collected() )
	total = tostring( total )
	local reverse = string.reverse( total )
	local s = ""
	for i = 1, string.len( reverse ) do
		s = s..string.sub( reverse, i, i )..((math.mod( i, 3 ) == 0 and (i ~= string.len( reverse )) and self._cash_tousand_separator) or "")
	end
	return self._cash_sign..string.reverse( s )
end

function MoneyManager:add_decimal_marks_to_string( string )
	local total = string
	local reverse = string.reverse( total )
	local s = ""
	for i = 1, string.len( reverse ) do
		s = s..string.sub( reverse, i, i )..((math.mod( i, 3 ) == 0 and (i ~= string.len( reverse )) and self._cash_tousand_separator) or "")
	end
	return string.reverse( s )
end

function MoneyManager:use_multiplier( multiplier )
	if not tweak_data.money_manager.multipliers[ multiplier ] then
		Application:error( "Unknown multiplier \"" .. tostring( multiplier ) .. " in money manager." )
		return
	end
	
	self._active_multipliers[ multiplier ] = tweak_data.money_manager.multipliers[ multiplier ]
end

function MoneyManager:remove_multiplier( multiplier )
	if not tweak_data.money_manager.multipliers[ multiplier ] then
		Application:error( "Unknown multiplier \"" .. tostring( multiplier ) .. " in money manager." )
		return
	end
	
	self._active_multipliers[ multiplier ] = nil
end

function MoneyManager:perform_action( action )
	if true then
		return
	end
	--[[if not tweak_data.money_manager.actions[ action ] then
		Application:error( "Unknown action \"" .. tostring( action ) .. " in money manager." )
		return
	end
	
	self:_add( tweak_data.money_manager.actions[ action ] )]]
end

function MoneyManager:perform_action_interact( name )
	if true then
		return
	end
	--[[if not tweak_data.money_manager.actions.interact[ name:key() ] then
		return
	end
	
	self:_add( tweak_data.money_manager.actions.interact[ name:key() ] )]]
end

function MoneyManager:perform_action_money_wrap( amount )
	self:_add( amount )
end

------------------------------------------------------------------
function MoneyManager:get_civilian_deduction()
	local has_active_job = managers.job:has_active_job()
	local job_and_difficulty_stars = has_active_job and managers.job:current_job_and_difficulty_stars() or 1

	return math.round( tweak_data:get_value( "money_manager", "killing_civilian_deduction", job_and_difficulty_stars ) )
end

function MoneyManager:civilian_killed()
	local deduct_amount = self:get_civilian_deduction()
	
	-- local text = "Deducting "..managers.experience:cash_string( deduct_amount ).." from your account in fencing costs." -- managers.localization:text( equipment.text_id )	
	local text = managers.localization:text( "hud_civilian_killed_message", { AMOUNT = managers.experience:cash_string( deduct_amount ) } )
	local title = managers.localization:text( "hud_civilian_killed_title" )
	managers.hud:present_mid_text( { text = text, title = title, time = 4 } )
	
	self:_deduct_from_total( deduct_amount )
end

------------------------------------------------------------------

-- ( (stage_white_stars + ( stage_white_stars * diff_multiplier )) + (job_white_stars + ( job_white_stars * diff_multiplier )) + (bonus_bags_value + ( bonus_bags_value * diff_multiplier ) ) ) * alive_players + ( small_loot )

-- simplified
-- ( (stage_white_stars + job_white_stars + bonus_bags_value) * (diff_multiplier+1) ) * alive_players + ( small_loot_value * diff_multiplier )

--[[
function MoneyManager.mon( sws, jws, bbv, dm, ap, sl )
	return ( ( sws + ( sws * dm ) ) + ( jws + ( jws * dm ) ) + ( bbv + ( bbv * dm ) ) ) * ap + sl
	,( ( sws + jws + bbv ) * (dm+1) ) * ap + sl
end]]

function MoneyManager:on_mission_completed( num_winners )
	if managers.job:skip_money() then -- Skip money if escape level
		managers.loot:set_postponed_small_loot()

		return
	end
	
	local stage_value, job_value, bag_value, small_value, crew_value, total_payout, risk_table = self:get_real_job_money_values( num_winners )
	managers.loot:clear_postponed_small_loot()

	self:_set_stage_payout( stage_value + risk_table.stage_risk )
	self:_set_job_payout( job_value + risk_table.job_risk )
	self:_set_bag_payout( bag_value + risk_table.bag_risk )
	self:_set_small_loot_payout( small_value + risk_table.small_risk )
	self:_set_crew_payout( crew_value )
	
	self:_add_to_total( total_payout )
end

function MoneyManager:get_contract_money_by_stars( job_stars, risk_stars, job_days, job_id )
	local job_and_difficulty_stars = job_stars + risk_stars
	local job_stars = job_stars
	local difficulty_stars = risk_stars
	local player_stars = managers.experience:level_to_stars()

	local params = {}
	params.job_id = job_id
	params.job_stars = job_stars
	params.difficulty_stars = difficulty_stars


	params.success = true
	params.num_winners = 1
	params.on_last_stage = true
	params.player_stars = player_stars
	params.secured_bags = 0
	params.small_value = 0


	local stage_value, job_value, bag_value, small_value, crew_value, total_payout, risk_table = self:get_money_by_params( params )

	local stage_risk_value = risk_table.stage_risk
	local job_risk_value = risk_table.job_risk

	local total_stage_value = stage_value
	local total_stage_risk_value = stage_risk_value




	local total_job_value = job_value
	local total_job_risk_value = job_risk_value

	total_payout = total_stage_value + total_stage_risk_value + total_job_value + total_job_risk_value

	return total_payout, { stage_value, total_stage_value, stage_risk_value, total_stage_risk_value }, { job_value, total_job_value, job_risk_value, total_job_risk_value }
end

function MoneyManager:get_money_by_job( job_id, difficulty )
	if not job_id or not tweak_data.narrative.jobs[ job_id ] then
		Application:error( "Error: Missing Job =", job_id )
		return 0
	end

	if tweak_data.narrative.jobs[ job_id ].payout and tweak_data.narrative.jobs[ job_id ].payout[ difficulty ] then
		return tweak_data.narrative.jobs[ job_id ].payout[ difficulty ]
	else
		local payout = 0
		for _, level in pairs( tweak_data.narrative.jobs[ job_id ].chain ) do
			if tweak_data.levels[ level.level_id ] and tweak_data.levels[ level.level_id ].payout and tweak_data.levels[ level.level_id ].payout[ difficulty ] then
				payout = payout + tweak_data.levels[ level.level_id ].payout[ difficulty ]
			end
		end

		return payout
	end
end

function MoneyManager:get_money_by_params( params )
	local job_id = params.job_id
	local job_stars = params.job_stars or 0
	local difficulty_stars = params.difficulty_stars or params.risk_stars or 0
	local job_and_difficulty_stars = job_stars + difficulty_stars

	local success = params.success
	local num_winners = params.num_winners or 1
	local on_last_stage = params.on_last_stage
	local current_job_stage = params.current_stage or 1
	local total_stages = job_id and #tweak_data.narrative.jobs[ job_id ].chain or 1

	local player_stars = params.player_stars or managers.experience:level_to_stars() or 0

	local total_stars = math.min( job_stars, player_stars )
	local total_difficulty_stars = difficulty_stars
	local money_multiplier = self:get_contract_difficulty_multiplier( total_difficulty_stars )
	local contract_money_multiplier = 1 + money_multiplier / 10
	local small_loot_multiplier = managers.money:get_small_loot_difficulty_multiplier( total_difficulty_stars ) or 0
	
	local cash_skill_bonus = 1
	local bag_skill_bonus = managers.player:upgrade_value( "player", "secured_bags_money_multiplier", 1 )
	if managers.groupai and managers.groupai:state():whisper_mode() then
		cash_skill_bonus = cash_skill_bonus * managers.player:team_upgrade_value( "cash", "stealth_money_multiplier", 1 )
		bag_skill_bonus = bag_skill_bonus * managers.player:team_upgrade_value( "cash", "stealth_bags_multiplier", 1 )
	end
	
	local bonus_bags = params.secured_bags or managers.loot:get_secured_bonus_bags_value()
	local mandatory_bags = params.secured_bags or managers.loot:get_secured_mandatory_bags_value()
	local real_small_value = params.small_value or math.round( managers.loot:get_real_total_small_loot_value() )

	local offshore_rate = tweak_data:get_value( "money_manager", "offshore_rate" )

	local total_payout = 0
	local stage_value = 0
	local job_value = 0
	local bag_value = 0
	local small_value = 0
	local crew_value = 0
	local stage_risk = 0
	local job_risk = 0
	local bag_risk = 0
	local small_risk = 0

	local static_value = self:get_money_by_job( job_id, difficulty_stars + 1 ) * cash_skill_bonus
	if static_value then
	
	
		small_value = real_small_value + managers.loot:get_real_total_postponed_small_loot_value()

		if on_last_stage then
			bag_value = bonus_bags * total_stages
			bag_risk = math.round( bag_value * money_multiplier * bag_skill_bonus )
			bag_value = ( bag_value + mandatory_bags ) * bag_skill_bonus

			total_payout = math.round( ( static_value + bag_value + bag_risk ) / offshore_rate + small_value )

			stage_value = math.round( static_value / offshore_rate )
			bag_value = math.round( bag_value / offshore_rate )
			bag_risk = math.round( bag_risk / offshore_rate )

			crew_value = total_payout
			total_payout = math.round( total_payout * ( tweak_data:get_value( "money_manager", "alive_humans_multiplier", num_winners ) or 1 ) )
			crew_value = total_payout - crew_value
		else
			total_payout = small_value
		end
		
		local limited_bonus = tweak_data:get_value("money_manager", "limited_bonus_multiplier") or 1
		if limited_bonus > 1 then
			stage_value = stage_value * limited_bonus
			stage_risk = stage_risk * limited_bonus
			bag_value = bag_value * limited_bonus
			bag_risk = bag_risk * limited_bonus
			small_value = small_value * limited_bonus
			small_risk = small_risk * limited_bonus
			crew_value = crew_value * limited_bonus
			total_payout = total_payout * limited_bonus
		end
		
	else
		
		stage_value = self:get_stage_payout_by_stars( total_stars ) or 0
		local mandatory_bag_value = 0
		local bonus_bag_value = 0
		small_value = real_small_value + managers.loot:get_real_total_postponed_small_loot_value()

		if on_last_stage then
			job_value = self:get_job_payout_by_stars( total_stars ) or 0

			bonus_bag_value = bonus_bags * total_stages
			mandatory_bag_value = mandatory_bags
		end
		


		local is_level_limited = player_stars < job_stars
		if is_level_limited and stage_value > 0 then
			local unlimited_stage_value = self:get_stage_payout_by_stars( job_stars ) or 0
			local unlimited_job_value = 0
			local unlimited_bonus_bag_value = 0
			local unlimited_mandatory_bag_value = 0
			local unlimited_small_value = real_small_value
			
			if managers.job:on_last_stage() then
				unlimited_job_value = self:get_job_payout_by_stars( job_stars ) or 0
				unlimited_bonus_bag_value = bonus_bags * tweak_data:get_value( "money_manager", "bag_value_multiplier", job_stars )
				unlimited_mandatory_bag_value = mandatory_bags
			end
			
			local unlimited_payout = unlimited_stage_value + unlimited_job_value + unlimited_bonus_bag_value + unlimited_mandatory_bag_value + unlimited_small_value
			
			total_payout = math.round( stage_value + job_value + bonus_bag_value + mandatory_bag_value + small_value )
			
			local diff_in_money = unlimited_payout - total_payout
			local diff_in_stars = job_stars - player_stars
			local tweak_multiplier = tweak_data:get_value( "money_manager", "level_limit", "pc_difference_multipliers", diff_in_stars ) or 0
			
			local new_total_payout = total_payout + math.round( diff_in_money * tweak_multiplier )
			
			local stage_ratio = stage_value / total_payout
			local small_ratio = small_value / total_payout
			local bonus_bag_ratio = bonus_bag_value / total_payout
			local mandatory_bag_ratio = mandatory_bag_value / total_payout
			local job_ratio = job_value / total_payout
			
			stage_value = math.round( new_total_payout * stage_ratio )
			small_value = math.round( new_total_payout * small_ratio )
			bonus_bag_value = math.round( new_total_payout * bonus_bag_ratio * bag_skill_bonus )
			mandatory_bag_value = math.round( new_total_payout * mandatory_bag_ratio * bag_skill_bonus )
			job_value = math.round( new_total_payout * job_ratio )
			
			local rounding_error = new_total_payout - ( stage_value + small_value + bonus_bag_value + mandatory_bag_value + job_value )
			job_value = job_value + rounding_error
		end
		
		stage_risk = math.round( stage_value * contract_money_multiplier )
		job_risk = math.round( job_value * contract_money_multiplier )
		bag_risk = math.round( bonus_bag_value * money_multiplier )
		small_risk = math.round( small_value * small_loot_multiplier )
		
		total_payout = stage_value + job_value + bonus_bag_value + mandatory_bag_value + small_value
		total_payout = total_payout + stage_risk + job_risk + bag_risk + small_risk
		
		crew_value = math.round( total_payout )
		total_payout = math.round( total_payout * ( tweak_data:get_value( "money_manager", "alive_humans_multiplier", num_winners ) or 1 ) )
		crew_value = math.round( total_payout - crew_value )
		
		if not static_value then
			total_payout = total_payout + tweak_data:get_value( "money_manager", "flat_stage_completion" )
			stage_value = stage_value + tweak_data:get_value( "money_manager", "flat_stage_completion" )
			
			if on_last_stage then
				total_payout = total_payout + tweak_data:get_value( "money_manager", "flat_job_completion" )
				job_value = job_value + tweak_data:get_value( "money_manager", "flat_job_completion" )
			end
		end

		local bag_value = math.round( ( bonus_bag_value + mandatory_bag_value ) / offshore_rate )
		bag_risk = math.round( bag_risk / offshore_rate )
	end

	return stage_value, job_value, bag_value, small_value, crew_value, total_payout, { stage_risk = stage_risk, job_risk = job_risk, bag_risk = bag_risk, small_risk = small_risk }
end

function MoneyManager:get_real_job_money_values( num_winners, potential_payout )
	local has_active_job = managers.job:has_active_job()
	local job_and_difficulty_stars = has_active_job and managers.job:current_job_and_difficulty_stars() or 1

	local job_id = managers.job:current_job_id()
	local job_stars = has_active_job and managers.job:current_job_stars() or 1
	local difficulty_stars = job_and_difficulty_stars - job_stars
	local current_stage = has_active_job and managers.job:current_stage() or 1
	local is_professional = has_active_job and managers.job:is_current_job_professional() or false

	local on_last_stage = potential_payout and true or ( has_active_job and managers.job:on_last_stage() )

	return self:get_money_by_params( {	job_id = job_id,
						job_stars = job_stars,
						difficulty_stars = difficulty_stars,
						current_stage = current_stage,
						professional = is_professional,
						success = true,
						num_winners = num_winners,
						on_last_stage = on_last_stage	} )
end

--[[function MoneyManager:on_stage_completed( num_winners )
	if not managers.job:has_active_job() then
		return 0
	end
	
	-- local stars = managers.job:current_job_and_difficulty_stars()
	-- local amount = tweak_data.money_manager.stage_completion[ stars ]
	local stage_value = self:_get_contract_money( false, nil )
	local amount = stage_value

	amount = math.round( amount * tweak_data:get_value( "money_manager", "alive_humans_multiplier", num_winners ) )
	
	self:_add_to_total( amount )
	self:_set_stage_payout( stage_value )
	self:_set_crew_payout( amount - stage_value )
	return amount
end]]

--[[
function MoneyManager:on_job_completed( num_winners )	-- OLD
	if not managers.job:has_active_job() then
		return 0
	end
	
	-- local stars = managers.job:current_job_and_difficulty_stars()
	-- local amount = tweak_data.money_manager.job_completion[ stars ]
	local stage_value = self:_get_contract_money( false, nil )		-- for day/stage
	local job_value = self:_get_contract_money( true, nil )	-- for contract/job
	local bag_value = self:get_secured_bonus_bags_money() -- managers.loot:get_secured_bonus_bags_amount() * ( tweak_data.money_manager.bag_value * self:get_job_bag_value() )
	
	local amount = stage_value + job_value -- + ( managers.loot:get_secured_bonus_bags_amount() or 0 )
	amount = amount + bag_value

	amount = math.round( amount * tweak_data:get_value( "money_manager", "alive_humans_multiplier", num_winners ) )
	
	self:_add_to_total( amount )
	
	self:_set_stage_payout( stage_value )
	self:_set_job_payout( job_value )
	self:_set_bag_payout( bag_value )
	self:_set_crew_payout( amount - stage_value - job_value - bag_value )
	
	return amount
end
]]

function MoneyManager:get_secured_bonus_bags_money()
	local job_id = managers.job:current_job_id()
	local stars = managers.job:has_active_job() and managers.job:current_difficulty_stars() or 0
	local money_multiplier = self:get_contract_difficulty_multiplier( stars )
	local total_stages = job_id and #tweak_data.narrative.jobs[ job_id ].chain or 1
	local bag_skill_bonus = managers.player:upgrade_value( "player", "secured_bags_money_multiplier", 1 )

	local bonus_bags = managers.loot:get_secured_bonus_bags_value()
	local bag_value = bonus_bags * total_stages
	local bag_risk = math.round( bag_value * money_multiplier )

	return math.round( ( bag_value + bag_risk ) * bag_skill_bonus / tweak_data:get_value( "money_manager", "offshore_rate" ) )
end

function MoneyManager:get_secured_mandatory_bags_money()
	local mandatory_value = managers.loot:get_secured_mandatory_bags_value()
	local bag_skill_bonus = managers.player:upgrade_value( "player", "secured_bags_money_multiplier", 1 )

	return math.round( mandatory_value * bag_skill_bonus / tweak_data:get_value( "money_manager", "offshore_rate" ) )
end

function MoneyManager:get_secured_bonus_bag_value( carry_id, value )
	local bag_value = 0
	local bag_risk = 0
	local bag_skill_bonus = managers.player:upgrade_value( "player", "secured_bags_money_multiplier", 1 )

	if managers.loot:is_bonus_bag( carry_id ) then
		local job_id = managers.job:current_job_id()
		local stars = managers.job:has_active_job() and managers.job:current_difficulty_stars() or 0
		local money_multiplier = self:get_contract_difficulty_multiplier( stars )
		local total_stages = job_id and #tweak_data.narrative.jobs[ job_id ].chain or 1

		bag_value = value * total_stages
		bag_risk = math.round( bag_value * money_multiplier )
	else
		bag_value = value
	end

	return math.round( ( bag_value + bag_risk ) * bag_skill_bonus / tweak_data:get_value( "money_manager", "offshore_rate" ) )
end

--[[
function MoneyManager:_get_contract_money( is_job, success )
	local has_active_job = managers.job:has_active_job()
	local job_and_difficulty_stars = has_active_job and managers.job:current_job_and_difficulty_stars() or 1
	local job_stars = has_active_job and managers.job:current_job_stars() or 1
	local difficulty_stars = job_and_difficulty_stars - job_stars
	local player_stars = managers.experience:level_to_stars()
	
	-- print( "job_and_difficulty_stars, player_stars", job_and_difficulty_stars, player_stars + 1 ) 
	local total_stars = math.min( job_and_difficulty_stars, player_stars + 1 )
	
	local total_difficulty_stars = math.max( 0, total_stars - job_stars )
	local money_multiplier = self:get_contract_difficulty_multiplier( total_difficulty_stars )
	
	total_stars = math.min( job_stars, total_stars )
	-- print( "total_stars", total_stars )
	
	-- print( "total_difficulty_stars, money_multiplier", total_difficulty_stars, money_multiplier )
	
	local contract_money = 0
	if is_job then
		contract_money = contract_money + self:get_job_payout_by_stars( total_stars )
		-- print( "AWARDED JOB COMPLETED MONEY", contract_money )
	else
		contract_money = contract_money + self:get_stage_payout_by_stars( total_stars )
		-- print( "AWARDED STAGE COMPLETED MONEY", contract_money )
	end
	
	contract_money = contract_money + (contract_money*money_multiplier)
	contract_money = contract_money -- * (not success and tweak_data.experience_manager.stage_failed_multiplier or 1) 
	-- print( "contract_money", contract_money )
	return math.round( contract_money )
end
]]


function MoneyManager:get_job_bag_value()
	local has_active_job = managers.job:has_active_job()
	local job_and_difficulty_stars = has_active_job and managers.job:current_job_and_difficulty_stars() or 1

	return tweak_data:get_value( "money_manager", "bag_value_multiplier", job_and_difficulty_stars )
end

function MoneyManager:get_bag_value( carry_id )
	local carry_data = tweak_data.carry[ carry_id ]
	local bag_value_id = carry_data.bag_value or "default"

	local value = tweak_data:get_value( "money_manager", "bag_values", bag_value_id )
	return math.round( value )
end

-------------------------------------------------------------

function MoneyManager:debug_job_completed( stars )

	local amount = tweak_data:get_value( "money_manager", "job_completion", stars )
	self:_add_to_total( amount )
end

function MoneyManager:get_job_payout_by_stars( stars, cap_stars )
	if cap_stars then
		stars = math.clamp( stars, 1, #tweak_data.money_manager.stage_completion )
	end

	local amount = tweak_data:get_value( "money_manager", "job_completion", stars )
	return amount
end

function MoneyManager:get_stage_payout_by_stars( stars, cap_stars )
	if cap_stars then
		stars = math.clamp( stars, 1, #tweak_data.money_manager.stage_completion )
	end

	local amount = tweak_data:get_value( "money_manager", "stage_completion", stars )
	return amount
end

function MoneyManager:get_small_loot_difficulty_multiplier( stars ) -- stars are 0 - 3

	local multiplier = tweak_data:get_value( "money_manager", "small_loot_difficulty_multiplier", stars )
	
	return multiplier or 0
end

function MoneyManager:get_contract_difficulty_multiplier( stars ) -- stars are 0 - 3
	return tweak_data:get_value( "money_manager", "difficulty_multiplier", stars + 1 ) or 1
end

function MoneyManager:get_potential_payout_from_current_stage()
	local stage_value, job_value, bag_value, small_value, crew_value, total_payout = self:get_real_job_money_values( 1, true )

	return total_payout

	--[[if not managers.job:has_active_job() then
		return 0
	end
	
	local job_and_difficulty_stars = managers.job:current_job_and_difficulty_stars() or 1
	local job_stars = managers.job:current_job_stars() or 1
	local difficulty_stars = job_and_difficulty_stars - job_stars
	local money_multiplier = managers.money:get_contract_difficulty_multiplier( difficulty_stars )
	
	local amount = managers.money:get_stage_payout_by_stars( job_stars )
	if managers.job:on_last_stage() then
		amount = amount + managers.money:get_job_payout_by_stars( job_stars )
	end
	
	amount = amount + amount * money_multiplier
	return amount]]

end

------------------------------------------------------------------

function MoneyManager:can_afford_weapon( weapon_id )
	return self:total() >= self:get_weapon_price_modified( weapon_id )
end

function MoneyManager:get_weapon_price( weapon_id )
	local pc = self:_get_weapon_pc( weapon_id )
	if not tweak_data.money_manager.weapon_cost[ pc ] then
		pc = 1
	end

	return tweak_data:get_value( "money_manager", "weapon_cost", pc )
end

function MoneyManager:get_weapon_price_modified( weapon_id )
	local pc = self:_get_weapon_pc( weapon_id )
	if not tweak_data.money_manager.weapon_cost[ pc ] then
		pc = 1
	end

	return math.round( tweak_data:get_value( "money_manager", "weapon_cost", pc ) * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "crime_net_deal", 1 ) )
end

function MoneyManager:get_weapon_slot_sell_value( category, slot )
	local crafted_item = managers.blackmarket:get_crafted_category_slot( category, slot )
	if not crafted_item then
		return 0
	end
	local weapon_id = crafted_item.weapon_id
	local blueprint = crafted_item.blueprint
	
	local base_value = self:get_weapon_price( weapon_id )
	local parts_value = 0
	
	--[[
	if blueprint then
		local stats
		for _, id in ipairs( blueprint ) do
			stats = tweak_data.weapon.factory.parts[id].stats
			if stats then
				parts_value = parts_value + (tweak_data.weapon.stats.value[math.min( stats.value or 1, #tweak_data.weapon.stats.value )] * base_value)
			end
		end
	end]]
	
	-- print( base_value, parts_value )

	return math.round( (base_value + parts_value) * tweak_data:get_value( "money_manager", "sell_weapon_multiplier" ) * managers.player:upgrade_value( "player", "sell_cost_multiplier", 1 ) )
end

function MoneyManager:get_weapon_sell_value( weapon_id )

	return math.round( self:get_weapon_price( weapon_id ) * tweak_data:get_value( "money_manager", "sell_weapon_multiplier" ) * managers.player:upgrade_value( "player", "sell_cost_multiplier", 1 ) )
end

function MoneyManager:_get_weapon_pc( weapon_id )
	local weapon_data = managers.blackmarket:get_weapon_data( weapon_id ) or {}
	local weapon_level = weapon_data.level
	
	--[[local weapon_level
	for level, level_data in pairs( tweak_data.upgrades.level_tree ) do
		for _, upgrade in ipairs( level_data.upgrades ) do
			if( upgrade == weapon_id ) then
				weapon_level = level
				break
			end
		end
	end]]
	
	if not weapon_level then
		Application:error( "DIDN'T FIND LEVEL FOR", weapon_id )
		weapon_level = 1
	end
	local pc = math.ceil( weapon_level )
	return pc
end

function MoneyManager:on_buy_weapon_platform( weapon_id, discount )
	local amount = self:get_weapon_price_modified( weapon_id )
	-- print( "MoneyManager:on_buy_weapon_platform", amount )

	self:_deduct_from_total( math.round( amount * ( discount and tweak_data:get_value( "money_manager", "sell_weapon_multiplier" ) or 1 ) ) )
end

function MoneyManager:on_sell_weapon( category, slot ) -- weapon_id )
	local amount = self:get_weapon_slot_sell_value( category, slot )
	-- local amount = self:get_weapon_sell_value( weapon_id )
	-- print( "MoneyManager:on_sell_weapon", amount )
	self:_add_to_total( amount, { no_offshore = true } )
end


function MoneyManager:get_weapon_part_sell_value( part_id, global_value )
	local part = tweak_data.weapon.factory.parts[ part_id ]
	local mod_price = 1000
	if part then
		local pc_value = self:_get_pc_entry( part )
		
		if pc_value then
			local star_value = math.ceil( pc_value/10 )

			mod_price = tweak_data:get_value( "money_manager", "modify_weapon_cost", star_value )
		end
		
		local stats_value = part.stats
		stats_value = stats_value and stats_value.value or 1
		mod_price = mod_price * tweak_data.weapon.stats.value[ math.clamp( stats_value, 1, #tweak_data.weapon.stats.value ) ]
	end

	return math.round( mod_price * tweak_data:get_value( "money_manager", "sell_weapon_multiplier" ) * managers.player:upgrade_value( "player", "sell_cost_multiplier", 1 ) )
end

function MoneyManager:on_sell_weapon_part( part_id, global_value )
	local amount = self:get_weapon_part_sell_value( part_id, global_value )
	Application:debug( "value of removed weapon part", amount )
	self:_add_to_total( amount, { no_offshore = true } )
end

function MoneyManager:on_sell_weapon_slot( category, slot )
	local amount = self:get_weapon_slot_sell_value( category, slot )
	self._add_to_total( amount, { no_offshore = true } )
end

------------------------------------------------------------------

function MoneyManager:can_afford_mission_asset( asset_id )
	return self:total() >= self:get_mission_asset_cost_by_id( asset_id )
end

function MoneyManager:on_buy_mission_asset( asset_id )
	local amount = self:get_mission_asset_cost_by_id( asset_id )
	
	
	-- print( "MoneyManager:on_buy_mission_asset", amount )
	self:_deduct_from_total( amount )
	return amount
end

------------------------------------------------------------------

function MoneyManager:can_afford_spend_skillpoint( tree, tier, points )
	return self:total() >= self:get_skillpoint_cost( tree, tier, points )
end
function MoneyManager:can_afford_respec_skilltree( tree )
	return true -- self._global.total >= self:get_skilltree_tree_respec_cost( tree )
end

function MoneyManager:on_skillpoint_spent( tree, tier, points )
	local amount = self:get_skillpoint_cost( tree, tier, points )
	
	self:_deduct_from_total( amount )
end

function MoneyManager:on_respec_skilltree( tree, forced_respec_multiplier )
	local amount = self:get_skilltree_tree_respec_cost( tree, forced_respec_multiplier )
	-- managers.skilltree:increase_times_respeced( 1 )
	-- print( "MoneyManager:on_respec_skilltree", amount )
	-- self:_deduct_from_total( amount )
	self:_add_to_total( amount, { no_offshore = true } )
end

------------------------------------------------------------------

function MoneyManager:refund_weapon_part( weapon_id, part_id, global_value )
	local pc_value = tweak_data.blackmarket.weapon_mods and tweak_data.blackmarket.weapon_mods[ part_id ] and tweak_data.blackmarket.weapon_mods[ part_id ].value or 1 	-- Changed system to used value instead of PC

	local mod_price = tweak_data:get_value( "money_manager", "modify_weapon_cost", pc_value ) -- Changed system to used value instead of PC
	

	local global_value_multiplier = tweak_data:get_value( "money_manager", "global_value_multipliers", global_value or "normal" )
	-- local amount = self:get_weapon_modify_price( weapon_id, part_id, global_value )
	
	self:_add_to_total( math.round(mod_price*global_value_multiplier), { no_offshore = true } )
end

function MoneyManager:get_weapon_modify_price( weapon_id, part_id, global_value )
	local star_value
	
	-- local pc_value = self:_get_pc_entry( tweak_data.weapon.factory.parts[ part_id ] )
	-- local mod_price = tweak_data.money_manager.modify_weapon_cost[ (pc_value and math.ceil( pc_value/10 ) or 1) ]
	
	local pc_value = tweak_data.blackmarket.weapon_mods and tweak_data.blackmarket.weapon_mods[part_id] and tweak_data.blackmarket.weapon_mods[part_id].value or 1 -- Changed system to used value instead of PC

	local mod_price = tweak_data:get_value( "money_manager", "modify_weapon_cost", pc_value ) -- Changed system to used value instead of PC
	

	local global_value_multiplier = tweak_data:get_value( "money_manager", "global_value_multipliers", global_value or "normal" )
	local crafting_multiplier = managers.player:upgrade_value( "player", "passive_crafting_weapon_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "crafting_weapon_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "crime_net_deal", 1 )
	
	
	local total_price = mod_price * crafting_multiplier * global_value_multiplier
	-- print( "weapon_price", weapon_price, "mod_price", mod_price, "total_price", total_price, "crafting_multiplier", crafting_multiplier )
	return math.round( total_price )
end

function MoneyManager:can_afford_weapon_modification( weapon_id, part_id, global_value )
	return self:total() >= self:get_weapon_modify_price( weapon_id, part_id, global_value )
end

function MoneyManager:on_buy_weapon_modification( weapon_id, part_id, global_value )
	local amount = self:get_weapon_modify_price( weapon_id, part_id, global_value )
	-- print( "MoneyManager:on_buy_weapon_modification", amount )
	self:_deduct_from_total( amount )
end

------------------------------------------------------------------

function MoneyManager:_get_pc_entry( entry )
	if not entry then
		Application:error( "MoneyManager:_get_pc_entry. No entry" )
		return 5
	end
	local pcs = entry.pcs
	local pc_value
	if not pcs then
		-- print( "no pcs for", entry )
		local pc = entry.pc
		if not pc then
			-- print( "no pc for entry", inspect( entry ) )
		else
			pc_value = pc
		end
	else
		pc_value = pcs[ 1 ] 
		for _,pcv in ipairs( pcs ) do
			pc_value = math.min( pc_value, pcv )
		end
	end
	return pc_value 
end

------------------------------------------------------------------

function MoneyManager:get_buy_mask_slot_price()
	local multiplier = 1
	multiplier = multiplier * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 )
	multiplier = multiplier * managers.player:upgrade_value( "player", "crime_net_deal", 1 )
	
	return tweak_data:get_value( "money_manager", "unlock_new_mask_slot_value" )
end

function MoneyManager:can_afford_buy_mask_slot()
	return self:total() >= self:get_buy_mask_slot_price()
end

function MoneyManager:on_buy_mask_slot( slot )
	local amount = self:get_buy_mask_slot_price()
	self:_deduct_from_total(amount)
end

------------------------------------------------------------------

function MoneyManager:get_buy_weapon_slot_price()
	local multiplier = 1
	multiplier = multiplier * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 )
	multiplier = multiplier * managers.player:upgrade_value( "player", "crime_net_deal", 1 )
	
	return tweak_data:get_value( "money_manager", "unlock_new_weapon_slot_value" )
end

function MoneyManager:can_afford_buy_weapon_slot()
	return self:total() >= self:get_buy_weapon_slot_price()
end

function MoneyManager:on_buy_weapon_slot( slot )
	local amount = self:get_buy_weapon_slot_price()
	self:_deduct_from_total( amount )
end

------------------------------------------------------------------

function MoneyManager:get_mask_part_price_modified( category, id, global_value )
	local mask_part_price = self:get_mask_part_price( category, id, global_value )
	local crafting_multiplier = managers.player:upgrade_value( "player", "passive_crafting_mask_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "crafting_mask_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "crime_net_deal", 1 )
	
	local total_price = mask_part_price * crafting_multiplier
	return math.round( total_price )
end

function MoneyManager:get_mask_crafting_price_modified( mask_id, global_value, blueprint )
	local mask_price = self:get_mask_crafting_price( mask_id, global_value, blueprint )
	local crafting_multiplier = managers.player:upgrade_value( "player", "passive_crafting_mask_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "crafting_mask_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 )
	crafting_multiplier = crafting_multiplier * managers.player:upgrade_value( "player", "crime_net_deal", 1 )
	
	local total_price = mask_price * crafting_multiplier
	return math.round( total_price )
end

function MoneyManager:get_mask_part_price( category, id, global_value )
	local part_pc = tweak_data.blackmarket[category] and self:_get_pc_entry( tweak_data.blackmarket[category][id] ) or 0
	local star_value = (part_pc == 0 and part_pc) or math.ceil( part_pc / 10 )
	
	local part_name_converter = { textures="pattern", materials="material", colors="color" }
	-- local part_name_converter = { pattern="textures", material="materials", color="colors" }
	

	local gv_multiplier = tweak_data:get_value( "money_manager", "global_value_multipliers", global_value )
	
	local value = tweak_data.blackmarket[ category ] and tweak_data.blackmarket[ category ][ id ] and tweak_data.blackmarket[ category ][ id ].value or 1 -- Changed system to used value instead of PC
	

	local pv = tweak_data:get_value( "money_manager", "masks", part_name_converter[ category ] .. "_value", value ) or 0
	
	return math.round( pv * gv_multiplier )
end

function MoneyManager:get_mask_crafting_price( mask_id, global_value, blueprint )
	local bonus_global_values = { normal=0, superior=0, exceptional=0, infamous=0}
	
	-- local pc_value = self:_get_pc_entry( tweak_data.blackmarket.masks[ mask_id ] )
	local pc_value = tweak_data.blackmarket.masks and tweak_data.blackmarket.masks[ mask_id ] and tweak_data.blackmarket.masks[ mask_id ].value or 1 -- Changed system to used value instead of PC
	
	local base_value
	
	if pc_value > 0 then
		local star_value = pc_value and math.ceil( pc_value ) or 1
		base_value = tweak_data:get_value( "money_manager", "masks", "mask_value", star_value ) * tweak_data:get_value( "money_manager", "global_value_multipliers", global_value )
	else
		
		base_value = 0
	end
	
	local parts_value = 0
	local part_name_converter = { pattern="textures", material="materials", color="colors" }
	
	bonus_global_values[ global_value ] = (bonus_global_values[ global_value ] or 0) + 1
	if not blueprint then
		blueprint = managers.blackmarket:get_default_mask_blueprint()
	end
	for id, data in pairs( blueprint ) do
		local part_pc = tweak_data.blackmarket[part_name_converter[id]] and self:_get_pc_entry( tweak_data.blackmarket[part_name_converter[id]][data.id] ) or 1
		
		-- star_value = (part_pc == 0 and part_pc) or math.ceil( part_pc / 10 )
		local star_value = tweak_data.blackmarket[part_name_converter[id]] and tweak_data.blackmarket[part_name_converter[id]][ data.id ] and tweak_data.blackmarket[part_name_converter[id]][ data.id ].value or 1 -- Changed system to used value instead of PC
		if star_value > 0 then
			
			local gv_multiplier = tweak_data:get_value( "money_manager", "global_value_multipliers", data.global_value )
			bonus_global_values[ data.global_value ] = (bonus_global_values[ data.global_value ] or 0) + 1
			
			
			local pv = tweak_data:get_value( "money_manager", "masks", id .. "_value", star_value ) or 0
			parts_value = parts_value + pv * gv_multiplier
		end
	end
	
	return math.round(base_value + parts_value), bonus_global_values
end

function MoneyManager:get_mask_sell_value( mask_id, global_value, blueprint )
	local sell_value, bonuses = self:get_mask_crafting_price( mask_id, global_value, blueprint )
	
	local bonus_multiplier
	for gv, amount in pairs( bonuses ) do

		bonus_multiplier = tweak_data:get_value( "money_manager", "global_value_bonus_multiplier", gv ) * math.max( amount-1, 0 )
		sell_value = sell_value + ( sell_value * bonus_multiplier )
	end
	

	return math.round( sell_value * tweak_data:get_value( "money_manager", "sell_mask_multiplier" ) * managers.player:upgrade_value( "player", "sell_cost_multiplier", 1 ) )
end

function MoneyManager:get_mask_slot_sell_value( slot )
	local mask = managers.blackmarket:get_crafted_category_slot( "masks", slot )
	if not mask then
		return 0
	end
	return math.round( self:get_mask_sell_value( mask.mask_id, mask.global_value, mask.blueprint ) )
end

function MoneyManager:can_afford_mask_crafting( mask_id, global_value, blueprint )
	return self:total() >= self:get_mask_crafting_price_modified( mask_id, global_value, blueprint )
end

function MoneyManager:on_buy_mask( mask_id, global_value, blueprint )
	local amount = self:get_mask_crafting_price_modified( mask_id, global_value, blueprint )
	self:_deduct_from_total( amount )
end

function MoneyManager:on_sell_mask( mask_id, global_value, blueprint )
	local amount = self:get_mask_sell_value( mask_id, global_value, blueprint )
	self:_add_to_total( amount, { no_offshore = true } )
end

function MoneyManager:on_loot_drop_cash( value_id )

	local amount = tweak_data:get_value( "money_manager", "loot_drop_cash", value_id ) or 100
	self:_add_to_total( amount, { no_offshore = true } )
end


------------------------------------------------------------------
function MoneyManager:get_skillpoint_cost( tree, tier, points )
	local respec_tweak_data = tweak_data.money_manager.skilltree.respec
	
	local exp_cost = 0

	--[[
	local points_spent = managers.skilltree:points_spent( tree )
	local exp_cost = respec_tweak_data.base_point_cost + (points_spent * respec_tweak_data.point_cost) ^ respec_tweak_data.point_multiplier_cost
	]]
	

	local tier_cost = (not tier and 0) or tweak_data:get_value( "money_manager", "skilltree", "respec", "point_tier_cost", tier ) * points
	local cost = tweak_data:get_value( "money_manager", "skilltree", "respec", "base_point_cost" ) + tier_cost
	
	if managers.experience:current_rank() > 0 then
		for infamy, item in pairs( tweak_data.infamy.items ) do
			if managers.infamy:owned( infamy ) and item.upgrades and item.upgrades.skillcost then
				cost = cost * item.upgrades.skillcost.multiplier or 1
			end
		end
	end
	
	return math.round( cost )
end

function MoneyManager:get_skilltree_tree_respec_cost( tree, forced_respec_multiplier )
















	local base_point_cost = tweak_data:get_value( "money_manager", "skilltree", "respec", "base_point_cost" )
	local value = base_point_cost
	for id, tier in ipairs( tweak_data.skilltree.trees[tree].tiers ) do
		for _, skill_id in ipairs( tier ) do
			local step = managers.skilltree:skill_step( skill_id )
			if step > 0 then
				for i=1, step do
					value = value + base_point_cost + managers.skilltree:get_skill_points( skill_id, i ) * tweak_data:get_value( "money_manager", "skilltree", "respec", "point_tier_cost", id )
				end
			end
		end
	end
	return math.round( value * (forced_respec_multiplier or tweak_data:get_value( "money_manager", "skilltree", "respec", "respec_refund_multiplier" ) ) )
	--[[
	local respec_tweak_data = tweak_data.money_manager.skilltree.respec
	local cost = respec_tweak_data.base_cost
	
	local points_spent = managers.skilltree:points_spent( tree )
	local max_tier = managers.skilltree:current_max_tier( tree )
	
	cost = cost + (points_spent * respec_tweak_data.point_cost) ^ respec_tweak_data.point_multiplier_cost
	
	for i=1, max_tier do
		local tier_cost = respec_tweak_data.tier_cost[i] or 0
		
		cost = cost + tier_cost
	end
	
	local times_respeced = managers.skilltree:get_times_respeced()
	return math.round( cost * tweak_data.money_manager.skilltree.respec.profile_cost_increaser_multiplier[times_respeced] )
	]]
end

------------------------------------------------------------------

function MoneyManager:get_mission_asset_cost()
	local stars = managers.job:has_active_job() and managers.job:current_job_and_difficulty_stars() or 1

	return math.round( tweak_data:get_value( "money_manager", "mission_asset_cost", stars ) * managers.player:upgrade_value( "player", "assets_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "assets_cost_multiplier_b", 1 ) * managers.player:upgrade_value( "player", "passive_assets_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "crime_net_deal", 1 ) )
end

function MoneyManager:get_mission_asset_cost_by_stars( stars )

	return math.round( tweak_data:get_value( "money_manager", "mission_asset_cost", stars ) * managers.player:upgrade_value( "player", "assets_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "assets_cost_multiplier_b", 1 ) * managers.player:upgrade_value( "player", "passive_assets_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "crime_net_deal", 1 ) )
end

function MoneyManager:get_mission_asset_cost_by_id( id )
	local asset_tweak_data = managers.assets:get_asset_tweak_data_by_id( id )
	local value = asset_tweak_data and asset_tweak_data.money_lock or 0
	
	local has_active_job = managers.job:has_active_job()
	local job_and_difficulty_stars = has_active_job and managers.job:current_job_and_difficulty_stars() or 1
	local job_stars = has_active_job and managers.job:current_job_stars() or 1
	local difficulty_stars = job_and_difficulty_stars - job_stars
	


	local pc_multiplier = tweak_data:get_value( "money_manager", "mission_asset_cost_multiplier_by_pc", job_stars ) or 0
	local risk_multiplier = difficulty_stars > 0 and tweak_data:get_value( "money_manager", "mission_asset_cost_multiplier_by_risk", difficulty_stars ) or 0
	
	
	value = value + value * pc_multiplier + value * risk_multiplier
	return math.round( value* managers.player:upgrade_value( "player", "assets_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "assets_cost_multiplier_b", 1 ) * managers.player:upgrade_value( "player", "passive_assets_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "crime_net_deal", 1 ) )
end

------------------------------------------------------------------

function MoneyManager:get_cost_of_premium_contract( job_id, difficulty_id )
	local job_data = tweak_data.narrative.jobs[ job_id ]
	if not job_data then
		return 0
	end

	local stars = job_data.jc / 10
	local total_payout, stage_payout_table, job_payout_table = self:get_contract_money_by_stars( stars, difficulty_id - 2, #job_data.chain, job_id )

	local diffs = { "easy", "normal", "hard", "overkill", "overkill_145" }
	local value = total_payout * tweak_data:get_value( "money_manager", "buy_premium_multiplier", diffs[ difficulty_id ] ) + tweak_data:get_value( "money_manager", "buy_premium_static_fee", diffs[ difficulty_id ] )
	value = value + ( tweak_data.narrative.jobs[ job_id ].payout and tweak_data.narrative.jobs[ job_id ].payout[ difficulty_id - 1 ] / tweak_data:get_value( "money_manager", "offshore_rate" ) or 0 )

	local multiplier = 1 * managers.player:upgrade_value( "player", "buy_cost_multiplier", 1 ) * managers.player:upgrade_value( "player", "crime_net_deal", 1 ) * managers.player:upgrade_value( "player", "premium_contract_cost_multiplier", 1 )
	local total_value = math.round( value * multiplier )
	
	total_value = total_value + ( tweak_data.narrative.jobs[ job_id ].contract_cost and tweak_data.narrative.jobs[ job_id ].contract_cost[ difficulty_id - 1 ] / tweak_data:get_value( "money_manager", "offshore_rate" ) or 0 )
	
	return total_value
end

function MoneyManager:can_afford_buy_premium_contract( job_id, difficulty_id )
	local amount = self:get_cost_of_premium_contract( job_id, difficulty_id )


	return amount <= self:offshore()
end

function MoneyManager:on_buy_premium_contract( job_id, difficulty_id )
	local amount = self:get_cost_of_premium_contract( job_id, difficulty_id )
	self:deduct_from_offshore( amount )
end

------------------------------------------------------------------

function MoneyManager:get_cost_of_casino_entrance()
	local current_level = managers.experience:current_level()
	
	local level = 1
	for i = 1, #tweak_data.casino.entrance_level do
		level = i
		
		if current_level < tweak_data:get_value( "casino", "entrance_level", i ) then
			break
		end
	end
	
	return tweak_data:get_value( "casino", "entrance_fee", level )
end

function MoneyManager:get_cost_of_casino_fee( secured_cards, increase_infamous, preferred_card )
	local fee = self:get_cost_of_casino_entrance()
	
	for i = 1, secured_cards do
		fee = fee + tweak_data:get_value( "casino", "secure_card_cost", i )
	end
	
	if increase_infamous then
		fee = fee + tweak_data:get_value( "casino", "infamous_cost" )
	end
	
	if preferred_card and preferred_card ~= "none" then
		fee = fee + tweak_data:get_value( "casino", "prefer_cost" )
	end
	
	return fee
end

function MoneyManager:can_afford_casino_fee( secured_cards, increase_infamous, preferred_card )
	return self:offshore() >= self:get_cost_of_casino_fee( secured_cards, increase_infamous, preferred_card )
end

function MoneyManager:on_buy_casino_fee( secured_cards, increase_infamous, preferred_card )
	local amount = self:get_cost_of_casino_fee( secured_cards, increase_infamous, preferred_card )
	self:deduct_from_offshore( amount )
end

------------------------------------------------------------------

--[[function MoneyManager:calculate_end_score( multipliers )
	local player_alive = managers.player:player_unit() and true or false
	if not player_alive then
		return 0
	end
	
	multipliers = multipliers or {}
	local end_score = self._heist_total
	for _,multiplier in ipairs( multipliers ) do
		if not tweak_data.money_manager.end_multipliers[ multiplier ] then
			Application:error( "Unknown end multiplier \"" .. tostring( multiplier ) .. "\" in money manager." )
		end
		end_score = end_score * tweak_data.money_manager.end_multipliers[ multiplier ]
	end
	
	-- self._global.total = self._global.total + end_score
	self:_add_to_total( end_score )
	return math.round( end_score )
end]]
------------------------------------------------------------------

function MoneyManager:total()
	return Application:digest_value( self._global.total, false )
end

function MoneyManager:_set_total( value )
	self._global.total = Application:digest_value( value, true )
end

function MoneyManager:total_collected()
	return Application:digest_value( self._global.total_collected, false )
end

function MoneyManager:_set_total_collected( value )
	self._global.total_collected = Application:digest_value( value, true )
end

function MoneyManager:offshore()
	return Application:digest_value( self._global.offshore, false )
end

function MoneyManager:_set_offshore( value )
	self._global.offshore = Application:digest_value( value, true )
end

function MoneyManager:total_spent()
	return Application:digest_value( self._global.total_spent, false )
end

function MoneyManager:_set_total_spent( value )
	self._global.total_spent = Application:digest_value( value, true )
end

function MoneyManager:add_to_total( amount )
	amount = math.round( amount )
	print( "MoneyManager:add_to_total", amount )
	self:_add_to_total( amount )
end

function MoneyManager:_add_to_total( amount, params )
	local no_offshore = params and params.no_offshore


	local offshore = math.round( (no_offshore and 0) or amount * (1 - tweak_data:get_value( "money_manager", "offshore_rate" ) ) )
	local spending_cash = math.round( (no_offshore and amount) or amount * tweak_data:get_value( "money_manager", "offshore_rate" ) )
	
	local rounding_error = math.round( amount - (offshore + spending_cash) )
	spending_cash = spending_cash + rounding_error
	
	self:_set_total( self:total() + spending_cash )
	self:_set_total_collected( self:total_collected() + math.round( amount ) )
	self:_set_offshore( self:offshore() + offshore )
	self:_on_total_changed( amount, spending_cash, offshore ) 
end

function MoneyManager:deduct_from_total( amount )
	amount = math.round( amount )
	print( "MoneyManager:deduct_from_total", amount )
	self:_deduct_from_total( amount )
end

function MoneyManager:_deduct_from_total( amount )
	amount = math.min( amount, self:total() )
	self:_set_total( math.max( 0, self:total() - amount ) )
	self:_set_total_spent( self:total_spent() + amount )
	self:_on_total_changed( -amount, -amount, 0 )
end

function MoneyManager:deduct_from_offshore( amount )
	amount = math.round( amount )
	print( "MoneyManager:deduct_from_offshore", amount )
	self:_deduct_from_offshore( amount )
end

function MoneyManager:_deduct_from_offshore( amount )
	amount = math.min( amount, self:offshore() )
	self:_set_offshore( math.max( 0, self:offshore() - amount ) )
	self:_on_total_changed(0, 0, -amount)
end

function MoneyManager:_on_total_changed( amount, spending_cash, offshore )
	-- Application:debug( "MoneyManager:_on_total_changed:", "amount", amount, "total", self._global.total )
	-- self._heist_total = self._heist_total + spending_cash
	
	self._heist_total = self._heist_total + amount
	self._heist_offshore = self._heist_offshore + offshore
	
	if offshore and offshore > 0 then
		self._heist_spending = self._heist_spending + spending_cash
	end
	
	if self:total() >= tweak_data.achievement.going_places then
		managers.achievment:award( "going_places" )
	end
	
	-- if (self._global.total_collected-self._global.total) >= tweak_data.achievement.spend_money_to_make_money then
	if self:total_spent() >= tweak_data.achievement.spend_money_to_make_money then
		managers.achievment:award( "spend_money_to_make_money" )
	end
end

function MoneyManager:heist_total()
	return self._heist_total or 0
end

function MoneyManager:heist_spending()
	return self._heist_spending or 0
end

function MoneyManager:heist_offshore()
	return self._heist_offshore or 0
end

function MoneyManager:get_payouts()
	return self._stage_payout, self._job_payout, self._bag_payout, self._small_loot_payout, self._crew_payout
end

function MoneyManager:_set_stage_payout( amount )
	self._stage_payout = amount
end

function MoneyManager:_set_job_payout( amount )
	self._job_payout = amount
end

function MoneyManager:_set_bag_payout( amount )
	self._bag_payout = amount
end

function MoneyManager:_set_small_loot_payout( amount )
	self._small_loot_payout = amount
end

function MoneyManager:_set_crew_payout( amount )
	self._crew_payout = amount
end

function MoneyManager:_add( amount )
	amount = self:_check_multipliers( amount )
	self._heist_total = self._heist_total + amount
	self:_present( amount )
	-- managers.experience:add_points( amount )
end

function MoneyManager:_check_multipliers( amount )
	for _,multiplier in pairs( self._active_multipliers ) do
		amount = amount * multiplier
	end
	return math.round( amount )
end

function MoneyManager:_present( amount )
	-- print( "Recieved money:", amount, "Total now:", self._heist_total )
	
	local s_amount = tostring( amount )
	local reverse = string.reverse( s_amount )
	local present = ""
	for i = 1, string.len( reverse ) do
		present = present..string.sub( reverse, i, i )..((math.mod( i, 3 ) == 0 and (i ~= string.len( reverse )) and ",") or "")
	end
	
	-- Specify this in tweak data later
	local event = "money_collect_small"
	if amount > 999 then
		event = "money_collect_large"
	elseif amount > 101 then
		event = "money_collect_medium"
	end
	
	-- managers.hud:present_text( "$"..string.reverse( present ), 0.75 )
	
	--managers.hud:present_text( { text = "$"..string.reverse( present ), time = 0.75, event = event } )
end

-- Returns a sorted ipairs with all actions
function MoneyManager:actions()
	local t = {}
	for action,_ in pairs( tweak_data.money_manager.actions ) do
		table.insert( t, action )
	end
	table.sort ( t )
	return t
end

-- Returns a sorted ipairs with all multipliers
function MoneyManager:multipliers()
	local t = {}
	for multiplier,_ in pairs( tweak_data.money_manager.multipliers ) do
		table.insert( t, multiplier )
	end
	table.sort ( t )
	return t
end

function MoneyManager:reset()
	Global.money_manager = nil
	self:_setup()
end

function MoneyManager:save( data )
	local state = {	
				total = self._global.total,
				total_collected = self._global.total_collected,
				offshore = self._global.offshore,
				total_spent = self._global.total_spent,
				-- active_multipliers = self._active_multipliers
	}
	data.MoneyManager = state
end

function MoneyManager:load( data )
	local state = data.MoneyManager
	self._global.total = state.total
	self._global.total_collected = state.total_collected or Application:digest_value( 0, true )
	self._global.offshore = state.offshore or Application:digest_value( 0, true )
	self._global.total_spent = state.total_spent or Application:digest_value( 0, true )
	
	--[[for multiplier,_ in pairs( state.active_multipliers ) do
		self:use_multiplier( multiplier )
	end]]
end