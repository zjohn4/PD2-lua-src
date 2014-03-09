require "core/lib/managers/cutscene/keys/CoreCutsceneKeyBase"

CoreSetupCutsceneKeyBase = CoreSetupCutsceneKeyBase or class(CoreCutsceneKeyBase)

function CoreSetupCutsceneKeyBase:populate_from_editor(cutscene_editor)
	-- Overridden to force to frame 0.
end

function CoreSetupCutsceneKeyBase:frame()
	-- Overridden to force to frame 0.
	return 0
end

function CoreSetupCutsceneKeyBase:set_frame(frame)
	-- Overridden to force to frame 0.
end

function CoreSetupCutsceneKeyBase:on_gui_representation_changed(sender, sequencer_clip)
	-- Overridden to force to frame 0.
end

function CoreSetupCutsceneKeyBase:prime(player)
	error("Cutscene keys deriving from CoreSetupCutsceneKeyBase must define the \"prime\" method.")
end

function CoreSetupCutsceneKeyBase:play(player, undo, fast_forward)
	-- Overridden to do nothing - everything happens in prime().
end