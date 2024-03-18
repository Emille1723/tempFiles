-- import lspconfig plugin safely
local lspconfig_status, lspconfig = pcall(require, "lspconfig")
if not lspconfig_status then
    return
end

-- import cmp-nvim-lsp plugin safely
local cmp_nvim_lsp_status, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
if not cmp_nvim_lsp_status then
    return
end

local keymap = vim.keymap -- for conciseness

-- enable keybinds only for when lsp server available
---@diagnostic disable-next-line: unused-local
local on_attach = function(client, bufnr)
    -- client.server_capabilities.semanticTokensProvider = nil
    -- client.server_capabilities.semanticTokensProvider = nil

    vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- keybind options
    local opts = { noremap = true, silent = true, buffer = bufnr }

    opts.desc = "Go to Definition"
    keymap.set("n", "gF", function()
        vim.cmd([[ lua vim.lsp.buf.definition() ]]) -- to to def
        vim.cmd([[ norm! zz ]])               -- center the view can also be written as vim.cmd("norm! zz")
    end, opts)                                -- go to implementation alt

    opts.desc = "Find LSP Implementations"
    keymap.set("n", "gi", function()
        return require("fzf-lua").lsp_implementations({ winopts = { title = "Find LSP Implementations" } })
    end, opts)

    opts.desc = "Find LSP References"
    keymap.set("n", "gR", function()
        return require("fzf-lua").lsp_references({ winopts = { title = "Find LSP References" } })
    end, opts)

    opts.desc = "Go to Declaration"
    keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

    opts.desc = "Find LSP Definitions"
    keymap.set("n", "gd", function()
        return require("fzf-lua").lsp_definitions({ winopts = { title = "Find LSP Definitions" } })
    end, opts)

    opts.desc = "Find LSP Type Definitions"
    keymap.set("n", "gt", function()
        return require("fzf-lua").lsp_typedefs({ winopts = { title = "Find LSP Type Definitions" } })
    end, opts)

    opts.desc = "Find Available Code Actions"
    keymap.set({ "n", "v" }, "<leader>ca", function()
        return require("fzf-lua").lsp_code_actions({
            winopts = {
                -- title = "Code Actions ⚙️",
                title = "Code Actions  ",
                preview = {
                    layout = "vertical",
                    vertical = "up:70%",
                    border = "border",
                },
            },
        })
    end, opts)

    opts.desc = "Smart rename"
    keymap.set("n", "<leader>rn", ":IncRename ", opts) -- smart rename

    opts.desc = "Show line diagnostics"
    keymap.set("n", "<leader>df", vim.diagnostic.open_float, opts) -- show diagnostics for line -- to focus the message, press <leader>df again

    opts.desc = "Go to previous diagnostic"
    keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

    opts.desc = "Go to next diagnostic"
    keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

    opts.desc = "Show documentation for what is under cursor"
    keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

    keymap.set("n", "<leader>C", "<cmd>TroubleClose<CR>", { desc = "Close Trouble Diagnostics View" })

    keymap.set("n", "<leader>fd", function()
        ---@diagnostic disable-next-line: unused-local
        local ok, trouble = pcall(require, "trouble")
        return trouble.toggle("workspace_diagnostics")
    end, { desc = "Find Diagnostics: Current Working Directory" })

    keymap.set("n", "<leader>fc", function()
        ---@diagnostic disable-next-line: unused-local
        local ok, trouble = pcall(require, "trouble")
        return trouble.toggle("document_diagnostics")
    end, { desc = "Find Diagnostics: Current Buffer" })
end

-- used to enable autocompletion (assign to every lsp server config)
local capabilities = cmp_nvim_lsp.default_capabilities()

-- Change the Diagnostic symbols in the sign column (gutter)
local signs = { Error = "▷", Warn = "▷", Hint = "▷", Info = "▷" } -- default

local signsInfo = { ERROR = "▷", WARN = "▷", HINT = "▷", INFO = "▷" } -- default

for type, icon in pairs(signs) do
    local hl = "DiagnosticSign" .. type
    -- local hl = 'DiagnosticSign' .. type:sub(1, 1) .. type:sub(2):lower()
    -- vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    -- vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
    vim.fn.sign_define(hl, { text = "", texthl = hl, numhl = hl })
end

-- change icon in virtual text from diagnostic
vim.diagnostic.config({
    virtual_text = {
        format = function(diagnostic) -- disable this to revert to the default message
            local icon = signsInfo[vim.diagnostic.severity[diagnostic.severity]]
            local message = vim.split(diagnostic.message, "\n")[1]
            return string.format("%s %s ", icon, message)
        end,
        prefix = "󰧞",
        suffiz = "",
    },
    float = {
		border = "rounded",
		-- Show severity icons as prefixes.
		prefix = function(diag) -- disable this to revert to the default message
			local level = vim.diagnostic.severity[diag.severity]
			-- local prefix = string.format(' %s ', diagnostic_icons[level])
			local prefix = string.format(" %s ", signsInfo[level])
			return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
		end,
    },
})

-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
vim.diagnostic.handlers.virtual_text = {
    show = function(ns, bufnr, diagnostics, opts)
        table.sort(diagnostics, function(diag1, diag2)
            return diag1.severity > diag2.severity
        end)
        return show_handler(ns, bufnr, diagnostics, opts)
    end,
    hide = hide_handler,
}

require("lspconfig.ui.windows").default_options.border = "rounded"

-- local border = {
--     { '┌', 'FloatBorder' },
--     { '─', 'FloatBorder' },
--     { '┐', 'FloatBorder' },
--     { '│', 'FloatBorder' },
--     { '┘', 'FloatBorder' },
--     { '─', 'FloatBorder' },
--     { '└', 'FloatBorder' },
--     { '│', 'FloatBorder' },
-- }

local border = {
    { "╭", "FloatBorder" },
    { "─", "FloatBorder" },
    { "╮", "FloatBorder" },
    { "│", "FloatBorder" },
    { "╯", "FloatBorder" },
    { "─", "FloatBorder" },
    { "╰", "FloatBorder" },
    { "│", "FloatBorder" },
}

-- LSP settings (for overriding per client)
local handlers = {
    ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = border }),
    ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = border }),
}

-- configure cpp/c server
lspconfig["clangd"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
    single_file_support = true,
})

-- configure html server
lspconfig["html"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
})

lspconfig["lemminx"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
})

lspconfig.intelephense.setup({
    on_attach = on_attach,
    handlers = handlers,
    capabilities = capabilities,
    autostart = true,
    detached = false,
    root_dir = require("lspconfig").util.root_pattern("composer.json", ".git", "package.json"),
    filetypes = { "php", "blade", "blade.php" },
    -- cmd = { "intelephense", "--stdio" },
    root_pattern = { "composer.json", ".git" },
    settings = {
        intelephense = {
            environment = {
                shortOpenTag = true,
            },
        },
    },
})

lspconfig["vuels"].setup({
	on_attach = on_attach,
	capabilities = capabilities,
	handlers = handlers,
	filetypes = "vue"
})

--  note: Configure Gleam
lspconfig["gleam"].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    handlers = handlers,
})

--   note: Configure yamlls
lspconfig["yamlls"].setup({
    on_attach = on_attach,
    capabilities = capabilities,
    handlers = handlers,
})

-- note: Configure json lsp
lspconfig["jsonls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
})

-- note: Configure css lsp
lspconfig["cssls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
    filetypes = {
        "css",
        "scss",
        "less",
        "postcss",
    },
})

-- configure lua server (with special settings)
lspconfig["lua_ls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
    settings = { -- custom settings for lua
        Lua = {
            -- make the language server recognize "vim" global
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                -- make language server aware of runtime files
                library = {
                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    [vim.fn.stdpath("config") .. "/lua"] = true,
                },
            },
            telemetry = { enable = false },
        },
    },
})

lspconfig["marksman"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
})

lspconfig["dockerls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
})

lspconfig["docker_compose_language_service"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
})

lspconfig["sqlls"].setup({
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,
    filetypes = { "sql" },
    root_dir = function(_)
        return vim.loop.cwd()
    end,
})

-- local os = require('os')
-- local pid = vim.fn.getpid()
local omnisharp = "/usr/local/bin/omnisharp-roslyn/OmniSharp.dll"
--  note: Download Omnisharp, extract and place in /usr/local/bin/omnisharp-roslyn/
--  note: Use this as a guide for where to download Omnisharp => https://aaronbos.dev/posts/csharp-dotnet-neovim
--  note: I downloaded the file => omnisharp-linux-x64-net6.0.tar.gz

lspconfig["omnisharp"].setup({
    -- cmd = { "dotnet", "/path/to/omnisharp/OmniSharp.dll" },
    cmd = { "dotnet", omnisharp },
    capabilities = capabilities,
    on_attach = on_attach,
    handlers = handlers,

    -- new addition - testing
    root_dir = function(fname)
        local primary = require("lspconfig").util.root_pattern("*.sln")(fname)
        local fallback = require("lspconfig").util.root_pattern("*.csproj")(fname)
        return primary or fallback
    end,

    -- Enables support for reading code style, naming convention and analyzer
    -- settings from .editorconfig.
    enable_editorconfig_support = true,

    -- If true, MSBuild project system will only load projects for files that
    -- were opened in the editor. This setting is useful for big C# codebases
    -- and allows for faster initialization of code navigation features only
    -- for projects that are relevant to code that is being edited. With this
    -- setting enabled OmniSharp may load fewer projects and may thus display
    -- incomplete reference lists for symbols.
    enable_ms_build_load_projects_on_demand = false,

    -- Enables support for roslyn analyzers, code fixes and rulesets.
    enable_roslyn_analyzers = true, -- default -> false

    -- Specifies whether 'using' directives should be grouped and sorted during
    -- document formatting.
    organize_imports_on_format = true, -- default -> false

    -- Enables support for showing unimported types and unimported extension
    -- methods in completion lists. When committed, the appropriate using
    -- directive will be added at the top of the current file. This option can
    -- have a negative impact on initial completion responsiveness,
    -- particularly for the first few completion sessions after opening a
    -- solution.
    enable_import_completion = true, -- default false

    -- Specifies whether to include preview versions of the .NET SDK when
    -- determining which version to use for project loading.
    sdk_include_prereleases = true,

    -- Only run analyzers against open files when 'enableRoslynAnalyzers' is true
    analyze_open_documents_only = false,
})
