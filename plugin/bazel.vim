let s:bazel_workspace_file = findfile("WORKSPACE", ".;")

" Bash completion script path for bazel.
" In most cases, the user should not need to set it. In case you
" need to, consider sending a PR to add it to the search list.
" let g:bazel_bash_completion_path = ...
if !exists("g:bazel_bash_completion_path")
  let candidates = filter([
        \ "/etc/bash_completion.d/bazel",
        \ "/usr/local/lib/bazel/bin/bazel-complete.bash"
        \ ], 'filereadable(v:val)')
  if !empty(candidates)
    let g:bazel_bash_completion_path = candidates[0]
  endif
endif

" No need to continue if we are not in a bazel project
if empty(s:bazel_workspace_file)
  finish
endif

" Add bazel-bin and bazel-<project> to the path
call bazel#ModifyPath(fnamemodify(s:bazel_workspace_file, ":p:h"))

augroup VimBazel
  autocmd!
  " Resolve references to external/ paths in the quickfix list
  " There's a relative flag which might do it, wait until I encounter
  " such an issue
  " autocmd QuickFixCmdPost make :call bazel#ResolveQuickfixPaths()
augroup END

" Jump to the BUILD file corresponding to current source file
command! Bld :call bazel#JumpToBuildFile()

" Call bazel command
command! -complete=customlist,bazel#Completions -nargs=+
      \ Bazel :call bazel#Execute(<f-args>)
