" Should we use asynchronous builds?
" This requires tpope/vim-dispatch
if !exists('g:bazel_enable_async_dispatch')
  let g:bazel_enable_async_dispatch = 1
endif

" Bash completion script path for bazel.
" In most cases, the use should not need to set it. In case you
" need to, consider sending a PR to add it to the search list.
" let g:bazel_bash_completion_path = ...

command! -complete=customlist,bazel#Completions -nargs=+
      \ Bazel :call bazel#Execute(<f-args>)
