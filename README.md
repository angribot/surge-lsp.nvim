# surge-lsp.nvim

Lightweight Surge highlighting and optional official LSP diagnostics for Neovim.
No compilation, Tree-sitter, Node.js, or `nvim-lspconfig` required.

Highlighting uses independently written Vim syntax rules.

## Requirements

- Neovim 0.12 or later.
- For diagnostics only: macOS, Surge Mac 6.10.0 or later, and `surge-cli`
  available on Neovim's `PATH`.

Highlighting does not require Surge or an enabled language server.

## Install

Install this repository with your plugin manager or as a standard
`pack/*/start` package. No `setup()` call is needed. Do not lazy-load it on
`ft = 'sgconf'`: the plugin itself registers that file type.

Neovim normally enables syntax and filetype plugins by default. If your
configuration disables them, enable them with:

```vim
filetype plugin on
syntax enable
```

Optionally enable diagnostics in `init.lua`, after making the plugin available
on the runtime path:

```lua
vim.lsp.enable('surge')
```

Use this plugin instead of `nvim-treesitter-sgconf`, not alongside it, to avoid
competing highlighters and LSP configurations. An existing
`~/.config/nvim/lsp/surge.lua` takes precedence over the bundled LSP config;
remove or update that override when migrating.

## File detection

The plugin recognizes:

- `*.sgmodule` anywhere.
- `*.conf` and `*.dconf`, including nested directories, beneath:
  - `~/Library/Application Support/Surge/Profiles/`
  - `~/Library/Mobile Documents/iCloud~com~nssurge~inc/Documents/`

These files use the `sgconf` file type and `# %s` comment string. Other `.conf`
files, `.sgconf`, `.lsr`, and `.list` are not automatically recognized.
For a configuration elsewhere, use `:setfiletype sgconf`, or
`:setlocal filetype=sgconf` to override an existing file type.

File detection is registered on plugin load, independently of LSP activation.
If you load the plugin after opening a file, reopen it or set its file type
manually.

## Highlighting

`syntax/sgconf.vim` provides basic lexical highlighting for:

- Section headers, assignment names, and comma-separated parameter names.
- Common rule types and built-in policies.
- Booleans, numbers, delimiters, and double-quoted strings.
- Comments, TODO markers, and module directives.

Highlight groups link to standard theme groups using `highlight default link`.
This is intentionally not a full parser: it does not validate section-specific
keys, parse embedded scripts or regular expressions, or provide Tree-sitter
folds, text objects, or structural navigation. Unknown rule types may remain
uncolored; diagnostics remain the official server's responsibility.

## Diagnostics

`lsp/surge.lua` runs `{ 'surge-cli', 'lsp' }`. Configuration documents use the
`surge` language ID; modules use `surge-module`. `.lsr` and `.list` are excluded
even if manually assigned `sgconf`; RULE-SET and DOMAIN-SET diagnostics are
outside this plugin's scope.

Errors and warnings use Neovim's built-in diagnostics, including unknown
`[General]` key warnings. The server runs offline without a running Surge app
and does not apply configuration changes.

Buffers share a rootless server instance. Open a main profile alongside its
included `.dconf` files for policy and script reference checks. Standalone
fragments receive syntax checks; the main must actually reference the fragment
with `#!include` for context to apply.

When multiple main profiles include the same fragment with different
definitions, the last validation can replace its diagnostics. Keep only the
relevant main profile open for unambiguous results.

To override the command, configure it before enabling:

```lua
vim.lsp.config('surge', {
  cmd = { '/custom/path/surge-cli', 'lsp' },
})
vim.lsp.enable('surge')
```

The plugin does not search for, install, or version-check the CLI. For startup
failures, check `:checkhealth vim.lsp`, `:echo executable('surge-cli')`, and the
log at `:lua print(vim.lsp.log.get_filename())`.

Restart diagnostics with:

```lua
vim.lsp.enable('surge', false)
vim.lsp.enable('surge')
```

## License

MIT. See [LICENSE](LICENSE).
