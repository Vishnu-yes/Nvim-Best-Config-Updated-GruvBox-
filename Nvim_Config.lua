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
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    priority = 1000,
    config = function()
      local current_style = "light_default"

      local function set_github_theme(style)
        require("github-theme").setup({
          options = { transparent = false },
          styles = { comments = "NONE", keywords = "NONE", functions = "NONE", variables = "NONE" },
        })
        vim.cmd("colorscheme github_" .. style)
      end

      set_github_theme(current_style)

      _G.ToggleGithubTheme = function()
        if current_style == "light_default" then
          current_style = "dark_default"
        else
          current_style = "light_default"
        end
        set_github_theme(current_style)
        print("GitHub theme switched to: " .. current_style)
      end

      vim.api.nvim_set_keymap("n", "<leader>gt", ":lua ToggleGithubTheme()<CR>", { noremap = true, silent = true })
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
        snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
        mapping = cmp.mapping.preset.insert({ ["<CR>"] = cmp.mapping.confirm({ select = true }) }),
        sources = cmp.config.sources({ { name = "nvim_lsp" }, { name = "luasnip" }, { name = "buffer" }, { name = "path" } }),
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

      -- C/C++ LSP
      lspconfig.clangd.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = { "clangd", "--background-index", "--clang-tidy" },
        root_dir = function(fname)
          return require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt", ".git")(fname) or vim.fn.getcwd()
        end,
      })

      -- Pyright
      lspconfig.pyright.setup({ on_attach = on_attach, capabilities = capabilities })

      -- Lua LSP
      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })

      -- Diagnostic config
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      vim.cmd("highlight DiagnosticError guifg=#fb4934 gui=bold")
      vim.cmd("highlight DiagnosticWarn guifg=#fabd2f gui=bold")
      vim.cmd("highlight DiagnosticInfo guifg=#83a598 gui=italic")
      vim.cmd("highlight DiagnosticHint guifg=#b8bb26 gui=italic")
    end,
  },

  -- ARM64 assembly syntax highlighting
  {
    "Shirk/vim-gas",
    ft = { "asm", "s" },
  },

  -- ARM64 assembly linting
  {
    "mfussenegger/nvim-lint",
    config = function()
      local lint = require("lint")
      lint.linters.as = {
        name = "as",
        cmd = "as",
        args = { "-o", "/dev/null", "%f" },
        stdin = false,
        stream = "stderr",
        parser = require("lint.parser").from_errorformat("%f:%l: %m", {}),
      }
      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        pattern = { "*.s" },
        callback = function() require("lint").try_lint() end,
      })
    end,
  },

})
    -- Filetype-specific indentation (moved OUTSIDE plugin spec)
    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "c", "cpp", "python", "lua" },
      callback = function()
        vim.bo.shiftwidth = 4
        vim.bo.tabstop = 4
      end,
    })

