" Disable unused providers
let g:loaded_perl_provider = 0
let g:loaded_ruby_provider = 0

:set number
:set relativenumber
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set smarttab
:set softtabstop=4
:set mouse=a

" Treesitter-based folding: collapse functions/classes/blocks to signatures.
" Files open with all folds expanded; use zM/zR/zo/zc to navigate.
:set foldmethod=expr
:set foldexpr=nvim_treesitter#foldexpr()
:set foldlevelstart=99
:set nofoldenable


call plug#begin()

Plug 'http://github.com/tpope/vim-surround' " Surrounding ysw)
Plug 'https://github.com/preservim/nerdtree' " NerdTree
Plug 'https://github.com/vim-airline/vim-airline' " Status bar
Plug 'https://github.com/neoclide/coc.nvim'  " Auto Completion
Plug 'https://github.com/ap/vim-css-color' " CSS Color Preview
Plug 'https://github.com/rafi/awesome-vim-colorschemes' " Retro Scheme
Plug 'https://github.com/ryanoasis/vim-devicons' " Developer Icons
Plug 'https://github.com/github/copilot.vim' " Github Copilot
Plug 'https://github.com/folke/which-key.nvim' " Which Key
Plug 'https://github.com/iamcco/markdown-preview.nvim', { 'do': 'cd app && npx --yes yarn install' } " Markdown Preview
Plug 'https://github.com/MeanderingProgrammer/render-markdown.nvim' " Markdown Renderer
Plug 'norcalli/nvim-colorizer.lua' " Colorizer
Plug 'themaxmarchuk/tailwindcss-colors.nvim' " Tailwind CSS Colors
Plug 'https://github.com/tailwindlabs/tailwindcss-intellisense' " Tailwind CSS IntelliSense
Plug 'neovim/nvim-lspconfig'
Plug 'kabouzeid/nvim-lspinstall'
Plug 'MunifTanjim/nui.nvim' " Dependency for noicevim
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'https://github.com/rcarriga/nvim-notify' " Notifications
Plug 'https://github.com/folke/noice.nvim' " Noice Vim
Plug 'nvim-lua/plenary.nvim' " Required dependency for leetcode.nvim
Plug 'nvim-telescope/telescope.nvim' " Required for leetcode.nvim picker
Plug 'https://github.com/kawre/leetcode.nvim' " Leetcode
Plug 'https://github.com/mrcjkb/haskell-tools.nvim' " haskell
Plug 'https://github.com/folke/flash.nvim' " Flash - rapid navigation
Plug 'https://github.com/lewis6991/gitsigns.nvim' " Git signs in gutter + blame
Plug 'https://github.com/sindrets/diffview.nvim' " Side-by-side diff viewer
Plug 'https://github.com/3rd/image.nvim' " Real pixels via Kitty graphics protocol
Plug 'https://github.com/stevearc/aerial.nvim' " Symbol outline / progressive code structure
Plug 'https://github.com/catppuccin/nvim', { 'as': 'catppuccin' } " Catppuccin theme

call plug#end()

lua << EOF
require("nvim-treesitter.configs").setup({
  highlight = {
    enable = true,
  },
})

require("render-markdown").setup({
  latex = { enabled = false },
  code = {
    style = "full",
    border = "hide",
    width = "full",
    language = true,
    language_icon = true,
    language_name = true,
    inline = true,
  },
})
EOF


let g:NERDTreeDirArrowExpandable="+"
let g:NERDTreeDirArrowCollapsible="~"
let g:NERDTreeShowHidden=1

" Auto start NERD tree when opening a directory
autocmd VimEnter * if argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | wincmd p | endif

autocmd FileType json syntax match Comment +\/\/.\+$+

nnoremap <SPACE> <Nop>
let mapleader=" "

let g:NERDTreeChDirMode = 0

nnoremap <silent> <leader>e :NERDTreeFocus<CR>
nnoremap <silent> <leader>t :NERDTreeToggle<CR>
nnoremap <silent> <leader>m :MarkdownPreviewToggle<CR>

function! s:IsRealFileBuffer() abort
  return &buftype ==# '' && expand('%:p') !=# '' && filereadable(expand('%:p'))
endfunction

function! s:NERDTreeIsVisible() abort
  return exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1
endfunction

function! s:SyncNERDTreeToCurrentFile() abort
  if &filetype ==# 'nerdtree' || !<SID>IsRealFileBuffer() || !<SID>NERDTreeIsVisible()
    return
  endif

  let l:current_win = win_getid()
  silent! NERDTreeFind
  call win_gotoid(l:current_win)
endfunction

augroup nerdtree_sync_current_file
  autocmd!
  autocmd BufEnter * call <SID>SyncNERDTreeToCurrentFile()
augroup END

" If we're in NERDTree, jump to the previous window before running Telescope
function! s:GoPrevIfNERDTree() abort
  if &filetype ==# 'nerdtree'
    wincmd p
  endif
endfunction

" image.nvim — real-pixel image rendering via Kitty graphics protocol.
" Uses the magick CLI processor so we don't need the `magick` luarock.
lua << EOF
local ok_image, image = pcall(require, "image")
if ok_image then
  image.setup({
    backend = "kitty",
    processor = "magick_cli",
    integrations = {},  -- Skip auto-render in markdown/neorg/etc.
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 100,
    window_overlap_clear_enabled = true,
    editor_only_render_when_focused = false,
    -- Auto-hijack on :edit for these extensions. We deliberately omit *.pdf
    -- because image.nvim's magick_cli processor mishandles multi-page PDFs
    -- (ImageMagick splits the output into page-N files, breaking the
    -- expected single-output-path contract). PDFs are pre-converted to PNG
    -- in view_image_in_nvim() instead.
    hijack_file_patterns = {
      "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif",
      "*.bmp", "*.tiff", "*.tif",
    },
  })
end

-- Open an image or PDF in the current window. Image.nvim's BufWinEnter
-- hijack autocmd (configured above) detects the file extension and renders
-- it inline with Kitty graphics protocol. Press `q` to return to the
-- previous buffer.
--
-- PDFs are pre-rasterised with pdftoppm to a temp PNG because image.nvim's
-- magick_cli processor breaks on multi-page PDFs (ImageMagick splits the
-- output into page-N suffixed files, leaving the expected output path empty).
_G.view_image_in_nvim = function(path)
  if not path or path == "" then return end
  if vim.bo.filetype == "nerdtree" then
    vim.cmd("wincmd p")
  end

  local ext = vim.fn.fnamemodify(path, ":e"):lower()
  if ext == "pdf" then
    local prefix = vim.fn.tempname()
    vim.fn.system({ "pdftoppm", "-f", "1", "-l", "1", "-r", "200", "-png", path, prefix })
    if vim.v.shell_error ~= 0 then
      vim.notify("pdftoppm failed for " .. path, vim.log.levels.ERROR)
      return
    end
    local png = prefix .. "-1.png"
    if vim.fn.filereadable(png) == 0 then
      vim.notify("pdftoppm produced no output for " .. path, vim.log.levels.ERROR)
      return
    end
    path = png
  end

  vim.cmd("edit " .. vim.fn.fnameescape(path))

  local buf = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "q", function()
    local alt = vim.fn.bufnr("#")
    if alt > 0 and vim.api.nvim_buf_is_valid(alt) then
      vim.api.nvim_set_current_buf(alt)
    else
      vim.cmd("enew")
    end
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end, { buffer = buf, nowait = true })
end
EOF

" Kitty-graphics image/PDF previewer for Telescope.
" Falls back to `bat` for non-image, non-PDF files so text previews still work.
lua << EOF
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local MEDIA_EXTS = {
  png=true, jpg=true, jpeg=true, gif=true, webp=true, bmp=true,
  tiff=true, tif=true, ico=true, svg=true, heic=true, avif=true, pdf=true,
}

-- Attach this to a picker's `attach_mappings` so <CR> on a media file opens
-- it externally (macOS Preview / default app) instead of loading bytes into nvim.
_G.media_attach_mappings = function(prompt_bufnr, map)
  local function smart_open()
    local entry = action_state.get_selected_entry()
    if entry then
      local path = entry.path or entry.filename or entry.value
      local ext = path and vim.fn.fnamemodify(path, ":e"):lower()
      if ext and MEDIA_EXTS[ext] then
        actions.close(prompt_bufnr)
        _G.view_image_in_nvim(path)
        return
      end
    end
    actions.select_default(prompt_bufnr)
  end
  map({ "i", "n" }, "<CR>", smart_open)
  return true
end

local IMAGE_EXTS = {
  png = true, jpg = true, jpeg = true, gif = true, webp = true,
  bmp = true, tiff = true, tif = true, ico = true, svg = true,
  heic = true, avif = true,
}

_G.kitty_media_previewer = previewers.new_termopen_previewer({
  get_command = function(entry, status)
    local path = entry.path or entry.filename or entry.value
    if not path or path == "" then return { "echo", "" } end
    local ext = vim.fn.fnamemodify(path, ":e"):lower()

    -- Pull preview-window dimensions directly from Neovim instead of relying on
    -- $COLUMNS / $LINES / tput inside the nested PTY (those are flaky).
    local pwin = status and status.preview_win
    local cols = (pwin and vim.api.nvim_win_is_valid(pwin)) and vim.api.nvim_win_get_width(pwin) or 80
    local rows = (pwin and vim.api.nvim_win_is_valid(pwin)) and vim.api.nvim_win_get_height(pwin) or 24
    -- Leave 1 row of headroom so the "[Process exited 0]" banner doesn't clip the image.
    rows = math.max(rows - 1, 1)

    -- Dense symbol set + corrected font-ratio for Kitty's ~1:2 cell aspect.
    -- sextant/octant symbols give 2x3 / 2x4 sub-cell resolution.
    local CHAFA = "chafa --format=symbols --symbols=block+sextant+wedge+space-wide-inverted "
               .. "--colors=truecolor --dither=diffusion --font-ratio=0.5"

    if ext == "pdf" then
      local cmd = string.format(
        [[tmp=$(mktemp -t tspdf) && pdftoppm -f 1 -l 1 -r 200 -png %s "$tmp" >/dev/null 2>&1 && %s --size=%dx%d "$tmp-1.png"; rm -f "$tmp-1.png"]],
        vim.fn.shellescape(path), CHAFA, cols, rows
      )
      return { "sh", "-c", cmd }
    elseif IMAGE_EXTS[ext] then
      local cmd = string.format(
        [[%s --size=%dx%d %s]],
        CHAFA, cols, rows, vim.fn.shellescape(path)
      )
      return { "sh", "-c", cmd }
    else
      -- Plain text fallback. Use bat if present, else cat.
      if vim.fn.executable("bat") == 1 then
        return { "bat", "--style=plain", "--color=always", "--paging=never", path }
      end
      return { "cat", path }
    end
  end,
})
EOF

function! s:TelescopeSmartFiles() abort
  call <SID>GoPrevIfNERDTree()
  lua << EOF
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local entry_display = require("telescope.pickers.entry_display")

-- Get recent files (existing files only)
local recent = {}
local seen = {}
for _, file in ipairs(vim.v.oldfiles) do
  if vim.fn.filereadable(file) == 1 and not seen[file] then
    seen[file] = true
    table.insert(recent, {path = file, recent = true})
    if #recent >= 15 then break end
  end
end

-- Run find_files and get results, then merge
local Job = require("plenary.job")
local all_files = {}

Job:new({
  command = "fd",
  args = {"--type", "f", "--hidden", "--follow", "--exclude", ".git"},
  cwd = vim.fn.getcwd(),
  on_exit = function(j, return_val)
    all_files = j:result()
  end,
}):sync(1000)

-- Merge: recent first, then remaining files
for _, file in ipairs(all_files) do
  if not seen[file] then
    table.insert(recent, {path = file, recent = false})
  end
end

-- Create picker with merged results
pickers.new({}, {
  prompt_title = "Smart Files (Recent → All)",
  finder = finders.new_table({
    results = recent,
    entry_maker = function(entry)
      local displayer = entry_display.create({
        separator = " ",
        items = {
          { width = 2 },
          { remaining = true },
        },
      })
      return {
        value = entry.path,
        display = function()
          local icon = entry.recent and "★ " or "  "
          return displayer({ icon, vim.fn.fnamemodify(entry.path, ":~:.") })
        end,
        ordinal = entry.path,
        filename = entry.path,
        path = entry.path,
      }
    end,
  }),
  sorter = conf.file_sorter({}),
  previewer = _G.kitty_media_previewer,
  attach_mappings = _G.media_attach_mappings,
}):find()
EOF
endfunction

function! s:TelescopeFindFiles() abort
  call <SID>GoPrevIfNERDTree()
  lua require('telescope.builtin').find_files({
    cwd = vim.fn.getcwd(),
    previewer = _G.kitty_media_previewer,
    attach_mappings = _G.media_attach_mappings,
  })
endfunction

function! s:TelescopeRecentFiles() abort
  call <SID>GoPrevIfNERDTree()
  lua require('telescope.builtin').oldfiles({
    prompt_title = 'Recent Files',
    cwd_only = false,
    sort_mru = true,
    sort_lastused = true,
    previewer = _G.kitty_media_previewer,
    attach_mappings = _G.media_attach_mappings,
  })
endfunction

function! s:TelescopeLiveGrep() abort
  call <SID>GoPrevIfNERDTree()
  lua require('telescope.builtin').live_grep({ cwd = vim.fn.getcwd() })
endfunction

nnoremap <silent> <leader>ff :call <SID>TelescopeSmartFiles()<CR>
nnoremap <silent> <leader>fr :call <SID>TelescopeRecentFiles()<CR>
nnoremap <silent> <leader>fF :call <SID>TelescopeFindFiles()<CR>
nnoremap <silent> <leader>fg :call <SID>TelescopeLiveGrep()<CR>

" Telescope git pickers
nnoremap <silent> <leader>gs :lua require('telescope.builtin').git_status()<CR>
nnoremap <silent> <leader>gc :lua require('telescope.builtin').git_commits()<CR>
nnoremap <silent> <leader>gb :lua require('telescope.builtin').git_branches()<CR>

" Diffview keybindings
nnoremap <silent> <leader>gd :DiffviewOpen<CR>
nnoremap <silent> <leader>gD :DiffviewClose<CR>
nnoremap <silent> <leader>gh :DiffviewFileHistory<CR>
nnoremap <silent> <leader>gf :DiffviewFileHistory %<CR>

:set completeopt-=preview " For No Previews

:set clipboard+=unnamedplus

" Catppuccin Mocha (loaded after plug#end so the colorscheme is available)
silent! lua require("catppuccin").setup({
\   flavour = "mocha",
\   transparent_background = true,
\   integrations = {
\     cmp = true, gitsigns = true, nvimtree = false, treesitter = true,
\     telescope = { enabled = true }, which_key = true, flash = true,
\     aerial = true, mason = false, native_lsp = { enabled = true },
\     notify = true, noice = false, render_markdown = true, leap = false,
\   },
\ })
silent! colorscheme catppuccin-mocha

hi Normal guibg=NONE ctermbg=NONE

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

" Having longer updatetime (default is 4000 ms = 4s) leads to noticeable
" delays and poor user experience
set updatetime=300

" Always show the signcolumn, otherwise it would shift the text each time
" diagnostics appear/become resolved
set signcolumn=yes

" Use tab for trigger completion with characters ahead and navigate
" NOTE: There's always complete item selected by default, you may want to enable
" no select by `"suggest.noselect": true` in your configuration file
" NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
" other plugin before putting this into your config
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
" <C-g>u breaks current undo, please make your own choice
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion
if has('nvim')
  inoremap <silent><expr> <c-space> coc#refresh()
else
  inoremap <silent><expr> <c-@> coc#refresh()
endif

" Use `[g` and `]g` to navigate diagnostics
" Use `:CocDiagnostics` to get all diagnostics of current buffer in location list
nmap <silent> [g <Plug>(coc-diagnostic-prev)
nmap <silent> ]g <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Use K to show documentation in preview window
nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

nnoremap <silent> <leader>s :CocCommand prettier.formatFile<CR>

" Leetcode keybindings
nnoremap <silent> <leader>lq :Leet<CR>
nnoremap <silent> <leader>ll :Leet list<CR>
nnoremap <silent> <leader>lr :Leet run<CR>
nnoremap <silent> <leader>ls :Leet submit<CR>

" lua require("noice").setup()
lua require("which-key").setup()

" Which-key descriptions: press the prefix, wait, see the menu.
"   <leader>      → all your leader mappings
"   z             → folds & scrolling
"   g             → goto / coc navigation
"   ]   [         → next/prev (diagnostics, hunks, folds, symbols)
lua << EOF
local wk = require("which-key")
wk.add({
  -- Fold commands (z-prefix)
  { "z",  group = "fold / scroll" },
  { "zM", desc = "Close ALL folds (collapse to signatures)" },
  { "zR", desc = "Open ALL folds" },
  { "za", desc = "Toggle fold under cursor" },
  { "zo", desc = "Open fold under cursor" },
  { "zc", desc = "Close fold under cursor" },
  { "zA", desc = "Toggle fold recursively" },
  { "zO", desc = "Open fold recursively" },
  { "zC", desc = "Close fold recursively" },
  { "zj", desc = "Jump to next fold" },
  { "zk", desc = "Jump to previous fold" },
  { "zz", desc = "Center current line on screen" },
  { "zt", desc = "Scroll current line to top" },
  { "zb", desc = "Scroll current line to bottom" },

  -- Goto / coc navigation (you already have these mapped)
  { "g",  group = "goto" },
  { "gd", desc = "Goto definition" },
  { "gy", desc = "Goto type definition" },
  { "gi", desc = "Goto implementation" },
  { "gr", desc = "Goto references" },

  -- Next / previous
  { "]",  group = "next" },
  { "[",  group = "previous" },
  { "]g", desc = "Next diagnostic" },
  { "[g", desc = "Previous diagnostic" },
  { "]c", desc = "Next git hunk" },
  { "[c", desc = "Previous git hunk" },

  -- Leader groups (so the popup labels them nicely)
  { "<leader>f", group = "find (telescope)" },
  { "<leader>g", group = "git" },
  { "<leader>h", group = "hunk (gitsigns)" },
  { "<leader>l", group = "leetcode" },
  { "<leader>o",  desc = "Aerial: toggle outline pane" },
  { "<leader>fs", desc = "Find symbols (aerial)" },
  { "<leader>e", desc = "NERDTree: focus" },
  { "<leader>t", desc = "NERDTree: toggle" },
  { "<leader>m", desc = "Markdown preview toggle" },
  { "<leader>s", desc = "Format with prettier" },
  { "<leader>L", desc = "Flash: continue search" },
  { "<leader>T", desc = "Flash: treesitter nodes" },
})
EOF

" Gitsigns configuration
lua << EOF
require("gitsigns").setup({
  signs = {
    add = { text = "+" },
    change = { text = "~" },
    delete = { text = "_" },
    topdelete = { text = "‾" },
    changedelete = { text = "~" },
  },
  current_line_blame = true,  -- Show inline git blame
  current_line_blame_opts = {
    delay = 200,
    virt_text_pos = "eol",
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    
    -- Navigation
    vim.keymap.set("n", "]c", gs.next_hunk, { buffer = bufnr, desc = "Next hunk" })
    vim.keymap.set("n", "[c", gs.prev_hunk, { buffer = bufnr, desc = "Previous hunk" })
    
    -- Actions
    vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
    vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { buffer = bufnr, desc = "Reset hunk" })
    vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
    vim.keymap.set("n", "<leader>hb", gs.blame_line, { buffer = bufnr, desc = "Blame line" })
    vim.keymap.set("n", "<leader>hd", gs.diffthis, { buffer = bufnr, desc = "Diff this" })
  end,
})

-- Diffview setup
require("diffview").setup({
  use_icons = true,
})
EOF

" Flash.nvim configuration
lua << EOF
require("flash").setup({
  modes = {
    search = {
      enabled = true,  -- Enable labeled search navigation
    },
    char = {
      enabled = true,
      config = function(opts)
        opts.autohide = true
      end,
    },
  },
})
EOF

" Flash keymaps (using lua functions since <Plug> can be unreliable)
"   s  /  S        forward / backward jump (type chars, pick a label)
"   <leader>L      continue: re-label the matches from your last `/` search
"   <leader>T      treesitter: label every AST node, jump to one
nnoremap <silent> s :lua require("flash").jump()<CR>
nnoremap <silent> S :lua require("flash").jump({search = {forward = false}})<CR>
nnoremap <silent> <Leader>L :lua require("flash").jump({continue = true})<CR>
nnoremap <silent> <Leader>T :lua require("flash").treesitter()<CR>


" Leetcode.nvim configuration
lua << EOF
require("leetcode").setup({
    lang = "python3",
})
EOF

" Aerial: symbol outline / progressive disclosure of code structure.
" <leader>o     toggle the outline pane (right side)
" <leader>O     fuzzy-pick a symbol via Telescope
" {  }          jump to prev/next symbol (works in all buffers when aerial is loaded)
lua << EOF
require("aerial").setup({
  backends = { "treesitter", "lsp", "markdown", "man" },
  layout = {
    default_direction = "right",
    placement = "edge",
    min_width = 30,
  },
  attach_mode = "global",       -- one outline tracks the active window
  show_guides = true,
  filter_kind = false,           -- show every symbol kind (functions, branches, etc.)
  highlight_on_hover = true,
  autojump = true,
  on_attach = function(bufnr)
    vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Aerial prev symbol" })
    vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Aerial next symbol" })
  end,
})

-- Telescope integration: <leader>O fuzzy-finds symbols across the file.
pcall(function() require("telescope").load_extension("aerial") end)
EOF

nnoremap <silent> <leader>o :AerialToggle!<CR>
nnoremap <silent> <leader>fs :Telescope aerial<CR>
