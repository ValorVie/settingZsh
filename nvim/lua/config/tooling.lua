return {
    lsp = {
        { name = "PHP", mason = "intelephense", command = "intelephense" },
        { name = "Python types", mason = "pyright", command = "pyright-langserver" },
        { name = "Python lint", mason = "ruff", command = "ruff" },
        { name = "TypeScript", mason = "vtsls", command = "vtsls" },
        { name = "ESLint", mason = "eslint-lsp", command = "vscode-eslint-language-server" },
        { name = "JSON", mason = "json-lsp", command = "vscode-json-language-server" },
        { name = "YAML", mason = "yaml-language-server", command = "yaml-language-server" },
        { name = "Docker", mason = "dockerfile-language-server", command = "docker-langserver" },
        {
            name = "Docker Compose",
            mason = "docker-compose-language-service",
            command = "docker-compose-langserver",
        },
        { name = "Markdown", mason = "marksman", command = "marksman" },
        { name = "HTML", mason = "html-lsp", command = "vscode-html-language-server" },
        { name = "CSS", mason = "css-lsp", command = "vscode-css-language-server" },
        { name = "Rust", mason = "rust-analyzer", command = "rust-analyzer" },
    },
    tools = {
        { name = "Black", mason = "black", command = "black" },
        { name = "Prettier", mason = "prettier", command = "prettier" },
        { name = "PHPCS", mason = "phpcs", command = "phpcs" },
        { name = "PHP CS Fixer", mason = "php-cs-fixer", command = "php-cs-fixer" },
        { name = "Hadolint", mason = "hadolint", command = "hadolint" },
        { name = "Markdownlint", mason = "markdownlint-cli2", command = "markdownlint-cli2" },
    },
}
