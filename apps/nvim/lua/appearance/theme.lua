return {
	"sainnhe/gruvbox-material",
	priority = 1000,
	config = function()
		-- Colors configuration
		vim.g.gruvbox_material_better_performance = 1
		vim.g.gruvbox_material_background = "medium"
		vim.g.gruvbox_material_foreground = "material"
		vim.g.gruvbox_material_transparent_background = 1
		-- Font configuration
		vim.g.gruvbox_material_enable_bold = 1
		vim.g.gruvbox_material_enable_italic = 1
		vim.cmd.colorscheme("gruvbox-material")

		local function apply_highlights()
			local function hi(group, opts)
				vim.api.nvim_set_hl(0, group, opts)
			end

			hi("NormalFloat", { bg = "NONE" })
			hi("FloatBorder", { bg = "NONE", fg = "#a89984" })
			hi("Pmenu", { bg = "NONE" })
			hi("PmenuSel", { bg = "#3c3836" })
			hi("PmenuBorder", { bg = "NONE", fg = "#a89984" })

			hi("BlinkCmpMenu", { bg = "NONE" })
			hi("BlinkCmpMenuBorder", { bg = "NONE", fg = "#a89984" })
			hi("BlinkCmpMenuSelection", { bg = "#3c3836" })
			hi("BlinkCmpDoc", { bg = "NONE" })
			hi("BlinkCmpDocBorder", { bg = "NONE", fg = "#a89984" })
			hi("BlinkCmpDocSeparator", { bg = "NONE", fg = "#a89984" })
			hi("BlinkCmpGhostText", { bg = "NONE", fg = "#928374" })
			hi("BlinkCmpLabelMatch", { bg = "NONE" })
			hi("BlinkCmpSignatureHelp", { bg = "NONE" })
			hi("BlinkCmpSignatureHelpBorder", { bg = "NONE", fg = "#a89984" })

			hi("MasonNormal", { bg = "NONE" })
			hi("MasonHeader", { bg = "NONE", fg = "#d5c4a1" })
			hi("MasonFooter", { bg = "NONE", fg = "#a89984" })

			hi("LspInfoBorder", { bg = "NONE", fg = "#a89984" })

			hi("DiagnosticFloatingError", { bg = "NONE", fg = "#ea6962" })
			hi("DiagnosticFloatingWarn", { bg = "NONE", fg = "#d8a657" })
			hi("DiagnosticFloatingInfo", { bg = "NONE", fg = "#7daea3" })
			hi("DiagnosticFloatingHint", { bg = "NONE", fg = "#a9b665" })

			hi("DiagnosticVirtualTextError", { bg = "NONE", fg = "#ea6962" })
			hi("DiagnosticVirtualTextWarn", { bg = "NONE", fg = "#d8a657" })
			hi("DiagnosticVirtualTextInfo", { bg = "NONE", fg = "#7daea3" })
			hi("DiagnosticVirtualTextHint", { bg = "NONE", fg = "#a9b665" })

			hi("DiagnosticSignError", { bg = "NONE", fg = "#ea6962" })
			hi("DiagnosticSignWarn", { bg = "NONE", fg = "#d8a657" })
			hi("DiagnosticSignInfo", { bg = "NONE", fg = "#7daea3" })
			hi("DiagnosticSignHint", { bg = "NONE", fg = "#a9b665" })

			hi("DiagnosticUnderlineError", { undercurl = true, sp = "#ea6962" })
			hi("DiagnosticUnderlineWarn", { undercurl = true, sp = "#d8a657" })
			hi("DiagnosticUnderlineInfo", { undercurl = true, sp = "#7daea3" })
			hi("DiagnosticUnderlineHint", { undercurl = true, sp = "#a9b665" })

			hi("NoiceCmdlinePopup", { bg = "NONE" })
			hi("NoiceCmdlinePopupBorder", { bg = "NONE", fg = "#a89984" })
			hi("NoiceCmdlinePopupBorderSearch", { bg = "NONE", fg = "#a89984" })
			hi("NoiceConfirm", { bg = "NONE" })
			hi("NoiceConfirmBorder", { bg = "NONE", fg = "#a89984" })
		end

		apply_highlights()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_highlights })
	end
}
