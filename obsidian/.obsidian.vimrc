set clipboard=unnamedplus

" map Ctrl u/d scrolling to Ctrl-Alt j/k and center screen after scrolling 
map <C-A-k> <C-u>zz<CR>
map <C-A-j> <C-d>zz<CR>
map <C-k> <C-u>zz<CR>
map <C-j> <C-d>zz<CR>

" go to front or back of line with leader l/h
noremap <leader>l $
noremap <leader>h 0

" map search command, and also a "sp" as search command with contents of clipboard (* register)
" "sv" only works in visual mode, it puts the selected text into the "a" register and then starts a search with it
" "sw" marks the current word and executs "sv" 
map ss /
map sp /<C-r>*
vnoremap sv \"ay<Esc>/<C-r>a
nnoremap sw viw\"ay<Esc>/<C-r>a
