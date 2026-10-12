" Standalone RULE-SET entries share the policy-free inline ruleset grammar.
if exists('b:current_syntax')
  finish
endif
runtime! syntax/shared/surge.vim
syntax match surgeRulesetComment /^\s*\%(#\|;\|\/\/\).*$/ contains=surgeRulesetTodo
syntax match surgeRulesetComment /\s\@<=\%(#\|;\|\/\/\).*$/ contains=surgeRulesetTodo
syntax keyword surgeRulesetTodo TODO FIXME NOTE XXX contained
syntax region surgeRulesetLine transparent start=/^\s*\ze[A-Z][A-Z0-9-]*\s*,/ end=/$/ oneline keepend contains=@sgconfRuleset,surgeRulesetComment
syntax match sgconfOptionComma /,/ contained nextgroup=surgeRulesetOption,sgconfRuleParameter skipwhite
highlight default link surgeRulesetComment sgconfComment
highlight default link surgeRulesetTodo sgconfTodo
let b:current_syntax = 'surge_ruleset'
