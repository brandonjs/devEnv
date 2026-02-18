" from perl snippets
" Format file with perltidy
map ;t 1G!Gperltidy<CR>
" F2 close current window (commonly used with my F1/F3 functions)
noremap <f2> <Esc>:close<CR><Esc>

" perl -cw buffer, using a temp file, into a new window
function! PerlCW()
   let l:tmpfile1 = tempname()
   let l:tmpfile2 = tempname()

   execute "normal:w!" . l:tmpfile1 . "\<CR>"
   execute "normal:! perl -cw ".l:tmpfile1." \> ".l:tmpfile2." 2\>\&1 + \<CR>"
   execute "normal:new\<CR>"
   execute "normal:edit " . l:tmpfile2 . "\<CR>"
endfunction

" perl buffer, using a temp file, into a new window
function! PerlOutput()
   let l:tmpfile1 = tempname()
   let l:tmpfile2 = tempname()

   execute "normal:w!" . l:tmpfile1 . "\<CR>"
   execute "normal:! perl ".l:tmpfile1." \> ".l:tmpfile2." 2\>\&1 \<CR>"
   execute "normal:new\<CR>"
   execute "normal:edit " . l:tmpfile2 . "\<CR>"
endfunction

"function! Unhighlight()
"               :nohlsearch
"endfunction

" Settings for editing perl source (plus bind the above two functions)
function! MyPerlSettings()
   if !did_filetype()
      set filetype=perl
   endif

   set textwidth=80
   set expandtab
   set cindent
   set comments=:#
   set formatoptions=croql
   set keywordprg=man\ -S\ 3
   noremap <f1> <Esc>:call PerlCW()<CR><Esc>
   noremap <f3> <Esc>:call PerlOutput()<CR><Esc>
endfunction

if has("eval")
   augroup SetEditOpts
   au!
   autocmd FileType perl :call MyPerlSettings()
   augroup END
endif
