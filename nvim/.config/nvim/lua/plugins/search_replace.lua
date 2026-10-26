-- Search and replace in the whole project with a live preview, like "Replace in Path" in IntelliJ
return {
	"MagicDuck/grug-far.nvim",
	cmd = "GrugFar",
	opts = {},
	keys = {
		{
			"<leader>sp",
			function()
				require("grug-far").open()
			end,
			desc = "[S]earch and replace in [P]roject",
		},
		{
			"<leader>sp",
			function()
				require("grug-far").with_visual_selection()
			end,
			mode = "x",
			desc = "[S]earch and replace selection in [P]roject",
		},
	},
}
