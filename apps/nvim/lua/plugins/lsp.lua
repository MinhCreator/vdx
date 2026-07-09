return {
	"neovim/nvim-lspconfig",
	config = function()
		vim.lsp.config("*", {
			capabilities = vim.lsp.protocol.make_client_capabilities(),
		})
		vim.diagnostic.config({
			float = { border = "single" },
		})
	end,
}
