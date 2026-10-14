" Standalone RULE-SET entries share the policy-free inline ruleset grammar.
if exists('b:current_syntax')
  finish
endif
runtime! syntax/shared/surge.vim
syntax match surgeRulesetComment /^\s*\%(#!\@!\|;\|\/\/\).*$/ contained
syntax match surgeRulesetComment /\s\@1<=\%(#!\@!\|;\|\/\/\).*$/ contained
syntax match surgeRulesetRoot /^.*$/ transparent keepend contains=@sgconfRuleset,surgeRulesetComment
highlight default link surgeRulesetComment sgconfComment
let b:current_syntax = 'surge_ruleset'
