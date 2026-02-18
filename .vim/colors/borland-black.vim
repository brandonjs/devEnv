" Vim color file
" Maintainer:   Yegappan Lakshmanan
" Last Change:  2001 Sep 9

" Color settings similar to that used in Borland IDE's.

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name="borland"

hi Normal       term=NONE cterm=NONE ctermfg=Yellow ctermbg=Black
hi Normal       gui=NONE guifg=Yellow guibg=Black
hi NonText      term=NONE cterm=NONE ctermfg=White ctermbg=Black
hi NonText      gui=NONE guifg=White guibg=Black

hi Statement    term=NONE cterm=NONE ctermfg=White  ctermbg=Black
hi Statement    gui=NONE guifg=White guibg=Black
hi Special      term=NONE cterm=NONE ctermfg=Cyan ctermbg=Black
hi Special      gui=NONE guifg=Cyan guibg=Black
hi Constant     term=NONE cterm=NONE ctermfg=Magenta ctermbg=Black
hi Constant     gui=NONE guifg=Magenta guibg=Black
hi Comment      term=NONE cterm=NONE ctermfg=Gray ctermbg=Black
hi Comment      gui=NONE guifg=Gray guibg=Black
hi Preproc      term=NONE cterm=NONE ctermfg=Green ctermbg=Black
hi Preproc      gui=NONE guifg=Green guibg=Black
hi Type         term=NONE cterm=NONE ctermfg=White ctermbg=Black
hi Type         gui=NONE guifg=White guibg=Black
hi Identifier   term=NONE cterm=NONE ctermfg=White ctermbg=Black
hi Identifier   gui=NONE guifg=White guibg=Black

hi StatusLine   term=bold cterm=bold ctermfg=Black ctermbg=White
hi StatusLine   gui=bold guifg=Black guibg=White

hi StatusLineNC term=NONE cterm=NONE ctermfg=Black ctermbg=White
hi StatusLineNC gui=NONE guifg=Black guibg=White

hi Visual       term=NONE cterm=NONE ctermfg=Black ctermbg=DarkCyan
hi Visual       gui=NONE guifg=Black guibg=DarkCyan

hi Search       term=NONE cterm=NONE ctermbg=Gray
hi Search       gui=NONE guibg=Gray

hi VertSplit    term=NONE cterm=NONE ctermfg=Black ctermbg=White
hi VertSplit    gui=NONE guifg=Black guibg=White

hi Directory    term=NONE cterm=NONE ctermfg=Green ctermbg=Black
hi Directory    gui=NONE guifg=Green guibg=Black

hi WarningMsg   term=standout cterm=NONE ctermfg=Red ctermbg=Black
hi WarningMsg   gui=standout guifg=Red guibg=Black

hi Error        term=NONE cterm=NONE ctermfg=White ctermbg=Red
hi Error        gui=NONE guifg=White guibg=Red

hi Cursor       ctermfg=Black ctermbg=Yellow
hi Cursor       guifg=Black guibg=Yellow

