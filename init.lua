-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.opt.signcolumn = 'yes'

vim.opt.number = true
vim.opt.mouse = 'n'
vim.opt.showmode = false

-- vim.cmd [[
--   filetype indent off
-- ]]

-- NOTE: This supplies comment strings
-- filetype plugin off

-- Disable all forms of automatic indentation
-- vim.opt.breakindent = false
-- vim.opt.autoindent = false
-- vim.opt.smartindent = false
-- vim.opt.cindent = false
-- vim.opt.indentexpr = ''
-- vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- persist undo history
vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
    vim.opt.clipboard = 'unnamedplus'
end)

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
    spec = {
        'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
        {
            'stevearc/oil.nvim',
            lazy = false,
            config = function()
                require("oil").setup()
                vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
            end
        },
        {
            'mfussenegger/nvim-dap',
            dependencies = {
                'rcarriga/nvim-dap-ui',
                'leoluz/nvim-dap-go',
                'nvim-neotest/nvim-nio',
                'mfussenegger/nvim-dap-python',
            },
            config = function()
                local dap = require 'dap'
                local ui = require 'dapui'
                require('dapui').setup()
                require('dap-go').setup()
                require('dap-python').setup 'python'

                dap.adapters.codelldb = {
                    type = 'server',
                    port = '${port}',
                    executable = {
                        command = vim.fn.stdpath 'data' .. '/mason/bin/codelldb',
                        args = { '--port', '${port}' },
                    },
                }

                table.insert(dap.configurations.python, {
                    name = 'Launch justMyCode = false',
                    type = 'python',
                    request = 'launch',
                    program = '${file}',
                    justMyCode = false,
                })

                dap.configurations.rust = {
                    {
                        name = 'Launch (by name)',
                        type = 'codelldb',
                        request = 'launch',
                        program = function()
                            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
                        end,
                        cwd = '${workspaceFolder}',
                        stopOnEntry = false,
                        args = {},
                    },
                }

                dap.configurations.zig = {
                    {
                        name = 'Launch (by name)',
                        type = 'codelldb',
                        request = 'launch',
                        program = function()
                            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/zig-out/bin/', 'file')
                        end,
                        cwd = '${workspaceFolder}',
                        stopOnEntry = false,
                        args = {},
                    },
                    {
                        name = 'Launch (default)',
                        type = 'codelldb',
                        request = 'launch',
                        program = '${workspaceFolder}/zig-out/bin/main',
                        cwd = '${workspaceFolder}',
                        stopOnEntry = false,
                        args = {},
                    },
                }

                dap.configurations.c = {
                    {
                        name = 'Launch',
                        type = 'codelldb',
                        request = 'launch',
                        program = function()
                            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
                        end,
                        -- program = function()
                        --   return '${workspaceFolder}/build/bin/' .. vim.fn.input 'name of file: '
                        -- end,
                        cwd = '${workspaceFolder}',
                        stopOnEntry = false,
                        args = {},
                    },
                }

                vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint)
                vim.keymap.set('n', '<leader>cb', dap.toggle_breakpoint)
                vim.keymap.set('n', '<leader>gb', dap.run_to_cursor)
                vim.keymap.set('n', '<leader>tb', function()
                    dap.disconnect { terminateDebuggee = true }
                end)

                vim.keymap.set('n', '<leader>?', function()
                    require('dapui').eval(nil, { enter = true })
                end)

                vim.keymap.set('n', '<F1>', dap.continue)
                vim.keymap.set('n', '<F2>', dap.step_over)
                vim.keymap.set('n', '<F3>', dap.step_into)
                vim.keymap.set('n', '<F4>', dap.step_out)
                vim.keymap.set('n', '<F5>', dap.clear_breakpoints)
                vim.keymap.set('n', '<F12>', dap.restart)

                dap.listeners.before.attach.dapui_config = function()
                    ui.open()
                end
                dap.listeners.before.launch.dapui_config = function()
                    ui.open()
                end
                dap.listeners.before.event_terminated.dapui_config = function()
                    ui.close()
                end
                dap.listeners.before.event_exited.dapui_config = function()
                    ui.close()
                end
            end,
        },

        -- -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
        'mbbill/undotree',
        -- See `:help gitsigns` to understand what the configuration keys do
        { -- Adds git related signs to the gutter, as well as utilities for managing changes
            'lewis6991/gitsigns.nvim',
            opts = {
                signs = {
                    add = { text = '+' },
                    change = { text = '~' },
                    delete = { text = '_' },
                    topdelete = { text = '‾' },
                    changedelete = { text = '~' },
                },
            },
        },
        { -- Fuzzy Finder (files, lsp, etc)
            'nvim-telescope/telescope.nvim',
            event = 'VimEnter',
            branch = '0.1.x',
            dependencies = {
                'nvim-lua/plenary.nvim',
                { -- If encountering errors, see telescope-fzf-native README for installation instructions
                    'nvim-telescope/telescope-fzf-native.nvim',

                    -- `build` is used to run some command when the plugin is installed/updated.
                    -- This is only run then, not every time Neovim starts up.
                    build = 'make',

                    -- `cond` is a condition used to determine whether this plugin should be
                    -- installed and loaded.
                    cond = function()
                        return vim.fn.executable 'make' == 1
                    end,
                },
                { 'nvim-telescope/telescope-ui-select.nvim' },

                -- Useful for getting pretty icons, but requires a Nerd Font.
                { 'nvim-tree/nvim-web-devicons',            enabled = vim.g.have_nerd_font },
            },
            config = function()
                -- Telescope is a fuzzy finder that comes with a lot of different things that
                -- it can fuzzy find! It's more than just a "file finder", it can search
                -- many different aspects of Neovim, your workspace, LSP, and more!
                --
                -- The easiest way to use Telescope, is to start by doing something like:
                --  :Telescope help_tags
                --
                -- After running this command, a window will open up and you're able to
                -- type in the prompt window. You'll see a list of `help_tags` options and
                -- a corresponding preview of the help.
                --
                -- Two important keymaps to use while in Telescope are:
                --  - Insert mode: <c-/>
                --  - Normal mode: ?
                --
                -- This opens a window that shows you all of the keymaps for the current
                -- Telescope picker. This is really useful to discover what Telescope can
                -- do as well as how to actually do it!

                -- [[ Configure Telescope ]]
                -- See `:help telescope` and `:help telescope.setup()`
                require('telescope').setup {
                    -- You can put your default mappings / updates / etc. in here
                    --  All the info you're looking for is in `:help telescope.setup()`
                    --
                    -- defaults = {
                    --   mappings = {
                    --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
                    --   },
                    -- },
                    -- pickers = {}
                    defaults = {
                        initial_mode = 'normal',
                        layout_config = {
                            width = 0.95,             -- Adjust width here (0.9 means 90% of the editor width)
                            height = 0.95,            -- Adjust height here (0.9 means 90% of the editor height)
                            preview_cutoff = 120,     -- Preview will be hidden for narrow screens
                            horizontal = {
                                preview_width = 0.75, -- Adjust preview width for horizontal layout
                            },
                            vertical = {
                                preview_height = 0.5, -- Adjust preview height for vertical layout
                            },
                        },
                    },

                    pickers = {},

                    extensions = {
                        ['ui-select'] = {
                            require('telescope.themes').get_dropdown(),
                        },
                    },
                }

                -- Enable Telescope extensions if they are installed
                pcall(require('telescope').load_extension, 'fzf')
                pcall(require('telescope').load_extension, 'ui-select')

                -- See `:help telescope.builtin`
                local builtin = require 'telescope.builtin'
                vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
                vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
                vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
                vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
                vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
                vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
                vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
                vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
                vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
                vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

                -- Slightly advanced example of overriding default behavior and theme
                vim.keymap.set('n', '<leader>/', function()
                    -- You can pass additional configuration to Telescope to change the theme, layout, etc.
                    builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                        winblend = 10,
                        previewer = false,
                    })
                end, { desc = '[/] Fuzzily search in current buffer' })

                -- It's also possible to pass additional configuration options.
                --  See `:help telescope.builtin.live_grep()` for information about particular keys
                vim.keymap.set('n', '<leader>s/', function()
                    builtin.live_grep {
                        grep_open_files = true,
                        prompt_title = 'Live Grep in Open Files',
                    }
                end, { desc = '[S]earch [/] in Open Files' })

                -- Shortcut for searching your Neovim configuration files
                vim.keymap.set('n', '<leader>sn', function()
                    builtin.find_files { cwd = vim.fn.stdpath 'config' }
                end, { desc = '[S]earch [N]eovim files' })
            end,
        },

        -- LSP Plugins
        {
            -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
            -- used for completion, annotations and signatures of Neovim apis
            'folke/lazydev.nvim',
            ft = 'lua',
            opts = {
                library = {
                    -- Load luvit types when the `vim.uv` word is found
                    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
                },
            },
        },
        {
            'saghen/blink.cmp',
            -- -- optional: provides snippets for the snippet source
            -- dependencies = 'rafamadriz/friendly-snippets',

            -- use a release tag to download pre-built binaries
            version = '*',
            -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
            -- build = 'cargo build --release',
            -- If you use nix, you can build from source using latest nightly rust with:
            -- build = 'nix run .#build-plugin',

            ---@module 'blink.cmp'
            ---@type blink.cmp.Config
            opts = {
                -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept, C-n/C-p for up/down)
                -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys for up/down)
                -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
                --
                -- All presets have the following mappings:
                -- C-space: Open menu or open docs if already open
                -- C-e: Hide menu
                -- C-k: Toggle signature help
                --
                -- See the full "keymap" documentation for information on defining your own keymap.
                keymap = { preset = 'default' },

                appearance = {
                    -- Sets the fallback highlight groups to nvim-cmp's highlight groups
                    -- Useful for when your theme doesn't support blink.cmp
                    -- Will be removed in a future release
                    use_nvim_cmp_as_default = true,
                    -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                    -- Adjusts spacing to ensure icons are aligned
                    nerd_font_variant = 'mono'
                },

                -- Default list of enabled providers defined so that you can extend it
                -- elsewhere in your config, without redefining it, due to `opts_extend`
                sources = {
                    default = { 'lsp', 'path', 'snippets', 'buffer' },
                },

                -- Blink.cmp uses a Rust fuzzy matcher by default for typo resistance and significantly better performance
                -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
                -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
                --
                -- See the fuzzy documentation for more information
                fuzzy = { implementation = "prefer_rust_with_warning" }
            },
            opts_extend = { "sources.default" }
        },
        -- LSP servers and clients communicate which features they support through "capabilities".
        --  By default, Neovim supports a subset of the LSP specification.
        --  With blink.cmp, Neovim has _more_ capabilities which are communicated to the LSP servers.
        --  Explanation from TJ: https://youtu.be/m8C0Cq9Uv9o?t=1275
        --
        -- This can vary by config, but in general for nvim-lspconfig:

        {
            'neovim/nvim-lspconfig',
            dependencies = { 'saghen/blink.cmp' },

            -- example using `opts` for defining servers
            opts = {
                servers = {
                    lua_ls = {},
                    ruff = {},
                    pyright = {},
                    rust_analyzer = {},
                    clangd = {},
                    sourcekit = {
                        cmd = { "/usr/bin/sourcekit-lsp" },
                        capabilities = {
                            workspace = {
                                didChangeWatchedFiles = {
                                    dynamicRegistration = true,
                                },
                            },
                        },
                    }
                }
            },
            config = function(_, opts)
                vim.api.nvim_create_autocmd('LspAttach', {
                    group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
                    callback = function(event)
                        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
                        -- to define small helper and utility functions so you don't have to repeat yourself.
                        --
                        -- In this case, we create a function that lets us more easily define mappings specific
                        -- for LSP related items. It sets the mode, buffer and description for us each time.
                        local map = function(keys, func, desc, mode)
                            mode = mode or 'n'
                            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
                        end

                        -- Jump to the definition of the word under your cursor.
                        --  This is where a variable was first declared, or where a function is defined, etc.
                        --  To jump back, press <C-t>.
                        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')

                        -- Find references for the word under your cursor.
                        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')

                        -- Jump to the implementation of the word under your cursor.
                        --  Useful when your language has ways of declaring types without an actual implementation.
                        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')

                        -- Jump to the type of the word under your cursor.
                        --  Useful when you're not sure what type a variable is and you want to see
                        --  the definition of its *type*, not where it was *defined*.
                        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')

                        -- Fuzzy find all the symbols in your current document.
                        --  Symbols are things like variables, functions, types, etc.
                        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')

                        -- Fuzzy find all the symbols in your current workspace.
                        --  Similar to document symbols, except searches over your entire project.
                        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols,
                            '[W]orkspace [S]ymbols')

                        -- Rename the variable under your cursor.
                        --  Most Language Servers support renaming across files, etc.
                        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

                        -- Execute a code action, usually your cursor needs to be on top of an error
                        -- or a suggestion from your LSP for this to activate.
                        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction', { 'n', 'x' })

                        -- WARN: This is not Goto Definition, this is Goto Declaration.
                        --  For example, in C this would take you to the header.
                        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

                        -- The following two autocommands are used to highlight references of the
                        -- word under your cursor when your cursor rests there for a little while.
                        --    See `:help CursorHold` for information about when this is executed
                        --
                        -- When you move your cursor, the highlights will be cleared (the second autocommand).
                        local client = vim.lsp.get_client_by_id(event.data.client_id)
                        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
                            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight',
                                { clear = false })
                            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
                                buffer = event.buf,
                                group = highlight_augroup,
                                callback = vim.lsp.buf.document_highlight,
                            })

                            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
                                buffer = event.buf,
                                group = highlight_augroup,
                                callback = vim.lsp.buf.clear_references,
                            })

                            vim.api.nvim_create_autocmd('LspDetach', {
                                group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
                                callback = function(event2)
                                    vim.lsp.buf.clear_references()
                                    vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
                                end,
                            })
                        end

                        -- The following code creates a keymap to toggle inlay hints in your
                        -- code, if the language server you are using supports them
                        --
                        -- This may be unwanted, since they displace some of your code
                        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                            map('<leader>th', function()
                                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
                            end, '[T]oggle Inlay [H]ints')
                        end
                    end,
                })
                local lspconfig = require('lspconfig')
                for server, config in pairs(opts.servers) do
                    -- passing config.capabilities to blink.cmp merges with the capabilities in your
                    -- `opts[server].capabilities, if you've defined it
                    config.capabilities = require('blink.cmp').get_lsp_capabilities(config.capabilities)
                    lspconfig[server].setup(config)
                end
            end
        },
        { -- Autoformat
            'stevearc/conform.nvim',
            enabled = true,
            event = { 'BufWritePre' },
            cmd = { 'ConformInfo' },
            keys = {
                {
                    '<leader>f',
                    function()
                        require('conform').format { async = true, lsp_format = 'fallback' }
                    end,
                    mode = '',
                    desc = '[F]ormat buffer',
                },
            },
            opts = {
                notify_on_error = false,
                format_on_save = function(bufnr)
                    -- Disable "format_on_save lsp_fallback" for languages that don't
                    -- have a well standardized coding style. You can add additional
                    -- languages here or re-enable it for the disabled ones.
                    local disable_filetypes = { c = true, cpp = true, lua = false }
                    local lsp_format_opt
                    if disable_filetypes[vim.bo[bufnr].filetype] then
                        lsp_format_opt = 'never'
                    else
                        lsp_format_opt = 'fallback'
                    end
                    return {
                        timeout_ms = 500,
                        lsp_format = lsp_format_opt,
                    }
                end,
                formatters_by_ft = {
                    -- lua = { 'stylua' },
                    -- Conform can also run multiple formatters sequentially
                    -- python = { 'ruff' },
                    --
                    -- You can use 'stop_after_first' to run the first available formatter from the list
                    -- javascript = { 'prettierd', 'prettier', stop_after_first = true },
                },
            },
        },

        { -- You can easily change to a different colorscheme.
            -- Change the name of the colorscheme plugin below, and then
            -- change the command in the config to whatever the name of that colorscheme is.
            --
            -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
            -- 'folke/tokyonight.nvim',
            'ellisonleao/gruvbox.nvim',
            priority = 1000, -- Make sure to load this before all the other start plugins.
            config = function()
                ---@diagnostic disable-next-line: missing-fields
                require('gruvbox').setup {
                    styles = {
                        comments = { italic = false }, -- Disable italics in comments
                    },
                }

                -- Load the colorscheme here.
                -- Like many other themes, this one has different styles, and you could load
                -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
                vim.cmd.colorscheme 'gruvbox'

                -- You can configure highlights by doing something like:
                vim.cmd.hi 'Comment gui=none'
            end,
        },

        -- Highlight todo, notes, etc in comments
        { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

        { -- Collection of various small independent plugins/modules
            'echasnovski/mini.nvim',
            config = function()
                -- Better Around/Inside textobjects
                --
                -- Examples:
                --  - va)  - [V]isually select [A]round [)]paren
                --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
                --  - ci'  - [C]hange [I]nside [']quote
                require('mini.ai').setup { n_lines = 500 }

                -- Add/delete/replace surroundings (brackets, quotes, etc.)
                --
                -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
                -- - sd'   - [S]urround [D]elete [']quotes - sr)'  - [S]urround [R]eplace [)] [']

                require('mini.surround').setup()

                -- Simple and easy statusline.
                --  You could remove this setup call if you don't like it,
                --  and try some other statusline plugin
                local statusline = require 'mini.statusline'
                -- set use_icons to true if you have a Nerd Font
                statusline.setup { use_icons = vim.g.have_nerd_font }

                -- You can configure sections in the statusline by overriding their
                -- default behavior. For example, here we set the section for
                -- cursor location to LINE:COLUMN
                ---@diagnostic disable-next-line: duplicate-set-field
                statusline.section_location = function()
                    return '%2l:%-2v'
                end

                -- ... and there is more!
                --  Check out: https://github.com/echasnovski/mini.nvim
            end,
        },
        { -- Highlight, edit, and navigate code
            'nvim-treesitter/nvim-treesitter',
            -- dev = true,
            -- dir = '$HOME/.config/nvim/plugins/nvim-treesitter',
            enabled = true,
            build = ':TSUpdate',
            main = 'nvim-treesitter.configs', -- Sets main module to use for opts
            -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
            opts = {
                ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc', 'python' },
                -- Autoinstall languages that are not installed
                -- auto_install = false,
                highlight = {
                    enable = true,
                    -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
                    --  If you are experiencing weird indenting issues, add the language to
                    --  the list of additional_vim_regex_highlighting and disabled languages for indent.

                    additional_vim_regex_highlighting = { 'ruby' },
                    -- additional_vim_regex_highlighting = false,
                },
                indent = { enable = false, disable = { 'ruby' } },
            },
        },
        --
        -- There are additional nvim-treesitter modules that you can use to interact
        -- with nvim-treesitter. You should go explore a few and see what interests you:
        --
        --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
        --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
        --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
        {
            'MeanderingProgrammer/render-markdown.nvim',
            enabled = false,
            opts = {},
            dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
            config = function()
                require('render-markdown').setup {
                    link = {
                        -- Turn on / off inline link icon rendering
                        enabled = false,
                    },
                    heading = {
                        enabled = false,
                    },
                    code = {
                        highlight = nil,
                        -- Highlight for inline code
                        highlight_inline = nil,
                    },
                }
            end,
            -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
            -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        },
        {
            'chottolabs/kznllm.nvim',
            dev = true,
            dir = '/Users/chottolabs/.config/nvim/plugins/kznllm.nvim',
            dependencies = {
                { 'j-hui/fidget.nvim' },
            },
            config = function(self)
                local presets = require 'kznllm.presets.ollama'

                vim.keymap.set({ 'n', 'v' }, '<leader>m', function()
                    presets.switch_presets(presets.options)
                end, { desc = 'switch between presets' })

                local function invoke_with_opts(opts)
                    return function()
                        local preset = presets.load_selected_preset(presets.options)
                        preset.invoke(opts)
                    end
                end

                local function yap_generator()
                    math.randomseed(os.time())
                    local yap_cycle = {
                        'brewing up a yappacino for %ds',
                        'yapping up a storm for %ds',
                        'putting the fries in the bag for %ds',
                        'lowkey chilling for %ds',
                        'locking in for %ds',
                        'rewriting from scratch in c for %ds',
                        'ohh husbant, you yapped for %ds',
                    }

                    local idx = math.random(1, #yap_cycle)
                    return function()
                        idx = idx + 1
                        if idx > #yap_cycle then
                            idx = 1
                        end
                        return yap_cycle[idx]
                    end
                end

                local yap = yap_generator()

                local function progress_fn(state)
                    local now = os.time()
                    if (now ~= state.last_updated) and ((now - state.start) % 2) == 0 then
                        state.last_updated = now
                        return yap()
                    end
                end

                vim.keymap.set({ 'n', 'v' }, '<leader>K',
                    invoke_with_opts { debug = true, progress_message_fn = progress_fn },
                    { desc = 'Send current selection to LLM debug' })
                vim.keymap.set({ 'n', 'v' }, '<leader>k',
                    invoke_with_opts { debug = false, progress_message_fn = progress_fn },
                    { desc = 'Send current selection to LLM llm_fill' })

                vim.api.nvim_set_keymap('n', '<Esc>', '', {
                    noremap = true,
                    silent = true,
                    callback = function()
                        vim.api.nvim_exec_autocmds('User', { pattern = 'LLM_Escape' })
                    end,
                })
            end,
        },
    },
    install = { colorscheme = { "habamax" } },
    checker = { enabled = true, notify = false },
}
