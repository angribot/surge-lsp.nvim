" Original, lightweight RULE-SET syntax; no profile assignments or policies.
if exists('b:current_syntax')
  finish
endif
syntax case match
syntax match surgeRulesetDelimiter /[,()]/
syntax match surgeRulesetType /^\s*\zs[A-Z][A-Z0-9-]*\ze\s*,/
syntax match surgeRulesetOption /,\s*\zs\%(no-resolve\|extended-matching\|pre-matching\|debug\)\>/
syntax region surgeRulesetString start=/"/ skip=/\\./ end=/"/ oneline
syntax region surgeRulesetString start=/'/ skip=/\\./ end=/'/ oneline
syntax match surgeRulesetComment /^\s*\%(#\|;\|\/\/\).*$/ contains=surgeRulesetTodo
syntax match surgeRulesetComment /\s\zs\%(#\|;\|\/\/\).*$/ contains=surgeRulesetTodo
syntax keyword surgeRulesetTodo TODO FIXME NOTE XXX contained
highlight default link surgeRulesetDelimiter Delimiter
highlight default link surgeRulesetType Keyword
highlight default link surgeRulesetOption Special
highlight default link surgeRulesetString String
highlight default link surgeRulesetComment Comment
highlight default link surgeRulesetTodo Todo
let b:current_syntax = 'surge_ruleset'
