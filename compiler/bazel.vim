if exists("current_compiler")
  finish
endif
let current_compiler = "bazel"

let s:cpo_save = &cpo
set cpo&vim

if exists(":CompilerSet") != 2
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=bazel

" Errorformat settings
"
" * errorformat reference: http://vimdoc.sourceforge.net/htmldoc/quickfix.html#errorformat
" * look for message without consuming: https://stackoverflow.com/a/36959245/10923940
" * errorformat explanation: https://stackoverflow.com/a/29102995/10923940
"
" Use %f\\ instead of %f so that isfname setting is used to match filenames
" See: https://vi.stackexchange.com/a/8085/29769

" Ignore this error message, it is always redundant
" ERROR: <filename>:<line>:<col>: C++ compilation of rule '<target>' failed (Exit 1)
CompilerSet errorformat=%-GERROR:\ %f:%l:%c:\ C++\ compilation\ of\ rule\ %m
CompilerSet errorformat+=%tRROR:\ %f:%l:%c:\ %m   " Generic bazel error handler
CompilerSet errorformat+=%tARNING:\ %f:%l:%c:\ %m " Generic bazel warning handler
CompilerSet errorformat+=%tEBUG:\ %f:%l:%c:\ %m   " Generic bazel debug handler

" this rule is missing dependency declarations for the following files included by '<another-filename>'
"   '<fname-1>'
"   '<fname-2>'
"   ...
CompilerSet errorformat+=%Ethis\ rule\ is\ %m\ the\ following\ files\ included\ by\ \'%f\':
CompilerSet errorformat+=%C\ \ \'%m\'
CompilerSet errorformat+=%Z

" Test failures
CompilerSet errorformat+=FAIL:\ %m\ (see\ %f)            " FAIL: <test-target> (see <test-log>)

" test failures in async builds
CompilerSet errorformat+=%E%*[\ ]FAILED\ in%m
CompilerSet errorformat+=%C\ \ %f
CompilerSet errorformat+=%Z

" Errors in the build stage
CompilerSet errorformat+=%f:%l:%c:\ fatal\ %trror:\ %m         " <filename>:<line>:<col>: fatal error: <message>
CompilerSet errorformat+=%f:%l:%c:\ %trror:\ %m                " <filename>:<line>:<col>: error: <message>
CompilerSet errorformat+=%f:%l:%c:\ %tarning:\ %m              " <filename>:<line>:<col>: warning: <message>
CompilerSet errorformat+=%f:%l:%c:\ note:\ %m                  " <filename>:<line>:<col>: note: <message>
CompilerSet errorformat+=%f:%l:%c:\ \ \ requ%tred\ from\ here  " <filename>:<line>:<col>: <message>
CompilerSet errorformat+=%f(%l):\ %tarning:\ %m                " <filename>(<line>): warning: <message>
CompilerSet errorformat+=%f(%l):\ %trror:\ %m                  " <filename>(<line>): error: <message>
CompilerSet errorformat+=%f:%l:%c:\ %m                         " <filename>:<line>:<col>: <message>
CompilerSet errorformat+=%f\\:%l:\ %m                          " <filename>:<line>: <message>

let &cpo = s:cpo_save
unlet s:cpo_save
