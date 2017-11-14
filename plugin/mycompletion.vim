" guard {{{1

if exists('g:loaded_mycompletion')
    finish
endif
let g:loaded_mycompletion = 1

" completion mappings {{{1

" Expand snippet or complete, when hitting Tab or S-Tab
ino  <silent>        <Tab>                    <c-r>=mycompletion#snippet_or_complete(1)<cr>
ino  <silent>        <S-Tab>                  <c-r>=mycompletion#snippet_or_complete(-1)<cr>
imap <silent> <expr> <plug>(MC_tab_complete)  mycompletion#tab_complete(1)
imap <silent> <expr> <plug>(MC_stab_complete) mycompletion#tab_complete(-1)

snor <silent>        <Tab>                    <esc>:call UltiSnips#JumpForwards()<cr>
snor <silent>        <S-Tab>                  <esc>:call UltiSnips#JumpBackwards()<cr>

" The next mappings are necessary to prevent custom mappings from interfering.

" Typed/returned by mycompletion#complete()
ino <silent>         <plug>(MC_tab)           <Tab>
ino <silent>         <plug>(MC_c-d)           <c-d>

" Typed/returned by mycompletion#cycle()
ino <silent>         <plug>(MC_c-e)           <c-e>
ino <silent>         <plug>(MC_c-n)           <c-n>
ino <silent>         <plug>(MC_c-p)           <c-p>
ino <silent>         <plug>(MC_c-r)           <c-r>
ino <silent>         <plug>(MC_down)          <down>
ino <silent>         <plug>(MC_up)            <up>

" We don't want recursiveness for those keys when we're in regular insert mode.
" In C-x submode, custom mappings should not interfere.

" cycling mappings {{{1

"                     ┌─ if we override `c-j` in our vimrc, warn us
"                     │
imap <silent> <expr> <unique> <c-j>             pumvisible() ? mycompletion#cycle(1) : '<plug>(MC_c-j)'
ino  <silent>                 <plug>(MC_c-j)    <c-j>

" To cycle back, we can't use `c-k` because it would be shadowed by `c-k c-k`
" (vimrc) which deletes from cursor till end of line.
" It's hard to find a key for this mapping (can't use `c-h`, `c-l`, `c-k`, …).
" We'll try `c-o` with the mnemonics: Old (cycle back).
imap <silent> <expr> <unique> <c-o>             pumvisible() ? mycompletion#cycle(-1) : '<plug>(MC_c-o)'
ino  <silent>                 <plug>(MC_c-o)    <c-o>

imap <silent> <expr> <plug>(MC_next_method)   mycompletion#verify_completion()
imap <silent> <expr> <plug>(MC_Auto)          mycompletion#complete(1)

" autocompletion {{{1

nno <silent>         [om                      :<c-u>call mycompletion#enable_auto()<cr>
nno <silent>         ]om                      :<c-u>call mycompletion#disable_auto()<cr>
nno <silent>         com                      :<c-u>call mycompletion#toggle_auto()<cr>

com! -bar McAutoEnable  call mycompletion#enable_auto()
com! -bar McAutoDisable call mycompletion#disable_auto()
com! -bar McAutoToggle  call mycompletion#toggle_auto()