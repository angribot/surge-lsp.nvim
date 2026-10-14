# surge-lsp.nvim

Lightweight Surge highlighting and opt-in official LSP diagnostics for Neovim.

A Neovim plugin modeled after the official [Surge language support extension for VS Code](https://marketplace.visualstudio.com/items?itemName=SurgeNetworks.surge-language-support).

## Requirements and installation

- Neovim 0.12 or later.
- For diagnostics: macOS and Surge Mac 6.10.0 or later. The default CLI path is
  `/Applications/Surge.app/Contents/Applications/surge-cli`; override it if Surge
  is installed elsewhere.

Install with your plugin manager or as a `pack/*/start` package. No `setup()`
call is needed. Do not lazy-load by filetype: the plugin registers detection.
Highlighting works without Surge. If disabled in your configuration, enable
`filetype plugin on` and `syntax enable`.

Enable diagnostics explicitly, after the plugin is on the runtime path:

```lua
vim.lsp.enable('surge')
```

Use this plugin instead of `nvim-treesitter-sgconf`, not alongside it.
An existing `~/.config/nvim/lsp/surge.lua` takes precedence over the bundled
configuration; remove or update that override when migrating.

## Filetypes and detection

| Neovim filetype | LSP language ID | Filename associations |
| --- | --- | --- |
| `surge` | `surge` | `*.sgconf`, `*.dconf`, `Surge.conf` |
| `surge_module` | `surge-module` | `*.sgmodule` |
| `surge_ruleset` | `surge-ruleset` | Content detection or manual selection |
| `sgconf` (legacy) | `surge`, or `surge-module` for `.sgmodule` | Manual/user association |

All four use `# %s` as their comment string. Separate filetypes take precedence
over filenames when choosing the language ID. Legacy `sgconf` remains supported
for existing configurations, but is no longer the automatically assigned type.

Content/location detection follows the conservative recognition criteria of the
**official Surge VSCode extension 0.1.9**:

- `.conf` files in a `Library/Application Support/Surge/Profiles/` or
  `Library/Mobile Documents/iCloud~com~nssurge~inc/Documents/Profiles/` directory
  are profiles, including nested files.
- Elsewhere, `.conf` files need `[Rule]` plus `[Proxy]` or `[Proxy Group]`.
  Section names are case-sensitive; trailing comments are allowed.
- `.conf`, `.txt`, `.module`, and extensionless module candidates need a nonempty
  `#!name = ...` before the first section. Module evidence takes precedence.
- RULE-SET detection requires at least two recognized rule lines, ignoring
  blank/comment lines. All examined rules must have a condition and only known
  options (`no-resolve`, `extended-matching`, `pre-matching`, `debug`), not a
  policy column. Recognition stops checking rules after 20 valid entries.
  Quoted conditions are supported. `.list`/`.lsr` alone imply nothing.
- Plain domain lists (DOMAIN-SET), YAML payloads, and profile rule blocks with
  policy columns are not automatically treated as standalone RULE-SET files.

Recognition inspects only complete lines within the first **65,536 bytes** of
buffer content, including unsaved edits. It does not read the file again or
validate rule values. The byte limit is intentionally not VSCode's UTF-16 limit.

### Native Neovim precedence

Content recognition is a lowest-priority `vim.filetype.add` fallback. Existing
filename/extension/pattern associations win, and detection never overwrites a
nonempty buffer filetype. Unlike VSCode, Neovim does not expose whether a generic
filetype was explicitly chosen. Consequently, default `text` (`.txt`), `dosini`
(`.ini`), and other already-associated types are preserved too; use a manual
filetype for those documents. Unmatched `.conf` files can be recognized before
Neovim's generic configuration fallback.

Untyped named buffers are reconsidered on `TextChanged`/`TextChangedI`; buffers
already assigned a type are not reclassified after edits. Special buffers,
URI-style names, and unnamed buffers are not content-detected. For late plugin
loading, reopen the file or select a filetype manually. There are no timers,
VSCode-style language-change tracking, or lifecycle emulation.

Disable heuristic content/location detection in `init.lua`:

```lua
vim.g.surge_auto_detect = false
```

Explicit filename associations above remain active, like the extension's
contributed language associations. Existing buffers are not reclassified.

Select a type explicitly, overriding the current type:

```vim
:setlocal filetype=surge
:setlocal filetype=surge_module
:setlocal filetype=surge_ruleset
```

Use `:setfiletype surge` only when a buffer has no established type. For persistent
associations, configure Neovim normally (after this plugin loads when replacing
one of its exact mappings):

```lua
vim.filetype.add({
  filename = { ['work-profile.conf'] = 'surge' },
  extension = { myrules = 'surge_ruleset' },
  pattern = { ['.*/not-surge/.*%.conf'] = 'dosini' },
})
```

## Highlighting

Native Vim syntax highlighting follows the official Surge VSCode extension
**0.1.9** for profiles, modules, and RULE-SET files, without a TextMate runtime
or extra dependencies. It covers:

- Proxy/policy-group definitions, members, and parameters.
- Rule conditions, policy references, modifiers, and recursive logical rules;
  inline and standalone RULE-SET entries share the policy-free grammar.
- Script names, recognized script types, and pattern parameters.
- URL/Header/Body Rewrite fields, capture references, and jq forms.
- Comments, directives, placeholders, quoted/unquoted values, URLs, IPv4
  addresses, numbers, and constants, including outside sections.

Section names are case-sensitive and exact: `[ Rule ]` is not `[Rule]`.
As upstream does, any line beginning with `[` after indentation ends the
previous section, even an unfinished header or bracket-led rewrite pattern.
Incomplete constructs fall back to ordinary value highlighting.

This aligns lexical categories, not theme colors or TextMate scope stacks.
Word/digit classes use Neovim's native ASCII-oriented patterns: boundaries
around non-ASCII letters, digits, or combining marks can differ from Oniguruma.
Unicode text in names, strings, conditions, and placeholders remains supported.
TextMate tokenizer recovery quirks on malformed input are not emulated.
Regexes, scripts, and jq are not parsed as embedded languages.

Highlighting works without Surge installed and does not validate configuration;
enable diagnostics for that. Colors depend on your Neovim theme. Override the
`sgconf*` highlight groups to customize them; standalone RULE-SET files also
expose `surgeRulesetType` and `surgeRulesetComment`. All links use
`highlight default link`.

## Diagnostics

The bundled config runs
`{ '/Applications/Surge.app/Contents/Applications/surge-cli', 'lsp' }`, matching
the official VSCode extension's default path. Configurations, modules, and
RULE-SET buffers are all eligible, including manually selected `.list`/`.lsr`
files. DOMAIN-SET validation is not provided by selecting RULE-SET mode.
Diagnostics use Neovim's built-in UI. The server runs offline and does not apply
configuration changes to Surge.

Buffers share a rootless server instance. Open the main profile alongside its
included `.dconf` fragments for policy and script reference checks; the main must
actually reference the fragment with `#!include`. Standalone fragments receive
syntax checks. If multiple main profiles include the same fragment with different
definitions, the last validation can replace its diagnostics. Keep only the
relevant main profile open for unambiguous results.

Override the command using normal Neovim configuration, before enabling. For
example, to use a compatible `surge-cli` on `PATH` instead:

```lua
vim.lsp.config('surge', {
  cmd = { 'surge-cli', 'lsp' },
})
vim.lsp.enable('surge')
```

Neither this plugin nor the official extension installs the CLI or searches for
it automatically; the CLI ships with Surge. Unlike the VSCode extension, this
plugin does not perform a compatibility preflight or automatically enable the
server. It does not install a workspace-wide file watcher; context updates
depend on the server and Neovim's LSP synchronization rather than VSCode's broad
watcher. For failures, check `:checkhealth vim.lsp`, verify the configured
executable (by default,
`:echo executable('/Applications/Surge.app/Contents/Applications/surge-cli')`),
and inspect `:lua print(vim.lsp.log.get_filename())`.

Restart with:

```lua
vim.lsp.enable('surge', false)
vim.lsp.enable('surge')
```

## License

MIT. See [LICENSE](LICENSE). The official extension was consulted only as a
behavioral reference; its source and grammars are not included or copied.
