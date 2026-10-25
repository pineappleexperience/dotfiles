-- Attaches the Java debugger once the JVM of the task listens on its debug port.
---@type overseer.ComponentFileDefinition
return {
	desc = "Attach the Java debugger when the debug port opens",
	params = {
		port = { type = "integer", desc = "JDWP port" },
	},
	serializable = false,
	constructor = function(params)
		return {
			on_start = function()
				require("config.java.run").attach_when_ready(params.port)
			end,
		}
	end,
}
