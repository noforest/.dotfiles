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
    local ui = vim.api.nvim_list_uis()[1]  -- Récupère les dimensions du terminal
    return ui and ui.width > 50 and ui.height > 40  -- Ajuste ces valeurs selon tes besoins
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

  {
    'nvim-telescope/telescope.nvim',
    -- tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require('telescope.actions.state')
      local bufferline = require('bufferline')
      local sorters = require('telescope.sorters')
      local devicons = require("nvim-web-devicons")
      local entry_display = require("telescope.pickers.entry_display")

      telescope.setup({
        file_ignore_patterns = { "%.git/." },
        defaults = {
          mappings = {
            i = {
              ["<Tab>"] = actions.select_default,
            },
            n = {
              ["<Tab>"] = actions.select_default,
            }
          },
          path_display = {
            "filename_first",

          },
          -- previewer = true,
          file_ignore_patterns = { "node_modules", "package-lock.json" },
          initial_mode = "insert",
          select_strategy = "reset",
          sorting_strategy = "ascending",
          color_devicons = true,
          set_env = { ["COLORTERM"] = "truecolor" }, -- default = nil,
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

        },
        pickers = {
          find_files = {
            -- previewer = false,
            -- path_display = formattedName,
            sort_mru = true,
            layout_config = {
              -- height = 0.4,
              prompt_position = "top",
              preview_cutoff = 120,
            },

            mappings = {
                i = {
                    ["<C-up>"] = function(prompt_bufnr)
                        local current_picker =
                        require("telescope.actions.state").get_current_picker(prompt_bufnr)
                        -- cwd is only set if passed as telescope option
                        local cwd = current_picker.cwd and tostring(current_picker.cwd)
                        or vim.loop.cwd()
                        local parent_dir = vim.fs.dirname(cwd)

                        require("telescope.actions").close(prompt_bufnr)
                        require("telescope.builtin").find_files {
                            prompt_title = vim.fs.basename(parent_dir),
                            cwd = parent_dir,
                        }
                    end,
                },
            },
          },
          git_files = {
            -- previewer = false,
            -- path_display = formattedName,
            layout_config = {
              -- height = 0.4,
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
            -- theme = "dropdown",
            layout_config = {
              height = 0.4,
              width = 0.6,
              prompt_position = "top",
              preview_cutoff = 120,
            },
            sort_mru = true;
            ignore_current_buffer = true, -- Ignorer le buffer actif
          },
          current_buffer_fuzzy_find = {
            previewer = true,
            layout_config = {
              prompt_position = "top",
              preview_cutoff = 120,
            },
          },

          -- *************** VERSION AVC CHEMIN MAIS quand meme fichiers ************************ 
          live_grep = (function()
              local filename_registry = {}

              return {
                  attach_mappings = function(_, map)
                      filename_registry = {}
                      vim.schedule(function()
                          -- Création des highlights si non existants
                          vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
                          vim.api.nvim_set_hl(0, "TelescopeMatching", {})
                      end)
                      return true
                  end,

                  entry_maker = function(line)
                      local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
                      if not filename then return end

                      local full_path = vim.fn.fnamemodify(filename, ":p")
                      local basename = vim.fn.fnamemodify(full_path, ":t")
                      local dir_path = vim.fn.fnamemodify(full_path, ":h")
                      local relative_dir = vim.fn.fnamemodify(dir_path, ":~:.") .. "/"

                      -- Gestion des doublons
                      if not filename_registry[basename] then
                          filename_registry[basename] = {
                              dirs = { [dir_path] = true },
                              count = 1
                          }
                      else
                          if not filename_registry[basename].dirs[dir_path] then
                              filename_registry[basename].count = filename_registry[basename].count + 1
                              filename_registry[basename].dirs[dir_path] = true
                          end
                      end

                      local show_path = filename_registry[basename].count > 1
                      local icon, icon_hl = require("nvim-web-devicons").get_icon(basename, nil, { default = true })
                      icon = icon or ""
                      icon_hl = icon_hl or "DevIconDefault" -- Fallback si nil

                      local icon_width = vim.fn.strwidth(icon)
                      local dir_width = vim.fn.strwidth(relative_dir)

                      return {
                          value = line,
                          ordinal = basename .. " " .. text,
                          display = function()
                              local display_text = icon .. " "
                              local highlights = {}

                              -- Highlight pour l'icône
                              table.insert(highlights, {
                                  { 0, icon_width + 1 },
                                  icon_hl
                              })

                              if show_path then
                                  display_text = display_text .. relative_dir
                                  -- Highlight pour le chemin
                                  table.insert(highlights, {
                                      { icon_width + 2, icon_width + 2 + dir_width },
                                      "TelescopePathSeparator"
                                  })
                              end

                              display_text = display_text .. basename

                              return display_text, highlights
                          end,
                          filename = filename,
                          lnum = tonumber(lnum),
                          col = tonumber(col)
                      }
                  end
              }
          end)(),


          grep_string = (function()
              local filename_registry = {}

              return {
                  attach_mappings = function(_, map)
                      filename_registry = {}
                      vim.schedule(function()
                          -- Création des highlights si non existants
                          vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
                          -- vim.api.nvim_set_hl(0, "DevIconDefault", { fg = "#FFFFFF" })
                          vim.api.nvim_set_hl(0, "TelescopeMatching", {})
                      end)
                      return true
                  end,

                  entry_maker = function(line)
                      local filename, lnum, col, text = line:match("^(.-):(%d+):(%d+):(.*)$")
                      if not filename then return end

                      local full_path = vim.fn.fnamemodify(filename, ":p")
                      local basename = vim.fn.fnamemodify(full_path, ":t")
                      local dir_path = vim.fn.fnamemodify(full_path, ":h")
                      local relative_dir = vim.fn.fnamemodify(dir_path, ":~:.") .. "/"

                      -- Gestion des doublons
                      if not filename_registry[basename] then
                          filename_registry[basename] = {
                              dirs = { [dir_path] = true },
                              count = 1
                          }
                      else
                          if not filename_registry[basename].dirs[dir_path] then
                              filename_registry[basename].count = filename_registry[basename].count + 1
                              filename_registry[basename].dirs[dir_path] = true
                          end
                      end

                      local show_path = filename_registry[basename].count > 1
                      local icon, icon_hl = require("nvim-web-devicons").get_icon(basename, nil, { default = true })
                      icon = icon or ""
                      icon_hl = icon_hl or "DevIconDefault" -- Fallback si nil

                      local icon_width = vim.fn.strwidth(icon)
                      local dir_width = vim.fn.strwidth(relative_dir)

                      return {
                          value = line,
                          ordinal = basename .. " " .. text,
                          display = function()
                              local display_text = icon .. " "
                              local highlights = {}

                              -- Highlight pour l'icône
                              table.insert(highlights, {
                                  { 0, icon_width + 1 },
                                  icon_hl
                              })

                              if show_path then
                                  display_text = display_text .. relative_dir
                                  -- Highlight pour le chemin
                                  table.insert(highlights, {
                                      { icon_width + 2, icon_width + 2 + dir_width },
                                      "TelescopePathSeparator"
                                  })
                              end

                              display_text = display_text .. basename

                              return display_text, highlights
                          end,
                          filename = filename,
                          lnum = tonumber(lnum),
                          col = tonumber(col)
                      }
                  end
              }
          end)(),


          -- *********** SANS CHEMIN GRIS *********************
          -- grep_string = {
          --     -- Désactiver le surlignage
          --     attach_mappings = function(_, map)
          --         vim.schedule(function()
          --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
          --         end)
          --         return true
          --     end,
          --     only_sort_text = true,
          --     previewer = true,
          --     entry_maker = function(line)
          --         -- line au format : "filepath:line:col:text"
          --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
          --         local basename = filename and vim.fn.fnamemodify(filename, ":t") or line
          --
          --         local icon, icon_hl = devicons.get_icon(basename, nil, { default = true })
          --
          --         local displayer = entry_display.create({
          --             separator = " ",
          --             items = {
          --                 { width = 2 }, -- icône
          --                 { remaining = true }, -- filename
          --             },
          --         })
          --
          --         return {
          --             value = line,
          --             ordinal = basename,
          --             display = function(entry)
          --                 return displayer({
          --                     { icon, icon_hl },
          --                     basename,
          --                 })
          --             end,
          --             filename = filename,
          --             lnum = lnum and tonumber(lnum) or nil,
          --             col = col and tonumber(col) or nil,
          --             __line = line,
          --         }
          --     end,
          --
          -- },

          -- **************** VERSION AVEC CHEMIN RELATIF EN GRIS ********************
          -- live_grep = {
          --     -- désactiver le surlignage
          --     attach_mappings = function(_, map)
          --         vim.schedule(function()
          --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
          --             -- Définit la couleur grise pour le chemin
          --             vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
          --         end)
          --         return true
          --     end,
          --     only_sort_text = true,
          --     previewer = true,
          --     entry_maker = function(line)
          --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
          --         local directory, filename_part = "", line
          --
          --         if filename then
          --             local relative_path = vim.fn.fnamemodify(filename, ":~:.") -- Chemin relatif
          --             directory, filename_part = relative_path:match("(.*/)([^/]+)$")
          --             if not directory then
          --                 directory = ""
          --                 filename_part = relative_path
          --             end
          --         end
          --
          --         local icon, icon_hl = devicons.get_icon(filename_part, nil, { default = true })
          --         icon = icon or ""
          --
          --         return {
          --             value = line,
          --             ordinal = filename_part,
          --             display = function(entry)
          --                 local icon_padding = icon .. " "
          --                 local display_line = icon_padding .. directory .. filename_part
          --
          --                 local highlights = {
          --                     { { 0, #icon_padding }, icon_hl }, -- Couleur de l'icône
          --                 }
          --
          --                 if #directory > 0 then
          --                     table.insert(highlights, {
          --                         { #icon_padding, #icon_padding + #directory },
          --                         "TelescopePathSeparator" -- Couleur grise pour le chemin
          --                     })
          --                 end
          --
          --                 return display_line, highlights
          --             end,
          --             filename = filename,
          --             lnum = lnum and tonumber(lnum) or nil,
          --             col = col and tonumber(col) or nil,
          --             __line = line,
          --         }
          --     end,
          -- },
          --
          -- grep_string = {
          --
          --     -- désactiver le surlignage
          --     attach_mappings = function(_, map)
          --         vim.schedule(function()
          --             vim.api.nvim_set_hl(0, "TelescopeMatching", {})
          --             -- Définit la couleur grise pour le chemin
          --             vim.api.nvim_set_hl(0, "TelescopePathSeparator", { fg = "#6C7085" })
          --         end)
          --         return true
          --     end,
          --     only_sort_text = true,
          --     previewer = true,
          --     entry_maker = function(line)
          --         local filename, lnum, col = line:match("^([^:]+):(%d+):(%d+):")
          --         local directory, filename_part = "", line
          --
          --         if filename then
          --             local relative_path = vim.fn.fnamemodify(filename, ":~:.") -- Chemin relatif
          --             directory, filename_part = relative_path:match("(.*/)([^/]+)$")
          --             if not directory then
          --                 directory = ""
          --                 filename_part = relative_path
          --             end
          --         end
          --
          --         local icon, icon_hl = devicons.get_icon(filename_part, nil, { default = true })
          --         icon = icon or ""
          --
          --         return {
          --             value = line,
          --             ordinal = filename_part,
          --             display = function(entry)
          --                 local icon_padding = icon .. " "
          --                 local display_line = icon_padding .. directory .. filename_part
          --
          --                 local highlights = {
          --                     { { 0, #icon_padding }, icon_hl }, -- Couleur de l'icône
          --                 }
          --
          --                 if #directory > 0 then
          --                     table.insert(highlights, {
          --                         { #icon_padding, #icon_padding + #directory },
          --                         "TelescopePathSeparator" -- Couleur grise pour le chemin
          --                     })
          --                 end
          --
          --                 return display_line, highlights
          --             end,
          --             filename = filename,
          --             lnum = lnum and tonumber(lnum) or nil,
          --             col = col and tonumber(col) or nil,
          --             __line = line,
          --         }
          --     end,
          --
          -- },
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
            fuzzy = true,                   -- false will only do exact matching
            override_generic_sorter = true, -- override the generic sorter
            override_file_sorter = true,    -- override the file sorter
            case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
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
    end
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




  {
    "karb94/neoscroll.nvim",
    config = function()
      require('neoscroll').setup({
        mappings = { -- Keys to be mapped to their corresponding default scrolling animation
          '<C-u>', '<C-d>',
          '<C-b>', '<C-f>',
          '<C-y>', '<C-e>',
          -- 'zt', 'zz', 'zb',
        },
        hide_cursor = false,         -- Hide cursor while scrolling
        stop_eof = true,             -- Stop at <EOF> when scrolling downwards
        respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
        cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
        easing = 'linear',           -- Default easing function
        pre_hook = nil,              -- Function to run before the scrolling animation starts
        post_hook = nil,             -- Function to run after the scrolling animation ends
        performance_mode = false,    -- Disable "Performance Mode" on all buffers.
        duration_multiplier = 0.5, -- plus rapide
        ignored_events = {           -- Events ignored while scrolling
          'WinScrolled', 'CursorMoved'
        },
      })
    end
  },

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
          set({"n", "x"}, "<leader>n", function() mc.matchAddCursor(1) end)
          set({"n", "x"}, "<leader>N", function() mc.matchAddCursor(-1) end)

          set({"n", "x"}, "<leader>s", function() mc.matchSkipCursor(1) end)
          set({"n", "x"}, "<leader>S", function() mc.matchSkipCursor(-1) end)

          -- Add and remove cursors with control + left click.
          set("n", "<c-leftmouse>", mc.handleMouse)
          set("n", "<c-leftdrag>", mc.handleMouseDrag)
          set("n", "<c-leftrelease>", mc.handleMouseRelease)

          -- Disable and enable cursors.
          set({"n", "x"}, "<c-q>", mc.toggleCursor)

          -- Mappings defined in a keymap layer only apply when there are
          -- multiple cursors. This lets you have overlapping mappings.
          mc.addKeymapLayer(function(layerSet)

              -- Select a different cursor as the main one.
              layerSet({"n", "x"}, "<left>", mc.prevCursor)
              layerSet({"n", "x"}, "<right>", mc.nextCursor)

              -- Delete the main cursor.
              layerSet({"n", "x"}, "<leader>x", mc.deleteCursor)

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
          hl(0, "MultiCursorSign", { link = "SignColumn"})
          hl(0, "MultiCursorMatchPreview", { link = "Search" })
          hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
          hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
          hl(0, "MultiCursorDisabledSign", { link = "SignColumn"})
      end
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

  {
    "lervag/vimtex",
    lazy = false, -- we don't want to lazy load VimTeX
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = "zathura"
      vim.g.maplocalleader = "ù"
      vim.g.vimtex_quickfix_mode = 0 -- enlève la fenêtre de warning à chaque fois que je compile.
    end
  },


  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',

    config = function()
      require 'nvim-treesitter.configs'.setup {
        ensure_installed = { 'lua', 'python', 'bash', 'markdown', 'markdown_inline', 'javascript', "c", "vim", "vimdoc", "query", "rust", "typescript", }, -- ou une liste des langages que tu veux
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

  {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      event = "InsertEnter",
      config = function()
          require("copilot").setup({
              panel = {
                  enabled = true,
                  auto_refresh = false,
                  keymap = {
                      jump_prev = "[[",
                      jump_next = "]]",
                      accept = "<CR>",
                      refresh = "gr",
                      open = "<M-CR>",
                  },
                  layout = {
                      position = "bottom", -- | top | left | right | horizontal | vertical
                      ratio = 0.4,
                  },
              },
              suggestion = {
                  enabled = true,
                  auto_trigger = false,
                  hide_during_completion = true,
                  debounce = 75,
                  keymap = {
                      accept = "<C-l>",
                      accept_word = false,
                      accept_line = false,
                      next = "<M-]>",
                      prev = "<M-[>",
                      dismiss = "<C-]>",
                  },
              },
              filetypes = {
                  yaml = false,
                  markdown = false,
                  help = false,
                  gitcommit = false,
                  gitrebase = false,
                  hgcommit = false,
                  svn = false,
                  cvs = false,
                  ["."] = false,
              },
              copilot_node_command = "node", -- Node.js version must be > 18.x
              server_opts_overrides = {},
          })
      end,
  },



  {
      "yetone/avante.nvim",
      event = "VeryLazy",
      lazy = false,
      version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
      opts = {
          -- add any opts here
          provider = "copilot",
          hints = { enabled = false },
          -- copilot = {
          -- }

      },
      -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
      build = "make",
      dependencies = {
          "stevearc/dressing.nvim",
          "nvim-lua/plenary.nvim",
          "MunifTanjim/nui.nvim",
          --- The below dependencies are optional,
          "echasnovski/mini.pick", -- for file_selector provider mini.pick
          "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
          "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
          "ibhagwan/fzf-lua", -- for file_selector provider fzf
          "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
          "zbirenbaum/copilot.lua", -- for providers='copilot'
          {
              -- Make sure to set this up properly if you have lazy=true
              'MeanderingProgrammer/render-markdown.nvim',
              opts = {
                  file_types = { "markdown", "Avante" },
              },
              ft = { "markdown", "Avante" },
          },
      },
  },

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


    {
        "echasnovski/mini.files",

        opts = function(_, opts)


            -- I didn't like the default mappings, so I modified them
            -- Module mappings created only inside explorer.
            -- Use `''` (empty string) to not create one.
            opts.mappings = vim.tbl_deep_extend("force", opts.mappings or {}, {
                close = "<esc>" ,
                -- Use this if you want to open several files
                go_in = "<Right>",
                -- This opens the file, but quits out of mini.files (default L)
                go_in_plus = "<CR>",
                -- I swapped the following 2 (default go_out: h)
                -- go_out_plus: when you go out, it shows you only 1 item to the right
                -- go_out: shows you all the items to the right
                go_out = "H",
                go_out_plus = "<Left>",
                -- Default <BS>
                reset = "<BS>",
                -- Default @
                reveal_cwd = ".",
                show_help = "g?",
                -- Default =
                synchronize = "s",
                trim_left = "<",
                trim_right = ">",

                -- Below I created an autocmd with the "," keymap to open the highlighted
                -- directory in a tmux pane on the right
            })

            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesBufferCreate",
                callback = function(args)
                    vim.keymap.set("n", "<Tab>", "<Right>", { buffer = args.data.buf_id, remap = true })
                end,
            })

            -- Here I define my custom keymaps in a centralized place
            opts.custom_keymaps = {
                -- open_tmux_pane = "<M-t>",
                copy_to_clipboard = "<space>yy",
                zip_and_copy = "<space>yz",
                paste_from_clipboard = "<space>p",
                copy_path = "<M-c>",
                -- Don't use "i" as it conflicts wit insert mode
                preview_image = "<C-Right>",
                -- preview_image_popup = "<M-i>",

            }

            opts.windows = vim.tbl_deep_extend("force", opts.windows or {}, {
                preview = false,
                width_focus = 30,
                width_preview = 80,
            })

            opts.options = vim.tbl_deep_extend("force", opts.options or {}, {
                -- Whether to use for editing directories
                -- Disabled by default in LazyVim because neo-tree is used for that
                use_as_default_explorer = true,
                -- If set to false, files are moved to the trash directory
                -- To get this dir run :echo stdpath('data')
                -- ~/.local/share/neobean/mini.files/trash
                permanent_delete = false,
            })


            local nsMiniFiles = vim.api.nvim_create_namespace("mini_files_git")
            local autocmd = vim.api.nvim_create_autocmd
            local _, MiniFiles = pcall(require, "mini.files")

            -- Cache for git status
            local gitStatusCache = {}
            local cacheTimeout = 2000 -- Cache timeout in milliseconds

            ---@type table<string, {symbol: string, hlGroup: string}>
            ---@param status string
            ---@return string symbol, string hlGroup
            local function mapSymbols(status)
                local statusMap = {
                    -- stylua: ignore start 
                    [" M"] = { symbol = "•", hlGroup  = "GitSignsChange"}, -- Modified in the working directory
                    ["M "] = { symbol = "✹", hlGroup  = "GitSignsChange"}, -- modified in index
                    ["MM"] = { symbol = "≠", hlGroup  = "GitSignsChange"}, -- modified in both working tree and index
                    ["A "] = { symbol = "+", hlGroup  = "GitSignsAdd"   }, -- Added to the staging area, new file
                    ["AA"] = { symbol = "≈", hlGroup  = "GitSignsAdd"   }, -- file is added in both working tree and index
                    ["D "] = { symbol = "-", hlGroup  = "GitSignsDelete"}, -- Deleted from the staging area
                    ["AM"] = { symbol = "⊕", hlGroup  = "GitSignsChange"}, -- added in working tree, modified in index
                    ["AD"] = { symbol = "-•", hlGroup = "GitSignsChange"}, -- Added in the index and deleted in the working directory
                    ["R "] = { symbol = "→", hlGroup  = "GitSignsChange"}, -- Renamed in the index
                    ["U "] = { symbol = "‖", hlGroup  = "GitSignsChange"}, -- Unmerged path
                    ["UU"] = { symbol = "⇄", hlGroup  = "GitSignsAdd"   }, -- file is unmerged
                    ["UA"] = { symbol = "⊕", hlGroup  = "GitSignsAdd"   }, -- file is unmerged and added in working tree
                    ["??"] = { symbol = "?", hlGroup  = "GitSignsDelete"}, -- Untracked files
                    ["!!"] = { symbol = "!", hlGroup  = "GitSignsChange"}, -- Ignored files
                    -- stylua: ignore end
                }

                local result = statusMap[status]
                or { symbol = "?", hlGroup = "NonText" }
                return result.symbol, result.hlGroup
            end

            ---@param cwd string
            ---@param callback function
            ---@return nil
            local function fetchGitStatus(cwd, callback)
                local function on_exit(content)
                    if content.code == 0 then
                        callback(content.stdout)
                        vim.g.content = content.stdout
                    end
                end

                local cwd = vim.loop.cwd()
                if not cwd or vim.fn.isdirectory(cwd .. "/.git") == 0 then
                    print("Not a Git repository: " .. cwd)
                    return
                end
                vim.system(
                { "git", "status", "--ignored", "--porcelain" },
                { text = true, cwd = cwd },
                on_exit
                )
            end

            ---@param str string?
            local function escapePattern(str)
                return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
            end

            ---@param buf_id integer
            ---@param gitStatusMap table
            ---@return nil
            local function updateMiniWithGit(buf_id, gitStatusMap)
                vim.schedule(function()
                    local nlines = vim.api.nvim_buf_line_count(buf_id)
                    local cwd = vim.fs.root(buf_id, ".git")
                    local escapedcwd = escapePattern(cwd)
                    if vim.fn.has("win32") == 1 then
                        escapedcwd = escapedcwd:gsub("\\", "/")
                    end

                    for i = 1, nlines do
                        local entry = MiniFiles.get_fs_entry(buf_id, i)
                        if not entry then
                            break
                        end
                        local relativePath = entry.path:gsub("^" .. escapedcwd .. "/", "")
                        local status = gitStatusMap[relativePath]

                        if status then
                            local symbol, hlGroup = mapSymbols(status)
                            vim.api.nvim_buf_set_extmark(buf_id, nsMiniFiles, i - 1, 0, {
                                -- NOTE: if you want the signs on the right uncomment those and comment
                                -- the 3 lines after
                                -- virt_text = { { symbol, hlGroup } },
                                -- virt_text_pos = "right_align",
                                sign_text = symbol,
                                sign_hl_group = hlGroup,
                                priority = 2,
                            })
                        else
                        end
                    end
                end)
            end


            -- Thanks for the idea of gettings https://github.com/refractalize/oil-git-status.nvim signs for dirs
            ---@param content string
            ---@return table
            local function parseGitStatus(content)
                local gitStatusMap = {}
                -- lua match is faster than vim.split (in my experience )
                for line in content:gmatch("[^\r\n]+") do
                    local status, filePath = string.match(line, "^(..)%s+(.*)")
                    -- Split the file path into parts
                    local parts = {}
                    for part in filePath:gmatch("[^/]+") do
                        table.insert(parts, part)
                    end
                    -- Start with the root directory
                    local currentKey = ""
                    for i, part in ipairs(parts) do
                        if i > 1 then
                            -- Concatenate parts with a separator to create a unique key
                            currentKey = currentKey .. "/" .. part
                        else
                            currentKey = part
                        end
                        -- If it's the last part, it's a file, so add it with its status
                        if i == #parts then
                            gitStatusMap[currentKey] = status
                        else
                            -- If it's not the last part, it's a directory. Check if it exists, if not, add it.
                            if not gitStatusMap[currentKey] then
                                gitStatusMap[currentKey] = status
                            end
                        end
                    end
                end
                return gitStatusMap
            end

            ---@param buf_id integer
            ---@return nil
            local function updateGitStatus(buf_id)
                if not vim.fs.root(vim.uv.cwd(), ".git") then
                    return
                end

                local cwd = vim.fn.expand("%:p:h")
                local currentTime = os.time()
                if
                    gitStatusCache[cwd]
                    and currentTime - gitStatusCache[cwd].time < cacheTimeout
                    then
                        updateMiniWithGit(buf_id, gitStatusCache[cwd].statusMap)
                    else
                        fetchGitStatus(cwd, function(content)
                            local gitStatusMap = parseGitStatus(content)
                            gitStatusCache[cwd] = {
                                time = currentTime,
                                statusMap = gitStatusMap,
                            }
                            updateMiniWithGit(buf_id, gitStatusMap)
                        end)
                    end
                end

                ---@return nil
                local function clearCache()
                    gitStatusCache = {}
                end

                local function augroup(name)
                    return vim.api.nvim_create_augroup(
                    "MiniFiles_" .. name,
                    { clear = true }
                    )
                end

                autocmd("User", {
                    group = augroup("start"),
                    pattern = "MiniFilesExplorerOpen",
                    -- pattern = { "minifiles" },
                    callback = function()
                        local bufnr = vim.api.nvim_get_current_buf()
                        updateGitStatus(bufnr)
                    end,
                })

                autocmd("User", {
                    group = augroup("close"),
                    pattern = "MiniFilesExplorerClose",
                    callback = function()
                        clearCache()
                    end,
                })

                autocmd("User", {
                    group = augroup("update"),
                    pattern = "MiniFilesBufferUpdate",
                    callback = function(sii)
                        local bufnr = sii.data.buf_id
                        local cwd = vim.fn.expand("%:p:h")
                        if gitStatusCache[cwd] then
                            updateMiniWithGit(bufnr, gitStatusCache[cwd].statusMap)
                        end
                    end,
                })

                return opts

        end,


        -- keys = {
        --     {
        --         -- Toggle the directory of the file currently being edited
        --         -- If the file doesn't exist, open the current working directory
        --         "<leader>e",
        --         function()
        --             local buf_name = vim.api.nvim_buf_get_name(0)
        --             local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")
        --
        --             if mini_files_open then
        --                 -- If mini.files is open, close it
        --                 require("mini.files").close()
        --                 mini_files_open = false
        --             else
        --                 -- If mini.files is not open, open the appropriate directory
        --                 if vim.fn.filereadable(buf_name) == 1 then
        --                     -- Pass the full file path to highlight the file
        --                     require("mini.files").open(buf_name, true)
        --                 elseif vim.fn.isdirectory(dir_name) == 1 then
        --                     -- If the directory exists but the file doesn't, open the directory
        --                     require("mini.files").open(dir_name, true)
        --                 else
        --                     -- If neither exists, fallback to the current working directory
        --                     require("mini.files").open(vim.uv.cwd(), true)
        --                 end
        --                 mini_files_open = true
        --             end
        --         end,
        --         desc = "Toggle mini.files (Directory of Current File or CWD if not exists)",
        --     },
        --     -- Open the current working directory
        --     {
        --         "<leader>E",
        --         function()
        --             require("mini.files").open(vim.uv.cwd(), true)
        --         end,
        --         desc = "Open mini.files (cwd)",
        --     },
        -- },


        --config si on ne peut pas toggle avec <leader>e
        keys = {
            -- {
            --     -- Open the directory of the file currently being edited
            --     -- If the file doesn't exist because you maybe switched to a new git branch
            --     -- open the current working directory
            --     "<leader>e",
            --     function()
            --         local buf_name = vim.api.nvim_buf_get_name(0)
            --         local dir_name = vim.fn.fnamemodify(buf_name, ":p:h")
            --         if vim.fn.filereadable(buf_name) == 1 then
            --             -- Pass the full file path to highlight the file
            --             require("mini.files").open(buf_name, true)
            --         elseif vim.fn.isdirectory(dir_name) == 1 then
            --             -- If the directory exists but the file doesn't, open the directory
            --             require("mini.files").open(dir_name, true)
            --         else
            --             -- If neither exists, fallback to the current working directory
            --             require("mini.files").open(vim.uv.cwd(), true)
            --         end
            --     end,
            --     desc = "Open mini.files (Directory of Current File or CWD if not exists)",
            -- },
            -- Open the current working directory
            {
                "<leader>E",
                function()
                    require("mini.files").open(vim.uv.cwd(), true)
                end,
                desc = "Open mini.files (cwd)",
            },
        },
    },

  { "sindrets/diffview.nvim" },

  {
      'arminveres/md-pdf.nvim',
      branch = 'main', -- you can assume that main is somewhat stable until releases will be made
      lazy = true,
      keys = {
          {
              "ùll",
              function() require("md-pdf").convert_md_to_pdf() end,
              desc = "Markdown preview",
          },
      },
      ---@type md-pdf.config
      opts = {
          -- Generate a table of contents, on by default
          toc = false,
          preview_cmd = function() return 'zathura' end,
          margins = "1.3cm",
      },
  },

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

  {'akinsho/toggleterm.nvim', version = "*", config = true},

  {
      'echasnovski/mini.surround',
      version = false,
      opts = {
          surround = {
              custom_surroundings = nil,
              highlight_duration = 500,
              mappings = {
                  add = 'sa',
                  delete = 'sd',
                  find = 'sf',
                  find_left = 'sF',
                  highlight = 'sh',
                  replace = 'sr',
                  update_n_lines = 'sn',
                  suffix_last = 'l',
                  suffix_next = 'n',
              },
              n_lines = 20,
              respect_selection_type = false,
              search_method = 'cover',
              silent = false,
          }
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
                  wrap = true,  -- Assure-toi que le wrapping est activé pour les notifications
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
                                  ["/"] = "toggle_focus",-- IMPORTANT
                                  ["<BS>"] = "explorer_up",
                                  ["<CR>"] = "confirm",
                                  ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } },-- IMPORTANT
                                  ["<Tab>"] = { "select", mode = { "i", "n" } },-- IMPORTANT
                                  ["l"] = "confirm",
                                  ["h"] = "explorer_close", -- close directory
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

                                  ["<C-left>"] = {"explorer_up_and_cd", mode = {"i", "n"}},
                                  ["<C-right>"] = {"explorer_cd", mode = {"i", "n"}},
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
                          ["/"] = "toggle_focus",                                                           -- IMPORTANT
                          -- ["<C-Down>"] = { "history_forward", mode = { "i", "n" } },
                          -- ["<C-Up>"] = { "history_back", mode = { "i", "n" } },
                          ["<C-up>"] = {navigate_to_parent_smooth, mode = {"i", "n"}},
                          ["<C-down>"] = {navigate_back_smooth, mode = {"i", "n"}},
                          ["<C-left>"] = {navigate_to_parent_smooth, mode = {"i", "n"}},
                          ["<C-right>"] = {navigate_back_smooth, mode = {"i", "n"}},
                          ["<C-c>"] = { "cancel", mode = "i" },
                          ["<C-w>"] = { "<c-s-w>", mode = { "i" }, expr = true, desc = "delete word" },
                          ["<CR>"] = { "confirm", mode = { "n", "i" } },
                          ["<Down>"] = { "list_down", mode = { "i", "n" } },
                          ["<Esc>"] = "cancel",
                          -- ["<S-CR>"] = { { "pick_win", "jump" }, mode = { "n", "i" } },
                          -- ["<S-Tab>"] = { "select_and_prev", mode = { "i", "n" } },-- IMPORTANT
                          -- ["<Tab>"] = { "select_and_next", mode = { "i", "n" } },-- IMPORTANT

                          ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } },-- IMPORTANT
                          ["<Tab>"] = { "select", mode = { "i", "n" } },-- IMPORTANT
                          ["<Up>"] = { "list_up", mode = { "i", "n" } },
                          ["<a-d>"] = { "inspect", mode = { "n", "i" } },
                          ["<a-f>"] = { "toggle_follow", mode = { "i", "n" } },
                          ["<a-h>"] = { "toggle_hidden", mode = { "i", "n" } },-- IMPORTANT
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

                          ["<C-up>"] = {navigate_to_parent_smooth, mode = {"i", "n"}},
                          ["<C-left>"] = {navigate_to_parent_smooth, mode = {"i", "n"}},

                          ["<C-down>"] = {navigate_back_smooth, mode = {"i", "n"}},
                          ["<C-right>"] = {navigate_back_smooth, mode = {"i", "n"}},
                          ["/"] = "toggle_focus",-- IMPORTANT
                          ["<2-LeftMouse>"] = "confirm",
                          ["<CR>"] = "confirm",-- IMPORTANT
                          ["<Down>"] = "list_down",
                          ["<Esc>"] = "cancel",
                          ["<S-CR>"] = { { "pick_win", "jump" } },
                          -- ["<S-Tab>"] = { "select_and_prev", mode = { "n", "x" } },-- IMPORTANT
                          -- ["<Tab>"] = { "select_and_next", mode = { "n", "x" } },-- IMPORTANT

                          ["<S-Tab>"] = { "unselect_all", mode = { "i", "n" } },-- IMPORTANT
                          ["<Tab>"] = { "select", mode = { "i", "n" } },-- IMPORTANT
                          ["<Up>"] = "list_up",
                          ["<a-d>"] = "inspect",
                          ["<a-f>"] = "toggle_follow",
                          ["<a-h>"] = "toggle_hidden",-- IMPORTANT
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
              row = nil, -- dashboard position. nil for center
              col = nil, -- dashboard position. nil for center
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
                 { section = "header", gap = 2},

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
          { "<leader>:", function() Snacks.picker.command_history() end, desc = "Command History" },
          { "<M-n>", function() Snacks.picker.notifications({ wrap = true }) end, desc = "Notification History" },
          { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
          { "<leader>e", function() Snacks.explorer() end, desc = "File Explorer" },        -- ~~~~~~~~~~~~~~~ <leader>E correspond à mini.files (explorer flottant) ~~~~~~~~~~~~~~~~~~

          -- Picker (file)
          { "<leader>ff", function() Snacks.picker.files() end, desc = "Picker Find Files" },
          { "<leader>fa", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
          { "<leader>ga", function() Snacks.picker.lsp_workspace_symbols() end, desc = "LSP Workspace Symbols" },
          { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
          { "<leader>fp", function() Snacks.picker.projects() end, desc = "Projects" },
          { "<leader>fd", function() Snacks.explorer() end, desc = "File Explorer" },

          -- Picker (Git)
          { "<leader>fb", function() Snacks.gitbrowse() end, desc = "Git Browse" },
          { "<leader>fc", function() Snacks.picker.git_log_file() end, desc = "Git Commit File" },
          { "<leader>fC", function() Snacks.picker.git_log() end, desc = "Git Commit Files" },
          { "<leader>fh", function() Snacks.picker.git_diff() end, desc = "Git Diff (Hunks)" },
          { "<leader>lg", function() Snacks.lazygit() end, desc = "Lazygit" },

          -- Picker (Diagnostics)
          { "<leader>ds", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },


          -- { "<leader>sw", function() Snacks.picker.grep_word() end, desc = "Visual selection or word", mode = { "n", "x" } },

          -- Terminal
          -- { "<c-ù>",      function() Snacks.terminal() end, desc = "Toggle Terminal" },
          {
              "<leader>N",
              desc = "Neovim News",
              function()
                  Snacks.win({
                      file = vim.api.nvim_get_runtime_file("doc/news.txt", false)[1],
                      width = 0.6,
                      height = 0.6,
                      wo = {
                          spell = false,
                          wrap = false,
                          -- signcolumn = "yes",
                          statuscolumn = " ",
                          conceallevel = 3,
                      },
                  })
              end,
          }
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
                  Snacks.toggle.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map("<leader>uc")
                  Snacks.toggle.treesitter():map("<leader>uT")
                  Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>ub")
                  Snacks.toggle.inlay_hints():map("<leader>uh")
              end,
          })

      end,
  },


  { "tpope/vim-fugitive" },

  -- Lua
  {"shortcuts/no-neck-pain.nvim"},

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
              height = 1, -- height of the Zen window
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
                  ruler = false, -- disables the ruler text in the cmd line area
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
    {
      'VonHeikemen/lsp-zero.nvim',
      branch = 'v3.x',
      lazy = true,
      config = false,
      init = function()
        -- Disable automatic setup, we are doing it manually
        vim.g.lsp_zero_extend_cmp = 0
        vim.g.lsp_zero_extend_lspconfig = 0
      end,
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


    -- Autocompletion
    -- {
    --   'hrsh7th/nvim-cmp',
    --   event = 'InsertEnter',
    --   dependencies = {
    --     -- {"afonsocarlos/cmp-nvim-lsp-signature-help"},
    --     -- {
    --     --     "edte/cmp-nvim-lsp-signature-help",
    --     --     event = "InsertEnter"
    --     -- },
    --     {
    --       'ray-x/lsp_signature.nvim',
    --       event = 'InsertEnter',
    --       config = function()
    --
    --         require('lsp_signature').setup({
    --           bind = true, -- Cela permet de lier directement l'affichage des signatures
    --           floating_window = true, -- Active une fenêtre flottante pour afficher les signatures
    --           hint_enable = false, -- Désactive les suggestions dans la ligne (pour une interface plus propre)
    --           doc_lines = 0,
    --           floating_window_above_cur_line = true,
    --           max_width = 150, -- Limite la largeur de la signature affichée
    --           max_height = 3, -- Limite la hauteur de la fenêtre flottante
    --           -- floating_window_off_y = 4,
    --
    --           floating_window_off_x = 5, -- adjust float windows x position.
    --           floating_window_off_y = function() -- adjust float windows y position. e.g. set to -2 can make floating window move up 2 lines
    --               local linenr = vim.api.nvim_win_get_cursor(0)[1] -- buf line number
    --               local pumheight = vim.o.pumheight
    --               local winline = vim.fn.winline() -- line number in the window
    --               local winheight = vim.fn.winheight(0)
    --
    --               -- window top
    --               if winline - 1 < pumheight then
    --                   return pumheight
    --               end
    --
    --               -- window bottom
    --               if winheight - winline < pumheight then
    --                   return -pumheight
    --               end
    --               return 0
    --           end,
    --         })
    --
    --
    --         vim.api.nvim_create_autocmd("CursorMoved", {
    --           pattern = "*", -- S'applique à tous les fichiers
    --
    --           callback = function()
    --             local filetype = vim.bo.filetype
    --
    --             -- Désactiver le comportement pour les fichiers .tex et .txt et autres
    --             if filetype == "tex" or filetype == "txt" or filetype == "python" or filetype == "javascript" or filetype == "typescript" then
    --                 return
    --             end
    --
    --             -- Vérifier si nous sommes en mode insertion
    --             if vim.fn.mode() ~= "i" then
    --               return
    --             end
    --
    --             local line = vim.api.nvim_get_current_line()
    --             local col = vim.api.nvim_win_get_cursor(0)[2]
    --             local char_under_cursor = line:sub(col + 1, col + 1)
    --
    --             -- Ferme si le curseur sort des parenthèses
    --             if char_under_cursor ~= "(" and char_under_cursor ~= "," then
    --               require('lsp_signature').toggle_float_win(false) -- Ferme la fenêtre
    --             end
    --           end,
    --         })
    --
    --       end,
    --     },
    --
    --     -- {
    --     --   -- snippet plugin
    --     --   "L3MON4D3/LuaSnip",
    --     --   -- dependencies = "rafamadriz/friendly-snippets",
    --     --   -- config = function()
    --     --   --   local luasnip = require("luasnip")
    --     --   --   require("luasnip.loaders.from_vscode").lazy_load { exclude = vim.g.vscode_snippets_exclude or {} }
    --     --   --   require("luasnip.loaders.from_vscode").lazy_load { paths = vim.g.vscode_snippets_path or "" }
    --     --   --
    --     --   --   -- snipmate format
    --     --   --   require("luasnip.loaders.from_snipmate").load()
    --     --   --   require("luasnip.loaders.from_snipmate").lazy_load { paths = vim.g.snipmate_snippets_path or "" }
    --     --   --
    --     --   --   -- lua format
    --     --   --   require("luasnip.loaders.from_lua").load()
    --     --   --   require("luasnip.loaders.from_lua").lazy_load { paths = vim.g.lua_snippets_path or "" }
    --     --   --
    --     --   --   vim.api.nvim_create_autocmd("InsertLeave", {
    --     --   --     callback = function()
    --     --   --       if
    --     --   --         require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
    --     --   --         and not require("luasnip").session.jump_active
    --     --   --         then
    --     --   --           require("luasnip").unlink_current()
    --     --   --         end
    --     --   --       end,
    --     --   --     })
    --     --   -- end,
    --     -- },
    --     {
    --       "windwp/nvim-autopairs",
    --       opts = {
    --         fast_wrap = {},
    --         disable_filetype = { "TelescopePrompt", "vim" },
    --       },
    --       config = function(_, opts)
    --         require("nvim-autopairs").setup(opts)
    --
    --         -- setup cmp for autopairs
    --         local cmp_autopairs = require "nvim-autopairs.completion.cmp"
    --         require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
    --       end,
    --     },
    --   },
    --   config = function()
    --     local lsp_zero = require('lsp-zero')
    --     lsp_zero.extend_cmp()
    --
    --     local cmp = require('cmp')
    --     local cmp_action = lsp_zero.cmp_action()
    --
    --     cmp.setup({
    --       -- formatting = lsp_zero.cmp_format({ details = true }),
    --
    --       formatting = {
    --         format = function(entry, vim_item)
    --           -- Add the signature details next to the completion item
    --           vim_item.menu = entry.completion_item.detail or ""
    --           return vim_item
    --         end,
    --       },
    --       preselect = cmp.PreselectMode.None,
    --       mapping = cmp.mapping.preset.insert({
    --         ['<C-Space>'] = cmp.mapping.complete(),
    --         ['<C-n>'] = cmp.mapping.select_next_item(), -- Navigue vers l'élément suivant
    --         ['<C-p>'] = cmp.mapping.select_prev_item(), -- Navigue vers l'élément précédent
    --         ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    --         ['<C-d>'] = cmp.mapping.scroll_docs(4),
    --         ['<C-f>'] = cmp_action.luasnip_jump_forward(),
    --         ['<C-b>'] = cmp_action.luasnip_jump_backward(),
    --         ['<Tab>'] = cmp.mapping.confirm {
    --           behavior = cmp.ConfirmBehavior.Replace,
    --           select = true,
    --         },
    --       }),
    --       sources = {
    --
    --         -- { name = 'nvim_lsp_signature_help' },
    --         { name = 'nvim_lsp', max_item_count = 10 },                                         -- Limiter les suggestions LSP à 5
    --         -- { name = 'luasnip',  options = { show_autosnippets = true }, max_item_count = 10 }, -- Limiter les suggestions LSP à 5
    --         { name = 'buffer',   max_item_count = 10 },                                         -- Limiter les suggestions du buffer à 5
    --         { name = 'path',     max_item_count = 10 },                                         -- Limiter les suggestions de chemin à 5
    --       },
    --
    --       snippet = {
    --         expand = function(args)
    --           require('luasnip').lsp_expand(args.body)
    --         end,
    --       },
    --     })
    --   end
    -- },


    {
      "saghen/blink.cmp",
      -- build = 'cargo build --release',
      enabled = true,      --------------------------------------------------------------------------------------------------------------------------------
      dependencies = {
        "moyiz/blink-emoji.nvim",

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
        { 'L3MON4D3/LuaSnip', version = 'v2.*' }, -- utiliser uniquement pour fichier .tex
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
            default = { "lsp", "path", "snippets", "buffer" },
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
                trailing_slash = false,
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
              score_offset = 16, -- the higher the number, the higher the priority
              -- min_keyword_length = 1,
            },

            snippets = {
                name = "snippets",
                score_offset = 15, -- the higher the number, the higher the priority
                max_items = 4,
                enabled = function()
                    return vim.bo.filetype == "tex" -- UTILISER pour fichers .tex
                end,
            },

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
          -- completion = { menu = { auto_show = true } },
        }

        opts.completion = {

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

            winhighlight = 'Normal:BlinkCmpLabel,FloatBorder:FloatBorder,CursorLine:BlinkCmpMenuSelection,Search:None',

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

          -- menu = {
          --     border = "single",
          --     draw = {
          --         treesitter = { "lsp" },
          --         columns = { { "kind_icon" }, { "label", gap = 1 } },
          --         components = {
          --             label = {
          --                 -- Texte du label
          --                 text = function(ctx)
          --                     return ctx.label .. (ctx.label_detail or "")
          --                 end,
          --                 -- Mise en évidence des correspondances
          --                 highlight = function(ctx)
          --                     print("label_matched_indices:", vim.inspect(ctx.label_matched_indices))
          --                     local highlights = {
          --                         { 0, #ctx.label, group = ctx.deprecated and 'BlinkCmpLabelDeprecated' or 'BlinkCmpLabel' },
          --                     }
          --                     -- if ctx.label_detail then
          --                     --     table.insert(highlights, { #ctx.label, #ctx.label + #ctx.label_detail, group = 'BlinkCmpLabelDetail' })
          --                     -- end
          --                     -- Ajout du surlignage pour les lettres correspondant au fuzzy matcher
          --                     for _, idx in ipairs(ctx.label_matched_indices or {}) do
          --                         table.insert(highlights, { idx, idx + 1, group = 'ErrorMsg' }) -- Test avec un groupe existant
          --                     end
          --
          --                     return highlights
          --                 end,
          --             },
          --         },
          --     },
          -- },


          -- Définition du groupe de surlignage pour les lettres correspondant au fuzzy matcher
          vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { fg = "#ffffff", bg = "#ffff00", bold = true, underline = true }),

          list = {
              selection = {
                  preselect = true,
                  auto_insert = true,
              }
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
            ["<Tab>"] = {"select_and_accept", "fallback"},
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

    -- LSP
    {
      'neovim/nvim-lspconfig',
      cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
      event = { 'BufReadPre', 'BufNewFile', 'VimEnter' },
      dependencies = {
        { 'hrsh7th/cmp-nvim-lsp' },
        { 'williamboman/mason-lspconfig.nvim' },
        {'ray-x/lsp_signature.nvim'},
      },
      enabled = true,      --------------------------------------------------------------------------------------------------------------------------------

      config = function()
        -- This is where all the LSP shenanigans will live
        local lsp_zero = require('lsp-zero')
        lsp_zero.extend_lspconfig()

        -- local capabilities = vim.lsp.protocol.make_client_capabilities()
        -- capabilities.offsetEncoding = { "utf-16" }
        --
        -- -- ---------------------------------------------------------------------------------
        -- capabilities.textDocument.completion.completionItem.snippetSupport = true -- IMPORTANT (false désactive tous les snippets)

        -- ---------------------------------------------------------------------------------

        local ft = vim.bo.filetype
        local caps = vim.lsp.protocol.make_client_capabilities()
        caps.offsetEncoding = { "utf-16" }
        caps.textDocument.completion.completionItem.snippetSupport = (ft == "tex")

        lsp_zero.on_attach(function(client, bufnr)


            client.offset_encoding = 'utf-16'  -- Cela garantit que l'encodage d'offset est uniforme
          -- Disable LSP for .txt files specifically
          if vim.bo[bufnr].filetype == 'text' and client.name == 'textlsp' then
            client.stop()  -- Stop the LSP client for `.txt` files
            return
          end

          lsp_zero.default_keymaps({ buffer = bufnr })
          local opts = { noremap = true, silent = true }
          vim.keymap.set('n', '<leader>gh', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
          vim.keymap.set('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
          -- vim.keymap.set('n', '<leader>gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
          vim.keymap.set("n", "<leader>gl", ":Trouble lsp toggle focus=true<cr>", {silent = true})
          -- vim.keymap.set("n", "<leader>gr", ":Trouble lsp_references toggle focus=true<cr>", {silent = true})
          -- vim.keymap.set("n", "<leader>gr", ":Trouble lsp_references toggle focus=true win.type=float<cr>", {silent = true})
          vim.keymap.set("n", "<leader>gr", ":Telescope lsp_references<cr>")
        end)


        require('mason-lspconfig').setup({
          ensure_installed = {},
          handlers = {
            -- this first function is the "default handler"
            -- it applies to every language server without a "custom handler"
            function(server_name)
              require('lspconfig')[server_name].setup({
                capabilities = capabilities,
              })
            end,


            clangd = function()

                local ft = vim.bo.filetype
                local caps = vim.lsp.protocol.make_client_capabilities()
                caps.offsetEncoding = { "utf-16" }
                caps.textDocument.completion.completionItem.snippetSupport = (ft == "tex")

                require('lspconfig').clangd.setup({
                    capabilities = caps,
                    -- cmd = { "clangd", "--background-index" },
                    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
                    root_dir = require('lspconfig.util').root_pattern('compile_commands.json', '.clangd', '.git'),
                })
            end,

            -- this is the "custom handler" for `lua_ls`
            lua_ls = function()

                local ft = vim.bo.filetype
                local caps = vim.lsp.protocol.make_client_capabilities()
                caps.offsetEncoding = { "utf-16" }
                caps.textDocument.completion.completionItem.snippetSupport = (ft == "tex")

              local lua_opts = lsp_zero.nvim_lua_ls()
              require('lspconfig').lua_ls.setup(vim.tbl_deep_extend("force", lua_opts, {
                capabilities = caps,
              }))
            end,


            -- pyright = function()
            --   require('lspconfig').pyright.setup({
            --     capabilities = capabilities,
            --     on_attach = function(_, bufnr) -- '_' signifie que le client est ignoré
            --       -- Set indentation to 2 spaces for Python
            --       require('lsp_signature').toggle_float_win(false)
            --       vim.bo[bufnr].tabstop = 4
            --       vim.bo[bufnr].shiftwidth = 4
            --       vim.bo[bufnr].expandtab = true
            --       vim.bo[bufnr].autoindent = true
            --       vim.bo[bufnr].smartindent = true
            --     end,
            --   })
            -- end,


          }
        })

      end
    }

  }

})
