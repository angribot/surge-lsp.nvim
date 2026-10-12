" Section-aware lexical highlighting; validation belongs to surge-cli.
if exists('b:current_syntax')
  finish
endif
runtime! syntax/shared/surge.vim
syntax sync minlines=1

" These also work before a section, for module headers and detached fragments.
syntax match sgconfComment /^\s*\%(#\|;\|\/\/\).*$/ contains=sgconfTodo
syntax match sgconfComment /\s\@<=\%(#\|;\|\/\/\).*$/ contains=sgconfTodo
syntax region sgconfDirectiveLine matchgroup=sgconfDirective start=/^\s*#![a-zA-Z0-9_-]\+/ end=/$/ oneline keepend contains=@sgconfValues
syntax match sgconfKey /^\s*\zs\%(\/\/\)\@![^][#;=,[:space:]][^=,]*\ze\s*=/ contained
syntax region sgconfAssignment transparent start=/^\s*\ze\%(\/\/\)\@![^][#;=,[:space:]][^=,]*=/ end=/$/ oneline keepend contains=@sgconfValues,sgconfKey
syntax region sgconfRuleLine transparent start=/^\s*\ze[A-Z][A-Z0-9-]*\s*,/ end=/$/ oneline keepend contains=sgconfRule,sgconfFinalRule,sgconfLogicalRule,sgconfComment
syntax region sgconfRulesetLine transparent start=/^\s*\ze[A-Z][A-Z0-9-]*\s*,/ end=/$/ oneline keepend contained contains=@sgconfRuleset

" Named definitions distinguish their name and first value from parameters.
syntax region sgconfProxyLine transparent start=/^\s*\ze\%(\/\/\)\@![^][#;=[:space:]][^=]*=/ end=/$/ oneline keepend contained contains=sgconfProxyName,sgconfComment
syntax match sgconfProxyName /^\s*\zs\%(\/\/\)\@![^][#;=[:space:]][^=]*\ze=/ contained nextgroup=sgconfProxyEquals
syntax match sgconfProxyEquals /=/ contained nextgroup=sgconfProxyType skipwhite
syntax match sgconfProxyType /[a-zA-Z][a-zA-Z0-9_-]*/ contained nextgroup=sgconfProxyFields skipwhite
syntax region sgconfProxyFields matchgroup=sgconfDelimiter start=/,/ end=/$/ oneline keepend contained contains=@sgconfValues
syntax region sgconfGroupLine transparent start=/^\s*\ze\%(\/\/\)\@![^][#;=[:space:]][^=]*=/ end=/$/ oneline keepend contained contains=sgconfGroupName,sgconfComment
syntax match sgconfGroupName /^\s*\zs\%(\/\/\)\@![^][#;=[:space:]][^=]*\ze=/ contained nextgroup=sgconfGroupEquals
syntax match sgconfGroupEquals /=/ contained nextgroup=sgconfGroupType skipwhite
syntax match sgconfGroupType /[a-zA-Z][a-zA-Z0-9_-]*/ contained nextgroup=sgconfGroupFields skipwhite
syntax region sgconfGroupFields matchgroup=sgconfDelimiter start=/,/ end=/$/ oneline keepend contained contains=@sgconfValues

syntax region sgconfScriptLine transparent start=/^\s*\ze\%(\/\/\)\@![^][#;=[:space:]][^=]*=/ end=/$/ oneline keepend contained contains=@sgconfValues,sgconfScriptName,sgconfScriptTypeKey,sgconfScriptPatternKey
syntax match sgconfScriptName /^\s*\zs\%(\/\/\)\@![^][#;=[:space:]][^=]*\ze=/ contained
syntax match sgconfScriptTypeKey /\<type\ze\s*=/ contained nextgroup=sgconfScriptTypeEquals skipwhite
syntax match sgconfScriptTypeEquals /=/ contained nextgroup=sgconfScriptType skipwhite
syntax match sgconfScriptType /[a-zA-Z][a-zA-Z0-9_-]*/ contained
syntax match sgconfScriptPatternKey /\<pattern\ze\s*=/ contained nextgroup=sgconfScriptPatternEquals skipwhite
syntax match sgconfScriptPatternEquals /=/ contained nextgroup=sgconfScriptPattern skipwhite
syntax region sgconfScriptPattern start=/\ze\S/ end=/\ze,/ end=/$/ oneline contained contains=sgconfString,sgconfEscape,sgconfPlaceholder,sgconfComment

" Rewrite fields are whitespace-separated, not configuration assignments.
" Treat regexes and jq expressions as opaque text instead of parsing code.
let s:word = '\%([#;]\|\/\/\)\@!\%("\%([^"\\]\|\\.\)*"\|''\%([^''\\]\|\\.\)*''\|\S\+\)'
syntax match sgconfCapture /\$\d\+/ contained
syntax cluster sgconfRewriteValue contains=sgconfString,sgconfEscape,sgconfPlaceholder,sgconfCapture
execute 'syntax match sgconfURLPattern /' . s:word . '/ contained contains=@sgconfRewriteValue nextgroup=sgconfURLReplacement skipwhite'
execute 'syntax match sgconfURLReplacement /' . s:word . '/ contained contains=@sgconfRewriteValue nextgroup=sgconfURLRewriteType skipwhite'
syntax match sgconfURLRewriteType /\%(header\|302\|307\|reject\)\ze\%([[:space:]]\|$\)/ contained
execute 'syntax match sgconfHeaderPattern /' . s:word . '/ contained contains=@sgconfRewriteValue nextgroup=sgconfHeaderAction skipwhite'
syntax match sgconfHeaderDirection /\<http-\%(request\|response\)\>/ contained nextgroup=sgconfHeaderPattern skipwhite
syntax match sgconfHeaderAction /header-\%(add\|del\|replace\%(-regex\)\?\)\ze\%([[:space:]]\|$\)/ contained nextgroup=sgconfHeaderName skipwhite
execute 'syntax match sgconfHeaderName /' . s:word . '/ contained nextgroup=sgconfHeaderValue skipwhite'
syntax region sgconfHeaderValue start=/\ze\S/ end=/$/ oneline keepend contained contains=@sgconfRewriteValue,sgconfComment
syntax match sgconfBodyDirection /\<http-\%(request\|response\)\>/ contained nextgroup=sgconfBodyURL skipwhite
execute 'syntax match sgconfBodyURL /' . s:word . '/ contained contains=@sgconfRewriteValue nextgroup=sgconfBodyPattern skipwhite'
execute 'syntax match sgconfBodyPattern /' . s:word . '/ contained contains=@sgconfRewriteValue nextgroup=sgconfBodyReplacement skipwhite'
execute 'syntax match sgconfBodyReplacement /' . s:word . '/ contained contains=@sgconfRewriteValue nextgroup=sgconfBodyPattern skipwhite'
syntax match sgconfJQDirection /\<http-\%(request\|response\)-jq\>/ contained nextgroup=sgconfJQURL skipwhite
execute 'syntax match sgconfJQURL /' . s:word . '/ contained contains=@sgconfRewriteValue nextgroup=sgconfJQExpression skipwhite'
syntax region sgconfJQExpression start=/\ze\S/ end=/$/ oneline keepend contained contains=sgconfString,sgconfPlaceholder,sgconfComment
unlet s:word

" Line containers keep field chains local, including unfinished quoted values.
syntax region sgconfURLRewriteLine transparent start=/^\s*\ze[^#;[:space:]]/ end=/$/ oneline keepend contained contains=sgconfURLPattern,sgconfComment
syntax region sgconfHeaderRewriteLine transparent start=/^\s*\ze[^#;[:space:]]/ end=/$/ oneline keepend contained contains=sgconfHeaderPattern,sgconfHeaderDirection,sgconfComment
syntax region sgconfBodyRewriteLine transparent start=/^\s*\zehttp-/ end=/$/ oneline keepend contained contains=sgconfBodyDirection,sgconfJQDirection,sgconfComment
syntax region sgconfLegacyScriptLine transparent start=/^\s*\ze\%(http-request\|http-response\|cron\|dns\|event\|rule\|generic\)\s\+[^=[:space:]]/ end=/$/ oneline keepend contained contains=@sgconfValues,sgconfLegacyScriptType
syntax match sgconfLegacyScriptType /^\s*\zs[a-z-]\+/ contained nextgroup=sgconfLegacyScriptValue skipwhite
syntax match sgconfLegacyScriptValue /\%("[^"\r\n]*"\|\S\+\)/ contained contains=sgconfPlaceholder,sgconfEscape

" Generic sections come first: specific regions win at the same position.
" Only complete header lines count: a rewrite regex may begin with [a-z].
" The entirely zero-width end also preserves indentation for the next header.
let s:headerTail = '\s*\%([#;].*\|\/\/.*\)\?$'
let s:anyHeader = '^\s*\[[^]\r\n]\+\]\ze' . s:headerTail
let s:sectionEnd = '^\ze\s*\[[^]\r\n]\+\]' . s:headerTail
execute 'syntax region sgconfConfigSection matchgroup=sgconfSection start=/' . s:anyHeader . '/ end=/' . s:sectionEnd . '/ keepend contains=sgconfAssignment,sgconfComment,sgconfDirectiveLine'
" Only sections span lines. Sync to their state without reparsing every rule
" above the viewport, even in very large profiles.
execute 'syntax sync match sgconfConfigSync groupthere sgconfConfigSection /' . s:anyHeader . '/'
let s:sections = [
      \ ['sgconfProxySection', 'Proxy', 'sgconfProxyLine'],
      \ ['sgconfGroupSection', 'Proxy Group', 'sgconfGroupLine'],
      \ ['sgconfRuleSection', 'Rule', 'sgconfRuleLine'],
      \ ['sgconfRulesetSection', 'Ruleset [^]\r\n]\+', 'sgconfRulesetLine'],
      \ ['sgconfScriptSection', 'Script', 'sgconfScriptLine,sgconfLegacyScriptLine'],
      \ ['sgconfURLRewriteSection', 'URL Rewrite', 'sgconfURLRewriteLine'],
      \ ['sgconfHeaderRewriteSection', 'Header Rewrite', 'sgconfHeaderRewriteLine'],
      \ ['sgconfBodyRewriteSection', 'Body Rewrite', 'sgconfBodyRewriteLine'],
      \ ]
for [s:group, s:section, s:items] in s:sections
  let s:header = '^\s*\[\s*' . s:section . '\s*\]\ze' . s:headerTail
  execute 'syntax region ' . s:group . ' matchgroup=sgconfSection start=/' . s:header . '/ end=/' . s:sectionEnd . '/ keepend contains=' . s:items . ',sgconfComment,sgconfDirectiveLine'
  execute 'syntax sync match sgconfSectionSync groupthere ' . s:group . ' /' . s:header . '/'
endfor
unlet s:sections s:group s:section s:items s:header s:headerTail s:anyHeader s:sectionEnd

highlight default link sgconfSection Title
highlight default link sgconfKey Identifier
highlight default link sgconfDirective PreProc
highlight default link sgconfProxyName Function
highlight default link sgconfGroupName Function
highlight default link sgconfScriptName Function
highlight default link sgconfProxyType Type
highlight default link sgconfGroupType Type
highlight default link sgconfScriptType Type
highlight default link sgconfProxyFields String
highlight default link sgconfGroupFields Identifier
highlight default link sgconfProxyEquals sgconfDelimiter
highlight default link sgconfGroupEquals sgconfDelimiter
highlight default link sgconfScriptTypeEquals sgconfDelimiter
highlight default link sgconfScriptPatternEquals sgconfDelimiter
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
highlight default link sgconfHeaderValue String
highlight default link sgconfBodyDirection Keyword
highlight default link sgconfBodyURL String
highlight default link sgconfBodyPattern String
highlight default link sgconfBodyReplacement String
highlight default link sgconfJQDirection Keyword
highlight default link sgconfJQURL String
highlight default link sgconfJQExpression String
highlight default link sgconfLegacyScriptType sgconfScriptType
highlight default link sgconfLegacyScriptValue String

let b:current_syntax = 'sgconf'
