" Lexical highlighting aligned with the official Surge VSCode 0.1.9 grammar.
syntax case match

" Vim has no per-capture highlighting. A complete match gates a local field
" chain; transparent gaps preserve whitespace and keepend bounds nested tokens.
function! s:Fields(name, parts) abort
  let l:patterns = map(copy(a:parts), 'type(v:val) == v:t_list ? v:val[0] : v:val')
  let l:fields = filter(range(len(a:parts)), 'type(a:parts[v:val]) == v:t_list')
  let l:previous = -1
  for l:n in range(len(l:fields))
    let l:i = l:fields[l:n]
    let l:part = a:parts[l:i]
    let l:gap = l:i == l:previous + 1 ? '' : join(l:patterns[l:previous + 1 : l:i - 1], '')
    let l:tail = join(l:patterns[l:i + 1 :], '')
    let l:tail = empty(l:tail) ? '' : '\%(' . l:tail . '\)\@='
    let l:field = a:name . 'Field' . l:i
    let l:step = a:name . 'Step' . l:i
    execute 'syntax match ' . l:field . ' /' . escape(l:gap . '\zs' . l:part[0] . l:tail, '/')
          \ . '/ contained keepend contains=' . get(l:part, 2, 'NONE')
    execute 'highlight default link ' . l:field . ' ' . l:part[1]
    let l:next = l:n + 1 < len(l:fields) ? ' nextgroup=' . a:name . 'Step' . l:fields[l:n + 1] : ''
    execute 'syntax match ' . l:step . ' /' . escape(l:gap . l:part[0] . l:tail, '/')
          \ . '/ contained transparent keepend contains=' . l:field . l:next
    let l:previous = l:i
  endfor
  execute 'syntax match ' . a:name . ' /' . escape(join(l:patterns, ''), '/')
        \ . '/ contained transparent keepend contains=' . a:name . 'Step' . l:fields[0]
endfunction

" TextMate prefers earlier alternatives; Vim prefers later definitions.
syntax match sgconfBarePlaceholder /{{{[^}[:space:],=]\+}}}/ contained
syntax match sgconfURLPlaceholder /{{{[^}[:space:],"']\+}}}/ contained
syntax match sgconfBareValue /[^[:space:],=]\+/ contained contains=sgconfBarePlaceholder
syntax match sgconfDelimiter /[,=]/ contained
syntax match sgconfNumber /[[:alnum:]_.-]\@1<!\d\+\%(\.\d\+\)\?[[:alnum:]_.-]\@!/ contained
syntax match sgconfAddress /[[:alnum:]_.]\@1<!\%(\d\{1,3}\.\)\{3}\d\{1,3}\%(\/\d\+\)\?[[:alnum:]_.]\@!/ contained
syntax match sgconfBoolean /[[:alnum:]_]\@1<!\%(true\|false\|enabled\|disabled\)[[:alnum:]_]\@!/ contained
syntax match sgconfPolicy /[[:alnum:]_]\@1<!\%(DIRECT\|REJECT\%(-DROP\|-TINYGIF\|-NO-DROP\)\?\)[[:alnum:]_]\@!/ contained
syntax match sgconfURL /[[:alnum:]_]\@1<!\%(https\?\|socks5\|file\):\/\/[^[:space:],"']\+/ contained contains=sgconfURLPlaceholder
call s:Fields('sgconfParameterMatch', [
      \ ['[[:alnum:]_]\@1<![a-zA-Z]\%([[:alnum:]_-]*\)\@>', 'sgconfParameter'], ['\s*=', 'sgconfAssignmentOperator']])

syntax cluster sgconfStrings contains=sgconfStringSingle,sgconfStringDouble,sgconfPlaceholder
syntax cluster sgconfValues contains=sgconfBareValue,sgconfDelimiter,sgconfNumber,sgconfAddress,sgconfBoolean,sgconfPolicy,sgconfURL,sgconfParameterMatch,@sgconfStrings,sgconfComment

call s:Fields('sgconfDirectiveStart', ['^\s*', ['#!', 'sgconfDirectiveMarker'], ['[[:alnum:]_-]\+', 'sgconfDirective']])
let s:name = '[^#;[:space:]][^=]\{-}'
call s:Fields('sgconfAssignment', ['^\s*', [s:name, 'sgconfKey'], ['\s*=', 'sgconfAssignmentOperator']])

" Complete rule fields may contain quoted fragments, commas inside quotes,
" and internal spaces. Missing fields fall back to the shared values grammar.
let s:quoted = '\%("\%(\\.\|[^"\\]\)*"\|''[^'']*''\)'
" Atomic unquoted runs avoid a backtracking frame for every regex character.
let s:atom = '\%(' . s:quoted . '\|\%([^,[:space:]"''#;/]\+\)\@>\|[#;/]\)'
let s:field = s:atom . '\%(' . s:atom . '\|[ \t]\+\%([#;]\|//\|$\)\@!\)\{-}'
let s:tail = '\%(\s*\%([,#;]\|//\|$\)\)\@='
let s:comma = ['\s*,', 'sgconfDelimiter']
syntax match sgconfFieldPlaceholder /{{{[^},\r\n]\+}}}/ contained
syntax match sgconfPolicyConstant /[[:alnum:]_]\@1<!\%(DIRECT\|REJECT\%(-DROP\|-TINYGIF\|-NO-DROP\)\?\)[[:alnum:]_]\@!/ contained
syntax cluster sgconfFieldTokens contains=sgconfStringSingle,sgconfStringDouble,sgconfFieldPlaceholder
syntax cluster sgconfFieldPolicy contains=@sgconfFieldTokens,sgconfPolicyConstant
call s:Fields('sgconfRuleMatch', ['^\s*', ['[A-Z][A-Z0-9-]*', 'sgconfRule'], s:comma, '\s*', [s:field, 'sgconfCondition', '@sgconfFieldTokens'], s:comma, '\s*', [s:field, 'sgconfTarget', '@sgconfFieldPolicy'], s:tail])
call s:Fields('sgconfURLRuleMatch', ['^\s*', ['URL-REGEX', 'sgconfRule'], s:comma, '\s*', [s:field, 'sgconfURLPattern', '@sgconfFieldTokens'], s:comma, '\s*', [s:field, 'sgconfTarget', '@sgconfFieldPolicy'], s:tail])
call s:Fields('sgconfRulesetMatch', ['^\s*', ['[A-Z][A-Z0-9-]*', 'surgeRulesetType'], s:comma, '\s*', [s:field, 'sgconfRulesetCondition', '@sgconfFieldTokens'], s:tail])
call s:Fields('sgconfURLRulesetMatch', ['^\s*', ['URL-REGEX', 'surgeRulesetType'], s:comma, '\s*', [s:field, 'sgconfURLPattern', '@sgconfFieldTokens'], s:tail])

" Logical parentheses recurse lexically; their contents are not regex-aware.
syntax match sgconfNestedPlaceholder /{{{[^}[:space:],()]\+}}}/ contained
syntax match sgconfNestedCondition /[^[:space:],()]\+/ contained contains=sgconfNestedPlaceholder
" Only double quotes recognize escapes, and only quote/backslash escapes.
syntax region sgconfStringSingle start=/[^[:space:],=]\@4<!'/ end=/'/ excludenl end=/$/ oneline contained contains=sgconfPlaceholder
syntax region sgconfStringDouble start=/"/ skip=/\\["\\]\ze./ end=/"/ excludenl end=/$/ oneline contained contains=sgconfEscape,sgconfPlaceholder
syntax match sgconfEscape /\\["\\]/ contained
syntax match sgconfPlaceholder /{{{[^}\r\n]\+}}}/ contained
syntax match sgconfLogicalComma /,/ contained
call s:Fields('sgconfNestedRuleMatch', [['[[:alnum:]_]\@1<![A-Z][A-Z0-9-]*', 'sgconfNestedRule'], [',', 'sgconfDelimiter']])
syntax region sgconfExpression transparent matchgroup=sgconfLogicalOpen start=/(/ matchgroup=sgconfLogicalClose end=/)/ end=/$/ oneline contained contains=sgconfNestedCondition,sgconfLogicalComma,@sgconfStrings,sgconfNestedRuleMatch,sgconfExpression
syntax match sgconfLogicalTarget /,\@1<=\s*[^,()[:space:]][^,()]*/ contained
syntax match sgconfRuleOption /[[:alnum:]_]\@1<!\%(no-resolve\|extended-matching\|pre-matching\|force-remote-dns\|no-system\|via-interface\)[[:alnum:]_]\@!/ contained
call s:Fields('sgconfLogicalStart', ['^\s*', ['\%(AND\|OR\|NOT\)', 'sgconfLogicalRule'], s:comma])
syntax region sgconfLogicalLine transparent start=/^\s*\%(AND\|OR\|NOT\)\s*,/ end=/$/ oneline keepend contained contains=@sgconfValues,sgconfLogicalTarget,sgconfRuleOption,sgconfExpression,sgconfLogicalStart
call s:Fields('sgconfFinalMatch', ['^\s*', ['FINAL', 'sgconfFinalRule'], s:comma, '\s*', [s:field, 'sgconfTarget', '@sgconfFieldPolicy'], s:tail])
syntax cluster sgconfRules contains=@sgconfValues,sgconfRuleOption,sgconfRuleMatch,sgconfURLRuleMatch,sgconfLogicalLine,sgconfFinalMatch,sgconfDirectiveLine
syntax cluster sgconfRuleset contains=@sgconfValues,sgconfRuleOption,sgconfRulesetMatch,sgconfURLRulesetMatch,sgconfLogicalLine,sgconfDirectiveLine

" Named definitions require a protocol/group type; incomplete lines use values.
call s:Fields('sgconfProxyStart', ['^\s*', [s:name, 'sgconfProxyName'], ['\s*=', 'sgconfProxyEquals'], '\s*', ['[[:alnum:]_-]\+', 'sgconfProxyType']])
call s:Fields('sgconfGroupStart', ['^\s*', [s:name, 'sgconfGroupName'], ['\s*=', 'sgconfGroupEquals'], '\s*', ['[[:alnum:]_-]\+', 'sgconfGroupType']])
let s:definition = '^\s*' . s:name . '\s*=\s*[[:alnum:]_-]\+'
execute 'syntax region sgconfProxyLine transparent start=/' . s:definition . '/ end=/$/ oneline keepend contained contains=sgconfProxyStart,@sgconfValues'
call s:Fields('sgconfGroupMember', [',\@1<=\%(\s*$\)\@!\s*', ['[^,=]\{-1,}', 'sgconfGroupFields', '@sgconfFieldPolicy'], '\%(\s*\%(,\|$\)\)\@='])
syntax region sgconfGroupValue transparent start=/=\@1<=\s*/ end=/\ze,/ excludenl end=/$/ oneline contained contains=@sgconfValues
execute 'syntax region sgconfGroupLine transparent start=/' . s:definition . '/ end=/$/ oneline keepend contained contains=@sgconfValues,sgconfGroupMember,sgconfGroupValue,sgconfGroupStart'

call s:Fields('sgconfScriptTypeMatch', [['[[:alnum:]_]\@1<!type', 'sgconfScriptTypeKey'], ['\s*=\s*', 'sgconfScriptTypeEquals'], ['\%(http-request\|http-response\|cron\|event\|rule\|dns\|generic\)[[:alnum:]_]\@!', 'sgconfScriptType']])
call s:Fields('sgconfScriptPatternStart', [['[[:alnum:]_]\@1<!pattern', 'sgconfScriptPatternKey'], ['\s*=\s*', 'sgconfScriptPatternEquals']])
syntax region sgconfScriptPattern start=/[[:alnum:]_]\@1<!pattern\s*=\s*/ end=/\ze,/ excludenl end=/$/ oneline contained contains=@sgconfStrings,sgconfScriptPatternStart
" An anchored name wins over parameters, even for scripts named type/pattern.
call s:Fields('sgconfScriptAssignment', ['^\s*', [s:name, 'sgconfScriptName'], ['\s*=', 'sgconfAssignmentOperator']])

" Rewrite captures are opaque regex/replacement fields, not embedded code.
let s:word = '\%(' . s:quoted . '\|\S\+\)'
let s:rewriteTail = '\%(\s*\%([#;]\|//\|$\)\)\@='
syntax match sgconfWordPlaceholder /{{{[^}[:space:]]\+}}}/ contained
syntax match sgconfCapture /\$\d\+/ contained
call s:Fields('sgconfURLRewritePlain', ['^\s*', ['\S\+', 'sgconfURLPattern', 'sgconfWordPlaceholder'], '\s\+', ['\S\+', 'sgconfURLReplacement', 'sgconfCapture,sgconfWordPlaceholder'], s:rewriteTail])
call s:Fields('sgconfURLRewriteTyped', ['^\s*', ['\S\+', 'sgconfURLPattern', 'sgconfWordPlaceholder'], '\s\+', ['\S\+', 'sgconfURLReplacement', 'sgconfCapture,sgconfWordPlaceholder'], '\s\+', ['\%(302\|307\|header\|reject\)', 'sgconfURLRewriteType'], s:rewriteTail])
for s:direction in ['', 'http-\%(request\|response\)']
  let s:parts = ['^\s*']
  if !empty(s:direction)
    call extend(s:parts, [[s:direction, 'sgconfHeaderDirection'], '\s\+'])
  endif
  call extend(s:parts, [[s:word, 'sgconfHeaderPattern'], '\s\+', ['header-\%(replace-regex\|replace\|add\|del\)', 'sgconfHeaderAction'], '\s\+', ['\S\+', 'sgconfHeaderName']])
  call s:Fields('sgconfHeaderRewrite' . (empty(s:direction) ? 'Plain' : 'Directed'), s:parts)
endfor
call s:Fields('sgconfBodyPair', [[s:word, 'sgconfBodyPattern'], '\s\+', [s:word, 'sgconfBodyReplacement', 'sgconfCapture,sgconfPlaceholder']])
call s:Fields('sgconfBodyStart', ['^\s*', ['http-\%(request\|response\)', 'sgconfBodyDirection'], '\s\+', [s:word, 'sgconfBodyURL']])
call s:Fields('sgconfJQStart', ['^\s*', ['http-\%(request\|response\)-jq', 'sgconfJQDirection'], '\s\+', [s:word, 'sgconfJQURL']])
execute 'syntax region sgconfBodyRewriteLine transparent start=/^\s*http-\%(request\|response\)\s\+' . s:word . '/ end=/$/ oneline keepend contained contains=sgconfBodyStart,sgconfBodyPair,sgconfComment'
execute 'syntax region sgconfJQLine transparent start=/^\s*http-\%(request\|response\)-jq\s\+' . s:word . '/ end=/$/ oneline keepend contained contains=sgconfJQStart,@sgconfValues'

" Comments/directives take priority over section-specific line matches.
syntax region sgconfDirectiveLine transparent start=/^\s*#![[:alnum:]_-]\+/ end=/$/ oneline keepend contained contains=sgconfDirectiveStart,@sgconfValues
syntax match sgconfComment /\s\@1<=\%(#!\@!\|;\|\/\/\).*$/ contained
syntax match sgconfComment /^\s*\%(#!\@!\|;\|\/\/\).*$/ contained
unlet s:name s:quoted s:atom s:field s:tail s:comma s:definition s:word s:rewriteTail s:direction s:parts
delfunction s:Fields

" Public groups remain theme-overridable; field wrappers link to these roles.
highlight default link sgconfDelimiter Delimiter
highlight default link sgconfAssignmentOperator Operator
highlight default link sgconfNumber Number
highlight default link sgconfAddress Number
highlight default link sgconfBoolean Boolean
highlight default link sgconfPolicy Constant
highlight default link sgconfPlaceholder Special
highlight default link sgconfEscape SpecialChar
highlight default link sgconfString String
highlight default link sgconfBareValue String
highlight default link sgconfStringSingle sgconfString
highlight default link sgconfStringDouble sgconfString
highlight default link sgconfBarePlaceholder sgconfPlaceholder
highlight default link sgconfURLPlaceholder sgconfPlaceholder
highlight default link sgconfFieldPlaceholder sgconfPlaceholder
highlight default link sgconfNestedPlaceholder sgconfPlaceholder
highlight default link sgconfWordPlaceholder sgconfPlaceholder
highlight default link sgconfPolicyConstant sgconfPolicy
highlight default link sgconfURL Underlined
highlight default link sgconfParameter Identifier
highlight default link sgconfComment Comment
highlight default link sgconfSection Title
highlight default link sgconfKey Identifier
highlight default link sgconfDirective PreProc
highlight default link sgconfDirectiveMarker PreProc
highlight default link sgconfRule Keyword
highlight default link sgconfCondition String
highlight default link sgconfTarget Identifier
highlight default link sgconfRuleOption Special
highlight default link sgconfFinalRule sgconfRule
highlight default link sgconfLogicalRule sgconfRule
highlight default link sgconfNestedRule sgconfRule
highlight default link sgconfNestedCondition sgconfCondition
highlight default link sgconfRulesetCondition sgconfCondition
highlight default link sgconfLogicalOpen sgconfDelimiter
highlight default link sgconfLogicalClose sgconfDelimiter
highlight default link sgconfLogicalComma sgconfDelimiter
highlight default link sgconfLogicalTarget sgconfTarget
highlight default link surgeRulesetType sgconfRule
highlight default link sgconfProxyName Function
highlight default link sgconfGroupName Function
highlight default link sgconfScriptName Function
highlight default link sgconfProxyType Type
highlight default link sgconfGroupType Type
highlight default link sgconfScriptType Type
highlight default link sgconfGroupFields sgconfTarget
highlight default link sgconfProxyEquals sgconfAssignmentOperator
highlight default link sgconfGroupEquals sgconfAssignmentOperator
highlight default link sgconfScriptTypeEquals sgconfAssignmentOperator
highlight default link sgconfScriptPatternEquals sgconfAssignmentOperator
highlight default link sgconfScriptTypeKey sgconfParameter
highlight default link sgconfScriptPatternKey sgconfParameter
highlight default link sgconfScriptPattern String
highlight default link sgconfCapture Special
highlight default link sgconfURLPattern String
highlight default link sgconfURLReplacement String
highlight default link sgconfURLRewriteType Keyword
highlight default link sgconfHeaderPattern String
highlight default link sgconfHeaderDirection Keyword
highlight default link sgconfHeaderAction Keyword
highlight default link sgconfHeaderName Identifier
highlight default link sgconfBodyDirection Keyword
highlight default link sgconfBodyURL String
highlight default link sgconfBodyPattern String
highlight default link sgconfBodyReplacement String
highlight default link sgconfJQDirection Keyword
highlight default link sgconfJQURL String
