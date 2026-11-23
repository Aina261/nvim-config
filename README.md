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
  editor.lua               Telescope, Treesitter, comments, autopairs, git signs, PDF viewer
  completion.lua           blink.cmp
  lsp.lua                  lazydev, Mason, nvim-lspconfig
  mason_tools.lua          Full list of Mason packages installed automatically
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
| pdf-view.nvim | View PDF files inside Neovim (iTerm2 inline images) |
| blink.cmp + friendly-snippets | Completion (LSP, paths, snippets, buffer) |
| mason.nvim + mason-lspconfig.nvim | Install and enable language servers |
| mason-tool-installer.nvim | Installs every Mason package listed in `lua/plugins/mason_tools.lua` |
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

## Mason packages

All Mason packages (servers, formatters, linters, debug adapters) are listed in
`MASON_PACKAGES_TO_INSTALL` in `lua/plugins/mason_tools.lua` and installed automatically at
startup by mason-tool-installer, so a new machine gets the same tools. To add one, append its
Mason name to that list (find names with `:Mason`).

Some packages are built with a toolchain that Mason does not provide. If one is needed, install the
toolchain and run `:MasonToolsInstall`:

| Package needs | Install |
| --- | --- |
| `cargo` (Rust packages) | `rustup` or `brew install rust` |
| `luarocks` (Lua packages) | `brew install luarocks` / your package manager |
| JDK and `maven` (Java packages) | `brew install openjdk maven` |
| Python 3.9 to 3.13 (some Python packages) | Mason refuses Python 3.14 and newer |

Packages currently left out for that reason: `gitlab-ci-ls`, `prettypst`, `luacheck`,
`luaformatter`, `java-language-server`, `nginx-language-server`.

## Requirements

| Tool | Why it is needed |
| --- | --- |
| Neovim 0.11+ | Native LSP configuration API (`vim.lsp.config`) |
| `git` | Clones lazy.nvim and every plugin |
| C compiler (`cc` / `gcc` / `clang`) | nvim-treesitter compiles each parser locally |
| [`tree-sitter` CLI](https://github.com/tree-sitter/tree-sitter/blob/master/crates/cli/README.md) | Required by the `main` branch of nvim-treesitter to build parsers. Without it every parser install fails (`error during tree-sitter build`) and highlighting is disabled |
| `tar` and `curl` | nvim-treesitter downloads and unpacks parser sources |
| `node` and `npm` | Mason installs many packages with npm (`ts_ls`, `bashls`, `prettier`, `eslint_d`...) |
| `python3` 3.9 to 3.13 (with `venv`) | Mason installs Python packages (`black`, `sqlfluff`, `python-lsp-server`...) in virtual environments |
| `unzip`, `gzip`, `wget` or `curl` | Mason downloads and unpacks servers (`lua_ls` is a binary release) |
| `ripgrep` (`rg`) | Telescope live grep (`<leader>fg`) |
| `fd` (optional) | Faster file finding in Telescope |
| `mutool` (MuPDF) | pdf-view.nvim renders PDF pages with it |
| A [Nerd Font](https://www.nerdfonts.com/) | Icons in the explorer, status line and Mason |
| Clipboard tool (Linux only) | `clipboard=unnamedplus` needs `xclip`, `xsel` or `wl-clipboard` |

Then set your terminal font to the installed Nerd Font (e.g. `JetBrainsMono Nerd Font`).

## Installation

Install the requirements for your system, put this configuration at the path below, then start
`nvim` once. lazy.nvim installs the plugins, nvim-treesitter builds its parsers and
mason-tool-installer installs all Mason packages (about 57, it takes a few minutes: wait until
the messages stop, then restart Neovim).

| System | Configuration path |
| --- | --- |
| macOS / Linux | `~/.config/nvim` |
| Windows | `%LOCALAPPDATA%\nvim` |

### macOS (Homebrew)

```sh
xcode-select --install   # C compiler, git, tar, curl (skip if already installed)
brew install neovim tree-sitter-cli node python@3.13 ripgrep fd unzip mupdf
brew install --cask font-jetbrains-mono-nerd-font
```

### Linux

Install the Neovim 0.11+ and `tree-sitter-cli` versions from a source that is recent enough:
many distribution repositories ship older ones. Check with `nvim --version`.

Debian / Ubuntu:

```sh
sudo apt update
sudo apt install -y git build-essential python3 python3-venv curl wget unzip tar gzip ripgrep fd-find nodejs npm xclip
sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd   # Debian names the binary fdfind
```

Fedora:

```sh
sudo dnf install -y git gcc make python3 curl wget unzip tar gzip ripgrep fd-find nodejs npm wl-clipboard
```

Arch:

```sh
sudo pacman -S --needed git base-devel python curl wget unzip tar gzip ripgrep fd nodejs npm neovim tree-sitter-cli wl-clipboard
```

Neovim and the `tree-sitter` CLI on Debian / Ubuntu / Fedora (when the packaged versions are too old):

```sh
# Neovim: download the release archive matching your CPU from
# https://github.com/neovim/neovim/releases (or use Homebrew on Linux / snap / flatpak).
# tree-sitter CLI:
sudo npm install -g tree-sitter-cli
# or: cargo install --locked tree-sitter-cli
```

Nerd Font: download one from <https://www.nerdfonts.com/font-downloads>, unzip it into
`~/.local/share/fonts`, then run `fc-cache -fv`.

### Windows

Run in PowerShell (Windows 10 / 11 already ship `tar` and `curl`):

```powershell
winget install Neovim.Neovim Git.Git OpenJS.NodeJS.LTS Python.Python.3.13 BurntSushi.ripgrep.MSVC sharkdp.fd 7zip.7zip
winget install tree-sitter.tree-sitter-cli   # or: npm install -g tree-sitter-cli
winget install zig.zig                       # C compiler for treesitter parsers
```

A C compiler is mandatory. Pick one:

- `zig` (installed above): the simplest option, nvim-treesitter detects it.
- Visual Studio Build Tools with the "Desktop development with C++" workload
  (`winget install Microsoft.VisualStudio.2022.BuildTools`), then start Neovim from the
  "Developer PowerShell for VS".
- MinGW-w64 (`scoop install mingw` or MSYS2) with `gcc` available in `PATH`.

Install a Nerd Font (`scoop bucket add nerd-fonts` then `scoop install JetBrainsMono-NF`, or download
it from the Nerd Fonts site) and select it in Windows Terminal. Then open a new terminal so that
`PATH` is refreshed. Using WSL instead? Follow the Linux instructions inside the WSL distribution.

### Verify the installation

```sh
nvim --version                      # 0.11 or newer
tree-sitter --version
nvim --headless "+checkhealth nvim-treesitter" +qa
```

Inside Neovim run `:checkhealth nvim-treesitter lazy mason telescope vim.lsp`: nothing should be
reported as `ERROR` for the tools listed above. Warnings about the Node, Python, Perl and Ruby
providers and about `luarocks` are harmless for this configuration.

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

### PDF viewer (pdf-view.nvim)

Opening a `.pdf` (`:e file.pdf`, `nvim file.pdf`, nvim-tree) shows it as a page image. Press `g?` in the viewer for the full list.

| Key | Action |
| --- | --- |
| `j` / `k` | Scroll, turning the page at the edge |
| `<PageDown>` / `<PageUp>` | Next / previous page |
| `+` / `-` / `0` | Zoom in / out / fit page |
| `/` | Search |
| `gO` | Document outline |
| `i` | Toggle dark mode |
| `q` | Close the viewer |

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
