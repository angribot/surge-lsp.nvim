" Lightweight lexical highlighting; validation belongs to surge-cli.
if exists('b:current_syntax')
  finish
endif

syntax case match
syntax match sgconfDelimiter /[,=()]/
syntax match sgconfNumber /\<\d\+\%(\.\d\+\)*\>/
syntax keyword sgconfBoolean true false
syntax keyword sgconfPolicy DIRECT REJECT REJECT-DROP REJECT-TINYGIF REJECT-NO-DROP
syntax match sgconfKey /^\s*\zs[^][#;=,[:space:]][^=,]*\ze\s*=/ contains=NONE
syntax match sgconfParameter /[, ]\s*\zs[a-zA-Z][a-zA-Z0-9_-]*\ze\s*=/
syntax match sgconfSection /^\s*\[[^]\r\n]\+\]\s*$/
syntax match sgconfRule /^\s*\zs\%(DOMAIN\%(-SUFFIX\|-KEYWORD\|-SET\)\?\|IP-CIDR6\?\|IP-ASN\|GEOIP\|RULE-SET\|PROCESS-NAME\|PROCESS-PATH\|URL-REGEX\|USER-AGENT\|DEST-PORT\|SRC-PORT\|SRC-IP\|IN-PORT\|PROTOCOL\|SCRIPT\|AND\|OR\|NOT\|FINAL\)\ze\s*,/
syntax region sgconfString start=/"/ skip=/\\./ end=/"/ oneline
syntax match sgconfComment /^\s*\%(#\|;\|\/\/\).*$/ contains=sgconfTodo
syntax match sgconfComment /\s\zs\%(#\|;\|\/\/\).*$/ contains=sgconfTodo
syntax keyword sgconfTodo TODO FIXME NOTE XXX contained
syntax match sgconfDirective /^\s*\zs#![a-zA-Z0-9_-]\+/

highlight default link sgconfSection Title
highlight default link sgconfKey Identifier
highlight default link sgconfParameter Identifier
highlight default link sgconfRule Keyword
highlight default link sgconfPolicy Constant
highlight default link sgconfBoolean Boolean
highlight default link sgconfNumber Number
highlight default link sgconfDelimiter Delimiter
highlight default link sgconfString String
highlight default link sgconfComment Comment
highlight default link sgconfTodo Todo
highlight default link sgconfDirective PreProc

let b:current_syntax = 'sgconf'
