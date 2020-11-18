let s:bazel_workspace_file = findfile("WORKSPACE", ".;")

" No need to continue if we are not in a bazel project
if empty(s:bazel_workspace_file)
  finish
endif

" This can use used to enable asynchronous builds.
" See :help bazel-g:bazel_make_command
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

" Add bazel-bin and bazel-<project> to the path
call bazel#ModifyPath(fnamemodify(s:bazel_workspace_file, ":p:h"))

augroup VimBazel
  autocmd!
  " Resolve references to external/ paths in the quickfix list
  autocmd QuickFixCmdPost make :call bazel#ResolveQuickfixPaths()
augroup END

" Jump to the BUILD file corresponding to current source file
command! Bld :call bazel#JumpToBuildFile()

" Read the entire output from the last bazel command
command! BazelLog :call bazel#ReadLastLog()

" Call bazel command
command! -complete=customlist,bazel#Completions -nargs=+
      \ Bazel :call bazel#Execute(<f-args>)
