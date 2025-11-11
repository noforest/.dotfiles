-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

local function should_show_image()
    local ui = vim.api.nvim_list_uis()[1]          -- Récupère les dimensions du terminal
    return ui and ui.width > 50 and ui.height > 40 -- Ajuste ces valeurs selon tes besoins
end



local picker_state = {
    history = {},
}

local function navigate_to_parent_smooth(picker)
    local current_cwd = picker.opts.cwd or vim.loop.cwd()
    local parent_dir = vim.fs.dirname(current_cwd)

    if parent_dir and parent_dir ~= current_cwd then
        -- Enregistre le répertoire actuel dans l’historique
        table.insert(picker_state.history, current_cwd)

        -- Mise à jour du répertoire
        vim.cmd("cd " .. vim.fn.fnameescape(parent_dir))
        picker:close()

        vim.defer_fn(function()
            require("snacks").picker.files({
                cwd = parent_dir,
                prompt_title = vim.fs.basename(parent_dir),
            })
        end, 50)
    end
end

local function navigate_back_smooth(picker)
    local previous = table.remove(picker_state.history)
    if previous and vim.fn.isdirectory(previous) == 1 then
        vim.cmd("cd " .. vim.fn.fnameescape(previous))
        picker:close()

        vim.defer_fn(function()
            require("snacks").picker.files({
                cwd = previous,
                prompt_title = vim.fs.basename(previous),
            })
        end, 50)
    else
        vim.notify("📁 No previous directory in history", vim.log.levels.INFO)
    end
end


require("lazy").setup({
    { "catppuccin/nvim",               name = "catppuccin", priority = 1000 },
    { "rafi/awesome-vim-colorschemes", priority = 1000 },
    -- { "joshdick/onedark.vim", name = "onedark", priority = 1000 },

    -- {
    --   'nvim-telescope/telescope.nvim',
    --   -- tag = '0.1.8',
    --   dependencies = { 'nvim-lua/plenary.nvim' },
    --   config = function()
    --     local telescope = require("telescope")
    --     local actions = require("telescope.actions")
    --     local action_state = require('telescope.actions.state')
    --     local bufferline = require('bufferline')
    --     local sorters = require('telescope.sorters')
    --     local devicons = require("nvim-web-devicons")
    --     local entry_display = require("telescope.pickers.entry_display")
    --
    --
    --     telescope.setup({
    --       file_ignore_patterns = { "%.git/." },
    --       defaults = {
    --         mappings = {
    --           -- i = {
    --           --   ["<Tab>"] = actions.select_default,
    --           -- },
    --           -- n = {
    --           --   ["<Tab>"] = actions.select_default,
    --           -- }
    --         },
    --         path_display = {
    --           "filename_first",
    --
    --         },
    --         -- previewer = true,
    --         file_ignore_patterns = { "node_modules", "package-lock.json" },
    --         initial_mode = "insert",
    --         select_strategy = "reset",
    --         sorting_strategy = "ascending",
    --         color_devicons = true,
    --         set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
    --         layout_config = {
    --           prompt_position = "top",
    --           preview_cutoff = 120,
    --         },
    --         vimgrep_arguments = {
    --           "rg",
    --           "--color=never",
    --           "--no-heading",
    --           "--with-filename",
    --           "--line-number",
    --           "--column",
    --           "--smart-case",
    --           "--hidden",
    --           "--glob=!.git/",
    --         },
    --
    --       },
    --       pickers = {
    --         find_files = {
    --           -- previewer = false,
    --           -- path_display = formattedName,
    --           sort_mru = true,
    --           layout_config = {
    --             -- height = 0.4,
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --
    --           },
    --
    --           -- mappings = {
    --           --     i = {
    --           --         ["<C-up>"] = function(prompt_bufnr)
    --           --             local current_picker =
    --           --             require("telescope.actions.state").get_current_picker(prompt_bufnr)
    --           --             -- cwd is only set if passed as telescope option
    --           --             local cwd = current_picker.cwd and tostring(current_picker.cwd)
    --           --             or vim.loop.cwd()
    --           --             local parent_dir = vim.fs.dirname(cwd)
    --           --
    --           --             require("telescope.actions").close(prompt_bufnr)
    --           --             require("telescope.builtin").find_files {
    --           --                 prompt_title = vim.fs.basename(parent_dir),
    --           --                 cwd = parent_dir,
    --           --             }
    --           --         end,
    --           --     },
    --           -- },
    --         },
    --         git_files = {
    --           -- previewer = false,
    --           -- path_display = formattedName,
    --           layout_config = {
    --             -- height = 0.4,
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --           },
    --         },
    --
    --         buffers = {
    --           mappings = {
    --             n = {
    --               ["<Del>"] = actions.delete_buffer,
    --               ["<BS>"] = actions.delete_buffer,
    --             },
    --           },
    --           previewer = false,
    --           initial_mode = "normal",
    --           -- theme = "dropdown",
    --           layout_config = {
    --             height = 0.4,
    --             width = 0.6,
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --           },
    --           sort_mru = true;
    --           ignore_current_buffer = true, -- Ignorer le buffer actif
    --         },
    --         current_buffer_fuzzy_find = {
    --           previewer = true,
    --           layout_config = {
    --             prompt_position = "top",
    --             preview_cutoff = 120,
    --           },
    --         },
    --
    --         -- *************** VERSION AVC CHEMIN MAIS quand meme fichiers ************************
    --         live_grep = (function()
    --             local filename_registry = {}
    --
    --             return {
    --                 attach_mappings = function(_, map)
    --                     filename_registry = {}
    --                     vim.schedule(function()
    --                         -- Création des highlights si non existants
    --                         vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --                         vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --                     end)
    --                     return true
    --                 end,
    --
    --                 entry_maker = function(line)
    --                     local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
    --                     if not filename then return end
    --
    --                     local full_path = vim.fn.fnamemodify(filename, ":p")
    --                     local basename = vim.fn.fnamemodify(full_path, ":t")
    --                     local dir_path = vim.fn.fnamemodify(full_path, ":h")
    --                     local relative_dir = vim.fn.fnamemodify(dir_path, ":~:.") .. "/"
    --
    --                     -- Gestion des doublons
    --                     if not filename_registry[basename] then
    --                         filename_registry[basename] = {
    --                             dirs = { [dir_path] = true },
    --                             count = 1
    --                         }
    --                     else
    --                         if not filename_registry[basename].dirs[dir_path] then
    --                             filename_registry[basename].count = filename_registry[basename].count + 1
    --                             filename_registry[basename].dirs[dir_path] = true
    --                         end
    --                     end
    --
    --                     local show_path = filename_registry[basename].count > 1
    --                     local icon, icon_hl = require("nvim-web-devicons").get_icon(basename, nil, { default = true })
    --                     icon = icon or ""
    --                     icon_hl = icon_hl or "DevIconDefault" -- Fallback si nil
    --
    --                     local icon_width = vim.fn.strwidth(icon)
    --                     local dir_width = vim.fn.strwidth(relative_dir)
    --
    --                     return {
    --                         value = line,
    --                         ordinal = basename .. " " .. text,
    --                         display = function()
    --                             local display_text = icon .. " "
    --                             local highlights = {}
    --
    --                             -- Highlight pour l'icône
    --                             table.insert(highlights, {
    --                                 { 0, icon_width + 1 },
    --                                 icon_hl
    --                             })
    --
    --                             if show_path then
    --                                 display_text = display_text .. relative_dir
    --                                 -- Highlight pour le chemin
    --                                 table.insert(highlights, {
    --                                     { icon_width + 2, icon_width + 2 + dir_width },
    --                                     "TelescopePathSeparator"
    --                                 })
    --                             end
    --
    --                             display_text = display_text .. basename
    --
    --                             return display_text, highlights
    --                         end,
    --                         filename = filename,
    --                         lnum = tonumber(lnum),
    --                         col = tonumber(col)
    --                     }
    --                 end
    --             }
    --         end)(),
    --
    --
    --         grep_string = (function()
    --             local filename_registry = {}
    --
    --             return {
    --                 attach_mappings = function(_, map)
    --                     filename_registry = {}
    --                     vim.schedule(function()
    --                         -- Création des highlights si non existants
    --                         vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --                         -- vim.api.nvim_set_hl(0, "DevIconDefault", { fg = "#FFFFFF" })
    --                         vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --                     end)
    --                     return true
    --                 end,
    --
    --                 entry_maker = function(line)
    --                     local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
    --                     if not filename then return end
    --
    --                     local full_path = vim.fn.fnamemodify(filename, ":p")
    --                     local basename = vim.fn.fnamemodify(full_path, ":t")
    --                     local dir_path = vim.fn.fnamemodify(full_path, ":h")
    --                     local relative_dir = vim.fn.fnamemodify(dir_path, ":~:.") .. "/"
    --
    --                     -- Gestion des doublons
    --                     if not filename_registry[basename] then
    --                         filename_registry[basename] = {
    --                             dirs = { [dir_path] = true },
    --                             count = 1
    --                         }
    --                     else
    --                         if not filename_registry[basename].dirs[dir_path] then
    --                             filename_registry[basename].count = filename_registry[basename].count + 1
    --                             filename_registry[basename].dirs[dir_path] = true
    --                         end
    --                     end
    --
    --                     local show_path = filename_registry[basename].count > 1
    --                     local icon, icon_hl = require("nvim-web-devicons").get_icon(basename, nil, { default = true })
    --                     icon = icon or ""
    --                     icon_hl = icon_hl or "DevIconDefault" -- Fallback si nil
    --
    --                     local icon_width = vim.fn.strwidth(icon)
    --                     local dir_width = vim.fn.strwidth(relative_dir)
    --
    --                     return {
    --                         value = line,
    --                         ordinal = basename .. " " .. text,
    --                         display = function()
    --                             local display_text = icon .. " "
    --                             local highlights = {}
    --
    --                             -- Highlight pour l'icône
    --                             table.insert(highlights, {
    --                                 { 0, icon_width + 1 },
    --                                 icon_hl
    --                             })
    --
    --                             if show_path then
    --                                 display_text = display_text .. relative_dir
    --                                 -- Highlight pour le chemin
    --                                 table.insert(highlights, {
    --                                     { icon_width + 2, icon_width + 2 + dir_width },
    --                                     "TelescopePathSeparator"
    --                                 })
    --                             end
    --
    --                             display_text = display_text .. basename
    --
    --                             return display_text, highlights
    --                         end,
    --                         filename = filename,
    --                         lnum = tonumber(lnum),
    --                         col = tonumber(col)
    --                     }
    --                 end
    --             }
    --         end)(),
    --
    --
    --         -- *********** SANS CHEMIN GRIS *********************
    --         -- grep_string = {
    --         --     -- Désactiver le surlignage
    --         --     attach_mappings = function(_, map)
    --         --         vim.schedule(function()
    --         --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --         --         end)
    --         --         return true
    --         --     end,
    --         --     only_sort_text = true,
    --         --     previewer = true,
    --         --     entry_maker = function(line)
    --         --         -- line au format : "filepath:line:col:text"
    --         --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
    --         --         local basename = filename and vim.fn.fnamemodify(filename, ":t") or line
    --         --
    --         --         local icon, icon_hl = devicons.get_icon(basename, nil, { default = true })
    --         --
    --         --         local displayer = entry_display.create({
    --         --             separator = " ",
    --         --             items = {
    --         --                 { width = 2 }, -- icône
    --         --                 { remaining = true }, -- filename
    --         --             },
    --         --         })
    --         --
    --         --         return {
    --         --             value = line,
    --         --             ordinal = basename,
    --         --             display = function(entry)
    --         --                 return displayer({
    --         --                     { icon, icon_hl },
    --         --                     basename,
    --         --                 })
    --         --             end,
    --         --             filename = filename,
    --         --             lnum = lnum and tonumber(lnum) or nil,
    --         --             col = col and tonumber(col) or nil,
    --         --             __line = line,
    --         --         }
    --         --     end,
    --         --
    --         -- },
    --
    --         -- **************** VERSION AVEC CHEMIN RELATIF EN GRIS ********************
    --         -- live_grep = {
    --         --     -- désactiver le surlignage
    --         --     attach_mappings = function(_, map)
    --         --         vim.schedule(function()
    --         --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --         --             -- Définit la couleur grise pour le chemin
    --         --             vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --         --         end)
    --         --         return true
    --         --     end,
    --         --     only_sort_text = true,
    --         --     previewer = true,
    --         --     entry_maker = function(line)
    --         --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
    --         --         local directory, filename_part = "", line
    --         --
    --         --         if filename then
    --         --             local relative_path = vim.fn.fnamemodify(filename, ":~:.") -- Chemin relatif
    --         --             directory, filename_part = relative_path:match("(.*/)([^/]+)$")
    --         --             if not directory then
    --         --                 directory = ""
    --         --                 filename_part = relative_path
    --         --             end
    --         --         end
    --         --
    --         --         local icon, icon_hl = devicons.get_icon(filename_part, nil, { default = true })
    --         --         icon = icon or ""
    --         --
    --         --         return {
    --         --             value = line,
    --         --             ordinal = filename_part,
    --         --             display = function(entry)
    --         --                 local icon_padding = icon .. " "
    --         --                 local display_line = icon_padding .. directory .. filename_part
    --         --
    --         --                 local highlights = {
    --         --                     { { 0, #icon_padding }, icon_hl }, -- Couleur de l'icône
    --         --                 }
    --         --
    --         --                 if #directory > 0 then
    --         --                     table.insert(highlights, {
    --         --                         { #icon_padding, #icon_padding + #directory },
    --         --                         "TelescopePathSeparator" -- Couleur grise pour le chemin
    --         --                     })
    --         --                 end
    --         --
    --         --                 return display_line, highlights
    --         --             end,
    --         --             filename = filename,
    --         --             lnum = lnum and tonumber(lnum) or nil,
    --         --             col = col and tonumber(col) or nil,
    --         --             __line = line,
    --         --         }
    --         --     end,
    --         -- },
    --         --
    --         -- grep_string = {
    --         --
    --         --     -- désactiver le surlignage
    --         --     attach_mappings = function(_, map)
    --         --         vim.schedule(function()
    --         --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
    --         --             -- Définit la couleur grise pour le chemin
    --         --             vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
    --         --         end)
    --         --         return true
    --         --     end,
    --         --     only_sort_text = true,
    --         --     previewer = true,
    --         --     entry_maker = function(line)
    --         --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
    --         --         local directory, filename_part = "", line
    --         --
    --         --         if filename then
    --         --             local relative_path = vim.fn.fnamemodify(filename, ":~:.") -- Chemin relatif
    --         --             directory, filename_part = relative_path:match("(.*/)([^/]+)$")
    --         --             if not directory then
    --         --                 directory = ""
    --         --                 filename_part = relative_path
    --         --             end
    --         --         end
    --         --
    --         --         local icon, icon_hl = devicons.get_icon(filename_part, nil, { default = true })
    --         --         icon = icon or ""
    --         --
    --         --         return {
    --         --             value = line,
    --         --             ordinal = filename_part,
    --         --             display = function(entry)
    --         --                 local icon_padding = icon .. " "
    --         --                 local display_line = icon_padding .. directory .. filename_part
    --         --
    --         --                 local highlights = {
    --         --                     { { 0, #icon_padding }, icon_hl }, -- Couleur de l'icône
    --         --                 }
    --         --
    --         --                 if #directory > 0 then
    --         --                     table.insert(highlights, {
    --         --                         { #icon_padding, #icon_padding + #directory },
    --         --                         "TelescopePathSeparator" -- Couleur grise pour le chemin
    --         --                     })
    --         --                 end
    --         --
    --         --                 return display_line, highlights
    --         --             end,
    --         --             filename = filename,
    --         --             lnum = lnum and tonumber(lnum) or nil,
    --         --             col = col and tonumber(col) or nil,
    --         --             __line = line,
    --         --         }
    --         --     end,
    --         --
    --         -- },
    --         lsp_references = {
    --           show_line = false,
    --           previewer = true,
    --         },
    --         treesitter = {
    --           show_line = false,
    --           previewer = true,
    --         },
    --         colorscheme = {
    --           enable_preview = true,
    --         },
    --       },
    --       extensions = {
    --         fzf = {
    --           fuzzy = true,                   -- false will only do exact matching
    --           override_generic_sorter = true, -- override the generic sorter
    --           override_file_sorter = true,    -- override the file sorter
    --           case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
    --         },
    --         ["ui-select"] = {
    --           require("telescope.themes").get_dropdown({
    --             previewer = false,
    --             initial_mode = "normal",
    --             sorting_strategy = "ascending",
    --             layout_strategy = "horizontal",
    --             layout_config = {
    --               horizontal = {
    --                 width = 0.5,
    --                 height = 0.4,
    --                 preview_width = 0.6,
    --               },
    --             },
    --           }),
    --         },
    --       },
    --     })
    --
    -- end
    -- },

    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local telescope = require("telescope")
            local actions = require("telescope.actions")
            local action_state = require("telescope.actions.state")
            local builtin = require("telescope.builtin")
            local pickers = require("telescope.pickers")
            local finders = require("telescope.finders")
            local sorters = require("telescope.sorters")
            local from_entry = require("telescope.from_entry")

            -- Table pour stocker l'état des dossiers cachés par path
            local cd_state = {}

            -- Fonction principale Cd avec closure pour capturer l'état
            local function createCdFunction(initial_path, initial_show_hidden)
                return function()
                    local path = initial_path or "."
                    local show_hidden = initial_show_hidden or false

                    -- Stocker l'état pour ce path spécifique
                    cd_state[path] = show_hidden

                    local cmd = { "fd", ".", path, "-t", "d", "--ignore-file", vim.fn.expand(
                        "$HOME/.config/ignore/vim-ignore") }
                    if show_hidden then
                        table.insert(cmd, "-H")
                    end

                    local results = require("telescope.utils").get_os_command_output(cmd)

                    pickers.new({}, {
                        prompt_title = "Cd" .. (show_hidden and " (Hidden)" or ""),
                        finder = finders.new_table({
                            results = results,
                        }),
                        previewer = false,
                        sorter = sorters.get_fuzzy_file(),
                        attach_mappings = function(prompt_bufnr, map)
                            -- sélectionner dossier et changer cwd
                            actions.select_default:replace(function()
                                local entry = action_state.get_selected_entry()
                                actions.close(prompt_bufnr)
                                local dir = from_entry.path(entry)
                                vim.api.nvim_set_current_dir(dir)

                                vim.notify("Current directory: " .. dir,
                                vim.log.levels.INFO,
                                { title = "Directory changed" })
                            end)

                            -- Ctrl+h pour toggle les hidden files
                            local toggleHidden = function()
                                actions.close(prompt_bufnr)
                                createCdFunction(path, not show_hidden)()
                            end

                            map("i", "<C-h>", toggleHidden)
                            map("n", "<C-h>", toggleHidden)

                            return true
                        end,
                    }):find()
                end
            end

            telescope.setup({
                defaults = {
                    file_ignore_patterns = { "%.git/", "node_modules", "package%-lock.json" },
                    path_display = { "filename_first" },
                    initial_mode = "insert",
                    select_strategy = "reset",
                    sorting_strategy = "ascending",
                    color_devicons = true,
                    set_env = { ["COLORTERM"] = "truecolor" },
                    layout_config = {
                        prompt_position = "top",
                        preview_cutoff = 120,
                    },
                    vimgrep_arguments = {
                        "rg",
                        "--color=never",
                        "--no-heading",
                        "--with-filename",
                        "--line-number",
                        "--column",
                        "--smart-case",
                        "--hidden",
                        "--glob=!.git/",
                    },
                    mappings = {
                        i = {
                            ["<C-h>"] = function(prompt_bufnr)
                                actions.close(prompt_bufnr)
                                builtin.find_files({
                                    hidden = true,
                                    no_ignore = true,
                                    file_ignore_patterns = { "%.git/" },
                                })
                            end,
                        },
                        n = {
                            ["<C-h>"] = function(prompt_bufnr)
                                actions.close(prompt_bufnr)
                                builtin.find_files({
                                    hidden = true,
                                    no_ignore = true,
                                    file_ignore_patterns = { "%.git/" },
                                })
                            end,
                        },
                    },
                },
                pickers = {
                    find_files = {
                        sort_mru = true,
                        layout_config = {
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                    },
                    git_files = {
                        layout_config = {
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                    },
                    buffers = {
                        mappings = {
                            n = {
                                ["<Del>"] = actions.delete_buffer,
                                ["<BS>"] = actions.delete_buffer,
                            },
                        },
                        previewer = false,
                        initial_mode = "normal",
                        layout_config = {
                            height = 0.4,
                            width = 0.6,
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                        sort_mru = true,
                        ignore_current_buffer = true,
                    },
                    current_buffer_fuzzy_find = {
                        previewer = true,
                        layout_config = {
                            prompt_position = "top",
                            preview_cutoff = 120,
                        },
                    },
                    lsp_references = {
                        show_line = false,
                        previewer = true,
                    },
                    treesitter = {
                        show_line = false,
                        previewer = true,
                    },
                    colorscheme = {
                        enable_preview = true,
                    },
                },
                extensions = {
                    fzf = {
                        fuzzy = true,
                        override_generic_sorter = true,
                        override_file_sorter = true,
                        case_mode = "smart_case",
                    },
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown({
                            previewer = false,
                            initial_mode = "normal",
                            sorting_strategy = "ascending",
                            layout_strategy = "horizontal",
                            layout_config = {
                                horizontal = {
                                    width = 0.5,
                                    height = 0.4,
                                    preview_width = 0.6,
                                },
                            },
                        }),
                    },
                },
            })

            -- ===== Keymaps =====
            -- vim.keymap.set("n", "<Leader>fd", createCdFunction(vim.fn.expand('$HOME'), false), { desc = "Cd into home" })
            -- pcall(vim.keymap.del, "n", "<C-f>")
            -- vim.keymap.set("n", "<C-f>", createCdFunction(vim.fn.expand('$HOME'), false), { desc = "Cd into home" })

            vim.defer_fn(function()
                local homeCd = createCdFunction(vim.fn.expand('$HOME'), false)
                -- vim.keymap.set("n", "<Leader>fd", homeCd, { desc = "Cd into home", noremap = true, silent = true })
                vim.keymap.set("n", "<C-f>", homeCd, { desc = "Cd into home", noremap = true, silent = true })
            end, 0)
        end,
    },

    {
        "nvim-tree/nvim-tree.lua",
        version = "*",
        lazy = false,
        requires = {
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("nvim-tree").setup {
                sort = { sorter = "case_sensitive" },
                view = {
                    width = 30,
                    adaptive_size = true,
                },
                renderer = { group_empty = true },
                filters = { dotfiles = false },
            }
        end,
    },

    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        lazy = false,

        config = function()
            -- attention, c'est moi qui est modifié à la main le code source pour pouvoir rajouter la ligne ["<cr>"] = "open",
            -- dans le fichier "neo-tree.nvim/lua/neo-tree/sources/filesystem/lib/filter.lua", après la fonction 
            --     close_clear_filter = function(_state, _scroll_padding)
            --[[ 

            open = function(state_)
                local fs_cmds = require("neo-tree.sources.filesystem.commands")
                local utils = require("neo-tree.utils")

                -- Récupère le buffer actif avant d'ouvrir
                local bufnr_before = vim.api.nvim_get_current_buf()

                -- Appelle la commande native open de Neo-tree
                fs_cmds.open(state_)

                -- Récupère le buffer actif après ouverture
                local bufnr_after = vim.api.nvim_get_current_buf()

                -- Supprime les buffers No Name laissés derrière
                for _, b in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.api.nvim_buf_get_name(b) == "" and b ~= bufnr_after then
                        vim.api.nvim_buf_delete(b, { force = true })
                    end
                end
            end

            ]]
            require("neo-tree").setup({
                window = {
                    position = "left",
                    width = 40,
                    mappings = {
                      ["<space>"] = {
                        "toggle_node",
                        nowait = false, -- disable `nowait` if you have existing combos starting with this char that you want to use
                      },
                      ["<2-LeftMouse>"] = "open",
                      ["<cr>"] = "open",
                      ["<esc>"] = "cancel", -- close preview or floating neo-tree window
                      ["P"] = {
                        "toggle_preview",
                        config = {
                          use_float = true,
                          use_snacks_image = true,
                          use_image_nvim = true,
                        },
                      },
                      -- Read `# Preview Mode` for more information
                      ["l"] = "focus_preview",
                      ["S"] = "open_split",
                      ["s"] = "open_vsplit",
                      ["t"] = "open_tabnew",
                      -- ["t"] = "open_tab_drop",
                      ["w"] = "open_with_window_picker",
                      --["P"] = "toggle_preview", -- enter preview mode, which shows the current node without focusing
                      ["C"] = "close_node",
                      ["<Left>"] = "close_node",
                      -- ['C'] = 'close_all_subnodes',
                      ["z"] = "close_all_nodes",
                      --["Z"] = "expand_all_nodes",
                      --["Z"] = "expand_all_subnodes",

                      ["A"] = "add_directory", -- also accepts the optional config.show_path option like "add". this also supports BASH style brace expansion.
                      ["d"] = "delete",
                      ["r"] = "rename",
                      ["b"] = "rename_basename",
                      ["y"] = "copy_to_clipboard",
                      ["x"] = "cut_to_clipboard",
                      ["p"] = "paste_from_clipboard",
                      ["c"] = "copy", -- takes text input for destination, also accepts the optional config.show_path option like "add":
                      -- ["c"] = {
                      --  "copy",
                      --  config = {
                      --    show_path = "none" -- "none", "relative", "absolute"
                      --  }
                      --}
                      ["m"] = "move", -- takes text input for destination, also accepts the optional config.show_path option like "add".
                      ["q"] = "close_window",
                      ["R"] = "refresh",
                      ["?"] = "show_help",
                      ["<"] = "prev_source",
                      [">"] = "next_source",
                      ["i"] = "show_file_details",

                      ["<Tab>"] = function(state)
                          local node = state.tree:get_node()
                          if not node then return end

                          local api = vim.api
                          local tree_win = api.nvim_get_current_win() -- fenêtre Neo-tree
                          local main_win

                          -- trouver la première fenêtre qui n'est pas Neo-tree
                          for _, win in ipairs(api.nvim_list_wins()) do
                              if win ~= tree_win then
                                  main_win = win
                                  break
                              end
                          end

                          if node.type == "file" and main_win then
                              -- ouvrir le fichier dans la fenêtre principale
                              api.nvim_win_call(main_win, function()
                                  vim.cmd("silent keepalt edit " .. vim.fn.fnameescape(node.path))
                              end)
                          elseif node.type == "directory" then
                              -- ouvrir le dossier dans Neo-tree normalement
                              require("neo-tree.sources.filesystem.commands").open(state)
                          end
                      end,

                      ["<Right>"] = function(state)
                          local node = state.tree:get_node()
                          if not node then return end

                          local api = vim.api
                          local tree_win = api.nvim_get_current_win() -- fenêtre Neo-tree
                          local main_win

                          -- trouver la première fenêtre qui n'est pas Neo-tree
                          for _, win in ipairs(api.nvim_list_wins()) do
                              if win ~= tree_win then
                                  main_win = win
                                  break
                              end
                          end

                          if node.type == "file" and main_win then
                              -- ouvrir le fichier dans la fenêtre principale
                              api.nvim_win_call(main_win, function()
                                  vim.cmd("silent keepalt edit " .. vim.fn.fnameescape(node.path))
                              end)
                          elseif node.type == "directory" then
                              -- ouvrir le dossier dans Neo-tree normalement
                              require("neo-tree.sources.filesystem.commands").open(state)
                          end
                      end
                    },
                  },
                  nesting_rules = {},
                  filesystem = {
                    filtered_items = {
                      visible = false, -- when true, they will just be displayed differently than normal items
                      hide_dotfiles = true,
                      hide_gitignored = true,
                      hide_ignored = true, -- hide files that are ignored by other gitignore-like files
                      -- other gitignore-like files, in descending order of precedence.
                      ignore_files = {
                        ".neotreeignore",
                        ".ignore",
                        -- ".rgignore"
                      },
                      hide_hidden = true, -- only works on Windows for hidden files/directories
                      hide_by_name = {
                        --"node_modules"
                      },
                      hide_by_pattern = { -- uses glob style patterns
                        --"*.meta",
                        --"*/src/*/tsconfig.json",
                      },
                      always_show = { -- remains visible even if other settings would normally hide it
                        --".gitignored",
                      },
                      always_show_by_pattern = { -- uses glob style patterns
                        --".env*",
                      },
                      never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
                        --".DS_Store",
                        --"thumbs.db"
                      },
                      never_show_by_pattern = { -- uses glob style patterns
                        --".null-ls_*",
                      },
                    },
                    follow_current_file = {
                      enabled = false, -- This will find and focus the file in the active buffer every time
                      --               -- the current file is changed while the tree is open.
                      leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
                    },
                    group_empty_dirs = false, -- when true, empty folders will be grouped together
                    hijack_netrw_behavior = "open_default", -- netrw disabled, opening a directory opens neo-tree
                    -- in whatever position is specified in window.position
                    -- "open_current",  -- netrw disabled, opening a directory opens within the
                    -- window like netrw would, regardless of window.position
                    -- "disabled",    -- netrw left alone, neo-tree does not handle opening dirs
                    use_libuv_file_watcher = false, -- This will use the OS level file watchers to detect changes
                    -- instead of relying on nvim autocmd events.
                    window = {
                      mappings = {
                        ["<bs>"] = "navigate_up",
                        ["."] = "set_root",
                        ["H"] = "toggle_hidden",
                        ["/"] = "fuzzy_finder",
                        ["D"] = "fuzzy_finder_directory",
                        ["#"] = "fuzzy_sorter", -- fuzzy sorting using the fzy algorithm
                        -- ["D"] = "fuzzy_sorter_directory",
                        ["f"] = "filter_on_submit",
                        ["<c-x>"] = "clear_filter",
                        ["[g"] = "prev_git_modified",
                        ["]g"] = "next_git_modified",
                        ["o"] = {
                          "show_help",
                          nowait = false,
                          config = { title = "Order by", prefix_key = "o" },
                        },
                        ["oc"] = { "order_by_created", nowait = false },
                        ["od"] = { "order_by_diagnostics", nowait = false },
                        ["og"] = { "order_by_git_status", nowait = false },
                        ["om"] = { "order_by_modified", nowait = false },
                        ["on"] = { "order_by_name", nowait = false },
                        ["os"] = { "order_by_size", nowait = false },
                        ["ot"] = { "order_by_type", nowait = false },
                        -- ['<key>'] = function(state) ... end,
                      },
                      fuzzy_finder_mappings = { -- define keymaps for filter popup window in fuzzy_finder_mode
                        ["<cr>"] = "open", --<<<------------------------------------------- COMMANDE PERSO (cf commentaire plus haut)
                        ["<down>"] = "move_cursor_down",
                        ["<C-n>"] = "move_cursor_down",
                        ["<up>"] = "move_cursor_up",
                        ["<C-p>"] = "move_cursor_up",
                        ["<esc>"] = "close",
                        ["<S-CR>"] = "close_keep_filter",
                        ["<C-CR>"] = "close_clear_filter",
                        ["<C-w>"] = { "<C-S-w>", raw = true },
                        {
                          -- normal mode mappings
                          n = {
                            ["j"] = "move_cursor_down",
                            ["k"] = "move_cursor_up",
                            ["<S-CR>"] = "close_keep_filter",
                            ["<C-CR>"] = "close_clear_filter",
                            ["<esc>"] = "close",
                          }
                        }
                        -- ["<esc>"] = "noop", -- if you want to use normal mode
                        -- ["key"] = function(state, scroll_padding) ... end,
                      },
                    },

                    commands = {}, -- Add a custom command or override a global one using the same function name
                  },

            })
        end,
    },

    {
        "norcalli/nvim-colorizer.lua",
        enable = true,
        config = function()
            require("colorizer").setup()
        end,
    },

    {
        'akinsho/bufferline.nvim',
        version = "*",
        dependencies = 'nvim-tree/nvim-web-devicons',
    },

    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {
            focus = true,
            keys = {
                ["q"] = "close",
                ["<esc>"] = "close",
            },
        },
    },
    -- {
    --     "3rd/image.nvim",
    --     build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
    --     config = function ()
    --         require("image").setup({
    --             backend = "kitty", -- or "ueberzug" or "sixel"
    --             integrations = {
    --                 markdown = {
    --                     enabled = true,
    --                     clear_in_insert_mode = false,
    --                     download_remote_images = true,
    --                     only_render_image_at_cursor = false,
    --                     only_render_image_at_cursor_mode = "popup", -- or "inline"
    --                     floating_windows = false, -- if true, images will be rendered in floating markdown windows
    --                     filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
    --                 },
    --                 neorg = {
    --                     enabled = true,
    --                     filetypes = { "norg" },
    --                 },
    --                 typst = {
    --                     enabled = true,
    --                     filetypes = { "typst" },
    --                 },
    --                 html = {
    --                     enabled = false,
    --                 },
    --                 css = {
    --                     enabled = false,
    --                 },
    --             },
    --             max_width = 100,
    --             max_height = 12,
    --             max_width_window_percentage = math.huge,
    --             max_height_window_percentage = math.huge,
    --             scale_factor = 1.0,
    --             window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
    --             window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
    --             editor_only_render_when_focused = false, -- auto show/hide images when the editor gains/looses focus
    --             tmux_show_only_in_active_window = false, -- auto show/hide images in the correct Tmux window (needs visual-activity off)
    --             hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }, -- render image files as images when opened
    --         })
    --     end
    -- },


    -- {
    --     "karb94/neoscroll.nvim",
    --     config = function()
    --         require('neoscroll').setup({
    --             mappings = { -- Keys to be mapped to their corresponding default scrolling animation
    --                 '<C-u>', '<C-d>',
    --                 '<C-b>', '<C-f>',
    --                 '<C-y>', '<C-e>',
    --                 -- 'zt', 'zz', 'zb',
    --             },
    --             hide_cursor = false,         -- Hide cursor while scrolling
    --             stop_eof = true,             -- Stop at <EOF> when scrolling downwards
    --             respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
    --             cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
    --             easing = 'linear',           -- Default easing function
    --             pre_hook = nil,              -- Function to run before the scrolling animation starts
    --             post_hook = nil,             -- Function to run after the scrolling animation ends
    --             performance_mode = false,    -- Disable "Performance Mode" on all buffers.
    --             duration_multiplier = 0.5,   -- plus rapide
    --             ignored_events = {           -- Events ignored while scrolling
    --                 'WinScrolled', 'CursorMoved'
    --             },
    --         })
    --     end
    -- },

    -- {
    --     'mg979/vim-visual-multi',
    --     config = function()
    --         vim.g.VM_show_warnings = 0
    --         vim.g.VM_silent_exit = 1
    --     end
    -- },
    -- lazy.nvim:
    -- {
    --     "smoka7/multicursors.nvim",
    --     event = "VeryLazy",
    --     dependencies = {
    --         'nvimtools/hydra.nvim',
    --     },
    --     opts = {},
    --     cmd = { 'MCstart', 'MCvisual', 'MCclear', 'MCpattern', 'MCvisualPattern', 'MCunderCursor' },
    --     keys = {
    --         {
    --             mode = { 'v', 'n' },
    --             '<Leader>m',
    --             '<cmd>MCstart<cr>',
    --             desc = 'Create a selection for selected text or word under the cursor',
    --         },
    --     },
    -- },
    {
        "jake-stewart/multicursor.nvim",
        branch = "1.0",
        config = function()
            local mc = require("multicursor-nvim")
            mc.setup()

            local set = vim.keymap.set

            -- Add or skip cursor above/below the main cursor.
            -- set({"n", "x"}, "<up>", function() mc.lineAddCursor(-1) end)
            -- set({"n", "x"}, "<down>", function() mc.lineAddCursor(1) end)
            -- set({"n", "x"}, "<leader><up>", function() mc.lineSkipCursor(-1) end)
            -- set({"n", "x"}, "<leader><down>", function() mc.lineSkipCursor(1) end)

            -- Add or skip adding a new cursor by matching word/selection
            set({ "n", "x" }, "<leader>n", function() mc.matchAddCursor(1) end)
            set({ "n", "x" }, "<leader>N", function() mc.matchAddCursor(-1) end)

            set({ "n", "x" }, "<leader>s", function() mc.matchSkipCursor(1) end)
            set({ "n", "x" }, "<leader>S", function() mc.matchSkipCursor(-1) end)

            -- Add and remove cursors with control + left click.
            set("n", "<c-leftmouse>", mc.handleMouse)
            set("n", "<c-leftdrag>", mc.handleMouseDrag)
            set("n", "<c-leftrelease>", mc.handleMouseRelease)

            -- Disable and enable cursors.
            set({ "n", "x" }, "<c-q>", mc.toggleCursor)

            -- Mappings defined in a keymap layer only apply when there are
            -- multiple cursors. This lets you have overlapping mappings.
            mc.addKeymapLayer(function(layerSet)
                -- Select a different cursor as the main one.
                layerSet({ "n", "x" }, "<left>", mc.prevCursor)
                layerSet({ "n", "x" }, "<right>", mc.nextCursor)

                -- Delete the main cursor.
                layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

                -- Enable and clear cursors using escape.
                layerSet("n", "<esc>", function()
                    if not mc.cursorsEnabled() then
                        mc.enableCursors()
                    else
                        mc.clearCursors()
                    end
                end)
            end)

            -- Customize how cursors look.
            local hl = vim.api.nvim_set_hl
            hl(0, "MultiCursorCursor", { link = "Cursor" })
            hl(0, "MultiCursorVisual", { link = "Visual" })
            hl(0, "MultiCursorSign", { link = "SignColumn" })
            hl(0, "MultiCursorMatchPreview", { link = "Search" })
            hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
            hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
            hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
        end
    },


    -- {
    --     'arminveres/md-pdf.nvim',
    --     branch = 'main', -- you can assume that main is somewhat stable until releases will be made
    --     lazy = true,
    --     keys = {
    --         {
    --             "ùll",
    --             function() require("md-pdf").convert_md_to_pdf() end,
    --             desc = "Markdown preview",
    --         },
    --     },
    --     ---@type md-pdf.config
    --     opts = {
    --         -- Generate a table of contents, on by default
    --         toc = false,
    --         preview_cmd = function() return 'zathura' end,
    --         margins = "1.3cm",
    --     },
    -- },

    {
        'arminveres/md-pdf.nvim',
        branch = 'main',
        lazy = true,
        init = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "markdown",
                callback = function()
                    vim.keymap.set("n", "ùll", function()
                        require("md-pdf").convert_md_to_pdf()
                    end, { desc = "Markdown preview", buffer = true })
                end,
            })
        end,
        opts = {
            toc = false,
            preview_cmd = function() return 'zathura' end,
            margins = "1.3cm",
        },
    },

    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        opts = {
            heading = {
                enabled = true,
                width = 'block',
                sign = false,
            },
            code = {
                enabled = true,
                width = 'block',
                sign = false,
            }
        },
    },


    {
        'numToStr/Comment.nvim',
        opts = {
        }
    },

    -- {
    --     "lervag/vimtex",
    --     lazy = false, -- we don't want to lazy load VimTeX
    --     -- tag = "v2.15", -- uncomment to pin to a specific release
    --     init = function()
    --         -- VimTeX configuration goes here, e.g.
    --         vim.g.vimtex_view_method = "zathura"
    --         vim.g.maplocalleader = "ù"
    --         vim.g.vimtex_quickfix_mode = 0 -- enlève la fenêtre de warning à chaque fois que je compile.
    --     end
    -- },

    {
        "lervag/vimtex",
        lazy = false, -- on ne veut pas charger VimTeX en lazy
        -- tag = "v2.15", -- décommente si tu veux figer la version
        init = function()
            -- Configuration de base
            vim.g.vimtex_view_method = "zathura"
            vim.g.maplocalleader = "ù"
            vim.g.vimtex_quickfix_mode = 0 -- enlève la fenêtre de warning à chaque compilation

            -- ajouter pour gagner nettement de la performance
            vim.g.vimtex_complete_enabled = 0
            vim.g.vimtex_syntax_enabled = 1
            vim.g.vimtex_syntax_conceal_disable = 1
            vim.g.vimtex_indent_enabled = 0

            -- --- Compilateur par défaut : PdfLaTeX ---
            vim.g.vimtex_compiler_method = "latexmk"
            vim.g.vimtex_compiler_latexmk = {
                aux_dir = '_latex_aux',
                out_dir = '_latex_output',
                callback = 1,
                continuous = 1,
                executable = 'latexmk',
                options = {
                    '-pdf', -- compile avec pdflatex par défaut
                    '-interaction=nonstopmode',
                    '-synctex=1',
                },
            }
        end
    },
    {
        "folke/flash.nvim",
        event = "VeryLazy",
        opts = {
            highlight = {
                backdrop = false,
                matches = false,
            },
            modes = {
                char = {
                    highlight = { 
                        backdrop = false,
                        matches = false,
                    },
                    keys = { "f", "F", ";", "," },
                },
            },
        },
        config = function(_, opts)
            local flash = require("flash")
            flash.setup(opts)

            local search_hl = vim.api.nvim_get_hl(0, { name = "Search" })

            vim.api.nvim_set_hl(0, "FlashLabel", { bg = search_hl.bg, fg = "NONE" })
            vim.api.nvim_set_hl(0, "FlashBackdrop", {})
            vim.api.nvim_set_hl(0, "FlashMatch", {})
            vim.api.nvim_set_hl(0, "FlashCurrent", {})
        end,
    },


    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',

        config = function()
            require 'nvim-treesitter.configs'.setup {
                ensure_installed = { 'lua', 'python', 'bash', 'markdown', 'markdown_inline', 'javascript', "c", "vim", "vimdoc", "query", "rust", "typescript", "java" }, -- ou une liste des langages que tu veux
                highlight = { enable = true, additional_vim_regex_highlighting = false, },                                                                         -- active la coloration syntaxique
                indent = { enable = false },                                                                                                                       --METTRE SUR FALSE SINON HORRIBLES LAGS
            }
        end
    },

    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup {
                signs = {
                    add = { text = '+' },
                    change = { text = '~' },
                    delete = { text = '—' },
                    topdelete = { text = '—' },
                    changedelete = { text = '~' },
                },
                signs_staged = {
                    add = { text = '+' },
                    change = { text = '~' },
                    delete = { text = '—' },
                    topdelete = { text = '—' },
                    changedelete = { text = '~' },
                },
            }
        end,

    },

    -- {
    --     "zbirenbaum/copilot.lua",
    --     cmd = "Copilot",
    --     event = "InsertEnter",
    --     config = function()
    --         require("copilot").setup({
    --             panel = {
    --                 enabled = true,
    --                 auto_refresh = false,
    --                 keymap = {
    --                     jump_prev = "[[",
    --                     jump_next = "]]",
    --                     accept = "<CR>",
    --                     refresh = "gr",
    --                     open = "<M-CR>",
    --                 },
    --                 layout = {
    --                     position = "bottom", -- | top | left | right | horizontal | vertical
    --                     ratio = 0.4,
    --                 },
    --             },
    --             suggestion = {
    --                 enabled = true,
    --                 auto_trigger = false,
    --                 hide_during_completion = true,
    --                 debounce = 75,
    --                 keymap = {
    --                     accept = "<C-l>",
    --                     accept_word = false,
    --                     accept_line = false,
    --                     next = "<M-]>",
    --                     prev = "<M-[>",
    --                     dismiss = "<C-]>",
    --                 },
    --             },
    --             filetypes = {
    --                 yaml = false,
    --                 markdown = false,
    --                 help = false,
    --                 gitcommit = false,
    --                 gitrebase = false,
    --                 hgcommit = false,
    --                 svn = false,
    --                 cvs = false,
    --                 ["."] = false,
    --             },
    --             copilot_node_command = "node", -- Node.js version must be > 18.x
    --             server_opts_overrides = {},
    --         })
    --     end,
    -- },



    -- {
    --     "yetone/avante.nvim",
    --     event = "VeryLazy",
    --     lazy = false,
    --     version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
    --     opts = {
    --         -- add any opts here
    --         provider = "copilot",
    --         hints = { enabled = false },
    --         -- copilot = {
    --         -- }
    --
    --     },
    --     -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    --     build = "make",
    --     dependencies = {
    --         "stevearc/dressing.nvim",
    --         "nvim-lua/plenary.nvim",
    --         "MunifTanjim/nui.nvim",
    --         --- The below dependencies are optional,
    --         "echasnovski/mini.pick", -- for file_selector provider mini.pick
    --         "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
    --         "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
    --         "ibhagwan/fzf-lua", -- for file_selector provider fzf
    --         "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    --         "zbirenbaum/copilot.lua", -- for providers='copilot'
    --         {
    --             -- Make sure to set this up properly if you have lazy=true
    --             'MeanderingProgrammer/render-markdown.nvim',
    --             opts = {
    --                 file_types = { "markdown", "Avante" },
    --             },
    --             ft = { "markdown", "Avante" },
    --         },
    --     },
    -- },

    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            require('lualine').setup {
                options = {
                    icons_enabled = true,
                    theme = 'auto',
                    component_separators = { left = '', right = '' },
                    section_separators = { left = '', right = '' },
                    disabled_filetypes = {
                        statusline = { "NvimTree" },
                        winbar = { "NvimTree" },
                    },
                    ignore_focus = {},
                    always_divide_middle = true,
                    always_show_tabline = true,
                    globalstatus = false,
                    refresh = {
                        statusline = 10,
                        tabline = 10,
                        winbar = 10,
                    }
                },
                sections = {
                    lualine_a = { 'mode' },
                    lualine_b = { 'branch', 'diff', 'diagnostics' },
                    lualine_c = {
                        {
                            'filename',
                            path = 1, -- Affiche le chemin relatif
                        }
                    },
                    lualine_x = { 'encoding', 'fileformat', 'filetype' },
                    lualine_y = { 'progress' },
                    lualine_z = { 'location' }
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = {
                        {
                            'filename',
                            path = 1, -- Affiche le chemin relatif
                        }
                    },
                    lualine_x = { 'location' },
                    lualine_y = {},
                    lualine_z = {}
                },
                tabline = {},
                winbar = {},
                inactive_winbar = {},
                extensions = {}
            }
        end,
    },


    -- {"ggandor/leap.nvim"}, -- qd je serai un vim-experienced guy

    -- {
    --   "leath-dub/snipe.nvim",
    --   keys = {
    --     {
    --       "<leader><Tab>",
    --       function()
    --         require("snipe").open_buffer_menu()
    --       end,
    --       desc = "Open Snipe buffer menu",
    --     },
    --   },
    --   config = function()
    --     local snipe = require("snipe")
    --
    --     -- Surcharge de la méthode de formatage des buffers
    --     local function custom_format(buffer)
    --       local max_path_width = 2
    --       local path = buffer.path or ""
    --       -- Troncature des chemins trop longs
    --       if #path > max_path_width then
    --         path = "…" .. path:sub(-max_path_width)
    --       end
    --       return string.format("[%d] %s", buffer.bufnr, path)
    --     end
    --
    --     -- Configuration de Snipe avec la fonction de formatage personnalisée
    --     snipe.setup({
    --       hints = {
    --         dictionary = "123456789",
    --       },
    --       navigate = {
    --         cancel_snipe = "<esc>",
    --         close_buffer = "d",
    --         under_cursor = "<Tab>",
    --       },
    --       sort = "default",
    --       buffer_formatter = custom_format, -- Utilisation de notre format personnalisé
    --     })
    --   end,
    -- },


    { "moll/vim-bbye" },

    { "mbbill/undotree" },

    { "hrsh7th/cmp-path" },

    {
        "folke/persistence.nvim",
        event = "BufReadPre",
        opts = {},
        -- stylua: ignore
        keys = {
            { "<leader>qs", function() require("persistence").load() end,                desc = "Restore Session" },
            { "<leader>qS", function() require("persistence").select() end,              desc = "Select Session" },
            { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
            { "<leader>qd", function() require("persistence").stop() end,                desc = "Don't Save Current Session" },
        },
    },

    --   {
    --     "nvimdev/dashboard-nvim",
    --     lazy = false, -- As https://github.com/nvimdev/dashboard-nvim/pull/450, dashboard-nvim shouldn't be lazy-loaded to properly handle stdin.
    --     opts = function()
    --
    --       local logo = [[
    --
    --  ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
    --  ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
    -- ▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
    -- ▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██
    -- ▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
    -- ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
    -- ░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░
    --    ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░
    --          ░    ░  ░    ░ ░        ░   ░         ░
    --                                 ░
    -- ]]
    --
    --       logo = string.rep("\n", 8) .. logo .. "\n\n"
    --
    --       local opts = {
    --         theme = "doom",
    --         hide = {
    --           -- this is taken care of by lualine
    --           -- enabling this messes up the actual laststatus setting after loading a file
    --           statusline = true,
    --         },
    --         preview = {
    --             command = "chafa /home/for/Pictures/logo/samurai_logo_blue_bis.png --symbols all --size 55",  -- Commande pour convertir l'image en ASCII
    --             file_path = "/home/for/Pictures/samurai_logo_gray.png",  -- Chemin vers l'image
    --             file_height = 30,  -- Hauteur de l'aperçu
    --             file_width = 80,  -- Largeur de l'aperçu
    --             -- position = "right",
    --         },
    --         config = {
    --           header = vim.split(logo, "\n"),
    --           -- stylua: ignore
    --           center = {
    --             { action = ':Telescope find_files', desc = " Find File", icon = " ", key = "f" },
    --             { action = "ene | startinsert", desc = " New File", icon = " ", key = "n" },
    --             { action = ":Telescope oldfiles", desc = " Recent Files", icon = " ", key = "r" },
    --             { action = ':Telescope live_grep', desc = " Find Text", icon = " ", key = "g" },
    --             { action = 'require("telescope.builtin").find_files({ cwd = "~/.config/nvim" })', desc = " Config", icon = " ", key = "c" },
    --             { action = 'lua require("persistence").load()', desc = " Restore Session", icon = " ", key = "s" },
    --             { action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
    --             { action = function() vim.api.nvim_input("<cmd>qa<cr>") end, desc = " Quit", icon = " ", key = "q" },
    --           },
    --           footer = function()
    --             local stats = require("lazy").stats()
    --             local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
    --             return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
    --           end,
    --         },
    --       }
    --
    --       for _, button in ipairs(opts.config.center) do
    --         button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
    --         button.key_format = "  %s"
    --       end
    --
    --       -- open dashboard after closing lazy
    --       if vim.o.filetype == "lazy" then
    --         vim.api.nvim_create_autocmd("WinClosed", {
    --           pattern = tostring(vim.api.nvim_get_current_win()),
    --           once = true,
    --           callback = function()
    --             vim.schedule(function()
    --               vim.api.nvim_exec_autocmds("UIEnter", { group = "dashboard" })
    --             end)
    --           end,
    --         })
    --       end
    --
    --       return opts
    --     end,
    --   },


    -- {
    --     "echasnovski/mini.files",
    --
    --     opts = function(_, opts)
    --         -- I didn't like the default mappings, so I modified them
    --         -- Module mappings created only inside explorer.
    --         -- Use `''` (empty string) to not create one.
    --         opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
    --             close = "<esc>",
    --             -- Use this if you want to open several files
    --             go_in = "<Right>",
    --             -- This opens the file, but quits out of mini.files (default L)
    --             go_in_plus = "<CR>",
    --             -- I swapped the following 2 (default go_out: h)
    --             -- go_out_plus: when you go out, it shows you only 1 item to the right
    --             -- go_out: shows you all the items to the right
    --             go_out = "H",
    --             go_out_plus = "<Left>",
    --             -- Default <BS>
    --             reset = "<BS>",
    --             -- Default @
    --             reveal_cwd = ".",
    --             show_help = "g?",
    --             -- Default =
    --             synchronize = "s",
    --             trim_left = "<",
    --             trim_right = ">",
    --
    --             -- Below I created an autocmd with the "," keymap to open the highlighted
    --             -- directory in a tmux pane on the right
    --         })
    --
    --         vim.api.nvim_create_autocmd("User", {
    --             pattern = "MiniFilesBufferCreate",
    --             callback = function(args)
    --                 vim.keymap.set("n", "<Tab>", "<Right>", { buffer = args.data.buf_id, remap = true })
    --             end,
    --         })
    --
    --         -- Here I define my custom keymaps in a centralized place
    --         opts.custom_keymaps = {
    --             -- open_tmux_pane = "<M-t>",
    --             copy_to_clipboard = "<space>yy",
    --             zip_and_copy = "<space>yz",
    --             paste_from_clipboard = "<space>p",
    --             copy_path = "<M-c>",
    --             -- Don't use "i" as it conflicts wit insert mode
    --             preview_image = "<C-Right>",
    --             -- preview_image_popup = "<M-i>",
    --
    --         }
    --
    --         opts.windows = vim.tbl_deep_extend("force", opts.windows or {}, {
    --             preview = false,
    --             width_focus = 30,
    --             width_preview = 80,
    --         })
    --
    --         opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
    --             -- Whether to use for editing directories
    --             -- Disabled by default in LazyVim because neo-tree is used for that
    --             use_as_default_explorer = true,
    --             -- If set to false, files are moved to the trash directory
    --             -- To get this dir run :echo stdpath('data')
    --             -- ~/.local/share/neobean/mini.files/trash
    --             permanent_delete = false,
    --         })
    --
    --
    --         local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
    --         local autocmd = vim.api.nvim_create_autocmd
    --         local _, MiniFiles = pcall(require, "mini.files")
    --
    --         -- Cache for git status
    --         local gitStatusCache = {}
    --         local cacheTimeout = 2000 -- Cache timeout in milliseconds
    --
    --         ---@type table<string, {symbol: string, hlGroup: string}>
    --         ---@param status string
    --         ---@return string symbol, string hlGroup
    --         local function mapSymbols(status)
    --             local statusMap = {
    --                 -- stylua: ignore start
    --                 [" M"] = { symbol = "•", hlGroup = "GitSignsChange" }, -- Modified in the working directory
    --                 ["M "] = { symbol = "✹", hlGroup = "GitSignsChange" }, -- modified in index
    --                 ["MM"] = { symbol = "≠", hlGroup = "GitSignsChange" }, -- modified in both working tree and index
    --                 ["A "] = { symbol = "+", hlGroup = "GitSignsAdd" }, -- Added to the staging area, new file
    --                 ["AA"] = { symbol = "≈", hlGroup = "GitSignsAdd" }, -- file is added in both working tree and index
    --                 ["D "] = { symbol = "-", hlGroup = "GitSignsDelete" }, -- Deleted from the staging area
    --                 ["AM"] = { symbol = "⊕", hlGroup = "GitSignsChange" }, -- added in working tree, modified in index
    --                 ["AD"] = { symbol = "-•", hlGroup = "GitSignsChange" }, -- Added in the index and deleted in the working directory
    --                 ["R "] = { symbol = "→", hlGroup = "GitSignsChange" }, -- Renamed in the index
    --                 ["U "] = { symbol = "‖", hlGroup = "GitSignsChange" }, -- Unmerged path
    --                 ["UU"] = { symbol = "⇄", hlGroup = "GitSignsAdd" }, -- file is unmerged
    --                 ["UA"] = { symbol = "⊕", hlGroup = "GitSignsAdd" }, -- file is unmerged and added in working tree
    --                 ["??"] = { symbol = "?", hlGroup = "GitSignsDelete" }, -- Untracked files
    --                 ["!!"] = { symbol = "!", hlGroup = "GitSignsChange" }, -- Ignored files
    --                 -- stylua: ignore end
    --             }
    --
    --             local result = statusMap[status]
    --                 or { symbol = "?", hlGroup = "NonText" }
    --             return result.symbol, result.hlGroup
    --         end
    --
    --         ---@param cwd string
    --         ---@param callback function
    --         ---@return nil
    --         local function fetchGitStatus(cwd, callback)
    --             local function on_exit(content)
    --                 if content.code == 0 then
    --                     callback(content.stdout)
    --                     vim.g.content = content.stdout
    --                 end
    --             end
    --
    --             local cwd = vim.loop.cwd()
    --             if not cwd or vim.fn.isdirectory(cwd .. "/.git") == 0 then
    --                 print("Not a Git repository: " .. cwd)
    --                 return
    --             end
    --             vim.system(
    --                 { "git", "status", "--ignored", "--porcelain" },
    --                 { text = true, cwd = cwd },
    --                 on_exit
    --             )
    --         end
    --
    --         ---@param str string?
    --         local function escapePattern(str)
    --             return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    --         end
    --
    --         ---@param buf_id integer
    --         ---@param gitStatusMap table
    --         ---@return nil
    --         local function updateMiniWithGit(buf_id, gitStatusMap)
    --             vim.schedule(function()
    --                 local nlines = vim.api.nvim_buf_line_count(buf_id)
    --                 local cwd = vim.fs.root(buf_id, ".git")
    --                 local escapedcwd = escapePattern(cwd)
    --                 if vim.fn.has("win32") == 1 then
    --                     escapedcwd = escapedcwd:gsub("\\", "/")
    --                 end
    --
    --                 for i = 1, nlines do
    --                     local entry = MiniFiles.get_fs_entry(buf_id, i)
    --                     if not entry then
    --                         break
    --                     end
    --                     local relativePath = entry.path:gsub("^" .. escapedcwd .. "/", "")
    --                     local status = gitStatusMap[relativePath]
    --
    --                     if status then
    --                         local symbol, hlGroup = mapSymbols(status)
    --                         vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, 0, {
    --                             -- NOTE: if you want the signs on the right uncomment those and comment
    --                             -- the 3 lines after
    --                             -- virt_text = { { symbol, hlGroup } },
    --                             -- virt_text_pos = "right_align",
    --                             sign_text = symbol,
    --                             sign_hl_group = hlGroup,
    --                             priority = 2,
    --                         })
    --                     else
    --                     end
    --                 end
    --             end)
    --         end
    --
    --
    --         -- Thanks for the idea of gettings https://github.com/refractalize/oil-git-status.nvim signs for dirs
    --         ---@param content string
    --         ---@return table
    --         local function parseGitStatus(content)
    --             local gitStatusMap = {}
    --             -- lua match is faster than vim.split (in my experience )
    --             for line in content:gmatch("[^\r\n]+") do
    --                 local status, filePath = string.match(line, "^(..)%s+(.*)")
    --                 -- Split the file path into parts
    --                 local parts = {}
    --                 for part in filePath:gmatch("[^/]+") do
    --                     table.insert(parts, part)
    --                 end
    --                 -- Start with the root directory
    --                 local currentKey = ""
    --                 for i, part in ipairs(parts) do
    --                     if i > 1 then
    --                         -- Concatenate parts with a separator to create a unique key
    --                         currentKey = currentKey .. "/" .. part
    --                     else
    --                         currentKey = part
    --                     end
    --                     -- If it's the last part, it's a file, so add it with its status
    --                     if i == #parts then
    --                         gitStatusMap[currentKey] = status
    --                     else
    --                         -- If it's not the last part, it's a directory. Check if it exists, if not, add it.
    --                         if not gitStatusMap[currentKey] then
    --                             gitStatusMap[currentKey] = status
    --                         end
    --                     end
    --                 end
    --             end
    --             return gitStatusMap
    --         end
    --
    --         ---@param buf_id integer
    --         ---@return nil
    --         local function updateGitStatus(buf_id)
    --             if not vim.fs.root(vim.uv.cwd(), ".git") then
    --                 return
    --             end
    --
    --             local cwd = vim.fn.expand("%:p:h")
    --             local currentTime = os.time()
    --             if
    --                 gitStatusCache[cwd]
    --                 and currentTime - gitStatusCache[cwd].time < cacheTimeout
    --             then
    --                 updateMiniWithGit(buf_id, gitStatusCache[cwd].statusMap)
    --             else
    --                 fetchGitStatus(cwd, function(content)
    --                     local gitStatusMap = parseGitStatus(content)
    --                     gitStatusCache[cwd] = {
    --                         time = currentTime,
    --                         statusMap = gitStatusMap,
    --                     }
    --                     updateMiniWithGit(buf_id, gitStatusMap)
    --                 end)
    --             end
    --         end
    --
    --         ---@return nil
    --         local function clearCache()
    --             gitStatusCache = {}
    --         end
    --
    --         local function augroup(name)
    --             return vim.api.nvim_create_augroup(
    --                 "MiniFiles_" .. name,
    --                 { clear = true }
    --             )
    --         end
    --
    --         autocmd("User", {
    --             group = augroup("start"),
    --             pattern = "MiniFilesExplorerOpen",
    --             -- pattern = { "minifiles" },
    --             callback = function()
    --                 local bufnr = vim.api.nvim_get_current_buf()
    --                 updateGitStatus(bufnr)
    --             end,
    --         })
    --
    --         autocmd("User", {
    --             group = augroup("close"),
    --             pattern = "MiniFilesExplorerClose",
    --             callback = function()
    --                 clearCache()
    --             end,
    --         })
    --
    --         autocmd("User", {
    --             group = augroup("update"),
    --             pattern = "MiniFilesBufferUpdate",
    --             callback = function(sii)
    --                 local bufnr = sii.data.buf_id
    --                 local cwd = vim.fn.expand("%:p:h")
    --                 if gitStatusCache[cwd] then
    --                     updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
    --                 end
    --             end,
    --         })
    --
    --         return opts
    --     end,
    --
    --
    --     -- keys = {
    --     --     {
    --     --         -- Toggle the directory of the file currently being edited
    --     --         -- If the file doesn't exist, open the current working directory
    --     --         "<leader>e",
    --     --         function()
    --     --             local buf_name = vim.api.nvim_buf_get_name(0)
    --     --             local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")
    --     --
    --     --             if mini_files_open then
    --     --                 -- If mini.files is open, close it
    --     --                 require("mini.files").close()
    --     --                 mini_files_open = false
    --     --             else
    --     --                 -- If mini.files is not open, open the appropriate directory
    --     --                 if vim.fn.filereadable(buf_name) == 1 then
    --     --                     -- Pass the full file path to highlight the file
    --     --                     require("mini.files").open(buf_name, true)
    --     --                 elseif vim.fn.isdirectory(dir_name) == 1 then
    --     --                     -- If the directory exists but the file doesn't, open the directory
    --     --                     require("mini.files").open(dir_name, true)
    --     --                 else
    --     --                     -- If neither exists, fallback to the current working directory
    --     --                     require("mini.files").open(vim.uv.cwd(), true)
    --     --                 end
    --     --                 mini_files_open = true
    --     --             end
    --     --         end,
    --     --         desc = "Toggle mini.files (Directory of Current File or CWD if not exists)",
    --     --     },
    --     --     -- Open the current working directory
    --     --     {
    --     --         "<leader>E",
    --     --         function()
    --     --             require("mini.files").open(vim.uv.cwd(), true)
    --     --         end,
    --     --         desc = "Open mini.files (cwd)",
    --     --     },
    --     -- },
    --
    --
    --     --config si on ne peut pas toggle avec <leader>e
    --     keys = {
    --         -- {
    --         --     -- Open the directory of the file currently being edited
    --         --     -- If the file doesn't exist because you maybe switched to a new git branch
    --         --     -- open the current working directory
    --         --     "<leader>e",
    --         --     function()
    --         --         local buf_name = vim.api.nvim_buf_get_name(0)
    --         --         local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")
    --         --         if vim.fn.filereadable(buf_name) == 1 then
    --         --             -- Pass the full file path to highlight the file
    --         --             require("mini.files").open(buf_name, true)
    --         --         elseif vim.fn.isdirectory(dir_name) == 1 then
    --         --             -- If the directory exists but the file doesn't, open the directory
    --         --             require("mini.files").open(dir_name, true)
    --         --         else
    --         --             -- If neither exists, fallback to the current working directory
    --         --             require("mini.files").open(vim.uv.cwd(), true)
    --         --         end
    --         --     end,
    --         --     desc = "Open mini.files (Directory of Current File or CWD if not exists)",
    --         -- },
    --         -- Open the current working directory
    --         {
    --             "<leader>E",
    --             function()
    --                 require("mini.files").open(vim.uv.cwd(), true)
    --             end,
    --             desc = "Open mini.files (cwd)",
    --         },
    --     },
    -- },

    { "sindrets/diffview.nvim" },


    {
        -- You can also use the codeberg mirror if you want to use the plugin without relying on GitHub
        -- "https://codeberg.org/CodingThunder/zincoxide.git" -- for HTTPS
        -- "git@codeberg.org:CodingThunder/zincoxide.git"     -- for SSH
        -- NOTE: the username on both github and codeberg are different
        "thunder-coding/zincoxide",
        opts = {
            -- name of zoxide binary in your "$PATH" or path to the binary
            -- the command is executed using vim.fn.system()
            -- eg. "zoxide" or "/usr/bin/zoxide"
            zincoxide_cmd = "zoxide",
            -- Kinda experimental as of now
            complete = true,
            -- Available options { "tabs", "window", "global" }
            behaviour = "tabs",
        },
        cmd = { "Z", "Zg", "Zt", "Zw" },
    },

    -- { 'akinsho/toggleterm.nvim', version = "*", config = true },

    {
        'jghauser/follow-md-links.nvim'
    },

    {
        "folke/todo-comments.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        opts = {
            signs = true,
            sign_priority = 8,
            keywords = {
                FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
                TODO = { icon = " ", color = "info" },
                HACK = { icon = " ", color = "warning" },
                WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
                PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
                NOTE = { icon = "", color = "hint", alt = { "INFO" } },
                TEST = { icon = "󰙨", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
                SEP = { icon = "─", color = "info"},
                INSERT = { icon = "", color = "info"},
            },
            merge_keywords = false,
            gui_style = { fg = "NONE", bg = "BOLD" },
            highlight = {
                multiline = true,
                multiline_pattern = "^.",
                multiline_context = 10,
                before = "",
                keyword = "wide",
                after = "fg",
                pattern = [[.*<(KEYWORDS)\s*:]],
                comments_only = true, -- met true si tes TODO/FIX sont dans des commentaires
                max_line_len = 400,
                exclude = {},
            },
            colors = {
                -- error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
                -- warning = { "DiagnosticWarn", "WarningMsg", "#e0af68" },
                info = { "DiagnosticInfo" },
                -- hint = { "DiagnosticHint", "#10b981" },
                -- default = { "Identifier", "#bb9af7" },
                -- test = { "Identifier", "#FF00FF" },

                error = "#ff4d4d",
                -- warning = "#fff176",
                warning = "#fff59d",  -- jaune clair légèrement néon
                -- info = "#6eeed9",
                -- info = "#64f2d8",
                -- info = "#5ef0d0" ,
                -- info = "#76ffe1",
                -- info = "#4df2d1" ,

                hint = "#10b981",
                default = "#bb9af7",
                test = "#ff8c42",
                -- test = "#f5b7ff"  -- rose pastel lumineux
                -- test = "#f28ce2"  -- rose-violet doux

            },
            search = {
                command = "rg",
                args = { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column" },
                pattern = [[\b(KEYWORDS):]],
            },
        }
    },

    {
        "folke/snacks.nvim",
        priority = 1000,
        -- priority = 1000,
        lazy = false,
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
            bigfile = { enabled = true },
            notifier = {
                enabled = true,
                timeout = 3000,
            },
            quickfile = { enabled = true },

            image = {
                enabled = false,

                formats = {
                },

                doc = {
                    enabled = false,
                }
            },
            lazygit = {
                enabled = true,
                configure = true,
            },


            picker = {
                enabled = true,
                matcher = {
                    sort_empty = true,
                    frecency = true,
                },

                notifications = {
                    wrap = true, -- Assure-toi que le wrapping est activé pour les notifications
                },
                -- debug = {
                --     scores = true, -- show scores in the list
                -- },

                sources = {


                    explorer = {

                        finder = "explorer",
                        sort = { fields = { "sort" } },
                        supports_live = true,
                        tree = true,
                        watch = true,
                        diagnostics = true,
                        diagnostics_open = false,
                        git_status = true,
                        git_status_open = false,
                        git_untracked = true,
                        follow_file = true,
                        focus = "list",
                        auto_close = false,
                        jump = { close = false },
                        layout = { preset = "sidebar", preview = false },
                        -- to show the explorer to the right, add the below to
                        -- your config under `opts.picker.sources.explorer`
                        -- layout = { layout = { position = "right" } },
                        formatters = {
                            file = { filename_only = true },
                            severity = { pos = "right" },
                        },
                        matcher = { sort_empty = false, fuzzy = false },
                        -- config = function(opts)
                        --     return require("snacks.picker.source.explorer").setup(opts)
                        -- end,
                        win = {
                            list = {
                                keys = {
                                    ["/"] = "toggle_focus", -- IMPORTANT
                                    ["<BS>"] = "explorer_up",
                                    ["<CR>"] = "confirm",
                                    ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } }, -- IMPORTANT
                                    ["<Tab>"] = { "select", mode = { "i", "n" } },         -- IMPORTANT
                                    ["l"] = "confirm",
                                    ["h"] = "explorer_close",                              -- close directory
                                    ["a"] = "explorer_add",
                                    ["d"] = "explorer_del",
                                    ["r"] = "explorer_rename",
                                    ["c"] = "explorer_copy",
                                    ["m"] = "explorer_move",
                                    ["o"] = "explorer_open", -- open with system application
                                    ["P"] = "toggle_preview",
                                    ["y"] = { "explorer_yank", mode = { "n", "x" } },
                                    ["p"] = "explorer_paste",
                                    ["u"] = "explorer_update",
                                    ["<c-c>"] = "tcd",
                                    ["<leader>/"] = "picker_grep",
                                    ["<c-t>"] = "terminal",
                                    ["."] = "explorer_focus",
                                    ["I"] = "toggle_ignored",
                                    ["H"] = "toggle_hidden",
                                    ["Z"] = "explorer_close_all",
                                    ["]g"] = "explorer_git_next",
                                    ["[g"] = "explorer_git_prev",
                                    ["]d"] = "explorer_diagnostic_next",
                                    ["[d"] = "explorer_diagnostic_prev",
                                    ["]w"] = "explorer_warn_next",
                                    ["[w"] = "explorer_warn_prev",
                                    ["]e"] = "explorer_error_next",
                                    ["[e"] = "explorer_error_prev",

                                    ["<Left>"] = "explorer_up",
                                    ["<Right>"] = "confirm",

                                    ["<C-left>"] = { "explorer_up_and_cd", mode = { "i", "n" } },
                                    ["<C-right>"] = { "explorer_cd", mode = { "i", "n" } },
                                },
                            },
                        },
                    },
                },

                win = {
                    -- input window
                    input = {
                        keys = {
                            -- to close the picker on ESC instead of going to normal mode,
                            -- add the following keymap to your config
                            -- ["<Esc>"] = { "close", mode = { "n", "i" } },
                            ["/"] = "toggle_focus", -- IMPORTANT
                            -- ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
                            -- ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
                            ["<C-up>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },
                            ["<C-down>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["<C-left>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },
                            ["<C-right>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["<C-c>"] = { "cancel", mode = "i" },
                            ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
                            ["<CR>"] = { "confirm", mode = { "n", "i" } },
                            ["<Down>"] = { "list_down", mode = { "i", "n" } },
                            ["<Esc>"] = "cancel",
                            -- ["<S-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
                            -- ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },-- IMPORTANT
                            -- ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },-- IMPORTANT

                            ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } }, -- IMPORTANT
                            ["<Tab>"] = { "select", mode = { "i", "n" } },         -- IMPORTANT
                            ["<Up>"] = { "list_up", mode = { "i", "n" } },
                            ["<a-d>"] = { "inspect", mode = { "n", "i" } },
                            ["<a-f>"] = { "toggle_follow", mode = { "i", "n" } },
                            ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } }, -- IMPORTANT
                            ["<c-h>"] = { "toggle_hidden", mode = { "i", "n" } }, -- IMPORTANT
                            ["<a-i>"] = { "toggle_ignored", mode = { "i", "n" } },
                            ["<a-m>"] = { "toggle_maximize", mode = { "i", "n" } },
                            ["<a-p>"] = { "toggle_preview", mode = { "i", "n" } },
                            ["<a-w>"] = { "cycle_win", mode = { "i", "n" } },
                            ["<c-a>"] = { "select_all", mode = { "n", "i" } },
                            ["<c-b>"] = { "preview_scroll_up", mode = { "i", "n" } },
                            ["<c-d>"] = { "list_scroll_down", mode = { "i", "n" } },
                            ["<c-f>"] = { "preview_scroll_down", mode = { "i", "n" } },
                            ["<c-g>"] = { "toggle_live", mode = { "i", "n" } },
                            ["<c-j>"] = { "list_down", mode = { "i", "n" } },
                            ["<c-k>"] = { "list_up", mode = { "i", "n" } },
                            ["<c-n>"] = { "list_down", mode = { "i", "n" } },
                            ["<c-p>"] = { "list_up", mode = { "i", "n" } },
                            ["<c-q>"] = { "qflist", mode = { "i", "n" } },
                            ["<c-s>"] = { "edit_split", mode = { "i", "n" } },
                            ["<c-t>"] = { "tab", mode = { "n", "i" } },
                            ["<c-u>"] = { "list_scroll_up", mode = { "i", "n" } },
                            ["<c-v>"] = { "edit_vsplit", mode = { "i", "n" } },
                            ["<c-r>#"] = { "insert_alt", mode = "i" },
                            ["<c-r>%"] = { "insert_filename", mode = "i" },
                            ["<c-r><c-a>"] = { "insert_cWORD", mode = "i" },
                            ["<c-r><c-f>"] = { "insert_file", mode = "i" },
                            ["<c-r><c-l>"] = { "insert_line", mode = "i" },
                            ["<c-r><c-p>"] = { "insert_file_full", mode = "i" },
                            ["<c-r><c-w>"] = { "insert_cword", mode = "i" },
                            ["<c-w>H"] = "layout_left",
                            ["<c-w>J"] = "layout_bottom",
                            ["<c-w>K"] = "layout_top",
                            ["<c-w>L"] = "layout_right",
                            ["?"] = "toggle_help_input",
                            ["G"] = "list_bottom",
                            ["gg"] = "list_top",
                            ["j"] = "list_down",
                            ["k"] = "list_up",
                            ["q"] = "close",
                        },
                        b = {
                            minipairs_disable = true,
                        },
                    },
                    -- result list window
                    list = {
                        keys = {

                            ["<C-up>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },
                            ["<C-left>"] = { navigate_to_parent_smooth, mode = { "i", "n" } },

                            ["<C-down>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["<C-right>"] = { navigate_back_smooth, mode = { "i", "n" } },
                            ["/"] = "toggle_focus", -- IMPORTANT
                            ["<2-LeftMouse>"] = "confirm",
                            ["<CR>"] = "confirm",   -- IMPORTANT
                            ["<Down>"] = "list_down",
                            ["<Esc>"] = "cancel",
                            ["<S-CR>"] = { { "pick_win", "jump" } },
                            -- ["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },-- IMPORTANT
                            -- ["<Tab>"] = { "select_and_next", mode = { "n", "x" } },-- IMPORTANT

                            ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } }, -- IMPORTANT
                            ["<Tab>"] = { "select", mode = { "i", "n" } },         -- IMPORTANT
                            ["<Up>"] = "list_up",
                            ["<a-d>"] = "inspect",
                            ["<a-f>"] = "toggle_follow",
                            ["<a-h>"] = "toggle_hidden", -- IMPORTANT
                            ["<c-h>"] = "toggle_hidden",
                            ["<a-i>"] = "toggle_ignored",
                            ["<a-m>"] = "toggle_maximize",
                            ["<a-p>"] = "toggle_preview",
                            ["<a-w>"] = "cycle_win",
                            ["<c-a>"] = "select_all",
                            ["<c-b>"] = "preview_scroll_up",
                            ["<c-d>"] = "list_scroll_down",
                            ["<c-f>"] = "preview_scroll_down",
                            ["<c-j>"] = "list_down",
                            ["<c-k>"] = "list_up",
                            ["<c-n>"] = "list_down",
                            ["<c-p>"] = "list_up",
                            ["<c-q>"] = "qflist",
                            ["<c-s>"] = "edit_split",
                            ["<c-t>"] = "tab",
                            ["<c-u>"] = "list_scroll_up",
                            ["<c-v>"] = "edit_vsplit",
                            ["<c-w>H"] = "layout_left",
                            ["<c-w>J"] = "layout_bottom",
                            ["<c-w>K"] = "layout_top",
                            ["<c-w>L"] = "layout_right",
                            ["?"] = "toggle_help_list",
                            ["G"] = "list_bottom",
                            ["gg"] = "list_top",
                            ["i"] = "focus_input",
                            ["j"] = "list_down",
                            ["k"] = "list_up",
                            ["q"] = "close",
                            ["zb"] = "list_scroll_bottom",
                            ["zt"] = "list_scroll_top",
                            ["zz"] = "list_scroll_center",
                        },
                        wo = {
                            conceallevel = 2,
                            concealcursor = "nvc",
                        },
                    },
                },
            },



            input = { enabled = true },
            win = {
                enabled = true,
                show = true,

                backdrop = false,
            },

            scroll = { enabled = false },
            words = { enabled = false },
            indent = { enabled = false },
            scope = { enabled = false },
            statuscolumn = { enabled = false },
            dim = { enabled = false },
            terminal = {
                enabled = false,
            },

            dashboard = {
                enabled = true,
                -- pane_gap = 8, -- empty columns between vertical panes
                pane_gap = 16, -- empty columns between vertical panes
                width = 50,
                row = nil,     -- dashboard position. nil for center
                col = nil,     -- dashboard position. nil for center
                preset = {
                    pick = nil,
                    keys = {
                        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                        { icon = " ", key = "f", desc = "Find File", action = function() Snacks.picker.files() end },
                        { icon = " ", key = "g", desc = "Find Text", action = ":Telescope live_grep" },
                        -- { icon = " ", key = "r", desc = "Recent Files", action = function() Snacks.picker.oldfiles() end },
                        -- { icon = " ", key = "c", desc = "Config", action = function() Snacks.picker.files({ cwd = "~/.config/nvim" }) end },
                        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
                        -- { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
                        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
                    },
                    -- Used by the `header` section
                    header = [[


 ███▄    █ ▓█████  ▒█████   ██▒   █▓ ██▓ ███▄ ▄███▓
 ██ ▀█   █ ▓█   ▀ ▒██▒  ██▒▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██  ▀█ ██▒▒███   ▒██░  ██▒ ▓██  █▒░▒██▒▓██    ▓██░
▓██▒  ▐▌██▒▒▓█  ▄ ▒██   ██░  ▒██ █░░░██░▒██    ▒██
▒██░   ▓██░░▒████▒░ ████▓▒░   ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ▒ ▒ ░░ ▒░ ░░ ▒░▒░▒░    ░ ▐░  ░▓  ░ ▒░   ░  ░
░ ░░   ░ ▒░ ░ ░  ░  ░ ▒ ▒░    ░ ░░   ▒ ░░  ░      ░
   ░   ░ ░    ░   ░ ░ ░ ▒       ░░   ▒ ░░      ░
         ░    ░  ░    ░ ░        ░   ░         ░
                                ░
                  ]],

                },
                -- formats = {
                --     key = function(item)
                --         return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
                --     end,
                -- },

                sections = {
                    { section = "header", gap = 2 },

                    { section = "keys", gap = 1, padding = 1 },
                    { pane = 1, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1, limit = 5 },
                    -- { pane = 1, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 2 },
                    { section = "startup" },
                    should_show_image() and {
                        {
                            section = "terminal",
                            cmd = "cat /home/for/.cache/nvim/chafa/samurai_logo_doom.txt; sleep .1",
                            -- cmd = "cat /home/for/.cache/nvim/chafa/samurai_logo_all.txt",
                            ------------------------------------------------------------------------------------------------------
                            -- cmd = "chafa /home/for/Pictures/logo/samurai_logo_blue_bis.png --symbols all --size 50; sleep 10",
                            -- cmd = "chafa /home/for/Pictures/samurai_logo_blue_bis.png --symbols sextant --size 50; sleep .1",
                            -- cmd = "chafa /home/for/Pictures/samurai_logo_gray.png --symbols all --size 55; sleep .1",
                            ------------------------------------------------------------------------------------------------------
                            pane = 2,
                            -- indent = 4,
                            height = 35,
                        }
                    },
                },
            },
        },



        keys = {

            -- Picker (other)
            { "<leader>:",  function() Snacks.picker.command_history() end,              desc = "Command History" },
            { "<leader>fn", function() Snacks.picker.notifications({ wrap = true }) end, desc = "Notification History" },
            { "<leader>un", function() Snacks.notifier.hide() end,                       desc = "Dismiss All Notifications" },
            -- { "<leader>e",  function() Snacks.explorer() end,                            desc = "File Explorer" }, -- ~~~~~~~~~~~~~~~ <leader>E correspond à mini.files (explorer flottant) ~~~~~~~~~~~~~~~~~~

            -- Picker (file)
            { "<leader>ff", function() Snacks.picker.files() end,                        desc = "Picker Find Files" },
            { "<leader>fa", function() Snacks.picker.lsp_workspace_symbols() end,        desc = "LSP Workspace Symbols" },
            { "<leader>ga", function() Snacks.picker.lsp_workspace_symbols() end,        desc = "LSP Workspace Symbols" },
            { "<leader>fk", function() Snacks.picker.keymaps() end,                      desc = "Keymaps" },
            { "<leader>fp", function() Snacks.picker.projects() end,                     desc = "Projects" },

            -- Picker (Git)
            { "<leader>fb", function() Snacks.gitbrowse() end,                           desc = "Git Browse" },
            { "<leader>fc", function() Snacks.picker.git_log_file() end,                 desc = "Git Commit File" },
            { "<leader>fC", function() Snacks.picker.git_log() end,                      desc = "Git Commit Files" },
            { "<leader>fh", function() Snacks.picker.git_diff() end,                     desc = "Git Diff (Hunks)" },
            { "<leader>lg", function() Snacks.lazygit() end,                             desc = "Lazygit" },

            -- Picker (Diagnostics)
            { "<leader>ds", function() Snacks.picker.diagnostics() end,                  desc = "Diagnostics" },


            -- { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },

            -- Terminal
            -- { "<c-ù>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
            -- {
            --     "<leader>N",
            --     desc = "Neovim News",
            --     function()
            --         Snacks.win({
            --             file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
            --             width = 0.6,
            --             height = 0.6,
            --             wo = {
            --                 spell = false,
            --                 wrap = false,
            --                 -- signcolumn = "yes",
            --                 statuscolumn = " ",
            --                 conceallevel = 3,
            --             },
            --         })
            --     end,
            -- }
        },
        init = function()
            Snacks = require("snacks")


            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    -- Setup some globals for debugging (lazy-loaded)
                    _G.dd = function(...)
                        Snacks.debug.inspect(...)
                    end
                    _G.bt = function()
                        Snacks.debug.backtrace()
                    end
                    vim.print = _G.dd -- Override print to use snacks for `:=` command

                    -- Create some toggle mappings
                    Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
                    Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
                    Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
                    Snacks.toggle.diagnostics():map("<leader>ud")
                    Snacks.toggle.line_number():map("<leader>ul")
                    Snacks.toggle.option("conceallevel",
                        { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
                    Snacks.toggle.treesitter():map("<leader>uT")
                    Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map(
                        "<leader>ub")
                    Snacks.toggle.inlay_hints():map("<leader>uh")
                end,
            })
        end,
    },


    { "tpope/vim-fugitive" },

    -- {
    --     'kristijanhusak/vim-dadbod-ui',
    --     dependencies = {
    --         { 'tpope/vim-dadbod', lazy = false },
    --         -- { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql' }, lazy = true },
    --     },
    --     cmd = {
    --         'DBUI',
    --         'DBUIToggle',
    --         'DBUIAddConnection',
    --         'DBUIFindBuffer',
    --     },
    --     init = function()
    --         -- Your DBUI configuration
    --         vim.g.db_ui_use_nerd_fonts = 1
    --
    --         vim.g.db = 'postgresql://noah@localhost/db_test'
    --
    --             -- Mapping personnalisé pour exécuter dans le buffer courant
    --         vim.api.nvim_create_autocmd('FileType', {
    --             pattern = { 'sql', 'mysql', 'plsql' },
    --             callback = function()
    --                 vim.keymap.set('n', '<Leader>S', '<Plug>(DBUI_ExecuteQuery)', { buffer = true })
    --                 vim.keymap.set('v', '<Leader>S', '<Plug>(DBUI_ExecuteQuery)', { buffer = true })
    --             end,
    --         })
    --
    --         -- vim.g.dbs = {
    --         --     dev = 'postgresql://username:password@localhost:5432/dbname',
    --         --     -- Ajoutez d'autres connexions si nécessaire
    --         -- }
    --
    --         -- -- Charger les connexions depuis un fichier séparé
    --         -- local db_config = vim.fn.stdpath('config') .. '/db_connections.lua'
    --         -- if vim.fn.filereadable(db_config) == 1 then
    --         --     dofile(db_config)
    --         -- end
    --         -- vim.g.db_ui_save_location = vim.fn.stdpath('config') .. '/db_ui'
    --
    --         --[[
    --         Créez ~/.config/nvim/db_connections.lua :
    --         -- Ce fichier ne doit PAS être versionné (ajoutez-le au .gitignore)
    --         vim.g.db = 'postgresql://noah@localhost/db_test'
    --
    --         vim.g.dbs = {
    --             dev = 'postgresql://noah:password@localhost/db_test',
    --             prod = 'postgresql://noah:password@prod.example.com/production',
    --         }
    --
    --         ]]
    --
    --     end,
    -- },
    {
        'kristijanhusak/vim-dadbod-ui',
        dependencies = {
            { 'tpope/vim-dadbod', lazy = false },
        },
        cmd = {
            'DBUI',
            'DBUIToggle',
            'DBUIAddConnection',
            'DBUIFindBuffer',
        },
        init = function()
            vim.g.db_ui_use_nerd_fonts = 1
            -- vim.g.db = 'postgresql://noah@localhost/db_test'
            vim.g.db_ui_win_position = 'left'
            vim.g.db_ui_winwidth = 30
            vim.g.dbs = {
                { name = 'projet_local', url = 'postgresql://noah@localhost/db_test' },
                { name = 'tp_select_local', url = 'postgresql://noah@localhost/db_tp_select' },
            }
            -- vim.g.db_ui_show_notifications = 0
        end,
        config = function()
            local function close_dbout_window()
                local wins = vim.api.nvim_list_wins()
                for _, win in ipairs(wins) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local filetype = vim.bo[buf].filetype
                    if filetype == 'dbout' then
                        vim.api.nvim_win_close(win, false)
                        return true
                    end
                end
                return false
            end


            local function save_dbout_to_buffer()
                -- Chercher la fenêtre dbout
                local dbout_win = nil
                local wins = vim.api.nvim_list_wins()

                for _, win in ipairs(wins) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    local filetype = vim.bo[buf].filetype
                    if filetype == 'dbout' then
                        dbout_win = win
                        break
                    end
                end

                if not dbout_win then
                    vim.notify('No dbout window found', vim.log.levels.INFO)
                    return
                end

                -- Sauvegarder la fenêtre actuelle
                local original_win = vim.api.nvim_get_current_win()

                -- Aller à la fenêtre dbout
                vim.api.nvim_set_current_win(dbout_win)

                -- Créer le fichier temporaire
                local filename = "/tmp/dbout_" .. os.date('%H%M%S') .. ".txt"
                vim.cmd("w " .. filename)

                -- Fermer la fenêtre dbout
                vim.api.nvim_win_close(dbout_win, false)

                -- Revenir à la fenêtre originale et ouvrir le fichier
                vim.api.nvim_set_current_win(original_win)
                vim.cmd("edit " .. filename)
                vim.bo.buflisted = true

                -- vim.notify('DBout saved to: ' .. filename, vim.log.levels.INFO)
                vim.cmd("only")
            end

            -- Remplacer le mapping <leader>S original
            vim.keymap.set('n', '<leader>L', function()
                -- Exécuter la requête SQL (commande originale de dbui)
                vim.cmd('DB')

                -- Attendre un peu que le résultat soit affiché puis sauvegarder
                vim.defer_fn(function()
                    save_dbout_to_buffer()
                end, 2000)
            end, { desc = 'Execute query and save to buffer' })



            vim.keymap.set('n', '<leader>R', function()
                if not close_dbout_window() then
                    vim.notify('No dbout window found', vim.log.levels.INFO)
                end
            end, { desc = 'Close dbout result window' })

            vim.keymap.set('n', '<leader>dc', function()
                if not close_dbout_window() then
                    vim.notify('No dbout window found', vim.log.levels.INFO)
                end
            end, { desc = 'Close dbout result window' })

            vim.keymap.set('n', '<leader>b', save_dbout_to_buffer, { desc = 'Save dbout to buffer' })

        end,
        keys = {
            { '<leader>db', '<cmd>DBUIToggle<cr>', desc = 'Toggle DBUI' },
            { '<leader>df', '<cmd>DBUIFindBuffer<cr>', desc = 'DBUI Find Buffer' },
        },
    },



    -- Lua
    { "shortcuts/no-neck-pain.nvim" },

    -- Lua
    {
        "folke/zen-mode.nvim",
        opts = {
            window = {
                backdrop = 0.95, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
                -- height and width can be:
                -- * an absolute number of cells when > 1
                -- * a percentage of the width / height of the editor when <= 1
                -- * a function that returns the width or the height
                width = 120, -- width of the Zen window
                height = 1,  -- height of the Zen window
                -- by default, no options are changed for the Zen window
                -- uncomment any of the options below, or add other vim.wo options you want to apply
                options = {
                    -- signcolumn = "no", -- disable signcolumn
                    -- number = false, -- disable number column
                    -- relativenumber = false, -- disable relative numbers
                    -- cursorline = false, -- disable cursorline
                    -- cursorcolumn = false, -- disable cursor column
                    -- foldcolumn = "0", -- disable fold column
                    -- list = false, -- disable whitespace characters
                },
            },
            plugins = {
                options = {
                    enabled = true,
                    ruler = false,   -- disables the ruler text in the cmd line area
                    showcmd = false, -- disables the command in the last line of the screen
                    -- you may turn on/off statusline in zen mode by setting 'laststatus'
                    -- statusline will be shown only if 'laststatus' == 3
                    laststatus = 3,
                },
                -- twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
                gitsigns = { enabled = true },
                -- tmux = { enabled = false },
                -- todo = { enabled = false },
                alacritty = {
                    enabled = false,
                    font = "14",
                },
            },
            -- callback where you can add custom code when the Zen window opens
            on_open = function(win)
            end,
            -- callback where you can add custom code when the Zen window closes
            on_close = function()
            end,
        }
    },

    {
        'williamboman/mason.nvim',
        lazy = false,
        config = true,
    },
    {
        "xzbdmw/colorful-menu.nvim",
        config = function()
            -- You don't need to set these options.
            require("colorful-menu").setup({
                ls = {
                    lua_ls = {
                        -- Maybe you want to dim arguments a bit.
                        arguments_hl = "@comment",
                    },
                    gopls = {
                        -- By default, we render variable/function's type in the right most side,
                        -- to make them not to crowd together with the original label.

                        -- when true:
                        -- foo             *Foo
                        -- ast         "go/ast"

                        -- when false:
                        -- foo *Foo
                        -- ast "go/ast"
                        align_type_to_right = true,
                        -- When true, label for field and variable will format like "foo: Foo"
                        -- instead of go's original syntax "foo Foo". If align_type_to_right is
                        -- true, this option has no effect.
                        add_colon_before_type = false,
                        -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
                        preserve_type_when_truncate = true,
                    },
                    -- for lsp_config or typescript-tools
                    ts_ls = {
                        -- false means do not include any extra info,
                        -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
                        extra_info_hl = "@comment",
                    },
                    vtsls = {
                        -- false means do not include any extra info,
                        -- see https://github.com/xzbdmw/colorful-menu.nvim/issues/42
                        extra_info_hl = "@comment",
                    },
                    ["rust-analyzer"] = {
                        -- Such as (as Iterator), (use std::io).
                        extra_info_hl = "@comment",
                        -- Similar to the same setting of gopls.
                        align_type_to_right = true,
                        -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
                        preserve_type_when_truncate = true,
                    },
                    clangd = {
                        -- Such as "From <stdio.h>".
                        extra_info_hl = "@comment",
                        -- Similar to the same setting of gopls.
                        align_type_to_right = true,
                        -- the hl group of leading dot of "•std::filesystem::permissions(..)"
                        import_dot_hl = "@comment",
                        -- See https://github.com/xzbdmw/colorful-menu.nvim/pull/36
                        preserve_type_when_truncate = true,
                    },
                    zls = {
                        -- Similar to the same setting of gopls.
                        align_type_to_right = true,
                    },
                    roslyn = {
                        extra_info_hl = "@comment",
                    },
                    dartls = {
                        extra_info_hl = "@comment",
                    },
                    -- The same applies to pyright/pylance
                    basedpyright = {
                        -- It is usually import path such as "os"
                        extra_info_hl = "@comment",
                    },
                    -- If true, try to highlight "not supported" languages.
                    fallback = true,
                    -- this will be applied to label description for unsupport languages
                    fallback_extra_info_hl = "@comment",
                },
                -- If the built-in logic fails to find a suitable highlight group for a label,
                -- this highlight is applied to the label.
                fallback_highlight = "@variable",
                -- If provided, the plugin truncates the final displayed text to
                -- this width (measured in display cells). Any highlights that extend
                -- beyond the truncation point are ignored. When set to a float
                -- between 0 and 1, it'll be treated as percentage of the width of
                -- the window: math.floor(max_width * vim.api.nvim_win_get_width(0))
                -- Default 60.
                max_width = 60,
            })
        end,
    },




    {
            "saghen/blink.cmp",
            -- build = 'cargo build --release',
            enabled = true, --------------------------------------------------------------------------------------------------------------------------------
            dependencies = {
                "moyiz/blink-emoji.nvim",

                "hrsh7th/nvim-cmp",
                -- { "kristijanhusak/vim-dadbod-completion", ft = { 'sql', 'mysql', 'plsql' } },

                {
                    "windwp/nvim-autopairs",
                    opts = {
                        fast_wrap = {},
                        disable_filetype = { "TelescopePrompt", "vim" },
                    },
                    config = function(_, opts)
                        require("nvim-autopairs").setup(opts)

                        -- setup cmp for autopairs
                        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
                        require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done)
                    end,
                },
                { 'L3MON4D3/LuaSnip',            version = 'v2.*' }, -- utiliser uniquement pour fichier .tex
                { "rafamadriz/friendly-snippets" },



            },

            opts = function(_, opts)

                opts.enabled = function()
                    local filetype = vim.bo[0].filetype
                    if filetype == "TelescopePrompt" or filetype == "minifiles" or filetype == "snacks_picker_input" then
                        return false
                    end
                    return true
                end

                opts.sources = vim.tbl_deep_extend("force", opts.sources or {}, {
                    default = { "lsp", "path", "snippets", "buffer", "cmdline" },
                    -- per_filetype = {
                    --     sql = { 'dadbod', 'buffer', 'path' }, -- dadbod en premier pour la priorité
                    -- },
                    providers = {
                        lsp = {
                            name = "lsp",
                            enabled = true,
                            module = "blink.cmp.sources.lsp",
                            -- min_keyword_length = 1,
                            score_offset = 90, -- the higher the number, the higher the priority
                        },
                        path = {
                            name = "Path",
                            module = "blink.cmp.sources.path",
                            score_offset = 35,
                            fallbacks = { "buffer" },
                            -- min_keyword_length = 1,
                            opts = {
                                trailing_slash = true,
                                label_trailing_slash = true,
                                get_cwd = function(context)
                                    return vim.fn.expand(("#%d:p:h"):format(context.bufnr))
                                end,
                                show_hidden_files_by_default = true,
                            },

                        },
                        buffer = {
                            name = "Buffer",
                            enabled = true,
                            max_items = 4,
                            module = "blink.cmp.sources.buffer",
                            -- score_offset = 16, -- the higher the number, the higher the priority
                            score_offset = 20,
                            -- min_keyword_length = 1,
                        },

                        -- dadbod = {
                        --     name = "Dadbod",
                        --     module = "vim_dadbod_completion.blink",
                        --     score_offset = 50, -- the higher the number, the higher the priority
                        --     max_items = 10,
                        -- },

                        snippets = {
                            name = "snippets",
                            score_offset = 25, -- the higher the number, the higher the priority
                            max_items = 4,
                            enabled = function()
                                local ft = vim.bo.filetype
                                return ft == "tex" -- or ft == "sql"
                            end,
                        },

                        cmdline = {
                            -- min_keyword_length = 1,
                        }

                    },
                })


                -- Experimental signature help support

                opts.signature = {
                    enabled = true,
                    trigger = {
                        -- Show the signature help automatically
                        enabled = true,
                        -- Show the signature help window after typing any of alphanumerics, `-` or `_`
                        show_on_keyword = true,
                        blocked_trigger_characters = {},
                        blocked_retrigger_characters = {},
                        -- Show the signature help window after typing a trigger character
                        show_on_trigger_character = true,
                        -- Show the signature help window when entering insert mode
                        show_on_insert = true,
                        -- Show the signature help window when the cursor comes after a trigger character when entering insert mode
                        show_on_insert_on_trigger_character = true,
                    },
                    window = {
                        min_width = 1,
                        max_width = 100,
                        max_height = 10,
                        border = 'single',
                        winblend = 0,
                        winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder',
                        scrollbar = false, -- Note that the gutter will be disabled when border ~= 'none'
                        -- Which directions to show the window,
                        -- falling back to the next direction when there's not enough space,
                        -- or another window is in the way
                        -- direction_priority = { 's', 'e' },
                        direction_priority = { 's' },
                        -- Disable if you run into performance issues
                        treesitter_highlighting = true,
                        show_documentation = false,
                    },
                }

                opts.cmdline = {
                    enabled = true,

                    keymap = {
                        -- preset = 'inherit',
                        -- ['<Esc>'] = { 'hide' }, -- marche mais je peux plus quitter la cmdline ...
                        ["<Tab>"] = { "select_and_accept" },  -- Tab accepte la première suggestion
                        ["<S-Tab>"] = { "select_prev", "fallback" },
                        ['<Down>'] = { 'select_next', 'fallback' },
                        ['<Up>'] = { 'select_prev', 'fallback' },

                    },
                    completion = {
                        trigger = {
                            -- Ne pas bloquer le caractère "/" comme déclencheur

                            show_on_blocked_trigger_characters = {},
                            show_on_x_blocked_trigger_characters = {},
                        },
                        menu = { 
                            auto_show = function(ctx, _) 
                                if ctx.mode == 'cmdwin' then
                                    return true
                                end
                                if ctx.mode == 'cmdline' then
                                    local cmdline = vim.fn.getcmdline()

                                    -- Ne pas afficher pour les commandes simples de base
                                    local simple_cmds = { "^q!?$", "^w!?$", "^wq!?$", "^x!?$", "^qa!?$", "^wqa!?$" }
                                    for _, pattern in ipairs(simple_cmds) do
                                        if cmdline:match(pattern) then
                                            return false
                                        end
                                    end

                                    -- Afficher dès qu'on commence à taper
                                    return #cmdline > 0
                                end
                                return false
                            end 
                        },
                        list = {
                            selection = {
                                preselect = true,
                                auto_insert = false,  -- Attendre Tab pour accepter
                            },
                        },
                        ghost_text = { enabled = false },
                    }
                }


                opts.completion = {

                    trigger = {
                        show_on_trigger_character = true,
                    },

                    accept = {
                        auto_brackets = {
                            enabled = true,
                            default_brackets = { '(', ')' },
                            -- Overrides the default blocked filetypes
                            override_brackets_for_filetypes = {},
                            kind_resolution = {
                                enabled = true,
                                blocked_filetypes = { 'typescriptreact', 'javascriptreact', 'vue', 'typescript', 'javascript' },
                            },
                            -- Asynchronously use semantic token to determine if brackets should be added
                            semantic_token_resolution = {
                                enabled = true,
                                blocked_filetypes = { 'java' },
                                timeout_ms = 400,
                            },
                        },
                    },

                    keyword = {
                        -- 'prefix' will fuzzy match on the text before the cursor
                        -- 'full' will fuzzy match on the text before *and* after the cursor
                        -- example: 'foo_|_bar' will match 'foo_' for 'prefix' and 'foo__bar' for 'full'
                        range = "full",
                    },
                    menu = {
                        border = "single",

                        -- vim.api.nvim_set_hl(0, "BlinkCmpSignatureHelp", {
                        --     fg = "#ffffff",  -- Couleur du texte (premier plan)
                        --     bg = "#ff0000",  -- Couleur de fond
                        --     bold = true,     -- Appliquer un texte en gras
                        -- }),

                        winhighlight =
                        'Normal:BlinkCmpLabel,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None',

                        draw = {
                            treesitter = { "lsp" },
                            columns = { { "kind_icon" }, { "label", gap = 1 } },
                            -- components = {
                            --     label = {
                            --         text = function(ctx)
                            --             return require("colorful-menu").blink_components_text(ctx)
                            --         end,
                            --         highlight = function(ctx)
                            --             return require("colorful-menu").blink_components_highlight(ctx)
                            --         end,
                            --     },
                            -- },

                            components = {
                                label = {
                                    text = function(ctx)
                                        return require("colorful-menu").blink_components_text(ctx)
                                    end,
                                    highlight = function(ctx)
                                        -- Récupération des highlights de colorful-menu
                                        local highlights = require("colorful-menu").blink_components_highlight(ctx) or {}

                                        -- Ajout du surlignage pour les caractères correspondants au fuzzy matching (à la fin)

                                        -- vim.api.nvim_set_hl(0, "MyErrorMsg", { fg = "#f38ba8", bold = true })
                                        -- vim.api.nvim_set_hl(0, "MyInfoMsg", { fg = "#94e2d5", bold = true })
                                        --
                                        -- for _, idx in ipairs(ctx.label_matched_indices or {}) do
                                        --     table.insert(highlights, { idx, idx + 1, group = 'MyErrorMsg' }) -- Vérifier si ça force le changement
                                        -- end


                                        return highlights
                                    end,
                                },
                            },



                        },
                    },


                    -- Définition du groupe de surlignage pour les lettres correspondant au fuzzy matcher
                    vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch",
                        { fg = "#ffffff", bg = "#ffff00", bold = true, underline = true }),

                    list = {
                        selection = {
                            preselect = true,
                            auto_insert = true,
                        },


                    },


                    documentation = {
                        auto_show = false,
                        window = {
                            border = "single",
                            winhighlight = 'Normal:NormalFloat,FloatBorder:WarningMsg',
                        },
                    },
                    -- Displays a preview of the selected item on the current line
                    ghost_text = {
                        enabled = false,
                    },
                }

                opts.fuzzy = {
                    implementation = "prefer_rust_with_warning",

                    prebuilt_binaries = {
                        download = true,
                        ignore_version_mismatch = false,
                        force_version = nil,
                        force_system_triple = nil,
                        extra_curl_args = {}
                    },
                }

                opts.keymap = {
                    preset = "none",
                    ["<Tab>"] = { 
                        function(cmp)
                            if cmp.snippet_active() then
                                return cmp.snippet_forward()
                            else
                                return cmp.select_and_accept()
                            end
                        end,
                        "fallback" 
                    },
                    ["<S-Tab>"] = { "snippet_backward", "fallback" },
                    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                    ['<Up>'] = { 'select_prev', 'fallback' },
                    ['<Down>'] = { 'select_next', 'fallback' },
                    ['<C-w>'] = { 'select_prev', 'fallback_to_mappings' },
                    ['<C-x>'] = { 'select_next', 'fallback_to_mappings' },
                    ['<C-p>'] = { 'select_prev', 'fallback_to_mappings' },
                    ['<C-n>'] = { 'select_next', 'fallback_to_mappings' },
                }


                return opts
            end,
        },




        {"nanotee/sqls.nvim"},

        -- REFONTE DE MA CONFIG LSP

        {
            'neovim/nvim-lspconfig',
            dependencies = {
                'williamboman/mason.nvim',
                'williamboman/mason-lspconfig.nvim',
                'saghen/blink.cmp',
                'ray-x/lsp_signature.nvim',
            },
            event = { 'BufReadPre', 'BufNewFile', 'VimEnter' },

            opts = {
                servers = {
                    lua_ls = {
                        settings = {
                            Lua = {
                                workspace = { checkThirdParty = false },
                                telemetry = { enable = false },
                            },
                        },
                    },

                    clangd = {
                        cmd = { "clangd", "--background-index" },
                        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
                        root_dir = vim.fs.dirname(vim.fs.find({
                            'compile_commands.json', '.clangd', '.git'
                        }, { upward = true })[1]),
                    },

                    texlab = {
                        filetypes = { "tex", "bib" },
                    },

                    ts_ls = {

                    },

                    jdtls = {
                        filetypes = { "java" },
                        root_dir = vim.fs.dirname(vim.fs.find({
                            'pom.xml', 'build.gradle', '.git'
                        }, { upward = true })[1]),
                        settings = {
                            java = {
                                signatureHelp = { enabled = true };
                            }
                        }
                    },

                    -- sqls = {
                    --
                    -- }

                    sqls = (function()

                        -- ============================================================================================================================
                        -- TOUJOURS mettre un fichier config.yml au root du projet (cf template ~/.config/sqls/config.yml), ex sans mdp:
                        --[[ 
                        connections:
                          - alias: db_test
                            driver: postgresql
                            proto: tcp
                            host: localhost
                            port: 5432
                            user: noah
                            dbName: db_test
                            params:
                              sslmode: disable
                        ]]

                        -- ============================================================================================================================

                        local config_path = "config.yml"

                        -- Vérifie que le fichier existe
                        if vim.fn.filereadable(config_path) == 0 then
                            vim.notify("Fichier SQLs config non trouvé : " .. config_path .. ", le LSP utilisera la config globale", vim.log.levels.WARN)
                            config_path = nil -- laisse sqls utiliser la config par défaut
                        end

                        return {
                            cmd = (config_path ~= nil) and { "sqls", "--config", config_path } or { "sqls" },
                            filetypes = { "sql" },
                            single_file_support = true,
                            -- root_dir = project_root,
                        }
                    end)()

                },

            },

            config = function(_, opts)
                local signature = require('lsp_signature')
                local capabilities_base = require('blink.cmp').get_lsp_capabilities()

                --  Fonction utilitaire : capabilities dynamiques selon le type de fichier
                local function get_capabilities_for_server(server_name)
                    local enable_snippets = (server_name == "texlab")
                    return require('blink.cmp').get_lsp_capabilities({
                        textDocument = {
                            completion = { completionItem = { snippetSupport = enable_snippets } },
                        },
                    })
                end

                -- on_attach commun
                local function on_attach(client, bufnr)
                    local opts = { noremap = true, silent = true, buffer = bufnr }

                    vim.keymap.set('n', '<leader>gh', vim.lsp.buf.hover, opts)
                    vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, opts)
                    vim.keymap.set('n', '<leader>gr', '<cmd>Telescope lsp_references<cr>', opts)
                    vim.keymap.set('n', '<leader>gl', '<cmd>Trouble lsp toggle focus=true<cr>', opts)

                    signature.on_attach({
                        bind = true,
                        handler_opts = { border = "rounded" },
                        floating_window = false,
                        hint_enable = false,
                    }, bufnr)
                end

                -- Setup Mason
                require('mason').setup()
                require('mason-lspconfig').setup({
                    ensure_installed = vim.tbl_keys(opts.servers),
                    automatic_installation = true,
                })


                -- Configurer chaque serveur via la nouvelle API
                for name, config in pairs(opts.servers) do
                    vim.lsp.config[name] = vim.tbl_deep_extend("force", config, {
                        on_attach = on_attach,
                        capabilities = get_capabilities_for_server(name),
                    })
                end

            end,
        }



})
