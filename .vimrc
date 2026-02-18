set nocompatible
syntax on
color blackbeauty
set hlsearch
set incsearch
set ignorecase
set smartcase
set ruler
set tabstop=2
set softtabstop=2
set expandtab
set shiftwidth=2
set re=0
set showcmd
set autoindent
set autoread
set wildchar=<Tab>
set wildmode=list:longest,full
set wrap
setlocal spell spelllang=en
set nospell
set fileformats=unix,mac,dos
set fileformat=unix
set backspace=indent,eol,start
set matchpairs+=<:>,«:»,=:;  "Match angle brackets too
set foldlevelstart=99

" Setup paste mode
set pastetoggle=<F11>
let paste_mode = 0 " 0 = normal, 1 = paste

filetype plugin on "Turn ftplugins on
filetype indent on "Turn ftindent on
filetype on        " Enable filetype detection

if &term == "xterm"
set t_kb=
fixdel
endif

" Insert shebang lines...
iab hbb #!/bin/bash<CR><ESC>:call ToggleComment()<CR><INS><CR><ESC>G
iab hbc #!/bin/csh<CR><ESC>:call ToggleComment()<CR><INS><CR><ESC>G
iab hbs #!/bin/sh<CR><ESC>:call ToggleComment()<CR><INS><CR><ESC>G
iab hbp #!/usr/bin/perl -w<CR><ESC>:call ToggleComment()<ESC>G<INS><CR>use strict;<CR>use warnings;<CR><ESC>G

au BufWritePost * call ModeChange()
au BufRead,BufNewFile * call SetShellSyntax()
au BufRead,BufNewFile *.conf setfiletype sh

" {{{ Key mappings
" Open Url on this line with the browser \w
map <F4> :call Browser ()<CR><CR>

" Disable Ex mode
map Q <Nop>

" Search mappings: These will make it so that going to the next one in a
" search will center on the line it's found in.
map N Nzz
map n nzz

" Clear search highlight
noremap <F11> :call Paste_on_off()<CR>
noremap <f10> <Esc>:nohlsearch<CR><Esc>
map M :%s//\r/g
map # :call ToggleComment()<CR>j0

" find and remove leading white space.
map flw <Esc>:%s/^[ \t]*//<CR><Esc>
map llw <Esc>:s/^[ \t]*//<CR><Esc>
" find and remove trailing white space.
map ftw <Esc>:%s/[ \t]*$//<CR><Esc>
map ltw <Esc>:s/[ \t]*$//<CR><Esc>
" find and remove leading and trailing white space.
map frw <Esc>:%s/^[ \t]*//<CR><ESC>:%s/[ \t]*$//<CR><Esc>
map lrw <Esc>:s/^[ \t]*//<CR><ESC>:s/[ \t]*$//<CR><Esc>
" end find and remove trailing white space

"This unsets the "last search pattern" register by hitting return
nnoremap <CR> :noh<CR><CR>

" }}} End key mappings

" {{{ Functions go here
" my filetype file
function! SetShellSyntax()
if getline(1) =~ "^#!\/bin"
set ft=sh
elseif getline(1) =~ "perl"
set ft=perl
elseif expand("%:e") == "sls"
set ft=sls
set syntax=sls
endif
endfunction

" Define a function that can tell me if a file is executable
function! FileExecutable(fname)
execute "silent! ! test -x" a:fname
return v:shell_error
endfunction

" setting the comment/decomment function
function! ToggleComment()
let filetype = &ft
let currline = getline(".")
if filetype =~ 'java\|typescript'
  if currline =~ '^//'
    s/^\/\///
  elseif currline =~ '\S'
    s/^/\/\//
  endif
else
  if currline =~ '^#'
    s/^#//
  elseif currline =~ '\S'
    s/^/#/
  endif
endif
endfunction

" Automatically make Perl and Shell scripts executable if they aren't already
function ModeChange()
if getline(1) =~ "^#!"
if getline(1) =~ "/bin/"
silent !chmod +x <afile>
endif
endif
endfunction

function! Browser()
let line = getline (".")
"   let line = matchstr (line, "http[^   ]*")
if line =~ "^http"
exec "!/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome ".line
else
exec "!/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome "."'g ".line."'"
endif
endfunction

function! Paste_on_off()
if g:paste_mode == 0
set paste
set noexpandtab
let g:paste_mode = 1
else
set nopaste
set noexpandtab
let g:paste_mode = 0
endif
return
endfunction
" }}} End Functions


let &t_SI .= "\<Esc>[?2004h"
let &t_EI .= "\<Esc>[?2004l"

inoremap <special> <expr> <Esc>[200~ XTermPasteBegin()

function! XTermPasteBegin()
  set pastetoggle=<Esc>[201~
  set paste
  set noexpandtab
  return ""
endfunction

" let g:autopep8_on_save = 1
autocmd FileType python map <buffer> <F3> :call Autopep8()<CR>

au! BufRead,BufNewFile *.json set filetype=json

augroup json_autocmd
  autocmd!
  autocmd FileType json set autoindent
  autocmd FileType json set formatoptions=tcq2l
  autocmd FileType json set textwidth=78 shiftwidth=2
  autocmd FileType json set softtabstop=2 tabstop=8
  autocmd FileType json set expandtab
  autocmd FileType json set foldmethod=syntax
augroup END
