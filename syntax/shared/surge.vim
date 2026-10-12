" Independently written lexical building blocks. All items are contained so
" callers choose which tokens are meaningful in each section or field.
syntax case match
syntax match sgconfDelimiter /[,=]/ contained
syntax match sgconfNumber /\%([[:alnum:]_.-]\)\@<!-\?\d\+\%(\.\d\+\)\?\%([[:alnum:]_.-]\)\@!/ contained
syntax match sgconfAddress /\%([[:alnum:]_.]\)\@<!\%(\d\{1,3}\.\)\{3}\d\{1,3}\%(\/\d\+\)\?\%([[:alnum:]_.]\)\@!/ contained
syntax match sgconfAddress /\%([[:alnum:]_:]\)\@<!\x*:\%(:\|\x\+:\)\+\x*\%(\/\d\+\)\?\%([[:alnum:]_:]\)\@!/ contained
syntax match sgconfBoolean /\%([[:alnum:]_.-]\)\@<!\%(true\|false\|enabled\|disabled\)\%([[:alnum:]_.-]\)\@!/ contained
syntax match sgconfPolicy /\%(\%(^\|[,=]\)\s*\)\@<=\%(DIRECT\|REJECT\%(-DROP\|-TINYGIF\|-NO-DROP\)\?\)\ze\s*\%([,)]\|[#;]\|\/\/\|$\)/ contained
syntax match sgconfPlaceholder /{{{[^}\r\n]\+}}}/ contained
syntax match sgconfEscape /\\./ contained
syntax region sgconfString start=/"/ skip=/\\./ end=/"/ end=/$/ oneline contained contains=sgconfEscape,sgconfPlaceholder
syntax region sgconfString start=/\%(^\|[[:space:],=(]\)\@<='/ skip=/\\./ end=/'/ end=/$/ oneline contained contains=sgconfEscape,sgconfPlaceholder
syntax match sgconfURL /\<\%(https\?\|socks5\|file\):\/\/[^[:space:],"']\+/ contained contains=sgconfPlaceholder
syntax match sgconfParameter /\<[a-zA-Z][a-zA-Z0-9_-]*\ze\s*=/ contained
syntax match sgconfComment /^\s*\%(#\|;\|\/\/\).*$/ contained contains=sgconfTodo
syntax match sgconfComment /\s\@<=\%(#\|;\|\/\/\).*$/ contained contains=sgconfTodo
syntax keyword sgconfTodo TODO FIXME NOTE XXX contained
syntax cluster sgconfAtoms contains=sgconfString,sgconfPlaceholder,sgconfURL,sgconfNumber,sgconfAddress,sgconfBoolean
syntax cluster sgconfValues contains=@sgconfAtoms,sgconfPolicy,sgconfParameter,sgconfDelimiter,sgconfComment

" Comma-separated rules advance by field, rather than coloring policy names
" or rule keywords wherever they appear in arbitrary configuration values.
syntax match sgconfRule /^[[:space:]]*\zs[A-Z][A-Z0-9-]*\ze\s*,/ contained nextgroup=sgconfConditionComma skipwhite
syntax match sgconfConditionComma /,/ contained nextgroup=sgconfCondition skipwhite
syntax region sgconfCondition start=/\ze\S/ end=/\ze,/ end=/$/ oneline contained contains=sgconfString,sgconfPlaceholder,sgconfURL,sgconfAddress,sgconfComment nextgroup=sgconfPolicyComma skipwhite
syntax match sgconfPolicyComma /,/ contained nextgroup=sgconfTarget skipwhite
syntax region sgconfTarget start=/\ze\S/ end=/\ze,/ end=/$/ oneline contained contains=sgconfString,sgconfPlaceholder,sgconfPolicy,sgconfComment nextgroup=sgconfOptionComma skipwhite
syntax match sgconfFinalRule /^\s*\zsFINAL\ze\s*,/ contained nextgroup=sgconfPolicyComma skipwhite
syntax match sgconfLogicalRule /^\s*\zs\%(AND\|OR\|NOT\)\ze\s*,/ contained nextgroup=sgconfExpressionComma skipwhite
syntax match sgconfExpressionComma /,/ contained nextgroup=sgconfExpression skipwhite
syntax region sgconfExpression matchgroup=sgconfDelimiter start=/(/ end=/)/ end=/$/ oneline contained contains=sgconfNestedExpression,sgconfNestedRule,sgconfNestedLogicalRule,sgconfDelimiter nextgroup=sgconfPolicyComma skipwhite

" Nested sub-rules and RULE-SET entries have no target-policy column.
syntax region sgconfNestedExpression matchgroup=sgconfDelimiter start=/(/ end=/)/ end=/$/ oneline contained contains=sgconfNestedExpression,sgconfNestedRule,sgconfNestedLogicalRule,sgconfDelimiter nextgroup=sgconfOptionComma skipwhite
syntax match sgconfNestedRule /\<[A-Z][A-Z0-9-]*\ze\s*,/ contained nextgroup=sgconfNestedConditionComma skipwhite
syntax match sgconfNestedLogicalRule /\<\%(AND\|OR\|NOT\)\ze\s*,/ contained nextgroup=sgconfNestedExpressionComma skipwhite
syntax match sgconfNestedExpressionComma /,/ contained nextgroup=sgconfNestedExpression skipwhite
syntax match sgconfNestedConditionComma /,/ contained nextgroup=sgconfNestedCondition skipwhite
syntax region sgconfNestedCondition start=/\ze\S/ end=/\ze[,)]/ end=/$/ oneline contained contains=sgconfString,sgconfPlaceholder,sgconfAddress,sgconfEscape,sgconfRegexClass,sgconfConditionParens,sgconfComment nextgroup=sgconfOptionComma skipwhite
syntax region sgconfRegexClass start=/\[/ skip=/\\./ end=/]/ end=/$/ oneline contained contains=sgconfEscape
syntax region sgconfConditionParens start=/(/ skip=/\\./ end=/)/ end=/$/ oneline contained contains=sgconfConditionParens,sgconfString,sgconfPlaceholder,sgconfEscape,sgconfRegexClass
syntax match sgconfOptionComma /,/ contained nextgroup=sgconfRuleOption,sgconfRuleParameter skipwhite
syntax match sgconfRuleOption /\%(no-resolve\|extended-matching\|pre-matching\|debug\|dns-failed\|requires-resolve\|force-remote-dns\|no-system\)\ze\%([[:space:],)]\|$\)/ contained nextgroup=sgconfOptionComma skipwhite
syntax match sgconfRuleParameter /[a-zA-Z][a-zA-Z0-9_-]*\ze\s*=/ contained nextgroup=sgconfRuleOptionEquals skipwhite
syntax match sgconfRuleOptionEquals /=/ contained nextgroup=sgconfRuleOptionValue skipwhite
syntax region sgconfRuleOptionValue start=/\ze\S/ end=/\ze[,)]/ end=/$/ oneline contained contains=@sgconfAtoms,sgconfComment nextgroup=sgconfOptionComma skipwhite

" Top-level RULE-SET conditions end at commas, not at regex parentheses.
syntax match sgconfRulesetConditionComma /,/ contained nextgroup=sgconfRulesetCondition skipwhite
syntax region sgconfRulesetCondition start=/\ze\S/ end=/\ze,/ end=/$/ oneline contained contains=sgconfString,sgconfPlaceholder,sgconfURL,sgconfAddress,sgconfComment nextgroup=sgconfOptionComma skipwhite
syntax match surgeRulesetType /^\s*\zs[A-Z][A-Z0-9-]*\ze\s*,/ contained nextgroup=sgconfRulesetConditionComma skipwhite
syntax match surgeRulesetType /^\s*\zs\%(AND\|OR\|NOT\)\ze\s*,/ contained nextgroup=sgconfNestedExpressionComma skipwhite
syntax match surgeRulesetOption /\%(no-resolve\|extended-matching\|pre-matching\|debug\)\ze\%([[:space:],)]\|$\)/ contained nextgroup=sgconfOptionComma skipwhite
syntax cluster sgconfRuleset contains=surgeRulesetType,sgconfComment

highlight default link sgconfDelimiter Delimiter
highlight default link sgconfNumber Number
highlight default link sgconfAddress Number
highlight default link sgconfBoolean Boolean
highlight default link sgconfPolicy Constant
highlight default link sgconfPlaceholder Special
highlight default link sgconfEscape SpecialChar
highlight default link sgconfString String
highlight default link sgconfURL Underlined
highlight default link sgconfParameter Identifier
highlight default link sgconfComment Comment
highlight default link sgconfTodo Todo
highlight default link sgconfRule Keyword
highlight default link sgconfCondition String
highlight default link sgconfTarget Identifier
highlight default link sgconfRuleOption Special
highlight default link sgconfRuleParameter sgconfParameter
highlight default link sgconfRuleOptionValue String
highlight default link sgconfFinalRule sgconfRule
highlight default link sgconfLogicalRule sgconfRule
highlight default link sgconfNestedRule sgconfRule
highlight default link sgconfNestedLogicalRule sgconfRule
highlight default link sgconfNestedCondition sgconfCondition
highlight default link sgconfConditionParens sgconfCondition
highlight default link sgconfRegexClass sgconfCondition
highlight default link sgconfRulesetCondition sgconfCondition
highlight default link sgconfRulesetConditionComma sgconfDelimiter
highlight default link sgconfConditionComma sgconfDelimiter
highlight default link sgconfPolicyComma sgconfDelimiter
highlight default link sgconfExpressionComma sgconfDelimiter
highlight default link sgconfNestedExpressionComma sgconfDelimiter
highlight default link sgconfNestedConditionComma sgconfDelimiter
highlight default link sgconfOptionComma sgconfDelimiter
highlight default link sgconfRuleOptionEquals sgconfDelimiter
highlight default link surgeRulesetType sgconfRule
highlight default link surgeRulesetOption sgconfRuleOption
