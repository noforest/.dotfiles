-- -- METTRE LE FOND du colorscheme DE la meme couleur que mon terminal!!!!!!!!!!!!!!!
require("catppuccin").setup({
  custom_highlights = function(colors)
    return {
      -- Normal = { bg = "none" },
    }
  end
})

require("catppuccin").setup({
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        blink_cmp = true,
    },
})


-- setup must be called before loading
vim.cmd.colorscheme "catppuccin"

vim.cmd("colorscheme catppuccin-mocha") -- set color theme
-- vim.cmd("colorscheme no-clown-fiesta") -- set color theme

-- vim.cmd("highlight SignColumn guibg=NONE")
-- vim.o.background = "dark" -- or "light" for light mode

-- Load and setup function to choose plugin and language highlights
vim.g.startify_custom_header = "" -- startify remove random quote

vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "#181825" })
vim.opt.termguicolors = true      --bufferline
require("bufferline").setup {

  -- highlights = require("catppuccin.groups.integrations.bufferline").get(),
  highlights = {
    buffer_selected = {
      bold = true,
      italic = false,
    },
  },

  options = {

    always_show_bufferline = true,
    auto_toggle_bufferline = true,
    indicator = {
      icon = '▎', -- this should be omitted if indicator style is not 'icon'
      style = 'icon'
    },

    sort_by = 'directory',
  },
}


-- permet de renvoyer à la ligne les diagnostics
vim.api.nvim_create_autocmd("FileType", {
  pattern = "qf", -- pour la quickfix et loclist
  callback = function()
    vim.wo.wrap = true
  end,
})



-- vim.keymap.set('n', '<leader>gh', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)

-- -- Fonction pour désactiver le plugin de rendu Markdown
-- local function disable_markdown_render()
--   vim.cmd('RenderMarkdown disable')
-- end
--
-- -- Fonction pour réactiver le plugin de rendu Markdown
-- local function enable_markdown_render()
--   vim.cmd('RenderMarkdown enable')
-- end
--
--
-- -- Configuration de la touche de raccourci pour le hover LSP
-- vim.keymap.set('n', '<leader>gh', function()
--   disable_markdown_render() -- Désactiver le plugin de rendu Markdown
--   vim.lsp.buf.hover() -- Appeler la fonction de hover LSP
--
--   -- Définir une autocommande pour réactiver le plugin de rendu Markdown lors d'un mouvement de curseur
--   local group = vim.api.nvim_create_augroup('MarkdownRenderGroup', { clear = true })
--   vim.api.nvim_create_autocmd('CursorMoved', {
--     group = group,
--     callback = function()
--       enable_markdown_render() -- Réactiver le plugin de rendu Markdown
--       vim.api.nvim_del_augroup_by_name('MarkdownRenderGroup') -- Supprimer l'autocommande après utilisation
--     end,
--   })
-- end)


vim.cmd("doautocmd BufReadPost")

-- Gestionnaire d'erreurs pour ignorer l'erreur spécifique
vim.lsp.handlers["textDocument/signatureHelp"] = function(err, result, ctx, config)
    if err and err.message and err.message:match("height' key must be a positive Integer") then
        return -- Ignorer l'erreur
    end
    -- Appeler le gestionnaire par défaut si l'erreur n'est pas celle que nous voulons ignorer
    vim.lsp.handlers.signature_help(err, result, ctx, config)
end



-- Enregistre le répertoire courant dans zoxide à chaque changement
vim.api.nvim_create_autocmd({'DirChanged'}, {
    pattern = '*',
    callback = function()
        vim.fn.jobstart({'zoxide', 'add', vim.fn.getcwd()})
    end
})
