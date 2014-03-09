core:module("CoreSmoketestEditorSuite")

core:import("CoreClass")
core:import("CoreSmoketestCommonSuite")

EditorSuite = EditorSuite or class(CoreSmoketestCommonSuite.CommonSuite)

function EditorSuite:init()
	EditorSuite.super.init(self)
	
	self:add_step(
		"load_editor",
		CoreSmoketestCommonSuite.WaitEventSubstep,
		CoreSmoketestCommonSuite.WaitEventSubstep.step_arguments(Idstring("game_state_editor"))
		)
	
	self:add_step(
		"load_level",
		CoreSmoketestCommonSuite.CallAndDoneSubstep,
		CoreSmoketestCommonSuite.CallAndDoneSubstep.step_arguments(callback(self, self, "load_level"))
		)
--[[	
	self:add_step(
		"run_mission_simulation",
		CoreSmoketestCommonSuite.CallAndWaitEventSubstep,
		CoreSmoketestCommonSuite.CallAndWaitEventSubstep.step_arguments(callback(self, self, "run_mission_simulation"), Idstring("game_state_ingame"))
		)
	
	self:add_step(
		"stop_mission_simulation",
		CoreSmoketestCommonSuite.CallAndWaitEventSubstep,
		CoreSmoketestCommonSuite.CallAndWaitEventSubstep.step_arguments(callback(self, self, "run_mission_simulation"), Idstring("game_state_editor"))
		)
]]
--[[	
	self:add_step(
		"environment_editor",
		CoreSmoketestCommonSuite.CallAndDoneSubstep,
		CoreSmoketestCommonSuite.CallAndDoneSubstep.step_arguments(callback(self, self, "environment_editor"))
		)
]]
end

function EditorSuite:load_level()
	managers.editor:load_level(self:get_argument("editor_dir"), self:get_argument("editor_level"))
end

function EditorSuite:run_mission_simulation()
	managers.editor:run_simulation_callback(true) -- simulation with mission script
end

function EditorSuite:stop_mission_simulation()
	managers.editor:run_simulation_callback(true) -- simulation with mission script
end

function EditorSuite:environment_editor()
	managers.toolhub:open("Environment Editor")
	managers.toolhub:close("Environment Editor")
end
