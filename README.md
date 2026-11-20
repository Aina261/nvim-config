# Neovim configuration

A lightweight IDE-like Neovim setup built on [lazy.nvim](https://github.com/folke/lazy.nvim),
the native LSP client and Treesitter. Requires **Neovim 0.11 or newer**.

The leader key is **Space**. `<leader>ff` means: press `Space`, then `f`, then `f`.

## Structure

```
init.lua                   Entry point: leader keys, then loads the modules below
lazy-lock.json             Pinned plugin versions (commit it for reproducible installs)
lua/config/
  options.lua              Editor options
  keymaps.lua              Global keymaps
  lsp_keymaps.lua          Keymaps set when a language server attaches to a buffer
  lazy.lua                 lazy.nvim bootstrap
lua/plugins/
  ui.lua                   Theme, file explorer, status line, which-key
  editor.lua               Telescope, Treesitter, comments, autopairs, git signs
  completion.lua           blink.cmp
  lsp.lua                  lazydev, Mason, nvim-lspconfig
```

Every file in `lua/plugins/` is imported automatically by lazy.nvim.

## Plugins

| Plugin | Purpose |
| --- | --- |
| tokyonight.nvim | Color scheme (`tokyonight-night`) |
| nvim-tree.lua | File explorer |
| lualine.nvim | Status line, including the attached language servers |
| which-key.nvim | Popup listing the available keymaps |
| telescope.nvim | Fuzzy finder for files, text and buffers |
| nvim-treesitter (`main` branch) | Syntax highlighting and indentation |
| Comment.nvim | Toggle comments |
| nvim-autopairs | Close brackets and quotes automatically |
| gitsigns.nvim | Git changes in the gutter |
| blink.cmp + friendly-snippets | Completion (LSP, paths, snippets, buffer) |
| mason.nvim + mason-lspconfig.nvim | Install and enable language servers |
| nvim-lspconfig | Default configuration of each language server |
| lazydev.nvim | Lua language server awareness of the Neovim API |

## Language servers

Installed automatically by Mason and enabled by `mason-lspconfig`:

| Server | Language |
| --- | --- |
| `lua_ls` | Lua |
| `pyright` | Python |
| `ts_ls` | JavaScript / TypeScript |
| `bashls` | Bash / sh |

To add a server, append its name to `LANGUAGE_SERVERS_TO_INSTALL` in `lua/plugins/lsp.lua`.
Only override settings with `vim.lsp.config('<server>', { settings = ... })`: the command,
filetypes and root markers come from nvim-lspconfig.

## Requirements

- Neovim 0.11+ and `git`
- A [Nerd Font](https://www.nerdfonts.com/) for icons
- [`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md)
  (`brew install tree-sitter-cli`): the `main` branch of nvim-treesitter compiles parsers locally.
  Without it, parser installation fails and highlighting is disabled.
- `node` and `npm` (Mason servers `ts_ls`, `pyright` and `bashls`), `ripgrep` (Telescope live grep)

## Keymaps

### Files and windows

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>w` | Normal | Save file |
| `<leader>q` | Normal | Quit window |
| `<leader>da` | Normal | Delete all file content (sent to the black hole register) |
| `<leader>e` | Normal | Focus the file explorer |
| `<Esc>` | Normal | Clear search highlighting |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Normal | Move to the left / bottom / top / right window |

### Search (Telescope)

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>ff` | Normal | Find file in the project |
| `<leader>fg` | Normal | Search text in the project (live grep) |
| `<leader>fb` | Normal | Show open buffers |
| `<leader>fr` | Normal | Fuzzy find text in the current file |

Inside a Telescope prompt: `<C-n>` / `<C-p>` move the selection, `<CR>` opens, `<C-x>` opens in a
horizontal split, `<C-v>` in a vertical split, `<C-t>` in a new tab, `<C-c>` or `<Esc>` closes.

### LSP

Defined in `lua/config/lsp_keymaps.lua`, active only in buffers with an attached server:

| Key | Mode | Action |
| --- | --- | --- |
| `gd` | Normal | Go to definition |
| `gD` | Normal | Go to declaration |
| `<leader>cf` | Normal | Format file (asynchronous) |

Provided by Neovim 0.11+ itself when a server attaches:

| Key | Mode | Action |
| --- | --- | --- |
| `K` | Normal | Show documentation (hover) |
| `grn` | Normal | Rename symbol |
| `gra` | Normal / Visual | Code actions |
| `grr` | Normal | Show references |
| `gri` | Normal | Go to implementation |
| `grt` | Normal | Go to type definition |
| `gO` | Normal | Document symbols |
| `<C-s>` | Insert | Signature help |

### Diagnostics

| Key | Mode | Action |
| --- | --- | --- |
| `[d` | Normal | Jump to the previous diagnostic (opens the float) |
| `]d` | Normal | Jump to the next diagnostic (opens the float) |
| `<leader>xd` | Normal | Show the diagnostic under the cursor |
| `<leader>D` | Normal | Put all diagnostics in the location list |

### Tooling

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>li` | Normal | LSP health information (`:checkhealth vim.lsp`) |
| `<leader>lr` | Normal | Restart the language servers (`:lsp restart`) |
| `<leader>m` | Normal | Open Mason |

### Completion (blink.cmp, `super-tab` preset)

| Key | Mode | Action |
| --- | --- | --- |
| `<Tab>` | Insert | Accept the selected item, or jump to the next snippet field |
| `<S-Tab>` | Insert | Jump to the previous snippet field |
| `<Down>` / `<C-n>` | Insert | Select the next item |
| `<Up>` / `<C-p>` | Insert | Select the previous item |
| `<C-space>` | Insert | Open the menu / toggle documentation |
| `<C-e>` | Insert | Close the menu |
| `<C-d>` / `<C-u>` | Insert | Scroll the documentation down / up |

### Comments (built into Neovim 0.10+, also provided by Comment.nvim)

| Key | Mode | Action |
| --- | --- | --- |
| `gcc` | Normal | Toggle comment on the current line |
| `gc{motion}` | Normal | Toggle comment on a motion (e.g. `gcap` for a paragraph) |
| `gc` | Visual | Toggle comment on the selection |

### File explorer (nvim-tree)

Press `g?` inside the explorer for the full list. The most useful keys:

| Key | Action |
| --- | --- |
| `<CR>` / `o` | Open file or folder |
| `a` | Create a file or folder (end the name with `/` for a folder) |
| `d` | Delete |
| `r` | Rename |
| `x` / `c` / `p` | Cut / copy / paste |
| `R` | Refresh |
| `H` | Toggle hidden files |
| `q` | Close the explorer |

### Discovering more

Press `<leader>` and wait: which-key lists every available continuation.

## Notable options

Relative and absolute line numbers, mouse enabled, smart-case search without highlight,
4-space indentation (spaces), no line wrapping, `scrolloff = 10`, system clipboard shared with
Neovim (`unnamedplus`), splits opening to the right and below.

## Maintenance

| Command | Action |
| --- | --- |
| `:Lazy` | Open the plugin manager |
| `:Lazy restore` | Install the versions pinned in `lazy-lock.json` |
| `:Lazy update` | Update plugins (then review and commit `lazy-lock.json`) |
| `:Mason` | Manage language servers |
| `:checkhealth` | Diagnose the setup |
