  vim.env.PATH = vim.env.HOME .. "/.cargo/bin:" .. vim.env.PATH
  vim.env.PATH = vim.env.HOME .. "/.npm-global/bin:" .. vim.env.PATH

  -- Bootstrap lazy.nvim
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then     
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Basic settings
  vim.o.number = false
  vim.o.relativenumber = false
  vim.o.cursorline = false
  vim.o.termguicolors = true -- enable true color support

  print("Neovim Lua config loaded!")

  -- Plugins
  require("lazy").setup({

    -- Theme
    {
      "morhetz/gruvbox",
      priority = 1000,
      config = function()
        vim.g.gruvbox_contrast_dark = "hard"
        vim.g.gruvbox_italic = 1
        vim.g.gruvbox_bold = 1
        vim.g.gruvbox_sign_column = "bg0"
        vim.g.gruvbox_invert_selection = 0
        vim.g.gruvbox_termcolors = 256

        vim.cmd.colorscheme("gruvbox")

        -- Customize highlights
        vim.cmd("highlight Normal guibg=#282828 guifg=#ebdbb2")
        vim.cmd("highlight NormalNC guibg=#282828 guifg=#ebdbb2")                                                                                               vim.cmd("highlight SignColumn guibg=#282828")                                                                                                           vim.cmd("highlight LineNr guibg=#282828 guifg=#928374")
        vim.cmd("highlight CursorLine guibg=#3c3836")
        vim.cmd("highlight StatusLine guibg=#282828 guifg=#fabd2f")
        vim.cmd("highlight StatusLineNC guibg=#282828 guifg=#928374")
        vim.cmd("highlight VertSplit guibg=#282828 guifg=#504945")
        vim.cmd("highlight Pmenu guibg=#3c3836 guifg=#ebdbb2")
        vim.cmd("highlight PmenuSel guibg=#fabd2f guifg=#282828")
        vim.cmd("highlight FloatBorder guibg=#3c3836 guifg=#fabd2f")
      end,
    },

    -- Autopairs
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = function()
        require("nvim-autopairs").setup({})
      end,
    },

    -- Completion
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "buffer" },
            { name = "path" },
          }),
        })

        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end,
    },

    -- LSP
    {
      "neovim/nvim-lspconfig",
      config = function()
        local lspconfig = require("lspconfig")
        local capabilities = require("cmp_nvim_lsp").default_capabilities()

        local on_attach = function(_, bufnr)
          local opts = { noremap = true, silent = true, buffer = bufnr }
          local keymap = vim.keymap.set
          keymap("n", "gd", vim.lsp.buf.definition, opts)
          keymap("n", "K", vim.lsp.buf.hover, opts)
          keymap("n", "gi", vim.lsp.buf.implementation, opts)
          keymap("n", "<leader>rn", vim.lsp.buf.rename, opts)
          keymap("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          keymap("n", "gr", vim.lsp.buf.references, opts)
          keymap("n", "[d", vim.diagnostic.goto_prev, opts)     
          keymap("n", "]d", vim.diagnostic.goto_next, opts)     
        end

        -- Clangd
        lspconfig.clangd.setup({
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { "clangd", "--background-index", "--clang-tidy" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(
              "compile_commands.json",
              "compile_flags.txt",
                  ".git"
            )(fname) or vim.fn.getcwd()
          end,
        })

        -- ASM LSP (fixed duplicate cmd)
        lspconfig.asm_lsp.setup({
          cmd = { "asm-lsp" },
          on_attach = on_attach,
          capabilities = capabilities,
          filetypes = { "asm", "s", "S" },
          settings = {
            asm_lsp = {
              default_diagnostics = true,
              instruction_sets = {
                x86 = true,
                x86_64 = true,
                arm = true,
                aarch64 = true,
                riscv = false,
              },
              assemblers = { gas = true, nasm = true },
            }
          },
        })

        -- Pyright
        lspconfig.pyright.setup({
          on_attach = on_attach,
          capabilities = capabilities,
          settings = {
            python = {
              analysis = {
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
                typeCheckingMode = "basic",
              }
            }
          },
        })

        -- Lua LSP
        lspconfig.lua_ls.setup({
          on_attach = on_attach,
          capabilities = capabilities,
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" }, -- avoid "undefined global 'vim'"
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
            },
          },
        })

        -- Diagnostic configuration
        vim.diagnostic.config({
          virtual_text = true,
          signs = true,
          underline = true,
          update_in_insert = false,
          severity_sort = true,
        })

        -- Diagnostic highlights
        vim.cmd("highlight DiagnosticError guifg=#fb4934 gui=bold")
        vim.cmd("highlight DiagnosticWarn guifg=#fabd2f gui=bold")
        vim.cmd("highlight DiagnosticInfo guifg=#83a598 gui=italic")
        vim.cmd("highlight DiagnosticHint guifg=#b8bb26 gui=italic")
      end,
    },

  }) -- <- closes require("lazy").setup

  -- Filetype-specific indentation (moved OUTSIDE plugin spec)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "c", "cpp", "python", "lua" },
    callback = function()
      vim.bo.shiftwidth = 4
      vim.bo.tabstop = 4
    end,
  })
