let s:bazel_workspace_file = findfile("WORKSPACE", ".;")

" No need to continue if we are not in a bazel project
if empty(s:bazel_workspace_file)
  finish
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

" Call bazel command
command! -complete=customlist,bazel#Completions -nargs=+
      \ Bazel :call bazel#Execute(<f-args>)
