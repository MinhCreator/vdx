return {
	"folke/flash.nvim",
	config = function()
		require("flash").setup({
			labels = "asdfghjklqwertyuiopzxcvbnm",
			search = {
				mode = function(str)
					return "\\<" .. str
				end,
			},
		})
	end,
}
