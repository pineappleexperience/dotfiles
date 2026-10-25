vim.keymap.set("n", "gd", require("config.java.faces").goto_definition, {
	buffer = true,
	desc = "Go to bean of EL expression",
})
