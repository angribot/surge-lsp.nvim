" Section-aware lexical highlighting; validation belongs to surge-cli.
if exists('b:current_syntax')
  finish
endif
runtime! syntax/shared/surge.vim

" Detached fragments receive assignments and values, not profile rule fields.
syntax match sgconfRoot /^.*$/ transparent keepend contains=@sgconfValues,sgconfAssignment,sgconfDirectiveLine

" Upstream ends a section at any bracket-led line, even an unfinished header
" or rewrite regex. Names are exact; trailing text need not be a comment.
let s:sectionEnd = '^\ze\s*\['
let s:sections = [
      \ ['sgconfConfigSection', '[^]\r\n]\+', 'sgconfAssignment'],
      \ ['sgconfBodyRewriteSection', 'Body Rewrite', 'sgconfBodyRewriteLine,sgconfJQLine'],
      \ ['sgconfScriptSection', 'Script', 'sgconfScriptAssignment,sgconfScriptTypeMatch,sgconfScriptPattern'],
      \ ['sgconfHeaderRewriteSection', 'Header Rewrite', 'sgconfHeaderRewritePlain,sgconfHeaderRewriteDirected'],
      \ ['sgconfURLRewriteSection', 'URL Rewrite', 'sgconfURLRewritePlain,sgconfURLRewriteTyped'],
      \ ['sgconfRulesetSection', 'Ruleset [^]]\+', '@sgconfRuleset'],
      \ ['sgconfRuleSection', 'Rule', '@sgconfRules'],
      \ ['sgconfGroupSection', 'Proxy Group', 'sgconfGroupLine'],
      \ ['sgconfProxySection', 'Proxy', 'sgconfProxyLine'],
      \ ]
" Only sections span lines. A malformed header resets to the root grammar.
syntax sync minlines=1
syntax sync match sgconfSectionReset groupthere NONE /^\s*\[/
for [s:group, s:section, s:items] in s:sections
  let s:header = '^\s*\[' . s:section . '\]'
  execute 'syntax region ' . s:group . ' transparent matchgroup=sgconfSection start=/' . s:header . '/ end=/' . s:sectionEnd . '/ keepend contains=@sgconfValues,sgconfDirectiveLine,' . s:items
  execute 'syntax sync match sgconfSectionSync groupthere ' . s:group . ' /' . s:header . '/'
endfor
unlet s:sectionEnd s:sections s:group s:section s:items s:header
let b:current_syntax = 'sgconf'
