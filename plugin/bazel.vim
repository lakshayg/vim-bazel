" No need to continue if we are not in a bazel project
if empty(findfile("WORKSPACE", ".;"))
  finish
endif

" This can use used to enable asynchronous builds. See README
if !exists('g:bazel_make_command')
  let g:bazel_make_command = "make"
endif

" Set to 0 if more context in bazel error messages is needed.
" This will load everything from stdout into the quickfix list
" without filtering anything. By default, filtering is enabled
if !exists('g:bazel_filter_aggressively')
  let g:bazel_filter_aggressively = 1
endif

" Bash completion script path for bazel.
" In most cases, the use should not need to set it. In case you
" need to, consider sending a PR to add it to the search list.
" let g:bazel_bash_completion_path = ...

command! -complete=customlist,bazel#Completions -nargs=+
      \ Bazel :call bazel#Execute(<f-args>)
