" FIXME: "{{{
"
" If I hit C-x C-p C-k at the end of this line:
"
"     License: This file
"
" I have the following error:
"
"         Error detected while processing function
"         mucomplete#cycle[2]..<SNR>66_next_method:
"         line    1:
"         E121: Undefined variable: s:N
"         Error detected while processing function
"         mucomplete#cycle[2]..<SNR>66_next_method:
"         line    1:
"         E15: Invalid expression: (s:cycle ? (s:idx + s:dir + s:N) % s:N : s:idx + s:dir)
"
" Note:
" C-k is used to cycle backward in the completion chain.
" By default, it was C-h. I changed the mapping.
" The bug occurs when you type a key to move backward OR forward in the chain,
" without having hitting Tab once before;
" and you have:
"
"     let g:mc_cycle_with_trigger = 1
"
" … in your vimrc
"
" In fact, the bug occurs when the user asks to move in the chain (cycle)
" without having invoked a method in the chain at least once.
"
" Initially, I thought the solution was to initialize `s:N` in `cycle()`,
" exactly as it was defined in `complete()`.
" But then, I realized that it wasn't a good idea to let the user call
" `s:next_method()`, without having entered the chain at least once.
" If he's never entered the chain, he has no position inside it.
" So, there's no reference point on which base our relative motion in the chain.
" IOW, it doesn't make sense to try and support this weird / edge case.
"
" Maybe the best solution is to prevent `s:next_method()` to be called
" when the user never invoked a methode in the chain.
"
" How do we know whether they invoked a method?
" If they did, the `mucomplete#complete()` function was invoked at least once.
" It it was, it must have created the variable `s:N`.
" Besides, `s:N` is only created inside `mucomplete#complete()`, nowhere else.
" It means there's an equivalence between the existence of this variable and the
" user having invoked a method at least once.
"
" So, to fix this bug, inside `mucomplete#cycle()` we could test the existence
" of `s:N` before invoking `s:next_method()`.
"
"}}}
"FIXME: "{{{
"
" Write this in `/tmp/vimrc.vim`:

" let g:mucomplete#cycle_with_trigger = 1
" let g:mc_cycle_with_trigger = 1
" set cot=menuone
" set rtp+=~/.vim/plugged/vim-mucomplete
" setlocal tw=78
"
"    xx                                                  zzz
" zzzyyyyyyyyyyyyyyyyyyy


" Uncomment the 5 first lines of code.
" Launch Vim like this:
"
"     $ vim -Nu /tmp/vimrc.vim /tmp/vimrc.vim
"
" Place the cursor after `zzz` and hit Tab twice.
" The plugin gets stuck in a loop (high cpu).
"
" In fact we don't even need the first 2 lines.
" We can reproduce the bug without them, by hitting the key to move
" forward in the completion chain (C-j, …).

"}}}
" FIXME: "{{{
"
" I think lifepillar made a conceptual mistake in the original code.
" He allowed the user to define its own version of
" `g:mucomplete#can_complete.default`
" Then, the plugin merges whatever the user defined in there with some default
" value, via `extend()`.
" It works, but if the user source their vimrc a second time, the default
" values of the plugin are lost.
"
""}}}
" FIXME:"{{{
"
" In the `ulti` method, I think lifepillar introduced a regression here:
"
"     https://github.com/lifepillar/vim-mucomplete/issues/28
"
" Because, he inverted the order of the arguments passed to `stridx()`, which
" seems to prevent the `ulti` method to function properly.
"
" "}}}
" FIXME: "{{{

" In the completion mapping for the 'spel' method:
"
"         \ 'spel': "\<c-o>:\<cr>\<c-r>=mucomplete#spel#complete()\<cr>",
"
" … why do we prefix it with `\<c-o>:\<cr>`?
"
" If we configure the chain completion, like this:
"
"         let g:mc_chain = ['keyn', 'spel']
"
" … we enter a buffer and enable the spell correction (`cos`),
" we type `helo`, and hit `Tab` to complete/correct the word into `hello`.
" The menu opens but when we type `C-n`, it doesn't select the first entry.
" It gives us the message:
"
"         Keyword Local completion Back at original
"
" The second time we hit `C-n`, we can finally choose our correction.
" But why only after the 2nd time?
" And why does it seem that the plugin tries the `keyn` method?
" `C-n` shouldn't make it do that.
"
" The current solution seems this weird prefix.
" But I don't understand it.

""}}}
" FIXME: "{{{
"
" Given the following buffer `foo`:
"
"     hello world
"     hello world
"     hello world

" And the following `vimrc`:
"
"     set cot+=noselect,menu,menuone
"     set rtp+=~/.vim/plugged/vim-mucomplete

" Start Vim like this:
"
"     $ vim -Nu vimrc foo
"
" Hit `*` on `world` to populate the search register.
" Type `cgn`, to change the last used search pattern.
" Insert `wo`, then `Tab` to complete `wo`.
" Hit escape to go back in normal mode.
" Hit `.` to repeat the change to the next occurrence of `hello`.
" `hello` is changed into `wo` instead of the last completed text.
"
" Does the plugin breaks the undo sequence when we hit Tab?
" Yes, it seems that `s:act_on_pumvisible()` sometimes hit Up or Down,
" to force the insertion of an entry, no matter the value of 'cot'.
" It probably breaks the undo sequence, and somehow the dot command/register
" only remembers what was inserted before.
"
" This is a bit weird, because when the undo sequence is broken, dot usually
" remembers what was inserted AFTER (not before).
" You can check it by inserting foo, then hitting `Up` or `Down`, then inserting
" bar. Leave insert mode then hit dot. `bar` will be inserted, not `foo`.
"
" Anyway, Up/Down breaks the undo sequence, so whatever the dot command will
" remember, it will always be incomplete.
"
" But the problem isn't always present. It depends on the value of 'cot'.
" In the original plugin, the bug occurs when 'cot' contains 'noselect', or
" when it doesn't contain 'noselect', but does contain 'noinsert'.
"
" I fixed the bug in the the 2nd case, by replacing `Up` with `C-p`.
" But I didn't fixed it in the 1st case.
" Indeed, in the 2nd case, 'cot' contains ONLY 'noinsert'.
" So, the user just wants to prevent the insertion; he's still OK with the
" selection.
" All we have to do to force the insertion is sth like:
"
"         Up  C-n    (lifepillar) works but breaks   undo sequence
"         C-p C-n    (me)         works and preserve undo sequence
"
" However, in the 1st case, the user has 'noselect', so he doesn't want an
" entry to be selected. In this case, Vim doesn't do anything. To force, the
" insertion without selecting anything (to respect the user's decision),
" there's only one solution:
"
"         C-n Up    (lifepillar) works but breaks undo sequence
"
" The other solutions would either not work or violate a user's decision:
"
"         C-n       (me)         works but doesn't respect the user's decision
"                                of not selecting an entry
"
"         C-n C-p   (me)         doesn't work at all
"                                C-n would temporarily insert an entry,
"                                then C-p would immediately remove it
"
"}}}
" FIXME: "{{{
"
" The 'uspl' method of lifepillar doesn't work when the cursor is just at the
" end of word but not at the end of the line.
" Example:
"
"     helzo| people
"
" The pipe represents the cursor, where the method is invoked.
" 'uspl' tries to fix the word `people` instead of `helzo`.
" It probably comes down to the usage of the `:norm` command.
"
" Besides the method uses 2 functions, one to collect suggestions, and another
" to display them in a menu.
"
" One function could be enough. And we could get rid of the problematic
" `:norm` command, using the `spellbadword()` and `spellsuggest()` functions.
" It would fix the first issue.
"
" Tell lifepillar about it. Share our implementation.
" And ask him, why we have to prefix our mapping with `C-o : CR` to avoid
" a spurious bug.
"
"}}}
" FIXME: "{{{
"
" The methods `c-n` and `c-p` are tricky to invoke.
"
" Indeed, we don't know in advance WHEN they will be invoked.
" As the first ones? Or after other failing methods?
"
" For example, if `c-n` is the first method to be invoked after hitting Tab,
" then there's NO problem.
" But if it's invoked after another one, there MIGHT be a problem.
" Suppose the previous failing method left us in `C-x` submode (C-x C-…),
" then `C-n` will be interpreted, WRONGLY, as an attempt to cycle in the menu.
" So, we should prefix `C-n` with `C-e` to exit `C-x` submode, right?
" Nope.
" Because then, if the `C-n` method was the first one to be invoked, then
" `C-e` will be interpreted as ’copy the character below the current one’.
"
" MUcomplete.vim chooses the solution of prefixing the trigger keys with:
"
"         C-x C-b BS
"
" What does it do?
" `C-b` is not a valid key in C-x submode. Any invalid key makes us leave the
" submode, and is inserted. So, we leave the submode, C-b is inserted, and BS
" deletes it.
" And why did lifepillar choose SPECIFICALLY C-b?
" For 2 reasons.
"
"     1 - It's invalid in C-x submode, as we just saw it.
"     2 - It's unmapped in basic insert mode, see: :h i_CTRL-B-gone
"
" So, C-b is a good choice because it won't cause any side-effect.
"
" All in all, this trick works.
" BUT, there's a problem for me. I have remapped C-B to move the cursor back.
" Because of this, the trick won't work.
"
" We have to choose another key. I'm going to use `C-g C-g`.
" Why this key?
" Because by default, C-g is used as a prefix in insert mode for various kind
" of actions. To get a list of them, type: :h i_^g C-d
" Currently, behind this prefix, there is:
"
"         CTRL-J
"         CTRL-K
"         Down
"         Up
"         j
"         k
"         u
"         U
"
" Vim may map other actions in the future on other keys, but for the moment
" nothing is mapped on CTRL-G.
"
" It seems to work, but are we sure it is as good as `C-x C-b`?
" Ask lifepillar what he thinks, here:
"
"     https://github.com/lifepillar/vim-mucomplete/issues/4
"
" But don't ask him to integrate the change. He doesn't want. He added the tag
" `wontfix` and closed the issue.
"
" "}}}
" Why do we need to prepend `s:exit_ctrl_x` in front of "\<c-x>\<c-l>"? "{{{
"
" Suppose we have the following buffer:
"
"     hello world
"
" On another line, we write:
"
"     hello C-x C-l
"
" The line completion suggests us `hello world`, but we refuse and go on typing:
"
"     hello people
"
" If we hit C-x C-l again, the line completion will insert a newline.
" Why?
" It's probably one of Vim's quirks / bugs.
" It shouldn't insert anything, because now the line is unique.
"
" According to lifepillar, this can cause a problem when autocompletion
" is enabled.
" I can see how. The user set up line completion in his completion chain.
" Line completion is invoked automatically but he refuses the suggestion,
" and goes on typing. Later, line completion is invoked a second time.
" This time, there will be no suggestion, because the current line is likely
" unique (the user typed something that was nowhere else), but line completion
" will still insert a newline.
"
" Here's what lifepillar commented on the patch that introduced it:
"
"     Fix 'line' completion method inserting a new line.

"     Line completion seems to work differently from other completion methods:
"     typing a character that does not belong to an entry does not exit
"     completion. Before this commit, with autocompletion on such behaviour
"     resulted in µcomplete inserting a new line while the user was typing,
"     because µcomplete would insert <c-x><c-l> while in ctrl-x submode.

"     To fix that, we use the same trick as with 'c-p': make sure that we are
"     out of ctrl-x submode before typing <c-x><c-l>.
"
" To find the commit:
"
"     $ gsearch 's:cnp."\<c-x>\<c-l>"'
"
" There's a case, though, where adding a newline can make sense for line
" completion. When we're at the END of a line existing in multiple places, and
" we hit `C-x C-l`. Invoking line completion twice inserts a newline to suggest
" us the next line:
"
"     We have 2 identical lines:    L1 and L1'
"     After L1, there's L2.
"     The cursor is at the end of L1'.
"     The first `C-x C-l` invocation only suggests L1.
"     The second one inserts a newline and suggests L2.
"
"}}}

let s:exit_ctrl_x = "\<c-g>\<c-g>"
let s:compl_mappings = {
                       \ 'c-n' : s:exit_ctrl_x."\<c-n>",
                       \ 'c-p' : s:exit_ctrl_x."\<c-p>",
                       \ 'defs': "\<c-x>\<c-d>",
                       \ 'file': "\<c-x>\<c-f>",
                       \ 'incl': "\<c-x>\<c-i>",
                       \ 'dict': "\<c-x>\<c-k>",
                       \ 'line': s:exit_ctrl_x."\<c-x>\<c-l>",
                       \ 'keyn': "\<c-x>\<c-n>",
                       \ 'omni': "\<c-x>\<c-o>",
                       \ 'keyp': "\<c-x>\<c-p>",
                       \ 'thes': "\<c-x>\<c-t>",
                       \ 'user': "\<c-x>\<c-u>",
                       \ 'cmd' : "\<c-x>\<c-v>",
                       \ 'tags': "\<c-x>\<c-]>",
                       \ 'path': "\<c-r>=mucomplete#path#complete()\<cr>",
                       \ 'ulti': "\<c-r>=mucomplete#ultisnips#complete()\<cr>",
                       \ 'spel': "\<c-o>:\<cr>\<c-r>=mucomplete#spel#complete()\<cr>",
                       \ }

unlet s:exit_ctrl_x

let s:select_entry = { 'c-p' : "\<c-p>\<down>", 'keyp': "\<c-p>\<down>" }
" Internal state
let s:methods      = []
let s:word         = ''
let s:auto         = 0
let s:dir          = 1
let s:cycle        = 0
let s:idx          = 0
let s:pumvisible   = 0

fu! s:act_on_textchanged() abort
    if s:completedone
        let s:completedone = 0
        let g:mucomplete_with_key = 0

        if get(s:methods, s:idx, '') ==# 'path' && getline('.')[col('.')-2] =~# '\m\f'
            sil call mucomplete#path#complete()

        elseif get(s:methods, s:idx, '') ==# 'file' && getline('.')[col('.')-2] =~# '\m\f'
            sil call feedkeys("\<c-x>\<c-f>", 'i')
        endif

    elseif match(strpart(getline('.'), 0, col('.') - 1),
                \  { exists('b:mc_trigger_auto_pattern') ? 'b:' : 'g:' }mc_trigger_auto_pattern) > -1
        sil call feedkeys("\<plug>(MUcompleteAuto)", 'i')
    endif
endfu

fu! mucomplete#enable_auto() abort
    let s:completedone        = 0
    let g:mucomplete_with_key = 0

    augroup MUcompleteAuto
        autocmd!
        autocmd TextChangedI * noautocmd call s:act_on_textchanged()
        autocmd CompleteDone * noautocmd let s:completedone = 1
    augroup END
    let s:auto = 1
endfu

fu! mucomplete#disable_auto() abort
    if exists('#MUcompleteAuto')
        autocmd! MUcompleteAuto
        augroup! MUcompleteAuto
    endif
    let s:auto = 0
endfu

fu! mucomplete#toggle_auto() abort
    if exists('#MUcompleteAuto')
        call mucomplete#disable_auto()
        echom '[MUcomplete] Auto off'
    else
        call mucomplete#enable_auto()
        echom '[MUcomplete] Auto on'
    endif
endfu

" Default pattern to decide when automatic completion should be triggered.
let g:mc_trigger_auto_pattern = '\k\k$'

" Default completion chain
let g:mc_chain = ['file', 'omni', 'keyn', 'dict', 'spel', 'path', 'ulti']

" Conditions to be verified for a given method to be applied."{{{
"
" Explanation of the regex for the file completion method:
"
"     \v[/~]\f*$
"
" Before the cursor, there must a slash or a tilda, then zero or more characters
" in 'isfname'.
" By default the tilda is in 'isf', so why not simply:
"
"     \v/?\f*
"
" Because then, it would match anything. The condition would be useless.
" At the very least, we want a slash or a tilda before the cursor.
" The filename characters afterwards are optional, because we could try to
" complete `some_dir/` or just `~`.
"
"}}}

let s:yes_you_can   = { _ -> 1 }
let g:mc_conditions = {
                      \ 'dict': { t -> strlen(&l:dictionary) > 0 },
                      \ 'file': { t -> t =~# '\v[/~]\f*$' },
                      \ 'path': { t -> t =~# '\v[/~]\f*$' },
                      \ 'omni': { t -> strlen(&l:omnifunc) > 0 },
                      \ 'tags': { t -> !empty(tagfiles()) },
                      \ 'user': { t -> strlen(&l:completefunc) > 0 },
                      \ 'spel': { t -> &l:spell && !empty(&l:spelllang) },
                      \ 'ulti': { t -> get(g:, 'did_plugin_ultisnips', 0) },
                      \ }

" Purpose:
" insert the first entry in the menu

fu! s:act_on_pumvisible() abort
    let s:pumvisible = 0

    " If autocompletion is enabled don't do anything (respect the value of 'cot'). "{{{
    "
    " Why?
    " Automatically inserting text without the user having asked for a completion
    " (hitting Tab) is a bad idea.
    " It will regularly insert undesired text, and the user will constantly have
    " to undo it.
    "
    " Note that if 'cot' doesn't contain 'noinsert' nor 'noselect', Vim will
    " still automatically insert an entry from the menu.
    " That's why we'll have to make sure that 'cot' contains 'noselect' when
    " autocompletion is enabled.
    "
    " If the method is 'spel', don't do anything either.
    "
    " Why?
    " Fixing a spelling error is a bit different than simply completing text.
    " It's much more error prone.
    " We don't want to force the insertion of the first spelling suggestion.
    " We want `Tab` to respect the value of 'cot'.
    " In particular, the values 'noselect' and 'noinsert'.
    "
    " Otherwise, autocompletion is off, and the current method is not 'spel'.
    " In this case, we want to insert the first or last entry of the menu,
    " regardless of the values contained in 'cot'.
    "
    " Depending on the values in 'cot', there are 3 cases to consider:
    "
    "     1. 'cot' contains 'noselect'
    "
    "        Vim won't do anything (regardless whether 'noinsert' is there).
    "        So, to insert an entry of the menu, we'll have to return:
    "
    "            - `C-p Down` for the methods 'c-p' or 'keyp' (LAST entry)
    "            - `C-n Up`   for all the others              (FIRST entry)
    "
    "        It works but `Down` and `Up` breaks the undo sequence, meaning that
    "        if we want to repeat the completion with the dot command, a part of
    "        the completion will be lost.
    "
    "        We could also do:
    "
    "            C-n                    works but doesn't respect the user's
    "                                   decision of not selecting an entry
    "
    "            C-n C-p                doesn't work at all
    "                                   C-n would temporarily insert an entry,
    "                                   then C-p would immediately remove it
    "
    "        This means we shouldn't put 'noselect' in 'cot', at least for the
    "        moment.
    "
    "     2. 'cot' doesn't contain 'noselect' nor 'noinsert'
    "
    "        Vim will automatically insert and select an entry. So, nothing to do.
    "
    "     3. 'cot' doesn't contain 'noselect' but it DOES contain 'noinsert'
    "
    "        Vim will automatically select an entry, but it won't insert it.
    "        To force the insertion, we'll have to return `C-p C-n`.
    "
    "        It will work no matter the method.
    "        If the method is 'c-p' or 'keyp', `Up` will make us select the
    "        second but last entry, then `C-n` will select and insert the last
    "        entry.
    "        For all the other methods, `Up` will make us leave the menu,
    "        then `C-n` will select and insert the first entry.
    "
    "        Basically, `Up` and `C-n` cancel each other out no matter the method.
    "        But `C-n` asks for an insertion. The result is that we insert the
    "        currently selected entry.
    "
"}}}

    return s:auto || s:methods[s:idx] ==# 'spel'
                \ ? ''
                \ : (stridx(&l:completeopt, 'noselect') == -1
                \     ? (stridx(&l:completeopt, 'noinsert') == - 1 ? '' : "\<c-p>\<c-n>")
                \     : get(s:select_entry, s:methods[s:idx], "\<c-n>\<up>")
                \   )

endfu

" Purpose:
"
" During `s:next_method()`, find a method which can be applied.

fu! s:can_complete() abort
    return get({ exists('b:mc_conditions') ? 'b:' : 'g:' }mc_conditions,
                \ s:methods[s:idx], s:yes_you_can)(s:word)
endfu

" Purpose:
"
" just store 1 in `s:pumvisible`, at the very end of `s:next_method()`,
" when a method has been invoked, and it succeeded to find completions displayed
" in a menu.
"
" `s:pumvisible` is used as a flag to know whether the menu is open.
" This flag allows `mucomplete#verify_completion()` to choose between acting
" on the menu if there's one, or trying another method.

fu! mucomplete#menu_up() abort
    let s:pumvisible = 1
    return ''
endfu

" Precondition: pumvisible() is false.
fu! mucomplete#complete(dir) abort
    let s:word = matchstr(strpart(getline('.'), 0, col('.') - 1), '\S\+$')

    if empty(s:word)
        return (a:dir > 0 ? "\<plug>(MUcompleteTab)" : "\<plug>(MUcompleteCtd)")
    endif

    let [s:dir, s:cycle] = [a:dir, 0]
    let s:methods        = get(b:, 'mc_chain', g:mc_chain)

    let s:N   = len(s:methods)
    let s:idx = s:dir > 0 ? -1 : s:N

    return s:next_method()
endfu

fu! mucomplete#cycle(dir) abort
    let [s:dir, s:cycle] = [a:dir, 1]

    return exists('s:N') ? "\<c-e>" . s:next_method() : ''
endfu

" s:next_method() is called by:
"
"     - mucomplete#verify_completion()    after a first completion
"     - mucomplete#complete()             auto / manual completion
"     - mucomplete#cycle()                after a cycling

" Precondition: pumvisible() is false."{{{
"
"         s:dir   = 1     flag:                            initial direction,                  never changes
"         s:idx   = -1    number (positive or negative):   idx of the method to try,           CHANGES
"         s:cycle = 0     flag:                            did we ask to move in the chain ?,  never changes
"         s:N     = 7     number (positive):               number of methods in the chain,     never changes
"
" The valid values of `s:idx` will vary between 0 and s:N-1.
" It is initialized by `cycle_or_select()`, which gives it the value:
"
"         -1      if we go forward in the chain
"         s:N     "        backward "
"
""}}}

fu! s:next_method() abort
    if s:cycle

        " We will get out of the loop as soon as:"{{{
        "
        "     the next idx is beyond the chain
        " OR
        "     the method of the current idx can be applied

        " Condition to stay in the loop:
        "
        "     (s:idx+1) % (s:N+1) != 0    the next idx is not beyond the chain
        "                                 IOW there IS a NEXT method
        "
        "     && !s:can_complete()        AND the method of the CURRENT one can't be applied
        "
        ""}}}

        let s:idx = (s:idx + s:dir + s:N) % s:N
        while (s:idx+1) % (s:N+1) != 0  && !s:can_complete()
            let s:idx = (s:idx + s:dir + s:N) % s:N
        endwhile

    else

        let s:idx += s:dir
        while (s:idx+1) % (s:N+1) != 0  && !s:can_complete()
            let s:idx += s:dir
        endwhile
    endif
    " After the while loop:"{{{
    "
    "     if (s:idx+1) % (s:N+1) != 0
    "
    " … is equivalent to:
    "
    "     if s:can_complete()
    "
    " Why don't we use that, then?
    " Probably to save some time, the function call would be slower.
    "
    ""}}}

    if (s:idx+1) % (s:N+1) != 0

        " 1 - Type the keys to invoke the chosen method."{{{
        "
        " 2 - Store the state of the menu in `s:pumvisible` through
        "     `mucomplete#menu_up()`.
        "
        " 3 - call `mucomplete#verify_completion()` through `<plug>(MUcompleteNxt)`
        "
        ""}}}

        " FIXME:
        " Why does lifepillar use C-r twice.
        " Usually it's used to insert the contents of a register literally.
        " To prevent the interpretation of special characters like backspace:
        "
        "     register contents         insertion
        "     xy^Hz                →    xz
        "
        " Here we insert the expression register, which will store an empty
        " string. There's nothing to interpret. So why 2 C-r? Why not just one.

        return s:compl_mappings[s:methods[s:idx]] .
                    \ "\<c-r>\<c-r>=pumvisible()?mucomplete#menu_up():''\<cr>\<plug>(MUcompleteNxt)"

    endif

    return ''
endfu

" Purpose:
"
" It's called by `<plug>(MUcompleteNxt)`, which itself is typed at
" the very end of `s:next_method()`.
" It checks whether the last completion succeeded by looking at
" the state of the menu.
" If it's open, the function calls `s:act_on_pumvisible()`.
" If it's not, it recalls `s:next_method()` to try another method.

fu! mucomplete#verify_completion() abort
    return s:pumvisible ? s:act_on_pumvisible() : s:next_method()
endfu

fu! mucomplete#tab_complete(dir) abort
    if pumvisible()
        return mucomplete#cycle_or_select(a:dir)
    else
        let g:mucomplete_with_key = 1
        return mucomplete#complete(a:dir)
    endif
endfu

fu! mucomplete#cycle_or_select(dir) abort
    if get(g:, 'mc_cycle_with_trigger', 0)
        return mucomplete#cycle(a:dir)
    else
        return (a:dir > 0 ? "\<c-n>" : "\<c-p>")
    endif
endfu
