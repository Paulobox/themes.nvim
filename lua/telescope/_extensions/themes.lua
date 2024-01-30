local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function switcher()
	local original_theme = vim.g.colors_name or "default"

	local function set_theme(prompt_bufnr)
		local selected = action_state.get_selected_entry(prompt_bufnr)
		if selected then
			local cmd = "colorscheme " .. selected.value
			vim.cmd(cmd)
		end
	end

	local function write_config(prompt_bufnr)
		local selected = action_state.get_selected_entry(prompt_bufnr)
		local theme_path = vim.fn.stdpath("config") .. "/lua/current-theme.lua"
		local file = io.open(theme_path, "w")
		if file then
			file:write('vim.cmd("colorscheme ' .. selected.value .. '")\n')
			file:close()
		else
			print("Error: Unable to open " .. theme_path .. " for writing.")
		end
	end

	local colors = vim.fn.getcompletion("", "color")

	-- Layout configuration
	local layout_config = {
		prompt_position = "top",
		mirror = true,
		height = 0.7,
		width = 0.25,
		-- You can add more layout options here if needed
	}

	local picker_opts = {
		prompt_title = "Themes",
		finder = finders.new_table({ results = colors }),
		sorter = sorters.get_generic_fuzzy_sorter(),
		sorting_strategy = "ascending",
		layout_strategy = "vertical", -- Added layout strategy
		layout_config = layout_config, -- Added layout configuration

		attach_mappings = function(prompt_bufnr, map)
			map("i", "<CR>", function()
				set_theme(prompt_bufnr)
				write_config(prompt_bufnr)
				actions.close(prompt_bufnr)
			end)

			-- reload theme on cycling
			map("i", "<Down>", function()
				actions.move_selection_next(prompt_bufnr)
				set_theme(prompt_bufnr)
			end)

			map("i", "<Up>", function()
				actions.move_selection_previous(prompt_bufnr)
				set_theme(prompt_bufnr)
			end)

			map("i", "<C-n>", function()
				actions.move_selection_next(prompt_bufnr)
				set_theme(prompt_bufnr)
			end)

			map("i", "<C-p>", function()
				actions.move_selection_previous(prompt_bufnr)
				set_theme(prompt_bufnr)
			end)

			-- Restore the original theme when Esc is pressed
			map("i", "<Esc>", function()
				vim.cmd("colorscheme " .. original_theme)
				actions.close(prompt_bufnr)
			end)

			return true
		end,
	}

	local picker = pickers.new(nil, picker_opts)
	picker:find()
end

-- Function to save the current colorscheme to a file
local function save_current_theme()
	local theme_path = vim.fn.stdpath("config") .. "/lua/current-theme.lua"
	local current_colorscheme = vim.g.colors_name
	if current_colorscheme then
		local content = string.format('vim.cmd("colorscheme %s")\n', current_colorscheme)
		local file, err = io.open(theme_path, "w")
		if not file then
			if vim.v.vim_did_enter == 1 then
				print("Error: Unable to save colorscheme to " .. theme_path .. ". " .. err)
			end
			return
		end
		file:write(content)
		file:close()
		-- if vim.v.vim_did_enter == 1 then
		-- 	-- print("Colorscheme saved to " .. theme_path)
		-- end
	end
end

-- Autocommand to save the colorscheme when it changes
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = save_current_theme,
})

-- Register the Telescope extension with the switcher function
return require("telescope").register_extension({
	exports = { themes = switcher },
})
