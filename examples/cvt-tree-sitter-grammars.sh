#!/bin/sh
tmp_folder="/tmp/tslua"
grmh="$HOME/dev/c/A_grammars"
cvt_cmd="qjs $grmh/plgh/json2ebnf-lua.js"
gen_cmd="qjs $grmh/plgh/tree-sitter-generate.js"
base_folder="$grmh/tree-sitter"
fname_list="tree-sitter-ada/src/grammar.json \
	tree-sitter-angular/src/grammar.json \
	tree-sitter-awk/src/grammar.json \
	tree-sitter-bash/src/grammar.json \
	tree-sitter-bison/src/grammar.json \
	tree-sitter-c/src/grammar.json \
	tree-sitter-cmake/src/grammar.json \
	tree-sitter-commonlisp/src/grammar.json \
	tree-sitter-cpp/src/grammar.json \
	tree-sitter-c-sharp/src/grammar.json \
	tree-sitter-c/src/grammar.json \
	tree-sitter-css/src/grammar.json \
	tree-sitter-dart/src/grammar.json \
	tree-sitter-dockerfile/src/grammar.json \
	tree-sitter-d/src/grammar.json \
	tree-sitter-elixir/src/grammar.json \
	tree-sitter-elm/src/grammar.json \
	tree-sitter-erlang/src/grammar.json \
	tree-sitter-fortran/src/grammar.json \
	tree-sitter-fsharp/fsharp/src/grammar.json \
	tree-sitter-gleam/src/grammar.json \
	tree-sitter-go/src/grammar.json \
	tree-sitter-haskell/src/grammar.json \
	tree-sitter-haxe/src/grammar.json \
	tree-sitter-html/src/grammar.json \
	tree-sitter-javascript/src/grammar.json \
	tree-sitter-java/src/grammar.json \
	tree-sitter-julia/src/grammar.json \
	tree-sitter-kotlin/src/grammar.json \
	tree-sitter-ld/src/grammar.json \
	tree-sitter-lua/src/grammar.json \
	tree-sitter-make/src/grammar.json \
	tree-sitter-markdown/src/grammar.json \
	tree-sitter-minizinc/src/grammar.json \
	tree-sitter-nim2/src/grammar.json \
	tree-sitter-ocaml/grammars/ocaml/src/grammar.json \
	tree-sitter-php/php/src/grammar.json \
	tree-sitter-python/src/grammar.json \
	tree-sitter-regex/src/grammar.json \
	tree-sitter-ruby/src/grammar.json \
	tree-sitter-rust/src/grammar.json \
	tree-sitter-scala/src/grammar.json \
	tree-sitter-sql/src/grammar.json \
	tree-sitter-squirrel/src/grammar.json \
	tree-sitter-swift/src/grammar.json \
	tree-sitter-teal/src/grammar.json \
	tree-sitter-tlaplus/src/grammar.json \
	tree-sitter-typescript/typescript/src/grammar.json \
	tree-sitter-vim/src/grammar.json \
	tree-sitter-vimdoc/src/grammar.json \
	tree-sitter-zig/src/grammar.json"

	#"v-analyzer/tree_sitter_v/src/grammar.json"

if [ ! -d $tmp_folder ]; then
	mkdir $tmp_folder
fi

mycw=$PWD

for fn in $fname_list
do
	echo $fn
	fn_basename=`echo $fn | sed -E -e 's/tree-sitter-([^/]+)\/.+/\1/'`
	echo $fn_basename

	repo_base=`echo $fn | sed -E -e 's/(tree-sitter-[^/]+)\/.+/\1/'`
	repo_base="$base_folder/$repo_base"
	echo $repo_base
	cd $repo_base
	repo_url=`git config --get remote.origin.url`
	echo $repo_url
	repo_last_commit=`git rev-parse HEAD`
	echo $repo_last_commit
	cd $mycw

	tmp_fn_json0="$tmp_folder/${fn_basename}0.json"
	echo "==jsonToJson0 $tmp_fn_json0"
	cp $base_folder/$fn  $tmp_fn_json0

	tmp_ebnf_fn="$tmp_folder/$fn_basename.ebnf"
	echo "==jsonToEbnf $tmp_ebnf_fn"
	echo "; repository: $repo_url" > $tmp_ebnf_fn
	echo "; commit: $repo_last_commit" >> $tmp_ebnf_fn
	echo "; json from: $fn" >> $tmp_ebnf_fn
	$cvt_cmd $tmp_fn_json0 >> $tmp_ebnf_fn

	tmp_fname_js=$tmp_folder/$fn_basename.js
	echo "==ebnfToJs $tmp_fname_js"
	lua tree-sitter-ebnf-generator-cmd.lua $tmp_ebnf_fn > $tmp_fname_js

	tmp_fname_json=$tmp_folder/$fn_basename.json
	echo "==jsToJson $tmp_fname_js"
	$gen_cmd $tmp_fname_js > $tmp_fname_json
done
