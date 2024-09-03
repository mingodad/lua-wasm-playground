; From tree-sitter-cmake/src/grammar.json
; EBNF to generate grammar.js at
;      https://mingodad.github.io/lua-wasm-playground/
;      based on https://github.com/eatkins/tree-sitter-ebnf-generator
;      see also https://mingodad.github.io/plgh/json2ebnf.html

;*** maybe you'll need to search and replace this (:[a-zA-Z_]+)([?*+]) => $2$1


externals ::= {
	bracket_argument
	bracket_comment
	line_comment
	}

rules:

  source_file ::= _untrimmed_command_invocation*

  escape_sequence ::= _escape_identity
	| _escape_encoded
	| _escape_semicolon

  _escape_identity ::= /\\[^A-Za-z0-9;]/

  _escape_encoded ::= '\t'
	| '\r'
	| '\n'

  _escape_semicolon ::= ';'
	| '\;'

  variable ::=  <0(  ( /[a-zA-Z0-9/_.+-]/ | escape_sequence | variable_ref )+ )

  variable_ref ::= normal_var
	| env_var
	| cache_var

  normal_var ::= '$' '{' variable '}'

  env_var ::= '$' 'ENV' '{' variable '}'

  cache_var ::= '$' 'CACHE' '{' variable '}'

  argument ::= bracket_argument
	| quoted_argument
	| unquoted_argument

  _untrimmed_argument ::= /\s/
	| bracket_comment
	| line_comment
	| argument
	| _paren_argument

  _paren_argument ::= '(' _untrimmed_argument* ')'

  quoted_argument ::= '"'  quoted_element? '"'

  quoted_element ::= ( variable_ref | _quoted_text | escape_sequence )+

  _quoted_text ::=  <0(  ( '$' | /[^\\"]/ )+ )

  unquoted_argument ::=  >0(  ( variable_ref | _unquoted_text | escape_sequence )+ )

  _unquoted_text ::=  <0(  ( '$' | /[^()#"\\]/ )+ )

  body ::=  >0(  _untrimmed_command_invocation+ )

  argument_list ::= _untrimmed_argument+

  if_command ::= if /[\t ]/* '(' argument_list ')'

  elseif_command ::= elseif /[\t ]/* '(' argument_list ')'

  else_command ::= else /[\t ]/* '(' argument_list? ')'

  endif_command ::= endif /[\t ]/* '(' argument_list? ')'

  if_condition ::= if_command ( body | elseif_command | else_command )* endif_command

  foreach_command ::= foreach /[\t ]/* '(' argument_list ')'

  endforeach_command ::= endforeach /[\t ]/* '(' argument? ')'

  foreach_loop ::= foreach_command body endforeach_command

  while_command ::= while /[\t ]/* '(' argument_list ')'

  endwhile_command ::= endwhile /[\t ]/* '(' ( /\s*/ argument /\s*/ )? ')'

  while_loop ::= while_command body endwhile_command

  function_command ::= function /[\t ]/* '(' argument_list ')'

  endfunction_command ::= endfunction /[\t ]/* '(' argument_list? ')'

  function_def ::= function_command body endfunction_command

  macro_command ::= macro /[\t ]/* '(' argument_list ')'

  endmacro_command ::= endmacro /[\t ]/* '(' argument_list? ')'

  macro_def ::= macro_command body endmacro_command

  block_command ::= block /[\t ]/* '(' argument_list ')'

  endblock_command ::= endblock /[\t ]/* '(' argument_list? ')'

  block_def ::= block_command body endblock_command

  normal_command ::= identifier /[\t ]/* '(' argument_list? ')'

  _command_invocation ::= normal_command
	| if_condition
	| foreach_loop
	| while_loop
	| function_def
	| macro_def
	| block_def

  _untrimmed_command_invocation ::= /\s/
	| bracket_comment
	| line_comment
	| _command_invocation

  if ::= /[iI][fF]/

  elseif ::= /[eE][lL][sS][eE][iI][fF]/

  else ::= /[eE][lL][sS][eE]/

  endif ::= /[eE][nN][dD][iI][fF]/

  foreach ::= /[fF][oO][rR][eE][aA][cC][hH]/

  endforeach ::= /[eE][nN][dD][fF][oO][rR][eE][aA][cC][hH]/

  while ::= /[wW][hH][iI][lL][eE]/

  endwhile ::= /[eE][nN][dD][wW][hH][iI][lL][eE]/

  function ::= /[fF][uU][nN][cC][tT][iI][oO][nN]/

  endfunction ::= /[eE][nN][dD][fF][uU][nN][cC][tT][iI][oO][nN]/

  macro ::= /[mM][aA][cC][rR][oO]/

  endmacro ::= /[eE][nN][dD][mM][aA][cC][rR][oO]/

  block ::= /[bB][lL][oO][cC][kK]/

  endblock ::= /[eE][nN][dD][bB][lL][oO][cC][kK]/

  identifier ::= /[A-Za-z_][A-Za-z0-9_]*/

  integer ::= /[+-]*\d+/

