// Setup editors
function setupInfoArea(id) {
  const e = ace.edit(id);
  e.setShowPrintMargin(false);
  e.setOptions({
    readOnly: true,
    highlightActiveLine: false,
    highlightGutterLine: false
  })
  e.renderer.$cursorLayer.element.style.opacity=0;
  return e;
}

function setupEditorArea(id, lsKey) {
  const e = ace.edit(id);
  e.setShowPrintMargin(false);
  e.setValue(localStorage.getItem(lsKey) || '');
  e.moveCursorTo(0, 0);
  return e;
}

let userContentHasChanged = false;
let grammarContentHasChanged = false;
let inputContentHasChanged = false;
function grammarOnChange(delta) {
	if(!grammarContentHasChanged) {
		grammarContentHasChanged = true;
		userContentHasChanged = true;
	}
}
function inputOnChange(delta) {
	if(!inputContentHasChanged) {
		inputContentHasChanged = true;
		userContentHasChanged = true;
	}
}

const grammarEditor = setupEditorArea("grammar-editor", "grammarText");
grammarEditor.on("change", grammarOnChange);
grammarEditor.getSession().setMode("ace/mode/lua");
const codeEditor = setupEditorArea("code-editor", "codeText");
codeEditor.on("change", inputOnChange);
userContentHasChanged = localStorage.getItem("userContentHasChanged");

const codeOutput = setupInfoArea("run-output");

onbeforeunload= function(event) { updateLocalStorage(); };

const sampleList = [
	//title, lua_code, input, input ace syntax
	["Simple", "simple.lua", "fact.lua", "ace/mode/lua"],
	["Lua parser", "lua-ast-playground.lua", "fact.lua", "ace/mode/lua"],
	["C11 parser", "c11-ast-playground.lua", "fact.c", "ace/mode/c_cpp"],
	["Json parser**", "json-ast-playground.lua", "sample.json.txt", "ace/mode/json"],
	["Tree-sitter-ebnf-generator", "tree-sitter-ebnf-generator.lua", "scala.ebnf", "ace/mode/text"],
];

function loadLua_sample(self) {
  if(userContentHasChanged)
  {
	let ok = confirm("Your changes will be lost !\nIf the changes you've made are important save then before proceed.\nCopy and paste to your prefered editor and save it.\nEither OK or Cancel.");
	if(!ok) return false;
  }
  let base_url = "./examples/"
  if(self.selectedIndex > 0) {
      let sample_to_use = sampleList[self.selectedIndex-1];
      $.get(base_url + sample_to_use[1], function( data ) {
        grammarEditor.setValue( data );
	grammarContentHasChanged = false;
	userContentHasChanged = false;
      });
      $.get(base_url + sample_to_use[2], function( data ) {
        codeEditor.setValue( data );
	codeEditor.getSession().setMode(sample_to_use[3]);
	inputContentHasChanged = false;
	userContentHasChanged = false;
      });
  }
}

// Parse
function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}

function nl2br(str) {
  return str.replace(/\n/g, '<br>\n')
}

function textToErrors(str) {
  let errors = [];
  var regExp = /([^\n]+?)\n/g, match;
  while (match = regExp.exec(str)) {
    let msg = match[1];
    let line_col = msg.match(/:\s*input_text:(\d+):(\d+):/);
    if (line_col) {
      errors.push({"ln": line_col[1], "col":line_col[2], "editor": "input_text", "msg": msg});
    } else {
      line_col = msg.match(/^\s*source.lua:(\d+):/);
      if (line_col) {
        errors.push({"ln": line_col[1], "col":0, "msg": msg});
      } else {
        errors.push({"msg": msg});
      }
    }
  }
  return errors;
}

function generateErrorListHTML(errors) {
  let html = '<ul>';

  html += $.map(errors, function (x) {
    if (x.ln > 0) {
      return '<li data-ln="' + x.ln + '" data-col="' + x.col +
	'" data-editor="' + x.editor +
        '"><span>' + escapeHtml(x.msg) + '</span></li>';
    } else {
      return '<li><span>' + escapeHtml(x.msg) + '</span></li>';
    }
  }).join('');

  html += '<ul>';
  //console.log(html);
  return html;
}

function updateLocalStorage() {
  if(grammarContentHasChanged || inputContentHasChanged)
  {
    localStorage.setItem('grammarText', grammarEditor.getValue());
    localStorage.setItem('codeText', codeEditor.getValue());
    grammarContentHasChanged = false;
    inputContentHasChanged = false;
    localStorage.setItem('userContentHasChanged', userContentHasChanged);
  }
}

function parse() {
  const $grammarValidation = $('#grammar-validation');
  const $grammarInfo = $('#grammar-info');
  const grammarText = grammarEditor.getValue();

  const $codeValidation = $('#code-validation');
  const $codeInfo = $('#code-info');
  const codeText = codeEditor.getValue();

  const show_output = $('#show-output').prop('checked');

  $grammarInfo.html('');
  $grammarValidation.hide();
  $codeInfo.html('');
  $codeValidation.hide();
  codeOutput.setValue('');

  outputs.compile_status = '';
  outputs.run_status = '';
  outputs.ast = '';
  outputs.profile = '';

  if (grammarText.length === 0) {
    return;
  }

  $('#overlay').css({
    'z-index': '1',
    'display': 'block',
    'background-color': 'rgba(0, 0, 0, 0.1)'
  });

  window.setTimeout(() => {
    lua_run(grammarText , codeText);

    $('#overlay').css({
      'z-index': '-1',
      'display': 'none',
      'background-color': 'rgba(1, 1, 1, 1.0)'
    });

    if (result.compile == 0) {
      $grammarValidation.removeClass('validation-invalid').show();

      if(result.run == 0) codeOutput.insert(outputs.run_status);

      if (result.run == 0) {
        $codeValidation.removeClass('validation-invalid').show();
      } else {
        $codeValidation.addClass('validation-invalid').show();
      }

      if (result.run != 0 && outputs.run_status.length > 0) {
        const errors = textToErrors(outputs.run_status);
        const html = generateErrorListHTML(errors);
        $codeInfo.html(html);
      }
    } else {
      $grammarValidation.addClass('validation-invalid').show();
    }

    if (outputs.compile_status.length > 0) {
      const errors = textToErrors(outputs.compile_status);
      const html = generateErrorListHTML(errors);
      $grammarInfo.html(html);
    }
    updateLocalStorage();
  }, 0);
}

// Event handing in the info area
function makeOnClickInInfo(editor) {
  return function () {
    const el = $(this);
    //console.log(el.data('editor'));
    let line = el.data('ln') - 1;
    let col = el.data('col') - 1;
    let active_editor = editor;
    if(el.data('editor') == "input_text") active_editor = codeEditor;
    active_editor.navigateTo(line, col);
    active_editor.scrollToLine(line, true, false, null);
    active_editor.focus();
  }
};
$('#grammar-info').on('click', 'li[data-ln]', makeOnClickInInfo(grammarEditor));
$('#code-info').on('click', 'li[data-ln]', makeOnClickInInfo(grammarEditor));

$('#parse').on('click', parse);

// Resize editors to fit their parents
function resizeEditorsToParent() {
  codeEditor.resize();
  codeEditor.renderer.updateFull();
  codeOutput.resize();
  codeOutput.renderer.updateFull();
}

// Show windows
function setupToolWindow(lsKeyName, buttonSel, codeSel, showDefault) {
  let storedValue = localStorage.getItem(lsKeyName);
  if (!storedValue) {
    localStorage.setItem(lsKeyName, showDefault);
    storedValue = localStorage.getItem(lsKeyName);
  }
  let show = storedValue === 'true';
  $(buttonSel).prop('checked', show);
  $(codeSel).css({ 'display': show ? 'block' : 'none' });

  $(buttonSel).on('change', () => {
    show = !show;
    localStorage.setItem(lsKeyName, show);
    $(codeSel).css({ 'display': show ? 'block' : 'none' });
    resizeEditorsToParent();
  });
}

setupToolWindow('show-output', '#show-output', '#code-output', false);

// Show page
$('#main').css({
  'display': 'flex',
});

// used to collect output from C
var outputs = {
  'default': '',
  'compile_status': '',
  'run_status': '',
  'ast': '',
};

// current output (key in `outputs`)
var output = "default";

// results of the various stages
var result = {
  'compile': 0,
  'run': 0,
  'ast': 0,
  'profile': 0,
};

// chpeg_parse function: initialized when emscripten runtime loads
var lua_run = null;

// Emscripten
var Module = {

  // intercept stdout (print) and stderr (printErr)
  // note: text received is line based and missing final '\n'

  'print': function(text) {
    outputs[output] += text + "\n";
  },
  'printErr': function(text) {
    outputs[output] += text + "\n";
  },

  // called when emscripten runtime is initialized
  'onRuntimeInitialized': function() {
    // wrap the C `parse` function
    lua_run = cwrap('run_lua', 'number', ['string', 'string']);
    // Initial parse
    if ($('#auto-refresh').prop('checked')) {
      parse();
    }
  },
};

// vim: sw=2:sts=2
