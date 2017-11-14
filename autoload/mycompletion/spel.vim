if exists('g:autoloaded_mycompletion_spel')
    finish
endif
let g:autoloaded_mycompletion_spel = 1

fu! mycompletion#spel#complete() abort

    let word_to_complete = matchstr(getline('.'), '\k\+\%'.col('.').'c')
    let badword          = spellbadword(word_to_complete)
    let suggestions      = !empty(badword[1])
    \?                         spellsuggest(badword[0])
    \:                         []

    let from_where = col('.') - len(word_to_complete)

    if !empty(suggestions)
        call complete(from_where, suggestions)
    endif
    return ''
endfu